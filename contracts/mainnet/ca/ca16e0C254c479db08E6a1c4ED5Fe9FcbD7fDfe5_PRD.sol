// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC20.sol";

contract PRD is ERC20 {
	constructor(
		string  memory name_, 
		string  memory symbol_, 
		uint8 decimals_, 
		uint256 initialAmount_,
		address initialAddress_
	) ERC20(name_, symbol_, decimals_) {
		_mint(initialAddress_, initialAmount_);
	}
}