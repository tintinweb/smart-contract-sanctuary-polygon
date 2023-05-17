// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
pragma solidity 0.8.16;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/liquidity-deployer/ILiquidityDeployer.sol";
import "./interfaces/liquidity-deployer/IUniProxy.sol";
import "./libraries/liquidity-deployer/LiquidityDeployerDataTypes.sol";
import "./libraries/liquidity-deployer/LiquidityDeployerMath.sol";
import "./libraries/GPv2SafeERC20.sol";
import "./interfaces/liquidity-deployer/IHypervisor.sol";

/// @author Solid World
contract LiquidityDeployer is ILiquidityDeployer, ReentrancyGuard {
    using GPv2SafeERC20 for IERC20;

    LiquidityDeployerDataTypes.Config internal config;
    LiquidityDeployerDataTypes.Depositors internal depositors;
    LiquidityDeployerDataTypes.Fraction internal lastGammaAdjustmentFactor;

    /// @dev Account => Token => Balance
    mapping(address => mapping(address => uint)) internal userTokenBalance;

    /// @dev Token => Account => Amount
    mapping(address => mapping(address => uint)) internal lastDeployedLiquidity;
    /// @dev Token => Amount
    mapping(address => uint) internal lastTotalDeployedLiquidity;
    /// @dev Token => Amount
    mapping(address => uint) internal lastAvailableLiquidity;
    /// @dev Account => Amount
    mapping(address => uint) internal lPTokensOwed;
    /// @dev Token => Amount
    mapping(address => uint) internal totalDeposits;

    modifier validTokenAmount(uint amount) {
        if (amount == 0) {
            revert InvalidInput();
        }
        _;
    }

    modifier tokensMatch(
        address token0,
        address token1,
        address _gammaVault
    ) {
        IHypervisor gammaVault = IHypervisor(_gammaVault);

        if (token0 != gammaVault.token0() || token1 != gammaVault.token1()) {
            revert TokensMismatch();
        }
        _;
    }

    constructor(
        address token0,
        address token1,
        address gammaVault,
        address uniProxy,
        uint conversionRate,
        uint8 conversionRateDecimals
    ) tokensMatch(token0, token1, gammaVault) {
        config.token0 = token0;
        config.token1 = token1;
        config.gammaVault = gammaVault;
        config.uniProxy = uniProxy;
        config.conversionRate = conversionRate;
        config.conversionRateDecimals = conversionRateDecimals;
        config.token0Decimals = IERC20Metadata(token0).decimals();
        config.token1Decimals = IERC20Metadata(token1).decimals();
        config.minConvertibleToken0Amount = LiquidityDeployerMath.minConvertibleToken0Amount(
            config.token0Decimals,
            config.token1Decimals,
            conversionRate,
            conversionRateDecimals
        );
    }

    /// @inheritdoc ILiquidityDeployer
    function depositToken0(uint amount) external nonReentrant validTokenAmount(amount) {
        _depositToken(config.token0, amount);
    }

    /// @inheritdoc ILiquidityDeployer
    function depositToken1(uint amount) external nonReentrant validTokenAmount(amount) {
        _depositToken(config.token1, amount);
    }

    function withdrawToken0(uint amount) external nonReentrant validTokenAmount(amount) {
        _withdrawToken(config.token0, amount);
    }

    function withdrawToken1(uint amount) external nonReentrant validTokenAmount(amount) {
        _withdrawToken(config.token1, amount);
    }

    /// @inheritdoc ILiquidityDeployer
    function deployLiquidity() external nonReentrant {
        (
            lastAvailableLiquidity[config.token0],
            lastAvailableLiquidity[config.token1]
        ) = _computeAvailableLiquidity();

        (
            lastTotalDeployedLiquidity[config.token0],
            lastTotalDeployedLiquidity[config.token1]
        ) = _computeTotalDeployableLiquidity();

        _prepareDeployment();

        _allowUniProxyToSpendDeployableLiquidity();
        uint lpTokens = _depositToUniProxy();

        _prepareLPTokensOwed(lpTokens);

        emit LiquidityDeployed(
            lastTotalDeployedLiquidity[config.token0],
            lastTotalDeployedLiquidity[config.token1],
            lpTokens
        );
    }

    function withdrawLpTokens() external nonReentrant {
        _withdrawLpTokens(lPTokensOwed[msg.sender]);
    }

    function withdrawLpTokens(uint amount) external nonReentrant {
        _withdrawLpTokens(amount);
    }

    function getToken0() external view returns (address) {
        return config.token0;
    }

    function getToken1() external view returns (address) {
        return config.token1;
    }

    /// @inheritdoc ILiquidityDeployer
    function getGammaVault() external view returns (address) {
        return config.gammaVault;
    }

    /// @inheritdoc ILiquidityDeployer
    function getUniProxy() external view returns (address) {
        return address(config.uniProxy);
    }

    /// @inheritdoc ILiquidityDeployer
    function getConversionRate() external view returns (uint) {
        return config.conversionRate;
    }

    /// @inheritdoc ILiquidityDeployer
    function getConversionRateDecimals() external view returns (uint8) {
        return config.conversionRateDecimals;
    }

    /// @inheritdoc ILiquidityDeployer
    function getMinConvertibleToken0Amount() external view returns (uint) {
        return config.minConvertibleToken0Amount;
    }

    function token0BalanceOf(address account) external view returns (uint) {
        return userTokenBalance[account][config.token0];
    }

    function token1BalanceOf(address account) external view returns (uint) {
        return userTokenBalance[account][config.token1];
    }

    function getTotalDeposits() external view returns (uint token0Amount, uint token1Amount) {
        token0Amount = totalDeposits[config.token0];
        token1Amount = totalDeposits[config.token1];
    }

    function getTokenDepositors() external view returns (address[] memory tokenDepositors) {
        tokenDepositors = new address[](depositors.tokenDepositors.length);
        for (uint i; i < depositors.tokenDepositors.length; i++) {
            tokenDepositors[i] = depositors.tokenDepositors[i];
        }
    }

    /// @inheritdoc ILiquidityDeployer
    function getLastToken0AvailableLiquidity() external view returns (uint) {
        return lastAvailableLiquidity[config.token0];
    }

    /// @inheritdoc ILiquidityDeployer
    function getLastToken1AvailableLiquidity() external view returns (uint) {
        return lastAvailableLiquidity[config.token1];
    }

    /// @inheritdoc ILiquidityDeployer
    function getLastToken0LiquidityDeployed(address liquidityProvider)
        external
        view
        returns (uint lastDeployedAmount)
    {
        lastDeployedAmount = lastDeployedLiquidity[config.token0][liquidityProvider];
    }

    /// @inheritdoc ILiquidityDeployer
    function getLastToken1LiquidityDeployed(address liquidityProvider)
        external
        view
        returns (uint lastDeployedAmount)
    {
        lastDeployedAmount = lastDeployedLiquidity[config.token1][liquidityProvider];
    }

    function getLastTotalDeployedLiquidity() external view returns (uint, uint) {
        return (lastTotalDeployedLiquidity[config.token0], lastTotalDeployedLiquidity[config.token1]);
    }

    function getLPTokensOwed(address liquidityProvider) external view returns (uint) {
        return lPTokensOwed[liquidityProvider];
    }

    /// @inheritdoc ILiquidityDeployer
    function getLastGammaAdjustmentFactor() external view returns (uint, uint) {
        return (lastGammaAdjustmentFactor.numerator, lastGammaAdjustmentFactor.denominator);
    }

    /// @dev Fetches how many token1 tokens are needed if token0 amount is 10^token0Decimals
    /// @dev and stores token1amount/token0amount as a fraction for later computation
    function _loadGammaAdjustmentFactor() internal {
        uint token0Amount = 10**config.token0Decimals;
        (uint amountStart, uint amountEnd) = IUniProxy(config.uniProxy).getDepositAmount(
            config.gammaVault,
            config.token0,
            token0Amount
        );

        uint token1Amount = (amountStart + amountEnd) / 2;

        lastGammaAdjustmentFactor.numerator = token1Amount;
        lastGammaAdjustmentFactor.denominator = token0Amount;
    }

    function _computeAvailableLiquidity()
        internal
        view
        returns (uint token0AvailableLiquidity, uint token1AvailableLiquidity)
    {
        for (uint i; i < depositors.tokenDepositors.length; i++) {
            address depositor = depositors.tokenDepositors[i];
            uint token0Balance = userTokenBalance[depositor][config.token0];
            uint token1Balance = userTokenBalance[depositor][config.token1];

            if (token0Balance >= config.minConvertibleToken0Amount) {
                token0AvailableLiquidity += token0Balance;
            }
            if (token1Balance > 0) {
                token1AvailableLiquidity += token1Balance;
            }
        }
    }

    function _computeTotalDeployableLiquidity()
        internal
        returns (uint token0TotalDeployableLiquidity, uint token1TotalDeployableLiquidity)
    {
        if (
            _convertToken0ToToken1(lastAvailableLiquidity[config.token0]) == 0 ||
            lastAvailableLiquidity[config.token1] == 0
        ) {
            revert NotEnoughAvailableLiquidity(
                lastAvailableLiquidity[config.token0],
                lastAvailableLiquidity[config.token1]
            );
        }

        _loadGammaAdjustmentFactor();

        uint maxToken1DepositAmount = LiquidityDeployerMath.adjustTokenAmount(
            lastAvailableLiquidity[config.token0],
            lastGammaAdjustmentFactor
        );

        if (maxToken1DepositAmount <= lastAvailableLiquidity[config.token1]) {
            token0TotalDeployableLiquidity = lastAvailableLiquidity[config.token0];
            token1TotalDeployableLiquidity = maxToken1DepositAmount;
        } else {
            token0TotalDeployableLiquidity = LiquidityDeployerMath.adjustTokenAmount(
                lastAvailableLiquidity[config.token1],
                LiquidityDeployerMath.inverseFraction(lastGammaAdjustmentFactor)
            );
            token1TotalDeployableLiquidity = lastAvailableLiquidity[config.token1];
        }
    }

    function _prepareDeployment() internal {
        LiquidityDeployerDataTypes.Fraction memory token0AdjustmentFactor = LiquidityDeployerDataTypes
            .Fraction(lastTotalDeployedLiquidity[config.token0], lastAvailableLiquidity[config.token0]);

        LiquidityDeployerDataTypes.Fraction memory token1AdjustmentFactor = LiquidityDeployerDataTypes
            .Fraction(lastTotalDeployedLiquidity[config.token1], lastAvailableLiquidity[config.token1]);

        for (uint i; i < depositors.tokenDepositors.length; i++) {
            address tokenDepositor = depositors.tokenDepositors[i];
            uint token0DeployableLiquidity = _computeToken0DeployableLiquidity(
                userTokenBalance[tokenDepositor][config.token0],
                token0AdjustmentFactor
            );
            lastDeployedLiquidity[config.token0][tokenDepositor] = token0DeployableLiquidity;
            if (token0DeployableLiquidity > 0) {
                userTokenBalance[tokenDepositor][config.token0] -= token0DeployableLiquidity;
                totalDeposits[config.token0] -= token0DeployableLiquidity;
            }

            uint token1DeployableLiquidity = _computeDeployableLiquidity(
                userTokenBalance[tokenDepositor][config.token1],
                token1AdjustmentFactor
            );
            lastDeployedLiquidity[config.token1][tokenDepositor] = token1DeployableLiquidity;
            if (token1DeployableLiquidity > 0) {
                userTokenBalance[tokenDepositor][config.token1] -= token1DeployableLiquidity;
                totalDeposits[config.token1] -= token1DeployableLiquidity;
            }
        }
    }

    function _computeToken0DeployableLiquidity(
        uint tokenDepositorBalance,
        LiquidityDeployerDataTypes.Fraction memory adjustmentFactor
    ) internal view returns (uint) {
        if (tokenDepositorBalance < config.minConvertibleToken0Amount) {
            return 0;
        }

        return _computeDeployableLiquidity(tokenDepositorBalance, adjustmentFactor);
    }

    function _computeDeployableLiquidity(
        uint tokenDepositorBalance,
        LiquidityDeployerDataTypes.Fraction memory adjustmentFactor
    ) internal pure returns (uint) {
        if (tokenDepositorBalance == 0) {
            return 0;
        }

        return LiquidityDeployerMath.adjustTokenAmount(tokenDepositorBalance, adjustmentFactor);
    }

    function _depositToken(address token, uint amount) internal {
        userTokenBalance[msg.sender][token] += amount;
        totalDeposits[token] += amount;

        if (!depositors.isDepositor[msg.sender]) {
            depositors.isDepositor[msg.sender] = true;
            depositors.tokenDepositors.push(msg.sender);
        }

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        emit TokenDeposited(token, msg.sender, amount);
    }

    function _withdrawToken(address token, uint amount) internal {
        if (userTokenBalance[msg.sender][token] < amount) {
            revert InsufficientTokenBalance(token, msg.sender, userTokenBalance[msg.sender][token], amount);
        }

        userTokenBalance[msg.sender][token] -= amount;
        totalDeposits[token] -= amount;

        IERC20(token).safeTransfer(msg.sender, amount);

        emit TokenWithdrawn(token, msg.sender, amount);
    }

    function _withdrawLpTokens(uint amount) internal validTokenAmount(amount) {
        if (amount > lPTokensOwed[msg.sender]) {
            revert InsufficientLpTokenBalance(msg.sender, lPTokensOwed[msg.sender], amount);
        }

        lPTokensOwed[msg.sender] -= amount;
        IERC20(config.gammaVault).safeTransfer(msg.sender, amount);

        emit LpTokenWithdrawn(msg.sender, amount);
    }

    function _allowUniProxyToSpendDeployableLiquidity() internal {
        IERC20(config.token0).approve(config.gammaVault, lastTotalDeployedLiquidity[config.token0]);
        IERC20(config.token1).approve(config.gammaVault, lastTotalDeployedLiquidity[config.token1]);
    }

    function _depositToUniProxy() internal returns (uint lpTokens) {
        return
            IUniProxy(config.uniProxy).deposit(
                lastTotalDeployedLiquidity[config.token0],
                lastTotalDeployedLiquidity[config.token1],
                address(this),
                config.gammaVault,
                _uniProxyMinIn()
            );
    }

    function _prepareLPTokensOwed(uint lpTokens) internal {
        uint remainingLpTokens = lpTokens;
        uint totalLiquidityInToken1 = _totalToken0DeployedLiquidityInToken1() +
            lastTotalDeployedLiquidity[config.token1];

        for (uint i; i < depositors.tokenDepositors.length; i++) {
            address tokenDepositor = depositors.tokenDepositors[i];
            uint totalLiquidityInToken1ForDepositor = _totalDeployableLiquidityInToken1ForDepositor(
                tokenDepositor
            );

            if (totalLiquidityInToken1ForDepositor == 0) {
                continue;
            }

            uint lpTokensOwed = LiquidityDeployerMath.adjustTokenAmount(
                lpTokens,
                LiquidityDeployerDataTypes.Fraction(
                    totalLiquidityInToken1ForDepositor,
                    totalLiquidityInToken1
                )
            );

            lPTokensOwed[tokenDepositor] += lpTokensOwed;
            remainingLpTokens -= lpTokensOwed;
        }

        if (remainingLpTokens > 0) {
            // distribute dust to first depositor
            lPTokensOwed[depositors.tokenDepositors[0]] += remainingLpTokens;
        }
    }

    function _totalDeployableLiquidityInToken1ForDepositor(address depositor) internal view returns (uint) {
        uint token0DeployableLiquidity = lastDeployedLiquidity[config.token0][depositor];
        uint token1DeployableLiquidity = lastDeployedLiquidity[config.token1][depositor];
        uint token0DeployableLiquidityInToken1 = _convertToken0ToToken1(token0DeployableLiquidity);

        return token0DeployableLiquidityInToken1 + token1DeployableLiquidity;
    }

    function _totalToken0DeployedLiquidityInToken1() internal view returns (uint) {
        return _convertToken0ToToken1(lastTotalDeployedLiquidity[config.token0]);
    }

    function _convertToken0ToToken1(uint token0Amount) internal view returns (uint) {
        if (token0Amount < config.minConvertibleToken0Amount) {
            return 0;
        }

        return
            LiquidityDeployerMath.convertTokenValue(
                config.token0Decimals,
                config.token1Decimals,
                config.conversionRate,
                config.conversionRateDecimals,
                token0Amount
            );
    }

    function _uniProxyMinIn() internal pure returns (uint[4] memory) {
        return [uint(0), uint(0), uint(0), uint(0)];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Gamma Strategies
interface IHypervisor {
    function token0() external view returns (address);

    function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Solid World
interface ILiquidityDeployer {
    error InvalidInput();
    error TokensMismatch();
    error InsufficientTokenBalance(address token, address account, uint balance, uint withdrawAmount);
    error NotEnoughAvailableLiquidity(uint token0Liquidity, uint token1Liquidity);
    error InsufficientLpTokenBalance(address account, uint balance, uint withdrawAmount);

    event TokenDeposited(address indexed token, address indexed depositor, uint indexed amount);
    event TokenWithdrawn(address indexed token, address indexed withdrawer, uint indexed amount);
    event LpTokenWithdrawn(address indexed withdrawer, uint indexed amount);
    event LiquidityDeployed(
        uint indexed token0DeployedAmount,
        uint indexed token1DeployedAmount,
        uint indexed lpTokensReceived
    );

    /// @notice The caller must approve the contract to spend `amount` of token0
    function depositToken0(uint amount) external;

    /// @notice The caller must approve the contract to spend `amount` of token1
    function depositToken1(uint amount) external;

    function withdrawToken0(uint amount) external;

    function withdrawToken1(uint amount) external;

    /// @notice Looks at the current configuration and state of the contract, deploys
    /// the available liquidity to the Gamma Vault, and distributes the LP tokens to
    /// the depositors proportionally
    function deployLiquidity() external;

    function withdrawLpTokens(uint amount) external;

    function withdrawLpTokens() external;

    function getToken0() external view returns (address);

    function getToken1() external view returns (address);

    /// @return Gamma Vault address the UniProxy contract will deposit tokens to
    function getGammaVault() external view returns (address);

    /// @return UniProxy contract takes amounts of token0 and token1, deposits them to Gamma Vault,
    /// and returns LP tokens
    function getUniProxy() external view returns (address);

    /// @return 1 token0 = ? token1
    function getConversionRate() external view returns (uint);

    /// @return Number of decimals of the conversion rate
    /// e.g. to express 1 token0 = 0.000001 token1, conversion rate is 1 and decimals is 6
    function getConversionRateDecimals() external view returns (uint8);

    /// @dev Returns the minimum amount of token0 that can be converted to token1
    function getMinConvertibleToken0Amount() external view returns (uint);

    function token0BalanceOf(address account) external view returns (uint);

    function token1BalanceOf(address account) external view returns (uint);

    function getTotalDeposits() external view returns (uint token0Amount, uint token1Amount);

    function getTokenDepositors() external view returns (address[] memory);

    /// @dev returns the total amount of token0 that was available to be deployed (excludes deposits not convertible to token1)
    function getLastToken0AvailableLiquidity() external view returns (uint);

    /// @dev returns the total amount of token1 that was available to be deployed
    function getLastToken1AvailableLiquidity() external view returns (uint);

    /// @param liquidityProvider account that contributed liquidity
    /// @return lastDeployedAmount amount of token0 liquidity that was
    /// deployed by the liquidity provider during the last deployment
    function getLastToken0LiquidityDeployed(address liquidityProvider)
        external
        view
        returns (uint lastDeployedAmount);

    /// @param liquidityProvider account that contributed liquidity
    /// @return lastDeployedAmount amount of token1 liquidity that was
    /// last deployed by the liquidity provider during the last deployment
    function getLastToken1LiquidityDeployed(address liquidityProvider)
        external
        view
        returns (uint lastDeployedAmount);

    function getLastTotalDeployedLiquidity() external view returns (uint, uint);

    function getLPTokensOwed(address liquidityProvider) external view returns (uint);

    /// @return numerator the output amount of token1 that was received for the given amount of token0
    /// @return denominator the input amount of token0 to receive amount of token1
    function getLastGammaAdjustmentFactor() external view returns (uint numerator, uint denominator);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Gamma Strategies
interface IUniProxy {
    /// @notice Deposit into the given position
    /// @param deposit0 Amount of token0 to deposit
    /// @param deposit1 Amount of token1 to deposit
    /// @param to Address to receive liquidity tokens
    /// @param pos Hypervisor Address
    /// @param minIn Minimum amount of tokens that should be paid
    /// @return shares Amount of liquidity tokens received
    function deposit(
        uint deposit0,
        uint deposit1,
        address to,
        address pos,
        uint[4] memory minIn
    ) external returns (uint shares);

    /// @notice Get the amount of token to deposit for the given amount of pair token
    /// @param pos Hypervisor Address
    /// @param token Address of token to deposit
    /// @param depositAmount Amount of token to deposit
    /// @return amountStart Minimum amounts of the pair token to deposit
    /// @return amountEnd Maximum amounts of the pair token to deposit
    function getDepositAmount(
        address pos,
        address token,
        uint depositAmount
    ) external view returns (uint amountStart, uint amountEnd);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Gnosis Protocol v2 Safe ERC20 Transfer Library
/// @author Gnosis Developers
/// @dev Gas-efficient version of Openzeppelin's SafeERC20 contract.
library GPv2SafeERC20 {
    /// @dev Wrapper around a call to the ERC20 function `transfer` that reverts
    /// also when the token returns `false`.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        bytes4 selector_ = token.transfer.selector;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, selector_)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freeMemoryPointer, 36), value)

            if iszero(call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        require(getLastTransferResult(token), "GPv2: failed transfer");
    }

    /// @dev Wrapper around a call to the ERC20 function `transferFrom` that
    /// reverts also when the token returns `false`.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        bytes4 selector_ = token.transferFrom.selector;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, selector_)
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freeMemoryPointer, 68), value)

            if iszero(call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        require(getLastTransferResult(token), "GPv2: failed transferFrom");
    }

    /// @dev Verifies that the last return was a successful `transfer*` call.
    /// This is done by checking that the return data is either empty, or
    /// is a valid ABI encoded boolean.
    function getLastTransferResult(IERC20 token) private view returns (bool success) {
        // NOTE: Inspecting previous return data requires assembly. Note that
        // we write the return data to memory 0 in the case where the return
        // data size is 32, this is OK since the first 64 bytes of memory are
        // reserved by Solidy as a scratch space that can be used within
        // assembly blocks.
        // <https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html>
        // solhint-disable-next-line no-inline-assembly
        assembly {
            /// @dev Revert with an ABI encoded Solidity error with a message
            /// that fits into 32-bytes.
            ///
            /// An ABI encoded Solidity error has the following memory layout:
            ///
            /// ------------+----------------------------------
            ///  byte range | value
            /// ------------+----------------------------------
            ///  0x00..0x04 |        selector("Error(string)")
            ///  0x04..0x24 |      string offset (always 0x20)
            ///  0x24..0x44 |                    string length
            ///  0x44..0x64 | string value, padded to 32-bytes
            function revertWithMessage(length, message) {
                mstore(0x00, "\x08\xc3\x79\xa0")
                mstore(0x04, 0x20)
                mstore(0x24, length)
                mstore(0x44, message)
                revert(0x00, 0x64)
            }

            switch returndatasize()
            // Non-standard ERC20 transfer without return.
            case 0 {
                // NOTE: When the return data size is 0, verify that there
                // is code at the address. This is done in order to maintain
                // compatibility with Solidity calling conventions.
                // <https://docs.soliditylang.org/en/v0.7.6/control-structures.html#external-function-calls>
                if iszero(extcodesize(token)) {
                    revertWithMessage(20, "GPv2: not a contract")
                }

                success := 1
            }
            // Standard ERC20 transfer returning boolean success value.
            case 32 {
                returndatacopy(0, 0, returndatasize())

                // NOTE: For ABI encoding v1, any non-zero value is accepted
                // as `true` for a boolean. In order to stay compatible with
                // OpenZeppelin's `SafeERC20` library which is known to work
                // with the existing ERC20 implementation we care about,
                // make sure we return success for any non-zero return value
                // from the `transfer*` call.
                success := iszero(iszero(mload(0)))
            }
            default {
                revertWithMessage(31, "GPv2: malformed transfer result")
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

library LiquidityDeployerDataTypes {
    struct Config {
        address token0;
        address token1;
        address gammaVault;
        address uniProxy;
        /// @dev 1 token0 = ? token1
        uint conversionRate;
        uint minConvertibleToken0Amount;
        uint8 conversionRateDecimals;
        uint8 token0Decimals;
        uint8 token1Decimals;
    }

    struct Depositors {
        address[] tokenDepositors;
        /// @dev Depositor => IsDepositor
        mapping(address => bool) isDepositor;
    }

    /// @dev used to adjust deployable liquidity to maintain proportionality
    struct Fraction {
        uint numerator;
        uint denominator;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "./LiquidityDeployerDataTypes.sol";

/// @author Solid World
library LiquidityDeployerMath {
    error InvalidFraction(uint numerator, uint denominator);

    function convertTokenValue(
        uint currentDecimals,
        uint newDecimals,
        uint conversionRate,
        uint conversionRateDecimals,
        uint tokenAmount
    ) internal pure returns (uint tokenConverted) {
        if (tokenAmount == 0) {
            return 0;
        }

        tokenConverted = Math.mulDiv(
            tokenAmount,
            10**newDecimals * conversionRate,
            10**(currentDecimals + conversionRateDecimals)
        );
    }

    /// @dev Returns the minimum amount of token0 that can be converted to token1
    function minConvertibleToken0Amount(
        uint currentDecimals,
        uint newDecimals,
        uint conversionRate,
        uint conversionRateDecimals
    ) internal pure returns (uint) {
        return
            1 +
            Math.mulDiv(1, 10**(currentDecimals + conversionRateDecimals), 10**newDecimals * conversionRate);
    }

    function neutralFraction() internal pure returns (LiquidityDeployerDataTypes.Fraction memory) {
        return LiquidityDeployerDataTypes.Fraction(1, 1);
    }

    function inverseFraction(LiquidityDeployerDataTypes.Fraction memory fraction)
        internal
        pure
        returns (LiquidityDeployerDataTypes.Fraction memory)
    {
        if (fraction.denominator == 0) {
            revert InvalidFraction(fraction.numerator, fraction.denominator);
        }

        return LiquidityDeployerDataTypes.Fraction(fraction.denominator, fraction.numerator);
    }

    function adjustTokenAmount(uint amount, LiquidityDeployerDataTypes.Fraction memory adjustmentFactor)
        internal
        pure
        returns (uint)
    {
        if (adjustmentFactor.denominator == 0) {
            revert InvalidFraction(adjustmentFactor.numerator, adjustmentFactor.denominator);
        }

        if (_isNeutralFraction(adjustmentFactor)) {
            return amount;
        }

        return Math.mulDiv(amount, adjustmentFactor.numerator, adjustmentFactor.denominator);
    }

    function _isNeutralFraction(LiquidityDeployerDataTypes.Fraction memory adjustmentFactor)
        private
        pure
        returns (bool)
    {
        return adjustmentFactor.numerator == adjustmentFactor.denominator;
    }
}