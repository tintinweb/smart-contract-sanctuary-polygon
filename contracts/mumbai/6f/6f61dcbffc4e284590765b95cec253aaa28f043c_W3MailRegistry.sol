/**
 *Submitted for verification at polygonscan.com on 2022-08-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract W3MailRegistry {

    mapping(address => mapping(uint256 => string)) private emailRegistry;
    mapping(address => uint256) private userIndex;

    function setEmail(string memory _email, address to) public {
     //   require(msg.sender == wnsRegistry.getWnsAddress("_w3mailRegistrar"));
        uint256 _userIndex = userIndex[to];
        emailRegistry[to][_userIndex] = _email;
        userIndex[to] = _userIndex + 1;
    }



}