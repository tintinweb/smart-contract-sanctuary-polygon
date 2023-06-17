/**
 *Submitted for verification at polygonscan.com on 2023-06-16
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.19;

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

/**
    @author The Calystral Team
    @title The Scrap' Interface
*/
interface IScrap is IERC20 {
    /* ========== CONSTANTS ========== */
    function SCRAPTRANSFER_TYPEHASH() external view returns (bytes32);

    function SCRAPBURN_TYPEHASH() external view returns (bytes32);

    function SCRAPAPPROVE_TYPEHASH() external view returns (bytes32);

    function SCRAPINCREASEALLOWANCE_TYPEHASH() external view returns (bytes32);

    function SCRAPDECREASEALLOWANCE_TYPEHASH() external view returns (bytes32);

    /* ========== DATA STRUCTURES ========== */
    struct ScrapTransfer {
        address from;
        address to;
        uint256 amount;
        bytes data;
        uint256 nonce;
        uint256 maxTimestamp;
    }

    struct ScrapBurn {
        address account;
        uint256 amount;
        bytes data;
        uint256 nonce;
        uint256 maxTimestamp;
    }

    struct ScrapApprove {
        address owner;
        address spender;
        uint256 amount;
        bytes data;
        uint256 nonce;
        uint256 maxTimestamp;
    }

    struct ScrapIncreaseAllowance {
        address owner;
        address spender;
        uint256 addedValue;
        bytes data;
        uint256 nonce;
        uint256 maxTimestamp;
    }

    struct ScrapDecreaseAllowance {
        address owner;
        address spender;
        uint256 subtractedValue;
        bytes data;
        uint256 nonce;
        uint256 maxTimestamp;
    }

    /* ========== EVENTS ========== */

    /* ========== EXTERNAL FUNCTIONS ========== */
    function burn(address account, uint256 amount) external;

    function invalidateNonce(uint256 nonce) external;

    function metaTransfer(
        bytes calldata signature,
        ScrapTransfer calldata scrapTransfer
    ) external returns (bool);

    function metaBurn(
        bytes calldata signature,
        ScrapBurn calldata scrapBurn
    ) external;

    function metaApprove(
        bytes calldata signature,
        ScrapApprove calldata scrapApprove
    ) external returns (bool);

    function metaIncreaseAllowance(
        bytes calldata signature,
        ScrapIncreaseAllowance calldata scrapIncreaseAllowance
    ) external returns (bool);

    function metaDecreaseAllowance(
        bytes calldata signature,
        ScrapDecreaseAllowance calldata scrapDecreaseAllowance
    ) external returns (bool);

    /* ========== VIEW FUNCTIONS ========== */

    /* ========== RESTRICTED FUNCTIONS ========== */
    function batchMint(
        address[] calldata accounts,
        uint256[] calldata amounts
    ) external;
}

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

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
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
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
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
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
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
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
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
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
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
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        _update(from, to, amount);
    }

    /**
     * @dev Transfers `amount` of tokens from `from` to `to`, or alternatively mints (or burns) if `from` (or `to`) is
     * the zero address. All customizations to transfers, mints, and burns should be done by overriding this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (from == address(0)) {
            _totalSupply += amount;
        } else {
            uint256 fromBalance = _balances[from];
            require(
                fromBalance >= amount,
                "ERC20: transfer amount exceeds balance"
            );
            unchecked {
                // Overflow not possible: amount <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - amount;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: amount <= totalSupply or amount <= fromBalance <= totalSupply.
                _totalSupply -= amount;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + amount is at most totalSupply, which we know fits into a uint256.
                _balances[to] += amount;
            }
        }

        emit Transfer(from, to, amount);
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _update(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, by transferring it to address(0).
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _update(account, address(0), amount);
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
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v5.0._
     */
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v5.0._
     */
    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v5.0._
     */
    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v5.0._
     */
    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v5.0._
     */
    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function sqrt(
        uint256 a,
        Rounding rounding
    ) internal pure returns (uint256) {
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
    function log2(
        uint256 value,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(
        uint256 value,
        Rounding rounding
    ) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return
                result +
                (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(
        uint256 value,
        Rounding rounding
    ) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return
                result +
                (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    value < 0 ? "-" : "",
                    toString(SignedMath.abs(value))
                )
            );
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
    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        return
            bytes(a).length == bytes(b).length &&
            keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        unchecked {
            bytes32 s = vs &
                bytes32(
                    0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                );
            // We do not check for an overflow here since the shift operation results in 0 or 1.
            uint8 v = uint8((uint256(vs) >> 255) + 27);
            return tryRecover(hash, v, r, s);
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(
        bytes32 hash
    ) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(
        bytes memory s
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    Strings.toString(s.length),
                    s
                )
            );
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(
        bytes32 domainSeparator,
        bytes32 structHash
    ) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, hex"19_01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(
        address validator,
        bytes memory data
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(hex"19_00", validator, data));
    }
}

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(newImplementation.code.length > 0, "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(
        bytes32 slot
    ) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(
        bytes32 slot
    ) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(
        bytes32 slot
    ) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(
        bytes32 slot
    ) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(
        bytes32 slot
    ) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(
        string storage store
    ) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(
        bytes32 slot
    ) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(
        bytes storage store
    ) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// | string  | 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA   |
