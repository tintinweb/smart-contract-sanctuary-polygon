// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Dummy {
    address public governor;

    uint256 public fee;

    constructor(address _governor) {
        governor = _governor;
    }

    function setFees(uint256 newFee) external {
        require(msg.sender == governor);
        fee = newFee;
    }
}