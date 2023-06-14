/**
 *Submitted for verification at polygonscan.com on 2023-06-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

contract CatapultL2 {
    function executeDelegateMultiCall(address target, bytes memory data) public returns(bool, bytes memory) {
        return target.delegatecall(data);
    }
}