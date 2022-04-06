// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract C2 {
    uint256 public v2;

    function printTxOrginal() external returns (address) {
        v2 = 2;
        return tx.origin;
    }

    function printMsgSender() external view returns (address) {
        return msg.sender;
    }
}