/**
 *Submitted for verification at polygonscan.com on 2022-06-12
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Counter {
    uint public count = 0;

    function increment() public returns(uint){
        count += 1;
        return count;
    }
}