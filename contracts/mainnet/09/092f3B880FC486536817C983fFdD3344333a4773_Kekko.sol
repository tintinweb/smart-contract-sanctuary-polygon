// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC20.sol";



contract Kekko is ERC20 {
    
    
    constructor(string memory name, string memory symbol) 
        ERC20(name, symbol) {
        uint256 n = 420000000000000;
        _mint(msg.sender, n * 10**uint(decimals()));

    }
}