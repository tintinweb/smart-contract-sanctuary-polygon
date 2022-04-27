/**
 *Submitted for verification at polygonscan.com on 2022-04-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Message {
    string private message;

    event messageChanged(string _msg);

    function get_message() external view returns(string memory) {
        return message;
    }

    function set_message(string memory _msg) public {
        message = _msg;
        emit messageChanged(_msg);
    }
}