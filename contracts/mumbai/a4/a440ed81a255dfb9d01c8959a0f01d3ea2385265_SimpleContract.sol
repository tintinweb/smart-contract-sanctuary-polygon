/**
 *Submitted for verification at polygonscan.com on 2023-01-14
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract SimpleContract {
    // storedData - 0
    // storedData = 4
    uint storedData;

    function setStoredData(uint x) public {
        storedData = x;
    }

    function getStoredData() public view returns (uint) {
        return storedData;
    }
}