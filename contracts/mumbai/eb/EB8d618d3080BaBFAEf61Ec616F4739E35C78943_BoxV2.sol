// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Box.sol";

contract BoxV2 is Box {
	// Increments the stored value by 1
	function increment() public {
		store(retrieve() + 1);
	}
}

// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Box {
	uint256 private value;

	event ValueChanged(uint256 newValue);

	function store(uint256 newValue) public {
		value = newValue;
		emit ValueChanged(newValue);
	}

	function retrieve() public view returns (uint256) {
		return value;
	}
}