// | length  | 0x                                                              BB |
type ShortString is bytes32;

/**
 * @dev This library provides functions to convert short memory strings
 * into a `ShortString` type that can be used as an immutable variable.
 *
 * Strings of arbitrary length can be optimized using this library if
 * they are short enough (up to 31 bytes) by packing them with their
 * length (1 byte) in a single EVM word (32 bytes). Additionally, a
 * fallback mechanism can be used for every other case.
 *
 * Usage example:
 *
 * ```solidity
 * contract Named {
 *     using ShortStrings for *;
 *
 *     ShortString private immutable _name;
 *     string private _nameFallback;
 *
 *     constructor(string memory contractName) {
 *         _name = contractName.toShortStringWithFallback(_nameFallback);
 *     }
 *
 *     function name() external view returns (string memory) {
 *         return _name.toStringWithFallback(_nameFallback);
 *     }
 * }
 * ```
 */
library ShortStrings {
    // Used as an identifier for strings longer than 31 bytes.
    bytes32 private constant _FALLBACK_SENTINEL =
        0x00000000000000000000000000000000000000000000000000000000000000FF;

    error StringTooLong(string str);
    error InvalidShortString();

    /**
     * @dev Encode a string of at most 31 chars into a `ShortString`.
     *
     * This will trigger a `StringTooLong` error is the input string is too long.
     */
    function toShortString(
        string memory str
    ) internal pure returns (ShortString) {
        bytes memory bstr = bytes(str);
        if (bstr.length > 31) {
            revert StringTooLong(str);
        }
        return ShortString.wrap(bytes32(uint256(bytes32(bstr)) | bstr.length));
    }

    /**
     * @dev Decode a `ShortString` back to a "normal" string.
     */
    function toString(ShortString sstr) internal pure returns (string memory) {
        uint256 len = byteLength(sstr);
        // using `new string(len)` would work locally but is not memory safe.
        string memory str = new string(32);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(str, len)
            mstore(add(str, 0x20), sstr)
        }
        return str;
    }

    /**
     * @dev Return the length of a `ShortString`.
     */
    function byteLength(ShortString sstr) internal pure returns (uint256) {
        uint256 result = uint256(ShortString.unwrap(sstr)) & 0xFF;
        if (result > 31) {
            revert InvalidShortString();
        }
        return result;
    }

    /**
     * @dev Encode a string into a `ShortString`, or write it to storage if it is too long.
     */
    function toShortStringWithFallback(
        string memory value,
        string storage store
    ) internal returns (ShortString) {
        if (bytes(value).length < 32) {
            return toShortString(value);
        } else {
            StorageSlot.getStringSlot(store).value = value;
            return ShortString.wrap(_FALLBACK_SENTINEL);
        }
    }

    /**
     * @dev Decode a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     */
    function toStringWithFallback(
        ShortString value,
        string storage store
    ) internal pure returns (string memory) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return toString(value);
        } else {
            return store;
        }
    }

    /**
     * @dev Return the length of a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     *
     * WARNING: This will return the "byte length" of the string. This may not reflect the actual length in terms of
     * actual characters as the UTF-8 encoding of a single character can span over multiple bytes.
     */
    function byteLengthWithFallback(
        ShortString value,
        string storage store
    ) internal view returns (uint256) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return byteLength(value);
        } else {
            return bytes(store).length;
        }
    }
}

