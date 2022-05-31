/**
 *Submitted for verification at polygonscan.com on 2022-05-30
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract oddCounter {
uint public count = 1;

function increment() public returns(uint) {
count += 2;
return count;
}

function decrement() public returns(uint) {
count -= 2;
return count;
}

}