// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {MinimalAccount} from "../src/Minimal.sol";
import {DeployMinimal} from "../script/Minimal.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {SendPackedUserOp, PackedUserOperation} from "../script/SendPackedUserOp.s.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract MinimalAccountTest is Test {
    using MessageHashUtils for bytes32;

    HelperConfig helperConfig;
    MinimalAccount minimalAccount;
    ERC20Mock usdc;
    SendPackedUserOp sendPackedUserOp;
    uint256 constant AMOUNT = 1e18; // Standard amount for minting (1 token with 18 decimals)
    address randomUser = makeAddr("randomUser"); // A deterministic address for non-owner tests

    function setUp() public {
        DeployMinimal deployMinimal = new DeployMinimal();
        // Deploy MinimalAccount using our deployment script
        (helperConfig, minimalAccount) = deployMinimal.deployMinimalAccount();
        // Deploy a mock USDC token for interaction
        usdc = new ERC20Mock();
        sendPackedUserOp = new SendPackedUserOp();
    }

    function testOwnerCanExecuteCommands() public {
        // steps
        // 1. Set up the minimalAccount with a USDC token
        // 2. Call the execute function
        // 3. Check the USDC balance

        assertEq(usdc.balanceOf(address(minimalAccount)), 0, "USDC balance should be 0");
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);

        vm.prank(minimalAccount.owner());
        minimalAccount.execute(dest, value, functionData);
        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT, "MinimalAccount  should have minted USDC");
    }

    function testNonOwnerCantExecuteCommands() public {
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);

        vm.prank(randomUser);
        vm.expectRevert(MinimalAccount.MinimalAccount__NotFromEntryPointOrOwner.selector);
        minimalAccount.execute(dest, value, functionData);
    }

    // Now Test for the vaildateUserOP()
    // 1. verify the signature , we need to construct a valid PackedUserOperation struct, its corresponding hash (userOpHash), and potentially any missingAccountFunds
    // 2. validate nonce()
    // 3. Prefund check

    function testRecoverSignedOp() public {
        // NOTE: this flow like EntrypointContract calling -> MinimalAccount -> USDC contract
        assertEq(usdc.balanceOf(address(minimalAccount)), 0, "USDC balance should be 0");
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        bytes memory executeCallData =
            abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);

        PackedUserOperation memory packedUserOp = sendPackedUserOp.generatedSignedUserOperation(
            executeCallData, helperConfig.getConfig(), address(minimalAccount)
        );
        bytes32 userOpHash = IEntryPoint(helperConfig.getConfig().entrypoint).getUserOpHash(packedUserOp);
        // ACT
        address actualSign = ECDSA.recover(userOpHash.toEthSignedMessageHash(), packedUserOp.signature);

        //Assert
        assertEq(actualSign, minimalAccount.owner());
    }

    function testValidationOfUserOps() public {
        // Arrange
        vm.deal(address(minimalAccount), 2e18); // <<< FUND the smart account

        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        bytes memory executeCallData =
            abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);

        PackedUserOperation memory packedUserOp = sendPackedUserOp.generatedSignedUserOperation(
            executeCallData, helperConfig.getConfig(), address(minimalAccount)
        );

        bytes32 userOperationHash = IEntryPoint(helperConfig.getConfig().entrypoint).getUserOpHash(packedUserOp);

        uint256 missingAccountFunds = 1e18;

        // Act
        vm.prank(address(helperConfig.getConfig().entrypoint));
        uint256 validationData = minimalAccount.validateUserOp(packedUserOp, userOperationHash, missingAccountFunds);

        // Assert
        assertEq(validationData, 0);
    }

    // function testEntryPointCanExecuteCommands() public {
    //     // Arrange

    //     assertEq(usdc.balanceOf(address(minimalAccount)), 0);
    //     address dest = address(usdc);
    //     uint256 value = 0;
    //     bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
    //     bytes memory executeCallData =
    //         abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);

    //     PackedUserOperation memory packedUserOp =
    //         sendPackedUserOp.generatedSignedUserOperation(executeCallData, helperConfig.getConfig(),address(minimalAccount));
    //     vm.deal(address(minimalAccount), 1e18); // <<< FUND the smart account
    //     // Before the handleOps call
    //     PackedUserOperation[] memory ops = new PackedUserOperation[](1);
    //     ops[0] = packedUserOp;

    //     // Act (continued)
    //     vm.prank(randomUser);
    //     IEntryPoint(helperConfig.getConfig().entrypoint).handleOps(ops, payable(randomUser));

    //     // Assert
    //     assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    // }

    function testEntryPointCanExecuteCommands() public {
        vm.deal(address(minimalAccount), 1e18);

        address dest = address(usdc);
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        bytes memory executeCallData = abi.encodeWithSelector(MinimalAccount.execute.selector, dest, 0, functionData);

        PackedUserOperation memory packedUserOp =
            sendPackedUserOp.generatedSignedUserOperation(executeCallData, helperConfig.getConfig(), address(minimalAccount));

        // ↓↓↓ THIS IS THE LINE YOU ADD ↓↓↓
        packedUserOp = _forceNoPrefund(packedUserOp);
        // ↑↑↑ DO THIS BEFORE CALLING handleOps() ↑↑↑

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = packedUserOp;

        vm.prank(randomUser);
        IEntryPoint(helperConfig.getConfig().entrypoint).handleOps(ops, payable(randomUser));

        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }

    function _forceNoPrefund(PackedUserOperation memory op) internal pure returns (PackedUserOperation memory) {
        // ERC-4337: missingAccountFunds becomes 0 when maxFeePerGas = maxPriorityFeePerGas = 0
        op.gasFees = bytes32(0);
        return op;
    }
}
