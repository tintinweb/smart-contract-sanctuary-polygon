// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Box {
    uint256 private value;

    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);

    // Stores a new value in the contract
    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }
}

// contracts/BoxV2.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Box.sol";

contract Box2 is Box {
    // Increments the stored value by 1
    function increment() public {
        store(retrieve() + 1);
    }
}