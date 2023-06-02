// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Increment {
    string public message;

    constructor() {
        message = "";
    }

    function store_message(string memory _message) public{
        message = _message;
    }

    function get_message() public view returns (string memory){ 
        return message;
    }
    
}