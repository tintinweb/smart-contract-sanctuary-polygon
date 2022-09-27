pragma solidity ^0.8.10;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 500000000;
		name = "DigilawToken";
		decimals = 4;
		symbol = "DLTN";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}