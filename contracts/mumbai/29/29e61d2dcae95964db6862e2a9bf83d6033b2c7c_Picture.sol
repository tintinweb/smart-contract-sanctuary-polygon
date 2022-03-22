/**
 *Submitted for verification at polygonscan.com on 2022-03-22
*/

// SPDX-License-Identifier: None

// Specifies the version of Solidity, using semantic versioning.
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma
pragma solidity >=0.8.9;
contract Picture{
    mapping (uint => string) pic;
    uint x=0;
    address owner;
    constructor (){
        owner = msg.sender;
    }
    function save(string memory s) public{
        require(msg.sender == owner);
        pic[x]=s;
        x++;
    }

    function getpic(uint256 i) public view returns (string memory) {
        require(msg.sender == owner);
        return pic[i];
    }
}