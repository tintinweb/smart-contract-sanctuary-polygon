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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IBotPrevention {
    function setDexPairAddress(address _pairAddress) external;

    function beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) external view  returns (bool);

    function afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) external  returns (bool);

	function resetBotPreventionData() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

struct TokenReward {
    uint256 amount;
    uint256 releaseDate;
    bool isClaimed;
    bool isActive;
}

interface ICrowdfunding {
    function addRewards(
        address[] memory _rewardOwners,
        uint256[] memory _advancePayments,
        uint256[] memory _amountsPerVesting,
        uint8[] memory _numberOfVestings,
        uint256 _releaseDate,
        address _tokenHolder
    ) external;

    function claimTokens(uint8 _vestingIndex) external;

    function deactivateInvestorVesting(
        address _rewardOwner,
        uint8 _vestingIndex,
        address _tokenReceiver
    ) external;

    function activateInvestorVesting(
        address _rewardOwner,
        uint8 _vestingIndex,
        address _tokenSource
    ) external;

    function addToBlacklist(address _rewardOwner, address _tokenReceiver) external;

    function removeFromBlacklist(address _rewardOwner, address _tokenSource) external;

    function fetchRewardsInfo(uint8 _vestingIndex) external view returns (TokenReward memory);

    function fetchRewardsInfoForAccount(address _rewardOwner, uint8 _vestingIndex)
        external
        view
        returns (TokenReward memory);

    function isInBlacklist(address _address, uint256 _time) external view returns (bool);

    function getTotalBalance() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./IVault.sol";

interface ICrowdfundingVault is IVault {
    function setSeedSaleContract(address _seedSaleContractAddress) external;

    function setStrategicSaleContract(address _strategicSaleContractAddress) external;

    function setPassHolderSaleContract(address _passHolderSaleContractAddress) external;

    function setPrivateSaleContract(address _privateSaleContractAddress) external;

