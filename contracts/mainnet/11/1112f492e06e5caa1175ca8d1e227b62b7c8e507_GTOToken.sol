// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract GTOToken is ERC20 { 

    constructor() ERC20("GTO Equity Tokens", "GTOEQ") {
        _mint(0x7F2CDEB43bf82983b30d12d9B862Ee9cE6C10Bf1, 20000 * 10 ** 18);
    }
}