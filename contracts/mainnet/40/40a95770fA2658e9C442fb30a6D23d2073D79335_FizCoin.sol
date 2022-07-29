// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";

contract FizCoin is ERC20 {
    constructor() ERC20("Fiz coin", "FZL") {
        _mint(msg.sender, 100000000000000000000000000);
    }
}