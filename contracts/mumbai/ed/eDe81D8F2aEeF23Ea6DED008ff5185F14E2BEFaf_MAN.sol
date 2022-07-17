// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract MAN is ERC20 {
    
    constructor() ERC20 ("human","MAN",1000000 * 1e5,5){
            _balances[_msgSender()] = 1000000 * 1e5 ;
        }
}