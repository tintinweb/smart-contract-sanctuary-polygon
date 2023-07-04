/**
 *Submitted for verification at polygonscan.com on 2023-07-04
*/

// SPDX-License-Identifier: MIT
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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: contracts/IndigePlex_Bank.sol



//  Profiles Contract Developed by
// ░█████╗░██████╗░██╗░░░██╗██████╗░████████╗░█████╗░███╗░░██╗██╗░█████╗░
// ██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗╚══██╔══╝██╔══██╗████╗░██║██║██╔══██╗
// ██║░░╚═╝██████╔╝░╚████╔╝░██████╔╝░░░██║░░░██║░░██║██╔██╗██║██║██║░░╚═╝
// ██║░░██╗██╔══██╗░░╚██╔╝░░██╔═══╝░░░░██║░░░██║░░██║██║╚████║██║██║░░██╗
// ╚█████╔╝██║░░██║░░░██║░░░██║░░░░░░░░██║░░░╚█████╔╝██║░╚███║██║╚█████╔╝
// ░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░░░╚═╝░░░░╚════╝░╚═╝░░╚══╝╚═╝░╚════╝░

// ░█████╗░██╗░░██╗██████╗░░█████╗░███╗░░██╗██╗░█████╗░
// ██╔══██╗██║░░██║██╔══██╗██╔══██╗████╗░██║██║██╔══██╗
// ██║░░╚═╝███████║██████╔╝██║░░██║██╔██╗██║██║██║░░╚═╝
// ██║░░██╗██╔══██║██╔══██╗██║░░██║██║╚████║██║██║░░██╗
// ╚█████╔╝██║░░██║██║░░██║╚█████╔╝██║░╚███║██║╚█████╔╝

pragma solidity >=0.8.0 <0.9.0;



