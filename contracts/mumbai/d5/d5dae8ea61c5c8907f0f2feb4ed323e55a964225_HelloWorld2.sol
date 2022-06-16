/**
 *Submitted for verification at polygonscan.com on 2022-06-15
*/

//SPDX-License-Identifier:GPL-3.0

pragma solidity ^0.8.7;

contract HelloWorld2 {
    string public name;

    function set(string memory _name) public {
        name = _name;
    }

    function get() public view returns (string memory) {
        return name;
    }
}