/**
 *Submitted for verification at polygonscan.com on 2023-02-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract MyContract {
    function getRandom() external view returns(uint256){
        return block.prevrandao;
    }
}