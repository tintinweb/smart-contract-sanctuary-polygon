/**
 *Submitted for verification at polygonscan.com on 2022-07-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract GenerateKey {
    function _getPositionKey(address user, bytes32 productId, address currency, bool isLong) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(user, productId, currency, isLong));
    }
}