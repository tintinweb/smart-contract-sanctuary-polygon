//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ;

import "./ERC20.sol" ;

contract TokenVKG is ERC20 {
    constructor () ERC20 ("viking" , "VKG" , 6 , 1000000*1e6 ) {
        _balances[_msgSender()] = 1000000*1e6 ;
    }
}