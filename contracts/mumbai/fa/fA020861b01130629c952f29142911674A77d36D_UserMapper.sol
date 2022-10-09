/**
 *Submitted for verification at polygonscan.com on 2022-10-09
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract UserMapper {
    mapping(address => string) private ipfsBases;

    function updateRootDirectory(string calldata _rootDirData) external {
        ipfsBases[msg.sender] = _rootDirData;
    }

    function userRoot() public view returns (string memory) {
        return ipfsBases[msg.sender];
    }
}