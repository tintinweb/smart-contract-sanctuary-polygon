// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract bolomberk is ERC20 
    {
    constructor () ERC20("bolomberk" , "BERK" , 40000000 * 1e18 , 18)
        {
            _balances[_msgSender()] = 40000000 * 1e18;
        }
    }