    function setPublicSaleContract(address _publicSaleContractAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IVault.sol";

interface ILiquidityVault is IVault {
    function DEXPairAddress() external view returns (address);

    function stableAmountForInitialLiquidity() external returns (uint256);

    function withdrawMarketMakerShare(address _receiver, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IManagers {
    function isManager(address _address) external view returns (bool);

    function approveTopic(string memory _title, bytes memory _encodedValues) external;

    function cancelTopicApproval(string memory _title) external;

    function deleteTopic(string memory _title) external;

    function isApproved(string memory _title, bytes memory _value) external view returns (bool);

    function changeManager1(address _newAddress) external;

    function changeManager2(address _newAddress) external;

    function changeManager3(address _newAddress) external;

    function changeManager4(address _newAddress) external;

    function changeManager5(address _newAddress) external;

    function isTrustedSource(address _address) external view returns (bool);

    function addAddressToTrustedSources(address _address, string memory _name) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./IVault.sol";

interface IPlayToEarnVault is IVault {
    function intervalBetweenDistributions() external returns (uint256);

    function distributionOffset() external returns (uint256);

    function claimContractAddress() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

struct StakeData {
    uint256 amount;
    uint256 stakeDate;
    uint256 releaseDate;
    uint256 percentage;
    uint16 monthToStake;
    bool withdrawn;
    bool emergencyWithdrawn;
    uint256 withdrawTime;
}

interface IStaking {
    function changeMinimumStakingAmount(uint256 _newAmount) external;

    function stake(uint256 _amount, uint8 _monthToStake) external;

    function emergencyWithdrawStake(uint256 _stakeIndex) external;

    function withdrawStake(uint256 _stakeIndex) external;

    function pause() external;

    function getTotalBalance() external view returns (uint256);

    function fetchStakeDataForAddress(address _address) external view returns (StakeData[] memory);

    function fetchOwnStakeData() external view returns (StakeData[] memory);

    function fetchStakeRewardForAddress(address _address, uint256 _stakeIndex)
        external
        view
        returns (uint256 _totalAmount, uint256 _penaltyAmount);

    function fetchStakeReward(uint256 _stakeIndex) external view returns (uint256 _totalAmount, uint256 _penaltyAmount);

    function fetchActiveStakers() external view returns (address[] memory);
   
    function fetchAllStakers() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVault {
    function createVestings(
        uint256 _totalAmount,
        uint256 _initialRelease,
        uint256 _initialReleaseDate,
        uint256 _lockDurationInDays,
        uint256 _countOfVesting,
        uint256 _releaseFrequencyInDays
    ) external;

    function withdrawTokens(address[] memory _receivers, uint256[] memory _amounts) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IPlayToEarnVault.sol";
import "./interfaces/ILiquidityVault.sol";
import "./interfaces/ICrowdfundingVault.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/ICrowdfunding.sol";
import "./interfaces/IBotPrevention.sol";
import "./interfaces/IManagers.sol";
import "./SoulsToken.sol";

contract MainVault is Ownable {
    using SafeERC20 for IERC20;

    //Storage Variables
    SoulsToken public immutable soulsToken;
    IManagers public immutable managers;

    uint256 public liquidityTokensUnlockTime;

    //Tokenomi
    uint256 public constant crowdfundingShare = 613_820_200 ether;
    uint256 public constant playToEarnShare = 900_000_000 ether;
    uint256 public constant marketingShare = 300_000_000 ether;
    uint256 public constant liquidityShare = 60_000_000 ether;
    uint256 public constant treasuryShare = 226_179_800 ether;
    uint256 public constant stakingShare = 300_000_000 ether;
    uint256 public constant advisorShare = 150_000_000 ether;
    uint256 public constant airdropShare = 150_000_000 ether;
    uint256 public constant teamShare = 300_000_000 ether;

    address public crowdfundingVaultAddress;
    address public playToEarnVaultAddress;
    address public marketingVaultAddress;
    address public liquidityVaultAddress;
    address public treasuryVaultAddress;
    address public advisorVaultAddress;
    address public stakingVaultAddress;
    address public airdropVaultAddress;
    address public teamVaultAddress;
    address public dexPairAddress;

    enum VaultEnumerator {
        MARKETING,
        ADVISOR,
        TEAM,
        TREASURY,
        AIRDROP,
        STAKING
    }

    //Custom Errors
    error ManagerAddressCannotBeAddedToTrustedSources();
    error GameStartDayCanBeMaximum60DaysBefore();
    error LiquidityVaultNotInitialized();
    error GameStartTimeMustBeInThePast();
    error InvalidCrowdfundingContract();
    error DateMustBeInTheFuture();
    error AlreadyInitialized();
    error InvalidVaultIndex();
    error ZeroBalanceOfLP();
    error EmptyNameString();
    error NotAuthorized();
    error ZeroAddress();
    error ZeroAmount();
    error StillLocked();

    //Events
    event SetCrowdfundingContracts(
        address manager,
        address seedSaleContract,
        address strategicSaleContract,
        address privateSaleContract,
        address publicSaleContract,
        bool isApproved
    );
    event AddAddressToTrustedSources(address manager, address addr, string name, bool isApproved);

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        IManagers _managers,
        address _botPreventionAddress
    ) {
        managers = _managers;
        soulsToken = new SoulsToken(_tokenName, _tokenSymbol, address(managers), _botPreventionAddress);
        soulsToken.transferOwnership(msg.sender);
    }

    //Modifiers
    modifier onlyManager() {
        if (!managers.isManager(msg.sender)) {
            revert NotAuthorized();
        }
        _;
    }

    // //Write Functions
    // Managers Function
    function initPlayToEarnVault(address _playToEarnVaultAddress, uint256 _gameStartTime) external onlyManager {
        if (playToEarnVaultAddress != address(0)) {
            revert AlreadyInitialized();
        }
        if (_playToEarnVaultAddress == address(0)) {
            revert ZeroAddress();
        }
        if (_gameStartTime >= block.timestamp) {
            revert GameStartTimeMustBeInThePast();
        }

        string memory _title = "Init Play To Earn Vault";
        bytes memory _encodedValues = abi.encode(_playToEarnVaultAddress, _gameStartTime);
        managers.approveTopic(_title, _encodedValues);

        if (managers.isApproved(_title, _encodedValues)) {
            playToEarnVaultAddress = _playToEarnVaultAddress;
            uint256 daysSinceGameStartTime = (block.timestamp - _gameStartTime) / 1 days;
            if (daysSinceGameStartTime > 60) {
                revert GameStartDayCanBeMaximum60DaysBefore();
            }

            IPlayToEarnVault _playToEarnVault = IPlayToEarnVault(playToEarnVaultAddress);
            soulsToken.approve(playToEarnVaultAddress, playToEarnShare);

            _playToEarnVault.createVestings(playToEarnShare, 0, 0, 86, _gameStartTime + 60 days, 30);

            managers.addAddressToTrustedSources(playToEarnVaultAddress, "PlayToEarn Vault");
            managers.addAddressToTrustedSources(_playToEarnVault.claimContractAddress(), "Withdraw Claim Contract");

            managers.deleteTopic(_title);
        }
    }

    function initLiquidityVault(
        address _liquidityVaultAddress,
        address _stableTokenAddress,
        uint256 _initialReleaseDate
    ) external onlyOwner {
        if (liquidityVaultAddress != address(0)) {
            revert AlreadyInitialized();
        }
        if (_liquidityVaultAddress == address(0)) {
            revert ZeroAddress();
        }
        if (_initialReleaseDate < block.timestamp) {
            revert DateMustBeInTheFuture();
        }
        liquidityVaultAddress = _liquidityVaultAddress;

        ILiquidityVault _liquidityVault = ILiquidityVault(liquidityVaultAddress);
        soulsToken.approve(liquidityVaultAddress, liquidityShare);

        IERC20 stableToken = IERC20(_stableTokenAddress);
        stableToken.safeTransferFrom(
            msg.sender,
            liquidityVaultAddress,
            _liquidityVault.stableAmountForInitialLiquidity()
        );
        _liquidityVault.createVestings(liquidityShare, liquidityShare, _initialReleaseDate, 0, 0, 0);
        dexPairAddress = _liquidityVault.DEXPairAddress();
        liquidityTokensUnlockTime = block.timestamp + 365 days;
        managers.addAddressToTrustedSources(liquidityVaultAddress, "Liquidity Vault");
    }

    function initCrowdfundingVault(
        address _crowdfundingVaultAddress,
        address _seedSaleContract,
        address _strategicSaleContract,
        address _privateSaleContract,
        address _publicSaleContract,
        address _passHolderSaleContract,
        uint256 _initialReleaseDate
    ) external onlyOwner {
        if (crowdfundingVaultAddress != address(0)) {
            revert AlreadyInitialized();
        }

        if (_crowdfundingVaultAddress == address(0)) {
            revert ZeroAddress();
        }
        if (_initialReleaseDate < block.timestamp) {
            revert DateMustBeInTheFuture();
        }
        crowdfundingVaultAddress = _crowdfundingVaultAddress;
        IVault _vault = IVault(_crowdfundingVaultAddress);
        _vault.createVestings(crowdfundingShare, crowdfundingShare, _initialReleaseDate, 0, 0, 0);
        soulsToken.transfer(_crowdfundingVaultAddress, crowdfundingShare);
        managers.addAddressToTrustedSources(_crowdfundingVaultAddress, "Crowdfunding Vault");
        _setCrowdfundingContracts(
            _seedSaleContract,
            _strategicSaleContract,
            _passHolderSaleContract,
            _privateSaleContract,
            _publicSaleContract
        );
    }

    function _setCrowdfundingContracts(
        address _seedSaleContract,
        address _strategicSaleContract,
        address _passHolderSaleContract,
        address _privateSaleContract,
        address _publicSaleContract
    ) private {
        if (
            _seedSaleContract == address(0) ||
            _strategicSaleContract == address(0) ||
            _passHolderSaleContract == address(0) ||
            _privateSaleContract == address(0) ||
            _publicSaleContract == address(0)
        ) {
            revert ZeroAddress();
        }
        ICrowdfundingVault(crowdfundingVaultAddress).setSeedSaleContract(_seedSaleContract);
        ICrowdfundingVault(crowdfundingVaultAddress).setStrategicSaleContract(_strategicSaleContract);
        ICrowdfundingVault(crowdfundingVaultAddress).setPassHolderSaleContract(_passHolderSaleContract);
        ICrowdfundingVault(crowdfundingVaultAddress).setPrivateSaleContract(_privateSaleContract);
        ICrowdfundingVault(crowdfundingVaultAddress).setPublicSaleContract(_publicSaleContract);
    }

    function initVault(
        address _vaultAddress,
        VaultEnumerator _vaultToInit,
        uint256 _initialReleaseDate
    ) external onlyOwner {
        if (_vaultAddress == address(0)) {
            revert ZeroAddress();
        }
        if (_initialReleaseDate < block.timestamp) {
            revert DateMustBeInTheFuture();
        }
        string memory _vaultName;
        uint256 _vaultShare;
        uint256 _initialRelease;
        uint256 _vestingStartDate;
        uint256 _vestingCount;
        uint256 _vestingFrequency;

        if (_vaultToInit == VaultEnumerator.MARKETING) {
            if (marketingVaultAddress != address(0)) {
                revert AlreadyInitialized();
            }

            marketingVaultAddress = _vaultAddress;
            _vaultName = "Marketing Vault";
            _vaultShare = marketingShare;
            _initialRelease = 6_000_000 ether;
            _vestingStartDate = _initialReleaseDate + 90 days;
            _vestingCount = 24;
            _vestingFrequency = 30;
        } else if (_vaultToInit == VaultEnumerator.ADVISOR) {
            if (advisorVaultAddress != address(0)) {
                revert AlreadyInitialized();
            }
            advisorVaultAddress = _vaultAddress;
            _vaultName = "Advisor Vault";
            _vaultShare = advisorShare;
            _initialRelease = 0;
            _vestingStartDate = _initialReleaseDate + 365 days;
            _vestingCount = 24;
            _vestingFrequency = 30;
        } else if (_vaultToInit == VaultEnumerator.TEAM) {
            if (teamVaultAddress != address(0)) {
                revert AlreadyInitialized();
            }
            teamVaultAddress = _vaultAddress;
            _vaultName = "Team Vault";
            _vaultShare = teamShare;
            _initialRelease = 0;
            _vestingStartDate = _initialReleaseDate + 365 days;
            _vestingCount = 24;
            _vestingFrequency = 30;
        } else if (_vaultToInit == VaultEnumerator.TREASURY) {
            if (treasuryVaultAddress != address(0)) {
                revert AlreadyInitialized();
            }
            treasuryVaultAddress = _vaultAddress;
            _vaultName = "Treasury Vault";
            _vaultShare = treasuryShare;
            _initialRelease = 0;
            _vestingStartDate = _initialReleaseDate + 90 days;
            _vestingCount = 48;
            _vestingFrequency = 30;
        } else if (_vaultToInit == VaultEnumerator.AIRDROP) {
            if (airdropVaultAddress != address(0)) {
                revert AlreadyInitialized();
            }
            airdropVaultAddress = _vaultAddress;
            _vaultName = "Airdrop Vault";
            _vaultShare = airdropShare;
            _initialRelease = 0;
            _vestingStartDate = _initialReleaseDate + 240 days;
            _vestingCount = 12;
            _vestingFrequency = 30;
        } else if (_vaultToInit == VaultEnumerator.STAKING) {
            if (stakingVaultAddress != address(0)) {
                revert AlreadyInitialized();
            }
            stakingVaultAddress = _vaultAddress;
            _vaultName = "Staking Vault";
            _vaultShare = stakingShare;
            _initialRelease = 0;
            _vestingStartDate = _initialReleaseDate + 90 days;
            _vestingCount = 6;
            _vestingFrequency = 90;
        } else {
            revert InvalidVaultIndex();
        }

        soulsToken.approve(_vaultAddress, _vaultShare);
        IVault _vault = IVault(_vaultAddress);
        _vault.createVestings(
            _vaultShare,
            _initialRelease,
            _initialReleaseDate,
            _vestingCount,
            _vestingStartDate,
            _vestingFrequency
        );
        managers.addAddressToTrustedSources(_vaultAddress, _vaultName);
    }

    //Managers Function
    function withdrawLPTokens(address _to) external onlyManager {
        if (block.timestamp < liquidityTokensUnlockTime) {
            revert StillLocked();
        }
        if (dexPairAddress == address(0)) {
            revert LiquidityVaultNotInitialized();
        }
        if (_to == address(0)) {
            revert ZeroAddress();
        }
        uint256 _tokenBalance = IERC20(dexPairAddress).balanceOf(address(this));
        if (_tokenBalance == 0) {
            revert ZeroBalanceOfLP();
        }

        string memory _title = "Withdraw LP Tokens";
        bytes memory _encodedValues = abi.encode(_to);
        managers.approveTopic(_title, _encodedValues);

        if (managers.isApproved(_title, _encodedValues)) {
            IERC20(dexPairAddress).safeTransfer(_to, _tokenBalance);
            managers.deleteTopic(_title);
        }
    }

    //Managers Function
    function addAddressToTrustedSources(address _address, string calldata _name) external onlyManager {
        if (managers.isManager(_address)) {
            revert ManagerAddressCannotBeAddedToTrustedSources();
        }
        if (bytes(_name).length == 0) {
            revert EmptyNameString();
        }
        string memory _title = "Add To Trusted Sources";
        bytes memory _encodedValues = abi.encode(_address, _name);
        managers.approveTopic(_title, _encodedValues);

        bool _isApproved = managers.isApproved(_title, _encodedValues);
        if (_isApproved) {
            managers.addAddressToTrustedSources(_address, _name);
            managers.deleteTopic(_title);
        }
        emit AddAddressToTrustedSources(msg.sender, _address, _name, _isApproved);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IManagers.sol";
import "./interfaces/IBotPrevention.sol";

contract SoulsToken is ERC20, Ownable {
    //Storage Variables
    IBotPrevention botPrevention;
    IManagers managers;

    uint256 public constant maxSupply = 3000000000 ether;

    bool public botPreventionEnabled = true;

    //Custom Errors
    error BotPreventionError();
    error AlreadyDisabled();
    error AlreadyEnabled();
    error NotAuthorized();

    //Events
    event DisableBotPrevention(address manager, bool isApproved);
    event EnableBotPrevention(address manager, bool isApproved);

    constructor(
        string memory _name,
        string memory _symbol,
        address _managers,
        address _botPrevention
    ) ERC20(_name, _symbol) {
        botPrevention = IBotPrevention(_botPrevention);
        managers = IManagers(_managers);
        _mint(msg.sender, maxSupply);
    }

    modifier onlyManager() {
        if (!managers.isManager(msg.sender)) {
            revert NotAuthorized();
        }
        _;
    }

    function disableBotPrevention() external onlyManager {
        if (!botPreventionEnabled) {
            revert AlreadyDisabled();
        }
        string memory _title = "Set Bot Prevention Status";
        bytes memory _encodedValues = abi.encode(0);
        managers.approveTopic(_title, _encodedValues);
        bool _isApproved = managers.isApproved(_title, _encodedValues);
        if (_isApproved) {
            botPreventionEnabled = false;
            managers.deleteTopic(_title);
        }
        emit DisableBotPrevention(msg.sender, _isApproved);
    }

    function enableBotPrevention() external onlyManager {
        if (botPreventionEnabled) {
            revert AlreadyEnabled();
        }
        string memory _title = "Set Bot Prevention Status";
        bytes memory _encodedValues = abi.encode(0);
        managers.approveTopic(_title, _encodedValues);
        bool _isApproved = managers.isApproved(_title, _encodedValues);
        if (_isApproved) {
            botPreventionEnabled = true;
            managers.deleteTopic(_title);
            botPrevention.resetBotPreventionData();
        }
        emit EnableBotPrevention(msg.sender, _isApproved);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal view override {
        if (botPreventionEnabled && from != address(0)) {
            if (!managers.isManager(tx.origin) || !managers.isTrustedSource(msg.sender)) {
                if (!botPrevention.beforeTokenTransfer(from, to, amount)) {
                    revert BotPreventionError();
                }
            }
        }
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override {
        if (botPreventionEnabled && from != address(0)) {
            if (!managers.isManager(tx.origin) || !managers.isTrustedSource(msg.sender)) {
                if (!botPrevention.afterTokenTransfer(from, to, amount)) {
                    revert BotPreventionError();
                }
            }
        }
    }
}