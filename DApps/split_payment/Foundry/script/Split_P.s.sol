// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {SplitPayment} from "../src/Split_Payment.sol";

contract Split_PaymentScript is Script {
    SplitPayment public split;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        split = new SplitPayment();

        vm.stopBroadcast();
    }
}
