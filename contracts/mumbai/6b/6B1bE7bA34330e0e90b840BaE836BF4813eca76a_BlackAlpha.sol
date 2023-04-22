// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./DataStorage.sol";

contract BlackAlpha is DataStorage {

    constructor(address dai) {
        directShare[0] = 230;
        directShare[1] = 225;
        directShare[2] = 220;
        directShare[3] = 215;
        directShare[4] = 210;

        DAI = IERC20(dai);
    }

    function version() public pure returns(string memory) {
        return "1.0.3";
    }

    function register(address _referral) public {
        address userAddr = msg.sender;

        uint256 _entrance = checkCanRegister(userAddr, _referral);
        _newNode(userAddr, _referral, _entrance);
        _newUserId(userAddr);

        uint256 remaining = _payDirect(userAddr, _referral, _entrance);
        DAI.transferFrom(userAddr, address(this), remaining);
        _payBinary(userAddr, _referral, _entrance);
    }

    function upgrade() public {
        address userAddr = msg.sender;
        address _referral = users[userAddr].upAddr;
        uint256 _entrance = checkCanUpgrade(userAddr);

        uint256 remaining = _payDirect(userAddr, _referral, _entrance);
        DAI.transferFrom(userAddr, address(this), remaining);
        _payBinary(userAddr, _referral, _entrance);
    }
    
    function checkCanRegister(address userAddr, address upAddr) public view returns(uint256 entrance) {
        require(
            users[upAddr].childsCount < 2,
            "This address have two directs and could not accept new members!"
        );
        require(
            userAddr != upAddr,
            "You can not enter your own address!"
        );
        require(
            users[userAddr].entrance == 0,
            "This address is already registered!"
        );
        return 33 * 10 ** 18;
    }
    
    function checkCanUpgrade(address userAddr) public view returns(uint256 entrance) {
        User storage user = users[userAddr];
        require(
            user.upgradeTime == 0 || block.timestamp >= user.upgradeTime,
            "BlackAlpha: the upgrade time has been terminated."    
        );
        require(
            users[userAddr].entrance != 0,
            "This address has not registered!"
        );
        return users[userAddr].entrance * 2;
    }
    
    function checkEnterance(address userAddr) public view returns(uint256 entrance) {
        uint256 lastEntrance = users[userAddr].entrance;
        if(lastEntrance == 0) {
            entrance == 33 * 10 ** 18;
        } else {
            entrance == lastEntrance * 2;
        }
    }

    function _newUserId(address userAddr) internal {
        idToAddr[userCount] = userAddr;
        addrToId[userAddr] = userCount;
        userCount++;
    }

    function _newNode(address userAddr, address upAddr, uint256 entrance) internal {
        users[userAddr] = User ({
            upAddr : upAddr,
            rightAddr : address(0),
            leftAddr : address(0),
            entrance : entrance,
            earning : 0,
            paidOut : 0,
            leftVariance : 0,
            rightVariance : 0,
            leftPay : 0,
            rightPay : 0,
            leftUsers : 0,
            rightUsers : 0,
            depth : users[upAddr].depth + 1,
            childsCount : 0,
            isLeftOrRightChild : users[upAddr].childsCount,
            upgradeTime : 0
        });
    }


    function _payDirect(address userAddr, address upAddr, uint256 entrance)
        internal 
        returns (uint256 remaining)
    {
        remaining = entrance;
        uint256 share;
        for (uint256 i; i < 5; i++) {
            if(users[upAddr].entrance != 0) {
                share = entrance * directShare[i] / 3300;
                DAI.transferFrom(userAddr, upAddr, share);
                remaining -= share;
                upAddr = users[upAddr].upAddr;
            } else {
                break;
            }
        }
        totalEntrance += entrance;
    }

        
    function _payBinary(address userAddr, address upAddr, uint256 entrance) internal {

        if (users[upAddr].childsCount == 0) {
            users[upAddr].leftAddr = userAddr;
        } else {
            users[upAddr].leftAddr = userAddr;
        }
        users[upAddr].childsCount++;

        uint256 dayCount = dayCounter();
        uint256 userEarning;
        uint256 depth = users[userAddr].depth;
        for (uint256 i = 1; i < depth; i++) {
            if (users[userAddr].isLeftOrRightChild == 0) {
                uint256 todayRightPay = users[upAddr].rightVariance;
                if(todayRightPay == 0) {
                    users[upAddr].leftVariance += entrance;
                } else {
                    if(entrance < todayRightPay) {
                        users[upAddr].rightVariance -= entrance;
                        userEarning = entrance;
                    } else {
                        users[upAddr].rightVariance = 0;
                        users[upAddr].leftVariance = entrance - todayRightPay;
                        userEarning = todayRightPay;
                    }
                }
                users[upAddr].leftPay += entrance;
                users[upAddr].leftUsers ++;
            } else {
                uint256 todayLeftPay = users[upAddr].leftVariance;
                if(todayLeftPay == 0) {
                    users[upAddr].rightVariance += entrance;
                } else {
                    if(entrance < todayLeftPay) {
                        users[upAddr].leftVariance -= entrance;
                        userEarning = entrance;
                    } else {
                        users[upAddr].leftVariance = 0;
                        users[upAddr].rightVariance = entrance - todayLeftPay;
                        userEarning = todayLeftPay;
                    }
                }
                users[upAddr].rightPay += entrance;
                users[upAddr].rightUsers ++;
            }

            if(userEarning > 0) {
                uint256 todayEarning = userTodayEarning[upAddr][dayCount];
                uint256 userFlash = users[upAddr].entrance * 2/3;
                uint256 neededEarning =  userFlash - todayEarning;
                if(neededEarning > 0) {
                    if(neededEarning >= userEarning) {
                        userTodayEarning[upAddr][dayCount] += userEarning;
                    } else {
                        userTodayEarning[upAddr][dayCount] = userFlash;
                        userTodayFlash[upAddr][dayCount] += userEarning - neededEarning;
                        users[upAddr].upgradeTime = uint48(block.timestamp + 30 days);
                    }
                }
            }

            userAddr = upAddr;
            upAddr = users[upAddr].upAddr;
        }
    }

    function withdraw() public {
        address userAddr = msg.sender;
        User storage user = users[userAddr];
        require(
            user.upgradeTime == 0 || block.timestamp >= user.upgradeTime,
            "BlackAlpha: the upgrade time has been terminated."    
        );
        uint256 pending = pendingWithdrawal(userAddr);
        user.paidOut = pending;
        DAI.transfer(userAddr, pending);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract DataStorage {
    using Strings for uint256;

    IERC20 public DAI;
    uint256 public startTime;
    uint256 public userCount;
    uint256 public totalEntrance;

    struct User {
        address upAddr;
        address leftAddr;
        address rightAddr;
        uint256 entrance;
        uint256 earning;
        uint256 paidOut;
        uint256 leftVariance;
        uint256 rightVariance;
        uint256 leftPay;
        uint256 rightPay;
        uint16 leftUsers;
        uint16 rightUsers;
        uint16 depth;
        uint8 childsCount;
        uint8 isLeftOrRightChild;
        uint48 upgradeTime;
    }

    mapping(address => User) users;
    mapping(uint256 => address) public idToAddr;
    mapping(address => uint256) public addrToId;

    mapping(uint256 => uint256) directShare;

    mapping(address => mapping(uint256 => uint256)) public userTodayEarning;
    mapping(address => mapping(uint256 => uint256)) public userTodayFlash;

    function dayCounter() public view returns(uint256) {
        return (block.timestamp - startTime) / 1 days;
    }

    function dashboard() public view returns(
        uint256 _userCount,
        uint256 _totalEntrance
    ) {
        _userCount = userCount;
        _totalEntrance = totalEntrance;
    }

    function userDashboard(address userAddr) public view returns(
        uint16 depth,
        uint256 entrance,
        uint256 paidOut,
        uint256 pending,
        uint256 leftPay,
        uint256 rightPay,
        uint256 leftUsers,
        uint256 rightUsers
    ) {
        User storage user = users[userAddr];
        depth = user.depth;
        entrance = user.entrance;
        paidOut = user.paidOut;
        pending = pendingWithdrawal(userAddr);
        leftPay = user.leftPay;
        rightPay = user.rightPay;
        leftUsers = user.leftUsers;
        rightUsers = user.rightUsers;
    }

    function pendingWithdrawal(address userAddr) internal view returns(uint256 pending) {
        User storage user = users[userAddr];
        pending = user.earning - user.paidOut;
    }

    function upgradeRemainingTime(address userAddr) public view returns(string memory ans) {
        User storage user = users[userAddr];
        
        if(user.entrance == 0) {
            ans = "unregistered user";
        } else if(user.upgradeTime == 0) {
            ans = "user not flashed";
        } else if(block.timestamp > user.upgradeTime) {
            ans = string.concat("remaining:", (block.timestamp - user.upgradeTime).toString());
        } else {
            ans = "upgrade time terminated";
        }
    }

}