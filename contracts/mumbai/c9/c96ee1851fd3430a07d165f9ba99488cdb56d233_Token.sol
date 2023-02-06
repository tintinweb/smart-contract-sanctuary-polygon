/**
 *Submitted for verification at polygonscan.com on 2023-02-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TokenFactory {
    address[] public createdTokens;

 

    function getToken(uint256 index) public view returns (address) {
        return address(createdTokens[index]);
    }
}

contract Token {
    string public name;
    string public symbol;

    constructor(string memory _name, string memory _symbol) public {
        name = _name;
        symbol = _symbol;
    }
}