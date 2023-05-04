/**
 *Submitted for verification at polygonscan.com on 2023-05-03
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

// Cada vez que Belen diga Eeehh... Chupito!!
contract Chupito {
    uint256 counter;

    function getCounter() external view returns (uint256) {
        return counter;
    }

    function setCounter() external {
        counter += 1;
    }
}