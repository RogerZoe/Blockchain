// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Split_Payment.sol";

contract SplitPaymentTest is Test {
    SplitPayment public SP;
    address public payer = makeAddr("payer");
    address public splitter1 = makeAddr("splitter1");
    address public splitter2 = makeAddr("splitter2");

    function setUp() public {
        SP = new SplitPayment();
    }

    function common_splitters() public view returns (address[] memory) {
        address[] memory splitters = new address[](2);
        splitters[0] = splitter1;
        splitters[1] = splitter2;
        return splitters;
    }

    function common_createExpense() internal returns (uint256) {
        address[] memory splitters = new address[](2);
        splitters[0] = splitter1;
        splitters[1] = splitter2;

        vm.deal(payer, 3 ether);
        vm.prank(payer);
        uint256 id = SP.createExpense{value: 3 ether}("Lunch", splitters);
        return id;
    }

    function common_getTotalAmount(uint256 id) internal view returns (uint256) {
        (, uint256 amount, , , ) = SP.expenses(id);
        return amount;
    }

    // =============== createExpense ===============
    function test_createExpense_Success() public {
        uint256 id = common_createExpense();
        (
            string memory description,
            uint256 amount,
            address payerAddr,
            uint256 paidCount,
            bool isCompleted
        ) = SP.expenses(id);

        assertEq(description, "Lunch");
        assertEq(amount, 3 ether);
        assertEq(payerAddr, payer);
        assertEq(paidCount, 1);
        assertEq(isCompleted, false);

        assertTrue(SP.getPaymentStatus(id, payer));
    }

    function test_createExpense_Revert_Eth_Not_Empty() public {
        address[] memory splitters = new address[](1);
        splitters[0] = splitter1;

        vm.deal(payer, 0 ether);
        vm.prank(payer);
        vm.expectRevert("Eth should not be empty");
        SP.createExpense{value: 0 ether}("lunch", splitters);
    }

    function test_createExpense_Revert_Empty_Splitters() public {
        address[] memory splitters = new address[](0);

        vm.deal(payer, 1 ether);
        vm.prank(payer);
        vm.expectRevert("Empty splitters");
        SP.createExpense{value: 1 ether}("lunch", splitters);
    }

    function testFuzz_createExpense_Splitters(uint256 length) public {
        vm.assume(length > 0 && length < 100);
        address[] memory splitters = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            splitters[i] = makeAddr(string(abi.encodePacked("Splitter", i)));
        }
        vm.deal(payer, 1 ether);
        vm.prank(payer);
        uint256 id = SP.createExpense{value: 1 ether}("lunch", splitters);
        assertEq(SP.getTotalParticipants(id), length + 1);
    }

    // =============== payShare ===============

    function common_payShare_AsSplitter(uint256 id, address splitter) internal {
        uint256 share = (common_getTotalAmount(id)) /
            ((common_splitters().length) + 1);
        vm.prank(splitter);
        vm.deal(splitter, share);
        SP.payShare{value: share}(id);
    }

    function test_PayShare_Success_All_paid() public {
        uint256 id = common_createExpense();
        common_payShare_AsSplitter(id, splitter1);
        common_payShare_AsSplitter(id, splitter2);

        uint256 share = (common_getTotalAmount(id)) /
            ((common_splitters().length) + 1);
        uint256 expectedBalance = common_splitters().length * share;
        assertEq(address(payer).balance, expectedBalance);

        (, , , uint256 paidCount, bool isCompleted) = SP.expenses(id);
        assertEq(paidCount, ((common_splitters().length) + 1));
        assertTrue(isCompleted);
    }

    function test_PayShare_Success_Not_Yet_Paid() public {
        uint256 id = common_createExpense();
        common_payShare_AsSplitter(id, splitter1);

        uint256 share = (common_getTotalAmount(id)) /
            ((common_splitters().length) + 1);
        assertEq(address(payer).balance, share);

        (, , , uint256 paidCount, bool isCompleted) = SP.expenses(id);
        assertLt(paidCount, ((common_splitters().length) + 1));
        assertFalse(isCompleted);
    }

    function test_PayShare_Revert_Invalid_ExpenseID() public {
        vm.expectRevert("Invalid expense ID");
        SP.payShare(999);
    }

    function test_PayShare_Revert_Already_paid() public {
        uint256 id = common_createExpense();
        common_payShare_AsSplitter(id, splitter1);

        vm.prank(splitter1);
        vm.deal(splitter1, 1 ether);
        vm.expectRevert("Already paid");
        SP.payShare{value: 1 ether}(id);
    }

    function test_PayShare_Revert_Completed_Expense() public {
        uint256 id = common_createExpense();
        common_payShare_AsSplitter(id, splitter1);
        common_payShare_AsSplitter(id, splitter2);

        address newUser = makeAddr("newUser");
        uint256 share = common_getTotalAmount(id) /
            (common_splitters().length + 1);

        vm.deal(newUser, share);
        vm.prank(newUser);
        vm.expectRevert("Expense already completed");
        SP.payShare{value: share}(id);
    }

    function test_PayShare_Revert_PayerCannotPay() public {
        uint256 id = common_createExpense(); // payer is marked paid
        uint256 share = common_getTotalAmount(id) /
            (common_splitters().length + 1);

        vm.deal(payer, share);
        vm.prank(payer);
        vm.expectRevert("Already paid");
        SP.payShare{value: share}(id);
    }

    function test_PayShare_Revert_Incorrect_Amount() public {
        uint256 id = common_createExpense();

        vm.prank(splitter1);
        vm.deal(splitter1, 0.5 ether);
        vm.expectRevert("Incorrect share amount");
        SP.payShare{value: 0.5 ether}(id);
    }

    // =============== getExpenseDetails ===============

    function common_getShareAmount(uint256 id) internal view returns (uint256) {
        uint256 totalAmount = common_getTotalAmount(id);
        uint256 totalParticipants = common_splitters().length + 1;
        return totalAmount / totalParticipants;
    }

    function test_getExpenseDetails_success_not_paid() public {
        uint256 id = common_createExpense();

        vm.prank(splitter1);
        (
            string memory description,
            uint256 amount,
            address payerAddr,
            uint256 shareAmount,
            bool hasPaid
        ) = SP.getExpenseDetails(id);

        uint256 expectedShare = common_getShareAmount(id);

        assertEq(description, "Lunch");
        assertEq(amount, 3 ether);
        assertEq(payerAddr, payer);
        assertEq(shareAmount, expectedShare);
        assertFalse(hasPaid);
    }

    function test_getExpenseDetails_success_paid() public {
        uint256 id = common_createExpense();
        common_payShare_AsSplitter(id, splitter1);

        vm.prank(splitter1);
        (
            string memory description,
            uint256 amount,
            address payerAddr,
            uint256 shareAmount,
            bool hasPaid
        ) = SP.getExpenseDetails(id);

        assertEq(description, "Lunch");
        assertEq(amount, 3 ether);
        assertEq(payerAddr, payer);
        assertEq(shareAmount, 0);
        assertTrue(hasPaid);
    }

    function test_getExpenseDetails_Revert_Invalid_ExpenseID() public {
        vm.prank(splitter1);
        vm.expectRevert("Invalid expense ID");
        SP.getExpenseDetails(999);
    }

    function test_getExpenseDetails_PayerView() public {
        uint256 id = common_createExpense();

        vm.prank(payer);
        (, , , uint256 shareAmount, bool hasPaid) = SP.getExpenseDetails(id);

        assertEq(shareAmount, 0);
        assertTrue(hasPaid);
    }

    // =============== getSplitters ===============
    function test_getSplitters_Success() public {
        uint256 id = common_createExpense();
        address[] memory splitters = SP.getSplitters(id);
        assertEq(splitters.length, 2);
        assertEq(splitters[0], splitter1);
        assertEq(splitters[1], splitter2);
    }

    function test_getSplitters_Revert_InvalidID() public {
        vm.expectRevert("Invalid expense ID");
        SP.getSplitters(999);
    }

    // =============== getPaymentStatus ===============
    function test_getPaymentStatus_Payer() public {
        uint256 id = common_createExpense();
        assertTrue(SP.getPaymentStatus(id, payer));
    }

    function test_getPaymentStatus_Splitter_NotPaid() public {
        uint256 id = common_createExpense();
        assertFalse(SP.getPaymentStatus(id, splitter1));
    }

    function test_getPaymentStatus_Splitter_AfterPaid() public {
        uint256 id = common_createExpense();
        uint256 share = (common_getTotalAmount(id)) /
            ((common_splitters().length) + 1);

        vm.deal(splitter1, share);
        vm.prank(splitter1);
        SP.payShare{value: share}(id);

        assertTrue(SP.getPaymentStatus(id, splitter1));
    }

    function test_getPaymentStatus_NonParticipant() public {
        uint256 id = common_createExpense();
        address random = makeAddr("random");
        vm.expectRevert("User not part of expense");
        SP.getPaymentStatus(id, random);
    }

    function test_getPaymentStatus_Revert_InvalidID() public {
        vm.expectRevert("Invalid expense ID");
        SP.getPaymentStatus(999, payer);
    }

    // =============== getExpenseStatus ===============
    function test_getExpenseStatus_Incomplete() public {
        uint256 id = common_createExpense();
        assertFalse(SP.getExpenseStatus(id));
    }

    function test_getExpenseStatus_Completed() public {
        uint256 id = common_createExpense();
        uint256 share = (common_getTotalAmount(id)) /
            ((common_splitters().length) + 1);

        vm.deal(splitter1, share);
        vm.prank(splitter1);
        SP.payShare{value: share}(id);

        vm.deal(splitter2, share);
        vm.prank(splitter2);
        SP.payShare{value: share}(id);

        assertTrue(SP.getExpenseStatus(id));
    }

    function test_getExpenseStatus_Revert_InvalidID() public {
        vm.expectRevert("Invalid expense ID");
        SP.getExpenseStatus(999);
    }

    // =============== getTotalParticipants ===============
    function test_getTotalParticipants() public {
        uint256 id = common_createExpense();
        assertEq(SP.getTotalParticipants(id), (common_splitters().length) + 1); // payer + 2 splitters
    }

    function test_getTotalParticipants_Revert_InvalidID() public {
        vm.expectRevert("Invalid expense ID");
        SP.getTotalParticipants(999);
    }
}
