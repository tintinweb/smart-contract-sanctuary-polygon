// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Contract {

    address public owner;
    
    struct accountData {
        uint balance;
        uint releaseTime;
    }

    constructor () payable {
        owner = msg.sender;
    }

    mapping (address => accountData) accounts;

    event depositMade(uint value, address player);
    event withdrawMade(uint value, address player);

    function deposit() external payable returns (uint) {
        require(msg.value > 0.1 ether);
        accounts[msg.sender].balance += msg.value;
        accounts[msg.sender].releaseTime = block.timestamp + 100 days;
        emit depositMade(msg.value, msg.sender);
        return accounts[msg.sender].balance;

    }

    function withdraw() payable external {
        require(accounts[msg.sender].releaseTime < block.timestamp, "The challenge isn't over!");
        require(accounts[msg.sender].balance > 0, "You don't have balance");
        payable(msg.sender).transfer(accounts[msg.sender].balance);
        accounts[msg.sender].releaseTime = 0;
        accounts[msg.sender].balance = 0;
        emit withdrawMade(msg.value, msg.sender);
    }

    function balance() public view returns (uint) {
        return (accounts[msg.sender].balance)/1000000000000000000;
    }

    function releaseTime() public view returns (uint) {
	    return (accounts[msg.sender].releaseTime - block.timestamp)/86400;
    }
}