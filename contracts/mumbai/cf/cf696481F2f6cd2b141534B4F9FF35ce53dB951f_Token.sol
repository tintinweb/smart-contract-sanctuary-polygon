// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC20.sol';

contract Token is ERC20 {
    constructor() ERC20("OLOb", "OLOb") {
        _mint(msg.sender, 10 ** 9 * 10 ** decimals());
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}