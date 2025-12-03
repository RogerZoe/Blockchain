// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

// The flow for ERC-4337 typically involves an EntryPoint contract
// calling into this account contract.
contract MinimalAccount is Ownable, IAccount {
    error Transfer_Failed();
    error MinimalAccount__TransferFailed(bytes);
    error MinimalAccount__NotFromEntryPoint();
    error MinimalAccount__NotFromEntryPointOrOwner();

    IEntryPoint private immutable i_entryPoint;

    // Entrypoint
    constructor(address entrypoint) Ownable(msg.sender) {
        i_entryPoint = IEntryPoint(entrypoint); // set the entrypoint;
    }

    // this modifier checks if the sender is the entrypoint
    modifier requireFromEntryPoint() {
        if (msg.sender != address(i_entryPoint)) {
            revert MinimalAccount__NotFromEntryPoint();
        }
        _;
    }
    // this modifier checks if the sender is the entrypoint and the owner too.

    modifier requireFromEntryPointOrOwner() {
        if (msg.sender != address(i_entryPoint) && msg.sender != owner()) {
            revert MinimalAccount__NotFromEntryPointOrOwner();
        }
        _;
    }

    // Owner can call this function to validate the UserOperation
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        requireFromEntryPoint
        returns (uint256 validationData)
    {
        // steps
        //1 validate the signature , using userOpHash and userOp prove that the sender is the owner
        validationData = _ValidateSignature(userOpHash, userOp.signature);
        if (validationData != SIG_VALIDATION_SUCCESS) {
            return validationData;
        }
        // 2. validate nonce()
        // 3. Prefund check
        _preFundCheck(missingAccountFunds);
        // 4. EntryPoint restriction

        return validationData;
    }

    //  The EntryPoint only calls execute after successfully validating the UserOp (which includes signature verification).
    function execute(address dest, uint256 value, bytes calldata data) external requireFromEntryPointOrOwner {
        (bool success, bytes memory result) = dest.call{value: value}(data);
        if (!success) {
            revert MinimalAccount__TransferFailed(result);
        }
    }

    function _ValidateSignature(bytes32 userOpHash, bytes memory signature) internal view returns (uint256) {
        // convert userOpHash to bytes32
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(ethSignedMessageHash, signature);
        if (owner() != signer) {
            return SIG_VALIDATION_FAILED; // returns 1
        }
        return SIG_VALIDATION_SUCCESS; // returns 0
    }

    function _preFundCheck(uint256 missingAccountFunds) internal {
        if (missingAccountFunds != 0) {
            (bool success,) = payable(msg.sender).call{value: missingAccountFunds, gas: type(uint256).max}("");
            require(success, Transfer_Failed());
        }
    }

    ////////////////////////////////////////////
    //         Getter functions               //
    ///////////////////////////////////////////

    // To allow external contracts or off-chain services to verify which EntryPoint contract this MinimalAccount is associated with, we'll add a public getter function.
    function getEntrypoint() public view returns (address) {
        return address(i_entryPoint);
    }

    receive() external payable {}
}
