// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract PairDummy {
	function getReserves() external view returns (uint112, uint112, uint32) {
		return (5000 ether, 5000 ether, uint32(block.timestamp));
	}
}