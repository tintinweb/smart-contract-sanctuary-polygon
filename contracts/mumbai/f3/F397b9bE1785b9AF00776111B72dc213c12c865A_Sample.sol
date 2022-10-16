/**
 *Submitted for verification at polygonscan.com on 2022-10-14
*/

// Sources flattened with hardhat v2.12.0 https://hardhat.org

// File contracts/Sample.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

contract Sample {
    uint public myNumber = 8;

    function changeNumber(uint a) external {
        myNumber = a;
    }

    function getNumber() external view returns(uint) {
        return myNumber;
    }
}