contract IndigePlex_Bank is ERC20 {
    bool public paused = true;
    bool public started = false;
    bool public ended = false;
    bool private locked;
    address payable public liquidityAcct;
    uint public StartDate;
    uint public EndDate;
    uint public Duration;
    uint public unlockPrice;
    uint private payWalCount;
    address[] private payList;
    

    mapping(address => bool) private payWallets;
    mapping(address => uint) private payID;


    constructor() ERC20("IndigePlex Bank Token", "IDPB") {
        liquidityAcct = payable(msg.sender);
    }

    modifier contractOwner() {
        require(msg.sender == liquidityAcct, "not contract owner");
        _;
    }

    modifier preventReentrant() {
        require(!locked, "contract is locked");
        locked = true;
        _;
        locked = false;
    }

    modifier Paused() {
        require(paused, "contract must be paused");
        _;
    }

    modifier unPaused() {
        require(!paused, "contract must be unpaused");
        _;
    }

    // pause/unpause switch function
    function setPaused() public contractOwner {
        bool _state = paused;
        if (_state) {
            _state = false;
        } else {
            _state = true;
        }
        paused = _state;
    }

    function addPayWallet(address _contractAddr) public contractOwner unPaused {
        uint _payCount = payWalCount;
        _payCount++;
        require(!payWallets[_contractAddr], "address already added");
        payID[_contractAddr] = _payCount;
        payWallets[_contractAddr] = true;
        payWalCount = _payCount;
        payList.push(_contractAddr);
    }

    function delPayWallet(address _contractAddr) public contractOwner unPaused {
        uint _payCount = payWalCount;
        uint _payId = payID[_contractAddr] - 1;
        _payCount--;
        require(payWallets[_contractAddr], "address not added");
        payWallets[_contractAddr] = false;
        delete payList[_payId];
        payWalCount = _payCount;
    }

    function startContract(uint _duration, uint _price) public unPaused contractOwner {
        require(!started, "contract already started");
        require(_price > 0, "price must be more than 0");

        unlockPrice = _price * 10**18 wei;
        started = true; 
        StartDate = block.timestamp;
        EndDate = block.timestamp + (_duration * 86400);
        Duration = _duration;
        
    }

    function deposit() public payable unPaused preventReentrant {
        require(started, "contract has not started yet");
        require(!ended, "contract has ended");
        require(msg.value > 0, "amount must be greater than 0");
        require(payWallets[msg.sender], "not a public bank");
    } 

    function withdraw() external payable contractOwner unPaused preventReentrant{
        uint thisBal = address(this).balance;

        require(started, "contract not started");
        require(EndDate <= block.timestamp || thisBal >= unlockPrice, "contract not ended or limit not reached");
        ended = true;
        started = false;
        uint amount = thisBal;
        (bool success, ) = liquidityAcct.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function getCountdown() public view returns (uint timeLeft, uint monthsLeft, uint daysLeft, uint hoursLeft, uint minutesLeft) {
        require(started, "contract not started");
        uint _endDate = EndDate;

        require(_endDate > block.timestamp, "contract has ended");
        timeLeft = (_endDate - block.timestamp);
        // daysLeft = timeLeft / 86400;
        if (ended) {
            timeLeft = 0;
        } else {
            if (timeLeft > 2592000) {
                monthsLeft = timeLeft / 2592000;
            }
            if (timeLeft > 86400) {
                daysLeft = (timeLeft / 86400) - (monthsLeft * 30);
            }
            if (timeLeft > 3600) {
                hoursLeft = (timeLeft / 3600) - ((timeLeft / 86400)*24);
            }
            if (timeLeft > 60) {
                minutesLeft = (timeLeft / 60) - ((timeLeft / 3600)*60);
            }
        }
    }

    function getBankManager() public view returns(address bankManager) {
        bankManager = liquidityAcct;
    }

    function getDepositAccts() public view returns(uint paymentCount, address[] memory paymentWallets) {
        require(msg.sender == liquidityAcct, "not for public viewing");
        paymentCount = payWalCount;
        paymentWallets = payList;
    }
}
// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/interfaces/IERC2981.sol


// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/common/ERC2981.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;



/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;


/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// File: contracts/IndigePlex_Team.sol



pragma solidity >=0.8.0 <0.9.0;


/*
 Profiles Contract Developed by

    ░█████╗░██████╗░██╗░░░██╗██████╗░████████╗░█████╗░███╗░░██╗██╗░█████╗░
    ██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗╚══██╔══╝██╔══██╗████╗░██║██║██╔══██╗
    ██║░░╚═╝██████╔╝░╚████╔╝░██████╔╝░░░██║░░░██║░░██║██╔██╗██║██║██║░░╚═╝
    ██║░░██╗██╔══██╗░░╚██╔╝░░██╔═══╝░░░░██║░░░██║░░██║██║╚████║██║██║░░██╗
    ╚█████╔╝██║░░██║░░░██║░░░██║░░░░░░░░██║░░░╚█████╔╝██║░╚███║██║╚█████╔╝
    ░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░░░╚═╝░░░░╚════╝░╚═╝░░╚══╝╚═╝░╚════╝░

    ░█████╗░██╗░░██╗██████╗░░█████╗░███╗░░██╗██╗░█████╗░
    ██╔══██╗██║░░██║██╔══██╗██╔══██╗████╗░██║██║██╔══██╗
    ██║░░╚═╝███████║██████╔╝██║░░██║██╔██╗██║██║██║░░╚═╝
    ██║░░██╗██╔══██║██╔══██╗██║░░██║██║╚████║██║██║░░██╗
    ╚█████╔╝██║░░██║██║░░██║╚█████╔╝██║░╚███║██║╚█████╔╝

@dev this is layout for contract ranking, 

  Team Member Ranking List: 
    #1 Executive Director level
    #2 Senior Management level
    #3 SuperVisor/Team Leader level
    #4 Jr Team Member/New Hire
*/
contract IndigePlex_Team is ERC721URIStorage {
    
    uint public immutable deployDate; // the date of contract deployment to blockchain
    uint public maxMintPerWallet = 1;
    uint public tokenCount;
    bool public paused = true;
    bool private locked;
    address public contractOwner;

    struct TeamMember {
        uint tokenId;
        address tokenOwner;
        address hiredBy;
        uint seniorityLvl;
        string position;
    }

    event Hired (
        uint tokenId,
        address indexed tokenOwner,
        address indexed hiredBy,
        uint seniorityLvl,
        string position
    );

    event Fired (
        uint tokenId,
        address indexed tokenOwner,
        address indexed firedBy,
        uint seniorityLvl,
        string dismissalReason
    );

    mapping(uint => TeamMember) public members;
    mapping(address => uint) private memberRank;


    constructor() ERC721("IndigePlex Team Tokens", "IDPT") {
        contractOwner = msg.sender;
        deployDate = block.timestamp;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "not contract owner");
        _;
    }

    modifier SrRankMember() {
        // only contract owner or level 1 ranked members can call function
        require(msg.sender == contractOwner || memberRank[msg.sender] == 1, "you are not a Sr Ranked Member");
        _;
    }

    modifier preventReentrant() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    modifier Paused() {
        require(paused, "contract must be paused");
        _;
    }

    modifier unPaused() {
        require(!paused, "contract must be unpaused");
        _;
    }

    // pause/unpause switch function
    function setPaused() public onlyOwner {
        bool _state = paused;

        if (_state) {
            _state = false;
        } else {
            _state = true;
        }

        paused = _state;
    }

    function HireMember(string memory _tokenURI, string memory _position, address _memberAddr, uint _srRanking) 
    external SrRankMember unPaused preventReentrant {

        uint mintMax = maxMintPerWallet;
        address _msgSender = msg.sender;
        uint tokenCounter = tokenCount;
        uint seniorityLvl = _srRanking;

        require(balanceOf(_memberAddr) < mintMax, "member already exists");
        require(seniorityLvl <= 4 && seniorityLvl >= 1, "Rank level must be between #1-4"); // edited must be tested
        
        tokenCounter++;
        uint tokenId = tokenCounter;
        address tokenOwner = _memberAddr;
        address hiredBy = _msgSender;
        string memory position = _position;
        if (_msgSender != contractOwner) {
        // sr members cannot hire anyone above level 3 without
        // owners permission... 
            require(seniorityLvl >= 2, "only owner can hire new SR lvl members");
            require(_msgSender != _memberAddr, "cannot hire own address");
        }
        members[tokenId] = TeamMember(
            tokenId,
            tokenOwner,
            hiredBy,
            seniorityLvl,
            position
        );
        emit Hired (
            tokenId,
            tokenOwner,
            hiredBy,
            seniorityLvl,
            position
        );

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        safeTransferFrom(msg.sender, _memberAddr, tokenId);

        memberRank[tokenOwner] = seniorityLvl;
        tokenCount = tokenCounter;
    }

    function FireMember(uint _id, string memory reasonFired) public unPaused SrRankMember {
        TeamMember storage member = members[_id];
        address _msgSender = msg.sender;
        address tokenOwner = member.tokenOwner;
        address firedBy = _msgSender;
        address ContractAuthor = contractOwner;
        uint tokenId = _id;
        uint seniorityLvl = member.seniorityLvl;
        uint _memberRank = memberRank[tokenOwner];
        string memory dismissalReason = reasonFired;  

        if (_msgSender != ContractAuthor) {
            // @dev only contract owner can fire members with lvl 2 or greater rank.
            // this protects lvl 1 and lvl 2 ranked members from being deleted by accident.
            require(_memberRank != 0, "not a team member");
            require(seniorityLvl >= 3 && seniorityLvl < 5, "not sr. member");
        }
        emit Fired(
            tokenId,
            tokenOwner,
            firedBy,
            seniorityLvl,
            dismissalReason
        );

        seniorityLvl = 0;
        _memberRank = 0;
        dismissalReason;

        memberRank[tokenOwner] = _memberRank;
        member.position = dismissalReason;
        member.seniorityLvl = seniorityLvl;

        _burn(_id);
    }

    function newRanking(uint _id, uint _newRank, string memory _newPosition) public unPaused SrRankMember {
        TeamMember storage member = members[_id];
        address _tokenOwner = member.tokenOwner;
        address _msgSender = msg.sender;
        address ContractAuthor = contractOwner;

        if (_msgSender != ContractAuthor) {
            require(_newRank > 1 && _newRank < 5, "rank must be lvl 2-4,");
        }
        
        member.position = _newPosition;
        member.seniorityLvl = _newRank;
        memberRank[_tokenOwner] = _newRank;
    }

    function setNewURI(uint _id, string memory _newURI) unPaused public {
        address _tokenOwner = members[_id].tokenOwner;
        address _msgSender = msg.sender;

        require(_msgSender == _tokenOwner, "must be owner to edit");

        _setTokenURI(_id, _newURI);
        
    }

    function getSrRanking(uint _id) public view returns (uint teamMemberRank) {
        teamMemberRank = members[_id].seniorityLvl;
    }

    function getMemberRanking(address _teamMemberAddr) public view returns (uint memberRanking) {
        memberRanking = memberRank[_teamMemberAddr];
    }
}
// File: contracts/IndigePlex_Profiles.sol


pragma solidity ^0.8.4;

