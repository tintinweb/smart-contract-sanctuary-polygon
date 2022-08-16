// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./ERC20.sol";
contract mmad is ERC20 {
    constructor()ERC20("mohammad","mmd", 1000000 * 1e5, 5 ){
        _balances[_msgSender()]= 1000000 * 1e5;
    }
}