// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Test {
	uint256 public immutable RANDOM;

	constructor(uint256 rand) {
		RANDOM = rand;
	}
}