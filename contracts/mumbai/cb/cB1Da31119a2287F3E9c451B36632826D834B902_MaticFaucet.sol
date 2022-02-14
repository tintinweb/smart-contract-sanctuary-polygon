//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MaticFaucet {
	
    //state variable to keep track of owner and amount of MATIC to dispense
    address public owner;
    uint public amountAllowed = 10000000000000000;
    bool public paused = false;
    uint public timeOut = 60;


    //mapping to keep track of requested tokens
    mapping(address => uint) public lockTime;

    //constructor to set the owner
	constructor() payable {
		owner = msg.sender;
	}

    //function modifier
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _; 
    }

    //modifier to check if the contract is paused
    modifier checkPaused {
        require(!paused, "Faucet is paused.");
        _;
    }

    //modifier to check if the caller is a contract
    modifier callerIsUser {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    //function to change the owner.  Only the owner of the contract can call this function
    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    //function to set the amount allowable to be claimed. Only the owner can call this function
    function setAmountallowed(uint newAmountAllowed) public onlyOwner {
        amountAllowed = newAmountAllowed;
    }

    //function to set the time out for the tokens. Only the owner can call this function
    function setTimeOut(uint newTimeOut) public onlyOwner {
        timeOut = newTimeOut;
    }

    //function to donate funds to the faucet contract
	function donateTofaucet() public payable {
	}

    //function to send tokens from faucet to an address
    function requestTokens(address payable _requestor) public payable checkPaused callerIsUser {
        require(block.timestamp > lockTime[msg.sender], "lock time has not expired. Please try again later");
        require(address(this).balance > amountAllowed, "Not enough funds in the faucet. Please donate");
        require(address(msg.sender).balance < 50000000000000000, "You have too much MATIC");
        _requestor.transfer(amountAllowed);        
        lockTime[msg.sender] = block.timestamp + timeOut;
    }
}