//  Profiles Contract Developed by
// ░█████╗░██████╗░██╗░░░██╗██████╗░████████╗░█████╗░███╗░░██╗██╗░█████╗░
// ██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗╚══██╔══╝██╔══██╗████╗░██║██║██╔══██╗
// ██║░░╚═╝██████╔╝░╚████╔╝░██████╔╝░░░██║░░░██║░░██║██╔██╗██║██║██║░░╚═╝
// ██║░░██╗██╔══██╗░░╚██╔╝░░██╔═══╝░░░░██║░░░██║░░██║██║╚████║██║██║░░██╗
// ╚█████╔╝██║░░██║░░░██║░░░██║░░░░░░░░██║░░░╚█████╔╝██║░╚███║██║╚█████╔╝
// ░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░░░╚═╝░░░░╚════╝░╚═╝░░╚══╝╚═╝░╚════╝░

// ░█████╗░██╗░░██╗██████╗░░█████╗░███╗░░██╗██╗░█████╗░
// ██╔══██╗██║░░██║██╔══██╗██╔══██╗████╗░██║██║██╔══██╗
// ██║░░╚═╝███████║██████╔╝██║░░██║██╔██╗██║██║██║░░╚═╝
// ██║░░██╗██╔══██║██╔══██╗██║░░██║██║╚████║██║██║░░██╗
// ╚█████╔╝██║░░██║██║░░██║╚█████╔╝██║░╚███║██║╚█████╔╝
//  Contracted Created Oct 2022




    
contract IndigePlex_Profile is ERC721URIStorage {
    enum Status {
        Null, // default user setting
        Pending, // pending while team makes decisions on applicant
        Accepted, // user has been successfully verified
        Declined, // user declined to be verified
        Cancelled // user cancelled their application request
    }

    IndigePlex_Team teamMembers;
    bool public paused = true;
    bool private locked;
    uint public maxMintLimit = 1;
    uint public membershipFee = 2.5 * 10**18 wei; // fee for membership 25 matic
    uint public VerificationFee = 1.5 * 10**18 wei; // 150 matic application fee
    uint public burnFee = 0.25 * 10**18 wei; // cost to burn contract 0.25 matic
    uint public tokenCount;
    uint public applicantCount;
    uint public membershipCount; // counts how many paid members using dapp
    address payable public contractOwner;
    address payable private bankAcct;

    struct Profile {
        uint userId;
        string userName;
        address profileOwner;
        bool isAuthenticated;
    }

    event Created(
        uint userId,
        string userName,
        address indexed profileOwner,
        bool isAuthenticated
    );

    event CancelVerification (
        uint userId,
        uint refund,
        address indexed applicantAddrs,
        uint date
    );

    event Revoked (
        uint userId,
        address memberAddrs,
        string reasonRevoked
    );
    
    mapping(uint => Profile) private items;
    mapping(address => uint) private tokens;
    mapping(address => bool) private membership;
    mapping(uint => Status) public userStatus;
    mapping(uint => uint) public ApplicationBalance;

    constructor(address _bank) ERC721("IndigePlex Profile", "IDPP"){
        contractOwner = payable(msg.sender);
        bankAcct = payable(_bank);
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Not Your Profile");
        _;
    }

    modifier ExecRank() {
        uint TeamRank = teamMembers.getMemberRanking(msg.sender);
        if (msg.sender != contractOwner) {
                require(TeamRank == 1, "not Exec Rank");
        }
        _;
    }

    modifier SrRanking() {
        uint TeamRank = teamMembers.getMemberRanking(msg.sender);
        if (msg.sender != contractOwner) {
             require(TeamRank <= 2, "not Sr Rank");
        }

        _;
    }

    modifier preventReentrant() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    modifier Paused() {
        require(paused, "contract must be paused");
        _;
    }

    modifier unPaused() {
        require(!paused, "contract must be unpaused");
        _;
    }
   
    function setPaused() public onlyOwner {
        bool _state = paused;
        if (_state) {
            _state = false;
        } else {
            _state = true;
        }
        paused = _state;
    }

    function setTeamAddress(address _teamContract) public onlyOwner {
        teamMembers = IndigePlex_Team(_teamContract);
    }

    function createProfile(string memory _tokenURI, string memory _userName) external preventReentrant unPaused returns(uint) {
        address _msgSender = msg.sender;
        uint BalanceOF = balanceOf(_msgSender);
        uint mintMax = maxMintLimit;
        uint tokenCounter = tokenCount;
        require(BalanceOF < mintMax, "Profile Already Created");
        tokenCounter++;
        uint itemId = tokenCounter;
        address profileOwner = _msgSender;
        userStatus[itemId] = Status.Null;
        tokens[msg.sender] = itemId;
        items[itemId] = Profile(
            itemId,
            _userName,
            profileOwner,
            false
        );
        _safeMint(_msgSender, itemId);
        _setTokenURI(itemId, _tokenURI);

        tokenCount = tokenCounter;
        
        return(itemId);

    }

    function buyMembership(uint tokenId) external payable unPaused preventReentrant {
        Profile storage item = items[tokenId];
        
        uint buyFee = msg.value;
        address _msgSender = msg.sender;
        bool memberstat = membership[_msgSender];
        uint _memberFee = membershipFee;
        address payable _contractOwner = contractOwner;
        address tokenOwner = item.profileOwner;

        if (_msgSender != _contractOwner)
        require(_msgSender == tokenOwner, "incorrect address");
        require(buyFee >= _memberFee, "not enough for membership fee");
        require(!memberstat, "already a member!");
        memberstat = true;
        membershipCount++;
        _contractOwner.transfer(_memberFee);
        
        membership[_msgSender] = memberstat;
    }

    function RevokeMembership(uint _userId, string memory _reason) external unPaused ExecRank preventReentrant { // not working
        Profile storage item = items[_userId];
        address memberAddrs = item.profileOwner;
        bool memberstat = membership[memberAddrs];
        uint memberId = item.userId;
        string memory reasonRevoked = _reason;

        require(memberstat, "not a member");

        emit Revoked (
            memberId,
            memberAddrs,
            reasonRevoked
        );

        memberstat = false;
        membershipCount--;

        membership[memberAddrs] = memberstat;
    }

    function ApplyToVerify(uint _userId) public payable unPaused preventReentrant {
        Status userStats = userStatus[_userId];
        bool _userAuth = items[_userId].isAuthenticated;
        uint _verifyFee = VerificationFee;
        uint _val = msg.value;
        address _userProfile = items[_userId].profileOwner;
        address _msgSender = msg.sender;

        require(_msgSender == _userProfile, "not your profile");
        require(userStats != Status.Pending, "Application already Pending");
        require(!_userAuth, "Profile already verified");

        if (applicantCount > 3) {
            require(_val >= _verifyFee, "not enough funds");
            // this checks applicant count, if limit reached no more
            // free applications available, user must pay the 
            // application process fee.
            contractOwner.transfer(_verifyFee); //SET TO Bank Contract!!
            ApplicationBalance[_userId] = _val;
        }
        
        applicantCount++;

        userStats = Status.Pending;
        userStatus[_userId] = userStats;

    }

    function CancelApplication(uint _userId) public unPaused preventReentrant {
        Status userStats = userStatus[_userId];
        address _userProfile = items[_userId].profileOwner;
        address _msgSender = msg.sender;
        uint refund = (ApplicationBalance[_userId]) * 75/100;
        uint nonRefundable = (ApplicationBalance[_userId]) * 25/100;
        uint applicantId = _userId;
        uint date = block.timestamp;

        require(_msgSender == _userProfile, "not your profile");
        require(userStats == Status.Pending, "application not pending");
        require(userStats != Status.Declined && userStats != Status.Cancelled, "Applicant already denied/cancelled");

        if (refund > 0) {
            payable(_msgSender).transfer(refund);
            bankAcct.transfer(nonRefundable);
            // @dev if you apply then cancel there will be a 25% non-refundable fee
            refund = 0;
            nonRefundable = 0;
            userStats = Status.Cancelled;

        } else {
            userStats = Status.Cancelled;
        }

        emit CancelVerification (
            applicantId,
            refund,
            _userProfile,
            date
        );

        userStatus[_userId] = userStats;
        ApplicationBalance[_userId] = refund;
    }

    function AuthorizeVerification(uint _userId, bool passed) public unPaused SrRanking { // add team member auth mod
        Status _userStat = userStatus[_userId];
        bool userAuthentication = items[_userId].isAuthenticated;
        bool _passed = passed;
        require(_userStat == Status.Pending, "Application not Pending");
        require(_userStat != Status.Declined, "Application already denied");
        require(_userStat != Status.Accepted, "Application already Accepted");
        require(!userAuthentication, "this Profile is already verified");

        if (_passed) {
            _userStat = Status.Accepted;
            userAuthentication = true;
        } else {
            _userStat = Status.Declined;
        }

        userStatus[_userId] = _userStat;
        items[_userId].isAuthenticated = userAuthentication;
        passed = _passed;
    }

    function _burn(uint tokenId) internal virtual override {
        super._burn(tokenId);
    }

    function deleteUserProfile(uint _userId) external payable unPaused preventReentrant {
        Profile storage item = items[_userId];
        uint _cost = burnFee;
        uint _val = msg.value;
        address userProfile = item.profileOwner;
        address _msgSender = msg.sender;
        address payable ContractAuthor = contractOwner;

        if (_msgSender != contractOwner) {
            require(_msgSender == userProfile, "Not Your Profile!");
            require(_val >= _cost, "Not Enough To cover Reset Fee in Matic");
            ContractAuthor.transfer(_cost);
        }

        _burn(_userId);

    }

    function setNewUserName(uint _userId, string memory _newUserName) external unPaused preventReentrant {
        address _msgSender = msg.sender;
        address userProfile = items[_userId].profileOwner;
        string memory _userName;

        require(_msgSender == userProfile, "Not Your Account!");

        _userName = _newUserName;


        items[_userId].userName = _userName;
    }

    function setNewCost(uint _newCost) public Paused onlyOwner {
        uint _cost = burnFee;

        _cost = _newCost;

        burnFee = _cost;
    }

    function setNewMemberFee(uint _newAmount) public Paused onlyOwner {
        uint _memberFee = membershipFee;

        _memberFee = _newAmount;

        membershipFee = _memberFee;
    }

    function setURI(string memory _newURI, uint _userId) public unPaused  {
        address _msgSender = msg.sender;
        address profileOwner = items[_userId].profileOwner;
        uint tokenId = _userId;
        require(_msgSender == profileOwner, "not your profile!");
        _setTokenURI(tokenId, _newURI);
    }

    function getUserName(uint _userId) view public returns(string memory _userName) {
        _userName = items[_userId].userName;
    }

    function getMembershipStatus(address _userAddress) view public returns(bool membershipStatus) {
        membershipStatus = membership[_userAddress];
    }

    function getUserAuthentication(uint _userId) view external returns(bool userVerified) {
        userVerified = items[_userId].isAuthenticated;
    }

    function OwnerTokenId(address _address) public view returns(uint profileId) {
        profileId = tokens[_address];
    }

    function getApplicationStatus(uint _userId) public view returns(Status, string memory) {
        Status userStats = userStatus[_userId];
        string memory ApplicantStatus;
        if (userStats == Status.Null) {
            ApplicantStatus = "Application not completed";
        }
        if (userStats == Status.Pending) {
            ApplicantStatus = "Application Pending, check again later";
        }
        if (userStats == Status.Accepted) {
            ApplicantStatus = "Application accepted, congrats";
        }
        if (userStats == Status.Declined) {
            ApplicantStatus = "Application denied";
        }
        if (userStats == Status.Cancelled) {
            ApplicantStatus = "Application Cancelled";
        }
        userStats = userStatus[_userId];
        return (userStats, ApplicantStatus);
    }
 }


