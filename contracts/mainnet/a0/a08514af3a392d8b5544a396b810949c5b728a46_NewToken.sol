pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 10000000000000000;
		name = "The Meta Girls";
		decimals = 8;
		symbol = "TMG";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}