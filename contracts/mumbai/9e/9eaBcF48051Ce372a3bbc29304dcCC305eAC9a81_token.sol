// SPDX-License-Identifier: MIT
import "./ERC20.sol" ; 

pragma solidity ^0.8.2;

contract token is ERC20 {

    constructor() ERC20("Aria" , "ARI" , 1000000*1e5 , 5) {
        _balances[_msgSender()] = 1000000 * 1e5;
    } 
}