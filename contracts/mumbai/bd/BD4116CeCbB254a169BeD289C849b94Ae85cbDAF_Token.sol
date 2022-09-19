// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Token is ERC20
{
    constructor (string memory name, string memory symbol, uint8 decimals) ERC20 (name, symbol, decimals)
    {
        mint (100000000000000000000000);
    }
    
    function mint (uint amount) public onlyOwner 
    {
        address account = msg.sender;
        _mint (account, amount);
    }
}