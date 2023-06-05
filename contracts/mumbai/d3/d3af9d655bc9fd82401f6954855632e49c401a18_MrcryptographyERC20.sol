/**
 *Submitted for verification at polygonscan.com on 2023-06-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract MrcryptographyERC20 {

    string name = "MrcryptographyERC20";
    uint256 immutable maxTotalSupply = 10;

    function setName(string memory newName) public  {
    name = newName;
}

    function getName () public returns (string memory) {
        return name;

    }
}