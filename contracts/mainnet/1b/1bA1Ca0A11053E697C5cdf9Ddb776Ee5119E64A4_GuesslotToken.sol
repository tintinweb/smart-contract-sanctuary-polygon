// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import './Token.sol';

contract GuesslotToken is Token {
    constructor() public Token('Guesslot Token', 'GLT', 0) {
        _mint(msg.sender, 100_000_000 ether);
    }
}