// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <0.9.0;

library ConvertLib {
	struct TestStruct {
		uint256 name;
	}

	function convert(uint amount,uint conversionRate) public pure returns (uint convertedAmount)
	{
		return amount * conversionRate;
	}
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity >=0.4.25 <0.9.0;

import "./ConvertLib.sol";

// This is just a simple example of a coin-like contract.
// It is not standards compatible and cannot be expected to talk to other
// coin/token contracts. If you want to create a standards-compliant
// token, see: https://github.com/ConsenSys/Tokens. Cheers!

contract MetaCoin {
	mapping (address => uint) balances;

	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	constructor() public {
		balances[tx.origin] = 10000;
	}

	function sendCoin(address receiver, uint amount) public returns(bool sufficient) {
		if (balances[msg.sender] < amount) return false;
		balances[msg.sender] -= amount;
		balances[receiver] += amount;
		emit Transfer(msg.sender, receiver, amount);
		return true;
	}

	function getBalanceInEth(address addr) public view returns(uint){
		return ConvertLib.convert(getBalance(addr),2);
	}

	function getBalance(address addr) public view returns(uint) {
		return balances[addr];
	}

	function test(ConvertLib.TestStruct memory testObj) public pure {
		require(testObj.name > 10);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <0.9.0;

import { MetaCoin as Coin } from "./MetaCoin.sol";

contract WrappedMetaCoin {
	Coin public underlying;

	constructor(Coin _underlying) public {
		underlying = _underlying;
	}

	function sendCoin(address receiver, uint amount) public returns(bool sufficient) {
		return underlying.sendCoin(receiver, amount);
	}

	function getBalanceInEth(address addr) public view returns(uint){
		return underlying.getBalanceInEth(addr);
	}

	function getBalance(address addr) public view returns(uint) {
		return underlying.getBalance(addr);
	}
}

