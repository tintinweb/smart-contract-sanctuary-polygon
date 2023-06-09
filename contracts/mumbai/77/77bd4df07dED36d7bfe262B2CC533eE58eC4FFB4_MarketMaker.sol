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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */

// https://github.com/DAObox/liquid-protocol/blob/main/src/core/MarketMaker.sol
pragma solidity >=0.8.17;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { PluginStandalone } from "../standalone/PluginStandalone.sol";

import { IBondingCurve } from "../interfaces/IBondingCurve.sol";
import { IBondedToken } from "../interfaces/IBondedToken.sol";

import { Errors } from "../lib/Errors.sol";
import { Events } from "../lib/Events.sol";
import { Modifiers } from "../modifiers/MarketMaker.sol";
import { CurveParameters } from "../lib/Types.sol";

/**
 * @title DAO Market Maker with Adjustable Bonding Curve
 * @author DAOBox | (@pythonpete32)
 * @dev This contract is an non-upgradeable Aragon OSx Plugin
 *      It enables continuous minting and burning of tokens on an Augmented Bonding Curve, with part of the funds going
 * to the DAO and the rest being added to a reserve.
 *      The adjustable bonding curve formula is provided at initialization and determines the reward for minting and the
 * refund for burning.
 *      The DAO can also receive a sponsored mint, where another address pays to boost the reserve and the owner obtains
 * the minted tokens.
 *      Users can also perform a sponsored burn, where they burn their own tokens to enhance the value of the remaining
 * tokens.
 *      The DAO can set certain governance parameters like the theta (funding rate), or friction(exit fee)
 *
 * @notice This contract uses several external contracts and libraries from OpenZeppelin. Please review and understand
 * those before using this contract.
 * Also, consider the effects of the adjustable bonding curve and continuous minting/burning on your token's economics.
 * Use this contract responsibly.
 */
