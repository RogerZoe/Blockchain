// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStablecoin} from "../../src/DecentralizedStablecoin.sol";
import {DSC} from "../../script/DSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Handler} from "./Invariants.t.sol";

contract OpenInvariantsTest is Test {
    DSCEngine public dscEngine;
    DecentralizedStablecoin public dsc;
    DSC public dscDeployer;
    HelperConfig public helperConfig;
    Handler handler;
    address public Weth;
    address public Wbtc;
    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    function setUp() public {
        dscDeployer = new DSC();
        (dsc, dscEngine, helperConfig) = dscDeployer.run();
        (,, Weth, Wbtc,) = helperConfig.activeNetworkConfig();
        handler = new Handler(dscEngine, dsc);
        targetContract(address(handler)); // Set the target contract for invariant testing
    }
    /// @dev Invariant: The total supply of DSC should never exceed the total value of collateral in the system.

    function invariant_protocolMustHaveMoreValueThanTotalSupply() public view {
        // steps
        // 1. Get total supply of DSC
        // 2. Get total value of collateral in the system (in USD)
        // 3. Assert that total value of collateral >= total supply of DSC

        uint256 totalSupply = dsc.totalSupply();
        uint256 totalWethDeposited = IERC20(Weth).balanceOf(address(dscEngine));
        uint256 totalWbtcDeposited = IERC20(Wbtc).balanceOf(address(dscEngine));

        uint256 WethUsdvalue = dscEngine.getUsdValue(Weth, totalWethDeposited);
        uint256 WbtcUsdvalue = dscEngine.getUsdValue(Wbtc, totalWbtcDeposited);

        console.log("Total DSC Supply:", totalSupply);
        console.log("Total WETH USD Value:", WethUsdvalue);
        console.log("Total WBTC USD Value:", WbtcUsdvalue);
        console.log("Mint called times:", handler.TimesMintCalled());

        assert(WethUsdvalue + WbtcUsdvalue >= totalSupply);
    }
}
