// SPDX-License-Identifier: MIT

import "./ERC20.sol";

pragma solidity ^0.8.0;

contract Reyhan  is ERC20 {

    constructor() ERC20("Reyhan", "RE60", 1000000 * 1e5, 5) {
        _balances[_msgSender()] = 1000000 * 1e5;

    }
}