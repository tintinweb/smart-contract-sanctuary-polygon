/**
 *Submitted for verification at polygonscan.com on 2022-08-01
*/

// File: github/FATEx-DAO/fatex-dex-protocol/contracts/fatex/v3/IRewardScheduleV3.sol



pragma solidity 0.6.12;

interface IRewardScheduleV3 {

    /// @notice returns the amount of FATE earned over the provided period. Both _fromTimestamp and _toTimestamp are
    ///         inclusive
    function getFateForDuration(
        uint _startTimestamp,
        uint _fromTimestamp,
        uint _toTimestamp
    )
    external
    view
    returns (uint lockedFatePerSecond, uint unlockedFatePerSecond);


    function calculateCurrentIndex(
        uint _startTimestamp
    )
    external
    view
    returns (uint);

    function lockedPercent(uint index) external pure returns (uint);
}

// File: github/FATEx-DAO/fatex-dex-protocol/contracts/utils/SafeMathLocal.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathLocal {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: github/FATEx-DAO/fatex-dex-protocol/contracts/fatex/v3/RewardScheduleV3.sol



pragma solidity 0.6.12;



contract RewardScheduleV3 is IRewardScheduleV3 {
    using SafeMathLocal for uint;

    /// @notice This is the emission schedule for each second for a given week. These numbers represent how much FATE is
    ///         rewarded per second. Each index represents a week. The starting day/week, according to the Reward
    ///         Controller was XYZ (UTC time). Meaning, week 2 (index 1, since indices start at 0) starts on
    ///         XYZ (UTC time).
    uint[72] public FATE_PER_SECOND = [
        0.791131e18,    // week 1
        0.791131e18,    // week 2
        0.791131e18,    // week 3
        0.791131e18,    // week 4
        0.791131e18,    // week 5
        0.791131e18,    // week 6
        0.791131e18,    // week 7
        0.791131e18,    // week 8
        0.791131e18,    // week 9
        0.791131e18,    // week 10
        0.805371e18,    // week 11
        0.819868e18,    // week 12
        0.834625e18,    // week 13
        0.849649e18,    // week 14
        0.864942e18,    // week 15
        0.880511e18,    // week 16
        0.89636e18,     // week 17
        0.912495e18,    // week 18
        0.92892e18,     // week 19
        0.94564e18,     // week 20
        0.962662e18,    // week 21
        0.97999e18,     // week 22
        0.99763e18,     // week 23
        1.015587e18,    // week 24
        1.033868e18,    // week 25
        1.052477e18,    // week 26
        1.072e18,       // week 27
        1.090707e18,    // week 28
        1.11034e18,     // week 29
        1.130326e18,    // week 30
        1.150672e18,    // week 31
        1.171384e18,    // week 32
        1.193e18,       // week 33
        1.213934e18,    // week 34
        1.235784e18,    // week 35
        1.258028e18,    // week 36
        1.280673e18,    // week 37
        1.303725e18,    // week 38
        1.327192e18,    // week 39
        1.351082e18,    // week 40
        1.375401e18,    // week 41
        1.400158e18,    // week 42
        1.43e18,        // week 43
        1.451018e18,    // week 44
        1.4772e18,      // week 45
        1.50372e18,     // week 46
        1.530791e18,    // week 47
        1.558346e18,    // week 48
        1.586396e18,    // week 49
        1.614951e18,    // week 50
        1.64403e18,     // week 51
        1.672e18,       // week 52
        0.0000e18,      // week 53
        0.0000e18,      // week 54
        0.0000e18,      // week 55
        0.0000e18,      // week 56
        0.0000e18,      // week 57
        0.0000e18,      // week 58
        0.0000e18,      // week 59
        0.0000e18,      // week 60
        0.0000e18,      // week 61
        0.0000e18,      // week 62
        0.0000e18,      // week 63
        0.0000e18,      // week 64
        0.0000e18,      // week 65
        0.0000e18,      // week 66
        0.0000e18,      // week 67
        0.0000e18,      // week 68
        0.0000e18,    // week 69
        0.0000e18,    // week 70
        0.0000e18,    // week 71
        0.0000e18     // week 72
    ];

    // 60 seconds per minute, 60 minutes per hour, 24 hours per day, 7 days per week
    uint public constant SECONDS_PER_WEEK = 60 * 60 * 24 * 7;

    constructor() public {
    }

    function rewardsNumberOfWeeks() external view returns (uint) {
        return FATE_PER_SECOND.length;
    }

    function lockedPercent(uint index) public pure override returns (uint) {
        if (index >= 0 && index < 52) {
            return 92;
        } else {
            return 92;
        }
    }

    /**
     * @param index The week at which the amount of FATE per second should be rewarded. Index starts at 0, meaning index
     *              1 is actually week 2. Index 12 is week 13.
     */
    function getFateAtIndex(uint index)
    public
    view
    returns (uint, uint) {
        // vesting occurs at an 92/8 for now
        return (
            FATE_PER_SECOND[index] * lockedPercent(index) / 100,
            FATE_PER_SECOND[index] * (100 - lockedPercent(index)) / 100
        );
    }

    function calculateCurrentIndex(
        uint _startTimestamp
    ) public override view returns (uint) {
        if (_startTimestamp > block.timestamp) {
            return 0;
        }

        return (block.timestamp - _startTimestamp) / SECONDS_PER_WEEK;
    }

    function getFateForDuration(
        uint _startTimestamp,
        uint _fromTimestamp,
        uint _toTimestamp
    )
    external
    override
    view
    returns (uint, uint) {

        if (_startTimestamp > _toTimestamp || _fromTimestamp == _toTimestamp) {
            return (0, 0);
        }
        if (_fromTimestamp < _startTimestamp) {
            _fromTimestamp = _startTimestamp;
        }

        require(
            _fromTimestamp <= _toTimestamp,
            "RewardScheduleV3::getFatePerSecond: INVALID_RANGE"
        );

        uint endTimestampExclusive = _startTimestamp + (FATE_PER_SECOND.length * SECONDS_PER_WEEK);

        if (_fromTimestamp >= endTimestampExclusive) {
            return (0, 0);
        }

        if (_toTimestamp >= endTimestampExclusive) {
            _toTimestamp = endTimestampExclusive - 1;
        }

        uint fromIndex = (_fromTimestamp - _startTimestamp) / SECONDS_PER_WEEK;
        uint toIndex = (_toTimestamp - _startTimestamp) / SECONDS_PER_WEEK;

        if (fromIndex < toIndex) {
            uint secondsAtIndex = SECONDS_PER_WEEK - ((_fromTimestamp - _startTimestamp) % SECONDS_PER_WEEK);
            (uint lockedFatePerSecond, uint unlockedFatePerSecond) = getFateAtIndex(fromIndex);
            lockedFatePerSecond = secondsAtIndex * lockedFatePerSecond;
            unlockedFatePerSecond = secondsAtIndex * unlockedFatePerSecond;

            for (uint i = fromIndex + 1; i < toIndex; i++) {
                (uint lockedFatePerSecond2, uint unlockedFatePerSecond2) = getFateAtIndex(i);
                lockedFatePerSecond += lockedFatePerSecond2 * SECONDS_PER_WEEK;
                unlockedFatePerSecond += unlockedFatePerSecond2 * SECONDS_PER_WEEK;
            }

            secondsAtIndex = (_toTimestamp - _startTimestamp) % SECONDS_PER_WEEK;
            (uint lockedFatePerSecond3, uint unlockedFatePerSecond3) = getFateAtIndex(toIndex);

            return (
                lockedFatePerSecond + secondsAtIndex * lockedFatePerSecond3,
                unlockedFatePerSecond + secondsAtIndex * unlockedFatePerSecond3
            );
        } else {

            assert(fromIndex == toIndex);
            (uint lockedFatePerSecond, uint unlockedFatePerSecond) = getFateAtIndex(fromIndex);
            return (
                lockedFatePerSecond * (_toTimestamp - _fromTimestamp),
                unlockedFatePerSecond * (_toTimestamp - _fromTimestamp)
            );
        }
    }
}