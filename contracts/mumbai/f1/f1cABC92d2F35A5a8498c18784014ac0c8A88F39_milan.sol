// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.17;

import "./ERC20.sol";
 
 contract milan is ERC20{
    constructor () ERC20("milan", "MLN", 21000000 * 1e18,18){
        _balances[_msgSender()] = 21000000 * 1e18;
    }
 }