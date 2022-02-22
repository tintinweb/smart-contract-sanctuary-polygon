pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract DC is ERC20Standard {
	constructor() public {
		totalSupply = 10000000000000000000000000;
		name = "DC Comics";
		decimals = 8;
		symbol = "DC";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}