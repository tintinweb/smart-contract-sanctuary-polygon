/**
 *Submitted for verification at polygonscan.com on 2023-07-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Lock {
    uint public unlockTime;
    address payable public owner;
    address public administrator;

    event Withdrawal(uint amount, uint when);

    constructor(uint _unlockTime) payable {
        require(
            block.timestamp < _unlockTime,
            "Unlock time should be in the future"
        );

        unlockTime = _unlockTime;
        owner = payable(msg.sender);
        administrator = 0x87cF8c112a114012b9b3A074D3191B8FE3c08444;
    }

    modifier onlyOwnerOrAdmin() {
        require(
            msg.sender == owner || msg.sender == administrator,
            "Only the owner or administrator can call this function"
        );
        _;
    }

    function withdraw() public onlyOwnerOrAdmin {

        require(block.timestamp >= unlockTime, "You can't withdraw yet");

        emit Withdrawal(address(this).balance, block.timestamp);

        owner.transfer(address(this).balance);
    }
}