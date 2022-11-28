/**
 *Submitted for verification at polygonscan.com on 2022-11-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract dayTwentyFive {

    enum House {SMALL, MEDIUM, LARGE}

    House _variable;

    function setLarge() public {
        _variable = House.LARGE; // setting value to declared variable
    }

    function getChoice() public view returns(House){
        return _variable; // returning variable's value
    }

}