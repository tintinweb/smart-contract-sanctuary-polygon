/**
 *Submitted for verification at polygonscan.com on 2022-11-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract FirstSmartContract {
    string message;

    constructor() {
        message = "Hi there! :)";
    }

    function setMessage(string calldata _message) external {
        message = _message;
    }

    function getMessage() external view returns (string memory) {
        return message;
    }
}