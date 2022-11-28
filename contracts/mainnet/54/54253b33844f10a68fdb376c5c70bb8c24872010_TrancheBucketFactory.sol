// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "./interfaces/ITrancheBucketFactory.sol";
import "./interfaces/IChamberOfCommerce.sol";
import "./interfaces/ITrancheBucket.sol";
import "./interfaces/ITellerKeeper.sol";
// import "./TrancheBucket.sol";

import { ITrancheBucketFactoryEvents } from "./interfaces/IEvents.sol";

contract TrancheBucketFactory is ITrancheBucketFactory, ITrancheBucketFactoryEvents {
    using Strings for string;
    address public tellerKeeper;
    address public immutable chamberOfCommerce;
    // palletIndex => TrancheBucket address
    mapping(uint256 => address) public buckets;
    // palletIndex => BucketType
    mapping(uint256 => BucketType) public typeBucket;
    address public trancheBucketImplementation;
    bool private isConfigured;
    
    constructor(address _chamberOfCommerce) {
        chamberOfCommerce = _chamberOfCommerce;

    }

    modifier onlyKeeper() {
        require(
            msg.sender == tellerKeeper,
            "TrancheBucketFactory:Caller not tellerKeeper"
        );
        _;
    }

    modifier onlyDAOController() {
        require(
            IChamberOfCommerce(chamberOfCommerce).isDAOController(msg.sender),
            "TrancheBucketFactory:Caller not DAO Controller"
        );
        _;
    }

    function configureContract(
        address _tellerKeeper
    ) external onlyDAOController {
        require(
            !isConfigured,
            "TrancheBucketFactory:Contract already configured!"
        );
        tellerKeeper = _tellerKeeper;
        isConfigured = true;
        emit ContractConfigured(_tellerKeeper);
    }

    function setNewTrancheBucketFactoryImplementation(
        address _newImplementation
    ) external onlyDAOController {
        trancheBucketImplementation = _newImplementation;
        // emit event
    }

    /**
     * Deploys a TrancheBucket contract for the particular pallet
     * @dev at this point only one TB per palletIndex is allowed, in the future we could add the ability for multiple TBs to be deployed by different entities per pallet
     */
    function deployTrancheBucket(
        uint256 _palletIndex,
        uint32 _integratorIndex,
        bool _stakedYield,
        bool _bondBacked
    ) external returns(address trancheBucket_) {
        // Check if the caller is whitelisted in COC
        require(
            IChamberOfCommerce(chamberOfCommerce).isAccountWhitelisted(msg.sender),
            "TrancheBucketFactory:Caller not whitelisted" 
        );
        // Check if the pallet already has a bucket deployed (not allowed)
        require(
            buckets[_palletIndex] == address(0x0),
            "TrancheBucketFactory:Pallet already has a bucket"
        );
        if (_bondBacked) {
            // EXTERNAL CALL TO TELLER: Check if the loan/bid is in PENDING state
            require(
                ITellerKeeper(tellerKeeper).isBucketDeploymentAllowed(_palletIndex),
                "TrancheBucketFactory:BucketDeployment not allowed"
            );
        }
        trancheBucket_ = Clones.clone(trancheBucketImplementation);
        // initialize the state variables of the bucket
        _initializeBucket(trancheBucket_, _integratorIndex, _palletIndex, _stakedYield, _bondBacked);
        BucketType type_ = BucketType.BACKED;
        if (!_bondBacked) type_ = BucketType.UN_BACKED;
        buckets[_palletIndex] = trancheBucket_;
        typeBucket[_palletIndex] = type_;
        emit TrancheLockerCreated(
            _palletIndex,
            type_, 
            trancheBucket_
        );
    }

    function _initializeBucket(
        address _cloneAddress,
        uint32 _integratorIndex,
        uint256 _palletIndex,
        bool _stakedYield,
        bool _bondBacked
    ) internal {
        // trancheShares name and symbol are standardized
        (string memory name_,string memory symbol_) = _returnTokenDetails(_palletIndex);
        uint256 bidId_;
        if (_bondBacked) {
            bidId_ = IChamberOfCommerce(chamberOfCommerce).palletIndexToBid(_palletIndex);
        } else {
            bidId_ = 0;
        }
        ITrancheBucket(_cloneAddress).initializeBucket(
                                            name_,
                                            symbol_,
                                            _integratorIndex,
                                            [_palletIndex, bidId_],
                                            [msg.sender, chamberOfCommerce, tellerKeeper, IChamberOfCommerce(chamberOfCommerce).fuelToken(), IChamberOfCommerce(chamberOfCommerce).depositToken(), IChamberOfCommerce(chamberOfCommerce).returnPalletEvent(_palletIndex)],
                                            _stakedYield,
                                            _bondBacked
                                        );
    }

    /**
     * @param _palletIndex the palletIndex of the collateral/event/inventory
     * @dev function can only be called by the TellerKeeper 
     */
    function tellerToAccepted(
        uint256 _palletIndex
    ) external onlyKeeper {
        (uint256 supply_, BackingVerification verification_) = _returnBucketInfo(_palletIndex);
        if ((verification_ == BackingVerification.VERIFIED) && (supply_ > 0)) {
            _setBucketToState(_palletIndex, BucketConfiguration.BUCKET_ACTIVE, false);
        }
        // if either there are not shareTokens or if the bucket wasn't VERIFIED then the bucket is invalid
        else {
            _setBucketToState(_palletIndex, BucketConfiguration.INVALID_CANCELLED_VOID, true);
        }
    }

    /**
     * This function needs to account for the fact that it is not assured that 
     * if the bucket was never verified, regardless of the loan being repaid the right state is INVALID_CANCELLED_VOID, since the bucket was never properly configured/verified.
     * additionally if there are no trancheShares, it was never configured properly, and also INVALID_CANCELLED_VOID
     */
    /**
     * @param _palletIndex the palletIndex of the collateral/event/inventory
     * @dev function can only be called by the TellerKeeper 
     */
    function tellerToPaid(
        uint256 _palletIndex
    ) external onlyKeeper {
        (uint256 supply_, BackingVerification verification_) = _returnBucketInfo(_palletIndex);
        if (_returnBucketConfig(_palletIndex) == BucketConfiguration.BUCKET_ACTIVE) {
            emit BucketAlreadyActive();
            return;
        }
        else if ((verification_ == BackingVerification.VERIFIED) && (supply_ > 0)) {
            _setBucketToState(_palletIndex, BucketConfiguration.BUCKET_ACTIVE, false);
        }
        // this function is here to catch any weird configurations that can occur for any reason.
        else {
            _setBucketToState(_palletIndex, BucketConfiguration.INVALID_CANCELLED_VOID, true);
        }
    }

    function doesBucketExist(uint256 _palletIndex) external view returns(bool exists_) {
        exists_ = buckets[_palletIndex] != address(0x0);
    }

    function doesExistAndIsBacked(uint256 _palletIndex) external view returns(bool backed_) {
        backed_ = (buckets[_palletIndex] != address(0x0)) && (typeBucket[_palletIndex] == BucketType.BACKED);
    }

    /**
     * @param _palletIndex the palletIndex of the collateral/event/inventory
     * @dev function can only be called by the TellerKeeper 
     */
    function tellerToCancelled(
        uint256 _palletIndex
    ) external onlyKeeper {
        _setBucketToState(_palletIndex, BucketConfiguration.INVALID_CANCELLED_VOID, true);
    }

    function deleteTrancheBucket(
        uint256 _palletIndex
    ) external onlyDAOController {
        _doesBucketExistCheck(_palletIndex);
        _setBucketToState(_palletIndex, BucketConfiguration.INVALID_CANCELLED_VOID, true);
        emit TrancheBucketDeleted(
            _palletIndex,
            buckets[_palletIndex]
        );
        delete buckets[_palletIndex];
    }

    function processBucketInvalidaton(
        uint256 _palletIndex
    ) external {
        require(
            buckets[_palletIndex] == msg.sender,
            "TrancheBucketFactory:Caller must be bucket"
        );
        delete buckets[_palletIndex];
        // TODO do we need to delete typeBucket[_palletIndex]
        // TODO emit event?
    }

    function setTrancheState(
        uint256 _palletIndex,
        BucketConfiguration _state,
        bool _toPause
    ) external onlyDAOController {
        _doesBucketExistCheck(_palletIndex);
        _setBucketToState(_palletIndex, _state, _toPause);
        emit SetTrancheBucketStateManual(
            _palletIndex,
            buckets[_palletIndex]
        );
    }

    /**
     * If a TellerLoan/Bid is LIQUIDATED this means that the base loan/bond wasn't repaid. The base part of the bond has seniority over the performance component. Hence that the TS are paused (made unmovable)
     * 
     * Note: I am not sure if I am super heavly conviced in that in case of the base-loan not being repaid that the trancheShares are always rekt. Especially if other entities than the TC are granting them! However for the initial configuration I feel it is simpler to use the senior/junior 'debt' model. We can re-access this configuration when we have actual diversity in the type of backers. 
     */
    function tellerToLiquidated(
        uint256 _palletIndex
    ) external onlyKeeper {
        _setBucketToState(_palletIndex, BucketConfiguration.INVALID_CANCELLED_VOID, true);
    }

    function _returnTokenDetails(
        uint256 _palletIndex
    ) internal pure returns(string memory name_, string memory symbol_) {
        name_ = string.concat(
            "Performance Inventory trancheShare - offering: ", 
            Strings.toString(_palletIndex)
        );
        symbol_ = "trancheShare";
    }

    function _returnBucketInfo(uint256 _palletIndex) internal view returns(uint256 supply_, BackingVerification verification_) {
        ITrancheBucket bucket_ = ITrancheBucket(buckets[_palletIndex]);
        supply_ = bucket_.totalSupply();
        verification_ = bucket_.returnBackingStruct().verification;
        return(supply_, verification_);
    }

    function _setBucketToState(uint256 _palletIndex, BucketConfiguration _state, bool _toPause) internal {
        ITrancheBucket bucket_ = ITrancheBucket(buckets[_palletIndex]);
        bucket_.setBucketState(_state, _toPause);
        emit RelayChangeToBucket(
            _palletIndex,
            _state
        );
    }

    function _returnBucketConfig(uint256 _palletIndex) internal view returns(BucketConfiguration config_) {
        ITrancheBucket bucket_ = ITrancheBucket(buckets[_palletIndex]);
        config_ = bucket_.bucketState();
    }

    function _doesBucketExistCheck(uint256 _palletIndex) internal view {
        require(
            buckets[_palletIndex] != address(0x0),
            "TrancheBucketFactory:Bucket does not exist"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ITellerV2DataTypes, IEconomicsDataTypes } from "./IDataTypes.sol";

interface IChamberOfCommerce is ITellerV2DataTypes, IEconomicsDataTypes {
    function bondCouncil() external view returns(address);
    function fuelToken() external returns(address);
    function depositToken() external returns(address);
    function tellerContract() external returns(address);
    function clearingHouse() external returns(address);
    function ticketSaleOracle() external returns(address);
    function economics() external returns(address);
    function palletRegistry() external returns(address);
    function palletMinter() external returns(address);
    function tellerKeeper() external returns(address);
    function returnPalletLocker(address _safeAddress) external view returns(address _palletLocker);
    function isChamberPaused() external view returns (bool);

    function returnIntegratorData(
        uint32 _integratorIndex
    )  external view returns(IntegratorData memory data_);

    function isAddressBorrower(
        address _addressSafeBorrower
    ) external view returns(bool);

    function isAccountWhitelisted(
        address _addressAccount
    ) external view returns(bool);

    function isAccountBlacklisted(
        address _addressAccount
    ) external view returns(bool);

    function returnPalletEvent(
        uint256 _palletIndex
    ) external view returns(address eventAddress_);

    function viewIntegratorUSDBalance(
        uint32 _integratorIndex
    ) external view returns (uint256 balance_);

    function emergencyMultisig() external view returns(address);

    function returnIntegratorIndexByRelayer(
        address _relayerAddress
    ) external view returns(uint32 integratorIndex_);

    function isDAOController(
        address _challenedController
    ) external view returns(bool);

    function isFuelAndCollateralSufficient(
        address _palletIssuerAddress, 
        uint64 _maxAmountInventory, 
        uint64 _averagePriceInventory,
        uint256 _amountPallet) external view returns(bool judgement_);


    function getIntegratorFuelPrice(
        uint32 _integratorIndex
    ) external view returns(uint256 _price);

    function palletIndexToBid(
        uint256 _palletIndex
    ) external view returns(uint256 _bidId);

    // EXTERNALCALL TO ORACLE
    function nftsIssuedForEvent(
        address _eventAddress
    ) external view returns(uint32 _ticketCount);

    // EXTERNALCALL TO ORACLE
    function isCountFinalized(
        address _eventAddress
    ) external view returns(bool _isFinalized);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IChamberOfCommerceDataTypes {

    // ChamberOfCommerce
    enum AccountType {
        NOT_SET,
        BORROWER,
        LENDER
    }

    enum AccountStatus {
        NONE,
        REGISTERED,
        WHITELISTED,
        BLACKLIST
    }

    struct ActorAccount {
        // uint256 actorIndex;
        uint32 integratorIndex;
        AccountStatus status;
        AccountType accountType;
        address palletLocker;
        // address stakeLocker;
        address relayerAddress;
        string nickName;
        string uriGeneral;
        string uriTerms;
    }

    struct CreditScore {
        uint256 minimumDeposit;
        uint24 fuelRequirement; // 100% = 1_000_000 = 1e6
    }
}

interface IEventImplementationDataTypes {

    enum TicketFlags {
        SCANNED, // 0
        CHECKED_IN, // 1
        INVALIDATED, // 2
        CLAIMED // 3
    }

    struct BalanceUpdates {
        address owner;
        uint64 quantity;
    }

    struct TokenData {
        address owner;
        uint40 basePrice;
        uint8 booleanFlags;
    }

    struct AddressData {
        // uint64 more than enough
        uint64 balance;
    }

    struct EventData {
        uint32 index;
        uint64 startTime;
        uint64 endTime;
        int32 latitude;
        int32 longitude;
        string currency;
        string name;
        string shopUrl;
        string imageUrl;
    }

    struct TicketAction {
        uint256 tokenId;
        bytes32 externalId; // sha256 hashed, emitted in event only.
        address to;
        uint64 orderTime;
        uint40 basePrice;
    }

    struct EventFinancing {
        uint64 palletIndex;
        address bondCouncil;
        bool inventoryRegistered;
        bool financingActive;
        bool primaryBlocked;
        bool secondaryBlocked;
        bool scanBlocked;
        bool claimBlocked;
    }
}


interface IBondCouncilDataTypes is IEventImplementationDataTypes {
    /**
     * @notice What happens to the collateral after a certain 'bond state' is a Policy. The Policy struct defines the consequence on the actions of the collateral
     * @param isPolicy bool that tracks 'if a policy exists'. Should always be set to True if a Policy is set
     * @param primaryBlocked if the NFTs can be sold on the primary market if the Policy is active. True means that the NFTs cannot be sold on the primary market.
     * Same principle of True/False relation to possible ticket-actions is the case for the other bools in this struct.
     */
    struct Policy {
        bool isPolicy;
        bool primaryBlocked;
        bool secondaryBlocked;
        bool scanBlocked;
        bool claimBlocked;
    }

    /**
     * @param verified bool indicating if the TB is verified by the DAO
     * @param eventAddress address of the Event (EventImplementation proxy) 
     * @param policyDuringLoan integer of the Policy that will be executed after the offering is ACCEPTED (so during the duration of the loan/bond)
     * @param policyAfterLiquidation integer of the Policy that will be executed if the offering is LIQUIDATED (so this is the consequence of not repaying the loan/bond)
     * @param flushstruct this is a copy of the EventFinancing struct in EventImplementation. 
     * @dev when a configuration is 'flushed' this means that the flushstruct is pushed to the EventImplementation contract. 
     */
    struct InventoryProcedure {
        bool verified;
        address eventAddress;
        uint256 policyDuringLoan;
        uint256 policyAfterLiquidation;
        EventFinancing flushstruct;
    }

    /**
     * XXXX ADD DESCRIPTION
     * @param INACTIVE XXX
     * @param DURING XXX
     * @param LIQUIDATED XXX
     * @param REPAID XXX
     */
    enum CollateralizationStage {
        INACTIVE,
        DURING,
        LIQUIDATED,
        REPAID
    }
}

interface IClearingHouseDataTypes {

    /**
     * Struct encoding the status of the collateral/loan/bid offering.
     * @param NONE offering isn't registered at all (doesn't exist)
     * @param READY the pallet is ready to be used as collateral
     * @param ACTIVE the pallet is being used as collateral
     * @param COMPLETED the pallet is returned to the bond issuer (the offering is completed, loan has been repaid)
     * @param DEFAULTED the pallet is sent to the lender because the loan/bond wasn't repaid. The offering isn't active anymore
     */
    enum OfferingStatus {
        NONE,
        READY,
        ACTIVE,
        COMPLETED,
        DEFAULTED
    }
}

interface IEconomicsDataTypes {
    struct IntegratorData {
        uint32 index;
        uint32 activeTicketCount;
        bool isBillingEnabled;
        bool isConfigured;
        uint256 price;
        uint256 availableFuel;
        uint256 reservedFuel;
        uint256 reservedFuelProtocol;
        string name;
    }

    struct RelayerData {
        uint32 integratorIndex;
    }

    struct DynamicRates {
        uint24 minFeePrimary;
        uint24 maxFeePrimary;
        uint24 primaryRate;
        uint24 minFeeSecondary;
        uint24 maxFeeSecondary;
        uint24 secondaryRate;
        uint24 salesTaxRate;
    }
}

interface PalletRegistryDataTypes {

    enum PalletState {
        NON_EXISTANT,
        UN_REGISTERED, // 'pallet is unregistered to an event'
        REGISTERED, // 'pallet is registered to an event'
        VERIFIED, // pallet is now sealed
        DISCARDED // end state
    }

    struct PalletStruct {
        address depositTokenAddress;
        uint64 maxAmountInventory;
        uint64 averagePriceInventory;
        bool fuelAndCollateralCheck;
        address safeAddressIssuer;
        address palletLocker;
        uint256 depositedDepositTokens;
        PalletState palletState;
        address eventAddress;
    }
}

interface ITellerV2DataTypes {
    enum BidState {
        NONEXISTENT,
        PENDING,
        CANCELLED,
        ACCEPTED,
        PAID,
        LIQUIDATED
    }
    
    struct Payment {
        uint256 principal;
        uint256 interest;
    }

    struct Terms {
        uint256 paymentCycleAmount;
        uint32 paymentCycle;
        uint16 APR;
    }
    
    struct LoanDetails {
        ERC20 lendingToken;
        uint256 principal;
        Payment totalRepaid;
        uint32 timestamp;
        uint32 acceptedTimestamp;
        uint32 lastRepaidTimestamp;
        uint32 loanDuration;
    }

    struct Bid {
        address borrower;
        address receiver;
        address lender;
        uint256 marketplaceId; // TODO should this be uncommented really?
        bytes32 _metadataURI; // DEPRECIATED
        LoanDetails loanDetails;
        Terms terms;
        BidState state;
    }
}

interface ITrancheBucketFactoryDataTypes {

    enum BucketType {
        NONE,
        BACKED,
        UN_BACKED
    }

}

interface ITrancheBucketDataTypes is IEconomicsDataTypes {

    /**
     * @param NONE config doesn't exist
     * @param CONFIGURABLE BUCKET IS CONFIGURABLE. it is possible to change the inv range and the kickback per NFT sold (so the bucket is still configuratable)
     * @param BUCKET_ACTIVE BUCKET IS ACTIVE. the bucket is active / in use (the loan/bond has been issued). The bucket CANNOT be configured anymore
     * @param AT_CHECKOUT BUCKET DEBT IS BEING CALCULATED AND PAID. The bond/loan has been repaid / the ticket sale is completed. In a sense the bucket backer is at the checkout of the process (the total bill is made up, and the payment request/process is being run). Look of it as it as the contract being at the checkout at the supermarket, items bought are scanned, creditbard(Economics contract) is charged.
     * @param REDEEMABLE the proceeds/kickback collected in the bucket can now be claimed from the bucket contract. 
     * @param INVALID_CANCELLED_VOID the bucket is invalid. this can have several reasons. The different reasons are listed below.
     * 
     * We have collapsed all these different reasons in a single state because the purpose of this struct is to tell the market what the shares are worth anything. If the bucket is in this state, the value of the shares are 0 (and they are unmovable).
     */


    // stored in: bucketState
    enum BucketConfiguration {
        NONE,
        CONFIGURABLE,
        BUCKET_ACTIVE,
        AT_CHECKOUT,
        REDEEMABLE,
        INVALID_CANCELLED_VOID
    }

    // stored in backing.verification
    enum BackingVerification {
        NONE,
        INVALIDATED,
        VERIFIED
    }

    // stored in tranche
    struct InventoryTranche {
        uint32 startIndexTranche;
        uint32 stopIndexTranche;
        uint32 averagePriceNFT;
        uint32 totalNFTInventory;
        uint32 usdKickbackPerNft; // 10000 = 1e4 = $1,00 = 1 dollar 
    }

    struct BackingStruct {
        bool relayerAttestation;
        BackingVerification verification;
        IntegratorData integratorData;
        uint32 integratorIndex;
        uint256 timestampBacking; // the moment the bucket was deployed and the backing was configured 
    }

    // struct OfferingBidInfo{
    //     address eventAddress;
    //     uint256 bidId;
    // }

    // struct RepaymentStruct {
    //     uint32 scalingFactor;
    //     uint32 bucketDebt;
    //     uint256 amountReceived;
    //     uint256 totalYieldCollected;
    //     uint256 supplyAtFinalization;
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IClearingHouseDataTypes, ITrancheBucketDataTypes, IBondCouncilDataTypes, ITellerV2DataTypes, ITrancheBucketFactoryDataTypes } from "./IDataTypes.sol";

interface IChamberOfCommerceEvents {


    event DefaultDepositSet(
        uint256 newDefaultDeposit
    );

    event CreditScoreEdit(
        address safeAddress,
        uint256 minimumDeposit,
        uint24 fuelRequirement
    );

    event EconomicsContractChange(
        address economicsContract
    );

    event DepositTokenChange(address newDepositToken);

    event AccountDeleted(
        address accountAddress
    );

    event RegisterySet(
        address palletRegistry
    );

    event ControllerSet(
        address addressController,
        bool setting
    );

    event ChamberPaused();

    event ChamberUnPaused();

    event AccountRegistered(
        address safeAddress,
        // uint256 actorIndex,
        string nickName
    );

    event AccountApproved(
        address safeAddress
    );

    event AccountWhitelisted(
        address safeAddress
    );

    event AccountBlacklisted(
        address safeAddress
    );

    event ContractsConfigured(
        address palletLockerFactory,
        address bondCouncil,
        address ticketSalesOracle,
        address economics,
        address palletRegistry,
        address clearingHouse,
        address tellerKeeper
    );

    event PalletLockerDeployed(
        address safeAddress,
        address palletLockerAddress
    );

    event StakeLockerDeployed(
        address safeAddress,
        address safeLockerAddress
    );
}

interface IClearingHouseEvents is IClearingHouseDataTypes {

    event BucketUpdate();

    event ManualCancel(uint256 palletIndex);

    event OfferingAccepted(
        uint256 palletIndex
    );

    event ContractConfigured(
        address palletRegistry,
        address tellerKeeper,
        address bondCouncil
    );

    event OfferingRegistered(
        uint256 palletIndex,
        uint256 bidId
    );

    event OfferingCancelled(
        uint256 palletIndex
    );

    event OfferingLiquidated(
        uint256 palletIndex,
        address lenderAddress
    );

    event PalletReclaimed(
        uint256 palletIndex
    );

    event OfferingStatusChange(
        uint256 palletIndex,
        OfferingStatus _status
    );

}

interface IPalletRegistryEvents {

    event EmergencyWithdraw(
        address tokenAddress,
        address controllerDAO,
        uint256 amountWithdrawn
    );
    
    event BalanceCheck(
        uint256 palletIndex,
        bool rulingBalance
    );

    event DepositTokenChange(address newDepositToken);

    event PalletUnwindLiquidation(
        uint256 palletIndex,
        address liquidatorAddress
    );

    event PalletUnwindIssuer(
        uint256 palletIndex,
        uint256 depositAmount
    );

    event UnwindIssuer(
        uint256 palletIndex
    );

    event UnwindPallet(
        uint256 palletIndex,
        uint256 amountUnwound,
        address recipientDeposit,
        address lockerAddress
    );

    event PalletMinted(
        uint256 palletIndex,
        address safeAddress,
        uint256 tokensDeposited
    );

    event RegisterEventToPallet (
        uint256 palletIndex,
        address eventAddress
    );

    event DepositTokensAdded(
        uint256 palletIndex,
        uint256 extraDepositTokens
    );

    event PalletBurnedManual(
        uint256 palletIndex
    );

    event WithdrawPalletLocker(
        address depositTokenAddress,
        address toAddress,
        uint256 stakeDepositAmount
    );

    event PalletJudged(
        uint256 palletIndex,
        bool ruling
    );

    event PalletDepositClaimed(
        address claimAddress,
        uint256 palletIndex,
        uint256 depositedStateTokens
    );
}

interface ITrancheBucketEvents is ITrancheBucketDataTypes {

    event PaymentApproved();

    event ManualWithdraw(
        address withdrawTokenAddress,
        uint256 amountWithdrawn
    );

    event FunctionNotFullyExecuted();

    event BucketUpdate();

    event ManualCancel();

    event ClaimNotAllowed();

    event ModificationNotAllowed();

    event TrancheFinalized();

    event TrancheFullyRegistered(
        uint32 startIndex,
        uint32 stopIndex,
        uint32 averagePrice,
        uint32 totalInventory
    );

    event AllStaked(
        uint256 stakedAmount,
        uint256 sharesAmount
    );

    event BucketConfigured(
        uint32 integratorIndex
    );

    event RelayerAttestation(
        address attestationAddress
    );

    event BackingVerified(
        bool ruling
    );

    event TrancheShareMint(
        uint256 totalSupply
    );

    event BurnAll();

    event StateChange(
        BucketConfiguration _status
    );

    event InvalidState(
        BucketConfiguration currentState,
        BucketConfiguration requiredState
    );

    event DAOCancel();

    event StateAlreadyInSync();

    event SharesClaimed(
        address claimerAddress,
        uint256 amountClaimed
    );
    
    event UpdateDebt(
        uint256 currentDebt,
        uint256 timestamp
    );

    event BucketCheckedOut(
        uint256 finalDebt
    );

    event ReceivablesUpdated(
        uint256 balanceOf
    );

    event RedemptionUnlocked(
        uint256 balance,
        uint256 atPrice,
        uint256 totalReward
    );

    event Claim(
        uint256 shares,
        uint256 yield
    );

    event ClaimAmount();
}

interface ITellerKeeperEvents is ITellerV2DataTypes {

    event EmergencyWithdraw(
        address tokenAddress,
        address controllerDAO,
        uint256 amountWithdrawn
    );

    error NoOfferingToUpdate(
        uint256 palletIndex,
        string message
    );

    event KeeperUpToDate();

    event NotEnoughFuel();

    event OfferingManualCancel(
        uint256 palletIndex
    );

    event OfferingRegistered(
        uint256 palletIndex
    );

    event TellerLiquidation(
        uint256 palletIndex
    );

    event ContractConfigured(
        address trancheBucketFactory,
        address clearingHouse
    );

    event KeeperReward(
        address rewardRecipient,
        uint256 amountRewarded
    );

    event TellerPaid(
        uint256 palletIndex
    );

    event RewardUpdated(
        uint256 newUpdateReward
    );

    event TellerCancelled(
        uint256 palletIndex
    );

    event TellerAccepted(
        uint256 palletIndex
    );

    event StateUpdateKeeper(
        uint256 bidId,
        uint256 palletIndex,
        BidState currentState
    );
}

interface ITrancheBucketFactoryEvents is ITrancheBucketDataTypes, ITrancheBucketFactoryDataTypes {

    event BucketAlreadyActive();

    event TrancheBucketDeleted(
        uint256 palletIndex,
        address deletedBucket
    );

   event SetTrancheBucketStateManual(
        uint256 palletIndex,
        address bucketAddress
    );

    event TrancheLockerCreated(
        uint256 palletIndex,
        BucketType bucketType,
        address trancheAddress
    );

    event ContractConfigured(
        address clearingHouse
    );

    event RelayChangeToBucket(
        uint256 palletIndex,
        BucketConfiguration newState
    );
}

interface IBondCouncilEvents is IBondCouncilDataTypes {

    event FlushSwitchOff();

    event FlushSwitch(
        bool flushSwitch
    );

    event ImpossibleState();

    event CancelProcedure(
        uint256 palletIndex
    );

    event ManualFS (
        uint256 palletIndex,
        uint256 policyIndex
    );

    event EditProcedure(
        uint256 palletIndex
    );

    event VerifyProcedure(
        uint256 palletIndex
    );

    event PalletCancellation(
        uint256 palletIndex
    );

    event PalletCollateralization(
        uint256 palletIndex
    );

    event PolicyAdded(
        uint256 policyIndex,
        Policy newpolicy
    );

    event ManualFlush(
        uint256 palletIndex
    );

    event PalletRegistered(
        uint256 palletIndex
    );

    event Flush(
        uint256 palletIndex
    );

    event ContractsConfigured(
        address clearingHouse,
        address palletRegistry
    );

    event ChamberSet(
        address chamberOfCommerce
    );

    event Liquidation(
        uint256 palletIndex
    );

    event Repayment(
        uint256 palletIndex
    );
}

interface IStakeLockerFactoryEvents {

    event StakeLockerDeployed(
        address safeAddress
    );

    event TokensAdded(
        address stakeLocker,
        uint256 tokensAdded
    );

    event BalanceUpdated(
        address stakeLocker,
        uint256 newBalance
    );
    
    event UnstakeRequest(
        address safeAddress,
        address lockerAddress,
        uint256 requestAmount
    );

    event UnstakeRequestExecuted(
        address lockerAddress,
        uint256 requestAmount
    );

    event UnstakeRequestRejected(
        address lockerAddress,
        uint256 rejectedAmount
    );

    event EmergencyWithdrawAll(
        address lockerAddress,
        uint256 withdrawAmount
    );

    event LockerSlashed(
        address lockerAddress,
        uint256 slashAmount
    );
}


interface IStakeLockerEvents {

}

interface ITicketSaleOracleEvents {

    event EventCountUpdate(
        address eventAddress,
        uint32 nftsSold
    );

    event EventFinalized(
        address eventAddress
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ITellerV2DataTypes } from "./IDataTypes.sol";

interface ITellerKeeper is ITellerV2DataTypes {

    function setUpdateReward(
        uint256 _newUpdateReward
    ) external;

    function fuelForUpdates() external view returns(uint16 updates_);

    function updateByPalletIndex(
        uint256 _palletIndex,
        bool _isEFMContract
    ) external returns(bool update_);

    function bidStateTeller(uint256 _palletIndex) external view returns(BidState state_);

    function registerOffering(uint256 _palletIndex) external;

    function cancelOffering(uint256 _palletIndex) external;

    function isKeeperUpdateNeeded(
        uint256 _palletIndex
    ) external view returns(bool update_);

    function isBucketDeploymentAllowed(
        uint256 _palletIndex
    ) external view returns(bool allowed_);

    function getLoanLender(
        uint256 _bidIdTeller
    ) external view returns (address lender_);

    function getLoanBorrower(
        uint256 _bidIdTeller
    ) external view returns (address borrower_);

    function getStateBidId(
        uint256 _bidIdTeller
    ) external view returns (BidState state_);

    function canRegisterOffering(
        uint256 _bidIdTeller
    ) external view returns(bool canRegister_);

    function canCancelOffering(
        uint256 _palletIndex
    ) external view returns(bool allowed_);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ITrancheBucketDataTypes } from "./IDataTypes.sol";
// import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ITrancheBucket is IERC20Upgradeable, ITrancheBucketDataTypes {
    // function setBackingStruct(
    //     uint32 _integratorIndex
    // ) external;
    function initializeBucket(
        string memory _name,
        string memory _symbol,
        uint32 _integratorIndex,
        uint256[2] memory _indexes,
        address[6] memory _addresses,
        bool _stakedYield,
        bool _bondBacked
    ) external;
    function setBucketState(BucketConfiguration _stateToSet, bool _toPause) external;
    function bucketState() external view returns(BucketConfiguration);
    function attestRelayer() external;
    function verifyBackingConfiguration(bool _verify) external;
    function registerPerformanceRangeTranche(
        uint32 _startIndexTranche,
        uint32 _stopIndexTranche,
        uint32 _averagePriceNFT,
        uint32 _totalNFTInventory
    ) external;
    function returnBackingStruct() external view returns(BackingStruct memory backing);
    function totalTicketsInTranche() external view returns(uint32 _range);
    function totalValue() external view returns(uint32 _value);
    function maxReturn(uint32 _usdPerInRange) external view returns(uint256 _max);
    function setKickbackPerNFTinTranche(uint32 _usdPerInRange) external;
    function claimTrancheShares() external;
    function updateDebt() external returns(uint256 debt_);
    function currentReturnPerShare() external view returns(uint256 _return);
    function checkOutBucket() external;
    function registerReceivables() external returns(uint256 balance_);
    function unlockRedemption(bool _checkBalance) external returns(uint256 balance_);
    function claimYieldAll() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITrancheBucketFactory {
    function tellerKeeper() external view returns(address keeper_);
    function tellerToAccepted(
        uint256 _palletIndex
    ) external;

    function tellerToCancelled(
        uint256 _palletIndex
    ) external;

    function tellerToLiquidated(
        uint256 _palletIndex
    ) external;

    function tellerToPaid(
        uint256 _palletIndex
    ) external;

    function buckets(uint256 _palletIndex) external view returns(address bucket_);

    function doesBucketExist(uint256 _palletIndex) external returns(bool exists_);

    function doesExistAndIsBacked(uint256 _palletIndex) external view returns(bool backed_);

    function processBucketInvalidaton(
        uint256 _palletIndex
    ) external;
}