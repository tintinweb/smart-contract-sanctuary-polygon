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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IPair.sol";

contract Calibrator is Ownable {
    IPair public pair;
    IERC20 public tokenBase;
    IERC20 public tokenQuote;
    address public vault = address(0);

    uint256 public feeNumerator = 997;
    uint256 public feeDenominator = 1000;

    uint256 public precisionNumerator = 5;
    uint256 public precisionDenominator = 100;

    uint256 public strengthNumerator = 100;
    uint256 public strengthDenominator = 1;

    uint256 public minimumBase = 100000;

    constructor(address _pair, address _tokenBase, address _tokenQuote) {
        pair = IPair(_pair);
        tokenBase = IERC20(_tokenBase);
        tokenQuote = IERC20(_tokenQuote);
    }

    function setVault(address _vault) external onlyOwner {
        vault = _vault;
    }

    function setFee(
        uint256 _feeNumerator,
        uint256 _feeDenominator
    ) external onlyOwner {
        feeNumerator = _feeNumerator;
        feeDenominator = _feeDenominator;
    }

    function setPrecision(
        uint256 _precisionNumerator,
        uint256 _precisionDenominator
    ) external onlyOwner {
        precisionNumerator = _precisionNumerator;
        precisionDenominator = _precisionDenominator;
    }

    function setStrength(
        uint256 _strengthNumerator,
        uint256 _strengthDenominator
    ) external onlyOwner {
        strengthNumerator = _strengthNumerator;
        strengthDenominator = _strengthDenominator;
    }

    function setMinimumBase(uint256 _minimumBase) external onlyOwner {
        minimumBase = _minimumBase;
    }

    function setRatio(
        uint256 targetRatioBase,
        uint256 targetRatioQuote
    ) external onlyOwner {
        (uint256 reserveBaseInvariant, uint256 reserveQuoteStart, ) = pair
            .getReserves();

        _checkStrength(
            reserveBaseInvariant,
            reserveQuoteStart,
            targetRatioBase,
            targetRatioQuote
        );

        _removeLiquidity(reserveBaseInvariant);

        _swapToRatio(targetRatioBase, targetRatioQuote);

        // check ratio calibration
        (uint256 reserveBase, uint256 reserveQuote, ) = pair.getReserves();

        _checkPrecision(
            reserveBase,
            reserveQuote,
            targetRatioBase,
            targetRatioQuote
        );

        _addLiquidity(reserveBaseInvariant);

        _transfer();
    }

    // retrieve current pool ratio
    function getRatio()
        external
        view
        returns (uint256 ratioBase, uint256 ratioQuote)
    {
        (ratioBase, ratioQuote, ) = pair.getReserves();
    }

    // calculate amount of quote tokens needed to set ratio
    // amount of quote tokens left over after ratio change
    // amount of base tokens left over after ratio change
    // amount of liquidity after ratio change
    function estimate(
        uint256 targetRatioBase,
        uint256 targetRatioQuote
    )
        external
        view
        returns (
            bool baseToQuote,
            uint256 requiredBase,
            uint256 requiredQuote,
            uint256 leftoverBase,
            uint256 leftoverQuote,
            uint256 leftoverLiquidity,
            uint256 reserveBase,
            uint256 reserveQuote
        )
    {
        (reserveBase, reserveQuote, ) = pair.getReserves();

        uint256 reserveBaseInvariant = reserveBase;

        (
            uint256 minimumLiquidity,
            uint256 removedLiquidity
        ) = _calculateRemoveLiquidity(reserveBaseInvariant);

        uint256 totalSupply = pair.totalSupply();

        uint256 availableBase = (removedLiquidity * reserveBase) / totalSupply;

        uint256 availableQuote = (removedLiquidity * reserveQuote) /
            totalSupply;

        totalSupply -= removedLiquidity;

        reserveBase -= availableBase;

        reserveQuote -= availableQuote;

        uint256 amountIn;
        uint256 amountOut;

        (baseToQuote, amountIn, amountOut) = _calculateSwapToRatio(
            reserveBase,
            reserveQuote,
            targetRatioBase,
            targetRatioQuote
        );

        if (baseToQuote) {
            availableBase -= amountIn;
            reserveBase += amountIn;
            reserveQuote -= amountOut;
            availableQuote += amountOut;
        } else {
            availableQuote -= amountIn;
            reserveQuote += amountIn;
            reserveBase -= amountOut;
            availableBase += amountOut;
        }

        _checkPrecision(
            reserveBase,
            reserveQuote,
            targetRatioBase,
            targetRatioQuote
        );

        (uint256 addedBase, uint256 addedQuote) = _calculateAddLiquidity(
            reserveBase,
            reserveQuote,
            reserveBaseInvariant
        );

        if (availableBase < addedBase) {
            leftoverBase = 0;
            requiredBase = addedBase - availableBase;
        } else {
            leftoverBase = availableBase - addedBase;
            requiredBase = 0;
        }

        if (availableQuote < addedQuote) {
            leftoverQuote = 0;
            requiredQuote = addedQuote - availableQuote;
        } else {
            leftoverQuote = availableQuote - addedQuote;
            requiredQuote = 0;
        }

        uint256 mintedLiquidity = Math.min(
            (addedBase * totalSupply) / reserveBase,
            (addedQuote * totalSupply) / reserveQuote
        );

        reserveBase += addedBase;

        reserveQuote += addedQuote;

        leftoverLiquidity = minimumLiquidity + mintedLiquidity;
    }

    function _getVault() internal view returns (address) {
        return vault != address(0) ? vault : msg.sender;
    }

    function _removeLiquidity(uint256 reserveBaseInvariant) internal {
        (, uint256 removedLiquidity) = _calculateRemoveLiquidity(
            reserveBaseInvariant
        );

        pair.transferFrom(_getVault(), address(pair), removedLiquidity);

        pair.burn(address(this));
    }

    function _swapToRatio(
        uint256 targetRatioBase,
        uint256 targetRatioQuote
    ) internal {
        (uint256 reserveBase, uint256 reserveQuote, ) = pair.getReserves();

        (
            bool baseToQuote,
            uint256 amountIn,
            uint256 amountOut
        ) = _calculateSwapToRatio(
                reserveBase,
                reserveQuote,
                targetRatioBase,
                targetRatioQuote
            );

        IERC20 tokenIn = baseToQuote ? tokenBase : tokenQuote;

        tokenIn.transfer(address(pair), amountIn);

        (address token0, ) = _sortTokens(
            address(tokenBase),
            address(tokenQuote)
        );

        (uint amount0Out, uint amount1Out) = address(tokenIn) == token0
            ? (uint(0), amountOut)
            : (amountOut, uint(0));

        pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
    }

    function _addLiquidity(uint256 reserveBaseInvariant) internal {
        (uint256 reserveBase, uint256 reserveQuote, ) = pair.getReserves();

        (uint256 addedBase, uint256 addedQuote) = _calculateAddLiquidity(
            reserveBase,
            reserveQuote,
            reserveBaseInvariant
        );

        tokenBase.transfer(address(pair), addedBase);

        uint256 availableQuote = tokenQuote.balanceOf(address(this));

        if (addedQuote > availableQuote) {
            tokenQuote.transfer(address(pair), availableQuote);

            tokenQuote.transferFrom(
                _getVault(),
                address(pair),
                addedQuote - availableQuote
            );
        } else {
            tokenQuote.transfer(address(pair), addedQuote);
        }

        pair.mint(address(this));
    }

    function _transfer() internal {
        pair.transfer(_getVault(), pair.balanceOf(address(this)));

        tokenBase.transfer(_getVault(), tokenBase.balanceOf(address(this)));

        tokenQuote.transfer(_getVault(), tokenQuote.balanceOf(address(this)));
    }

    function _calculateRemoveLiquidity(
        uint256 reserveBaseInvariant
    )
        internal
        view
        returns (uint256 minimumLiquidity, uint256 removedliquidity)
    {
        uint256 availableLiquidity = pair.allowance(_getVault(), address(this));

        uint256 totalSupply = pair.totalSupply();

        minimumLiquidity = Math.mulDiv(
            totalSupply,
            minimumBase,
            reserveBaseInvariant
        );

        require(
            availableLiquidity >= minimumLiquidity,
            "_calculateRemoveLiquidity: INSUFFICIENT_LIQUIDITY"
        );

        removedliquidity = availableLiquidity - minimumLiquidity;
    }

    function _checkStrength(
        uint256 reserveBase,
        uint256 reserveQuote,
        uint256 targetRatioBase,
        uint256 targetRatioQuote
    ) internal view {
        // base ratio to number of decimal places specified in strengthDenominator
        uint256 ratioBaseDP = Math.mulDiv(
            reserveBase,
            targetRatioQuote * strengthDenominator,
            reserveQuote
        );

        uint256 targetRatioBaseDP = targetRatioBase * strengthDenominator;

        uint256 lowerBound = ratioBaseDP > strengthNumerator
            ? ratioBaseDP - strengthNumerator
            : 0;

        uint256 upperBound = ratioBaseDP + strengthNumerator;

        require(lowerBound <= targetRatioBaseDP, "_checkStrength: LOWER BOUND");

        require(targetRatioBaseDP <= upperBound, "_checkStrength: UPPER BOUND");
    }

    function _checkPrecision(
        uint256 reserveBase,
        uint256 reserveQuote,
        uint256 targetRatioBase,
        uint256 targetRatioQuote
    ) internal view {
        // base ratio to number of decimal places specified in precisionDenominator
        uint256 ratioBaseDP = Math.mulDiv(
            reserveBase,
            targetRatioQuote * precisionDenominator,
            reserveQuote
        );

        uint256 targetRatioBaseDP = targetRatioBase * precisionDenominator;

        uint256 lowerBound = targetRatioBaseDP > precisionNumerator
            ? targetRatioBaseDP - precisionNumerator
            : 0;

        uint256 upperBound = targetRatioBaseDP + precisionNumerator;

        require(lowerBound <= ratioBaseDP, "_checkPrecision: LOWER BOUND");

        require(ratioBaseDP <= upperBound, "_checkPrecision: UPPER BOUND");
    }

    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal view returns (uint256 amountOut) {
        require(amountIn > 0, "_getAmountOut: INSUFFICIENT_INPUT_AMOUNT");

        require(
            reserveIn > 0 && reserveOut > 0,
            "_getAmountOut: INSUFFICIENT_LIQUIDITY"
        );

        uint256 amountInWithFee = amountIn * feeNumerator;

        uint256 numerator = amountInWithFee * reserveOut;

        uint256 denominator = (reserveIn * feeDenominator) + amountInWithFee;

        amountOut = numerator / denominator;
    }

    function _calculateSwapToRatio(
        uint256 reserveBase,
        uint256 reserveQuote,
        uint256 targetRatioBase,
        uint256 targetRatioQuote
    )
        internal
        view
        returns (bool baseToQuote, uint256 amountIn, uint256 amountOut)
    {
        baseToQuote =
            Math.mulDiv(reserveBase, targetRatioQuote, reserveQuote) <
            targetRatioBase;

        uint256 invariant = reserveBase * reserveQuote;

        uint256 leftSide = Math.sqrt(
            Math.mulDiv(
                invariant * feeDenominator,
                baseToQuote ? targetRatioBase : targetRatioQuote,
                (baseToQuote ? targetRatioQuote : targetRatioBase) *
                    feeNumerator
            )
        );

        uint256 rightSide = (
            baseToQuote
                ? reserveBase * feeDenominator
                : reserveQuote * feeDenominator
        ) / feeNumerator;

        require(
            leftSide > rightSide,
            "_calculateSwapToRatio: RATIO EQUALS TARGET"
        );

        amountIn = leftSide - rightSide;

        amountOut = baseToQuote
            ? _getAmountOut(amountIn, reserveBase, reserveQuote)
            : _getAmountOut(amountIn, reserveQuote, reserveBase);
    }

    function _sortTokens(
        address tokenA,
        address tokenB
    ) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "_sortTokens: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "_sortTokens: ZERO_ADDRESS");
    }

    function _calculateAddLiquidity(
        uint256 reserveBase,
        uint256 reserveQuote,
        uint256 reserveBaseInvariant
    ) internal pure returns (uint256 addedBase, uint256 addedQuote) {
        uint256 amountBaseDesired = reserveBaseInvariant - reserveBase;

        // Library.quote()
        uint256 amountQuoteDesired = Math.mulDiv(
            amountBaseDesired,
            reserveQuote,
            reserveBase
        );

        // calculate added tokens
        uint256 amountQuoteOptimal = Math.mulDiv(
            amountBaseDesired,
            reserveQuote,
            reserveBase
        );

        if (amountQuoteOptimal <= amountQuoteDesired) {
            require(
                amountQuoteOptimal >= 0,
                "_calculateAddLiquidity: INSUFFICIENT_QUOTE_AMOUNT"
            );
            (addedBase, addedQuote) = (amountBaseDesired, amountQuoteOptimal);
        } else {
            uint256 amountBaseOptimal = Math.mulDiv(
                amountQuoteDesired,
                reserveBase,
                reserveQuote
            );

            assert(amountBaseOptimal <= amountBaseDesired);

            require(
                amountBaseOptimal >= 0,
                "_calculateAddLiquidity: INSUFFICIENT_BASE_AMOUNT"
            );

            (addedBase, addedQuote) = (amountBaseOptimal, amountQuoteDesired);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

interface IERC20 {
    function mint(address _to, uint256 _value) external;

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool);

    function transfer(
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}