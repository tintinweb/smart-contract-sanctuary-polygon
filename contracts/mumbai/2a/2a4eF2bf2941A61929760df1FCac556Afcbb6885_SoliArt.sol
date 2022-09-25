// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC20.sol";


contract SoliArt is ERC20 
{
    constructor()ERC20("SoliArt" , "SA" , 1000000 * 1e5 ,5 ){
        _balances[_msgSender()] = 1000000 * 1e5;
    }
}