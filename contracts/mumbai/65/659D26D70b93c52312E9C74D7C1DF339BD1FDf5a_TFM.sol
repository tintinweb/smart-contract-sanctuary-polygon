// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract TFM {
    //save each user balance
    mapping(address => uint256) public balances;

    //events
    event Deposited(address indexed account, uint256 amount, uint256 balance);
    event Withdrawn(address indexed account, uint256 amount, uint256 balance);

    //functions
    function deposit() public payable {
        require(msg.value > 0, "You need to send some Ether");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value, balances[msg.sender]);
    }

    function withdraw(uint256 _amount) public {
        uint256 amount = _amount * 1 ether;
        require(balances[msg.sender] >= amount, "Not enough funds");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawn(msg.sender, amount, balances[msg.sender]);
    }
}