//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Fallback contract accepts all inputs. Used for unit testing routing contracts.
 */
contract Fallback {
    fallback() external {}
}