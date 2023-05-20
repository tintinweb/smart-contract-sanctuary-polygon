/**
 *Submitted for verification at polygonscan.com on 2023-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SimpleContract {
    uint256 number;
    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function."
        );
        _;
    }

    function setNumber(uint256 _number) public onlyOwner {
        number = _number;
    }

    function getNumber() public view returns (uint256) {
        return number;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}