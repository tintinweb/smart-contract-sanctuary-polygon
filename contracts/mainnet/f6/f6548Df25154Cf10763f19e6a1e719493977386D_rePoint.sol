// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRePointToken is IERC20 {
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../ERC20/IRePointToken.sol";
import "./EnumerableArrays.sol";
import "./PriceFeed.sol";

import "./LotteryPool/LotteryPool.sol";
import "./ExtraPool/ExtraPool.sol";
import "./SystemPool/SystemPool.sol";


abstract contract DataStorage is EnumerableArrays, PriceFeed {

    IRePointToken RPT;
    LotteryPool public LPool;
    ExtraPool public XPool;
    SystemPool SPool;   

    address payable rewardAddr;
    address payable lotteryAddr;
    address payable extraAddr;
    address payable systemAddr;


    struct NodeData {
        uint24 allUsersLeft;
        uint24 allUsersRight;
        uint24 allLeftDirect;
        uint24 allRightDirect;
        uint16 leftVariance;
        uint16 rightVariance;
        uint16 depth;
        uint16 maxPoints;
        uint16 childs;
        uint16 isLeftOrRightChild;
    }

    struct NodeInfo {
        address uplineAddress;
        address leftDirectAddress;
        address rightDirectAddress;
    }

    mapping(address => uint256) _userAllEarned_USD;
    mapping(address => NodeData) _userData;
    mapping(address => NodeInfo) _userInfo;
    mapping(string => address) public nameToAddr;
    mapping(address => string) public addrToName;
    mapping(uint256 => string) public idToName;

    uint256 public allPayments_USD;
    uint256 public allPayments_MATIC;

    uint256 public lastReward24h;
    uint256 public lastReward7d;
    uint256 public lastReward30d;
    uint256 public userCount;
    uint256 public todayTotalPoint;
    uint256 public todayPointOverflow;
    uint256 public todayEnteredUSD;
    uint256 public allEnteredUSD;
    uint256 maxOld;


    function AllPayments() public view returns(
        uint256 rewardPaymentsMATIC,
        uint256 rewardPaymentsUSD,
        uint256 extraPaymentsMATIC,
        uint256 extraPaymentsUSD,
        uint256 lotteryPaymentsMATIC,
        uint256 lotteryPaymentsUSD
    ) {
        rewardPaymentsMATIC = allPayments_MATIC;
        rewardPaymentsUSD = allPayments_USD;
        extraPaymentsMATIC = XPool.allPayments_MATIC();
        extraPaymentsUSD = XPool.allPayments_USD();
        lotteryPaymentsMATIC = LPool.allPayments_MATIC();
        lotteryPaymentsUSD = LPool.allPayments_USD();
    }

    function dashboard(bool getLists) public view returns(
        uint256 userCount_,
        uint256 pointValue_,
        uint256 extraPointValue_,
        uint256 lotteryPointValue_,
        uint256 todayPoints_,
        uint256 extraPoints_,
        uint256 todayEnteredUSD_,
        uint256 allEnteredUSD_,
        uint256 lotteryTickets_,
        uint256 rewardPoolBalance_,
        uint256 extraPoolBalance_,
        uint256 lotteryPoolBalance_,
        uint256 extraRewardReceiversCount_,
        string[] memory lastLotteryWinners_,
        string[] memory extraRewardReceivers_
    ) {
        userCount_ = userCount;
        pointValue_ = todayEveryPointValue(); 
        extraPointValue_ = XPool.exPointValue(); 
        lotteryPointValue_ = LPool.lotteryFractionValue(); 
        todayPoints_ = todayTotalPoint;
        extraPoints_ = XPool.extraPointCount();
        todayEnteredUSD_ = todayEnteredUSD;
        allEnteredUSD_ = allEnteredUSD;
        lotteryTickets_ = LPool.lotteryTickets();
        rewardPoolBalance_ = balance();
        extraPoolBalance_ = XPool.balance();
        lotteryPoolBalance_ = LPool.balance();
        extraRewardReceiversCount_ = XPool.extraRewardReceiversCount();
        if(getLists) {
            lastLotteryWinners_ = lastLotteryWinners();
            extraRewardReceivers_ = extraRewardReceivers();
        }
    }

    function userDashboard(string calldata username) public view returns(
        uint256 depth,
        uint256 todayPoints,
        uint256 maxPoints,
        uint256 extraPoints,
        uint256 lotteryTickets,
        uint256 todayLeft,
        uint256 todayRight,
        uint256 allTimeLeft,
        uint256 allTimeRight,
        uint256 usersLeft,
        uint256 usersRight,
        uint256 rewardEarned,
        uint256 extraEarned,
        uint256 lotteryEarned
    ) {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");
        uint256 points = _todayPoints[dayCounter][userAddr];

        depth = _userData[userAddr].depth;
        todayPoints = _todayPoints[dayCounter][userAddr];
        maxPoints = _userData[userAddr].maxPoints;
        extraPoints = XPool.userExtraPoints(userAddr);
        lotteryTickets = LPool.userTickets(userAddr);
        todayLeft = _userData[userAddr].leftVariance + points;
        todayRight = _userData[userAddr].rightVariance + points;
        allTimeLeft = _userData[userAddr].allLeftDirect;
        allTimeRight = _userData[userAddr].allRightDirect;
        usersLeft = _userData[userAddr].allUsersLeft;
        usersRight = _userData[userAddr].allUsersRight;
        rewardEarned = _userAllEarned_USD[userAddr];
        extraEarned = XPool._userAllEarned_USD(userAddr);
        lotteryEarned = LPool._userAllEarned_USD(userAddr);
    }

    function usernameExists(string calldata username) public view returns(bool) {
        return nameToAddr[username] != address(0);
    }

    function userAddrExists(address userAddr) public view returns(bool) {
        return bytes(addrToName[userAddr]).length != 0;
    }

    function balance() public view returns(uint256) {
        return address(this).balance;
    }

    function todayEveryPointValue() public view returns(uint256) {
        uint256 denominator = todayTotalPoint;
        denominator = denominator > 0 ? denominator : 1;
        return address(this).balance / denominator;
    }

    function todayEveryPointValueUSD() public view returns(uint256) {
        return todayEveryPointValue() * MATIC_USD/10**18;
    }

    function userUpReferral(string calldata username) public view returns(string memory) {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");
        return addrToName[_userInfo[userAddr].uplineAddress];
    }

    function userChilds(string calldata username)
        public
        view
        returns (string memory left, string memory right)
    {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");
        left = addrToName[_userInfo[userAddr].leftDirectAddress];
        right = addrToName[_userInfo[userAddr].rightDirectAddress];        
    }

    function userTree(string calldata username, uint256 len) public view returns(string[] memory temp) {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");
        address[] memory addrs = new address[](len + 1 + len % 2);
        temp = new string[](len);

        addrs[0] = userAddr;

        uint256 i = 0;
        uint256 j = 1;
        while(j < len) {
            addrs[j] = _userInfo[addrs[i]].leftDirectAddress;
            addrs[j + 1] = _userInfo[addrs[i]].rightDirectAddress;
            i++;
            j += 2;
        }
        for(uint256 a; a < len; a++) {
            temp[a] = addrToName[addrs[a + 1]];
        }
    } 

    function userChildsCount(string calldata username)
        public
        view
        returns (uint256)
    {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");
        return _userData[userAddr].childs;        
    }
    
    function userTodayPoints(string calldata username) public view returns (uint256) {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");
        return _todayPoints[dayCounter][userAddr];
    }

    function userMonthPoints(string calldata username) public view returns(uint256) {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");
        uint256 under50 = 
            _monthDirectLeft[monthCounter][userAddr] < _monthDirectRight[monthCounter][userAddr] ?
            _monthDirectLeft[monthCounter][userAddr] : _monthDirectRight[monthCounter][userAddr];
        return XPool.userExtraPoints(userAddr) * 50 + under50;
    }

    function userMonthDirects(string calldata username) public view returns(uint256 directLeft, uint256 directRight) {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");
        uint256 monthPoints = XPool.userExtraPoints(userAddr) * 50;
        directLeft = monthPoints + _monthDirectLeft[monthCounter][userAddr];
        directRight = monthPoints + _monthDirectRight[monthCounter][userAddr];
    }

    function extraRewardReceivers() public view returns(string[] memory temp) {
        address[] memory addrs = XPool.extraRewardReceivers();
        uint256 len = addrs.length;
        temp = new string[](len);

        for(uint256 i; i < len; i++) {
            temp[i] = addrToName[addrs[i]];
        }
    }

    function extraRewardReceiversAddr() public view returns(address[] memory temp) {
        address[] memory addrs = XPool.extraRewardReceivers();
        uint256 len = addrs.length;
        temp = new address[](len);

        for(uint256 i; i < len; i++) {
            temp[i] = addrs[i];
        }
    }

    function lastLotteryWinners() public view returns(string[] memory temp) {
        address[] memory addrs = LPool.lastLotteryWinners();
        uint256 len = addrs.length;
        temp = new string[](len);

        for(uint256 i; i < len; i++) {
            temp[i] = addrToName[addrs[i]];
        }
    }

    function lastLotteryWinnersAddr() public view returns(address[] memory temp) {
        address[] memory addrs = LPool.lastLotteryWinners();
        uint256 len = addrs.length;
        temp = new address[](len);

        for(uint256 i; i < len; i++) {
            temp[i] = addrs[i];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract EnumerableArrays {

    mapping(uint256 => mapping(address => uint256)) _monthDirectLeft;
    mapping(uint256 => mapping(address => uint256)) _monthDirectRight;
    mapping(uint256 => mapping(address => uint16)) _todayPoints;
    mapping(uint256 => address[]) _rewardReceivers;

    uint256 rrIndex;
    uint256 monthCounter;
    uint256 dayCounter;
    
    function _resetRewardReceivers() internal {
        rrIndex++;
    }
    function _resetMonthPoints() internal {
        monthCounter ++;
    }
    function _resetDayPoints() internal {
        dayCounter ++;
    }

    function todayRewardReceivers() public view returns(address[] memory addr) {
        uint256 len = _rewardReceivers[rrIndex].length;
        addr = new address[](len);

        for(uint256 i; i < len; i++) {
            addr[i] = _rewardReceivers[rrIndex][i];
        }
    }

    function todayRewardReceiversCount() public view returns(uint256) {
        return _rewardReceivers[rrIndex].length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./XDataStorage.sol";

contract ExtraPool is XDataStorage{

    address public repoint;

    constructor (address _repoint) {
        repoint = _repoint;
    }

    modifier onlyrePoint() {
        require(msg.sender == repoint, "only repoint can call this function");
        _;
    }

    function distribute(uint256 MATIC_USD) public onlyrePoint {
        uint256 count = extraRewardReceiversCount();
        uint256 _balance = balance();
        if(count > 0) {
            uint256 balanceUSD = _balance * MATIC_USD/10**18;
            uint256 _exPointValue = exPointValue();
            for(uint256 i; i < count; i++) {
                address userAddr = _extraRewardReceivers[erIndex][i];
                uint256 earning = _userExtraPoints[epIndex][userAddr] * _exPointValue;
                _userAllEarned_USD[userAddr] += earning * MATIC_USD/10**18;
                payable(userAddr).transfer(earning);
            }
            allPayments_USD += balanceUSD;
            allPayments_MATIC += _balance;
        }
        delete extraPointCount;
        _resetExtraPoints();
        _resetExtraRewardReceivers();
    }

    function addAddr(address userAddr) public onlyrePoint {
        uint256 userPoints = _userExtraPoints[epIndex][userAddr];
        if(userPoints == 0) {
            _extraRewardReceivers[erIndex].push(userAddr);
        }
        if(userPoints <= 30) {
            extraPointCount ++;
            _userExtraPoints[epIndex][userAddr] ++;
        }
    }

    receive() external payable{}

    function panicWithdraw() public onlyrePoint {
        payable(repoint).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract XDataStorage {
    
    uint256 erIndex;
    uint256 epIndex;

    mapping(uint256 => address[]) _extraRewardReceivers;
    mapping(uint256 => mapping(address => uint256)) _userExtraPoints;

    function _resetExtraPoints() internal {
        epIndex ++;
    }
    function _resetExtraRewardReceivers() internal {
        erIndex++;
    }

    function extraRewardReceivers() public view returns(address[] memory addr) {
        uint256 len = _extraRewardReceivers[erIndex].length;
        addr = new address[](len);

        for(uint256 i; i < len; i++) {
            addr[i] = _extraRewardReceivers[erIndex][i];
        }
    }

    function extraRewardReceiversCount() public view returns(uint256) {
        return _extraRewardReceivers[erIndex].length;
    }

    function userExtraPoints(address userAddr) public view returns(uint256) {
        return _userExtraPoints[epIndex][userAddr];
    }

    mapping(address => uint256) public _userAllEarned_USD;

    uint256 public allPayments_USD;
    uint256 public allPayments_MATIC;
    uint256 public extraPointCount;

    function balance() public view returns(uint256) {
        return address(this).balance;
    }

    function exPointValue() public view returns(uint256) {
        uint256 denom = extraPointCount;
        if(denom == 0) {denom = 1;}
        return balance() / denom;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library LiteralRegex {

    string constant regex = "[a-zA-Z0-9-._]";

    function isLiteral(string memory text) internal pure returns(bool) {
        bytes memory t = bytes(text);
        for (uint i = 0; i < t.length; i++) {
            if(!_isLiteral(t[i])) {return false;}
        }
        return true;
    }

    function _isLiteral(bytes1 char) private pure returns(bool status) {
        if (  
            char >= 0x30 && char <= 0x39 // `0-9`
            ||
            char >= 0x41 && char <= 0x5a // `A-Z`
            ||
            char >= 0x61 && char <= 0x7a // `a-z`
            ||
            char == 0x2d                 // `-`
            ||
            char == 0x2e                 // `.`
            ||
            char == 0x5f                 // `_`
        ) {
            status = true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


abstract contract LDataStorage {

    uint256 lcIndex;
    uint256 lwIndex;

    mapping(uint256 => address[]) _lotteryCandidates;
    mapping(uint256 => address[]) _lotteryWinners;

    function _resetLotteryCandidates() internal {
        lcIndex++;
    }
    function _resetLotteryWinners() internal {
        lwIndex++;
    }

    function todayLotteryCandidates() public view returns(address[] memory addr) {
        uint256 len = _lotteryCandidates[lcIndex].length;
        addr = new address[](len);

        for(uint256 i; i < len; i++) {
            addr[i] = _lotteryCandidates[lcIndex][i];
        }
    }

    function lastLotteryWinners() public view returns(address[] memory addr) {
        uint256 len = _lotteryWinners[lwIndex].length;
        addr = new address[](len);

        for(uint256 i; i < len; i++) {
            addr[i] = _lotteryWinners[lwIndex][i];
        }
    }

    function lotteryCandidatesCount() public view returns(uint256) {
        return _lotteryCandidates[lcIndex].length;
    }

    function lastLotteryWinnersCount() public view returns(uint256) {
        return _lotteryWinners[lwIndex].length;
    }


    mapping(address => uint256) public _userAllEarned_USD;

    uint256 public allPayments_USD;
    uint256 public allPayments_MATIC;

    function balance() public view returns(uint256) {
        return address(this).balance;
    }

    function lotteryWinnersCount() public view returns(uint256) {
        uint256 count = lotteryCandidatesCount();
        return count % 20 == 0 ? count * 5/100 : count * 5/100 + 1;
    }

    function lotteryFractionValue() public view returns(uint256) {
        uint256 denom = lotteryWinnersCount();
        if(denom == 0) {denom = 1;}
        return balance() / denom;
    }


    uint256 utIndex;
    mapping(uint256 => mapping(address => uint256)) _userTickets;

    uint256 public lotteryTickets;

    function userTickets(address userAddr) public view returns(uint256) {
        return _userTickets[utIndex][userAddr];
    }

    function _resetUserTickets() internal {
        utIndex++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./LDataStorage.sol";

contract LotteryPool is LDataStorage {
    
    address public repoint;

    constructor (address _repoint) {
        repoint = _repoint;
    }

    modifier onlyrePoint() {
        require(msg.sender == repoint, "only repoint can call this function");
        _;
    }

    function distribute(uint256 MATIC_USD) public onlyrePoint {
        _resetLotteryWinners();

        address[] storage lotteryCandidates = _lotteryCandidates[lcIndex];
        address[] storage lotteryWinners = _lotteryWinners[lwIndex];

        uint256 _balance = balance();
        uint256 _balanceUSD = _balance * MATIC_USD/10**18;

        uint256 winnersCount = lotteryWinnersCount();
        uint256 candidatesCount = lotteryCandidatesCount();
        uint256 lotteryFraction = lotteryFractionValue();
        address winner;

        uint256 randIndex = uint256(keccak256(abi.encodePacked(
            block.timestamp, block.difficulty, MATIC_USD
        )));
        for(uint256 i; i < winnersCount; i++) {
            randIndex = uint256(keccak256(abi.encodePacked(randIndex, i))) % candidatesCount;
            candidatesCount--;
            winner = lotteryCandidates[randIndex];
            lotteryCandidates[randIndex] = lotteryCandidates[candidatesCount];
            lotteryWinners.push(winner);
            _userAllEarned_USD[winner] += lotteryFraction * MATIC_USD/10**18;
            payable(winner).transfer(lotteryFraction);
        }
        if(balance() < 10 ** 10) {
            allPayments_USD += _balanceUSD;
            allPayments_MATIC += _balance;
        }
        delete lotteryTickets;
        _resetLotteryCandidates();
        _resetUserTickets();
    }

    function addAddr(address userAddr, uint256 numTickets) public payable onlyrePoint {
        for(uint256 i; i < numTickets; i++) {
            _lotteryCandidates[lcIndex].push(userAddr);
        }
        lotteryTickets += numTickets;
        _userTickets[utIndex][userAddr] += numTickets;
    }

    receive() external payable{}

    function panicWithdraw() public onlyrePoint {
        payable(repoint).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract PriceFeed {
    using Strings for uint256;
    AggregatorInterface immutable AGGREGATOR_MATIC_USD;

    uint256 public MATIC_USD;
    uint256 public USD_MATIC;

    uint256 public lastUpdatePrice;

    constructor(
        address aggregatorAddr
    ) {
        AGGREGATOR_MATIC_USD = AggregatorInterface(aggregatorAddr);
        _updateMaticePrice();
    }

    function USD_MATIC_Multiplier(uint256 num) public view returns(uint256) {
        return num * USD_MATIC;
    }

    function USD_MATIC_Multiplier_String(uint256 num) public view returns(string memory) {
        return string.concat("s", (num * USD_MATIC).toString());
    }

    function get_MATIC_USD() private view returns(uint256) {
        return uint256(AGGREGATOR_MATIC_USD.latestAnswer());
    }

    function _updateMaticePrice() internal {
        uint256 MATIC_USD_8 = get_MATIC_USD();
        MATIC_USD = MATIC_USD_8 * 10 ** 10;
        USD_MATIC = 10 ** 26 / MATIC_USD_8;
    }

    function updateMaticPrice() public {
        require(
            block.timestamp > lastUpdatePrice + 4 hours,
            "time exception"
        );
        lastUpdatePrice = block.timestamp;
        _updateMaticePrice();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./DataStorage.sol";
import "./LiteralRegex.sol";

contract rePoint is DataStorage {
    using LiteralRegex for string;

    constructor(
        address RPT_Addr,
        address _aggregator,
        address[] memory _system,
        uint256[] memory _fractions,
        uint256 _maxOld,
        uint256 allPayments_MATIC_,
        uint256 allPayments_USD_,
        uint256 allEnteredUSD_
    ) PriceFeed (_aggregator) {
        address repointAddr = address(this);

        RPT = IRePointToken(RPT_Addr);
        LPool = new LotteryPool(repointAddr);
        XPool = new ExtraPool(repointAddr);
        SPool = new SystemPool(_system, _fractions);

        allPayments_MATIC = allPayments_MATIC_;
        allPayments_USD = allPayments_USD_;
        allEnteredUSD = allEnteredUSD_;        

        lotteryAddr = payable(address(LPool));        
        extraAddr = payable(address(XPool));
        systemAddr = payable(address(SPool));

        maxOld = _maxOld;
        lastReward24h = 1678017600000;
        lastReward7d = 1677671100000;
        lastReward30d = 1677843900000;
    }


    function register(string calldata upReferral, string calldata username) public payable {
        uint256 enterPrice = msg.value;
        address userAddr = msg.sender;
        address upAddr = nameToAddr[upReferral];

        checkCanRegister(upReferral, username, upAddr, userAddr);
        (uint16 todayPoints, uint16 maxPoints, uint16 directUp, uint256 enterPriceUSD) = checkEnterPrice(enterPrice);

        _payShares(enterPrice, enterPriceUSD);

        _newUsername(userAddr, username);
        _newNode(userAddr, upAddr, maxPoints, todayPoints);
        _setChilds(userAddr, upAddr);
        _setDirects(userAddr, upAddr, directUp, 1);
    }

    function checkCanRegister(
        string calldata upReferral,
        string calldata username,
        address upAddr,
        address userAddr
    ) internal view returns(bool) {
        require(
            userAddr.code.length == 0,
            "onlyEOAs can register"
        );
        uint256 usernameLen = bytes(username).length;
        require(
            usernameLen >= 4 && usernameLen <= 16,
            "the username must be between 4 and 16 characters" 
        );
        require(
            username.isLiteral(),
            "you can just use numbers(0-9) letters(a-zA-Z) and signs(-._)" 
        );
        require(
            !usernameExists(username),
            "This username is taken!"
        );
        require(
            !userAddrExists(userAddr),
            "This address is already registered!"
        );
        require(
            usernameExists(upReferral),
            "This upReferral does not exist!"
        );
        require(
            _userData[upAddr].childs < 2,
            "This address have two directs and could not accept new members!"
        );
        return true;
    }

    function checkEnterPrice(uint256 enterPrice) public view returns(
        uint16 todayPoints, uint16 maxPoints, uint16 directUp, uint256 enterPriceUSD
    ) {
        if(enterPrice == USD_MATIC_Multiplier(20)) {
            maxPoints = 10;
            directUp = 1;
            enterPriceUSD = 20 * 10 ** 18;
        } else if(enterPrice == USD_MATIC_Multiplier(60)) {
            maxPoints = 30;
            directUp = 3;
            enterPriceUSD = 60 * 10 ** 18;
        } else if(enterPrice == USD_MATIC_Multiplier(100)) {
            todayPoints = 1;
            maxPoints = 50;
            directUp = 5;
            enterPriceUSD = 100 * 10 ** 18;
        } else {
            revert("Wrong enter price");
        }
    }

    function _payShares(uint256 enterPrice, uint256 enterPriceUSD) internal {
        todayEnteredUSD += enterPriceUSD;
        allEnteredUSD += enterPriceUSD;
        
        lotteryAddr.transfer(enterPrice * 15/100);
        extraAddr.transfer(enterPrice * 10/100);
        systemAddr.transfer(enterPrice * 5/100);
    }

    function _newUsername(address userAddr, string memory username) internal {
        nameToAddr[username] = userAddr;
        addrToName[userAddr] = username;
        idToName[userCount] = username;
        userCount++;
    }

    function _newNode(address userAddr, address upAddr, uint16 maxPoints, uint16 todayPoints) internal {
        _userData[userAddr] = NodeData (
            0,
            0,
            0,
            0,
            0,
            0,
            _userData[upAddr].depth + 1,
            maxPoints,
            0,
            _userData[upAddr].childs
        );
        _userInfo[userAddr] = NodeInfo (
            upAddr,
            address(0),
            address(0)
        );
        if(todayPoints == 1) {
            _rewardReceivers[rrIndex].push(userAddr);
            _todayPoints[dayCounter][userAddr] = 1;
            todayTotalPoint ++;
        }
    }

    function _setChilds(address userAddr, address upAddr) internal {

        if (_userData[upAddr].childs == 0) {
            _userInfo[upAddr].leftDirectAddress = userAddr;
        } else {
            _userInfo[upAddr].rightDirectAddress = userAddr;
        }
        _userData[upAddr].childs++;
    }

    function _setDirects(address userAddr, address upAddr, uint16 directUp, uint16 userUp) internal { 
        address[] storage rewardReceivers = _rewardReceivers[rrIndex];

        uint256 depth = _userData[userAddr].depth;
        uint16 _pointsOverflow;
        uint16 _totalPoints;
        uint16 points;
        uint16 v;
        uint16 userTodayPoints;
        uint16 userNeededPoints;
        for (uint256 i; i < depth; i++) {
            if (_userData[userAddr].isLeftOrRightChild == 0) {
                if(_userData[upAddr].rightVariance == 0){
                    _userData[upAddr].leftVariance += directUp;
                } else {
                    if(_userData[upAddr].rightVariance < directUp) {
                        v = _userData[upAddr].rightVariance;
                        _userData[upAddr].rightVariance = 0;
                        _userData[upAddr].leftVariance += directUp - v;
                        points = v;
                    } else {
                        _userData[upAddr].rightVariance -= directUp;
                        points = directUp;
                    }
                }
                _userData[upAddr].allUsersLeft += userUp;
                _userData[upAddr].allLeftDirect += directUp;
                _addMonthDirectLeft(upAddr, directUp);
            } else {
                if(_userData[upAddr].leftVariance == 0){
                    _userData[upAddr].rightVariance += directUp;
                } else {
                    if(_userData[upAddr].leftVariance < directUp) {
                        v = _userData[upAddr].leftVariance;
                        _userData[upAddr].leftVariance = 0;
                        _userData[upAddr].rightVariance += directUp - v;
                        points = v;
                    } else {
                        _userData[upAddr].leftVariance -= directUp;
                        points = directUp;
                    }
                }
                _userData[upAddr].allUsersRight += userUp;
                _userData[upAddr].allRightDirect += directUp;
                _addMonthDirectRight(upAddr, directUp);
            }

            if(points > 0) {
                userTodayPoints = _todayPoints[dayCounter][upAddr];
                userNeededPoints = _userData[upAddr].maxPoints - userTodayPoints;
                if(userNeededPoints > 0) {
                    if(userNeededPoints >= points) {
                        if(userTodayPoints == 0){
                            rewardReceivers.push(upAddr);
                        }
                        _todayPoints[dayCounter][upAddr] += points;
                        _totalPoints += points;
                    } else {
                        _todayPoints[dayCounter][upAddr] += userNeededPoints;
                        _totalPoints += userNeededPoints;
                        _pointsOverflow += points - userNeededPoints;
                        delete _userData[upAddr].leftVariance;
                        delete _userData[upAddr].rightVariance;
                    }
                } else {
                    _pointsOverflow += points;
                }
                points = 0;
            }
            userAddr = upAddr;
            upAddr = _userInfo[upAddr].uplineAddress;
        }

        todayTotalPoint += _totalPoints;
        todayPointOverflow += _pointsOverflow;
    }


    function topUp() public payable {
        address userAddr = msg.sender;
        uint256 topUpPrice = msg.value;

        address upAddr = _userInfo[userAddr].uplineAddress;
        (uint16 maxPoints, uint16 directUp, uint256 topUpPriceUSD) = _checkTopUpPrice(userAddr, topUpPrice);

        _payShares(topUpPrice, topUpPriceUSD);
        _setDirects(userAddr, upAddr, directUp, 0);
                        
        _userData[userAddr].maxPoints += maxPoints;
    }

    function _checkTopUpPrice(address userAddr, uint256 topUpPrice) internal view returns(
        uint16 maxPoints, uint16 directUp, uint256 topUpPriceUSD
    ) {
        require(
            userAddrExists(userAddr),
            "You have not registered!"
        );

        if(topUpPrice == USD_MATIC_Multiplier(40)) {
            require(
                _userData[userAddr].maxPoints != 50,
                "the highest max point possible is 50"
            );
            maxPoints = 20;
            directUp = 2;
            topUpPriceUSD = 40 * 10 ** 18;
        } else if(topUpPrice == USD_MATIC_Multiplier(80)) {
            require(
                _userData[userAddr].maxPoints == 10,
                "the highest max point is 50"
            );
            maxPoints = 40;
            directUp = 4;
            topUpPriceUSD = 80 * 10 ** 18;
        } else {
            revert("Wrong TopUp price");
        }
    }

    function distribute() public {
        uint256 currentTime = block.timestamp;
        uint256 _MATIC_USD = MATIC_USD;
        require(
            currentTime >= lastReward24h + 24 hours - 5 minutes,
            "The distribute Time Has Not Come"
        );
        lastReward24h = currentTime;
        _reward24h(_MATIC_USD);
        SPool.distribute();
        if(currentTime >= lastReward7d + 7 days - 35 minutes) {
            lastReward7d = currentTime;
            LPool.distribute(_MATIC_USD);
        }
        if(currentTime >= lastReward30d + 30 days - 150 minutes) {
            lastReward30d = currentTime;
            XPool.distribute(_MATIC_USD);
            _resetMonthPoints();
        }
        _updateMaticePrice();

    }

    function _reward24h(uint256 _MATIC_USD) internal {

        uint256 pointValue = todayEveryPointValue();
        uint256 pointValueUSD = pointValue * _MATIC_USD/10**18;

        address[] storage rewardReceivers = _rewardReceivers[rrIndex];

        address userAddr;
        uint256 len = rewardReceivers.length;
        uint256 userPoints;
        for(uint256 i; i < len; i++) {
            userAddr = rewardReceivers[i];
            userPoints = _todayPoints[dayCounter][userAddr];
            _userAllEarned_USD[userAddr] += userPoints * pointValueUSD;
            payable(userAddr).transfer(userPoints * pointValue);
        }

        allPayments_MATIC += todayTotalPoint * pointValue;
        allPayments_USD += todayTotalPoint * pointValueUSD;

        delete todayTotalPoint;
        delete todayPointOverflow;
        delete todayEnteredUSD;
        _resetRewardReceivers();
        _resetDayPoints();
    }

    function _addMonthDirectLeft(address userAddr, uint256 directLeft) internal {
        uint256 neededDirectLeft = 50 - _monthDirectLeft[monthCounter][userAddr];

        if(neededDirectLeft > directLeft) {
            _monthDirectLeft[monthCounter][userAddr] += directLeft;
        } else {
            if(_monthDirectRight[monthCounter][userAddr] < 50) {
                _monthDirectLeft[monthCounter][userAddr] += directLeft;
            } else {
                _monthDirectRight[monthCounter][userAddr] -= 50;
                _monthDirectLeft[monthCounter][userAddr] = directLeft - neededDirectLeft;
                XPool.addAddr(userAddr);
            }
        }
    }

    function _addMonthDirectRight(address userAddr, uint256 directRight) internal {
        uint256 neededDirectRight = 50 - _monthDirectRight[monthCounter][userAddr];

        if(neededDirectRight > directRight) {
            _monthDirectRight[monthCounter][userAddr] += directRight;
        } else {
            if(_monthDirectLeft[monthCounter][userAddr] < 50) {
                _monthDirectRight[monthCounter][userAddr] += directRight;
            } else {
                _monthDirectLeft[monthCounter][userAddr] -= 50;
                _monthDirectRight[monthCounter][userAddr] = directRight - neededDirectRight;
                XPool.addAddr(userAddr);
            }
        }
    }

    function registerInLottery(uint256 rptAmount) public payable {
        address userAddr = msg.sender;
        uint256 paidAmount = msg.value;
        require(
            userAddrExists(userAddr),
            "This address is not registered in rePoint Contract!"
        );
        require(
            rptAmount == 0 || paidAmount == 0,
            "payment by RPT and MATIC in the same time"
        );
        uint256 ticketPrice;
        uint256 numTickets;
        if(rptAmount != 0) {
            ticketPrice = 50 * 10 ** 18;
            require(
                rptAmount >= ticketPrice,
                "minimum lottery enter price is 50 RPTs"
            );
            numTickets = rptAmount / ticketPrice;
            RPT.burnFrom(userAddr, rptAmount);
        } else {
            ticketPrice = 1 * USD_MATIC;
            require(
                paidAmount >= ticketPrice,
                "minimum lottery enter price is 1 USD in MATIC"
            );
            numTickets = paidAmount / ticketPrice;
        }
        require(
            LPool.userTickets(userAddr) + numTickets <= 5,
            "maximum 5 tickets"
        );
        LPool.addAddr{value : paidAmount}(userAddr, numTickets);
    }

    function uploadOldUsers(
        string calldata upReferral,
        string calldata username,
        address userAddr,
        uint16 depth,
        uint16 maxPoints,
        uint8 isLeftOrRightChild,
        uint8 childsCount,
        uint24 allUsersLeft,
        uint24 allUsersRight,
        uint24 allLeftDirect,
        uint24 allRightDirect,
        uint16 leftVariance,
        uint16 rightVariance,
        uint256 rewardEarned,
        uint256 numTickets,
        address childLeft,
        address childRight
    ) public {
        require(userCount < maxOld, "maximum old");
        require(
            !usernameExists(username),
            "This username is taken!"
        );
        require(
            !userAddrExists(userAddr),
            "This address is already registered!"
        );
        if(userCount > 0) {
            require(
                usernameExists(upReferral),
                "This upReferral does not exist!"
            );
        }
        address upAddr = nameToAddr[upReferral];
        _userData[userAddr] = NodeData (
            allUsersLeft,
            allUsersRight,
            allLeftDirect,
            allRightDirect,
            leftVariance,
            rightVariance,
            depth,
            maxPoints,
            childsCount,
            isLeftOrRightChild
        );
        _userInfo[userAddr] = NodeInfo (
            upAddr,
            childLeft,
            childRight
        );
        _userAllEarned_USD[userAddr] = rewardEarned;
        _newUsername(userAddr, username);
        LPool.addAddr{value : 0}(userAddr, numTickets);
    }

    function emergencyMainDistribute() public {
        require(
            block.timestamp >= lastReward24h + 3 days,
            "The Emergency Time Has Not Come"
        );
        lastReward24h = block.timestamp;
        uint256 _MATIC_USD = MATIC_USD;
        _reward24h(_MATIC_USD);
        _updateMaticePrice();
    }

    function emergencyLPoolDistribute() public {
        require(
            block.timestamp >= lastReward7d + 10 days,
            "The Emergency Time Has Not Come"
        );
        lastReward7d = block.timestamp;
        LPool.distribute(MATIC_USD);
    }

    function emergencyXPoolDistribute() public {
        require(
            block.timestamp >= lastReward30d + 33 days,
            "The Emergency Time Has Not Come"
        );
        lastReward30d = block.timestamp;
        XPool.distribute(MATIC_USD);
    }

    function panic7d() public {
        require(
            block.timestamp > lastReward24h + 7 days,
            "The panic situation has not happend"
        );
        XPool.panicWithdraw();
        LPool.panicWithdraw();
        systemAddr.transfer(balance());
    }
    
    receive() external payable{}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SystemPool {
    
    address[] _members_;
    mapping(address => uint256) _fractions_;

    constructor (address[] memory _members, uint256[] memory _fractions) {
        require(
            _members.length == _fractions.length, 
            "_fractions_ and _members_ length difference"
        );
        uint256 denom;
        for(uint256 i; i < _fractions.length; i++) {
            denom += _fractions[i];
            _fractions_[_members[i]] = _fractions[i];
        }
        require(denom == 1000, "wrong denominator sum");
        _members_ = _members;
    }

    function members() public view returns(address[] memory temp) {
        uint256 len = _members_.length;
        temp = new address[](len);

        for(uint256 i; i < len; i++) {
            temp[i] = _members_[i];
        }
    }

    function fractions() public view returns(uint256[] memory temp) {
        uint256 len = _members_.length;
        temp = new uint256[](len);

        for(uint256 i; i < len; i++) {
            temp[i] = _fractions_[_members_[i]];
        }
    }
    
    function distribute() external {
        uint256 membersLen = _members_.length;
        uint256 balance = address(this).balance;
        address member;

        for(uint256 i; i < membersLen; i++) {
            member = _members_[i];
            payable(member).transfer(balance * _fractions_[member]/1000);
        }
    }

    receive() external payable {}
}