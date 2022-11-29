// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract WeHomeToken is ERC20 {
    constructor() ERC20("test We Home Token", "tHOME") {
        _mint(msg.sender, 800000000000*10**18);
    }
}