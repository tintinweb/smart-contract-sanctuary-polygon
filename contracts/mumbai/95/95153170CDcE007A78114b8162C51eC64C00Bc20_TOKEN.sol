// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";

contract TOKEN is ERC20 {
    constructor () ERC20("soheilToken","SOT", 9) // 0,000000001 // 10000 // 0,000010000
    {
        _mint(msg.sender, 10000000000000);
    }
}