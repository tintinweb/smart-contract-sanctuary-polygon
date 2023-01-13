/**
 *Submitted for verification at polygonscan.com on 2023-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Owner{
    address private admin;
    uint256 private balance;

    mapping(address => uint256) private saldos;

    event DepositCreated(address indexed _to, uint256 indexed _amount);

    constructor(){
        admin = msg.sender;
    }

    modifier onlyOwner{
        msg.sender == admin;
        _;
    }

    function pagar()public payable onlyOwner{

        balance += msg.value;

        emit DepositCreated(admin, msg.value);
    }
}