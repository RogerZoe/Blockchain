// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {BoxV2} from "../src/Box2.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract UpgradeBox is Script {
    function run() external returns (address) {
        address proxy = DevOpsTools.get_most_recent_deployment("ERC1967Proxy", block.chainid);

        vm.startBroadcast();
        BoxV2 newImpl = new BoxV2();
        BoxV2(proxy).upgradeToAndCall(address(newImpl), "");
        vm.stopBroadcast();
        
        return address(proxy);
    }
}