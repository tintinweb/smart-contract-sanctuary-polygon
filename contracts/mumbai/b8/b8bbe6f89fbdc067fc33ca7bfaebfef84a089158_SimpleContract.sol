/**
 *Submitted for verification at polygonscan.com on 2023-01-13
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract SimpleContract {
    uint storedData;

    function setStoredData(uint x) public {
        storedData = x;
    }

    function getStoredData() public view returns(uint) {
        return storedData;
    }
}