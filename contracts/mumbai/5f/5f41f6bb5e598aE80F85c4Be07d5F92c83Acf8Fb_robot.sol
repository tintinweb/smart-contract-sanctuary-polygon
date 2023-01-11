//SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0 ;

import "./ERC20.sol" ; 

contract robot is ERC20{
    constructor () ERC20 (6 , 1000000*1e6 , "Mr.Robot" , "MRT") {
        _balances[_msgSender()] = 1000000*1e6 ;
    }
}