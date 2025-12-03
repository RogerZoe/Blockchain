// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {LinkToken} from "../test/Mocks/LinkToken.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";



// this script is used to interact with the Subscription features of Chainlink VRF v2.5
contract CreateSubscription is Script, CodeConstants {
    function createSubscriptionByConfig() public returns (uint256) {
        HelperConfig helperConfig = new HelperConfig();
        address configAddress = helperConfig.getConfig().vrfCoordinatorV2;
        address account = helperConfig.getConfig().account; // For Sepolia deployment
        (uint256 subId, ) = createSubscription(configAddress, account);
        return subId;
    }
 
    function createSubscription(
        address vrfCoordinator, address account
    ) public returns (uint256, address) {
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock coordinator = VRFCoordinatorV2_5Mock(
            vrfCoordinator
        );
        uint256 subId = coordinator.createSubscription();
        vm.stopBroadcast();
        return (subId, address(coordinator));
    }

    function run() public {
        createSubscriptionByConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 constant LINK_AMOUNT = 3 ether;

    //1. VrfCoordinator Address
    //2. Subscription Id
    //3 Link Amount to fund

    function fundSubscription() public {
        HelperConfig helperConfig = new HelperConfig();
        address configAddress = helperConfig.getConfig().vrfCoordinatorV2;
        uint256 subId = helperConfig.getConfig().subId;
        address linkAmount = helperConfig.getConfig().link;
        address account = helperConfig.getConfig().account;
        fundSubscription(configAddress, subId, linkAmount, account);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint256 subId,
        address link,
        address account
    ) public {
        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast(account);
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subId,
                LINK_AMOUNT 
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(link).transferAndCall(
                vrfCoordinator,
                LINK_AMOUNT,
                abi.encode(subId)
            );
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubscription();
    }
}

// This script is used to add a consumer contract, which will use the subscription created earlier
contract AddConsumer is Script {
    //1. VrfCoordinator Address
    //2. Subscription Id
    //3. Consumer Address

    function addConsumerByConfig(address consumer) public {
        HelperConfig helperConfig = new HelperConfig();
        address configAddress = helperConfig.getConfig().vrfCoordinatorV2;
        uint256 subId = helperConfig.getConfig().subId;
        address account = helperConfig.getConfig().account;
        addConsumer(configAddress, subId, consumer, account);
    }

    function addConsumer(
        address vrfCoordinator,
        uint256 subId,
        address consumer,
        address account
    ) public {
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, consumer);
        vm.stopBroadcast();
    }

    function run() public {
        //
        address mostRecentDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerByConfig(mostRecentDeployed);
    }
}
