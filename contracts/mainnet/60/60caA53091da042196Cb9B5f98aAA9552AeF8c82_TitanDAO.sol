// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./ERC20.sol";
import "./Ownable.sol";

/// @author KirienzoEth for TitanDAO
contract TitanDAO is ERC20, Ownable {
  constructor(
    string memory name,
    string memory symbol,
    uint256 _totalSupply,
    address _mintTo
  ) ERC20(name, symbol) {
    _mint(_mintTo, _totalSupply);
    transferOwnership(_mintTo);
  }
}