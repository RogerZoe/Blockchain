// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStablecoin} from "../../src/DecentralizedStablecoin.sol";
import {DSC} from "../../script/DSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {ERC20Mock as CustomERC20Mock} from "../Mocks/ERC20Mock.sol";

contract DSCEngineTest is Test {
    DSCEngine public dscEngine; 
    DecentralizedStablecoin public dsc;
    DSC public dscDeployer;
    HelperConfig public helperConfig;
    address public Weth;
    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    function setUp() public {
        dscDeployer = new DSC();
        (dsc, dscEngine, helperConfig) = dscDeployer.run();
        (,, Weth,,) = helperConfig.activeNetworkConfig();
        ERC20Mock(Weth).mint(USER, STARTING_ERC20_BALANCE);
    }

    function testUSDValue() public view {
        uint256 ethAmount = 15e18;
        // uint256 ethUsdPrice = 2000e8;
        uint256 expectedUsdValue = 30000e18;

        uint256 usdValue = dscEngine.getUsdValue(Weth, ethAmount);
        console.log("USD Value:", usdValue);
        assertEq(expectedUsdValue, usdValue);
    }

    function testRevertsIfCollateralZero() public {
        vm.prank(USER);
        ERC20Mock(Weth).approve(address(dscEngine), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dscEngine.depositCollateral(Weth, 0);
    }

    address[] public tokens = new address[](2);
    address[] public priceFeeds = new address[](3);

    function testRevertsTokensAndPriceFeedsLengthMismatch() public {
        vm.expectRevert(DSCEngine.TokensAndPriceFeedsLengthNotEqual.selector);
        new DSCEngine(tokens, priceFeeds, address(dsc));
    }

    function testGetTokenAmountFromUSD() public view {
        uint256 ethAmount = 300e18;
        uint256 expectedEth = 0.15e18;
        uint256 tokenAmount = dscEngine.getTokenAmountFromUSD(Weth, ethAmount);
        assertEq(expectedEth, tokenAmount);
    }

    function testRevertsIsAllowedToken() public {
        CustomERC20Mock faketoken = new CustomERC20Mock("RAN", "RAN", USER, AMOUNT_COLLATERAL); // this line creates a mock ERC20 token
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.NotAllowedTokens.selector);
        dscEngine.depositCollateral(address(faketoken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    //
    modifier depositCollateral() {
        vm.startPrank(USER);
        ERC20Mock(Weth).approve(address(dscEngine), AMOUNT_COLLATERAL); // we need this
        dscEngine.depositCollateral(Weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralAndGetAccountInfo() public depositCollateral {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dscEngine.getAccountInformation(USER); // this info used to get user info about collateral and minted DSC.
        uint256 expectedDscMinted = 0;
        uint256 expectedCollateralValueInUsd = dscEngine.getUsdValue(Weth, AMOUNT_COLLATERAL);
        assertEq(expectedDscMinted, totalDscMinted);
        assertEq(expectedCollateralValueInUsd, collateralValueInUsd);
    }

    ///////////////////////////////////////
    //   INVARIANT TESTS
    ///////////////////////////////////////

    // (total collateral value in USD)  >  (total DSC minted)
    // DSC stablecoin must always be over-collateralized.
    // Total collateral (USD) > total DSC minted.

    
}
