// SPDX-Liceqnse-Identifier: MIT
pragma solidity ^0.8.19;

import {Script,console2} from "forge-std/Script.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address entrypoint;
        address wallet; // burner/deployer wallet address
    }

    NetworkConfig public networkConfig;
    mapping(uint256 => NetworkConfig) public networkConfigMapping;

    address private constant BURNER_WALLET = 0xB1d8DBA0B902E36c58d5c8AC50061Ab3aA5cD3e5;
    uint256 private constant SEPOLIA_CHAINID = 11155111;
    uint256 private constant LOCAL_CHAINID = 31337;
    address private constant ANVIL_ACCOUNT =0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    constructor() {
        networkConfigMapping[SEPOLIA_CHAINID] = getSepoliaEthConfig();
    }
    
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({entrypoint: 0x5Ff137D4b0FdCd49dCa30c7C6c780eE0B0728159, wallet: BURNER_WALLET});
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
    // If already stored, return it
    if (networkConfig.entrypoint != address(0)) {
        return networkConfig;
    }

    console2.log("Deploying mocks for Anvil...");
    // Deploy without broadcasting (tests run in-process)
    EntryPoint entryPoint = new EntryPoint();

    networkConfig = NetworkConfig({
        entrypoint: address(entryPoint),
        wallet: ANVIL_ACCOUNT
    });

    // Also store it in mapping for LOCAL_CHAINID if you want
    networkConfigMapping[LOCAL_CHAINID] = networkConfig;

    return networkConfig;
}


    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (chainId == LOCAL_CHAINID) {
            return getOrCreateAnvilEthConfig();
        }
        if (networkConfigMapping[chainId].wallet != address(0)) {
            // Check if config exists
            return networkConfigMapping[chainId];
        }
        revert("HelperConfig__InvalidChainId()");
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }
}
