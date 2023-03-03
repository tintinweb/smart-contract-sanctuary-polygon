// contracts/wrappers.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract SOL is ERC20 {
    constructor() ERC20("Solana", "SOL") {
        uint256 totalSupply = 1000000 * (10 ** 18);
        _mint(msg.sender, totalSupply);
    }
}