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
pragma solidity 0.8.18;

/// @author Gamma Strategies
interface IHypervisor {
    function token0() external view returns (address);

    function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

/// @title Permissionless state-mutating actions
/// @notice Contains state-mutating functions that can be called by anyone
/// @author Solid World DAO
interface ISolidStakingActions {
    /// @dev Stakes tokens for the caller into the staking contract
    /// @param token the token to stake
    /// @param amount the amount to stake
    function stake(address token, uint amount) external;

    /// @notice msg.sender stakes tokens for the recipient into the staking contract
    /// @dev funds are subtracted from msg.sender, stake is credited to recipient
    /// @param token the token to stake
    /// @param amount the amount to stake
    /// @param recipient the recipient of the stake
    function stake(
        address token,
        uint amount,
        address recipient
    ) external;

    /// @dev Withdraws tokens for the caller from the staking contract
    /// @param token the token to withdraw
    /// @param amount the amount to withdraw
    function withdraw(address token, uint amount) external;

    /// @dev Withdraws tokens for the caller from the staking contract
    /// @dev Claims all rewards of the incentivized `token` for the caller
    /// @param token the token to withdraw
    /// @param amount the amount to withdraw
    function withdrawStakeAndClaimRewards(address token, uint amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

/// @author Solid World
interface ISolidZapStaker {
    error GenericSwapError();
    error InvalidInput();
    error AcquiredSharesLessThanMin(uint acquired, uint min);

    event ZapStake(
        address indexed recipient,
        address indexed inputToken,
        uint indexed inputAmount,
        uint shares
    );

    struct Fraction {
        uint numerator;
        uint denominator;
    }

    struct SwapResult {
        address _address;
        uint balance;
    }

    struct SwapResults {
        SwapResult token0;
        SwapResult token1;
    }

    function router() external view returns (address);

    function weth() external view returns (address);

    function iUniProxy() external view returns (address);

    function solidStaking() external view returns (address);

    /// @notice Zap function that achieves the following:
    /// 1. Partially swaps `inputToken` to desired token via encoded swap1
    /// 2. Partially swaps `inputToken` to desired token via encoded swap2
    /// 3. Resulting tokens are deployed as liquidity via IUniProxy & `hypervisor`
    /// 4. Shares of the deployed liquidity are staked in `solidStaking`. `recipient` is the beneficiary of the staked shares
    /// @notice The msg.sender must own `inputAmount` and approve this contract to spend `inputToken`
    /// @param inputToken The token used to provide liquidity
    /// @param inputAmount The amount of `inputToken` to use
    /// @param hypervisor The hypervisor used to deploy liquidity
    /// @param swap1 Encoded swap to partially swap `inputToken` to desired token
    /// @param swap2 Encoded swap to partially swap `inputToken` to desired token
    /// @param minShares The minimum amount of liquidity shares required for transaction to succeed
    /// @param recipient The beneficiary of the staked shares
    /// @return shares The amount of shares staked in `solidStaking`
    function stakeDoubleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2,
        uint minShares,
        address recipient
    ) external returns (uint shares);

    /// @notice Zap function that achieves the following:
    /// 1. Partially swaps `inputToken` to desired token via encoded swap1
    /// 2. Partially swaps `inputToken` to desired token via encoded swap2
    /// 3. Resulting tokens are deployed as liquidity via IUniProxy & `hypervisor`
    /// 4. Shares of the deployed liquidity are staked in `solidStaking`. `msg.sender` is the beneficiary of the staked shares
    /// @notice The msg.sender must own `inputAmount` and approve this contract to spend `inputToken`
    /// @param inputToken The token used to provide liquidity
    /// @param inputAmount The amount of `inputToken` to use
    /// @param hypervisor The hypervisor used to deploy liquidity
    /// @param swap1 Encoded swap to partially swap `inputToken` to desired token
    /// @param swap2 Encoded swap to partially swap `inputToken` to desired token
    /// @param minShares The minimum amount of liquidity shares required for transaction to succeed
    /// @return shares The amount of shares staked in `solidStaking`
    function stakeDoubleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2,
        uint minShares
    ) external returns (uint shares);