// File: contracts/IndigePlex_NFT.sol



//  Profiles Contract Developed by
// ░█████╗░██████╗░██╗░░░██╗██████╗░████████╗░█████╗░███╗░░██╗██╗░█████╗░
// ██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗╚══██╔══╝██╔══██╗████╗░██║██║██╔══██╗
// ██║░░╚═╝██████╔╝░╚████╔╝░██████╔╝░░░██║░░░██║░░██║██╔██╗██║██║██║░░╚═╝
// ██║░░██╗██╔══██╗░░╚██╔╝░░██╔═══╝░░░░██║░░░██║░░██║██║╚████║██║██║░░██╗
// ╚█████╔╝██║░░██║░░░██║░░░██║░░░░░░░░██║░░░╚█████╔╝██║░╚███║██║╚█████╔╝
// ░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░░░╚═╝░░░░╚════╝░╚═╝░░╚══╝╚═╝░╚════╝░

// ░█████╗░██╗░░██╗██████╗░░█████╗░███╗░░██╗██╗░█████╗░
// ██╔══██╗██║░░██║██╔══██╗██╔══██╗████╗░██║██║██╔══██╗
// ██║░░╚═╝███████║██████╔╝██║░░██║██╔██╗██║██║██║░░╚═╝
// ██║░░██╗██╔══██║██╔══██╗██║░░██║██║╚████║██║██║░░██╗
// ╚█████╔╝██║░░██║██║░░██║╚█████╔╝██║░╚███║██║╚█████╔╝
//  Contracted Created Oct 2022

