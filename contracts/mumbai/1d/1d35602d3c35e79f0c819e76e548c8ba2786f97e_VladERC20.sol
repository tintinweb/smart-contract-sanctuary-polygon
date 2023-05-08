/**
 *Submitted for verification at polygonscan.com on 2023-05-07
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract VladERC20 {
    string name;
    uint256 public immutable totalSupply; // public generaría automáticamente el getter

    constructor() {
        totalSupply = 10000000;
        name = "VladToken";
    }

    function getName() external view returns (string memory){
        return name;
    }

    function setName(string memory _name) external {
        name = _name;
    }
}