contract MarketMaker is PluginStandalone, Modifiers {
    using SafeMath for uint256;

    // =============================================================== //
    // ========================== CONSTANTS ========================== //
    // =============================================================== //

    /// @dev The identifier of the permission that allows an address to conduct the hatch.
    bytes32 public constant HATCH_PERMISSION_ID = keccak256("HATCH_PERMISSION");

    /// @dev The identifier of the permission that allows an address to configure the contract.
    bytes32 public constant CONFIGURE_PERMISSION_ID = keccak256("CONFIGURE_PERMISSION");

    /// @dev 100% represented in PPM (parts per million)
    uint32 public constant DENOMINATOR_PPM = 1_000_000;

    // =============================================================== //
    // =========================== STROAGE =========================== //
    // =============================================================== //

    /// @notice The bonded token
    IBondedToken private _bondedToken;

    /// @notice The external token used to purchase the bonded token
    IERC20 private _externalToken;

    /// @notice The parameters for the _curve
    CurveParameters private _curve;

    /// @notice is the contract post hatching
    bool private _hatched;

    // =============================================================== //
    // ========================= INITIALIZE ========================== //
    // =============================================================== //

    /**
     * @dev Sets the values for {owner}, {fundingRate}, {exitFee}, {reserveRatio}, {formula}, and {reserve}.
     * Governance cannot arbitrarily mint tokens after deployment. deployer must send some ETH
     * in the constructor to initialize the reserve.
     * Emits a {Transfer} event for the minted tokens.
     *
     * @param bondedToken_ The bonded token.
     * @param externalToken_ The external token used to purchace the bonded token.
     * @param curve_ The parameters for the curve_. This includes:
     *        {fundingRate} - The percentage of funds that go to the owner. Maximum value is 10000 (i.e., 100%).
     *        {exitFee} - The percentage of funds that are taken as fee when tokens are burned. Maximum value is 5000 (i.e., 50%).
     *        {reserveRatio} - The ratio for the reserve in the BancorBondingCurve.
     *        {formula} - The implementation of the bonding curve_.
     */
    constructor(
        IBondedToken bondedToken_,
        IERC20 externalToken_,
        CurveParameters memory curve_
    ) {
        _externalToken = externalToken_;
        _bondedToken = bondedToken_;
        _curve = curve_;
    }

    function hatch(
        uint256 initialSupply,
        address hatchTo
    )
        external
        preHatch(_hatched)
        auth(HATCH_PERMISSION_ID)
    {
        _hatched = true;

        // get the balance of the marketmaker and send theta to the DAO
        uint256 amount = _externalToken.balanceOf(address(this));

        // validate there is Liquidity to hatch with
        if (amount == 0) revert Errors.InitialReserveCannotBeZero();

        uint256 theta = calculateFee(amount); // Calculate the funding amount
        _externalToken.transfer(dao(), theta);

        // mint the hatched tokens to the hatcher
        if (hatchTo != address(0)) _bondedToken.mint(hatchTo, initialSupply);
        emit Events.Hatch(hatchTo, hatchTo == address(0) ? 0 : initialSupply);

        // this event parameters are not consistent and confusing, change them
        emit Events.ContinuousMint(hatchTo, initialSupply, amount, theta);
    }

    // =============================================================== //
    // ======================== BONDING CURVE ======================== //
    // =============================================================== //

    /**
     * @dev Mints tokens continuously, adding a portion of the minted amount to the reserve.
     * Reverts if the sender is the contract owner or if no ether is sent.
     * Emits a {ContinuousMint} event.
     * @param _amount The amount of external tokens used to mint.
     * @param _minAmountReceived The amount of bonded tokens to receive at least, otherwise the transaction will be reverted.
     */
    function mint(uint256 _amount, uint256 _minAmountReceived) public isDepositZero(_amount) postHatch(_hatched) {
        if (msg.sender == dao())
            revert Errors.OwnerCanNotContinuousMint();

        // Calculate the reward amount and mint the tokens
        uint256 rewardAmount = calculateMint(_amount); // Calculate the reward amount

        _externalToken.transferFrom(msg.sender, address(this), _amount);

        // Calculate the funding portion and the reserve portion
        uint256 fundingAmount = calculateFee(_amount); // Calculate the funding amount

        // transfer the funding amount to the funding pool
        // could the DAO reenter? 🧐
        _externalToken.transfer(dao(), fundingAmount);

        if (rewardAmount < _minAmountReceived)
            revert Errors.WouldRecieveLessThanMinRecieve();
        // Mint the tokens to the sender
        // but this is being called with static call
        _bondedToken.mint(msg.sender, rewardAmount);

        // Emit the ContinuousMint event
        emit Events.ContinuousMint(msg.sender, rewardAmount, _amount, fundingAmount);
    }

    /**
     * @dev Burns tokens continuously, deducting a portion of the burned amount from the reserve.
     * Reverts if the sender is the contract owner, if no tokens are burned, if the sender's balance is insufficient,
     * or if the reserve is insufficient to cover the refund amount.
     * Emits a {ContinuousBurn} event.
     *
     * @param _amount The amount of tokens to burn.
     * @param _minAmountReceived The amount of bonded tokens to receive at least, otherwise the transaction will be reverted.
     */
    function burn(uint256 _amount, uint256 _minAmountReceived) public isDepositZero(_amount) postHatch(_hatched) {
        if (msg.sender == dao())
            revert Errors.OwnerCanNotContinuousBurn();

        // Calculate the refund amount
        uint256 refundAmount = calculateBurn(_amount);

        _bondedToken.burn(msg.sender, _amount);

        // Calculate the exit fee
        uint256 exitFeeAmount = calculateFee(refundAmount);

        // Calculate the refund amount minus the exit fee
        uint256 refundAmountLessFee = refundAmount - exitFeeAmount;

        if (refundAmountLessFee < _minAmountReceived)
            revert Errors.WouldRecieveLessThanMinRecieve();
        // transfer the refund amount minus the exit fee to the sender
        _externalToken.transfer(msg.sender, refundAmountLessFee);

        // Emit the ContinuousBurn event
        emit Events.ContinuousBurn(msg.sender, _amount, refundAmountLessFee, exitFeeAmount);
    }

    /**
     * @notice Mints tokens to the owner's address and adds the sent ether to the reserve.
     * @dev This function is referred to as "sponsored" mint because the sender of the transaction sponsors
     * the increase of the reserve but the minted tokens are sent to the owner of the contract. This can be
     * useful in scenarios where a third-party entity (e.g., a user, an investor, or another contract) wants
     * to increase the reserve and, indirectly, the value of the token, without receiving any tokens in return.
     * The function reverts if no ether is sent along with the transaction.
     * Emits a {SponsoredMint} event.
     * @return mintedTokens The amount of tokens minted to the owner's address.
     */
    function sponsoredMint(uint256 _amount)
        external
        payable
        isDepositZero(_amount)
        postHatch(_hatched)
        returns (uint256)
    {
        // Transfer the specified amount of tokens from the sender to the contract
        _externalToken.transferFrom(msg.sender, address(this), _amount);

        // Calculate the number of tokens to be minted based on the deposited amount
        uint256 mintedTokens = calculateMint(_amount);

        // Mint the calculated amount of tokens to the owner's address
        _bondedToken.mint(address(dao()), mintedTokens);

        // Emit the SponsoredMint event, which logs the details of the minting transaction
        emit Events.SponsoredMint(msg.sender, _amount, mintedTokens);

        // Return the amount of tokens minted
        return mintedTokens;
    }

    /**
     * @notice Burns a specific amount of tokens from the caller's balance.
     * @dev This function is referred to as "sponsored" burn because the caller of the function burns
     * their own tokens, effectively reducing the total supply and, indirectly, increasing the value of
     * remaining tokens. The function reverts if the caller tries to burn more tokens than their balance
     * or tries to burn zero tokens. Emits a {SponsoredBurn} event.
     * @param _amount The amount of tokens to burn.
     */
    function sponsoredBurn(uint256 _amount) external isDepositZero(_amount) postHatch(_hatched) {
        // Burn the specified amount of tokens from the caller's balance
        _bondedToken.burn(msg.sender, _amount);

        // Emit the SponsoredBurn event, which logs the details of the burn transaction
        emit Events.SponsoredBurn(msg.sender, _amount);
    }

    // =============================================================== //
    // ===================== GOVERNANCE FUNCTIONS ==================== //
    // =============================================================== //

    /**
     * @notice Set governance parameters.
     * @dev Allows the owner to modify the funding rate, exit fee, or owner address of the contract.
     * The value parameter is a bytes type and should be decoded to the appropriate type based on
     * the parameter being modified.
     * @param what The name of the governance parameter to modify
     * @param value The new value for the specified governance parameter.
     * Must be ABI-encoded before passing it to the function.
     */
    function setGovernance(bytes32 what, bytes memory value) external auth(CONFIGURE_PERMISSION_ID) {
        if (what == "theta") _curve.theta = (abi.decode(value, (uint32)));
        else if (what == "friction") _curve.friction = (abi.decode(value, (uint32)));
        else if (what == "reserveRatio") _curve.reserveRatio = (abi.decode(value, (uint32)));
        else if (what == "formula") _curve.formula = (abi.decode(value, (IBondingCurve)));
        else revert Errors.InvalidGovernanceParameter(what);
    }

    // =============================================================== //
    // ======================== VIEW FUNCTIONS ======================= //
    // =============================================================== //

    /**
     * @notice Calculates and returns the amount of tokens that can be minted with {_amount}.
     * @dev The price calculation is based on the current bonding _curve and reserve ratio.
     * @return uint The amount of tokens that can be minted with {_amount}.
     */
    function calculateMint(uint256 _amount) public view returns (uint256) {
        return _curve.formula.getContinuousMintReward({
            depositAmount: _amount,
            continuousSupply: totalSupply(),
            reserveBalance: reserveBalance(),
            reserveRatio: reserveRatio()
        });
    }

    /**
     * @notice Calculates and returns the amount of Ether that can be refunded by burning {_amount} Continuous
     * Governance Token.
     * @dev The price calculation is based on the current bonding _curve and reserve ratio.
     * @return uint The amount of Ether that can be refunded by burning {_amount} token.
     */
    function calculateBurn(uint256 _amount) public view returns (uint256) {
        return _curve.formula.getContinuousBurnRefund(_amount, totalSupply(), reserveBalance(), reserveRatio());
    }

    function calculateFee(uint256 _burnAmount) public view returns (uint256) {
        return (_burnAmount * _curve.friction) / DENOMINATOR_PPM;
    }

    /**
     * @notice Returns the current implementation of the bonding _curve used by the contract.
     * @dev This is an internal property and cannot be modified directly. Use the appropriate function to modify it.
     * @return The current implementation of the bonding _curve.
     */
    function getCurveParameters() public view returns (CurveParameters memory) {
        return _curve;
    }

    /**
     * @notice Returns the current reserve balance of the contract.
     * @dev This function is necessary to calculate the buy and sell price of the tokens. The reserve
     * balance represents the amount of ether held by the contract, and is used in the Bancor algorithm
     *  to determine the price _curve of the token.
     * @return The current reserve balance of the contract.
     */
    function reserveBalance() public view returns (uint256) {
        return _externalToken.balanceOf(address(this));
    }

    function totalSupply() public view returns (uint256) {
        return _bondedToken.totalSupply();
    }

    function externalToken() public view returns (IERC20) {
        return _externalToken;
    }

    function bondedToken() public view returns (IBondedToken) {
        return _bondedToken;
    }

    function isHatched() public view returns (bool) {
        return _hatched;
    }

    function reserveRatio() public view returns (uint32) {
        return _curve.reserveRatio;
    }
}

