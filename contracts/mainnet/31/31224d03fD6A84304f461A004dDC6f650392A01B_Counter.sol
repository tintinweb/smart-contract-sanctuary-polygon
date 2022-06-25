/**
 *Submitted for verification at polygonscan.com on 2022-06-25
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Counter{
    uint256 public count = 0 ;

    function increment() public returns(uint256){
        count+=1;
        return count;
    }
}