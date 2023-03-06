// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Lock {

    uint256 public unlockTime;
    address public owner;

    constructor(uint256 _unlockTime) payable {
        // require(unlockTime > block.timestamp, "ERR: UNLOCK_TIME ALWAYS IN FUTURE");

        unlockTime = _unlockTime;
        owner = msg.sender;
    }

    event Withdraw(uint256 unlockTime, address owner);


    function withdraw() public {
        require(block.timestamp > unlockTime, "ERR: UNLOCK TIMESTAMP NOT CROSSED YET.");
        require(msg.sender == owner,"ERR: NOT AUTHORIZED");

        payable(owner).transfer(address(this).balance);
        emit Withdraw(block.timestamp, owner);
    }
}