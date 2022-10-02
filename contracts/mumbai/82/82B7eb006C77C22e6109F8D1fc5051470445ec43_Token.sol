// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract Token is ERC20 {
  constructor(string memory _name,string memory _symbol,uint _supply) ERC20(_name, _symbol) {
    _mint(msg.sender, _supply * (10 ** decimals()));
  }
}