// SPDX-License-Identifier: MIT
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */

// https://github.com/DAObox/liquid-protocol/blob/main/src/interfaces/IBondedToken.sol
pragma solidity >=0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title IBonded Token
 * @author DAOBox | (@pythonpete32)
 * @dev
 */
interface IBondedToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */

// https://github.com/DAObox/liquid-protocol/blob/main/src/interfaces/IBondingCurve.sol
pragma solidity >=0.8.17;

/**
 * @title IBondingCurve
 * @author DAOBox | (@pythonpete32)
 * @dev This interface defines the necessary methods for implementing a bonding curve.
 *      Bonding curves are price functions used for automated market makers.
 *      This specific interface is used to calculate rewards for minting and refunds for burning continuous tokens.
 */
interface IBondingCurve {
    /**
     * @notice Calculates the amount of continuous tokens that can be minted for a given reserve token amount.
     * @dev Implements the bonding curve formula to calculate the mint reward.
     * @param depositAmount The amount of reserve tokens to be provided for minting.
     * @param continuousSupply The current supply of continuous tokens.
     * @param reserveBalance The current balance of reserve tokens in the contract.
     * @param reserveRatio The reserve ratio, represented in ppm (parts per million), ranging from 1 to 1,000,000.
     * @return The amount of continuous tokens that can be minted.
     */
    function getContinuousMintReward(
        uint256 depositAmount,
        uint256 continuousSupply,
        uint256 reserveBalance,
        uint32 reserveRatio
    )
        external
        view
        returns (uint256);

