// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract TFM {
    //save each user balance
    mapping(address => uint256) public balances;

    //functions
    function deposit() public payable {
        require(msg.value > 0, "You need to send some Ether");
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 _amount) public {
        require(balances[msg.sender] >= _amount, "Not enough funds");
        balances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }
}