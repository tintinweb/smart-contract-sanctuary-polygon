/**
 *Submitted for verification at polygonscan.com on 2022-09-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Hello {
    string private _msg;

    event MessageChanged(
        string indexed msg
    );

    function setMessage(string memory message) external {
        _msg = message;
        emit MessageChanged(message);
    }

    function getMessage() external view returns(string memory) {
        return _msg;
    }
}