    /**
     * @notice Calculates the amount of reserve tokens that can be refunded for a given amount of continuous tokens.
     * @dev Implements the bonding curve formula to calculate the burn refund.
     * @param sellAmount The amount of continuous tokens to be burned.
     * @param continuousSupply The current supply of continuous tokens.
     * @param reserveBalance The current balance of reserve tokens in the contract.
     * @param reserveRatio The reserve ratio, represented in ppm (parts per million), ranging from 1 to 1,000,000.
     * @return The amount of reserve tokens that can be refunded.
     */
    function getContinuousBurnRefund(
        uint256 sellAmount,
        uint256 continuousSupply,
        uint256 reserveBalance,
        uint32 reserveRatio
    )
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */
pragma solidity ^0.8.0;

import { CurveParameters } from "../lib/Types.sol";

interface IMarketMaker {
    function hatch(uint256 initialSupply, address hatchTo) external;
    function getCurveParameters() external view returns (CurveParameters memory);
    function setGovernance(bytes32 what, bytes memory value) external;
}

// SPDX-License-Identifier: MIT
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */

// https://github.com/DAObox/liquid-protocol/blob/main/src/lib/Errors.sol
pragma solidity >=0.8.17;

library Errors {
    /// @notice Error thrown when the market is already open
    error TradingAlreadyOpened();

    /// @notice Error thrown when the initial reserve for the token contract is zero.
    error InitialReserveCannotBeZero();

    /// @notice Error thrown when the funding rate provided is greater than 10000 (100%).
    /// @param fundingRate The value of the funding rate provided.
    error FundingRateError(uint16 fundingRate);

    /// @notice Error thrown when the exit fee provided is greater than 5000 (50%).
    /// @param exitFee The value of the exit fee provided.
    error ExitFeeError(uint16 exitFee);

    /// @notice Error thrown when the initial supply for the token contract is zero.
    error InitialSupplyCannotBeZero();
    
    /// @notice Error thrown when the funding amount for the token contract is higher than it's balance.
    error FundingAmountHigherThanBalance();

    /// @notice Error thrown when the owner of the contract tries to mint tokens continuously.
    error OwnerCanNotContinuousMint();
    
    /// @notice Error thrown when the caller would receive less tokens then they specified to recieve at least.
    error WouldRecieveLessThanMinRecieve();

    /// @notice Error thrown when the owner of the contract tries to burn tokens continuously.
    error OwnerCanNotContinuousBurn();

    /// @notice Error thrown when the deposit amount provided is zero.
    error DepositAmountCannotBeZero();

    /// @notice Error thrown when the burn amount provided is zero.
    error BurnAmountCannotBeZero();

    /// @notice Error thrown when the reserve balance is less than the amount requested to burn.
    /// @param requested The amount of tokens requested to burn.
    /// @param available The available balance in the reserve.
    error InsufficientReserve(uint256 requested, uint256 available);

    /// @notice Error thrown when the balance of the sender is less than the amount requested to burn.
    /// @param sender The address of the sender.
    /// @param balance The balance of the sender.
    /// @param amount The amount requested to burn.
    error InsufficentBalance(address sender, uint256 balance, uint256 amount);

    /// @notice Error thrown when a function that requires ownership is called by an address other than the owner.
    /// @param caller The address of the caller.
    /// @param owner The address of the owner.
    error OnlyOwner(address caller, address owner);

    /// @notice Error thrown when a transfer of ether fails.
    /// @param recipient The address of the recipient.
    /// @param amount The amount of ether to transfer.
    error TransferFailed(address recipient, uint256 amount);

    /// @notice Error thrown when an invalid governance parameter is set.
    /// @param what The invalid governance parameter.
    error InvalidGovernanceParameter(bytes32 what);

    /// @notice Error thrown when addresses and values provided are not equal.
    /// @param addresses The number of addresses provided.
    /// @param values The number of values provided.
    error AddressesAmountMismatch(uint256 addresses, uint256 values);

    error AddressCannotBeZero();

    error InvalidPPMValue(uint32 value);

    error HatchingNotStarted();

    error HatchingAlreadyStarted();

    error HatchNotOpen();

    error VestingScheduleNotInitialized();

    error VestingScheduleRevoked();

    error VestingScheduleNotRevocable();

    error OnlyBeneficiary(address caller, address beneficiary);

    error NotEnoughVestedTokens(uint256 requested, uint256 available);

    error DurationCannotBeZero();

    error SlicePeriodCannotBeZero();

    error DurationCannotBeLessThanCliff();

    error ContributionWindowClosed();

    error MaxContributionReached();

    error HatchNotCanceled();

    error NoContribution();

    error NotEnoughRaised();

    error HatchOngoing();

    error MinRaiseMet();
}

// SPDX-License-Identifier: MIT
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */

// https://github.com/DAObox/liquid-protocol/blob/main/src/lib/Events.sol
pragma solidity >=0.8.17;

library Events {
    /**
     * @dev Emitted when tokens are minted continuously (the normal minting process).
     * @param buyer The address of the account that initiated the minting process.
     * @param minted The amount of tokens that were minted.
     * @param depositAmount The amount of ether that was deposited to mint the tokens.
     * @param fundingAmount The amount of ether that was sent to the owner as funding.
     */
    event ContinuousMint(address indexed buyer, uint256 minted, uint256 depositAmount, uint256 fundingAmount);

    /**
     * @dev Emitted when tokens are burned continuously (the normal burning process).
     * @param burner The address of the account that initiated the burning process.
     * @param burned The amount of tokens that were burned.
     * @param reimburseAmount The amount of ether that was reimbursed to the burner.
     * @param exitFee The amount of ether that was deducted as an exit fee.
     */
    event ContinuousBurn(address indexed burner, uint256 burned, uint256 reimburseAmount, uint256 exitFee);

    /**
     * @dev Emitted when tokens are minted in a sponsored process.
     * @param sender The address of the account that initiated the minting process.
     * @param depositAmount The amount of ether that was deposited to mint the tokens.
     * @param minted The amount of tokens that were minted.
     */
    event SponsoredMint(address indexed sender, uint256 depositAmount, uint256 minted);

    /**
     * @dev Emitted when tokens are burned in a sponsored process.
     * @param sender The address of the account that initiated the burning process.
     * @param burnAmount The amount of tokens that were burned.
     */
    event SponsoredBurn(address indexed sender, uint256 burnAmount);

    /**
     * @dev Emitted when the MarketMaker has been Hatched.
     * @param hatcher The address of the account recieved the hatch tokens.
     * @param amount The amount of bonded tokens that was minted to the hatcher.
     */
    event Hatch(address indexed hatcher, uint256 amount);
}

// SPDX-License-Identifier: MIT
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */

// https://github.com/DAObox/liquid-protocol/blob/main/src/lib/Types.sol
pragma solidity >=0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IBondedToken } from "../interfaces/IBondedToken.sol";
import { IBondingCurve } from "../interfaces/IBondingCurve.sol";
import { IMarketMaker } from "../interfaces/IMarketMaker.sol";

