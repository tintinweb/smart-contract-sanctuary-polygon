// SPDX-License-Identifier: MIT

import "./ERC20.sol";

pragma solidity ^0.8.17;


contract woas is ERC20 {
    constructor () ERC20 ("woas", "WOAS", 100000000000000000) {
        balances[msg.sender] = _totalSupply;
    }
}