// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {LinkToken} from "../test/Mocks/LinkToken.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract CodeConstants {
    address constant SEPOLIA_VRF_COORDINATOR =
        0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
    uint256 constant SEPOLIA_ENTRANCE_FEE = 0.01 ether;
    uint256 constant SEPOLIA_INTERVAL = 30;
    bytes32 constant SEPOLIA_KEY_HASH =
        0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
    uint256 constant SEPOLIA_SUB_ID =
        18776385321801707430405177069871431153657957294550349958299903282939335423092;

    uint256 constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;

    address constant SEPOLIA_LINK_TOKEN_ADDRESS =
        0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address constant SEPOLIA_ACCOUNT_ADDRESS =
        0xB1d8DBA0B902E36c58d5c8AC50061Ab3aA5cD3e5; // ✅ Fix: proper constant
    address constant LOCAL_ACCOUNT_ADDRESS =
        0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38; // ✅ Add as constant
}

//THIS HELPER CONFIG CONTRACT WILL STORE ALL THE NETWORK SPECIFIC DETAILS

contract HelperConfig is Script, CodeConstants {
    error No_ConfigFound();

    struct Config {
        address vrfCoordinatorV2;
        uint256 entranceFee;
        uint256 interval;
        bytes32 keyHash;
        uint256 subId;
        address link;
        address account;
    }
    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 4e15;

    Config public activeNetworkConfig;
    mapping(uint256 chainID => Config) public networkConfigs;

    constructor() {
        if (block.chainid == SEPOLIA_CHAIN_ID) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == LOCAL_CHAIN_ID) {
            activeNetworkConfig = getLocalEthConfig(); // ✅ Now it actually calls this
        } else {
            revert No_ConfigFound();
        }

        networkConfigs[block.chainid] = activeNetworkConfig;
    }

    function getConfigByChainID(
        uint256 chainID
    ) public returns (Config memory) {
        if (networkConfigs[chainID].vrfCoordinatorV2 != address(0)) {
            return networkConfigs[chainID];
        } else if (chainID == LOCAL_CHAIN_ID) {
            return getLocalEthConfig();
        } else {
            revert No_ConfigFound();
        }
    }

    function getSepoliaEthConfig() public pure returns (Config memory) {
        return
            Config({
                vrfCoordinatorV2: SEPOLIA_VRF_COORDINATOR,
                entranceFee: SEPOLIA_ENTRANCE_FEE,
                keyHash: SEPOLIA_KEY_HASH,
                interval: SEPOLIA_INTERVAL,
                subId: SEPOLIA_SUB_ID,
                link: SEPOLIA_LINK_TOKEN_ADDRESS,
                account: SEPOLIA_ACCOUNT_ADDRESS
            });
    }

    function getConfig() public view returns (Config memory) {
        return activeNetworkConfig;
    }

    function getLocalEthConfig() public returns (Config memory) {
        if (activeNetworkConfig.vrfCoordinatorV2 != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock mock = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE_LINK,
            MOCK_WEI_PER_UNIT_LINK
        );
        LinkToken link = new LinkToken();

        // 1️⃣ CREATE local subscription
        uint256 localSubId = mock.createSubscription();

        // 2️⃣ FUND the subscription (use ETH if nativePayment=true)
        mock.fundSubscription(localSubId, 100 ether);

        vm.stopBroadcast();

        return
            Config({
                entranceFee: 0.01 ether,
                vrfCoordinatorV2: address(mock),
                keyHash: SEPOLIA_KEY_HASH,
                interval: SEPOLIA_INTERVAL,
                subId: localSubId, // 🔥 USE THIS, not real Sepolia subId
                link: address(link),
                account: LOCAL_ACCOUNT_ADDRESS
            });
    }
}
