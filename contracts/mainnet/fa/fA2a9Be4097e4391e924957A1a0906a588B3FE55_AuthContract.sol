// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract AuthContract {

	event LoginEvent(uint256 code);

	function Login(uint256 _code) public {
		emit LoginEvent(_code);
	}
}