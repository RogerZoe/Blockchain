// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";
import {Attack} from "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;
    address public user = address(100);

    function setUp() public {
        counter = new Counter();
    }

    function testDeposit() public {
        uint256 initialBalance = address(counter).balance;
        uint256 depositAmount = 1 ether;

        vm.deal(user, depositAmount);
        vm.prank(user);
        counter.deposit{value: depositAmount}();

        console.log(
            "Contract balance:",
            address(counter).balance / 1e18,
            "ETH"
        );
        assertEq(address(counter).balance, initialBalance + depositAmount);
    }

    function testWithdraw() public {
        uint256 depositAmount = 1 ether;

        vm.deal(user, depositAmount);
        vm.startPrank(user);
        counter.deposit{value: depositAmount}();

        uint256 initialBalance = user.balance;
        console.log(
            "User balance before withdraw:",
            initialBalance / 1e18,
            "ETH"
        );

        counter.withdraw();

        console.log("User balance after withdraw:", user.balance / 1e18, "ETH");
        console.log(
            "Contract balance after withdraw:",
            address(counter).balance / 1e18,
            "ETH"
        );

        assertEq(user.balance, initialBalance + depositAmount);
        assertEq(address(counter).balance, 0);
        vm.stopPrank();
    }
}

contract AttackTest is Test {
    Counter public counter;
    Attack public att;
    address public hacker = address(899); // Changed from address(1)

    function setUp() public {
        counter = new Counter();
        vm.prank(hacker);
        att = new Attack(address(counter));
    }

    function testReentrancyAttack() public {
        address user1 = address(199);
        address user2 = address(299);

        // Fund users and deposit to counter
        vm.deal(user1, 3 ether);
        vm.deal(user2, 5 ether);

        vm.prank(user1);
        counter.deposit{value: 3 ether}();

        vm.prank(user2);
        counter.deposit{value: 5 ether}();

        assertEq(address(counter).balance, 8 ether);

        uint256 hackerInitialBalance = hacker.balance;
        console.log(hacker.balance);
        console.log(
            "Hacker initial balance:",
            hackerInitialBalance / 1e18,
            "ETH"
        );

        // Fund the Attack contract
        vm.deal(address(att), 1 ether);
        console.log(
            "Attack contract balance after funding:",
            address(att).balance / 1e18,
            "ETH"
        );

        console.log("=== Executing attack ===");
        vm.prank(hacker);
        att.attack();

        console.log("=== Withdrawing stolen funds ===", hacker.balance);
        vm.prank(hacker);

        uint256 hackerProfit = hacker.balance - hackerInitialBalance;
        console.log("Hacker profit:", hackerProfit / 1e18, "ETH");

        assertGt(hackerProfit, 1 ether, "Hacker should profit more than 1 ETH");
        assertEq(address(counter).balance, 0, "Counter should be drained");
    }
}
