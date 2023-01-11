// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 *  - Number smart contract.
 *      - Keeps track of a single number.
 *      - Folks can come in and increment that number.
 */

contract MyContract {

    uint256 public number;
    address public deployer;

    event NumberIncremented(uint256 newValue, address user);

    constructor(uint256 _startingNumber) {
        number = _startingNumber;
        deployer = msg.sender;
    }

    function incrementNumber() external {
        number += 1;
        emit NumberIncremented(number, msg.sender);
    }

    function setNumber(uint256 _newNumber) external {
        require(msg.sender == deployer, "Sorry you're not the deployer!");
        number = _newNumber;
    }
}