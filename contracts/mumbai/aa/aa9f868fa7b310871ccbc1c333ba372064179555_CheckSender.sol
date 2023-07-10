/**
 *Submitted for verification at polygonscan.com on 2023-07-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract CheckSender is Context {
    function getSender() external view returns(address) {
        return _msgSender();
    }
}