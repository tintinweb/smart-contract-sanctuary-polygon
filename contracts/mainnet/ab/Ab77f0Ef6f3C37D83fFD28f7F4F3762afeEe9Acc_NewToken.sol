pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 0;
		name = "Sandbox";
		decimals = 4;
		symbol = "SAND";
		version = "1.0";
	}
}