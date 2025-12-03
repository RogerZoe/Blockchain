// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// import "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";

import "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol"; // still required
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

/**
 * @title  Simple Raffle contract
 * @author Shaik
 * @notice This contract is for creating a simple raffle system
 * @dev This implements the basic functionality of a raffle system with Chainlink VRF v2.5
 */

contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    IVRFCoordinatorV2Plus private immutable s_vrfCoordinator;

    error Raffle__NotEnoughETHEntered();
    error Raffle__TimeNotPassed();
    error Raffle__TransferFailed();

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subId;
    uint16 private constant requestConfirmations = 3;
    uint32 private constant callbackGasLimit = 100000;
    uint32 private constant numWords = 1;
    address payable public WinnerAddress;
    uint256 public LastRequestId;

    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;
    RaffleState public s_raffleState; // Enum to track the state of the raffle

    event RaffleEnter(address indexed player);
    event WinnerPicked(address indexed winner);
    event RandomWordsRequested(uint256 indexed requestId);

    constructor(
        address vrfCoordinatorV2,
        uint256 entranceFee,
        uint256 interval,
        bytes32 keyHash,
        uint256 subId
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        s_vrfCoordinator = IVRFCoordinatorV2Plus(vrfCoordinatorV2);
        i_entranceFee = entranceFee;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
        i_keyHash = keyHash;
        i_subId = subId;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() public payable {
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__TimeNotPassed();
        }
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHEntered();
        }
        s_players.push(payable(msg.sender));

        emit RaffleEnter(msg.sender);
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        //  These conditions must be met for upkeep to be needed: because if any of these conditions are false, we don't need to perform upkeep.
        bool isOpen = (s_raffleState == RaffleState.OPEN);
        bool timePassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = (address(this).balance > 0);
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);

        return (upkeepNeeded, "");
    }

    /*
         This function is called by Chainlink Keepers when upkeep is needed and it initiates the process of selecting a winner.
    */

    function performUpkeep(bytes memory /* performData */) external override {
        // Check if upkeep is needed
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__TimeNotPassed();
        }

        s_raffleState = RaffleState.CALCULATING;
        // Create the RandomWordsRequest struct using the pattern from your example
        LastRequestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
        //! WE DONT HAVE TO EMIT THE EVENTS, BECAUSE CHAINLINK VRF COORDINATOR EMITS THEM AUTOMATICALLY, 
        emit RandomWordsRequested(LastRequestId);
    }

    //CEI pattern followed in fulfillRandomWords
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        //checks
        //Effects (Internal code changes)
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable _WinnerAddress = s_players[indexOfWinner];

        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0); // Reset the players array
        s_lastTimeStamp = block.timestamp; // Update the last timestamp

        WinnerAddress = _WinnerAddress;
        emit WinnerPicked(WinnerAddress);

        //interactions (External calls)
        (bool success, ) = WinnerAddress.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /**
     * @notice Getter functions
     */
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        require(index < s_players.length, "Index out of bounds");
        return s_players[index];
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getKeyHash() public view returns (bytes32) {
        return i_keyHash;
    }

    function getSubscriptionId() public view returns (uint256) {
        return i_subId;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getRecentWinner() public view returns(address){
        return WinnerAddress;
    }
}
