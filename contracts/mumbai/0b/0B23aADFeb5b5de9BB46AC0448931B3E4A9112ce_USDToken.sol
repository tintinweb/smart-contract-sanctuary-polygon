// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract USDToken is ERC20 {
    constructor() ERC20("test USD Token", "tUSDT") {
        _mint(msg.sender, 800000000000*10**18);
    }
}