    /// @notice Zap function that achieves the following:
    /// 1. Partially swaps `inputToken` to desired token via encoded swap
    /// 3. Resulting tokens are deployed as liquidity via IUniProxy & `hypervisor`
    /// 4. Shares of the deployed liquidity are staked in `solidStaking`. `recipient` is the beneficiary of the staked shares
    /// @notice The msg.sender must own `inputAmount` and approve this contract to spend `inputToken`
    /// @notice `inputToken` must be one of hypervisor's token0 or token1
    /// @param inputToken The token used to provide liquidity
    /// @param inputAmount The amount of `inputToken` to use
    /// @param hypervisor The hypervisor used to deploy liquidity
    /// @param swap Encoded swap to partially swap `inputToken` to desired token
    /// @param minShares The minimum amount of liquidity shares required for transaction to succeed
    /// @param recipient The beneficiary of the staked shares
    /// @return shares The amount of shares staked in `solidStaking`
    function stakeSingleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap,
        uint minShares,
        address recipient
    ) external returns (uint shares);

    /// @notice Zap function that achieves the following:
    /// 1. Partially swaps `inputToken` to desired token via encoded swap
    /// 3. Resulting tokens are deployed as liquidity via IUniProxy & `hypervisor`
    /// 4. Shares of the deployed liquidity are staked in `solidStaking`. `msg.sender` is the beneficiary of the staked shares
    /// @notice The msg.sender must own `inputAmount` and approve this contract to spend `inputToken`
    /// @notice `inputToken` must be one of hypervisor's token0 or token1
    /// @param inputToken The token used to provide liquidity
    /// @param inputAmount The amount of `inputToken` to use
    /// @param hypervisor The hypervisor used to deploy liquidity
    /// @param swap Encoded swap to partially swap `inputToken` to desired token
    /// @param minShares The minimum amount of liquidity shares required for transaction to succeed
    /// @return shares The amount of shares staked in `solidStaking`
    function stakeSingleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap,
        uint minShares
    ) external returns (uint shares);

    /// @notice Zap function that achieves the following:
    /// 1. Wraps `msg.value` to WETH
    /// 2. Partially swaps `WETH` to desired token via encoded swap1
    /// 3. Partially swaps `WETH` to desired token via encoded swap2
    /// 4. Resulting tokens are deployed as liquidity via IUniProxy & `hypervisor`
    /// 5. Shares of the deployed liquidity are staked in `solidStaking`. `recipient` is the beneficiary of the staked shares
    /// @param hypervisor The hypervisor used to deploy liquidity
    /// @param swap1 Encoded swap to partially swap `WETH` to desired token
    /// @param swap2 Encoded swap to partially swap `WETH` to desired token
    /// @param minShares The minimum amount of liquidity shares required for transaction to succeed
    /// @param recipient The beneficiary of the staked shares
    /// @return shares The amount of shares staked in `solidStaking`
    function stakeETH(
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2,
        uint minShares,
        address recipient
    ) external payable returns (uint shares);

    /// @notice Zap function that achieves the following:
    /// 1. Wraps `msg.value` to WETH
    /// 2. Partially swaps `WETH` to desired token via encoded swap1
    /// 3. Partially swaps `WETH` to desired token via encoded swap2
    /// 4. Resulting tokens are deployed as liquidity via IUniProxy & `hypervisor`
    /// 5. Shares of the deployed liquidity are staked in `solidStaking`. `msg.sender` is the beneficiary of the staked shares
    /// @param hypervisor The hypervisor used to deploy liquidity
    /// @param swap1 Encoded swap to partially swap `WETH` to desired token
    /// @param swap2 Encoded swap to partially swap `WETH` to desired token
    /// @param minShares The minimum amount of liquidity shares required for transaction to succeed
    /// @return shares The amount of shares staked in `solidStaking`
    function stakeETH(
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2,
        uint minShares
    ) external payable returns (uint shares);

    /// @notice Function is meant to be called off-chain with _staticCall_.
    /// @notice Zap function that achieves the following:
    /// 1. Partially swaps `inputToken` to desired token via encoded swap1
    /// 2. Partially swaps `inputToken` to desired token via encoded swap2
    /// 3. Resulting tokens are checked against Gamma Vault to determine if they qualify for a dustless liquidity deployment
    ///     * if dustless, the function deploys the liquidity to obtain the amounts of shares getting minted and returns
    ///     * if not dustless, the function computes the current gamma token ratio and returns
    /// @notice The msg.sender must own `inputAmount` and approve this contract to spend `inputToken`
    /// @param inputToken The token used to provide liquidity
    /// @param inputAmount The amount of `inputToken` to use
    /// @param hypervisor The hypervisor used to deploy liquidity
    /// @param swap1 Encoded swap to partially swap `inputToken` to desired token
    /// @param swap2 Encoded swap to partially swap `inputToken` to desired token
    /// @return isDustless Whether the resulting tokens qualify for a dustless liquidity deployment
    /// @return shares The amount of shares minted from the dustless liquidity deployment
    /// @return ratio The current gamma token ratio, or empty if dustless
    function simulateStakeDoubleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2
    )
        external
        returns (
            bool isDustless,
            uint shares,
            Fraction memory ratio
        );

    /// @notice Function is meant to be called off-chain with _staticCall_.
    /// @notice Zap function that achieves the following:
    /// 1. Wraps `msg.value` to WETH
    /// 2. Partially swaps `WETH` to desired token via encoded swap1
    /// 3. Partially swaps `WETH` to desired token via encoded swap2
    /// 4. Resulting tokens are checked against Gamma Vault to determine if they qualify for a dustless liquidity deployment
    ///     * if dustless, the function deploys the liquidity to obtain the amounts of shares getting minted and returns
    ///     * if not dustless, the function computes the current gamma token ratio and returns
    /// @param hypervisor The hypervisor used to deploy liquidity
    /// @param swap1 Encoded swap to partially swap `WETH` to desired token
    /// @param swap2 Encoded swap to partially swap `WETH` to desired token
    /// @return isDustless Whether the resulting tokens qualify for a dustless liquidity deployment
    /// @return shares The amount of shares minted from the dustless liquidity deployment
    /// @return ratio The current gamma token ratio, or empty if dustless
    function simulateStakeETH(
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2
    )
        external
        payable
        returns (
            bool isDustless,
            uint shares,
            Fraction memory ratio
        );

    /// @notice Function is meant to be called off-chain with _staticCall_.
    /// @notice Zap function that achieves the following:
    /// 1. Partially swaps `inputToken` to desired token via encoded swap
    /// 2. Resulting tokens are checked against Gamma Vault to determine if they qualify for a dustless liquidity deployment
    ///     * if dustless, the function deploys the liquidity to obtain the amounts of shares getting minted and returns
    ///     * if not dustless, the function computes the current gamma token ratio and returns
    /// @notice The msg.sender must own `inputAmount` and approve this contract to spend `inputToken`
    /// @notice `inputToken` must be one of hypervisor's token0 or token1
    /// @param inputToken The token used to provide liquidity
    /// @param inputAmount The amount of `inputToken` to use
    /// @param hypervisor The hypervisor used to deploy liquidity
    /// @param swap Encoded swap to partially swap `inputToken` to desired token
    /// @return isDustless Whether the resulting tokens qualify for a dustless liquidity deployment
    /// @return shares The amount of shares minted from the dustless liquidity deployment
    /// @return ratio The current gamma token ratio, or empty if dustless
    function simulateStakeSingleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap
    )
        external
        returns (
            bool isDustless,
            uint shares,
            Fraction memory ratio
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IWETH {
    function deposit() external payable;

    function approve(address spender, uint amount) external returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.18;

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../../interfaces/liquidity-deployer/IHypervisor_0_8_18.sol";
import "../../interfaces/liquidity-deployer/IUniProxy_0_8_18.sol";
import "../../interfaces/staking/ISolidStakingActions_0_8_18.sol";
import "../../interfaces/staking/IWETH.sol";
import "../../interfaces/staking/ISolidZapStaker.sol";
import "../../libraries/GPv2SafeERC20_0_8_18.sol";

/// @author Solid World
abstract contract BaseSolidZapStaker is ISolidZapStaker {
    address public immutable router;
    address public immutable weth;
    address public immutable iUniProxy;
    address public immutable solidStaking;

    constructor(
        address _router,
        address _weth,
        address _iUniProxy,
        address _solidStaking
    ) {
        router = _router;
        weth = _weth;
        iUniProxy = _iUniProxy;
        solidStaking = _solidStaking;

        IWETH(weth).approve(_router, type(uint).max);
    }

    function _swapViaRouter(bytes calldata encodedSwap) internal {
        (bool success, bytes memory retData) = router.call(encodedSwap);

        if (!success) {
            _propagateError(retData);
        }
    }

    function _wrap(uint amount) internal {
        IWETH(weth).deposit{ value: amount }();
    }

    function _fetchHypervisorTokens(address hypervisor)
        internal
        view
        returns (address token0, address token1)
    {
        token0 = IHypervisor(hypervisor).token0();
        token1 = IHypervisor(hypervisor).token1();
    }

    function _fetchTokenBalances(address token0, address token1)
        internal
        view
        returns (uint token0Balance, uint token1Balance)
    {
        token0Balance = IERC20(token0).balanceOf(address(this));
        token1Balance = IERC20(token1).balanceOf(address(this));
    }

    function _approveTokenSpendingIfNeeded(address token, address spender) internal {
        if (IERC20(token).allowance(address(this), spender) == 0) {
            IERC20(token).approve(spender, type(uint).max);
        }
    }

    function _deployLiquidity(
        uint token0Amount,
        uint token1Amount,
        address hypervisor
    ) internal returns (uint shares) {
        shares = IUniProxy(iUniProxy).deposit(
            token0Amount,
            token1Amount,
            address(this),
            hypervisor,
            _uniProxyMinIn()
        );
    }

    function _stakeWithRecipient(
        address token,
        uint amount,
        address recipient
    ) internal {
        ISolidStakingActions(solidStaking).stake(token, amount, recipient);
    }

    function _between(
        uint x,
        uint min,
        uint max
    ) internal pure returns (bool) {
        return x >= min && x <= max;
    }

    function _uniProxyMinIn() internal pure returns (uint[4] memory) {
        return [uint(0), uint(0), uint(0), uint(0)];
    }

    function _propagateError(bytes memory revertReason) internal pure {
        if (revertReason.length == 0) {
            revert GenericSwapError();
        }

        assembly {
            revert(add(32, revertReason), mload(revertReason))
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./BaseSolidZapStaker.sol";

/// @author Solid World
contract SolidZapStaker is BaseSolidZapStaker, ReentrancyGuard {
    using GPv2SafeERC20 for IERC20;

    constructor(
        address _router,
        address _weth,
        address _iUniProxy,
        address _solidStaking
    ) BaseSolidZapStaker(_router, _weth, _iUniProxy, _solidStaking) {}

    /// @inheritdoc ISolidZapStaker
    function stakeDoubleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2,
        uint minShares,
        address recipient
    ) external nonReentrant returns (uint) {
        _prepareToSwap(inputToken, inputAmount);
        return _stakeDoubleSwap(inputToken, inputAmount, hypervisor, swap1, swap2, minShares, recipient);
    }

    /// @inheritdoc ISolidZapStaker
    function stakeDoubleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2,
        uint minShares
    ) external nonReentrant returns (uint) {
        _prepareToSwap(inputToken, inputAmount);
        return _stakeDoubleSwap(inputToken, inputAmount, hypervisor, swap1, swap2, minShares, msg.sender);
    }

    /// @inheritdoc ISolidZapStaker
    function stakeSingleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap,
        uint minShares,
        address recipient
    ) external nonReentrant returns (uint) {
        return _stakeSingleSwap(inputToken, inputAmount, hypervisor, swap, minShares, recipient);
    }

    /// @inheritdoc ISolidZapStaker
    function stakeSingleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap,
        uint minShares
    ) external nonReentrant returns (uint) {
        return _stakeSingleSwap(inputToken, inputAmount, hypervisor, swap, minShares, msg.sender);
    }

    /// @inheritdoc ISolidZapStaker
    function stakeETH(
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2,
        uint minShares,
        address recipient
    ) external payable nonReentrant returns (uint) {
        _wrap(msg.value);

        return _stakeDoubleSwap(weth, msg.value, hypervisor, swap1, swap2, minShares, recipient);
    }

    /// @inheritdoc ISolidZapStaker
    function stakeETH(
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2,
        uint minShares
    ) external payable nonReentrant returns (uint) {
        _wrap(msg.value);

        return _stakeDoubleSwap(weth, msg.value, hypervisor, swap1, swap2, minShares, msg.sender);
    }

    /// @inheritdoc ISolidZapStaker
    function simulateStakeDoubleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2
    )
        external
        nonReentrant
        returns (
            bool,
            uint,
            Fraction memory
        )
    {
        _prepareToSwap(inputToken, inputAmount);

        return _simulateStakeDoubleSwap(hypervisor, swap1, swap2);
    }

    /// @inheritdoc ISolidZapStaker
    function simulateStakeETH(
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2
    )
        external
        payable
        nonReentrant
        returns (
            bool,
            uint,
            Fraction memory
        )
    {
        _wrap(msg.value);

        return _simulateStakeDoubleSwap(hypervisor, swap1, swap2);
    }

    /// @inheritdoc ISolidZapStaker
    function simulateStakeSingleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap
    )
        external
        nonReentrant
        returns (
            bool isDustless,
            uint shares,
            Fraction memory ratio
        )
    {
        SwapResults memory swapResults = _singleSwap(inputToken, inputAmount, hypervisor, swap);

        return _simulateLiquidityDeployment(hypervisor, swapResults);
    }

    function _simulateStakeDoubleSwap(
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2
    )
        private
        returns (
            bool,
            uint,
            Fraction memory
        )
    {
        SwapResults memory swapResults = _doubleSwap(hypervisor, swap1, swap2);
        return _simulateLiquidityDeployment(hypervisor, swapResults);
    }

    function _simulateLiquidityDeployment(address hypervisor, SwapResults memory swapResults)
        private
        returns (
            bool isDustless,
            uint shares,
            Fraction memory ratio
        )
    {
        (isDustless, ratio) = _checkDustless(hypervisor, swapResults);

        if (isDustless) {
            shares = _deployLiquidity(swapResults.token0.balance, swapResults.token1.balance, hypervisor);
        }
    }

    function _stakeDoubleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2,
        uint minShares,
        address recipient
    ) private returns (uint) {
        SwapResults memory swapResults = _doubleSwap(hypervisor, swap1, swap2);

        return _stake(inputToken, inputAmount, hypervisor, minShares, recipient, swapResults);
    }

    function _stakeSingleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap,
        uint minShares,
        address recipient
    ) private returns (uint) {
        SwapResults memory swapResults = _singleSwap(inputToken, inputAmount, hypervisor, swap);

        return _stake(inputToken, inputAmount, hypervisor, minShares, recipient, swapResults);
    }

    function _stake(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        uint minShares,
        address recipient,
        SwapResults memory swapResults
    ) private returns (uint shares) {
        _approveTokenSpendingIfNeeded(swapResults.token0._address, hypervisor);
        _approveTokenSpendingIfNeeded(swapResults.token1._address, hypervisor);
        shares = _deployLiquidity(swapResults.token0.balance, swapResults.token1.balance, hypervisor);

        if (shares < minShares) {
            revert AcquiredSharesLessThanMin(shares, minShares);
        }

        _approveTokenSpendingIfNeeded(hypervisor, solidStaking);
        _stakeWithRecipient(hypervisor, shares, recipient);

        emit ZapStake(recipient, inputToken, inputAmount, shares);
    }

    function _doubleSwap(
        address hypervisor,
        bytes calldata swap1,
        bytes calldata swap2
    ) private returns (SwapResults memory swapResults) {
        (address token0Address, address token1Address) = _fetchHypervisorTokens(hypervisor);
        (uint token0BalanceBefore, uint token1BalanceBefore) = _fetchTokenBalances(
            token0Address,
            token1Address
        );

        _swapViaRouter(swap1);
        _swapViaRouter(swap2);

        (uint token0BalanceAfter, uint token1BalanceAfter) = _fetchTokenBalances(
            token0Address,
            token1Address
        );

        swapResults.token0._address = token0Address;
        swapResults.token0.balance = token0BalanceAfter - token0BalanceBefore;

        swapResults.token1._address = token1Address;
        swapResults.token1.balance = token1BalanceAfter - token1BalanceBefore;
    }

    function _singleSwap(
        address inputToken,
        uint inputAmount,
        address hypervisor,
        bytes calldata swap
    ) private returns (SwapResults memory swapResults) {
        (address token0Address, address token1Address) = _fetchHypervisorTokens(hypervisor);

        if (inputToken != token0Address && inputToken != token1Address) {
            revert InvalidInput();
        }

        (uint token0BalanceBefore, uint token1BalanceBefore) = _fetchTokenBalances(
            token0Address,
            token1Address
        );

        _prepareToSwap(inputToken, inputAmount);
        _swapViaRouter(swap);

        (uint token0BalanceAfter, uint token1BalanceAfter) = _fetchTokenBalances(
            token0Address,
            token1Address
        );

        swapResults.token0._address = token0Address;
        swapResults.token0.balance = token0BalanceAfter - token0BalanceBefore;

        swapResults.token1._address = token1Address;
        swapResults.token1.balance = token1BalanceAfter - token1BalanceBefore;
    }

    function _checkDustless(address hypervisor, SwapResults memory swapResults)
        private
        view
        returns (bool isDustless, Fraction memory actualRatio)
    {
        (uint amountStart, uint amountEnd) = IUniProxy(iUniProxy).getDepositAmount(
            hypervisor,
            swapResults.token0._address,
            swapResults.token0.balance
        );

        isDustless = _between(swapResults.token1.balance, amountStart, amountEnd);

        if (!isDustless) {
            actualRatio = Fraction(swapResults.token0.balance, Math.average(amountStart, amountEnd));
        }
    }

    function _prepareToSwap(address inputToken, uint inputAmount) private {
        IERC20(inputToken).safeTransferFrom(msg.sender, address(this), inputAmount);
        _approveTokenSpendingIfNeeded(inputToken, router);
    }
}