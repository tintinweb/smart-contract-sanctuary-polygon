/**
 *Submitted for verification at polygonscan.com on 2023-04-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Simple_Wallet{
    address public owner;
    mapping(address => uint256) public balance;

    event Deposited(address indexed depositor , uint256 value );
    event Withdrawal(uint256 value);

    constructor(){
        owner = msg.sender;
    }

    function deposit() external payable {
        balance[msg.sender] += msg.value;
        emit Deposited(msg.sender , msg.value);
    } 

    function withdraw() external {
        require(msg.sender == owner,"You are not the Owner");
        uint256 amount = address(this).balance;
        payable(owner).transfer(amount);
        emit Withdrawal(amount);
    }

}