interface IERC5267 {
    /**
     * @dev MAY be emitted to signal that the domain could have changed.
     */
    event EIP712DomainChanged();

    /**
     * @dev returns the fields and values that describe the domain separator used by this contract for EIP-712
     * signature.
     */
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
}

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * NOTE: In the upgradeable version of this contract, the cached values will correspond to the address, and the domain
 * separator of the implementation contract. This will cause the `_domainSeparatorV4` function to always rebuild the
 * separator from the immutable values, which is cheaper than accessing a cached version in cold storage.
 *
 * _Available since v3.4._
 *
 * @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
 */
abstract contract EIP712 is IERC5267 {
    using ShortStrings for *;

    bytes32 private constant _TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _cachedDomainSeparator;
    uint256 private immutable _cachedChainId;
    address private immutable _cachedThis;

    bytes32 private immutable _hashedName;
    bytes32 private immutable _hashedVersion;

    ShortString private immutable _name;
    ShortString private immutable _version;
    string private _nameFallback;
    string private _versionFallback;

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        _name = name.toShortStringWithFallback(_nameFallback);
        _version = version.toShortStringWithFallback(_versionFallback);
        _hashedName = keccak256(bytes(name));
        _hashedVersion = keccak256(bytes(version));

        _cachedChainId = block.chainid;
        _cachedDomainSeparator = _buildDomainSeparator();
        _cachedThis = address(this);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _cachedThis && block.chainid == _cachedChainId) {
            return _cachedDomainSeparator;
        } else {
            return _buildDomainSeparator();
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _TYPE_HASH,
                    _hashedName,
                    _hashedVersion,
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(
        bytes32 structHash
    ) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev See {EIP-5267}.
     *
     * _Available since v4.9._
     */
    function eip712Domain()
        public
        view
        virtual
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        return (
            hex"0f", // 01111
            _name.toStringWithFallback(_nameFallback),
            _version.toStringWithFallback(_versionFallback),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }
}

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

/**
    @author The Calystral Team
    @title The RegistrableContractState's Interface
*/
interface IRegistrableContractState is IERC165 {
    /*==============================
    =           EVENTS             =
    ==============================*/
    /// @dev MUST emit when the contract is set to an active state.
    event Activated();
    /// @dev MUST emit when the contract is set to an inactive state.
    event Inactivated();

    /*==============================
    =          FUNCTIONS           =
    ==============================*/
    /**
        @notice Sets the contract state to active.
        @dev Sets the contract state to active.
    */
    function setActive() external;

    /**
        @notice Sets the contract state to inactive.
        @dev Sets the contract state to inactive.
    */
    function setInactive() external;

    /**
        @dev Sets the registry contract object.
        Reverts if the registryAddress doesn't implement the IRegistry interface.
        @param registryAddress The registry address
    */
    function setRegistry(address registryAddress) external;

    /**
        @notice Returns the current contract state.
        @dev Returns the current contract state.
        @return The current contract state (true == active; false == inactive)
    */
    function getIsActive() external view returns (bool);

    /**
        @notice Returns the Registry address.
        @dev Returns the Registry address.
        @return The Registry address
    */
    function getRegistryAddress() external view returns (address);

