// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/BEP20/IBEP20.sol)

import "./ERC20.sol";


pragma solidity ^0.8.0;

contract Ahmad is ERC20{
    constructor() ERC20 ("Ahmad","AK",1000000 * 1e18){
        _balances[_msgSender()] = 1000000 * 1e18 ;
    }
}