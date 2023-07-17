/**
 *Submitted for verification at polygonscan.com on 2023-07-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


contract counter {

    uint private count = 0;

    event Increase(uint indexed count);

    function increase() public {
        require(msg.sender == 0xb73071a9bF7FEdeE99483b77a5Fd54468a149114);
        count++;
        emit Increase(count);
    }

    function getCount() public view returns(uint) {
        return count;
    }
}