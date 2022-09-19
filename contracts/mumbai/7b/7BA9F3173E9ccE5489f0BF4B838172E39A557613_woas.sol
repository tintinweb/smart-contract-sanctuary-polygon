// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20.sol";

contract woas is ERC20 {
  constructor () ERC20 ("woas", "WAS", 1000000 * 1e5 , 5) {
    _balances[_msgSender()] = 1000000 * 1e5;
  }
}