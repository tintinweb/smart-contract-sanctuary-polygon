// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.12;

import "./ERC20.sol";

contract KevinCoin is ERC20 {
    constructor() ERC20("Kevin Coin", "KEVIN") {
        _mint(msg.sender, 1000000000 * 1000000000000000000);
    }
}