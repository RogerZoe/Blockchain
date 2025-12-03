// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStablecoin} from "../../src/DecentralizedStablecoin.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

//  we tell our framework not to call redeemCollateral unless there's collateral available to redeem.
// it means that we need to create a handler contract that will manage the state for us during the invariant testing.
//
contract Handler is Test {
    DSCEngine dsce;
    DecentralizedStablecoin dsc;
    ERC20Mock public weth;
    ERC20Mock public wbtc;
    uint256 public constant MAX_DESPOSIT_SIZE = type(uint96).max;
    uint256 public TimesMintCalled;

    constructor(DSCEngine _engine, DecentralizedStablecoin _dsc) {
        dsce = _engine;
        dsc = _dsc;

        address[] memory tokens = dsce.getCollateralTokens();
        weth = ERC20Mock(tokens[0]);
        wbtc = ERC20Mock(tokens[1]);
    }

    // Add functions here that will be called during invariant testing
    // write depositCollateral function
    function depositCollateral(uint256 CollateralSeed, uint256 amountCollateral) public {
        amountCollateral = bound(amountCollateral, 1, MAX_DESPOSIT_SIZE);
        ERC20Mock collateral = getCollateralAddress(CollateralSeed);

        //mint and approval
        collateral.mint(address(this), amountCollateral); // address(this) is the handler contract address
        collateral.approve(address(dsce), amountCollateral);

        dsce.depositCollateral(address(collateral), amountCollateral);
        console.log("Deposited %s of collateral %s", amountCollateral, address(collateral));
    }

    function getCollateralAddress(uint256 collateralSedd) private view returns (ERC20Mock) {
        if (collateralSedd % 2 == 0) {
            return weth;
        }
        return wbtc;
    }

    // address(this) is the handler contract address and msg.sender is the test contract address [the one that calls the handler functions]
    // address(this) used to call the dsce functions because the handler is the one interacting with the dsce contract
    // while msg.sender is used to get the status of the handler-user
    function redeemCollateral(uint256 CollateralSeed, uint256 amountCollateral) public {
        if (dsce.getDscMinted((address(this))) == 0) return; // if user has not minted DSC no need to redeem collateral
        ERC20Mock collateral = getCollateralAddress(CollateralSeed);
        uint256 maxCollateralToRedeem = dsce.getCollateralBalanceOfUser(msg.sender, address(collateral)); // here we use msg.sender because we want to check the collateral of the handler-user not the test contract
        amountCollateral = bound(amountCollateral, 0, maxCollateralToRedeem);
        if (amountCollateral == 0) {
            // if its zero no need to redeem
            return;
        }

        dsce.redeemCollateral(address(collateral), amountCollateral);
    }

    // we do invariants on minting DSC
    // NOTE: Without mintDsc() the DSC total supply will always be zero
    // You must add mintDsc(),  otherwise you’re not testing the real invariant.
    function mintDsc(uint256 amount) public {
        // checking steps:
        // check how much collateral the handler-user has
        // check how much DSC they already minted
        // calculate “safe minting amount”
        // mint only within that limit
        // get your (the handler's) collateral & minted DSC status.

        (uint256 minted, uint256 collateralValue) = dsce.getAccountInformation(address(this));       //  NOTE: here  we wont write msg.sender because the handler is the one calling this function,if we write msg.sender it will give zero values, because msg.sender is the test contract which has no collateral or minted DSC.

        // max DSC you can mint without breaking health factor
        uint256 maxDsc = (collateralValue / 2) - minted;

        if (maxDsc < 0) {
            return; // can't mint safely
        }

        amount = bound(amount, 0, maxDsc);
        if (amount == 0) return;

        dsce.mintDsc(amount);
        TimesMintCalled += 1;
    }
}
