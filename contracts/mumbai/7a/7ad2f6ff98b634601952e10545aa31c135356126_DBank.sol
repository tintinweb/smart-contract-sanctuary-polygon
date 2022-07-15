/**
 *Submitted for verification at polygonscan.com on 2022-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DBank 
{
    address owner;
    mapping (address => string ) costomerNames;
    mapping (address => bool ) userAccounts;
    mapping (address => mapping (uint => uint)) LockTimes;
    mapping (address => uint) valueLocks;

    uint fee = 0.02 ether;

    modifier User ()
    {
        require (userAccounts [msg.sender] == true, "ERROR : msg.sender is not a user (dev : place create account)");
        _;
    }

    modifier onlyOwner ()
    {
        require (msg.sender == owner , "just owenr access this functions");
        _;
    }

    constructor ()
    {
        owner = msg.sender;
    } 

    function CreateAccount (string memory name) public
    {
        require (msg.sender != address(0),"address is zero"); // 0x0000000000000
        require (!userAccounts[msg.sender], "every one can create 1 account");

        costomerNames [msg.sender] = name;
        userAccounts [msg.sender] = true;
    }

    function Lock (uint LockTime, uint value) public payable User
    {
        uint _lockTime = block.timestamp + LockTime;

        LockTimes [msg.sender] [value] = _lockTime;

        valueLocks [msg.sender] = value;

        require (msg.value == value,"Your balance is not enough to lock");
    }

    function UnLock () public payable User 
    {
        uint valueUser = valueLocks[msg.sender];
        address userAddress = msg.sender;

        require (block.timestamp >= LockTimes[userAddress][valueUser], "Lock time is not over ");

        (bool success, ) = userAddress.call{value: valueUser - fee}(""); 
        require(success, "Transfer failed.");
        
        
    }

    function withraw () public payable onlyOwner
    {
        (bool success, ) = owner.call{value: address(this).balance}(""); //0xe2899bddFD890e320e643044c6b95B9B0b84157A == address (this)
        require(success, "Transfer failed.");
    }
}