/**
 *Submitted for verification at polygonscan.com on 2022-05-06
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


contract TEST {
    
    uint256[1000000] list;

    function getlist() public view returns (uint256[1000000] memory) {
        return list;
    }

    function getelement(uint index) public view returns (uint256) {
        return list[index];
    }

    function set(uint number, uint index) public payable {
        list[index] = number;
    }

}