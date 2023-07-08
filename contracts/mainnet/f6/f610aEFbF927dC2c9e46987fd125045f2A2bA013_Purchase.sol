// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CBDToken is ERC20, ERC20Burnable {



    mapping(address => bool) public distributors; //is given address distributor 
    mapping(address => bool) public owners; //is given address owner 

    /**
    @param _name : token name
    @param _symbol : token symbol
     */
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        owners[msg.sender] = true;
    }


    function isOwner(address _user) public view returns(bool){
        return owners[_user];
    } 
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwners() {
        _checkOwners();
        _;
    }


    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwnerOrDistributor() {
        _checkOwnerOrDistributor();
        _;
    }
    
    // Check msg.sender should be owner
    function _checkOwners() internal view virtual {
        require(owners[_msgSender()], "Ownable_Distributor: caller is not from the owners");
    }

    // Check msg.sender should be owner or ditributor
    function _checkOwnerOrDistributor() internal view virtual {
        require(owners[_msgSender()] || distributors[_msgSender()], "Ownable_Distributor: caller is not the owner or distributor");
    }


    function transferUserOwnership(address _newOwner) public onlyOwners{
        owners[_msgSender()] = false;
        owners[_newOwner] = true;
    }

    function addOwner(address _newOwner) public onlyOwners{
        owners[_newOwner] = true;
    }

    function removeOwner(address _newOwner) public onlyOwners{
        owners[_newOwner] = false;
    }

    
    /**
    @param _distributor is a contract or wallet address that can mint or burn tokens
     */
    function addDistributor(address _distributor) external onlyOwners {
    distributors[_distributor] = true;
    }

    function removeDistributor(address _distributor) external onlyOwners {
    distributors[_distributor] = false;
    }


    //mint tokens by owner or distributor
    function mint(address to, uint256 amount) public onlyOwnerOrDistributor {
        _mint(to, amount);
    }

    function burn(address account, uint amount) public onlyOwnerOrDistributor {
        _burn(account, amount);
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
// pragma abicoderv2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./CBDToken.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Purchase {
    CBDToken public cbdToken;
    address public purchaseToken;
    uint256 public tokenPrice;
    uint256 public baseRegisterAmount;
    AggregatorV3Interface public priceFeed;

    address public admin;
    mapping(address => bool) public owners; //is given address owner 

    mapping(address => bool) public isRegistered;

    bool onlyAllowedAmountsStatus;
    mapping(uint => AllowedAmount) public allowedAmounts;
    
    
    struct AllowedAmount {
        bool isAllowed;
        uint totalReward;
    }

    struct UserRewards {
        uint256 totalRewardAmount;
        uint256 rewardAmount;
        uint256 endTime;
        uint256 lastUpdateTime;
    }

    /**
    @param _cbdToken : CBD token address
    @param _purchaseToken : address of the stablecoin that user can pay for buy
    @param _tokenPrice: price of each token. This price should be in format of purchase token.(if purchase token has 18 decimals, this input amount should has 18 decimals too)
    @notice usdc on polygon has 6 decimals so price should has 6 decimals
     */
    constructor(
        address _cbdToken,
        address _purchaseToken,
        uint256 _tokenPrice,
        address _priceFeed
    ) {
        cbdToken = CBDToken(_cbdToken);
        purchaseToken = _purchaseToken;
        tokenPrice = _tokenPrice;
        priceFeed = AggregatorV3Interface(_priceFeed);
        uint256 purchaseTokenDecimals = ERC20(purchaseToken).decimals();
        baseRegisterAmount = 50*10**purchaseTokenDecimals;
        //set owner and admin
        owners[msg.sender] = true;
        admin = msg.sender;
        //allowed amounts
        onlyAllowedAmountsStatus = true;
        anableAllawanceForAmount(250*10**purchaseTokenDecimals, 500*10**purchaseTokenDecimals);
        anableAllawanceForAmount(500*10**purchaseTokenDecimals, 1500*10**purchaseTokenDecimals);
        anableAllawanceForAmount(1000*10**purchaseTokenDecimals, 3000*10**purchaseTokenDecimals);
        anableAllawanceForAmount(2000*10**purchaseTokenDecimals, 6000*10**purchaseTokenDecimals);
    }

    
    mapping(address => UserRewards[]) public purchaseRewards;
    mapping(address => UserRewards[]) public referRewards;
    mapping(address => address) public refer;
    mapping(address => address[]) public referredPeople;
    //history
    mapping(address => uint) public instantReferRewardHistory;


    function isOwner(address _user) public view returns(bool){
        return owners[_user];
    } 


    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwners() {
        _checkOwners();
        _;
    }
    
    
    // Check msg.sender should be owner
    function _checkOwners() internal view virtual {
        require(owners[msg.sender], "Ownable_Distributor: caller is not from the owners");
    }
    

    function transferUserOwnership(address _newOwner) public onlyOwners{
        owners[msg.sender] = false;
        owners[_newOwner] = true;
    }

    function addOwner(address _newOwner) public onlyOwners{
        owners[_newOwner] = true;
    }

    function removeOwner(address _newOwner) public onlyOwners{
        owners[_newOwner] = false;
    }

    function changeAdmin(address _newAdmin) public onlyOwners{
        admin = _newAdmin;
    }


    function scalePrice(
        int256 _price,
        uint8 _priceDecimals,
        uint8 _decimals
    ) internal pure returns (int256) {
        if (_priceDecimals < _decimals) {
            return _price * int256(10**uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10**uint256(_priceDecimals - _decimals));
        }
        return _price;
    }

    function getOracleUsdcPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint8 baseDecimals = priceFeed.decimals();
        int256 basePrice = scalePrice(price, baseDecimals, 18);
        return uint256(basePrice);
    }

    //set purchase token
    function setPurchaseToken(address _purchaseToken) public onlyOwners {
        require(
            _purchaseToken != address(0),
            "Purchase token can not be zero address"
        );
        purchaseToken = _purchaseToken;
    }

    // enable or disable allowAmounts trading
    function changeAllowAmountsActivation(bool _status) public onlyOwners {
        onlyAllowedAmountsStatus = _status;
    }

    // allow amounts trading
    function anableAllawanceForAmount(uint _amount, uint _totalRewardByAmount) public onlyOwners {
        allowedAmounts[_amount].isAllowed = true;
        allowedAmounts[_amount].totalReward = _totalRewardByAmount;
    }

    // disAllow amounts trading
    function disableAllawanceForAmount(uint _amount) public onlyOwners {
        allowedAmounts[_amount].isAllowed = false;
        allowedAmounts[_amount].totalReward = 0;
    }



    //set CBD token
    function setCBDToken(address _CBDToken) public onlyOwners {
        require(_CBDToken != address(0), "CBD token can not be zero address");
        cbdToken = CBDToken(_CBDToken);
    }

    function setBaseRegisterAmount(uint256 _baseRegisterAmount) public onlyOwners {
        require(_baseRegisterAmount != 0, "Base register amount can not be zero");
        baseRegisterAmount = _baseRegisterAmount;
    }

    // referredPeople
    function userReferredPeople(address _user)
        public
        view
        returns (address[] memory)
    {
        return referredPeople[_user];
    }

    //return all purchse rewards of a user (in an array of the structurs)
    function userPurchaseRewards(address _user)
        public
        view
        returns (UserRewards[] memory)
    {
        return purchaseRewards[_user];
    }

    //return all purchse rewards of a user (in an array of the structurs)
    function userReferRewards(address _user)
        public
        view
        returns (UserRewards[] memory)
    {
        return referRewards[_user];
    }

    //return all purchase reward amounts of a user
    function allPurchaseRewardAmounts(address _user) public view returns (uint256) {
        uint256 allRewards = 0;
        for (uint256 i = 0; i < purchaseRewards[_user].length; i++) {
            if (purchaseRewards[_user][i].rewardAmount > 0) {
                allRewards += purchaseRewards[_user][i].rewardAmount;
            }
        }
        return allRewards;
    }


    //return all refer reward amounts of a user
    function allReferRewardAmounts(address _user) public view returns (uint256) {
        uint256 allRewards = 0;
        for (uint256 i = 0; i < referRewards[_user].length; i++) {
            if (referRewards[_user][i].rewardAmount > 0) {
                allRewards += referRewards[_user][i].rewardAmount;
            }
        }
        return allRewards;
    }

    //return all reward amounts of a user (purchase rewards + refer rewards)
    function allRewardAmounts(address _user) public view returns (uint256) {
        uint256 allRewards = 0;
        for (uint256 i = 0; i < purchaseRewards[_user].length; i++) {
            if (purchaseRewards[_user][i].rewardAmount > 0) {
                allRewards += purchaseRewards[_user][i].rewardAmount;
            }
        }
        for (uint256 i = 0; i < referRewards[_user].length; i++) {
            if (referRewards[_user][i].rewardAmount > 0) {
                allRewards += referRewards[_user][i].rewardAmount;
            }
        }
        return allRewards;
    }


    //return all purchase reward amounts of a user
    function allPurchaseTotalRewardAmounts(address _user) public view returns (uint256) {
        uint256 allTotalRewards = 0;
        for (uint256 i = 0; i < purchaseRewards[_user].length; i++) {
            if (purchaseRewards[_user][i].totalRewardAmount > 0) {
                allTotalRewards += purchaseRewards[_user][i].totalRewardAmount;
            }
        }
        return allTotalRewards;
    }


    //return all refer reward amounts of a user
    function allReferTotalRewardAmounts(address _user) public view returns (uint256) {
        uint256 allTotalRewards = 0;
        for (uint256 i = 0; i < referRewards[_user].length; i++) {
            if (referRewards[_user][i].totalRewardAmount > 0) {
                allTotalRewards += referRewards[_user][i].totalRewardAmount;
            }
        }
        return allTotalRewards;
    }

    //return all reward amounts of a user (purchase rewards + refer rewards)
    function allTotalRewardAmounts(address _user) public view returns (uint256) {
        uint256 allTotalRewards = 0;
        for (uint256 i = 0; i < purchaseRewards[_user].length; i++) {
            if (purchaseRewards[_user][i].totalRewardAmount > 0) {
                allTotalRewards += purchaseRewards[_user][i].totalRewardAmount;
            }
        }
        for (uint256 i = 0; i < referRewards[_user].length; i++) {
            if (referRewards[_user][i].totalRewardAmount > 0) {
                allTotalRewards += referRewards[_user][i].totalRewardAmount;
            }
        }
        return allTotalRewards;
    }

    function getUnclaimedRewards(address _user) public view returns (uint256) {
        uint256 unClaimedRewards = 0;
        //for purchase rewards
        for (uint256 i = 0; i < purchaseRewards[_user].length; i++) {
            if (purchaseRewards[_user][i].rewardAmount > 0) {
                if (block.timestamp < purchaseRewards[_user][i].endTime) {
                    uint256 allRemainPeriod = purchaseRewards[_user][i].endTime -
                        purchaseRewards[_user][i].lastUpdateTime;
                    uint256 unClaimedPeriod = block.timestamp -
                        purchaseRewards[_user][i].lastUpdateTime;
                    uint256 unClaimedAmount = (purchaseRewards[_user][i].rewardAmount *
                        unClaimedPeriod) / allRemainPeriod;
                    unClaimedRewards += unClaimedAmount;
                } else {
                    unClaimedRewards += purchaseRewards[_user][i].rewardAmount;
                }
            }
        }
        //for refer rewards
        for (uint256 i = 0; i < referRewards[_user].length; i++) {
            if (referRewards[_user][i].rewardAmount > 0) {
                if (block.timestamp < referRewards[_user][i].endTime) {
                    uint256 allRemainPeriod = referRewards[_user][i].endTime -
                        referRewards[_user][i].lastUpdateTime;
                    uint256 unClaimedPeriod = block.timestamp -
                        referRewards[_user][i].lastUpdateTime;
                    uint256 unClaimedAmount = (referRewards[_user][i].rewardAmount *
                        unClaimedPeriod) / allRemainPeriod;
                    unClaimedRewards += unClaimedAmount;
                } else {
                    unClaimedRewards += referRewards[_user][i].rewardAmount;
                }
            }
        }
        return unClaimedRewards;
    }

    /**
    @dev set token price by the owner (should be in wei)
    @param _newTokenPrice should be on format of purchase token price (18 decimal or other)
    @notice usdc on polygon has 6 decimals so price should has 6 decimals
     */
    function setTokenPrice(uint256 _newTokenPrice) public onlyOwners {
        tokenPrice = _newTokenPrice;
    }

    /**
    @dev User first should buy 80 usd tokens to be registered
    all stable coin will be transfered to the wallet of owner
    first smart contract perform purchase actions for the user after that four up level inviters will receive rewards
    @param stableCoinAmount is number of tokens that user wants to buy (should be in wei format without number)
    @param _refer is an address that invite user with referral link to buy token
    */
    function register(uint256 stableCoinAmount, address _refer) public {
        if(_refer != address(0)){
        require(isRegistered[_refer] == true, "Your refer is not registered");
        }
        require(stableCoinAmount >= baseRegisterAmount, "Your amount is lower than the base register amount");
        uint256 usdcOraclePrice = getOracleUsdcPrice();
        require(usdcOraclePrice >= 95e16, "USDC price is not above 0.95 $");
        require(_refer != msg.sender, "You can't put your address as refer");
        require(
            IERC20(purchaseToken).balanceOf(msg.sender) >= stableCoinAmount,
            "You don't have enough stablecoin balance to buy"
        );
        SafeERC20.safeTransferFrom(
            IERC20(purchaseToken),
            msg.sender,
            admin,
            stableCoinAmount
        );
        isRegistered[msg.sender] = true;
        if(refer[msg.sender] == address(0) && _refer != address(0)){
                // store msg.sender as refferedPeople for refer
                referredPeople[_refer].push(msg.sender);
                //set _refer for msg.sender
                refer[msg.sender] = _refer;
            }
    }

    /**
    @dev user can buy token by paying stable coin
    all stable coin will be transfered to the wallet of owner
    first smart contract perform purchase actions for the user after that four up level inviters will receive rewards
    @param stableCoinAmount is number of tokens that user wants to buy (should be in wei format without number)
    @param _refer is an address that invite user with referral link to buy token
    */
    function buyToken(uint256 stableCoinAmount, address _refer) public {
        require(isRegistered[msg.sender] == true, "You are not registered");
        if(_refer != address(0)){
        require(isRegistered[_refer] == true, "Your refer is not registered");
        }
        uint256 usdcOraclePrice = getOracleUsdcPrice();
        require(usdcOraclePrice >= 95e16, "USDC price is not above 0.95 $");
        uint256 purchaseTokenDecimals = ERC20(purchaseToken).decimals();
        require(_refer != msg.sender, "You can't put your address as refer");
        require(
            IERC20(purchaseToken).balanceOf(msg.sender) >= stableCoinAmount,
            "You don't have enough stablecoin balance to buy"
        );
        uint256 quantity = (stableCoinAmount * 1e18) / tokenPrice;
        uint256 baseQuantity = (1000 * 10**purchaseTokenDecimals * 1e18) /
            tokenPrice;

        if(onlyAllowedAmountsStatus == true){
            require(allowedAmounts[stableCoinAmount].isAllowed, "This stable coin amount is not allowed");
            uint allQuantityByReward = (allowedAmounts[stableCoinAmount].totalReward * 1e18) / tokenPrice;
            cbdToken.mint(msg.sender, allQuantityByReward*10/100);
            SafeERC20.safeTransferFrom(
                IERC20(purchaseToken),
                msg.sender,
                admin,
                stableCoinAmount
            );
            purchaseRewards[msg.sender].push(
                    UserRewards(
                        allQuantityByReward*90/100,
                        allQuantityByReward*90/100,
                        block.timestamp + 1095 days,
                        block.timestamp
                    )
                );
        }else{
        //perform purchase for user
        cbdToken.mint(msg.sender, quantity);
        SafeERC20.safeTransferFrom(
            IERC20(purchaseToken),
            msg.sender,
            admin,
            stableCoinAmount
        );
        }

        //give refers rewards
        if (_refer != address(0)) {
            if(refer[msg.sender] == address(0)){
                // store msg.sender as refferedPeople for refer
                referredPeople[_refer].push(msg.sender);
                //set _refer for msg.sender
                refer[msg.sender] = _refer;
            }
            // extract refers
            address refer1 = refer[msg.sender];
            address refer2 = refer[refer1];
            address refer3 = refer[refer2];
            address refer4 = refer[refer3];
            // set refer1 rewards
            if (refer1 != address(0) && cbdToken.balanceOf(refer1) > 0) {
                cbdToken.mint(refer1, (5e18 * quantity) / baseQuantity);
                instantReferRewardHistory[refer1] += ((5e18 * quantity) / baseQuantity);
                referRewards[refer1].push(
                    UserRewards(
                        (95e17 * quantity) / baseQuantity,
                        (95e17 * quantity) / baseQuantity,
                        block.timestamp + 1095 days,
                        block.timestamp
                    )
                );
            }
            // set refer2 rewards
            if (refer2 != address(0) && cbdToken.balanceOf(refer2) > 0) {
                referRewards[refer2].push(
                    UserRewards(
                        (75e17 * quantity) / baseQuantity,
                        (75e17 * quantity) / baseQuantity,
                        block.timestamp + 1095 days,
                        block.timestamp
                    )
                );
            }
            // set refer3 rewards
            if (refer3 != address(0) && cbdToken.balanceOf(refer3) > 0) {
                referRewards[refer3].push(
                    UserRewards(
                        (6e18 * quantity) / baseQuantity,
                        (6e18 * quantity) / baseQuantity,
                        block.timestamp + 1095 days,
                        block.timestamp
                    )
                );
            }
            // set refer4 rewards
            if (refer4 != address(0) && cbdToken.balanceOf(refer4) > 0) {
                referRewards[refer4].push(
                    UserRewards(
                        (4e18 * quantity) / baseQuantity,
                        (4e18 * quantity) / baseQuantity,
                        block.timestamp + 1095 days,
                        block.timestamp
                    )
                );
            }
        }
    }

    function buyTokenWhitoutRef(uint256 stableCoinAmount) public {
        require(isRegistered[msg.sender] == true, "You are not registered");
        uint256 usdcOraclePrice = getOracleUsdcPrice();
        require(usdcOraclePrice >= 95e16, "USDC price is not above 0.95 $");
        require(
            IERC20(purchaseToken).balanceOf(msg.sender) >= stableCoinAmount,
            "You don't have enough stablecoin balance to buy"
        );
        uint256 quantity = (stableCoinAmount * 1e18) / tokenPrice;
        //perform purchase for user
        cbdToken.mint(msg.sender, quantity);
        SafeERC20.safeTransferFrom(
            IERC20(purchaseToken),
            msg.sender,
            admin,
            stableCoinAmount
        );
    }

    function _deletePurchaseRewardObject(address _user, uint256 _rewardIndex) internal {
        for (uint256 i = _rewardIndex; i < purchaseRewards[_user].length - 1; i++) {
            purchaseRewards[_user][i] = purchaseRewards[_user][i + 1];
        }
        delete purchaseRewards[_user][purchaseRewards[_user].length - 1];
        purchaseRewards[_user].pop();
    }


    function _deleteReferRewardObject(address _user, uint256 _rewardIndex) internal {
        for (uint256 i = _rewardIndex; i < referRewards[_user].length - 1; i++) {
            referRewards[_user][i] = referRewards[_user][i + 1];
        }
        delete referRewards[_user][referRewards[_user].length - 1];
        referRewards[_user].pop();
    }

    //claim rewards by the user
    function claimRewards() public {
        uint tokenAmountToMint;
        // calculate purchase rewards
        for (uint256 i = 0; i < purchaseRewards[msg.sender].length; i++) {
            if (purchaseRewards[msg.sender][i].rewardAmount > 0) {
                if (block.timestamp < purchaseRewards[msg.sender][i].endTime) {
                    uint256 allRemainPeriod = purchaseRewards[msg.sender][i].endTime -
                        purchaseRewards[msg.sender][i].lastUpdateTime;
                    uint256 unClaimedPeriod = block.timestamp -
                        purchaseRewards[msg.sender][i].lastUpdateTime;
                    uint256 unClaimedAmount = (purchaseRewards[msg.sender][i]
                        .rewardAmount * unClaimedPeriod) / allRemainPeriod;
                    purchaseRewards[msg.sender][i].rewardAmount -= unClaimedAmount;
                    purchaseRewards[msg.sender][i].lastUpdateTime = block.timestamp;
                    if (purchaseRewards[msg.sender][i].rewardAmount == 0) {
                        _deletePurchaseRewardObject(msg.sender, i);
                    }
                    tokenAmountToMint += unClaimedAmount;
                } else {
                    uint256 unClaimedAmount = purchaseRewards[msg.sender][i]
                        .rewardAmount;
                    purchaseRewards[msg.sender][i].rewardAmount = 0;
                    purchaseRewards[msg.sender][i].lastUpdateTime = block.timestamp;
                    tokenAmountToMint += unClaimedAmount;
                }
            }
        }
        // calculate refer rewards
        for (uint256 i = 0; i < referRewards[msg.sender].length; i++) {
            if (referRewards[msg.sender][i].rewardAmount > 0) {
                if (block.timestamp < referRewards[msg.sender][i].endTime) {
                    uint256 allRemainPeriod = referRewards[msg.sender][i].endTime -
                        referRewards[msg.sender][i].lastUpdateTime;
                    uint256 unClaimedPeriod = block.timestamp -
                        referRewards[msg.sender][i].lastUpdateTime;
                    uint256 unClaimedAmount = (referRewards[msg.sender][i]
                        .rewardAmount * unClaimedPeriod) / allRemainPeriod;
                    referRewards[msg.sender][i].rewardAmount -= unClaimedAmount;
                    referRewards[msg.sender][i].lastUpdateTime = block.timestamp;
                    if (referRewards[msg.sender][i].rewardAmount == 0) {
                        _deleteReferRewardObject(msg.sender, i);
                    }
                    tokenAmountToMint += unClaimedAmount;
                } else {
                    uint256 unClaimedAmount = referRewards[msg.sender][i]
                        .rewardAmount;
                    referRewards[msg.sender][i].rewardAmount = 0;
                    referRewards[msg.sender][i].lastUpdateTime = block.timestamp;
                    tokenAmountToMint += unClaimedAmount;
                }
            }
        }
        cbdToken.mint(msg.sender, tokenAmountToMint);

        //delet zero purchase object
        for (uint256 i = 0; i < purchaseRewards[msg.sender].length; i++) {
            if (purchaseRewards[msg.sender][i].rewardAmount == 0) {
                _deletePurchaseRewardObject(msg.sender, i);
            }
        }
        //delet zero refer object
        for (uint256 i = 0; i < referRewards[msg.sender].length; i++) {
            if (referRewards[msg.sender][i].rewardAmount == 0) {
                _deleteReferRewardObject(msg.sender, i);
            }
        }
    }



    //claim only purchase rewards by the user
    function claimPurchaseRewards() public {
        uint tokenAmountToMint;
        // calculate purchase rewards
        for (uint256 i = 0; i < purchaseRewards[msg.sender].length; i++) {
            if (purchaseRewards[msg.sender][i].rewardAmount > 0) {
                if (block.timestamp < purchaseRewards[msg.sender][i].endTime) {
                    uint256 allRemainPeriod = purchaseRewards[msg.sender][i].endTime -
                        purchaseRewards[msg.sender][i].lastUpdateTime;
                    uint256 unClaimedPeriod = block.timestamp -
                        purchaseRewards[msg.sender][i].lastUpdateTime;
                    uint256 unClaimedAmount = (purchaseRewards[msg.sender][i]
                        .rewardAmount * unClaimedPeriod) / allRemainPeriod;
                    purchaseRewards[msg.sender][i].rewardAmount -= unClaimedAmount;
                    purchaseRewards[msg.sender][i].lastUpdateTime = block.timestamp;
                    if (purchaseRewards[msg.sender][i].rewardAmount == 0) {
                        _deletePurchaseRewardObject(msg.sender, i);
                    }
                    tokenAmountToMint += unClaimedAmount;
                } else {
                    uint256 unClaimedAmount = purchaseRewards[msg.sender][i]
                        .rewardAmount;
                    purchaseRewards[msg.sender][i].rewardAmount = 0;
                    purchaseRewards[msg.sender][i].lastUpdateTime = block.timestamp;
                    tokenAmountToMint += unClaimedAmount;
                }
            }
        }
        
        cbdToken.mint(msg.sender, tokenAmountToMint);

        //delet zero purchase object
        for (uint256 i = 0; i < purchaseRewards[msg.sender].length; i++) {
            if (purchaseRewards[msg.sender][i].rewardAmount == 0) {
                _deletePurchaseRewardObject(msg.sender, i);
            }
        }
    }


    //claim refer rewards by the user
    function claimReferRewards() public {
        uint tokenAmountToMint;
        
        // calculate refer rewards
        for (uint256 i = 0; i < referRewards[msg.sender].length; i++) {
            if (referRewards[msg.sender][i].rewardAmount > 0) {
                if (block.timestamp < referRewards[msg.sender][i].endTime) {
                    uint256 allRemainPeriod = referRewards[msg.sender][i].endTime -
                        referRewards[msg.sender][i].lastUpdateTime;
                    uint256 unClaimedPeriod = block.timestamp -
                        referRewards[msg.sender][i].lastUpdateTime;
                    uint256 unClaimedAmount = (referRewards[msg.sender][i]
                        .rewardAmount * unClaimedPeriod) / allRemainPeriod;
                    referRewards[msg.sender][i].rewardAmount -= unClaimedAmount;
                    referRewards[msg.sender][i].lastUpdateTime = block.timestamp;
                    if (referRewards[msg.sender][i].rewardAmount == 0) {
                        _deleteReferRewardObject(msg.sender, i);
                    }
                    tokenAmountToMint += unClaimedAmount;
                } else {
                    uint256 unClaimedAmount = referRewards[msg.sender][i]
                        .rewardAmount;
                    referRewards[msg.sender][i].rewardAmount = 0;
                    referRewards[msg.sender][i].lastUpdateTime = block.timestamp;
                    tokenAmountToMint += unClaimedAmount;
                }
            }
        }
        cbdToken.mint(msg.sender, tokenAmountToMint);

        //delet zero refer object
        for (uint256 i = 0; i < referRewards[msg.sender].length; i++) {
            if (referRewards[msg.sender][i].rewardAmount == 0) {
                _deleteReferRewardObject(msg.sender, i);
            }
        }
    }
}