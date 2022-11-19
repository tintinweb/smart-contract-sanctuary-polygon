//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract MyLovelyContractV1{
    string public alert;

    //no constructors for upgradeable contracts

    function initialize(string memory _alert) external {
        alert = _alert;
    }
}