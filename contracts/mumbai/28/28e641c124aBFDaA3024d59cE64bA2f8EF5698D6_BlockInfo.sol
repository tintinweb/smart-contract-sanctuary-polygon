// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;


contract BlockInfo {

    function difficulty() public view returns(uint256) {
        return block.difficulty;
    }
    function blockNumber() public view returns(uint256) {
        return block.number;
    }
}