pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 100000000;
		name = "F2test Dividends Token";
		decimals = 4;
		symbol = "F2TEST";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}