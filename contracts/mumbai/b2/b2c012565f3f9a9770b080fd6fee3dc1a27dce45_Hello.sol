/**
 *Submitted for verification at polygonscan.com on 2022-09-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Hello {
    string private _msg;

    event MessageChanged(
        string indexed msg,
        string msg2,
        address sender,
        uint256 number
    );

    function setMessage(string memory message) external {
        _msg = message;
        emit MessageChanged(message, message, msg.sender, 2000);
    }

    function getMessage() external view returns(string memory) {
        return _msg;
    }
}