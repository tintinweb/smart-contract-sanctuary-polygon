/**
 *Submitted for verification at polygonscan.com on 2023-05-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract BerenuEh {

    uint256 counter = 0;

    function getCounter() external view returns (uint256) {
        return counter;
    }

    function setCounter() external {
        counter = counter + 1;
    }
}