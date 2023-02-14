// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

/// @title IOracle
/// @author Angle Labs, Inc.
interface IOracle {
    /// @notice Returns the value of a base token in quote token in base 18
    function latestAnswer() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "../interfaces/IOracle.sol";

contract MockOracle is IOracle {
    event Update(uint256 _peg);

    uint256 public base = 1 ether;
    uint256 public precision = 1 ether;
    uint256 public rate;

    /// @notice Initiate with a fixe change rate
    constructor(uint256 rate_) {
        rate = rate_;
    }

    /// @notice Mock read
    function read() public view returns (uint256) {
        return rate;
    }

    function latestAnswer() public view returns (uint256) {
        return read();
    }

    /// @notice change oracle rate
    function update(uint256 newRate) external {
        rate = newRate;
        emit Update(newRate);
    }
}