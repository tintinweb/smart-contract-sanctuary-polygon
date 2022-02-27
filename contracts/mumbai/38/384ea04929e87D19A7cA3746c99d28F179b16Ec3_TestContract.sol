/**
 *Submitted for verification at polygonscan.com on 2022-02-26
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract TestContract {

    string internal _name;
    
    constructor() {
        _name = "Anton";
    }

    function setName(string memory name) public {
        _name = name;
    }

    function getName() public view returns(string memory) {
        return _name;
    }
}