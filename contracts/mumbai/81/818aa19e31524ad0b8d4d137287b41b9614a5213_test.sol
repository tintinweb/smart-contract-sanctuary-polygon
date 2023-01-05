/**
 *Submitted for verification at polygonscan.com on 2023-01-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

contract  test{
    address public owner = msg.sender;
     
    string public sayhi="Hello";

    function transferOwner(address newOwner) public{
        require(owner==msg.sender,"You are not the Owner");
        require(newOwner != address(0),"Enter a Valid address");
        owner=newOwner;

    }
}