/// @notice This struct holds the key parameters that define a bonding curve for a token.
/// @dev These parameters can be updated over time to change the behavior of the bonding curve.
struct CurveParameters {
    /// @notice  fraction of buy funds that go to the DAO.
    /// @dev This value is represented in  fraction (in PPM)
    /// The funds collected here could be used for various purposes like development, marketing, etc., depending on the
    /// DAO's decisions.
    uint32 theta;
    /// @notice  fraction of sell funds that are redistributed to the Pool.
    /// @dev This value is represented in fraction (in PPM)
    /// This "friction" is used to discourage burning and maintain stability in the token's price.
    uint32 friction;
    /// @notice The reserve ratio of the bonding curve, represented in parts per million (ppm), ranging from 1 to
    /// 1,000,000.
    /// @dev The reserve ratio corresponds to different formulas in the bonding curve:
    ///      - 1/3 corresponds to y = multiple * x^2 (exponential curve)
    ///      - 1/2 corresponds to y = multiple * x (linear curve)
    ///      - 2/3 corresponds to y = multiple * x^(1/2) (square root curve)
    /// The reserve ratio determines the price sensitivity of the token to changes in supply.
    uint32 reserveRatio;
    /// @notice The implementation of the curve.
    /// @dev This is the interface of the bonding curve contract.
    /// Different implementations can be used to change the behavior of the curve, such as linear, exponential, etc.
    IBondingCurve formula;
}

