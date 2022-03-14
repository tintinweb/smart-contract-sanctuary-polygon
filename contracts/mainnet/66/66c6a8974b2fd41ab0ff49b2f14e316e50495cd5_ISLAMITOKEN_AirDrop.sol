/**
 *Submitted for verification at polygonscan.com on 2022-03-14
*/

/**
 *Submitted for verification at polygonscan.com on 2021-09-05
*/

// SPDX-License-Identifier: MIT


// ISLAMITOKEN AirDrop Official smart contract


pragma solidity ^0.8.4;

contract ISLAMITOKEN_AirDrop {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}