// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

// In order for legacy GAO contracts to stop allowing tickets redemption,
// we had to create this fake TICKET contract and point the GAO contracts to this contract instead.
//
// As the contract does not declare any expected function nor a fallback function,
// it will just revert any transaction.

contract TICKET {
    bool public constant IS_TICKET_CONTRACT = true;
}