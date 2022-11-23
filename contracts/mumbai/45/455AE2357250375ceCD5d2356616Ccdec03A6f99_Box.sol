//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Box {
    string public alert;

    function initialize(string memory _alert) external{
        alert = _alert;
    }
}