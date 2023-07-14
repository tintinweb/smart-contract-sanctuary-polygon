/**
 *Submitted for verification at polygonscan.com on 2023-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Hello{

    string public name = "Hello world";

    function setname(string memory _name) public returns(bool){
            name = _name;
            return true;
    }


}