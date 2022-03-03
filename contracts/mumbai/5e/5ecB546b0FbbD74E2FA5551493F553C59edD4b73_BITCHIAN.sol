// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract BITCHIAN is ERC20{
    
    constructor () ERC20("BITCHAIN", "BitChain", 9, 2000000000 * 1e9, 1 * 1e9){
        _balances [msg.sender] = 2000000000 * 1e9;
    }
}