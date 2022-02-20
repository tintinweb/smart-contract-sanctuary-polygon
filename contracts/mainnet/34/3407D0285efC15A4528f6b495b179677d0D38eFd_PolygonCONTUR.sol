pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract PolygonCONTUR is ERC20Standard {
	constructor() public {
		totalSupply = 100000000000000000000000000000;
		name = "Polygon";
		decimals = 18;
		symbol = "CONTUR";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}