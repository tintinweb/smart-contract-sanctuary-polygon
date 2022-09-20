/**
 *Submitted for verification at polygonscan.com on 2022-09-20
*/

pragma solidity ^0.8.13;

// A library is like a contract with reusable code, which can be called by other contracts.
// Deploying common code can reduce gas costs.
library ConvertLib{
	function convert(uint amount, uint conversionRate) public pure returns (uint convertedAmount)
	{
		return amount * conversionRate;
	}
}