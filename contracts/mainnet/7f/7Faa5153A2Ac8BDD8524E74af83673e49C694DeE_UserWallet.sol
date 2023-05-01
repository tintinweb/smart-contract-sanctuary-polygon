// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract UserWallet {
    mapping(address => uint256) private _balances;

    function deposit() public payable {
        require(msg.value > 0, "Deposit amount should be greater than zero.");
        _balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public {
        require(amount > 0, "Withdrawal amount should be greater than zero.");
        require(amount <= _balances[msg.sender], "Insufficient balance.");
        
        _balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function balance() public view returns (uint256) {
        return _balances[msg.sender];
    }
}