/**
 *Submitted for verification at polygonscan.com on 2022-11-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.7.0;

contract SimpleStorage2 {
    uint storedData;
    uint toenData;

    function set(uint x) public {
        storedData = x;
    }

    function set2(uint y) public {
        toenData = y*2;
    }

    function get() public view returns (uint) {
        return storedData;
    }

    function get2() public view returns (uint) {
        return toenData;
    }

}