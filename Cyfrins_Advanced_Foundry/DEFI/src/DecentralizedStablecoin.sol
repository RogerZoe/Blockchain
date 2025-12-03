// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DecentralizedStablecoin is ERC20Burnable, Ownable {
    error AmountMustBeGreaterThanZero();
    error InsufficientBalance();
    error NotAValidAddress();

    constructor() ERC20("Decentralized Stablecoin", "DSC") Ownable(msg.sender) {}

    // this function will used to burn tokens, burning  the tokens means removing the tokens from the total supply
    function burn(uint256 amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (amount <= 0) {
            revert AmountMustBeGreaterThanZero();
        } else if (amount > balance) {
            revert InsufficientBalance();
        }
        _burn(msg.sender, amount);
    }

    // this function  will used to mint tokens, minting means adding tokens to the total supply
    function mint(address to, uint256 amount) external onlyOwner returns (bool) {
        if (to == address(0)) {
            revert NotAValidAddress();
        } else if (amount <= 0) {
            revert AmountMustBeGreaterThanZero();
        }
        _mint(to, amount);
        return true;
    }
}
