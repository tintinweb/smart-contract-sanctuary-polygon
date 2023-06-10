// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

contract Logger {
    event MethodExecuted(address indexed dest, bytes params);

    function log(address dest, bytes calldata func) external {
        emit MethodExecuted(dest, func);
    }

    function see () external pure returns (bool) {
        return true;
    }
}