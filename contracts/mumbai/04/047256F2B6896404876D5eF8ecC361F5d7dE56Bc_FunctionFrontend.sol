// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract FunctionFrontend {

    // this function returns the current time when it is called
    function getCurrentTime() external view returns (uint256) {
        return block.timestamp;
    }

    // this function returns the current date when it is called
    function getCurrentDate() external view returns (uint256) {
        // with an assumption that 1 day = 86400 seconds
        uint256 currentTimestamp = block.timestamp;
        uint256 currentDate = currentTimestamp / 86400;
        return currentDate;
    }

    // this function returns the caller's address when it is called
    function getCallerAddress() external view returns (address) {
        return msg.sender;
    }

}