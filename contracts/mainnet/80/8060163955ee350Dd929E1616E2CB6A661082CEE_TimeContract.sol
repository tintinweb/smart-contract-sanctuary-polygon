/**
 *Submitted for verification at polygonscan.com on 2023-03-31
*/

// Sources flattened with hardhat v2.12.2 https://hardhat.org

// File contracts/staking/interfaces/ITime.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ITime {
    /// @notice Returns current "day"
    /// @dev Launch Date = 0 Day
    /// @return randNumber Current day index
    function getCurrentTimeIndex() external view returns(uint);
}


// File contracts/staking/Time.sol

/// License-Identifier: MIT
pragma solidity 0.8.16;

 /**
  * @title Time management.
  * @notice Given a "Day 0" base timestamp (Like the "epoch time" in Unix), and the number of seconds in each "day",
  *         this contract converts standard timestamps into a "day" index value
  * @dev    By adjusting the two constructor values, developers can create debug environments where time proceeds faster.
  */
contract TimeContract is ITime {
    // "Day 0" base timestamp
    uint private immutable _launchTimestamp;
    // Number of seconds in each day
    uint private immutable _timeUnit;

    /// @notice Constructor
    /// @param launchTimestamp_ "Day 0" base timestamp
    /// @param timeUnitInSec Number of seconds in each day
    constructor(uint launchTimestamp_, uint timeUnitInSec) {
        if ( block.timestamp > launchTimestamp_ ) {
            require((block.timestamp - launchTimestamp_) / timeUnitInSec < 7);
        } else {
            require((launchTimestamp_ - block.timestamp) / timeUnitInSec < 7);
        }

        _launchTimestamp = launchTimestamp_;
        _timeUnit = timeUnitInSec;
    }

    /// @notice Returns current "day"
    /// @dev Launch Date = 0 Day
    /// @return randNumber Current day index
    function getCurrentTimeIndex() override external view returns(uint) {
        return (block.timestamp - _launchTimestamp) / _timeUnit;
    }
}