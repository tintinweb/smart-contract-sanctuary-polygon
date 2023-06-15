// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Capped.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20Capped is ERC20 {
    uint256 private immutable _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor(uint256 cap_) {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

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
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./FloatingMaths.sol";

// import "hardhat/console.sol";
// start-snippet: token import
import "./FNDRToken.sol";

// end-snippet: token import

// start-snippet: Unlockable reserve name
contract CommunityPoolReferrals is Ownable {
    // end-snippet: Unlockable reserve name

    // start-snippet: token definition
    FNDRToken public token;
    address public communityPoolAmbassadors_addr;
    address public communityPoolContributors_addr;
    address public daoWallet_addr;
    address public liquidityWallet_addr;
    // end-snippet: token definition

    uint public cliff;
    uint public vesting_period;
    uint public vesting_percentage;
    uint public deployDate;

    uint8 public tokenDecimals;

    // start-snippet: custom vars
    uint256 internal contributorsCounter;
    mapping(address => uint256) public contributorIds;
    mapping(uint256 => address) public contributorWallets;
    mapping(uint256 => uint256) public subscriptions;
    mapping(uint256 => uint256) public patrons;
    uint256 public subscriptionPrice;
    uint256 public totalPatrons;

    bool private initialized;

    // end-snippet: custom vars

    constructor() {
        // start-snippet: init definitions
        cliff = 30;
        vesting_period = 30;
        vesting_percentage = 50;
        // end-snippet: init definitions
        deployDate = block.timestamp;
    }

    function initialize(
        address _token,
        address _communityPoolAmbassadors_addr,
        address _communityPoolContributors_addr,
        address _daoWallet_addr,
        address _liquidityWallet_addr
    ) public {
        require(!initialized, "DynamicICO: contract is already initialized");

        token = FNDRToken(_token);
        tokenDecimals = token.decimals();

        initialized = true;

        subscriptionPrice = FMaths.mul(50000, 1, 0, 0, tokenDecimals);
        // redistribution addresses
        communityPoolAmbassadors_addr = _communityPoolAmbassadors_addr;
        communityPoolContributors_addr = _communityPoolContributors_addr;
        daoWallet_addr = _daoWallet_addr;
        liquidityWallet_addr = _liquidityWallet_addr;
    }

    /*
     * @dev Distributes the vesting percentage of the token it contains to owner.
     * Can only be called at most once every per vesting period.
     */
    function distribute() public onlyOwner {
        uint lastPeriod = deployDate + cliff * 1 days;
        require(
            block.timestamp >= lastPeriod,
            string(
                abi.encodePacked(
                    "Need to wait ",
                    Strings.toString(vesting_period),
                    " days after last distribution"
                )
            )
        );
        uint availableAmount = (token.balanceOf(address(this)) *
            vesting_percentage) / 100;

        for (
            uint contributorId = 0;
            contributorId < contributorsCounter;
            contributorId++
        ) {
            if (patrons[contributorId] > 0) {
                token.transfer(
                    contributorWallets[contributorId],
                    (patrons[contributorId] * availableAmount) / totalPatrons
                );
            }
        }
        cliff += vesting_period;
    }

    // start-snippet: custom code
    event RenewedSubscription(
        address contributor,
        address sponsor,
        uint256 endDate
    );
    event SubscriptionPriceUpdated(uint256 newPrice, uint256 oldPrice);

    function setSubscriptionPrice(uint256 newPrice) public onlyOwner {
        emit SubscriptionPriceUpdated(newPrice, subscriptionPrice);
        subscriptionPrice = newPrice;
    }

    function isSubscribed(
        address subscriber
    ) public view returns (bool subscription) {
        return block.timestamp <= subscriptions[contributorIds[subscriber]];
    }

    /*
     * @dev Renew subscription of contributor to allow rides creation
     */
    function renewSubscription(address sponsor) public {
        renewSubscriptionFor(msg.sender, sponsor, address(0));
    }

    function renewSubscriptionFor(
        address contributor,
        address sponsor,
        address payer
    ) public {
        if (payer == address(0)) {
            _transferTokens(contributor);
        } else {
            _transferTokens(payer);
        }

        if (contributorIds[contributor] == 0) {
            // new account
            contributorsCounter += 1;
            contributorIds[contributor] = contributorsCounter;
            contributorWallets[contributorsCounter] = contributor;
        }

        if (subscriptions[contributorIds[contributor]] > block.timestamp) {
            subscriptions[contributorIds[contributor]] += 365 * 1 days;
        } else {
            subscriptions[contributorIds[contributor]] =
                block.timestamp +
                365 *
                1 days;
        }

        if (sponsor != address(0)) {
            patrons[contributorIds[sponsor]] += 1;
            totalPatrons += 1;
        }

        emit RenewedSubscription(
            contributor,
            sponsor,
            subscriptions[contributorIds[contributor]]
        );
    }

    function offerSubscription(
        address contributor,
        uint256 daysOffered
    ) public onlyOwner {
        if (contributorIds[contributor] == 0) {
            // new account
            contributorsCounter += 1;
            contributorIds[contributor] = contributorsCounter;
            contributorWallets[contributorsCounter] = contributor;
        }

        if (subscriptions[contributorIds[contributor]] > block.timestamp) {
            subscriptions[contributorIds[contributor]] += daysOffered * 1 days;
        } else {
            subscriptions[contributorIds[contributor]] =
                block.timestamp +
                daysOffered *
                1 days;
        }

        emit RenewedSubscription(
            contributor,
            address(0),
            subscriptions[contributorIds[contributor]]
        );
    }

    function _transferTokens(address sender) internal {
        uint256 communityPoolAmbassadors_amount = FMaths.div(
            FMaths.mul(subscriptionPrice, 5, tokenDecimals, 0, tokenDecimals),
            100,
            tokenDecimals,
            0,
            tokenDecimals
        );
        uint256 communityPoolContributors_amount = FMaths.div(
            FMaths.mul(subscriptionPrice, 5, tokenDecimals, 0, tokenDecimals),
            100,
            tokenDecimals,
            0,
            tokenDecimals
        );
        uint256 communityPoolReferrals_amount = FMaths.div(
            FMaths.mul(subscriptionPrice, 5, tokenDecimals, 0, tokenDecimals),
            100,
            tokenDecimals,
            0,
            tokenDecimals
        );
        uint256 daoWallet_amount = FMaths.div(
            FMaths.mul(subscriptionPrice, 60, tokenDecimals, 0, tokenDecimals),
            100,
            tokenDecimals,
            0,
            tokenDecimals
        );
        uint256 liquidityWallet_amount = FMaths.div(
            FMaths.mul(subscriptionPrice, 25, tokenDecimals, 0, tokenDecimals),
            100,
            tokenDecimals,
            0,
            tokenDecimals
        );

        token.transferFrom(
            sender,
            communityPoolAmbassadors_addr,
            communityPoolAmbassadors_amount
        );
        token.transferFrom(
            sender,
            communityPoolContributors_addr,
            communityPoolContributors_amount
        );
        token.transferFrom(
            sender,
            address(this),
            communityPoolReferrals_amount
        );
        token.transferFrom(sender, daoWallet_addr, daoWallet_amount);
        token.transferFrom(
            sender,
            liquidityWallet_addr,
            liquidityWallet_amount
        );
    }
    // end-snippet: custom code
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
 * @dev Wrappers over Solidity's arithmetic operations.
 */
library FMaths {
  uint8 constant decimalsDefault = 18;

  /*
   * @dev Returns the addition of two uint256 (a + b)
   * @param a
   * @param b
   * @param decimalsA [optional] the number of floating points for a
   * @param decimalsB [optional] the number of floating points for b
   * @param decimalsOut [optional] the number of floating points for the result
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert (c >= a);
    assert (c >= b);
    return c;
  }
  function add(uint256 a, uint256 b, uint8 decimalsOut) internal pure returns (uint256) {
    assert (decimalsOut <= decimalsDefault);
    uint256 result = a + b;
    assert (result >= a);
    assert (result >= b);
    return result / (10 ** uint256(decimalsDefault - decimalsOut));
  }
  function add(uint256 a, uint256 b, uint8 decimalsA, uint8 decimalsB) internal pure returns (uint256) {
    assert (decimalsA <= decimalsDefault);
    assert (decimalsB <= decimalsDefault);
    uint8 deltaDecimalsA = decimalsDefault - decimalsA;
    uint8 deltaDecimalsB = decimalsDefault - decimalsB;
    uint256 result = add(a * 10 ** uint256(deltaDecimalsA), b * 10 ** uint256(deltaDecimalsB));
    return result;
  }
  function add(uint256 a, uint256 b, uint8 decimalsA, uint8 decimalsB, uint8 decimalsOut) internal pure returns (uint256) {
    assert (decimalsA <= decimalsDefault);
    assert (decimalsB <= decimalsDefault);
    assert (decimalsOut <= decimalsDefault);
    uint8 deltaDecimalsA = decimalsDefault - decimalsA;
    uint8 deltaDecimalsB = decimalsDefault - decimalsB;
    uint256 result = add(a * 10 ** uint256(deltaDecimalsA), b * 10 ** uint256(deltaDecimalsB));
    return result / (10 ** uint256(decimalsDefault - decimalsOut));
  }

  /*
   * @dev Returns the substraction of two uint256 (a - b)
   * @param a
   * @param b
   * @param decimalsA [optional] the number of floating points for a
   * @param decimalsB [optional] the number of floating points for b
   * @param decimalsOut [optional] the number of floating points for the result
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a - b;
    assert (c <= a);
    return c;
  }
  function sub(uint256 a, uint256 b, uint8 decimalsOut) internal pure returns (uint256) {
    assert (decimalsOut <= decimalsDefault);
    uint256 result = a - b;
    assert (result <= a);
    return result / (10 ** uint256(decimalsDefault - decimalsOut));
  }
  function sub(uint256 a, uint256 b, uint8 decimalsA, uint8 decimalsB) internal pure returns (uint256) {
    assert (decimalsA <= decimalsDefault);
    assert (decimalsB <= decimalsDefault);
    return sub(a * 10 ** uint256(decimalsDefault - decimalsA), b * 10 ** uint256(decimalsDefault - decimalsB));
  }
  function sub(uint256 a, uint256 b, uint8 decimalsA, uint8 decimalsB, uint8 decimalsOut) internal pure returns (uint256) {
    assert (decimalsA <= decimalsDefault);
    assert (decimalsB <= decimalsDefault);
    assert (decimalsOut <= decimalsDefault);
    uint256 result = sub(a * 10 ** uint256(decimalsDefault - decimalsA), b * 10 ** uint256(decimalsDefault - decimalsB));
    return result / (10 ** uint256(decimalsDefault - decimalsOut));
  }

  /*
   * @dev Returns the multiplication of two uint256 (a * b)
   * @param a
   * @param b
   * @param decimalsA [optional] the number of floating points for a
   * @param decimalsB [optional] the number of floating points for b
   * @param decimalsOut [optional] the number of floating points for the result
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = (a * b) / (10 ** decimalsDefault);
    return c;
  }
  function mul(uint256 a, uint256 b, uint8 decimalsOut) internal pure returns (uint256) {
    assert (decimalsOut <= decimalsDefault);
    uint256 result = mul(a, b);
    return result / 10 ** uint256(decimalsDefault - decimalsOut);
  }
  function mul(uint256 a, uint256 b, uint8 decimalsA, uint8 decimalsB) internal pure returns (uint256) {
    assert (decimalsA <= decimalsDefault);
    assert (decimalsB <= decimalsDefault);
    uint8 deltaDecimalsA = decimalsDefault - decimalsA;
    uint8 deltaDecimalsB = decimalsDefault - decimalsB;
    return mul(a * 10 ** uint256(deltaDecimalsA), b * 10 ** uint256(deltaDecimalsB));
  }
  function mul(uint256 a, uint256 b, uint8 decimalsA, uint8 decimalsB, uint8 decimalsOut) internal pure returns (uint256) {
    assert (decimalsA <= decimalsDefault);
    assert (decimalsB <= decimalsDefault);
    assert (decimalsOut <= decimalsDefault);
    uint256 result = mul(a * 10 ** uint256(decimalsDefault - decimalsA), b * 10 ** uint256(decimalsDefault - decimalsB));
    return result / (10 ** uint256(decimalsDefault - decimalsOut));
  }

  /*
   * @dev Returns the division of two uint256 (a / b)
   * @param a
   * @param b
   * @param decimalsA [optional] the number of floating points for a
   * @param decimalsB [optional] the number of floating points for b
   * @param decimalsOut [optional] the number of floating points for the result
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a * (10 ** decimalsDefault) / b;
  }
  function div(uint256 a, uint256 b, uint8 decimalsOut) internal pure returns (uint256) {
    assert (decimalsOut <= decimalsDefault);
    uint256 result = div(a, b);
    return result / 10 ** uint256(decimalsDefault - decimalsOut);
  }
  function div(uint256 a, uint256 b, uint8 decimalsA, uint8 decimalsB) internal pure returns (uint256) {
    assert (decimalsA <= decimalsDefault);
    assert (decimalsB <= decimalsDefault);
    return div(a * 10 ** uint256(decimalsDefault - decimalsA), b * 10 ** uint256(decimalsDefault - decimalsB));
  }
  function div(uint256 a, uint256 b, uint8 decimalsA, uint8 decimalsB, uint8 decimalsOut) internal pure returns (uint256) {
    assert (decimalsA <= decimalsDefault);
    assert (decimalsB <= decimalsDefault);
    assert (decimalsOut <= decimalsDefault);
    uint256 result = div(a * 10 ** uint256(decimalsDefault - decimalsA), b * 10 ** uint256(decimalsDefault - decimalsB));
    return result / (10 ** uint256(decimalsDefault - decimalsOut));
  }

  /*
   * @dev Returns the maximum between two values
   * @param a
   * @param b
   * @param decimalsA [optional] the number of floating points for a
   * @param decimalsB [optional] the number of floating points for b
   * @param decimalsOut [optional] the number of floating points for the result
   */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? a : b;
  }
  function max(uint256 a, uint256 b, uint8 decimalsOut) internal pure returns (uint256) {
    assert (decimalsOut <= decimalsDefault);
    return max(a, b) / (10 ** uint256(decimalsDefault - decimalsOut));
  }
  function max(uint256 a, uint256 b, uint8 decimalsA, uint8 decimalsB) internal pure returns (uint256) {
    assert (decimalsA <= decimalsDefault);
    assert (decimalsB <= decimalsDefault);
    return max(a * 10 ** uint256(decimalsDefault - decimalsA), b * 10 ** uint256(decimalsDefault - decimalsB));
  }
  function max(uint256 a, uint256 b, uint8 decimalsA, uint8 decimalsB, uint8 decimalsOut) internal pure returns (uint256) {
    assert (decimalsA <= decimalsDefault);
    assert (decimalsB <= decimalsDefault);
    assert (decimalsOut <= decimalsDefault);
    uint256 result = max(a * 10 ** uint256(decimalsDefault - decimalsA), b * 10 ** uint256(decimalsDefault - decimalsB));
    return result / (10 ** uint256(decimalsDefault - decimalsOut));
  }

  /*
   * @dev Returns the minimum between two values
   * @param a
   * @param b
   * @param decimalsA [optional] the number of floating points for a
   * @param decimalsB [optional] the number of floating points for b
   * @param decimalsOut [optional] the number of floating points for the result
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? b : a;
  }
  function min(uint256 a, uint256 b, uint8 decimalsOut) internal pure returns (uint256) {
    assert (decimalsOut <= decimalsDefault);
    return min(a, b) / (10 ** uint256(decimalsDefault - decimalsOut));
  }
  function min(uint256 a, uint256 b, uint8 decimalsA, uint8 decimalsB) internal pure returns (uint256) {
    assert (decimalsA <= decimalsDefault);
    assert (decimalsB <= decimalsDefault);
    return min(a * 10 ** uint256(decimalsDefault - decimalsA), b * 10 ** uint256(decimalsDefault - decimalsB));
  }
  function min(uint256 a, uint256 b, uint8 decimalsA, uint8 decimalsB, uint8 decimalsOut) internal pure returns (uint256) {
    assert (decimalsA <= decimalsDefault);
    assert (decimalsB <= decimalsDefault);
    assert (decimalsOut <= decimalsDefault);
    uint256 result = min(a * 10 ** uint256(decimalsDefault - decimalsA), b * 10 ** uint256(decimalsDefault - decimalsB));
    return result / (10 ** uint256(decimalsDefault - decimalsOut));
  }

  /*
   * @dev Returns the squre root of a value
   * @param x
   * @param decimalsX [optional] the number of floating points for x
   * @param decimalsOut [optional] the number of floating points for the result
   */
  function sqrt(uint256 _x) internal pure returns (uint256 result) {
    uint256 x = _x * 10 ** decimalsDefault;
    if (x == 0) {
        return 0;
    }

    // Calculate the square root of the perfect square of a power of two that is the closest to x.
    uint256 xAux = uint256(x);
    result = 1;
    if (xAux >= 0x100000000000000000000000000000000) {
        xAux >>= 128;
        result <<= 64;
    }
    if (xAux >= 0x10000000000000000) {
        xAux >>= 64;
        result <<= 32;
    }
    if (xAux >= 0x100000000) {
        xAux >>= 32;
        result <<= 16;
    }
    if (xAux >= 0x10000) {
        xAux >>= 16;
        result <<= 8;
    }
    if (xAux >= 0x100) {
        xAux >>= 8;
        result <<= 4;
    }
    if (xAux >= 0x10) {
        xAux >>= 4;
        result <<= 2;
    }
    if (xAux >= 0x8) {
        result <<= 1;
    }

    // The operations can never overflow because the result is max 2^127 when it enters this block.
    unchecked {
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1; // Seven iterations should be enough
        uint256 roundedDownResult = x / result;
        return result >= roundedDownResult ? roundedDownResult : result;
    }
  }
  function sqrt(uint256 x, uint8 decimalsX) internal pure returns (uint256 result) {
    assert (decimalsX <= decimalsDefault);
    return sqrt(x * (10 ** uint256(decimalsDefault - decimalsX)));
  }
  function sqrt(uint256 x, uint8 decimalsX, uint8 decimalsOut) internal pure returns (uint256 result) {
    assert (decimalsX <= decimalsDefault);
    assert (decimalsOut <= decimalsDefault);
    return sqrt(x * (10 ** uint256(decimalsDefault - decimalsX))) / (10 ** uint256(decimalsDefault - decimalsOut));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// snippet-start: Token name
contract FNDRToken is ERC20, ERC20Capped, Ownable {
    // snippet-end: Token name

    // start-snippet: repartition addresses [definition]
    bool internal initialized;
    address public dao_reserve_addr;
    address public dynamic_ico_addr;
    address public community_pool_ambassadors_addr;
    address public community_pool_contributors_addr;
    address public team_addr;
    // end-snippet: repartition addresses [definition]

    uint256 public totalTokenBurnt;

    constructor() ERC20("FNDRToken", "FNDR") ERC20Capped(2 * 10 ** (9 + 18)) {
        // No constructor, because repartition addresses can cause mutual dependencies
    }

    // start-snippet: Initialize [repartition addresses > 0]
    function initialize(
        // start-snippet: repartition addresses [constructor args]
        address _dao_reserve,
        address _dynamic_ico,
        address _community_pool_ambassadors,
        address _community_pool_contributors,
        address _team // end-snippet: repartition addresses [constructor args]
    ) public {
        require(!initialized, "FiatToken: contract is already initialized");
        initialized = true;

        // start-snippet: mintable = false
        uint256 totalMinted = 2 * 10 ** (9 + 18);
        // end-snippet: mintable = false

        // start-snippet: repartition addresses [constructor init]
        dao_reserve_addr = _dao_reserve;
        dynamic_ico_addr = _dynamic_ico;
        community_pool_ambassadors_addr = _community_pool_ambassadors;
        community_pool_contributors_addr = _community_pool_contributors;
        team_addr = _team;
        // end-snippet: repartition addresses [constructor init]

        // start-snippet: repartition addresses [minting distribution]
        _mint(dao_reserve_addr, ((totalMinted * 20) / 100));
        _mint(dynamic_ico_addr, ((totalMinted * 50) / 100));
        _mint(community_pool_ambassadors_addr, ((totalMinted * 5) / 100));
        _mint(community_pool_contributors_addr, ((totalMinted * 5) / 100));
        _mint(team_addr, ((totalMinted * 20) / 100));
        // end-snippet: repartition addresses [minting distribution]
    }

    // end-snippet: Initialize [repartition addresses > 0]

    function _mint(
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Capped) {
        super._mint(to, amount);
    }

    /*
     * @dev Destroy tokens. Used when certifying water.
     * @param amount The amount to burn.
     */
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
        totalTokenBurnt += amount;
    }
}