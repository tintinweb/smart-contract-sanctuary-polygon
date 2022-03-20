/**
 *Submitted for verification at polygonscan.com on 2022-03-20
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract CryptogenesEvenCounter {
uint public count = 0;

function increment() public returns(uint) {
count += 2;
return count;
}

}