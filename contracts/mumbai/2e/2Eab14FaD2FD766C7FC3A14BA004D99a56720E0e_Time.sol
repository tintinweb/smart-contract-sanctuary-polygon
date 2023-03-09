// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Time {
    function time() external view returns (uint256) {
        return block.timestamp + 1;
    }
}