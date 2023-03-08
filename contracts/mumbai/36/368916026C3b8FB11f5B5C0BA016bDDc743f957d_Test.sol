// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract Test {
    address public immutable owner = msg.sender;
    string public name;

    constructor(string memory _name) {
        name = _name;
    }

    function setName(string calldata _name) external {
        require(msg.sender == owner, "Only owner!");

        name = _name;
    }
}