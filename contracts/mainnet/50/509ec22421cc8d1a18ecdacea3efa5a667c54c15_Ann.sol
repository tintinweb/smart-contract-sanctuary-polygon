// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Ann is ERC20 {
    constructor() ERC20("Ann Widdecoin", "FRUITCAKE") {
        _mint(msg.sender, (500*10**6)*10**18);
    }
}