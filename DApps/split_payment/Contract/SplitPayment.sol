// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SimpleSplitPayment {
    
    struct Expense {
        string description;
        uint256 amount;
        address payer;
        address[] splitters;
        mapping(address => bool) hasPaid;
        uint256 paidCount;
        bool isCompleted;
    }
    
    uint256 public expenseCounter;
    mapping(uint256 => Expense) public expenses;
    
    event ExpenseCreated(uint256 indexed id, string description, uint256 amount, address indexed payer);
    event ExpenseSettled(uint256 indexed id, address indexed settler, uint256 share);
    event ExpenseCompleted(uint256 indexed id);
    
    // Create expense and split equally
    function createExpense(
        string memory _description,
        address[] memory _splitters
    ) external payable returns (uint256) {
        require(msg.value > 0, "Send ETH for expense");
        require(_splitters.length > 0, "Add splitters");
        
        uint256 expenseId = expenseCounter;
        expenseCounter++; // Increment after assigning
        
        Expense storage expense = expenses[expenseId];
        
        expense.description = _description;
        expense.amount = msg.value;
        expense.payer = msg.sender;
        expense.splitters = _splitters;
        
        // Mark payer as paid (they already paid the full amount)
        expense.hasPaid[msg.sender] = true;
        expense.paidCount = 1; // Payer counts as 1
        
        emit ExpenseCreated(expenseId, _description, msg.value, msg.sender);
        return expenseId;
    }

    
    // Pay your share of the expense
    function payShare(uint256 _expenseId) external payable {
        Expense storage expense = expenses[_expenseId];
        require(expense.amount > 0, "Expense doesn't exist");
        require(!expense.hasPaid[msg.sender], "Already paid");
        require(!expense.isCompleted, "Expense already completed");
        
        // Calculate equal share
        uint256 share = expense.amount / (expense.splitters.length + 1); // +1 for payer
        require(msg.value == share, "Wrong amount");
        
        expense.hasPaid[msg.sender] = true;
        expense.paidCount++;
        
        // Send to original payer
        payable(expense.payer).transfer(msg.value);
        
        emit ExpenseSettled(_expenseId, msg.sender, share);
        
        // Check if all paid
        if (expense.paidCount == (expense.splitters.length + 1)) {
            expense.isCompleted = true;
            emit ExpenseCompleted(_expenseId);
        }
    }
    
    // View functions
    function getExpenseDetails(uint256 _expenseId) external view returns (
        string memory description,
        uint256 amount,
        address payer,
        uint256 shareAmount,
        bool hasPaid
    ) {
        Expense storage expense = expenses[_expenseId];
        require(expense.amount > 0, "Expense doesn't exist");
        
        uint256 share = expense.amount / (expense.splitters.length + 1);
        bool userHasPaid = expense.hasPaid[msg.sender];
        
        return (
            expense.description,
            expense.amount,
            expense.payer,
            userHasPaid ? 0 : share, // Return 0 if user has already paid
            userHasPaid
        );
    }
    
    function getSplitters(uint256 _expenseId) external view returns (address[] memory) {
        return expenses[_expenseId].splitters;
    }
    
    function getPaymentStatus(uint256 _expenseId, address _user) external view returns (bool) {
        return expenses[_expenseId].hasPaid[_user];
    }
    
    function getExpenseStatus(uint256 _expenseId) external view returns (bool) {
        return expenses[_expenseId].isCompleted;
    }
    
    function getTotalParticipants(uint256 _expenseId) external view returns (uint256) {
        return expenses[_expenseId].splitters.length + 1;
    }
}
