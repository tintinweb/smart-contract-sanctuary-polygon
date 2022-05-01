/**
 *Submitted for verification at polygonscan.com on 2022-04-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Inspired from https://cryptomarketpool.com/create-a-crypto-faucet-using-a-solidity-smart-contract/
contract faucet {
	
    address public owner;
    uint public amountAllowed = 100000000000000000; // 0.1 MATIC
    uint public lockTime = 1 hours;

    mapping(address => uint) public lockTimeMapping;

	constructor() public payable {
		owner = msg.sender;
	}

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _; 
    }

    modifier onlyMumbaiPolygonTestnet {
        require(block.chainid == 80001, "Only Mumbai Polygon Testnet is supported.");
        _; 
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function setAmountallowed(uint _amountAllowed) public onlyOwner {
        amountAllowed = _amountAllowed;
    }

    function setLockTime(uint _lockTime) public onlyOwner {
        lockTime = _lockTime;
    }

    function getBalance() public onlyOwner view returns (uint256) {
        return address(this).balance;
    }

	function donateToFaucet() public payable onlyMumbaiPolygonTestnet {}


    function requestTokens(address payable _requestor) public onlyMumbaiPolygonTestnet {
        require(block.timestamp > lockTimeMapping[msg.sender], "lock time has not expired. Please try again later");
        require(address(this).balance > amountAllowed, "Not enough funds in the faucet. Please donate");

        _requestor.transfer(amountAllowed);        
 
        lockTimeMapping[msg.sender] = block.timestamp + 1 days;
    }
}