// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract C2 {
    function printTxOrginal() external view returns (address) {
        return tx.origin;
    }
}