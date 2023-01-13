/**
 *Submitted for verification at polygonscan.com on 2023-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Exchange {
    address public ulandAddress;
    address public owner;
    mapping(address => uint256) public ulandBalance;
    mapping(address => bool) public whitelist;

    constructor() public {
        ulandAddress = 0x0000000000000000000000000000000000000000;
        owner = msg.sender;
    }
    
   // function depositULAND(address _ulandAddress, uint256 _amount) public {
        //require(_amount > 0, "Deposit amount must be greater than 0.");
        //require(address(this).balance >= _amount, "Insufficient balance in contract.");
        //require(whitelist[msg.sender], "Sender not whitelisted.");
        //ulandBalance[_ulandAddress] += _amount;
        //_ulandAddress.transfer(_amount);
        //msg.sender.transfer(msg.value);
  //  }
    
    function setUlandAddress(address _ulandAddress) public {
        require(msg.sender == owner, "Only contract owner can change ULAND address.");
        ulandAddress = _ulandAddress;
    }

    function addWhitelist(address _user) public {
        require(msg.sender == owner, "Only contract owner can add to whitelist.");
        whitelist[_user] = true;
    }

    function removeWhitelist(address _user) public {
        require(msg.sender == owner, "Only contract owner can remove from whitelist.");
        whitelist[_user] = false;
    }

    function deposit() public payable {
        require(msg.sender == owner, "Only contract owner can deposit ether.");
    }

    function withdraw(uint256 _amount) public {
        require(msg.sender == owner, "Only contract owner can withdraw ether.");
        require(address(this).balance >= _amount, "Insufficient balance in contract.");
        //owner.transfer(_amount);
    }
}