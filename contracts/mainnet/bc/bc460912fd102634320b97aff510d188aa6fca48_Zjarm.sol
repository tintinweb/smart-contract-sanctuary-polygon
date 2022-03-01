// contracts/Zjarm.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Zjarm is ERC20 {
    constructor(uint256 initialSupply) ERC20("Zjarm", "Zrm") {
        _mint(msg.sender, initialSupply);
    }
}