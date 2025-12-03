// SPDX-License-Identifier: MIT

import {DecentralizedStablecoin} from "./DecentralizedStablecoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {OracleLib} from "./Libraries/Oracle.sol";

// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volatility coin

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

/*
 * @title DSCEngine
 * @author Patrick Collins
 *
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == $1 peg at all times.
 * This is a stablecoin with the properties:
 * - Exogenously Collateralized
 * - Dollar Pegged
 * - Algorithmically Stable
 *
 * It is similar to DAI if DAI had no governance, no fees, and was backed by only WETH and WBTC.
 *
 * Our DSC system should always be "overcollateralized". At no point, should the value of
 * all collateral < the $ backed value of all the DSC.
 *
 * @notice This contract is the core of the Decentralized Stablecoin system. It handles all the logic
 * for minting and redeeming DSC, as well as depositing and withdrawing collateral.
 * @notice This contract is based on the MakerDAO DSS system
 */

pragma solidity ^0.8.20;

contract DSCEngine is ReentrancyGuard {
    error DSCEngine__NeedsMoreThanZero();
    error NotAllowedTokens();
    error TokensAndPriceFeedsLengthNotEqual();
    error DSCEngine__DepositCollateralFailed();
    error DSCEngine__BreaksHealthFactor(uint256 healthFactor);
    error DSCEngine__MintFailed();
    error DSCEngine__BreaksHealthFactorOK();
    error DSCEngine__HealthFactorNotImproved();

    using OracleLib for AggregatorV3Interface;

    event CollateralDeposited(address user, address tokenCollateralAddress, uint256 amountCollateral);

    DecentralizedStablecoin public immutable i_dsc;
    mapping(address token => address priceFeeds) private s_priceFeeds;
    mapping(address user => mapping(address tokenAddress => uint256 amount)) private s_collateralDeposited;
    mapping(address user => uint256 amountDSCMinte) private s_DSCMinted;
    address[] private s_CollateralTokens; //Helps to traverse the collateral tokens so that we can check the health factor of the DSC
    uint256 private constant ADDITIONAL_PRICE_FEED = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant LIQUIDATION_THRESHOLD = 50;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;
    uint256 private constant BONUS_PERCENT = 10;
    uint256 private constant BONUS_PRECISION = 100;

    modifier moreThanZero(uint256 amount) {
        if (amount <= 0) {
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert NotAllowedTokens();
        }
        _;
    }

    constructor(address[] memory tokens, address[] memory priceFeeds, address dscAddress) {
        if (tokens.length != priceFeeds.length) {
            revert TokensAndPriceFeedsLengthNotEqual();
        }

        for (uint256 i = 0; i < tokens.length; i++) {
            s_priceFeeds[tokens[i]] = priceFeeds[i];
            s_CollateralTokens.push(tokens[i]);
        }
        i_dsc = DecentralizedStablecoin(dscAddress); // this hepls to access the DSC contract
    }

    /*
     * @notice: this function combines two actions: depositing collateral and minting DSC.
     * @param tokenCollateralAddress: The ERC20 token address of the collateral you're depositing
     * @param amountCollateral: The amount of collateral you're depositing
     * @param amountDSCToMint: The amount of DSC you want to mint
     */
    function depositCollateralAndMintDsc(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountDSCToMint
    ) external {
        depositCollateral(tokenCollateralAddress, amountCollateral);
        mintDsc(amountDSCToMint);
    }

    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral); // HERE DEPOISTING THE COLLATERAL FROM THE USER TO THE CONTRACT
        if (!success) {
            revert DSCEngine__DepositCollateralFailed();
        }
    }

    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        totalDscMinted = s_DSCMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);
    }

    // [ The following functions are left unimplemented for brevity]
    // function redeemCollateralForDsc(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountDSCToBurn)
    //     external
    //     moreThanZero(amountCollateral)
    //     isAllowedToken(tokenCollateralAddress)
    // {
    //     // Steps:
    //     // 1. Burn the DSC
    //     // 2. Redeem the collateral
    //     burnDsc(amountDSCToBurn);
    //     redeemCollateral(tokenCollateralAddress, amountCollateral);
    // }

    function redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        _redeemCollateral(msg.sender, msg.sender, tokenCollateralAddress, amountCollateral);

        // NOTE: BURNING THE  DSC EQUIVALENT TO THE COLLATERAL REDEEMED, SO NEXT BURN THE DSC
    }

    function burnDsc(uint256 amountDSC) public moreThanZero(amountDSC) nonReentrant {
        _burnDsc(amountDSC, msg.sender, msg.sender);
    }

    function mintDsc(uint256 amountDSCToMint) public moreThanZero(amountDSCToMint) nonReentrant {
        s_DSCMinted[msg.sender] += amountDSCToMint; // this is the amount of DSC minted by the user
        // Need to check the health factor of the DSC, if it's too low, need to liquidate the DSC and if it's too high, need to burn the DSC
        _revertIfHealthFactorToBroken(msg.sender);

        bool minted = i_dsc.mint(msg.sender, amountDSCToMint); // this mints the real DSC token
        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    function liquidate(address token, address user, uint256 amountCollateral)
        external
        moreThanZero(amountCollateral)
        isAllowedToken(token)
        nonReentrant
    {
        // Steps:
        // 1. Check the health factor of the user
        // 2. If the health factor is below the threshold, liquidate the user's collateral
        // 3. calculate the debt owed by the user
        //    3.1 first convert the Usd value of the collateral to token amount
        //    3.2 then we need to add the bonused amount to the debt owed
        // 4. Deduct the debt owed from the user's minted DSC
        // 5. Transfer the DSC from the contract to the user

        uint256 startingHealthFactor = HealthFactor(user);
        if (startingHealthFactor >= MIN_HEALTH_FACTOR) {
            revert DSCEngine__BreaksHealthFactorOK();
        }

        _revertIfHealthFactorToBroken(user);

        uint256 amountCollateralInUsd = getTokenAmountFromUSD(token, amountCollateral);
        uint256 bonusCollateral = (amountCollateralInUsd * BONUS_PERCENT) / BONUS_PRECISION; // 10% bonus
        uint256 totalCollateralRedeemed = bonusCollateral + amountCollateralInUsd;

        _redeemCollateral(user, msg.sender, token, amountCollateral);
        _burnDsc(amountCollateral, user, msg.sender);

        // Note: we would also need to handle the case where the user's debt exceeds their collateral.
        // INFO: So check the health factor again after liquidation to ensure it's above the threshold.

        uint256 endingHealthFactor = HealthFactor(user);
        if (endingHealthFactor <= startingHealthFactor) {
            // like if starting health factor was 0.8 and after liquidation it's still 0.7 then revert
            revert DSCEngine__HealthFactorNotImproved();
        }
        _revertIfHealthFactorToBroken(user); // final check to ensure the user's health factor is above the threshold (optional)
    }

    //////////////////////////////////////////////
    //        Internal Functions                //
    //////////////////////////////////////////////

    function _burnDsc(uint256 amountDscToBurn, address onBehalfOf, address dscFrom) internal {
        // Steps:
        // 1. Reduce the user's minted DSC balance
        // 2. Transfer the DSC from the user to the contract
        // 3. Burn the DSC

        s_DSCMinted[onBehalfOf] -= amountDscToBurn;
        bool success = i_dsc.transferFrom(dscFrom, address(this), amountDscToBurn); // transfer the DSC from the user to the contract, why transferfrom first because the user need to approve the contract first
        if (!success) {
            revert DSCEngine__MintFailed();
        }
        i_dsc.burn(amountDscToBurn); // burn the DSC
    }

    function _redeemCollateral(address from, address to, address tokenCollateralAddress, uint256 amountCollateral)
        internal
    {
        // Steps:
        // 1. Check if the user has enough collateral to redeem
        // 2. Check if the health factor is maintained after redeeming
        // 3. Update the user's collateral balance
        // 4. Transfer the collateral back to the user

        s_collateralDeposited[from][tokenCollateralAddress] -= amountCollateral;
        bool success = IERC20(tokenCollateralAddress).transfer(to, amountCollateral); // transfer the collateral back to the user
        if (!success) {
            revert DSCEngine__DepositCollateralFailed();
        }
        _revertIfHealthFactorToBroken(from);
    }

    function getTokenAmountFromUSD(address token, uint256 amountCollateral)
        public
        view
        returns (uint256 amountCollateralInUsd)
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 amount,,,) = priceFeed.staleCheckLatestRoundData();

        // CALCULATION DONE IN NOTES........
        amountCollateralInUsd = (amountCollateral * PRECISION) / (uint256(amount) * ADDITIONAL_PRICE_FEED);
    }

    function _revertIfHealthFactorToBroken(address User) internal view {
        // here we check the healthFactor
        uint256 HF = HealthFactor(User);
        if (HF < LIQUIDATION_THRESHOLD) {
            revert DSCEngine__BreaksHealthFactor(HF);
        }
    }

    function HealthFactor(address User) private view returns (uint256) {
        // to check healthFactor we need two things
        // 1. Total DSC minted by the user
        // 2. Total Collateral Deposited by the user
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = getTotalDSCMintedAndTotalCollateralDeposited(User);

        //! CALCULATION DONE IN NOTES........
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
    }

    function getTotalDSCMintedAndTotalCollateralDeposited(address User)
        private
        view
        returns (uint256 totalDSCMinted, uint256 totalCollateralDeposited)
    {
        totalDSCMinted = s_DSCMinted[User];
        totalCollateralDeposited = getTotalCollateralDespositedInUsd(User);
    }

    // this function is used to get the total collateral deposited by the user
    function getTotalCollateralDespositedInUsd(address User) private view returns (uint256 totalCollateralDeposited) {
        for (uint256 i = 0; i < s_CollateralTokens.length; i++) {
            address token = s_CollateralTokens[i]; // to get the token address of the collateral
            uint256 amountCollateral = s_collateralDeposited[User][token]; // to get the amount of collateral deposited by the user
            totalCollateralDeposited += getUsdValue(token, amountCollateral);
        }
    }

    // this function is like "Tell me how many dollars this token amount is worth."
    function getUsdValue(address token, uint256 amountCollateral) public view returns (uint256 amountCollateralInUsd) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 amount,,,) = priceFeed.staleCheckLatestRoundData();

        // CALCULATION DONE IN NOTES........
        amountCollateralInUsd = ((uint256(amount) * ADDITIONAL_PRICE_FEED) * amountCollateral) / PRECISION;
    }

    // this function  will get the total collateral value of a user account in USD
    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUsd) {
        for (uint256 index = 0; index < s_CollateralTokens.length; index++) {
            address token = s_CollateralTokens[index];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }
        return totalCollateralValueInUsd;
    }

    function getAccountInformation(address user)
        public
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        return _getAccountInformation(user);
    }

    function getCollateralTokens() public view returns (address[] memory) {
        return s_CollateralTokens;
    }

    function getCollateralBalanceOfUser(address user, address token) public view returns (uint256) {
        return s_collateralDeposited[user][token];
    }

    function getDscMinted(address user) external view returns (uint256) {
        return s_DSCMinted[user];
    }
}
