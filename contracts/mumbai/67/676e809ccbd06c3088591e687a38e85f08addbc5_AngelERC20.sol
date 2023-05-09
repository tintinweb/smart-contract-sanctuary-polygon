/**
 *Submitted for verification at polygonscan.com on 2023-05-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract AngelERC20 {
    string private name = "AngelERC20";
    uint256 private maxTotalSupply = 21000000;

    constructor() {
        require(maxTotalSupply > 0);
    }

    function totalSupply() public view returns (uint256) {
        return maxTotalSupply;
    }

    function setName(string memory _newName) public {
        name = _newName;
    }

    function getName() public view returns (string memory) {
        return name;
    } 
}