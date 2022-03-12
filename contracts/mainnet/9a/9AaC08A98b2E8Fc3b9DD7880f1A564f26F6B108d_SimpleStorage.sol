/**
 *Submitted for verification at polygonscan.com on 2022-03-12
*/

//SPDX-License-Identifier:MIT
pragma solidity >=0.8.0 <0.9.0;
contract SimpleStorage {
    mapping (address => string) public userName;
    mapping (address => uint256) public amout;
    function createNewUser(string memory _userName , uint256 _amout) public{
        userName[msg.sender] = _userName;
        amout[msg.sender] = _amout;
    }
}