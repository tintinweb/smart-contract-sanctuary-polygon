/**
 *Submitted for verification at polygonscan.com on 2023-07-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Lock {
    uint public unlockDuration;

    mapping (address => uint) unlockTimes;
    mapping (address => uint) balances;

    address payable public owner;

    event Withdrawal(uint amount, uint when);

    constructor(uint _unlockDuration) payable {
        require(
            _unlockDuration > 0,
            "Unlock time should be in the future"
        );

        unlockDuration = _unlockDuration;
        owner = payable(msg.sender);
        unlockTimes[owner] = block.timestamp + unlockDuration;
        balances[msg.sender] = msg.value;
    }

    receive() external payable {
        unlockTimes[msg.sender] = block.timestamp + unlockDuration;
        balances[msg.sender] += msg.value;
    }

    function deposit() public payable {
        unlockTimes[msg.sender] = block.timestamp + unlockDuration;
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        require(block.timestamp >= unlockTimes[msg.sender], "You can't withdraw yet");

        emit Withdrawal(address(this).balance, block.timestamp);

        payable(msg.sender).transfer(balances[msg.sender]);
        balances[msg.sender] = 0;
    }

    fallback() external payable {
        balances[msg.sender] += msg.value;
    }
}