struct VestingSchedule {
    // cliff period in seconds
    uint256 cliff;
    // start time of the vesting period
    uint256 start;
    // duration of the vesting period in seconds
    uint256 duration;
    // whether or not the vesting is revocable
    bool revocable;
}

struct VestingState {
    VestingSchedule schedule;
    // total amount of tokens to be released at the end of the vesting
    uint256 amountTotal;
    // amount of tokens released
    uint256 released;
    // whether or not the vesting has been revoked
    bool revoked;
}

enum HatchStatus {
    OPEN,
    HATCHED,
    CANCELED
}

struct HatchParameters {
    // External token contract (Stablecurrency e.g. DAI).
    IERC20 externalToken;
    IBondedToken bondedToken;
    IMarketMaker pool;
    uint256 initialPrice;
    uint256 minimumRaise;
    uint256 maximumRaise;
    // Time (in seconds) by which the curve must be hatched since initialization.
    uint256 hatchDeadline;
}

struct HatchState {
    HatchParameters params;
    HatchStatus status;
    uint256 raised;
}

// SPDX-License-Identifier: MIT
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */

// https://github.com/DAObox/liquid-protocol/blob/main/src/modifiers/MarketMaker.sol
pragma solidity >=0.8.17;

import { Errors } from "../lib/Errors.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Modifiers {
    modifier nonZeroAddress(address _address) {
        if (_address == address(0)) revert Errors.AddressCannotBeZero();
        _;
    }

    modifier isPPM(uint32 _amount) {
        if (_amount == 1_000_000) revert Errors.InvalidPPMValue(_amount);
        _;
    }

    modifier validateReserve(IERC20 token) {
        if (token.balanceOf(address(this)) == 0) revert Errors.InitialReserveCannotBeZero();
        _;
    }

    modifier isTradingOpen(bool _isTradingOpen) {
        if (_isTradingOpen) revert Errors.TradingAlreadyOpened();
        _;
    }

    modifier isDepositZero(uint256 _amount) {
        if (_amount == 0) revert Errors.DepositAmountCannotBeZero();
        _;
    }

    modifier postHatch(bool _hatched) {
        if (!_hatched) revert Errors.HatchingNotStarted();
        _;
    }

    modifier preHatch(bool _hatched) {
        if (_hatched) revert Errors.HatchingAlreadyStarted();
        _;
    }
}

// SPDX-License-Identifier: MIT
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract PluginStandalone is Ownable {
    address private dao_;
    mapping(bytes32 => mapping(address => bool)) private permissions_;
    
    error NotPermitted(bytes32 _permissionId);

    constructor() {
        dao_ = msg.sender;
    }

    function dao() public view returns (address) {
        return dao_;
    }

    function setDao(address _dao) external onlyOwner {
        dao_ = _dao;
    }

    function grantPermission(bytes32 _permissionId, address _to) external onlyOwner {
        permissions_[_permissionId][_to] = true;
    }
    
    function revokePermission(bytes32 _permissionId, address _to) external onlyOwner {
        permissions_[_permissionId][_to] = false;
    }

    modifier auth(bytes32 _permissionId) {
        if (!permissions_[_permissionId][msg.sender]) {
            revert NotPermitted(_permissionId);
        }
        _;
    }
}