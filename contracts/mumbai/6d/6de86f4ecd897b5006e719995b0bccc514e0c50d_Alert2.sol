//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Alert2{
    string public alert;

    function setAlert() external{
        alert = "setting alert";
    }
}