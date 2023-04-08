/**
 *Submitted for verification at polygonscan.com on 2023-04-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
contract Counter{
    uint256 public count=0;
    function increment() public returns(uint){
        count+=1;
        return count;
    }
}