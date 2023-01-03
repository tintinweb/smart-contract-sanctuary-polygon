// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.11;

contract Vault {

    address owner;

    constructor() {
        owner = msg.sender;
    }

    function whoOwnsThis() public view returns (address) {
        return owner;
    }
}