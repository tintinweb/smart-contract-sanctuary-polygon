/**
 *Submitted for verification at polygonscan.com on 2023-02-13
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

contract Subgraph {
    event Update(bytes);

    address private immutable owner;

    constructor() {
        owner = msg.sender;
    }

    function update(bytes memory data) external {
        require(msg.sender == owner, "owner");
        emit Update(data);
    }
}