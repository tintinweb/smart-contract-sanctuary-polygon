// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Date calculation logic from:
// https://github.com/RollaProject/solidity-datetime/blob/master/contracts/DateTime.sol
contract DateCalc {
    // For date calculation logic
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    int256 constant OFFSET19700101 = 2440588;

    function subYears(
        uint256 timestamp,
        uint256 _years
    ) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(
            timestamp / SECONDS_PER_DAY
        );
        year -= _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(
        uint256 _days
    ) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            int256 __days = int256(_days);

            int256 L = __days + 68569 + OFFSET19700101;
            int256 N = (4 * L) / 146097;
            L = L - (146097 * N + 3) / 4;
            int256 _year = (4000 * (L + 1)) / 1461001;
            L = L - (1461 * _year) / 4 + 31;
            int256 _month = (80 * L) / 2447;
            int256 _day = L - (2447 * _month) / 80;
            L = _month / 11;
            _month = _month + 2 - 12 * L;
            _year = 100 * (N - 49) + _year + L;

            year = uint256(_year);
            month = uint256(_month);
            day = uint256(_day);
        }
    }

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day -
            32075 +
            (1461 * (_year + 4800 + (_month - 14) / 12)) /
            4 +
            (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
            12 -
            (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
            4 -
            OFFSET19700101;

        _days = uint256(__days);
    }

    function _getDaysInMonth(
        uint256 year,
        uint256 month
    ) internal pure returns (uint256 daysInMonth) {
        if (
            month == 1 ||
            month == 3 ||
            month == 5 ||
            month == 7 ||
            month == 8 ||
            month == 10 ||
            month == 12
        ) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is a set of accounts (authorized callers) that can be granted exclusive
 * access to specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOTCaller`, which can be applied to your functions to restrict their use
 * to authorized Open Town accounts.
 */
abstract contract OTCallable is Ownable {
    mapping(address => bool) private otCallers;

    event CallerAuthorized(address indexed caller, address indexed by);
    event CallerDeauthorized(address indexed caller, address indexed by);

    /**
     * @dev Throws if called by unauthorized account.
     */
    modifier onlyOTCaller() {
        require(otCallers[msg.sender], "OTCallable: Unauthorized caller");
        _;
    }

    /**
     * @dev Authorizes new account (`addr`).
     * Can only be called by the current owner.
     */
    function authorizeCaller(address addr) external onlyOwner {
        otCallers[addr] = true;
        emit CallerAuthorized(addr, msg.sender);
    }

    /**
     * @dev Revokes authorization from the account (`addr`).
     * Can only be called by the current owner.
     */
    function deauthorizeCaller(address addr) external onlyOwner {
        otCallers[addr] = false;
        emit CallerDeauthorized(addr, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./OTCallable.sol";
import "./DateCalc.sol";

interface IOTContract {
    function transferFrom(address from, address to, uint256 amount) external;

    function transfer(address to, uint256 amount) external;
}

struct Stake {
    uint256 amount;
    uint256 blockNumber;
}

struct Staker {
    uint256 totalStaked;
    uint256 lastClaimedBlock;
    Stake[] history;
}

struct Deposit {
    uint256 amount; // amount in ETH
    uint256 blockNumber;
    uint256 timestamp;
    // total amount of staked token at given block
    uint256 totalStaked;
    // sum of the paid Eth for this reciept
    uint256 totalPaid;
    bool adjusted;
}

contract OTStaking is OTCallable, DateCalc {
    mapping(address => Staker) private stakers;
    Deposit[] public deposits;
    uint256 public totalStaked;

    IOTContract public token;

    event Staked(
        address indexed staker,
        uint256 amount,
        uint256 totalUserStakedAmount,
        uint256 totalStakedAmount
    );
    event Unstaked(
        address indexed staker,
        uint256 amount,
        uint256 totalStakedAmount
    );

    uint256 private minimumStakingAmount;

    constructor(address otContractAddr) {
        token = IOTContract(otContractAddr);
        minimumStakingAmount = 100 ether;
    }

    // stake can take amount and stake from the msg.sender
    function stake(uint256 amount) public {
        require(amount >= minimumStakingAmount, "amount less than minimum");

        // lastClaimedBlock will be current block when the user staked for the first time
        // this will prevent the user from claiming rewards from the genesis block
        if (stakers[msg.sender].lastClaimedBlock == 0) {
            stakers[msg.sender].lastClaimedBlock = block.number;
        }

        stakers[msg.sender].totalStaked += amount;
        totalStaked += amount;
        stakers[msg.sender].history.push(Stake(amount, block.number));

        emit Staked(
            msg.sender,
            amount,
            stakers[msg.sender].totalStaked,
            totalStaked
        );

        token.transferFrom(msg.sender, address(this), amount);
    }

    // unstake can take amount and unstake from the msg.sender and return the amount to the msg.sender
    function unstake() public {
        uint256 stakedAmount = stakers[msg.sender].totalStaked;
        require(stakedAmount > 0, "amount cannot be 0");

        // always claim before unstake
        claim();

        totalStaked -= stakedAmount;

        // Clear staker's history
        stakers[msg.sender].totalStaked = 0;
        stakers[msg.sender].lastClaimedBlock = 0;
        delete stakers[msg.sender].history;

        emit Unstaked(msg.sender, stakedAmount, totalStaked);

        token.transfer(msg.sender, stakedAmount);
    }

    // get balance of the staker
    function getBalance(address staker) public view returns (uint256) {
        return stakers[staker].totalStaked;
    }

    receive() external payable onlyOTCaller {
        // Go through the deposits form the latest to the oldest
        uint256 expiredAmount = 0;
        // 3 years ago
        uint256 expiredTime = subYears(block.timestamp, 3);
        // only work on the deposits which is older than 1 year
        uint256 boundIdx = findUpperTimestamp(deposits, expiredTime);

        // work on the old deposits backward
        for (uint256 i = boundIdx; i > 0; i--) {
            uint256 idx = i - 1;
            // stop if the already worked on
            // since all the previous deposits are already adjusted
            if (deposits[idx].adjusted) {
                break;
            }
            uint remainingAmount = deposits[idx].amount -
                deposits[idx].totalPaid;
            expiredAmount += remainingAmount;
            deposits[idx].adjusted = true;
        }

        // Reciept will record current total staked tokens
        deposits.push(
            Deposit(
                msg.value + expiredAmount,
                block.number,
                block.timestamp,
                totalStaked,
                0,
                false
            )
        );
    }

    function getDepositCount() public view returns (uint256) {
        return deposits.length;
    }

    // get claimable amount of the staker
    function getClaimableAmount(address staker) public view returns (uint256) {
        uint256 expiredTime = subYears(block.timestamp, 3);
        uint256 reward = 0;

        // Nothing to claim if there are no deposits or before any stakes are made.
        if (deposits.length <= 0 || stakers[staker].history.length <= 0) {
            return reward;
        }

        // Go through all users' stakes, calculating reward for each one separately.
        for (uint256 i = 0; i < stakers[staker].history.length; i++) {
            Stake memory targetStake = stakers[staker].history[i];

            // Find deposits that came after the target stake
            uint256 firstDepositAfterStakeIdx = findUpperBound(
                deposits,
                targetStake.blockNumber
            );

            // Go through all deposits that came after the target stake,
            // calculating the reward rate from the first deposit and the reward amount from the next one.
            // After that, calculate rate from second deposit and reward amount from the third.
            // Repeat until all deposits are covered to the last one.
            for (
                uint256 j = firstDepositAfterStakeIdx;
                j < deposits.length - 1;
                j++
            ) {
                Deposit memory rateDeposit = deposits[j];
                Deposit memory payoutDeposit = deposits[j + 1];

                if (
                    payoutDeposit.blockNumber >
                    stakers[staker].lastClaimedBlock &&
                    payoutDeposit.timestamp > expiredTime
                ) {
                    uint256 depositReward = (payoutDeposit.amount *
                        targetStake.amount) / rateDeposit.totalStaked;
                    reward += depositReward;
                }
            }
        }

        return reward;
    }

    // claim will calculate the reward and send eth to the msg.sender
    // reward is calculated by the amount of staked tokens and the time of staking
    // if the staked time is before than the deposit, the user is eligible for the reward
    // reward will be calculated by portion of the total stake at the time of deposit.
    function claim() public {
        uint256 expiredTime = subYears(block.timestamp, 3);
        uint256 reward = 0;

        // Nothing to claim if there are no deposits or before any stakes are made.
        if (deposits.length <= 0 || stakers[msg.sender].history.length <= 0) {
            return;
        }

        // Go through all users' stakes, calculating reward for each one separately.
        for (uint256 i = 0; i < stakers[msg.sender].history.length; i++) {
            Stake memory targetStake = stakers[msg.sender].history[i];

            // Find deposits that came after the target stake
            uint256 firstDepositAfterStakeIdx = findUpperBound(
                deposits,
                targetStake.blockNumber
            );

            // Go through all deposits that came after the target stake,
            // calculating the reward rate from the first deposit and the reward amount from the next one.
            // After that, calculate rate from second deposit and reward amount from the third.
            // Repeat until all deposits are covered to the last one.
            for (
                uint256 j = firstDepositAfterStakeIdx;
                j < deposits.length - 1;
                j++
            ) {
                Deposit memory rateDeposit = deposits[j];
                Deposit memory payoutDeposit = deposits[j + 1];

                // Skip deposit if already claimed or if it has expired
                if (
                    payoutDeposit.blockNumber >
                    stakers[msg.sender].lastClaimedBlock &&
                    payoutDeposit.timestamp > expiredTime
                ) {
                    uint256 depositReward = (payoutDeposit.amount *
                        targetStake.amount) / rateDeposit.totalStaked;
                    reward += depositReward;

                    // Update the total paid amount from the "payout" deposit
                    deposits[j + 1].totalPaid += depositReward;
                }
            }
        }

        stakers[msg.sender].lastClaimedBlock = block.number;
        if (reward > 0) {
            payable(msg.sender).transfer(reward);
        }
    }

    /**
     * based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/utils/Arrays.sol
     */
    function findUpperBound(
        Deposit[] storage array,
        uint256 blockNumber
    ) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            if (array[mid].blockNumber > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        if (low > 0 && array[low - 1].blockNumber >= blockNumber) {
            return low - 1;
        } else {
            return low;
        }
    }

    function findUpperTimestamp(
        Deposit[] storage array,
        uint256 timestamp
    ) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            if (array[mid].timestamp > timestamp) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        if (low > 0 && array[low - 1].timestamp >= timestamp) {
            return low - 1;
        } else {
            return low;
        }
    }
}