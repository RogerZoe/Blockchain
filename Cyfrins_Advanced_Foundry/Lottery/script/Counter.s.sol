// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffile.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription} from "./Interactions.s.sol";
import {FundSubscription} from "./Interactions.s.sol";
import {AddConsumer} from "./Interactions.s.sol";

contract RaffleScript is Script {
    Raffle public raffle;

    function deployContract() public returns (Raffle, HelperConfig) {
        // Deploy the config helper
        HelperConfig helperConfig = new HelperConfig();
        // Automatically returns Sepolia or Local config depending on chain ID
        HelperConfig.Config memory config = helperConfig.getConfig();


         //!Creating Subscription............. 
        if(config.subId == 0){
            // Create subscription
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subId,config.vrfCoordinatorV2) = createSubscription.createSubscription(config.vrfCoordinatorV2,config.account);

            // Note: In a real deployment, you would likely want to fund the subscription here as well.
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(config.vrfCoordinatorV2, config.subId, config.link, config.account);
        }

        // Start broadcast (real tx if private key loaded, dry-run otherwise)
        vm.startBroadcast(config.account); // adding config.account beccause we modified HelperConfig to include deployer account and for the sepolia config we have set a real account address
        raffle = new Raffle(
            config.vrfCoordinatorV2,
            config.entranceFee,
            config.interval,
            config.keyHash,
            config.subId
        );
        vm.stopBroadcast();

        // Add the raffle contract as a consumer to the subscription
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(config.vrfCoordinatorV2, config.subId, address(raffle), config.account);

        return (raffle, helperConfig);
    }

    // Optional for forge sc ript runner compatibility
    function setUp() public {}

    function run() public {
        deployContract();
    }
}
