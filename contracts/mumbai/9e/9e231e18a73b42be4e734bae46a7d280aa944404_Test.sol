/**
 *Submitted for verification at polygonscan.com on 2022-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Test{
    uint64 private constant multiplier = 0x5DEECE66D;
    uint64 private constant addend = 0xB;
    uint64 private constant mask = (1 << 48) - 1;

    function random(uint64 bound) public pure returns(uint64){
        uint64 r = next(31);
        uint64 m = bound - 1;
        if ((bound & m) == 0)  // i.e., bound is a power of 2
            r = (bound * r) >> 31;
        else {
            for (uint64 u = r;u - (r = u % bound) + m < 0;){
                u = next(31);
            }
        }
        return r;
    }

    function initialScramble(uint64 seed) public pure returns(uint64){
        return (seed ^ multiplier) & mask;
    }

    function next(uint64 bits) public pure returns(uint64){
        uint64 nextseed = ((initialScramble(1) * multiplier) & 0xffffffffffffffff + addend) & mask;
        return nextseed >> (48 - bits);
    }
}