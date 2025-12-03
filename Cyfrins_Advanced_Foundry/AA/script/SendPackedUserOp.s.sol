// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract SendPackedUserOp is Script {
    using MessageHashUtils for bytes32;

    uint256 constant ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    function run() public {} // Entry point for script execution, empty for now

    function generatedSignedUserOperation(bytes memory callData, HelperConfig.NetworkConfig memory config,address minimalAccount)
        public
        returns (PackedUserOperation memory)
    {
        // 1. Generate the unsigned data
        uint256 nonce = vm.getNonce(minimalAccount)-1;
        PackedUserOperation memory userOp = _generateUnsignedUserOperation(callData, minimalAccount, nonce);

        // 2. get the userOpHash
        bytes32 userOpHash = IEntryPoint(config.entrypoint).getUserOpHash(userOp);
        bytes32 digest = userOpHash.toEthSignedMessageHash();

        //    3. sign it
        uint8 v;
        bytes32 r;
        bytes32 s;

        if (block.chainid == 31337) {
            // Local Anvil chain ID
            // Use the known Anvil private key for signing on the local chain
            (v, r, s) = vm.sign(ANVIL_DEFAULT_KEY, digest);
        } else {
            // For testnets (e.g., Sepolia), use the account from config (e.g., BURNER_WALLET).
            // Foundry will use the private key associated with this address (e.g., from .env via vm.startBroadcast).
            (v, r, s) = vm.sign(config.wallet, digest);
        }
        userOp.signature = abi.encodePacked(r, s, v);
        return userOp;
    }

    function _generateUnsignedUserOperation(bytes memory callData, address sender, uint256 nonce)
        internal
        returns (PackedUserOperation memory packedUserOp)
    {
        uint128 verificationGasLimit = 16_777_216;
        uint128 callGasLimit = verificationGasLimit;

        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;

        bytes32 accountGasLimits = bytes32((uint256(verificationGasLimit) << 128) | uint256(callGasLimit)); //  adding two 128 bit values , Because ERC-4337 V2 aims to reduce calldata size for efficiency. Packing two gas fields into one 32-byte slot means: It’s basically “bit-level Tetris” to make the userOp cheaper and more compact.
        bytes32 gasFees = bytes32((uint256(maxFeePerGas) << 128) | uint256(maxPriorityFeePerGas));

        packedUserOp = PackedUserOperation({
            sender: sender,
            nonce: nonce,
            initCode: bytes(""),
            callData: callData,
            accountGasLimits: accountGasLimits,
            preVerificationGas: 0,
            gasFees: gasFees,
            paymasterAndData: bytes(""),
            signature: bytes("")
        });
    }
}
