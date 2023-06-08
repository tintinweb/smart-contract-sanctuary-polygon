// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract FunctionFrontend {

    address public deployer;

    // this function (the constructor) yields the address of the deployer of the smart contract

    constructor() {
        deployer = address(this);
    }

    // this function yields the current time when it is called
    function getCurrentTime() external view returns (uint256) {
        return block.timestamp;
    }

    // this function yields the current date when it is called
    function getCurrentDate() external view returns (uint256) {
        // with an assumption that 1 day = 86400 seconds
        uint256 currentTimestamp = block.timestamp;
        uint256 currentDate = currentTimestamp / 86400;
        return currentDate;
    }

}