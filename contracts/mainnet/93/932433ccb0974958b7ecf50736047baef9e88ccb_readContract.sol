/**
 *Submitted for verification at polygonscan.com on 2022-03-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract readContract{
    uint tt=0;

    function readVariable() public view returns (uint){
        return tt;
    }

    function add1() public returns (uint){
        tt += 1;
        return tt;
    }
//        function retrieve() public view returns (uint256){
//        return number;
//    }
}