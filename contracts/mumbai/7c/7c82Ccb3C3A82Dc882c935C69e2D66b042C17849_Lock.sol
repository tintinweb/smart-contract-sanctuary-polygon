// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Lock {
    uint public unlockTime;
    address payable public owner;
    mapping(uint => address) public TimeToOwner;

    event Withdrawal(uint amount, uint when);

    constructor(uint _unlockTime) {
       

        unlockTime = _unlockTime;
        owner = payable(msg.sender);
        TimeToOwner[_unlockTime] = msg.sender;
    }

    function withdraw() public {
        // Uncomment this line, and the import of "hardhat/console.sol", to print a log in your terminal
        // console.log("Unlock time is %o and block timestamp is %o", unlockTime, block.timestamp)

        owner.transfer(address(this).balance);
    }
}