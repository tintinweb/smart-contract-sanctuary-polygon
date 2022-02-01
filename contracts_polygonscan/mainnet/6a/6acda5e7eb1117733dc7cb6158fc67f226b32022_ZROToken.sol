// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract ZROToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("ZROToken", "ZRO") {
        _mint(msg.sender, initialSupply);
    }
}