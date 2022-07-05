/**
 *Submitted for verification at polygonscan.com on 2022-07-05
*/

// File: polygon_flat.sol


// File: polygon.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract polygon {

    string[] public names;

    function Addname(string memory name) public {
        names.push(name);
    }

    function Getname() public view returns(string[] memory) {
        return names;
    }
}