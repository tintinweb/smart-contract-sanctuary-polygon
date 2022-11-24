//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Alert3{
    string public alert;

    function getAlert() external view returns(string memory){
        return alert;
    }
}