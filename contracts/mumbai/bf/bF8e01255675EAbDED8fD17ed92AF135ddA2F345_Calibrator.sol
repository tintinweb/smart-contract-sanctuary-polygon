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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.19;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IPair} from "./interfaces/IPair.sol";
import {Calculate} from "./libraries/Calculate.sol";
import {Settings} from "./Settings.sol";
import {Estimator} from "./Estimator.sol";

/// @title Changes ratio of pool reserves
/// @author Anton Davydov
contract Calibrator is Settings, Estimator {
    /// @notice Emits at the start of calibration
    /// @param targetBase The number of base parts in target ratio
    /// @param targetQuote The number of quote parts in target ratio
    /// @param vault The address of the vault that holds pair and ERC20 tokens
    event SetRatio(uint256 indexed targetBase, uint256 indexed targetQuote, address indexed vault);

    /// @notice Emits after liquidity removal
    /// @param minimumBase The target size of the base reserve
    /// @param reserveBase The size of base token reserve after removal
    /// @param reserveQuote The size of quote token reserve after removal
    /// @param removedLiquidity Amount of burned liquidity tokens
    event RemoveLiquidity(uint256 indexed minimumBase, uint256 reserveBase, uint256 reserveQuote, uint256 removedLiquidity);

    /// @notice Emits after a ratio change
    /// @param isIdle Did not swap
    /// @param reserveBase The size of base token reserve after ratio change
    /// @param reserveQuote The size of quote token reserve after ratio change
    /// @param missingIn Amount of tokens transfered from vault
    event SwapToRatio(bool indexed isIdle, uint256 reserveBase, uint256 reserveQuote, uint256 missingIn);

    /// @notice Emits after liquidity provision
    /// @param reserveBase The size of base token reserve after provision
    /// @param reserveQuote The size of quote token reserve after provision
    /// @param missingQuote Amount of quote tokens transfered from vault
    /// @param mintedLiquidity Amount of liquidity tokens minted
    event AddLiquidity(uint256 reserveBase, uint256 reserveQuote, uint256 missingQuote, uint256 mintedLiquidity);

    constructor(address _pair, address _tokenBase, address _tokenQuote) Settings(_pair, _tokenBase, _tokenQuote) {}

    /// @notice Change pool reserves to match target ratio
    /// @param targetBase The number of base parts in target ratio
    /// @param targetQuote The number of quote parts in target ratio
    function setRatio(uint256 targetBase, uint256 targetQuote) external onlyOwner {
        emit SetRatio(targetBase, targetQuote, getVault());

        (uint256 reserveBaseInvariant,) = getReserves();

        removeLiquidity();

        (uint256 reserveBase, uint256 reserveQuote) = getReserves();

        bool isIdle;
        bool isPrecise = Calculate.checkPrecision(
                reserveBase, reserveQuote, targetBase, targetQuote, precisionNumerator, precisionDenominator
            );

        while (!isIdle && !isPrecise) {

            // returns `isIdle=true` if swap doesn't change state, avoiding infinite while loop
            isIdle = swapToRatio(targetBase, targetQuote);

            (reserveBase, reserveQuote) = getReserves();

            isPrecise = Calculate.checkPrecision(
                reserveBase, reserveQuote, targetBase, targetQuote, precisionNumerator, precisionDenominator
            );
        }

        addLiquidity(reserveBaseInvariant);

        reclaim();
    }

    /// @notice Remove liquidity from the pool for smaller swaps
    function removeLiquidity() internal onlyOwner {
        (uint256 reserve,) = getReserves();

        (, uint256 removedLiquidity) =
            Calculate.removeLiquidity(reserve, minimumBase, pair.balanceOf(getVault()), pair.totalSupply());

        pair.transferFrom(getVault(), address(pair), removedLiquidity);

        pair.burn(address(this));

        (uint256 reserveBase, uint256 reserveQuote) = getReserves();

        emit RemoveLiquidity(minimumBase, reserveBase, reserveQuote, removedLiquidity);
    }

    /// @notice Swap to move reserves in the direction of target ratio
    /// @param targetBase The number of base parts in target ratio
    /// @param targetQuote The number of quote parts in target ratio
    /// @return isIdle Did not swap
    function swapToRatio(uint256 targetBase, uint256 targetQuote) internal onlyOwner returns (bool) {
        (uint256 reserveBase, uint256 reserveQuote) = getReserves();

        (bool baseToQuote, uint256 amountIn, uint256 amountOut) =
            Calculate.swapToRatio(reserveBase, reserveQuote, targetBase, targetQuote, feeNumerator, feeDenominator);

        // when reserves are small and desired ratio change is small, no swap is possible
        if (amountIn == 0 || amountOut == 0) {
            emit SwapToRatio(true, reserveBase, reserveQuote, 0);

            return true;
        }

        IERC20 tokenIn = baseToQuote ? tokenBase : tokenQuote;

        uint256 availableIn = tokenIn.balanceOf(address(this));

        uint256 sentIn = Math.min(availableIn, amountIn);

        tokenIn.transfer(address(pair), sentIn);

        uint256 missingIn = amountIn - sentIn;

        tokenIn.transferFrom(getVault(), address(pair), missingIn);

        (address token0,) = sortTokens(address(tokenBase), address(tokenQuote));

        (uint256 amount0Out, uint256 amount1Out) =
            address(tokenIn) == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));

        pair.swap(amount0Out, amount1Out, address(this), new bytes(0));

        (reserveBase, reserveQuote) = getReserves();

        emit SwapToRatio(false, reserveBase, reserveQuote, missingIn);

        return false;
    }

    /// @notice Add liquidity to reach invariant base reserve
    /// @param reserveBaseInvariant The target size of base reserve
    function addLiquidity(uint256 reserveBaseInvariant) internal onlyOwner {
        (uint256 reserveBase, uint256 reserveQuote) = getReserves();

        (uint256 addedBase, uint256 addedQuote) =
            Calculate.addLiquidity(reserveBase, reserveQuote, reserveBaseInvariant);

        // when addedBase is very small, addedQuote is 0,
        // which is not enough to mint liquidity and change reserves
        // OGX: INSUFFICIENT_LIQUIDITY_MINTED
        if (addedQuote == 0) return;

        tokenBase.transfer(address(pair), addedBase);

        uint256 availableQuote = tokenQuote.balanceOf(address(this));

        uint256 sentQuote = Math.min(availableQuote, addedQuote);

        tokenQuote.transfer(address(pair), sentQuote);

        uint256 missingQuote = addedQuote - sentQuote;

        tokenQuote.transferFrom(getVault(), address(pair), missingQuote);

        uint256 mintedLiquidity = pair.mint(address(this));

        (reserveBase, reserveQuote) = getReserves();

        emit AddLiquidity(reserveBase, reserveQuote, missingQuote, mintedLiquidity);
    }

    /// @notice Transfer all tokens to the vault
    function reclaim() internal onlyOwner {
        pair.transfer(getVault(), pair.balanceOf(address(this)));

        tokenBase.transfer(getVault(), tokenBase.balanceOf(address(this)));

        tokenQuote.transfer(getVault(), tokenQuote.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.19;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Calculate} from "./libraries/Calculate.sol";
import {Settings} from "./Settings.sol";

/// @title Estimates resources required to change pool reserve ratio
/// @author Anton Davydov
abstract contract Estimator is Settings {
    /// @notice Information about the simulated calibration
    struct Estimation {
        bool baseToQuote;
        uint256 requiredQuote;
        uint256 leftoverQuote;
        uint256 leftoverLiquidity;
        uint256 reserveBase;
        uint256 reserveQuote;
    }

    /// @notice Intermediary state of the calibration
    struct EstimationContext {
        uint256 availableQuote;
        uint256 availableBase;
        uint256 minimumLiquidity;
        uint256 totalSupply;
        uint256 vaultLiquidity;
    }

    /// @notice Simulate a reserve ratio calibration
    /// @param targetBase The number of base parts in target ratio
    /// @param targetQuote The number of quote parts in target ratio
    /// @return estimation Information about the simulated calibration
    function estimate(uint256 targetBase, uint256 targetQuote) external view returns (Estimation memory estimation) {
        EstimationContext memory context;

        (estimation.reserveBase, estimation.reserveQuote) = getReserves();

        uint256 reserveBaseInvariant = estimation.reserveBase;

        context.totalSupply = pair.totalSupply();

        context.vaultLiquidity = pair.balanceOf(getVault());

        (estimation, context) = removeLiquidityDryrun(estimation, context, minimumBase);

        bool isIdle;
        bool isPrecise = Calculate.checkPrecision(
                estimation.reserveBase,
                estimation.reserveQuote,
                targetBase,
                targetQuote,
                precisionNumerator,
                precisionDenominator);

        while (!isIdle && !isPrecise) {
            // returns `isIdle=true` if swap doesn't change state, avoiding infinite while loop
            (estimation, context, isIdle) =
                swapToRatioDryrun(estimation, context, targetBase, targetQuote, feeNumerator, feeDenominator);

            isPrecise = Calculate.checkPrecision(
                estimation.reserveBase,
                estimation.reserveQuote,
                targetBase,
                targetQuote,
                precisionNumerator,
                precisionDenominator);
        }

        estimation = addLiquidityDryrun(estimation, context, reserveBaseInvariant);
    }

    /// @notice Simulate a removal of liquidity from the pool
    /// @param estimation Information about the simulated calibration
    /// @param context Intermediary state of the calibration
    /// @param minimumBase The size of base reserve after removal
    /// @return estimationNew Information about the simulated calibration
    /// @return contextNew Intermediary state of the calibration
    function removeLiquidityDryrun(Estimation memory estimation, EstimationContext memory context, uint256 minimumBase)
        internal
        pure
        returns (Estimation memory, EstimationContext memory)
    {
        uint256 removedLiquidity;

        (context.minimumLiquidity, removedLiquidity) =
            Calculate.removeLiquidity(estimation.reserveBase, minimumBase, context.vaultLiquidity, context.totalSupply);

        context.availableBase = (removedLiquidity * estimation.reserveBase) / context.totalSupply;

        context.availableQuote = (removedLiquidity * estimation.reserveQuote) / context.totalSupply;

        context.totalSupply -= removedLiquidity;

        estimation.reserveBase = estimation.reserveBase - context.availableBase;

        estimation.reserveQuote = estimation.reserveQuote - context.availableQuote;

        return (estimation, context);
    }

    /// @notice Simulate a swap that changes pool ratio
    /// @param estimation Information about the simulated calibration
    /// @param context Intermediary state of the calibration
    /// @param targetBase The number of base parts in target ratio
    /// @param targetQuote The number of quote parts in target ratio
    /// @param feeNumerator The top of a fraction that represents swap size minus fees
    /// @param feeDenominator The bottom of a fraction that represents swap size minus fees
    /// @return estimationNew Information about the simulated calibration
    /// @return contextNew Intermediary state of the calibration
    function swapToRatioDryrun(
        Estimation memory estimation,
        EstimationContext memory context,
        uint256 targetBase,
        uint256 targetQuote,
        uint256 feeNumerator,
        uint256 feeDenominator
    ) internal pure returns (Estimation memory, EstimationContext memory, bool) {
        (bool baseToQuote, uint256 amountIn, uint256 amountOut) = Calculate.swapToRatio(
            estimation.reserveBase, estimation.reserveQuote, targetBase, targetQuote, feeNumerator, feeDenominator
        );

        // when reserves are small and desired ratio change is small, no swap is possible
        if (amountIn == 0 && amountOut == 0) {
            return (estimation, context, true);
        }

        if (baseToQuote) {
            require(context.availableBase > amountIn, "swapToRatioDryrun: not enough base");
            context.availableBase = context.availableBase - amountIn;
            estimation.reserveBase = estimation.reserveBase + amountIn;
            estimation.reserveQuote = estimation.reserveQuote - amountOut;
            context.availableQuote = context.availableQuote + amountOut;
        } else {
            require(context.availableQuote > amountIn, "swapToRatioDryrun: not enough quote");
            context.availableQuote = context.availableQuote - amountIn;
            estimation.reserveQuote = estimation.reserveQuote + amountIn;
            estimation.reserveBase = estimation.reserveBase - amountOut;
            context.availableBase = context.availableBase + amountOut;
        }

        return (estimation, context, false);
    }

    /// @notice Simulate provision of liquidity that reaches invariant size of base reserve
    /// @param estimation Information about the simulated calibration
    /// @param context Intermediary state of the calibration
    /// @param reserveBaseInvariant The target size of base reserve
    /// @return estimationNew Information about the simulated calibration
    function addLiquidityDryrun(
        Estimation memory estimation,
        EstimationContext memory context,
        uint256 reserveBaseInvariant
    ) internal pure returns (Estimation memory) {
        (uint256 addedBase, uint256 addedQuote) =
            Calculate.addLiquidity(estimation.reserveBase, estimation.reserveQuote, reserveBaseInvariant);

        if (context.availableQuote < addedQuote) {
            estimation.leftoverQuote = 0;
            estimation.requiredQuote = addedQuote - context.availableQuote;
        } else {
            estimation.leftoverQuote = context.availableQuote - addedQuote;
            estimation.requiredQuote = 0;
        }

        uint256 mintedLiquidity = Math.min(
            (addedBase * context.totalSupply) / estimation.reserveBase,
            (addedQuote * context.totalSupply) / estimation.reserveQuote
        );

        estimation.reserveBase = estimation.reserveBase + addedBase;

        estimation.reserveQuote = estimation.reserveQuote + addedQuote;

        estimation.leftoverLiquidity = context.minimumLiquidity + mintedLiquidity;

        return estimation;
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
pragma solidity >=0.5.0;

interface IFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IPair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(
        address to
    ) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "./IRouter01.sol";

interface IRouter02 is IRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/math/Math.sol";

/// @title Calculates steps required for pool ratio calibration
/// @author Anton Davydov
library Calculate {
    /// @notice Calculate amount of liquidity tokens that should be
    /// removed from the pool to reach minimum reserve value
    /// @param reserve The size of token reserve in the pool
    /// @param minimum The size of token reserve after liquidity removal
    /// @param availableLiquidity The amount of owned liquidity provider tokens
    /// @param totalSupply Total amount of liquidity provider tokens
    /// @return leftoverLiquidity Amount of liquidity tokens left after removal
    /// @return removedLiquidity Amount of liquidity tokens to remove
    function removeLiquidity(
        uint256 reserve,
        uint256 minimum,
        uint256 availableLiquidity,
        uint256 totalSupply
    )
        internal
        pure
        returns (uint256 leftoverLiquidity, uint256 removedLiquidity)
    {
        leftoverLiquidity = Math.mulDiv(totalSupply, minimum, reserve);

        require(
            availableLiquidity >= leftoverLiquidity,
            "removeLiquidity: INSUFFICIENT_LIQUIDITY"
        );

        removedLiquidity = availableLiquidity - leftoverLiquidity;
    }

    /// @notice Calculate amount of tokens that will be swapped
    /// @param reserveBase The size of base token reserve in the pool
    /// @param reserveQuote The size of quote token reserve in the pool
    /// @param targetBase The number of base parts in target ratio
    /// @param targetQuote The number of quote parts in target ratio
    /// @param feeNumerator The top of a fraction that represents swap size minus fees
    /// @param feeDenominator The bottom of a fraction that represents swap size minus fees
    /// @return baseToQuote Whether to sell base and buy quote, or vice versa, trading direction
    /// @return amountIn The amount of tokens that will be sold
    /// @return amountOut The amount of tokens that will be bought
    function swapToRatio(
        uint256 reserveBase,
        uint256 reserveQuote,
        uint256 targetBase,
        uint256 targetQuote,
        uint256 feeNumerator,
        uint256 feeDenominator
    )
        internal
        pure
        returns (bool baseToQuote, uint256 amountIn, uint256 amountOut)
    {
        // estimate base reserve after ratio change
        // multiply by 1000 for more precise division
        // for cases when target ratio would round to the same quotient as reserve ratio
        uint256 reserveBaseDesired = Math.mulDiv(
            targetBase * 1000,
            reserveQuote,
            targetQuote
        );

        // if base reserve is estimated to remain unchanged, cancel the swap
        if (reserveBaseDesired == reserveBase * 1000) {
            return (false, 0, 0);
        }

        // if base reserve is estimated to grow, sell base
        // otherwise, sell quote
        baseToQuote = reserveBaseDesired > reserveBase * 1000;

        (uint256 targetIn, uint256 targetOut) = baseToQuote
            ? (targetBase, targetQuote)
            : (targetQuote, targetBase);

        // Future reserve `Ra` of token `a` required to move the market to desired price P
        // can be found using future reserve `Rb` of token `b` and constant product `k`
        // P=Rb/Ra; Rb=Ra*P
        // k=Ra*Rb; Rb=k/Ra
        // Ra*P=k/Ra
        // Ra^2=k*(1/P)
        // Ra=(k*(1/P))^1/2
        uint256 reserveInOptimal = Math.sqrt(
            Math.mulDiv(
                reserveBase * reserveQuote, // invariant, k
                targetIn, // target ratio is reversed here because of 1/P
                targetOut
            )
        );

        (uint256 reserveIn, uint256 reserveOut) = baseToQuote
            ? (reserveBase, reserveQuote)
            : (reserveQuote, reserveBase);

        // if base reserve remains unchanged, cancel the swap
        if (reserveInOptimal == reserveIn) {
            return (false, 0, 0);
        }

        // happens when target ratio rounds
        // to a larger quotient than reserve ratio
        // likely due to precision errors in division and sqrt
        require(reserveInOptimal > reserveIn, "swapToRatio: rounding error");

        amountIn = reserveInOptimal - reserveIn;

        amountOut = getAmountOut(
            amountIn,
            reserveIn,
            reserveOut,
            feeNumerator,
            feeDenominator
        );
    }

    /// @notice Calculate the size of token liquidity required to reach invariant base reserve
    /// @param reserveBase The size of base token reserve in the pool
    /// @param reserveQuote The size of quote token reserve in the pool
    /// @param reserveBaseInvariant The target size of base reserve
    /// @return amountBaseDesired Required amount of base tokens
    /// @return amountQuoteOptimal Required amount of quote tokens
    function addLiquidity(
        uint256 reserveBase,
        uint256 reserveQuote,
        uint256 reserveBaseInvariant
    )
        internal
        pure
        returns (uint256 amountBaseDesired, uint256 amountQuoteOptimal)
    {
        // assume that reserveBase is always smaller than invariant after removeLiqudity
        amountBaseDesired = reserveBaseInvariant - reserveBase;

        amountQuoteOptimal = Math.mulDiv(
            amountBaseDesired,
            reserveQuote,
            reserveBase
        );
    }

    /// @notice Check if the difference between pool and target ratios
    /// is smaller than acceptable margin of error
    /// @param reserveBase The size of base token reserve in the pool
    /// @param reserveQuote The size of quote token reserve in the pool
    /// @param targetBase The number of base parts in target ratio
    /// @param targetQuote The number of quote parts in target ratio
    /// @param precisionNumerator The top of a fraction that represents the acceptable margin of error
    /// @param precisionDenominator The bottom of a fraction that represents the acceptable margin of error
    /// @return isPrecise Difference between ratios is smaller than the acceptable margin of error
    function checkPrecision(
        uint256 reserveBase,
        uint256 reserveQuote,
        uint256 targetBase,
        uint256 targetQuote,
        uint256 precisionNumerator,
        uint256 precisionDenominator
    ) internal pure returns (bool) {
        (
            uint256 reserveA,
            uint256 reserveB,
            uint256 targetA,
            uint256 targetB
        ) = reserveBase > reserveQuote
                ? (reserveBase, reserveQuote, targetBase, targetQuote)
                : (reserveQuote, reserveBase, targetQuote, targetBase);

        // if target ratio is reverse, not precise
        if (targetB > targetA) return false;

        // reserve ratio parts to number of decimal places specified in precisionDenominator
        uint256 reserveRatioDP = Math.mulDiv(
            reserveA,
            precisionDenominator,
            reserveB
        );

        // target ratio parts to number of decimal places specified in precisionDenominator
        uint256 targetRatioDP = Math.mulDiv(
            targetA,
            precisionDenominator,
            targetB
        );

        uint256 lowerBound = targetRatioDP > precisionNumerator
            ? targetRatioDP - precisionNumerator
            : 0;

        uint256 upperBound = targetRatioDP + precisionNumerator;

        // if precision is 1/1000, then reserveRatioDP==targetRatioDP+-0.001
        return lowerBound <= reserveRatioDP && reserveRatioDP <= upperBound;
    }

    /// @notice Calculate the maximum output amount of the asset being bought
    /// @param amountIn The amount of tokens sold
    /// @param reserveIn The reserve size of the token being sold
    /// @param reserveOut The reserve size of the token being bought
    /// @param feeNumerator The top of a fraction that represents swap size minus fees
    /// @param feeDenominator The bottom of a fraction that represents swap size minus fees
    /// @return amountOut The amount of tokens bought
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feeNumerator,
        uint256 feeDenominator
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "getAmountOut: INSUFFICIENT_INPUT_AMOUNT");

        require(
            reserveIn > 0 && reserveOut > 0,
            "getAmountOut: INSUFFICIENT_LIQUIDITY"
        );

        uint256 amountInWithFee = amountIn * feeNumerator;

        uint256 numerator = amountInWithFee * reserveOut;

        uint256 denominator = (reserveIn * feeDenominator) + amountInWithFee;

        amountOut = numerator / denominator;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IPair.sol";

/// @title Stores settings for pool ratio calibration
/// @author Anton Davydov
contract Settings is Ownable {
    /// @notice Pool that is being calibrated
    IPair public pair;
    /// @notice Token which pool reserve remains invariant
    IERC20 public tokenBase;
    /// @notice Token which pool reserve changes
    IERC20 public tokenQuote;
    /// @notice Version of the contract, bumped on each deployment
    string public constant VERSION = "0.0.2";

    /// @notice The top of a fraction that represents swap size minus fees
    uint256 public feeNumerator = 997;
    /// @notice The bottom of a fraction that represents swap size minus fees
    uint256 public feeDenominator = 1000;

    /// @notice The top of a fraction that represents the acceptable margin of error in a calibration
    /// @dev when the error margin fraction is large, less swaps are performed, and precision is lower
    uint256 public precisionNumerator = 1;
    /// @notice The bottom of a fraction that represents the acceptable margin of error in a calibration
    uint256 public precisionDenominator = 1000;

    /// @notice The size of the base reserve after liquidity removal and before swaps
    /// @dev When minimum base reserve is large, swaps are more precise and more expensive
    uint256 public minimumBase = 10000000;

    /// @notice The address of the vault that holds pair and ERC20 tokens
    /// @dev When vault is 0, msg.sender is considered the vault
    /// @dev Vault is expected to approve a large allowance to this contract
    address public vault = address(0);

    /// @notice Emits when the net swap fraction is updated
    /// @dev Call this to setup a fork with alternative fees
    /// @param feeNumerator The top of a fraction that represents swap size minus fees
    /// @param feeDenominator The bottom of a fraction that represents swap size minus fees
    event SetFee(uint256 indexed feeNumerator, uint256 indexed feeDenominator);

    /// @notice Emits when acceptable margin of calibration error is updated
    /// @param precisionNumerator The top of a fraction that represents the acceptable margin of error in a calibration
    /// @param precisionDenominator The bottom of a fraction that represents the acceptable margin of error in a calibration
    event SetPrecision(uint256 indexed precisionNumerator, uint256 indexed precisionDenominator);

    /// @notice Emits when the minimum size of the base reserve is updated
    /// @param minimumBase The size of the base reserve after liquidity removal
    event SetMinimumBase(uint256 indexed minimumBase);

    /// @notice Emits when new vault is set
    /// @param vault The address of the vault that holds pair and ERC20 tokens
    event SetVault(address indexed vault);

    constructor(address _pair, address _tokenBase, address _tokenQuote) {
        pair = IPair(_pair);
        tokenBase = IERC20(_tokenBase);
        tokenQuote = IERC20(_tokenQuote);
    }

    /// @notice Update the fraction that represents a net swap size
    /// @param _feeNumerator The top of a fraction that represents swap size minus fees
    /// @param _feeDenominator The bottom of a fraction that represents swap size minus fees
    function setFee(uint256 _feeNumerator, uint256 _feeDenominator) external onlyOwner {
        require(_feeDenominator > 0, "setFee: division by 0");

        require(_feeNumerator <= _feeDenominator, "setFee: improper fraction");

        feeNumerator = _feeNumerator;
        feeDenominator = _feeDenominator;
    }

    /// @notice Update the fraction that represents the acceptable margin of error in a calibration
    /// @param _precisionNumerator The top of a fraction that represents the acceptable margin of error in a calibration
    /// @param _precisionDenominator The bottom of a fraction that represents the acceptable margin of error in a calibration
    function setPrecision(uint256 _precisionNumerator, uint256 _precisionDenominator) external onlyOwner {
        require(_precisionDenominator > 0, "setPrecision: division by 0");

        require(_precisionNumerator <= _precisionDenominator, "setPrecision: improper fraction");

        precisionNumerator = _precisionNumerator;
        precisionDenominator = _precisionDenominator;
    }

    /// @notice Update the size of the base reserve after liquidity removal
    /// @param _minimumBase The size of the base reserve after liquidity removal
    function setMinimumBase(uint256 _minimumBase) external onlyOwner {
        minimumBase = _minimumBase;
    }

    /// @notice Update the address of the vault that holds pair and ERC20 tokens
    /// @param _vault The address of the vault that holds pair and ERC20 tokens
    function setVault(address _vault) external onlyOwner {
        vault = _vault;
    }

    /// @notice Get the address of the vault that holds pair and ERC20 tokens
    /// @dev When vault is 0, msg.sender is considered the vault
    /// @return vault The address of the vault that holds pair and ERC20 tokens
    function getVault() internal view returns (address) {
        return vault != address(0) ? vault : msg.sender;
    }

    /// @notice Retrieve pool reserves sorted such that base if first and quote is second
    /// @return reserveBase The size of base token reserve in the pool
    /// @return reserveQuote The size of quote token reserve in the pool
    function getReserves() public view returns (uint256 reserveBase, uint256 reserveQuote) {
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();

        (address token0,) = sortTokens(address(tokenBase), address(tokenQuote));

        (reserveBase, reserveQuote) = address(tokenBase) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /// @notice Sort token addresses
    /// @param tokenA The address of token A
    /// @param tokenB The address of token B
    /// @return token0 The address of the first token in order
    /// @return token1 The address of the last token in order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "sortTokens: IDENTICAL_ADDRESSES");

        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        require(token0 != address(0), "sortTokens: ZERO_ADDRESS");
    }
}