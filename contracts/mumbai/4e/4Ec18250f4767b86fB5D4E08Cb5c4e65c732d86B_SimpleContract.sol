/**
 *Submitted for verification at polygonscan.com on 2023-01-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;


contract SimpleContract{
    uint storedData;

    function setStoredData(uint x) public {
        storedData = x;
    }

    function getStoredData() public view returns(uint) {
        return storedData;
    }
}