// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20.sol";

contract soheil is ERC20 {
        
        constructor () ERC20 ("soheil" , "SHL" , 1000000 * 5, 5) {
            _balances[_msgSender()] = 1000000 * 5;
        }
}