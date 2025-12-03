// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script} from "forge-std/Script.sol";
import {Nft} from "../src/Contract.sol";

contract DeployContract is Script {
    function run() external returns (Nft) {
        vm.startBroadcast();
        Nft BasicNft = new Nft();
        vm.stopBroadcast();
        return BasicNft;
    }
}