pragma solidity >=0.8.0 <0.9.0;






contract IndigePlex_NFT is ERC721URIStorage, IERC721Receiver, ERC2981 {
  

  string public uriPrefix;
  string public uriSuffix = ".json";
  uint256 public maxMintAmountPerTx = 1;
  uint public cost = .10 * 10**18 wei; // 0.10 Matic List Fee 125000000000000000 wei
  uint public tokenCount;
  bool public paused = true;
  bool private locked;
  address private marketplaceAddress;
  address private profileAddress;
  address public contractOwner;
  address payable private bankAccount;

  mapping(uint256 => address) private _creators;
  mapping(uint => string) private _userName;
  mapping(uint => uint) private _royalties;
  mapping(uint => bool) private _verifiedUser;
  mapping(address => bool) private BannedUser;
  mapping(address => bool) private TeamMember;


  constructor(address _bankAddress) ERC721("IndigePlex NFT", "IDPX") {
    contractOwner = payable(msg.sender);
    bankAccount = payable(_bankAddress);
  }

  modifier onlyOwner() {
    require(msg.sender == contractOwner, "you are not the owner");
    _;
  }

  modifier TeamAuth() {
    if(msg.sender != contractOwner){
      require(TeamMember[msg.sender], "not authorized member");
    }
    _;
  }

  modifier preventReentrant() {
    require(!locked, "reentrant attack failed");
    locked = true;
    _;
    locked = false;
  }

  modifier BannedAccount() {
    require(BannedUser[msg.sender] != true, "banned from minting");
    _;
  }

  modifier Paused() {
    require(paused, "contract must be paused");
    _;
  }

  modifier unPaused() {
    require(!paused, "contract must be unpaused");
    _;
  }
  
  // pause/unpause switch function
  function setPaused() public onlyOwner {
      bool _state = paused;
      if (_state) {
          _state = false;
      } else {
          _state = true;
      }
      paused = _state;
  }

  function setNewMarketAddress(address _marketplaceAddress) public Paused onlyOwner {
    marketplaceAddress = _marketplaceAddress;
  }

  function setNewProfileAddress(address _profileAddress) public Paused onlyOwner {
    profileAddress = _profileAddress;
  }

  function mintNFT(string memory tokenURI, uint _setTokenRoyalty) external payable unPaused BannedAccount preventReentrant {

    require(_setTokenRoyalty > 99 && _setTokenRoyalty < 951 , "Royalties Must Be 1-9.5%");

    address _msgSender = msg.sender;
    address ContractAuthor = contractOwner;
    uint _cost = cost;
    uint mintFee = msg.value;
    uint tokenId = tokenCount;
    uint userTokenId = IndigePlex_Profile(profileAddress).OwnerTokenId(_msgSender);
    bool paidMember = IndigePlex_Profile(profileAddress).getMembershipStatus(_msgSender);
    string memory artistName = IndigePlex_Profile(profileAddress).getUserName(userTokenId);
    bool userAuth = IndigePlex_Profile(profileAddress).getUserAuthentication(userTokenId);

    if (_msgSender != ContractAuthor) {
      if (!userAuth && !paidMember){
        require(mintFee >= _cost, "Insufficient funds to Mint NFT!");
        // all verified and paid members do not have to pay marketplace fees or minting fees
        // as long as they hold ownership of their wallets and private keys
      }
    }

    tokenId++;

    _safeMint(_msgSender, tokenId);
    _setTokenURI(tokenId, tokenURI);
    _creators[tokenId] = _msgSender;
    _userName[tokenId] = artistName;
    _royalties[tokenId] = _setTokenRoyalty;
    _verifiedUser[tokenId] = userAuth;
    setApprovalForAll(marketplaceAddress, true);
    tokenCount = tokenId;
  }

  function deposit() external payable onlyOwner unPaused preventReentrant {
    address ContractAuthor = contractOwner;
    address BankAcct = bankAccount;
    (bool payout, ) = ContractAuthor.call{value: (address(this).balance) * 50/100}("");
    (bool savingsAcct, ) = BankAcct.call{value: address(this).balance}("");
    require(payout || savingsAcct, "tx payout failed");
  }
  
  //@dev internal function may only be called by functions within this contract,
  // this will delete any tokens from existance by sending to burn wallet
  function _burn(uint256 tokenId) internal virtual override {
    super._burn(tokenId);
    _resetTokenRoyalty(tokenId);
  }

  // burnNFT function allows the original artist call internal burn function
  // once token is burned there is no way to undo....
  function burnNFT(uint256 tokenId) external unPaused {
    address originalArtist = _creators[tokenId];
    address _msgSender = msg.sender;
    address ContractAuthor = contractOwner;

    if (_msgSender != ContractAuthor){
      require(_msgSender == originalArtist, "Not Original Artist!");
        _burn(tokenId);
    }
    
  }

  function setBankAcct(address _newBankAddrs) external onlyOwner {
    require(_newBankAddrs != bankAccount, "address already set");
    bankAccount = payable(_newBankAddrs);
  }

  function setNewCost(uint _newCost) external Paused onlyOwner {
    uint _cost;
    uint _newMintCost = _newCost;

    _cost = _newMintCost;

    cost = _cost;
  }

  function setNewRoyaltyFee(uint _itemId, uint _newRoyaltyFee) public unPaused {
    address _msgSender = msg.sender;
    address originalArtist = _creators[_itemId];
    uint _royalty = _royalties[_itemId];
    require(_msgSender == originalArtist, "Not Original Artist!");
    _royalty = _newRoyaltyFee;

    _royalties[_itemId] = _royalty;
  }

  function setNewRoyaltyRec(uint _itemId, address _newAddress) public unPaused {
    address _msgSender = msg.sender;
    address originalArtist = _creators[_itemId];

    require(_msgSender == originalArtist, "Not Original Artist!");
    originalArtist = _newAddress;

   _creators[_itemId] = originalArtist;
  }

  function setNewMintLimit(uint _newAmountLimit) public onlyOwner {
    uint mintMax;
    mintMax = _newAmountLimit;
    maxMintAmountPerTx = mintMax;
  }

  function setNewURI(string memory _newBaseURI, uint _itemId) external unPaused preventReentrant {
    address _msgSender = msg.sender;
    address originalArtist = _creators[_itemId];

    require(_msgSender == originalArtist, "Not Original Artist!");
    _setTokenURI(_itemId, _newBaseURI);

    _creators[_itemId] = originalArtist;
  }

  function approveToMarket(uint _itemId) external virtual {
    address _marketplace = marketplaceAddress;
    address _msgSender = msg.sender;
    address _tokenOwner = _creators[_itemId];

    require(_msgSender == _tokenOwner, "not nft owner");
    setApprovalForAll(_marketplace, true);
  }

  function BanUserAcct(address _userWallet) public TeamAuth {
    require(_userWallet != address(0), "zero address error");
    BannedUser[_userWallet] = true;
  }

  function AllowUserAcct(address _userWallet) public TeamAuth {
    require(BannedUser[_userWallet] == true, "not a banned acct");
    BannedUser[_userWallet] = false;
  }

  function addMember(address _newMemberAddrs) public onlyOwner {
    require(!TeamMember[_newMemberAddrs], "already team member");
    TeamMember[_newMemberAddrs] = true;
  }

  function deleteMember(address _teamMember) public onlyOwner {
    require(TeamMember[_teamMember], "not a member");
    TeamMember[_teamMember] = false;
  }

  function _startTokenId() internal view virtual returns (uint256) {
    return 1;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
  
  function getArtistUserName(uint _itemId) view public returns(string memory) {
    return _userName[_itemId];
  }

  function checkBanStatus(address _userWallet) public view returns(bool banStatus) {
    if (msg.sender != contractOwner) {
      require(msg.sender == _userWallet, "not your wallet, nosey");
    }
    banStatus = BannedUser[msg.sender];
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function onERC721Received(address, address, uint256, bytes calldata) public pure override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  function royaltyInfo(uint256 _itemId, uint _salePrice) public view override returns (address receiver, uint256 royaltyAmount) {
    receiver = _creators[_itemId];
    royaltyAmount = (_salePrice / 10000) * _royalties[_itemId];
    // this implements the erc2981 contract for royalties
    // this is enforced by opensea and and any other markets
    // that have implemented the standard.
  }

}
// File: contracts/IndigePlex_Market.sol


pragma solidity ^0.8.0;






/*
Profiles Contract Developed by

    ░█████╗░██████╗░██╗░░░██╗██████╗░████████╗░█████╗░███╗░░██╗██╗░█████╗░
    ██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗╚══██╔══╝██╔══██╗████╗░██║██║██╔══██╗
    ██║░░╚═╝██████╔╝░╚████╔╝░██████╔╝░░░██║░░░██║░░██║██╔██╗██║██║██║░░╚═╝
    ██║░░██╗██╔══██╗░░╚██╔╝░░██╔═══╝░░░░██║░░░██║░░██║██║╚████║██║██║░░██╗
    ╚█████╔╝██║░░██║░░░██║░░░██║░░░░░░░░██║░░░╚█████╔╝██║░╚███║██║╚█████╔╝
    ░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░░░╚═╝░░░░╚════╝░╚═╝░░╚══╝╚═╝░╚════╝░

    ░█████╗░██╗░░██╗██████╗░░█████╗░███╗░░██╗██╗░█████╗░
    ██╔══██╗██║░░██║██╔══██╗██╔══██╗████╗░██║██║██╔══██╗
    ██║░░╚═╝███████║██████╔╝██║░░██║██╔██╗██║██║██║░░╚═╝
    ██║░░██╗██╔══██║██╔══██╗██║░░██║██║╚████║██║██║░░██╗
    ╚█████╔╝██║░░██║██║░░██║╚█████╔╝██║░╚███║██║╚█████╔╝

    This contract is designed to be used as a public marketplace contract for the IndigePlex Dapp
    created Oct 2022
*/


contract IndigePlex_Marketplace is ERC721URIStorage, IERC721Receiver, ERC2981 {

    // Variables
    address private nftContractAddress;
    address private profileAddress;
    address payable public immutable feeAccount;
    address payable public contractOwner;
    bool public paused = true;
    bool private locked;
    uint public immutable feePercent;
    uint public importFee = 0.25 * 10**18 wei; // fee for importing outside nfts to marketplace
    uint public deployDate;
    uint public itemCount;

    // enums
    enum OfferStatus{
        NoOffers,
        NewOffering,
        prevOffering,
        acceptOffering,
        declineOffering
    }

    // marketplace mapping
    mapping(uint => Item) public items;

    mapping(uint => uint) private bestOffer;
    mapping(uint => address) private prevAdrs;
    mapping(uint => uint) private prevOffers;
    mapping(uint => address) private offerBy;
    mapping(uint => uint) private offerCount;
    mapping(uint => uint[]) private listedOffers;
    mapping(uint => mapping(address => uint)) private offerBal;
    mapping(uint => mapping(uint => address)) private offerAdrs;
    mapping(uint => OfferStatus) private offerStats;

    // struct & events
    struct Item {
        IERC721 nft;
        uint tokenId;
        uint price;
        uint royalties;
        uint marketFee;
        uint discountPrice;
        uint discountRoyalties;
        address payable seller;
        address payable artist;
        bool verified;
        bool sold;
    }

    event ForSale(
        address indexed nft,
        uint tokenId,
        uint price,
        uint royalties,
        uint marketFee,
        uint discountPrice,
        uint discountRoyalties,
        address indexed seller,
        address indexed artist
    );

    event Bought(
        address indexed nft,
        uint tokenId,
        uint price,
        uint royalties,
        uint marketFee,
        address indexed seller,
        address indexed artist
    );
    
    event DiscountBuy(
        address indexed nft,
        uint tokenId,
        uint marketFee,
        uint discountPrice,
        uint discountRoyalties,
        address indexed seller,
        address indexed artist
    );

    event ItemOffer(
        address nft,
        uint tokenId,
        uint offerAmount,
        address indexed seller,
        address indexed artist,
        address indexed offeredBy
    );

    constructor(address _bankContract, uint _feePercent) ERC721("IndigePlex Marketplace", "IDP") {
        contractOwner = payable(msg.sender);
        feeAccount = payable(_bankContract);
        feePercent = _feePercent;
        deployDate = block.timestamp;
    }

    // custom modifiers to limit amount of imports
    modifier onlyOwner() {
        require(msg.sender == contractOwner, "you are not the owner");
        _;
    }

    modifier BannedAccount() {
        bool _bannedUser = IndigePlex_NFT(nftContractAddress).checkBanStatus(msg.sender);
        require(!_bannedUser, "User is banned");
        _;
    }

    modifier preventReentrant() {
        require(!locked, "reentrant attack failed");
        locked = true;
        _;
        locked = false;
    }

    modifier Paused() {
        require(paused, "contract must be paused");
        _;
    }

    modifier unPaused() {
        require(!paused, "contract must be unpaused");
        _;
    }

    function setNFTContractAddress(address _nftContractAddress) external onlyOwner Paused {
        nftContractAddress = _nftContractAddress;
        // @dev must fill this out before unpausing contract or else the artist function will 
        // not work properly... 
    } 

    function setProfileContractAddress(address _profileAddress) external onlyOwner Paused {
        profileAddress = _profileAddress;
        // @dev must fill this out before unpausing contract or else the artist function will 
        // not work properly... 
    }

    // pause/unpause switch function
    function setPaused() external onlyOwner {
        bool _state = paused;
        if (_state) {
            _state = false;
        } else {
            _state = true;
        }
        paused = _state;
    }


    // internal royalties calculations functions
    // calculates and sets variables to internal => external
    // only callable by inside contract, 

    function calculateTotals(address _nft, uint _itemId, uint _price) internal view unPaused returns(uint royalties, uint salePrice, address artist, uint marketFees) {
        marketFees = (_price / 100) * feePercent;
        (address originalArtist, uint itemRoyalties) = IERC2981(_nft).royaltyInfo(_itemId, _price);
        if (itemRoyalties > (_price / 10000) * 950) {
            royalties = (_price / 10000) * 950;
            salePrice = _price - royalties;
            artist = originalArtist;
        } else {
            royalties = itemRoyalties;
            salePrice = _price - itemRoyalties;
            artist = originalArtist;
        }
    } 

    function calculateOffer(address _nft, uint _itemId, uint _price) internal view unPaused returns(uint royalties, uint salePrice, address artist, uint marketFee) {
        marketFee = (_price / 100) * feePercent;
        (address originalArtist, uint itemRoyalties) = IERC2981(_nft).royaltyInfo(_itemId, _price);
        if (itemRoyalties > (_price / 10000) * 950) {
            royalties = (_price / 10000) * 950;
            salePrice = _price - (royalties + marketFee);
            artist = originalArtist;
        } else {
            royalties = itemRoyalties;
            salePrice = _price - (itemRoyalties + marketFee);
            artist = originalArtist;
        }
    }

    function calculateDiscount(uint price, uint royalties, uint _discount) internal pure returns(uint discountRoyalties, uint discountPrice) {        
        discountPrice = price * (10000 - _discount) / 10000;
        discountRoyalties = royalties * (10000 - _discount) / 10000;
    }

    function defaultRoyalties(uint _price) internal view returns(uint royalties, uint salePrice, address artist, uint marketFee) {
        marketFee = (_price / 100) * feePercent;
        royalties = (_price /10000) * 100;
        salePrice = _price - royalties;
        artist = feeAccount;
    }

    function getAuthStatus() internal view returns(bool userAuth) {
        address _profileAddress = profileAddress;
        address _msgSender = msg.sender;
        uint userTokenId = IndigePlex_Profile(_profileAddress).OwnerTokenId(_msgSender);
        userAuth = IndigePlex_Profile(_profileAddress).getUserAuthentication(userTokenId);
    }

    function getInterfaceSupport(IERC721 _nft) internal view returns(bool success) {
        bytes4 interfaceId;
        require(interfaceId == 0x2a55205a);
        (success) = _nft.supportsInterface(interfaceId);
    }

    function payImportFee(uint _importFee) internal unPaused preventReentrant {
        uint feePayment = msg.value;
        require(feePayment >= _importFee, "not enough to cover import fee");
        feeAccount.transfer(feePayment);
    }

    ////// Make item to offer on the marketplace ////////////
    function marketItem(IERC721 _nft, uint _itemId, uint _price, uint _discount) external unPaused preventReentrant {
        require(_price > 0, "Price must be greater than zero");
        require(_discount >= 0 && _discount <2501, "discount must be 0-25% max");
        bool supportedContract = getInterfaceSupport(_nft);
        uint royalties;
        uint price;
        address artist;
        uint marketFee;
        uint discountPrice;
        uint discountRoyalties;
        uint _importFee = importFee;
        bool _verified = getAuthStatus();
        if (!supportedContract) {
            (
                royalties, 
                price, 
                artist,
                marketFee
            ) = defaultRoyalties(_price); 

            (discountRoyalties, discountPrice) = calculateDiscount(price, royalties, _discount);
        } else {
            (
                royalties, 
                price, 
                artist,
                marketFee
            ) = calculateTotals(address(_nft), _itemId, _price);

            (discountRoyalties, discountPrice) = calculateDiscount(price, royalties, _discount);
        }
        if (address(_nft) != nftContractAddress) {
            payImportFee(_importFee);
        }
        _nft.safeTransferFrom(msg.sender, address(this), _itemId);
        itemCount++;
        items[itemCount] = Item (
            _nft,
            itemCount,
            price,
            royalties,
            marketFee,
            discountPrice,
            discountRoyalties,
            payable(msg.sender),
            payable(artist),
            _verified,
            false
        );
        emit ForSale(
            address(_nft),
            itemCount,
            price,
            royalties,
            marketFee,
            discountPrice,
            discountRoyalties,
            msg.sender,
            artist
        );
    }

    function purchaseItem(uint _itemId) external payable unPaused preventReentrant {
        require(_itemId > 0 && _itemId <= itemCount, "item doesn't exist");
        Item storage item = items[_itemId];
        require(!item.sold, "item already sold");
        address _msgSender = msg.sender;
        uint _itemPrice = item.price;
        uint _totalRoyalty = item.royalties;
        uint _marketFee = item.marketFee;
        uint _discountPrice = item.discountPrice;
        uint _discountRoyalties = item.discountRoyalties;
        uint _totalPrice = (_itemPrice + _totalRoyalty + _marketFee);
        require(msg.value >= _totalPrice, "not enough to cover item price and market fee");
        item.sold = true;
        bestOffer[_itemId] = 0;
        item.nft.safeTransferFrom(address(this), _msgSender, item.tokenId);

        bool isMember = getMemberStatus(_msgSender);

        if (!isMember) {
            feeAccount.transfer(_marketFee);
            item.artist.transfer(_totalRoyalty);
            item.seller.transfer(_itemPrice);
            emit Bought(
                address(item.nft),
                item.tokenId,
                item.price,
                item.royalties,
                item.marketFee,
                item.seller,
                item.artist
            );
        } else {
            feeAccount.transfer(_marketFee);
            item.artist.transfer(_discountRoyalties);
            item.seller.transfer(_discountPrice);
            emit DiscountBuy(
                address(item.nft),
                item.tokenId,
                item.price,
                item.discountPrice,
                item.discountRoyalties,
                item.seller,
                item.artist
            );
        }
    }

    ////////////////////////////////////////////////////////////////////
    /////////////// OFFER FUNCTIONS ////////////////////////

    function newOffer(uint _itemId) external payable preventReentrant {
        Item storage item = items[_itemId];
        OfferStatus _offerStats = offerStats[_itemId];
        IERC721 _nft = item.nft;
        uint _offerAmount = msg.value;
        address _seller = item.seller;
        address _artist = item.artist;
        address _msgSender = msg.sender;
        uint prevOffer =  offerBal[_itemId][_msgSender];
        uint _price = item.price;
        uint _bestOffer = bestOffer[_itemId];

        require(_itemId > 0, "nonexistant item");
        require(_offerAmount > 0, "offer cannot be 0");
        require(_offerAmount < _price, "offer < original price");

        if(_bestOffer > 0) {
            require(_offerAmount > _bestOffer, "new offer > prev offer");
            if (prevOffer > 0) {
                payable(_msgSender).transfer(prevOffer);
                prevOffer = 0;
            }
        }

        require(prevOffer == 0, "cancel prev offer");

        emit ItemOffer(
            address(_nft),
            _itemId,
            _offerAmount,
            _seller,
            _artist,
            _msgSender
        );

        _bestOffer = _offerAmount;
        _offerStats = OfferStatus.NewOffering;
        listedOffers[_itemId].push(_bestOffer);
        
        offerCount[_itemId]++;
        offerBal[_itemId][_msgSender] = _offerAmount;
        offerBy[_itemId] = _msgSender;
        bestOffer[_itemId] = _bestOffer;
        offerStats[_itemId] = _offerStats;
        offerAdrs[_itemId][_offerAmount] = _msgSender;
    }

    function withdrawOffer(uint _itemId) external preventReentrant {
        address _msgSender = msg.sender;
        uint myOffer = offerBal[_itemId][_msgSender];
        
        require(myOffer > 0, "nothing to refund");
        require(offerStats[_itemId] != OfferStatus.NoOffers, "no offers to withdraw");

        offerBal[_itemId][_msgSender] -= myOffer;

        payable(_msgSender).transfer(myOffer);

        myOffer = 0;

        offerCount[_itemId]--;

    }

    function acceptOffer(uint _itemId) external preventReentrant {
        Item storage item = items[_itemId];
        OfferStatus _offerStats = offerStats[_itemId];
        IERC721 _nft = item.nft;
        address _seller = msg.sender;
        address _buyer = offerBy[_itemId];
        uint _bestOffer = bestOffer[_itemId];
        address artist;
        uint royalties;
        uint offerRec;
        uint marketFees;
        bool supportedContract = getInterfaceSupport(_nft);
        if (!supportedContract) {
            (
                royalties, 
                offerRec, 
                artist, 
                marketFees
            ) = defaultRoyalties(_bestOffer);
        } else {
            (
                royalties, 
                offerRec, 
                artist,
                marketFees
            ) = calculateOffer(address(_nft), _itemId, _bestOffer);
        }
        require(_seller == item.seller, "not item seller");
        require(_bestOffer != 0, "no offers to accept");
        _offerStats = OfferStatus.acceptOffering;

        offerBal[_itemId][_buyer] -= _bestOffer;

        _nft.transferFrom(_seller, _buyer, _itemId);

        _bestOffer = 0;
        offerCount[_itemId] = 0;

        payable(_seller).transfer(offerRec);
        payable(artist).transfer(royalties);
        feeAccount.transfer(marketFees);
        refundOffers(_itemId, _buyer);
    }

    ///////////// internal offer function ///////////

    function refundOffers(uint _itemId, address refundedBy) internal unPaused preventReentrant{
        address _seller = items[_itemId].seller;
        address _msgSender = msg.sender;
        uint _itemCount = offerCount[_itemId];
        require(_msgSender == _seller || _msgSender == refundedBy, "not buyer or seller");
        require(_itemCount > 0, "no offers to refund");

        for(uint i = 0; i < _itemCount; i++) {
          address refundees = offerAdrs[_itemId][i];

          if(offerBal[_itemId][refundees] > 0) {
              payable(refundees).transfer(offerBal[_itemId][refundees]);
          }  
        }
    }

    //////////////////////////////////////////////////////////////////////////

    function unlistNFT(uint256 tokenId) external unPaused preventReentrant {
        Item storage item = items[tokenId];

        bool _sold = item.sold;
        address _msgSender = msg.sender;
        address _seller = item.seller;
        address _contractOwner = contractOwner;
        uint _tokenId = item.tokenId;
        
        require(!_sold, "item already sold, cannot burn");
        require(_msgSender == _seller || _msgSender == _contractOwner, "Not NFT Owner!");
        if (offerCount[tokenId] > 0) {
            refundOffers(tokenId, address(this));
        }
        // sends nft back to seller address
        item.nft.transferFrom(address(this), _msgSender, _tokenId);
        //  calls internal burn function
        //  to send tokenID to 0x0 address
        _burn(tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function onERC721Received(address, address, uint256, bytes calldata) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function getPrices(uint _itemId) view external returns (uint normalPrice, uint discountPrice) {
        Item memory item = items[_itemId];
        normalPrice = (item.price + item.royalties + item.marketFee);
        discountPrice = (item.discountPrice + item.discountRoyalties + item.marketFee);
    }

    function getMemberStatus(address _tokenOwner) view internal returns (bool) {
        bool memberStatus = IndigePlex_Profile(profileAddress).getMembershipStatus(_tokenOwner);
        return (memberStatus);
    }

    function currentOffer(uint _itemId) public view returns(uint _bestOffer, address _offerBy) {
        _bestOffer = bestOffer[_itemId];
        _offerBy = offerBy[_itemId];
    }

    function getRoyaltyInfo(uint _itemId, ERC2981 _nft) public view returns( address royaltyRec, uint royaltyAmount) {
        uint salePrice = (items[_itemId].royalties * 10000) / (items[_itemId].royalties + items[_itemId].price);
        bytes4 interfaceId = 0x2a55205a;
        require(_nft.supportsInterface(interfaceId), "ERC2981 unsupported");
        (royaltyRec, royaltyAmount) = _nft.royaltyInfo(_itemId, salePrice);
    }

    function totalOffersPer(uint _itemId) public view returns(uint totalOffers) {
        totalOffers = offerCount[_itemId];
    }

 }