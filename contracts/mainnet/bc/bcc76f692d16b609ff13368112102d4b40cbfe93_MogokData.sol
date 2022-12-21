// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Ownable.sol";

contract MogokData is Ownable {
	bytes[55] public mogok;
	uint256[4][55] public bounds;

	function mogokExists(uint256 x, uint256 y, uint256 z) public view returns (bool) {
		require(x < 61);
		require(y < 124);
		require(z < 55);

		if ((x < bounds[z][0]) || (x > bounds[z][1])) return false;
		if ((y < bounds[z][2]) || (y > bounds[z][3])) return false;

		uint256 bit = (x-bounds[z][0]) % 8;
		uint256 bytes_x = (bounds[z][1] - bounds[z][0] + 1) / 8;

		bytes1 v = mogok[z][(y-bounds[z][2])*bytes_x+((x-bounds[z][0])/8)];
		return (uint8(v) & (1 << (7-bit))) != 0;
	}

	function loadMogokData(uint256 z, uint256 minX, uint256 maxX, uint256 minY, uint256 maxY, bytes memory plane) public onlyOwner {
		require(z < 55);

		// NOTE: drop ownership after loading data

		mogok[z] = plane;
		bounds[z][0] = minX;
		bounds[z][1] = maxX;
		bounds[z][2] = minY;
		bounds[z][3] = maxY;
	}
}