    /**
        @notice Returns the current address associated with `key` identifier.
        @dev Look-up in the Registry.
        Returns the current address associated with `key` identifier.
        @return The key identifier
    */
    function getContractAddress(uint256 key) external view returns (address);
}

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor() {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

/**
    @author The Calystral Team
    @title The Registry's Interface
*/
interface IRegistry is IRegistrableContractState {
    /*==============================
    =           EVENTS             =
    ==============================*/
    /**
        @dev MUST emit when an entry in the Registry is set or updated.
        The `key` argument MUST be the key of the entry which is set or updated.
        The `value` argument MUST be the address of the entry which is set or updated.
    */
    event EntrySet(uint256 indexed key, address value);
    /**
        @dev MUST emit when an entry in the Registry is removed.
        The `key` argument MUST be the key of the entry which is removed.
        The `value` argument MUST be the address of the entry which is removed.
    */
    event EntryRemoved(uint256 indexed key, address value);

    /*==============================
    =          FUNCTIONS           =
    ==============================*/
    /**
        @notice Sets the MultiSigAdmin contract as Registry entry 1.
        @dev Sets the MultiSigAdmin contract as Registry entry 1.
        @param msaAddress The contract address of the MultiSigAdmin
    */
    function initializeMultiSigAdmin(address msaAddress) external;

    /**
        @notice Checks if the registry Map contains the key.
        @dev Returns true if the key is in the registry map. O(1).
        @param key  The key to search for
        @return     The boolean result
    */
    function contains(uint256 key) external view returns (bool);

    /**
        @notice Returns the registry map length.
        @dev Returns the number of key-value pairs in the registry map. O(1).
        @return     The registry map length
    */
    function length() external view returns (uint256);

    /**
        @notice Returns the key-value pair stored at position `index` in the registry map.
        @dev Returns the key-value pair stored at position `index` in the registry map. O(1).
        Note that there are no guarantees on the ordering of entries inside the
        array, and it may change when more entries are added or removed.
        Requirements:
        - `index` must be strictly less than {length}.
        @param index    The position in the registry map
        @return         The key-value pair as a tuple
    */
    function at(uint256 index) external view returns (uint256, address);

    /**
        @notice Tries to return the value associated with `key`.
        @dev Tries to return the value associated with `key`.  O(1).
        Does not revert if `key` is not in the registry map.
        @param key    The key to search for
        @return       The key-value pair as a tuple
    */
    function tryGet(uint256 key) external view returns (bool, address);

    /**
        @notice Returns the value associated with `key`.
        @dev Returns the value associated with `key`.  O(1).
        Requirements:
        - `key` must be in the registry map.
        @param key    The key to search for
        @return       The contract address
    */
    function get(uint256 key) external view returns (address);

    /**
        @notice Returns all indices, keys, addresses.
        @dev Returns all indices, keys, addresses as three seperate arrays.
        @return Indices, keys, addresses
    */
    function getAll()
        external
        view
        returns (uint256[] memory, uint256[] memory, address[] memory);

    /**
        @notice Adds a key-value pair to a map, or updates the value for an existing
        key.
        @dev Adds a key-value pair to the registry map, or updates the value for an existing
        key. O(1).
        Returns true if the key was added to the registry map, that is if it was not
        already present.
        @param key    The key as an identifier
        @param value  The address of the contract
        @return       Success as a bool
    */
    function set(uint256 key, address value) external returns (bool);

    /**
        @notice Removes a value from the registry map.
        @dev Removes a value from the registry map. O(1).
        Returns true if the key was removed from the registry map, that is if it was present.
        @param key    The key as an identifier
        @return       Success as a bool
    */
    function remove(uint256 key) external returns (bool);

    /**
        @notice Sets a contract state to active.
        @dev Sets a contract state to active.
        @param key    The key as an identifier
    */
    function setContractActiveByKey(uint256 key) external;

    /**
        @notice Sets a contract state to active.
        @dev Sets a contract state to active.
        @param contractAddress The contract's address
    */
    function setContractActiveByAddress(address contractAddress) external;

    /**
        @notice Sets all contracts within the registry to state active.
        @dev Sets all contracts within the registry to state active.
        Does NOT revert if any contract doesn't implement the RegistrableContractState interface.
        Does NOT revert if it is an externally owned user account.
    */
    function setAllContractsActive() external;

    /**
        @notice Sets a contract state to inactive.
        @dev Sets a contract state to inactive.
        @param key    The key as an identifier
    */
    function setContractInactiveByKey(uint256 key) external;

    /**
        @notice Sets a contract state to inactive.
        @dev Sets a contract state to inactive.
        @param contractAddress The contract's address
    */
    function setContractInactiveByAddress(address contractAddress) external;

    /**
        @notice Sets all contracts within the registry to state inactive.
        @dev Sets all contracts within the registry to state inactive.
        Does NOT revert if any contract doesn't implement the RegistrableContractState interface.
        Does NOT revert if it is an externally owned user account.
    */
    function setAllContractsInactive() external;
}

/**
    @author The Calystral Team
    @title A helper parent contract: Pausable & Registry
*/
contract RegistrableContractState is IRegistrableContractState, ERC165 {
    /*==============================
    =          CONSTANTS           =
    ==============================*/

    /*==============================
    =            STORAGE           =
    ==============================*/
    /// @dev Current contract state
    bool private _isActive;
    /// @dev Current registry pointer
    address private _registryAddress;

    /*==============================
    =          MODIFIERS           =
    ==============================*/
    modifier isActive() {
        _isActiveCheck();
        _;
    }

    modifier isAuthorizedAdmin() {
        _isAuthorizedAdmin();
        _;
    }

    modifier isAuthorizedAdminOrRegistry() {
        _isAuthorizedAdminOrRegistry();
        _;
    }

    /*==============================
    =          CONSTRUCTOR         =
    ==============================*/
    /**
        @notice Creates and initializes the contract.
        @dev Creates and initializes the contract.
        Registers all implemented interfaces.
        Inheriting contracts are INACTIVE by default.
    */
    constructor(address registryAddress) {
        _registryAddress = registryAddress;

        _registerInterface(type(IRegistrableContractState).interfaceId);
    }

    /*==============================
    =      PUBLIC & EXTERNAL       =
    ==============================*/

    /*==============================
    =          RESTRICTED          =
    ==============================*/
    function setActive() external override isAuthorizedAdminOrRegistry {
        _isActive = true;

        emit Activated();
    }

    function setInactive() external override isAuthorizedAdminOrRegistry {
        _isActive = false;

        emit Inactivated();
    }

    function setRegistry(
        address registryAddress
    ) external override isAuthorizedAdmin {
        _registryAddress = registryAddress;

        try
            _registryContract().supportsInterface(type(IRegistry).interfaceId)
        returns (bool supportsInterface) {
            require(
                supportsInterface,
                "The provided contract does not implement the Registry interface"
            );
        } catch {
            revert(
                "The provided contract does not implement the Registry interface"
            );
        }
    }

    /*==============================
    =          VIEW & PURE         =
    ==============================*/
    function getIsActive() public view override returns (bool) {
        return _isActive;
    }

    function getRegistryAddress() public view override returns (address) {
        return _registryAddress;
    }

    function getContractAddress(
        uint256 key
    ) public view override returns (address) {
        return _registryContract().get(key);
    }

    /*==============================
    =      INTERNAL & PRIVATE      =
    ==============================*/
    /**
        @dev Returns the target Registry object.
        @return The target Registry object
    */
    function _registryContract() internal view returns (IRegistry) {
        return IRegistry(_registryAddress);
    }

    /**
        @dev Checks if the contract is in an active state.
        Reverts if the contract is INACTIVE.
    */
    function _isActiveCheck() internal view {
        require(_isActive == true, "The contract is not active");
    }

    /**
        @dev Checks if the msg.sender is the Admin.
        Reverts if msg.sender is not the Admin.
    */
    function _isAuthorizedAdmin() internal view {
        require(msg.sender == getContractAddress(1), "Unauthorized call");
    }

    /**
        @dev Checks if the msg.sender is the Admin or the Registry.
        Reverts if msg.sender is not the Admin or the Registry.
    */
    function _isAuthorizedAdminOrRegistry() internal view {
        require(
            msg.sender == _registryAddress ||
                msg.sender == getContractAddress(1),
            "Unauthorized call"
        );
    }
}

/**
    @author The Calystral Team
    @title  Synergy of Serra in-game token.
*/
contract SynergyOfSerraScrap is
    IScrap,
    EIP712,
    ERC20,
    RegistrableContractState
{
    /*==============================
    =          CONSTANTS           =
    ==============================*/
    bytes32 public constant SCRAPTRANSFER_TYPEHASH =
        keccak256(
            "ScrapTransfer(address from,address to,uint256 amount,bytes data,uint256 nonce,uint256 maxTimestamp)"
        );
    bytes32 public constant SCRAPBURN_TYPEHASH =
        keccak256(
            "ScrapBurn(address account,uint256 amount,bytes data,uint256 nonce,uint256 maxTimestamp)"
        );
    bytes32 public constant SCRAPAPPROVE_TYPEHASH =
        keccak256(
            "ScrapApprove(address owner,address spender,uint256 amount,bytes data,uint256 nonce,uint256 maxTimestamp)"
        );
    bytes32 public constant SCRAPINCREASEALLOWANCE_TYPEHASH =
        keccak256(
            "ScrapIncreaseAllowance(address owner,address spender,uint256 addedValue,bytes data,uint256 nonce,uint256 maxTimestamp)"
        );
    bytes32 public constant SCRAPDECREASEALLOWANCE_TYPEHASH =
        keccak256(
            "ScrapDecreaseAllowance(address owner,address spender,uint256 subtractedValue,bytes data,uint256 nonce,uint256 maxTimestamp)"
        );

    /*==============================
    =       DATA STRUCTURES        =
    ==============================*/

    /*==============================
    =            STORAGE           =
    ==============================*/
    /// @dev signer => meta nonce => isUsed
    mapping(address => mapping(uint256 => bool)) public isMetaNonceUsed;

    /*==============================
    =          MODIFIERS           =
    ==============================*/
    modifier isAuthorizedScrapManager() {
        _isAuthorizedScrapManager();
        _;
    }

    /*==============================
    =          CONSTRUCTOR         =
    ==============================*/
    /**
        @notice Creates and initializes the contract.
        @dev Creates and initializes the contract.
        Registers all implemented interfaces.
        Contract is INACTIVE by default.
        @param registryAddress  Address of the Registry
    */
    constructor(
        string memory name,
        string memory symbol,
        address registryAddress
    )
        EIP712("Synergy of Serra Scrap", "1")
        ERC20(name, symbol)
        RegistrableContractState(registryAddress)
    {
        _registerInterface(type(EIP712).interfaceId);
        _registerInterface(type(IERC20).interfaceId);
        _registerInterface(type(IERC20Metadata).interfaceId);
    }

    /*==============================
    =      PUBLIC & EXTERNAL       =
    ==============================*/
    /**
        @dev See {IERC20-transfer}.
        
         Requirements:
        
         - `to` cannot be the zero address.
         - the caller must have a balance of at least `amount`.
    */
    function transfer(
        address to,
        uint256 amount
    ) public override(ERC20, IERC20) isActive returns (bool) {
        return super.transfer(to, amount);
    }

    /**
        @dev See {IERC20-transferFrom}.
        
        Emits an {Approval} event indicating the updated allowance. This is not
        required by the EIP. See the note at the beginning of {ERC20}.
        
        NOTE: Does not update the allowance if the current allowance
        is the maximum `uint256`.
        
        Requirements:
        
        - `from` and `to` cannot be the zero address.
        - `from` must have a balance of at least `amount`.
        - the caller must have allowance for ``from``'s tokens of at least
        `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override(ERC20, IERC20) isActive returns (bool) {
        return super.transferFrom(from, to, amount);
    }

    /**
         @dev See {IERC20-approve}.

         NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
         `transferFrom`. This is semantically equivalent to an infinite approval.

         Requirements:

         - `spender` cannot be the zero address.
     */
    function approve(
        address spender,
        uint256 amount
    ) public override(ERC20, IERC20) isActive returns (bool) {
        return super.approve(spender, amount);
    }

    /**
         @dev Atomically increases the allowance granted to `spender` by the caller.

         This is an alternative to {approve} that can be used as a mitigation for
         problems described in {IERC20-approve}.

         Emits an {Approval} event indicating the updated allowance.

         Requirements:

         - `spender` cannot be the zero address.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public override isActive returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    /**
         @dev Atomically decreases the allowance granted to `spender` by the caller.

         This is an alternative to {approve} that can be used as a mitigation for
         problems described in {IERC20-approve}.

         Emits an {Approval} event indicating the updated allowance.

         Requirements:

         - `spender` cannot be the zero address.
         - `spender` must have allowance for the caller of at least
         `subtractedValue`.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public override isActive returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    function burn(address account, uint256 amount) external isActive {
        _burn(account, amount);
    }

    function invalidateNonce(uint256 nonce) external override {
        _invalidateNonce(msg.sender, nonce);
    }

    function metaTransfer(
        bytes calldata signature,
        ScrapTransfer calldata scrapTransfer
    ) external isActive returns (bool) {
        address signer = ECDSA.recover(_digest(scrapTransfer), signature);
        require(scrapTransfer.from == signer, "Invalid signature");
        require(
            block.timestamp < scrapTransfer.maxTimestamp,
            "This transaction is not valid anymore"
        );
        require(
            isMetaNonceUsed[signer][scrapTransfer.nonce] == false,
            "This transaction was executed already"
        );
        _invalidateNonce(signer, scrapTransfer.nonce);
        _transfer(scrapTransfer.from, scrapTransfer.to, scrapTransfer.amount);

        return true;
    }

    function metaBurn(
        bytes calldata signature,
        ScrapBurn calldata scrapBurn
    ) external isActive {
        address signer = ECDSA.recover(_digest(scrapBurn), signature);
        require(scrapBurn.account == signer, "Invalid signature");
        require(
            block.timestamp < scrapBurn.maxTimestamp,
            "This transaction is not valid anymore"
        );
        require(
            isMetaNonceUsed[signer][scrapBurn.nonce] == false,
            "This transaction was executed already"
        );
        _invalidateNonce(signer, scrapBurn.nonce);
        _burn(scrapBurn.account, scrapBurn.amount);
    }

    function metaApprove(
        bytes calldata signature,
        ScrapApprove calldata scrapApprove
    ) external isActive returns (bool) {
        address signer = ECDSA.recover(_digest(scrapApprove), signature);
        require(scrapApprove.owner == signer, "Invalid signature");
        require(
            block.timestamp < scrapApprove.maxTimestamp,
            "This transaction is not valid anymore"
        );
        require(
            isMetaNonceUsed[signer][scrapApprove.nonce] == false,
            "This transaction was executed already"
        );
        _invalidateNonce(signer, scrapApprove.nonce);
        _approve(scrapApprove.owner, scrapApprove.spender, scrapApprove.amount);

        return true;
    }

    function metaIncreaseAllowance(
        bytes calldata signature,
        ScrapIncreaseAllowance calldata scrapIncreaseAllowance
    ) external isActive returns (bool) {
        address signer = ECDSA.recover(
            _digest(scrapIncreaseAllowance),
            signature
        );
        require(scrapIncreaseAllowance.owner == signer, "Invalid signature");
        require(
            block.timestamp < scrapIncreaseAllowance.maxTimestamp,
            "This transaction is not valid anymore"
        );
        require(
            isMetaNonceUsed[signer][scrapIncreaseAllowance.nonce] == false,
            "This transaction was executed already"
        );
        _invalidateNonce(signer, scrapIncreaseAllowance.nonce);
        _approve(
            scrapIncreaseAllowance.owner,
            scrapIncreaseAllowance.spender,
            allowance(
                scrapIncreaseAllowance.owner,
                scrapIncreaseAllowance.spender
            ) + scrapIncreaseAllowance.addedValue
        );

        return true;
    }

    function metaDecreaseAllowance(
        bytes calldata signature,
        ScrapDecreaseAllowance calldata scrapDecreaseAllowance
    ) external isActive returns (bool) {
        address signer = ECDSA.recover(
            _digest(scrapDecreaseAllowance),
            signature
        );
        require(scrapDecreaseAllowance.owner == signer, "Invalid signature");
        require(
            block.timestamp < scrapDecreaseAllowance.maxTimestamp,
            "This transaction is not valid anymore"
        );
        require(
            isMetaNonceUsed[signer][scrapDecreaseAllowance.nonce] == false,
            "This transaction was executed already"
        );
        _invalidateNonce(signer, scrapDecreaseAllowance.nonce);
        uint256 currentAllowance = allowance(
            scrapDecreaseAllowance.owner,
            scrapDecreaseAllowance.spender
        );
        require(
            currentAllowance >= scrapDecreaseAllowance.subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(
                scrapDecreaseAllowance.owner,
                scrapDecreaseAllowance.spender,
                currentAllowance - scrapDecreaseAllowance.subtractedValue
            );
        }

        return true;
    }

    /*==============================
    =          RESTRICTED          =
    ==============================*/
    function batchMint(
        address[] calldata accounts,
        uint256[] calldata amounts
    ) external isAuthorizedScrapManager {
        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], amounts[i]);
        }
    }

    /*==============================
    =          VIEW & PURE         =
    ==============================*/

    /*==============================
    =      INTERNAL & PRIVATE      =
    ==============================*/
    function _digest(
        ScrapBurn calldata scrapBurn
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        SCRAPBURN_TYPEHASH,
                        scrapBurn.account,
                        scrapBurn.amount,
                        keccak256(bytes(scrapBurn.data)),
                        scrapBurn.nonce,
                        scrapBurn.maxTimestamp
                    )
                )
            );
    }

    function _digest(
        ScrapTransfer calldata scrapTransfer
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        SCRAPTRANSFER_TYPEHASH,
                        scrapTransfer.from,
                        scrapTransfer.to,
                        scrapTransfer.amount,
                        keccak256(bytes(scrapTransfer.data)),
                        scrapTransfer.nonce,
                        scrapTransfer.maxTimestamp
                    )
                )
            );
    }

    function _digest(
        ScrapApprove calldata scrapApprove
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        SCRAPAPPROVE_TYPEHASH,
                        scrapApprove.owner,
                        scrapApprove.spender,
                        scrapApprove.amount,
                        keccak256(bytes(scrapApprove.data)),
                        scrapApprove.nonce,
                        scrapApprove.maxTimestamp
                    )
                )
            );
    }

    function _digest(
        ScrapIncreaseAllowance calldata scrapIncreaseAllowance
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        SCRAPINCREASEALLOWANCE_TYPEHASH,
                        scrapIncreaseAllowance.owner,
                        scrapIncreaseAllowance.spender,
                        scrapIncreaseAllowance.addedValue,
                        keccak256(bytes(scrapIncreaseAllowance.data)),
                        scrapIncreaseAllowance.nonce,
                        scrapIncreaseAllowance.maxTimestamp
                    )
                )
            );
    }

    function _digest(
        ScrapDecreaseAllowance calldata scrapDecreaseAllowance
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        SCRAPDECREASEALLOWANCE_TYPEHASH,
                        scrapDecreaseAllowance.owner,
                        scrapDecreaseAllowance.spender,
                        scrapDecreaseAllowance.subtractedValue,
                        keccak256(bytes(scrapDecreaseAllowance.data)),
                        scrapDecreaseAllowance.nonce,
                        scrapDecreaseAllowance.maxTimestamp
                    )
                )
            );
    }

    function _invalidateNonce(address signer, uint256 nonce) private {
        isMetaNonceUsed[signer][nonce] = true;
    }

    /**
        @dev Checks if the msg.sender is the ScrapManager.
        Reverts if msg.sender is not the ScrapManager.
    */
    function _isAuthorizedScrapManager() private view {
        require(
            getContractAddress(1008) == msg.sender,
            "Unauthorized call. Thanks for supporting the network with your ETH."
        );
    }
}