/**
 *Submitted for verification at polygonscan.com on 2023-01-16
*/

/**
 *Submitted for verification at polygonscan.com on 2023-01-16
 */

//SPDX-License-Identifier:MIT
// File: PRNG.sol
pragma solidity ^0.8.0;

library PRNG {
    struct Seed {
        uint256 _value;
    }

    function initBaseSeed(Seed storage seed) internal {
        unchecked {
            uint256 _timestamp = block.timestamp;
            seed._value =
                uint256(
                    keccak256(
                        abi.encodePacked(
                            _timestamp +
                                block.difficulty +
                                ((
                                    uint256(
                                        keccak256(
                                            abi.encodePacked(block.coinbase)
                                        )
                                    )
                                ) / (_timestamp)) +
                                block.gaslimit +
                                ((
                                    uint256(
                                        keccak256(abi.encodePacked(msg.sender))
                                    )
                                ) / (_timestamp)) +
                                block.number
                        )
                    )
                ) %
                1000000000000000;
        }
    }

    function next(Seed storage seed) internal returns (uint256, uint256) {
        uint256 generated_number = 0;
        unchecked {
            seed._value = seed._value + 1;
            generated_number = seed._value * 15485863;
            generated_number =
                (generated_number * generated_number * generated_number) %
                2038074743;
        }
        return (seed._value, generated_number);
    }
}

// File: Counters.sol

// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}
// File: @openzeppelin/contracts/utils/math/Math.sol

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
    function sqrt(uint256 a, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = sqrt(a);
            return
                result +
                (rounding == Rounding.Up && result * result < a ? 1 : 0);
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
    function log2(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = log2(value);
            return
                result +
                (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
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
    function log10(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = log10(value);
            return
                result +
                (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
    function log256(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = log256(value);
            return
                result +
                (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// File: lottery.sol

pragma solidity ^0.8.12;

contract Lottery {
    using Counters for Counters.Counter;
    using PRNG for PRNG.Seed;

    event UserEntrance(
        uint256 indexed lotteryId,
        uint256 indexed userIndex,
        address indexed userAddress
    );
    event FoundedWinners(
        uint256 indexed lotteryId,
        uint256 indexed winnerIndex,
        address indexed winnerAddress
    );

    event Lotteries(
        uint256 indexed lotteryId,
        address rewardSmartContractAddress,
        uint256 rewardPot,
        bool isLotteryFinished,
        uint256 userCount,
        uint256 winnerPrizeInToken,
        uint256 createDate
    );

    struct LotteryStructure {
        address[] users;
        mapping(address => uint256) winnersSeed;
        address[] winners;
        address rewardSmartContractAddress;
        bool isLotteryFinished;
        uint256 winnerPrizeInToken;
        uint256 lastAddedUserIndex;
        uint256 lastFoundedWinnerIndex;
    }
    Counters.Counter private _currentLotteryId;
    PRNG.Seed private _random;
    address private owner;
    mapping(uint256 => LotteryStructure) private _lotteries;

    constructor() {
        owner = msg.sender;
        _currentLotteryId.increment();
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Access Denied !");
        _;
    }

    function getLastLotteryId() public view returns (uint256) {
        return _currentLotteryId.current() - 1;
    }

    function createNewLottery(
        uint256 _usersCount,
        address _rewardSmartContractAddress,
        uint256 _winnersCount,
        uint256 _eachWinnerPrizeInToken
    ) public onlyOwner {
        uint256 currentLotteryId = _currentLotteryId.current();
        _lotteries[currentLotteryId].users = new address[](_usersCount);
        _lotteries[currentLotteryId].isLotteryFinished = false;

        _lotteries[currentLotteryId]
            .rewardSmartContractAddress = _rewardSmartContractAddress;
        _lotteries[currentLotteryId].winners = new address[](_winnersCount);
        _lotteries[currentLotteryId]
            .winnerPrizeInToken = _eachWinnerPrizeInToken;
        _currentLotteryId.increment();
        uint256 rewardPot = 0;
        unchecked {
            rewardPot = _winnersCount * _eachWinnerPrizeInToken;
        }
        emit Lotteries(
            currentLotteryId,
            _lotteries[currentLotteryId].rewardSmartContractAddress,
            rewardPot,
            _lotteries[currentLotteryId].isLotteryFinished,
            _lotteries[currentLotteryId].users.length,
            _lotteries[currentLotteryId].winnerPrizeInToken,
            block.timestamp
        );
    }

    function getLotteryById(uint256 _lotteryId)
        public
        view
        returns (string memory)
    {
        string memory isLotteryFinished = "false";
        if (_lotteries[_lotteryId].isLotteryFinished) {
            isLotteryFinished = "true";
        }
        string memory winnersCount;
        if (_lotteries[_lotteryId].winners.length > 0) {
            winnersCount = Strings.toString(
                _lotteries[_lotteryId].winners.length
            );
        } else {
            winnersCount = "0";
        }
        uint256 rewardPot = _lotteries[_lotteryId].winnerPrizeInToken *
            _lotteries[_lotteryId].winners.length;
        string memory result = "";
        if (_lotteries[_lotteryId].users.length > 0) {
            result = string.concat(
                "rewardSmartContractAddress:",
                Strings.toHexString(
                    _lotteries[_lotteryId].rewardSmartContractAddress
                ),
                ",rewardPot:",
                Strings.toString(rewardPot),
                ",isLotteryFinished:",
                isLotteryFinished,
                ",userCount:",
                Strings.toString(_lotteries[_lotteryId].users.length),
                ",winnerPrizeInToken:",
                Strings.toString(_lotteries[_lotteryId].winnerPrizeInToken),
                ",WinnersCount:",
                winnersCount
            );
        } else {
            result = "Lottery does not exist";
        }
        return result;
    }

    function getWinnersWithSeed(uint256 lotteryId, address winneraddress)
        public
        view
        returns (string memory)
    {
        require(
            _lotteries[lotteryId].winners.length > 0,
            "Lottery does not exist"
        );
        for (
            uint256 winnerIndex = 0;
            winnerIndex < _lotteries[lotteryId].winners.length;
            winnerIndex++
        ) {
            if (_lotteries[lotteryId].winners[winnerIndex] == winneraddress) {
                return
                    string.concat(
                        Strings.toHexString(
                            _lotteries[lotteryId].winners[winnerIndex]
                        ),
                        " : ",
                        Strings.toString(
                            _lotteries[lotteryId].winnersSeed[
                                _lotteries[lotteryId].winners[winnerIndex]
                            ]
                        )
                    );
            }
        }
        return "address not found in the winners list";
    }

    function getLotteryWinners(
        uint256 _lotteryId,
        uint256 fromIndex,
        uint256 toIndex
    ) public view returns (address[] memory) {
        require(toIndex < _lotteries[_lotteryId].winners.length);
        require(fromIndex < toIndex);
        address[] memory winnersResult = new address[](toIndex - fromIndex + 1);
        uint256 index = 0;
        for (uint256 i = fromIndex; i <= toIndex; ) {
            address result = _lotteries[_lotteryId].winners[i];
            winnersResult[index] = result;
            unchecked {
                index++;
                i++;
            }
        }
        return winnersResult;
    }

    function getLotteryUsers(
        uint256 _lotteryId,
        uint256 fromIndex,
        uint256 toIndex
    ) public view returns (address[] memory) {
        require(toIndex < _lotteries[_lotteryId].users.length);
        require(fromIndex < toIndex);
        address[] memory usersResult = new address[](toIndex - fromIndex + 1);
        uint256 index = 0;
        for (uint256 i = fromIndex; i <= toIndex; ) {
            address result = _lotteries[_lotteryId].users[i];
            usersResult[index] = result;
            unchecked {
                index++;
                i++;
            }
        }
        return usersResult;
    }

    function getUserLotteryPositions(uint256 _lotteryId, address userAddress)
        public
        view
        returns (string memory)
    {
        require(
            _lotteries[_lotteryId].users.length > 0,
            "Lottery does not exist"
        );
        string memory result = "[";
        bool isFirstItem = true;
        for (uint256 i = 0; i < _lotteries[_lotteryId].users.length; i++) {
            if (_lotteries[_lotteryId].users[i] == userAddress) {
                if (isFirstItem) {
                    string.concat(Strings.toString(i));
                    isFirstItem = false;
                } else {
                    string.concat(",", Strings.toString(i));
                }
            }
        }
        string.concat("]");
        return result;
    }

    function finishLottery(uint256 lotteryId) public onlyOwner {
        _lotteries[lotteryId].isLotteryFinished = true;
    }

    function getLatestAddedUserIndex(uint256 lotteryId)
        public
        view
        returns (uint256)
    {
        return _lotteries[lotteryId].lastAddedUserIndex;
    }

    function addUserToTheLottery(uint256 lotteryId, address[] memory users)
        public
        onlyOwner
    {
        require(!_lotteries[lotteryId].isLotteryFinished);

        uint256 remainingUsersSpace = _lotteries[lotteryId].users.length -
            _lotteries[lotteryId].lastAddedUserIndex;

        require(users.length <= remainingUsersSpace);

        uint256 starterIndex = _lotteries[lotteryId].lastAddedUserIndex;

        uint256 lastIndex = starterIndex + users.length;
        uint256 activeAddedUserIndex = 0;
        uint256 lastAddedUserIndex = _lotteries[lotteryId].lastAddedUserIndex;
        for (uint256 i = starterIndex; i < lastIndex; ) {
            _lotteries[lotteryId].users[i] = users[activeAddedUserIndex];

            emit UserEntrance(lotteryId, i, _lotteries[lotteryId].users[i]);

            i++;
            activeAddedUserIndex++;
            lastAddedUserIndex++;
        }

        _lotteries[lotteryId].lastAddedUserIndex = lastAddedUserIndex;
    }

    function findWinners(uint256 lotteryId, uint256 finderCount)
        public
        onlyOwner
    {
        require(!_lotteries[lotteryId].isLotteryFinished);
        uint256 remainingWinners = _lotteries[lotteryId].winners.length -
            _lotteries[lotteryId].lastFoundedWinnerIndex;
        require(finderCount <= remainingWinners);
        uint256 starterIndex = _lotteries[lotteryId].lastFoundedWinnerIndex;
        uint256 lastIndex = starterIndex + finderCount;
        _random.initBaseSeed();

        uint256 userCount = _lotteries[lotteryId].users.length;

        uint256 userFoundedIndex = 0;
        uint256 generatedSeed = 0;
        uint256 generatedRNDNum = 0;

        for (uint256 i = starterIndex; i < lastIndex; ) {
            (generatedSeed, generatedRNDNum) = _random.next();
            userFoundedIndex = generatedRNDNum % userCount;
            if (
                _lotteries[lotteryId].winnersSeed[
                    _lotteries[lotteryId].users[userFoundedIndex]
                ] ==
                0 &&
                _lotteries[lotteryId].users[userFoundedIndex] != address(0)
            ) {
                _lotteries[lotteryId].winnersSeed[
                    _lotteries[lotteryId].users[userFoundedIndex]
                ] = generatedSeed;
                _lotteries[lotteryId].winners[i] = _lotteries[lotteryId].users[
                    userFoundedIndex
                ];
                emit FoundedWinners(
                    lotteryId,
                    i,
                    _lotteries[lotteryId].winners[i]
                );
                unchecked {
                    i++;
                    _lotteries[lotteryId].lastFoundedWinnerIndex =
                        _lotteries[lotteryId].lastFoundedWinnerIndex +
                        1;
                }
            }
        }
    }
}