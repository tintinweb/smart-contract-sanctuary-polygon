// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Counter {
    uint public value;
    address payable public owner;

    event Increased(uint newValue, uint when);

    constructor(uint _startValue) payable {
        value = _startValue;
        owner = payable(msg.sender);
    }

    function increase() public {
        require(owner == msg.sender);
        value += 1;
        emit Increased(value, block.timestamp);
    }
}