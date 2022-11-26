//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Alert1{
    string public alert;

    function initialize(string memory _alert) external returns(string memory) {
        alert = _alert;
        return alert;
    }
}