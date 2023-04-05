/**
 *Submitted for verification at polygonscan.com on 2023-04-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.5.17;

contract MessageEmitter {
    event OwnerMessage(string messageText);

    address owner;
    uint256[] public someList;

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can emit event!");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function emitMessage(string calldata messageText) external onlyOwner {
        emit OwnerMessage(messageText);
    }

    function updateListLength(uint256 l) external {
        someList.length = l;
    }

    function updateList(uint256 i, uint256 val) external {
        someList[i] = val;
    }
}