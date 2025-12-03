// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {DecentralizedStablecoin} from "../src/DecentralizedStablecoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DSC is Script {
    address[] public tokenAddress;
    address[] public pricefeedAddress;
    function run() public returns (DecentralizedStablecoin, DSCEngine,HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (address wethUsdPriceFeed, address wbtcUsdPriceFeed, address weth, address wbtc, ) = helperConfig.activeNetworkConfig();

       tokenAddress=[weth,wbtc];
       pricefeedAddress = [wethUsdPriceFeed, wbtcUsdPriceFeed];

       vm.startBroadcast();
       DecentralizedStablecoin dsc = new DecentralizedStablecoin();
       DSCEngine dscEngine = new DSCEngine(tokenAddress, pricefeedAddress, address(dsc));
       dsc.transferOwnership(address(dscEngine)); // transfer ownership to the engine contract, bDecentralizedStableCoin.sol is Ownable, and by deploying it this way, our msg.sender is going to be the owner by default
       vm.stopBroadcast();
       return (dsc, dscEngine, helperConfig);

    }
}
