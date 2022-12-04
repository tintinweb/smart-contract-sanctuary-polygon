/**
 *Submitted for verification at polygonscan.com on 2022-12-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract Nonce {
    event NonceIncreased(uint newNonce);
    uint256 public nonce;
    constructor () {
        nonce = 0;
    }
    function increaseNonce() public {
        nonce++;
    }
}