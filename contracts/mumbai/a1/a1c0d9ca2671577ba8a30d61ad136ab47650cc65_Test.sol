/**
 *Submitted for verification at polygonscan.com on 2022-06-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Test{
    uint private constant multiplier = 25214903917;
    uint private constant addend = 11;
    uint private constant mask = (1 << 48) - 1;

    function random(uint bound) public returns(uint){
        uint r = next(31);
        uint m = bound - 1;
        if ((bound & m) == 0)  // i.e., bound is a power of 2
            r = (bound * r) >> 31;
        else {
            for (uint u = r;u - (r = u % bound) + m < 0;){
                u = next(31);
            }
        }
        return r;
    }

    function initialScramble(uint seed) public pure returns(uint){
        return (seed ^ multiplier) & mask;
    }

    function next(uint bits) public payable returns(uint){
        uint nextseed = (initialScramble(1) * multiplier + addend) & mask;
        return nextseed >> (48 - bits);
    }
}