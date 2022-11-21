/**
 *Submitted for verification at polygonscan.com on 2022-11-20
*/

// File: vv.sol


pragma solidity >=0.8.0;

contract bank_account{

    mapping(address => uint) public user_balance;
    mapping(address => bool) public is_user;

    function create_account() public {
        require(is_user[msg.sender] == false, "Account already exist");
        is_user[msg.sender] = true;
    }

    function deposit(uint256 amount) public payable {
        require(is_user[msg.sender],"User Account Not Found");
        require(msg.value>=amount,"not enough money sent");
        user_balance[msg.sender] += amount;  
    }

    function withdraw(uint256 amount) public payable {
        require(is_user[msg.sender],"User Account Not Found");
        require(user_balance[msg.sender]>=amount,"You don't have enough balance to withdraw");
        require(payable(msg.sender).send(amount));
        user_balance[msg.sender] -= amount; 
    }
}