// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract DebToken is ERC20 {
    constructor() ERC20("digital economy ecology builder", "DEB") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}