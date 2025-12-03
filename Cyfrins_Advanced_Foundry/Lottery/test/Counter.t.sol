// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../src/Raffile.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {RaffleScript} from "../script/Counter.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {CodeConstants} from "../script/HelperConfig.s.sol";

    
contract RaffleTest is Test, CodeConstants {
    address public vrfCoordinatorV2;
    uint256 public entranceFee;
    uint256 public interval;
    bytes32 public keyHash;
    uint256 public subId;
    Raffle public raffle;
    HelperConfig public helperConfig;

    event RaffleEnter(address indexed player);
    event WinnerPicked(address indexed winner);
    event RandomWordsRequested(uint256 indexed requestId);

    address public PLAYER = makeAddr("player");

    function setUp() public {
        RaffleScript deployer = new RaffleScript();
        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.Config memory config = helperConfig.getConfig();
        vrfCoordinatorV2 = config.vrfCoordinatorV2;
        entranceFee = config.entranceFee;
        interval = config.interval;
        keyHash = config.keyHash;
        subId = config.subId;
        vm.deal(PLAYER, 100 ether);
    }

    function testRaffleInitializesInOpenState() public view {
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(raffleState == Raffle.RaffleState.OPEN);
    }

    function test_Revert_When_NotEnoughETHEntered() public {
        vm.prank(PLAYER);

        vm.expectRevert(Raffle.Raffle__NotEnoughETHEntered.selector);
        raffle.enterRaffle();
    }

    function testRafflePlayersWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        assertEq(raffle.getNumberOfPlayers(), 1);
    }

    function testRafflePlayersWhenTheyEnter_Events() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false);
        emit RaffleEnter(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testDontAllowEntranceWhenRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        // Simulate the passage of time and change the raffle state to CALCULATING
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__TimeNotPassed.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCheckUpkeepReturnsFalseIfNoBalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpKeepReturnFalseIfNotOpen() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        //Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // assertEq(upkeepNeeded,false);
        assert(!upkeepNeeded);
    }

    function testPerformUpkeepOnlyRunsIfCheckUpkeepIsTrue() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");
        assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);
    }

    function testPerformUpKeepRevertsIfCheckUpkeepIsFalse() public {
        vm.expectRevert(Raffle.Raffle__TimeNotPassed.selector);
        raffle.performUpkeep(""); // it means checkUpkeep will false, if we don't have any players,time not passed,not open, no blance
    }

    modifier raffleEnteredAndTimePassed() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    //!TESTING THE EVENTS WHICH ARE EMITTED IN PERFORMUPKEEP FUNCTION [AUTOMATICALLY EMITS THE REQUEST ID BY REQUESTRANDOMWORDS FUNCTION]
    function testPerformUpkeepEmitsEventOnRequestingRandomWords()
        public
        raffleEnteredAndTimePassed
    {
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        // take the final log emitted inside performUpkeep()
        Vm.Log memory lastLog = entries[entries.length - 1];
        console.log("Last log emitter:", lastLog.emitter);
        console.log(lastLog.topics.length, "topics length");

        bytes32 requestIdTopic = lastLog.topics[1];
        console.log(uint256(requestIdTopic), "request ID");

        assert(uint256(requestIdTopic) > 0);
        assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);
    }

    /* ///////////////////////////////////////////////
                 FulfillRandomWords Tests
    ////////////////////////////////////////////// */

    modifier SkipFork(){
        if(block.chainid != LOCAL_CHAIN_ID){
            return;
        }
        _;
    }

    //! THIS ONE TESTS THAT FULFILLRANDOMWORDS FUNCTION CAN ONLY BE CALLED AFTER PERFORMUPKEEP FUNCTION IS CALLED AND REQUEST ID IS GENERATED
    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        uint256 requestId
    ) public raffleEnteredAndTimePassed SkipFork {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector); // because requestId is 0 here
        VRFCoordinatorV2_5Mock(vrfCoordinatorV2).fulfillRandomWords(
            requestId,
            address(raffle)
        );
    }

    function testFulfillRandomWordsWinnerResetsAndSendMoney()
        public
        raffleEnteredAndTimePassed SkipFork
    {
        uint256 Players = 3;
        uint256 startingIndex = 1;
        uint256 total = Players + startingIndex;

        address[] memory testPlayers = new address[](total);

        for (uint256 i = 0; i < total; i++) {
            address newPlayer = address(uint160(i));
            testPlayers[i] = newPlayer;
            hoax(newPlayer, 1 ether);
            raffle.enterRaffle{value: entranceFee}();
        }

        uint256 startingTimestamp = raffle.getLastTimeStamp();

        // request randomness
        raffle.performUpkeep("");
        uint256 requestId = raffle.LastRequestId();

        // fulfill randomness
        VRFCoordinatorV2_5Mock(vrfCoordinatorV2).fulfillRandomWords(
            requestId,
            address(raffle)
        );

        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 endingTimestamp = raffle.getLastTimeStamp();

        // Winner should be someone in players
        bool validWinner = false;
        for (uint256 i = 0; i < testPlayers.length; i++) {
            if (recentWinner == testPlayers[i]) {
                validWinner = true;
                break;
            }
        }

        assertTrue(validWinner);
        assertEq(uint256(raffleState), uint256(Raffle.RaffleState.OPEN));
        assertGt(endingTimestamp, startingTimestamp);
    }
}
