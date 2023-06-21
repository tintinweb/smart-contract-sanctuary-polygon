// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Betacoin is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        uint256 totalSupply = initialSupply * (10**uint256(18));
        _mint(msg.sender, totalSupply);
    }
}