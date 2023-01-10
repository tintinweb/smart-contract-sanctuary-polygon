/**
 *Submitted for verification at polygonscan.com on 2023-01-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.12 <0.9.0;

contract GasEater {
    mapping(uint256 => uint256) public map;

    function eat(uint256 _startIndex, uint256 _size) external {
        uint border = _startIndex + _size;
        for (uint256 i = _startIndex; i < border; i++) {
            map[i] = i;
        }
    }
}