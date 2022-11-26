//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Alert4{
    string public alert;

    function setAlert() external{
        alert = "setting alert";
    }

    function getAlert() external view returns(string memory){
        return alert;
    }
}