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

/*
    Copyright 2017-2019 Phillip A. Elsasser

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/// @title Math function library with overflow protection inspired by Open Zeppelin
library MathLib {

    int256 constant INT256_MIN = int256((uint256(1) << 255));
    int256 constant INT256_MAX = int256(~((uint256(1) << 255)));

    function multiply(uint256 a, uint256 b) pure internal returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b,  "MathLib: multiplication overflow");

        return c;
    }

    function divideFractional(
        uint256 a,
        uint256 numerator,
        uint256 denominator
    ) pure internal returns (uint256)
    {
        return multiply(a, numerator) / denominator;
    }

    function subtract(uint256 a, uint256 b) pure internal returns (uint256) {
        require(b <= a, "MathLib: subtraction overflow");
        return a - b;
    }

    function add(uint256 a, uint256 b) pure internal returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "MathLib: addition overflow");
        return c;
    }

    /// @notice determines the amount of needed collateral for a given position (qty and price)
    /// @param priceFloor lowest price the contract is allowed to trade before expiration
    /// @param priceCap highest price the contract is allowed to trade before expiration
    /// @param qtyMultiplier multiplier for qty from base units
    /// @param longQty qty to redeem
    /// @param shortQty qty to redeem
    /// @param price of the trade
    function calculateCollateralToReturn(
        uint priceFloor,
        uint priceCap,
        uint qtyMultiplier,
        uint longQty,
        uint shortQty,
        uint price
    ) pure internal returns (uint)
    {
        uint neededCollateral = 0;
        uint maxLoss;
        if (longQty > 0) {   // calculate max loss from entry price to floor
            if (price <= priceFloor) {
                maxLoss = 0;
            } else {
                maxLoss = subtract(price, priceFloor);
            }
            neededCollateral = multiply(multiply(maxLoss, longQty),  qtyMultiplier);
        }

        if (shortQty > 0) {  // calculate max loss from entry price to ceiling;
            if (price >= priceCap) {
                maxLoss = 0;
            } else {
                maxLoss = subtract(priceCap, price);
            }
            neededCollateral = add(neededCollateral, multiply(multiply(maxLoss, shortQty),  qtyMultiplier));
        }
        return neededCollateral;
    }

    /// @notice determines the amount of needed collateral for minting a long and short position token
    function calculateTotalCollateral(
        uint priceFloor,
        uint priceCap,
        uint qtyMultiplier
    ) pure internal returns (uint)
    {
        return multiply(subtract(priceCap, priceFloor), qtyMultiplier);
    }

    /// @notice calculates the fee in terms of base units of the collateral token per unit pair minted.
    function calculateFeePerUnit(
        uint priceFloor,
        uint priceCap,
        uint qtyMultiplier,
        uint feeInBasisPoints
    ) pure internal returns (uint)
    {
        uint midPrice = add(priceCap, priceFloor) / 2;
        return multiply(multiply(midPrice, qtyMultiplier), feeInBasisPoints) / 10000;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library StringLib {

    /// @notice converts bytes32 into a string.
    /// @param bytesToConvert bytes32 array to convert
    function bytes32ToString(bytes32 bytesToConvert) internal pure returns (string memory) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = bytesToConvert[i];
        }
        return string(bytesArray);
    }
}

/*
    Copyright 2017-2019 Phillip A. Elsasser

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/MathLib.sol";
import "./MarketContract.sol";
import "./tokens/PositionToken.sol";
import "./MarketContractRegistryInterface.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/// @title MarketCollateralPool
/// @notice This collateral pool houses all of the collateral for all market contracts currently in circulation.
/// This pool facilitates locking of collateral and minting / redemption of position tokens for that collateral.
/// @author Phil Elsasser <[email protected]>
contract MarketCollateralPool is Ownable {
    using MathLib for uint;
    using MathLib for int;
    using SafeERC20 for ERC20;

    address public marketContractRegistry;
    address public mktToken;

    mapping(address => uint) public contractAddressToCollateralPoolBalance;                 // current balance of all collateral committed
    mapping(address => uint) public feesCollectedByTokenAddress;

    event TokensMinted(
        address indexed marketContract,
        address indexed user,
        address indexed feeToken,
        uint qtyMinted,
        uint collateralLocked,
        uint feesPaid
    );

    event TokensRedeemed (
        address indexed marketContract,
        address indexed user,
        uint longQtyRedeemed,
        uint shortQtyRedeemed,
        uint collateralUnlocked
    );

    constructor(address marketContractRegistryAddress, address mktTokenAddress) {
        marketContractRegistry = marketContractRegistryAddress;
        mktToken = mktTokenAddress;
    }

    /*
    // EXTERNAL METHODS
    */

    /// @notice Called by a user that would like to mint a new set of long and short token for a specified
    /// market contract.  This will transfer and lock the correct amount of collateral into the pool
    /// and issue them the requested qty of long and short tokens
    /// @param marketContractAddress            address of the market contract to redeem tokens for
    /// @param qtyToMint                      quantity of long / short tokens to mint.
    /// @param isAttemptToPayInMKT            if possible, attempt to pay fee's in MKT rather than collateral tokens
    function mintPositionTokens(
        address marketContractAddress,
        uint qtyToMint,
        bool isAttemptToPayInMKT
    ) external onlyWhiteListedAddress(marketContractAddress)
    {

        MarketContract marketContract = MarketContract(marketContractAddress);
        require(!marketContract.isSettled(), "Contract is already settled");

        address collateralTokenAddress = marketContract.COLLATERAL_TOKEN_ADDRESS();
        uint neededCollateral = MathLib.multiply(qtyToMint, marketContract.COLLATERAL_PER_UNIT());
        // the user has selected to pay fees in MKT and those fees are non zero (allowed) OR
        // the user has selected not to pay fees in MKT, BUT the collateral token fees are disabled (0) AND the
        // MKT fees are enabled (non zero).  (If both are zero, no fee exists)
        bool isPayFeesInMKT = (isAttemptToPayInMKT &&
            marketContract.MKT_TOKEN_FEE_PER_UNIT() != 0) ||
            (!isAttemptToPayInMKT &&
            marketContract.MKT_TOKEN_FEE_PER_UNIT() != 0 &&
            marketContract.COLLATERAL_TOKEN_FEE_PER_UNIT() == 0);

        uint feeAmount;
        uint totalCollateralTokenTransferAmount;
        address feeToken;
        if (isPayFeesInMKT) { // fees are able to be paid in MKT
            feeAmount = MathLib.multiply(qtyToMint, marketContract.MKT_TOKEN_FEE_PER_UNIT());
            totalCollateralTokenTransferAmount = neededCollateral;
            feeToken = mktToken;

            // EXTERNAL CALL - transferring ERC20 tokens from sender to this contract.  User must have called
            // ERC20.approve in order for this call to succeed.
            ERC20(mktToken).safeTransferFrom(msg.sender, address(this), feeAmount);
        } else { // fee are either zero, or being paid in the collateral token
            feeAmount = MathLib.multiply(qtyToMint, marketContract.COLLATERAL_TOKEN_FEE_PER_UNIT());
            totalCollateralTokenTransferAmount = neededCollateral.add(feeAmount);
            feeToken = collateralTokenAddress;
            // we will transfer collateral and fees all at once below.
        }

        // EXTERNAL CALL - transferring ERC20 tokens from sender to this contract.  User must have called
        // ERC20.approve in order for this call to succeed.
        ERC20(marketContract.COLLATERAL_TOKEN_ADDRESS()).safeTransferFrom(msg.sender, address(this), totalCollateralTokenTransferAmount);

        if (feeAmount != 0) {
            // update the fee's collected balance
            feesCollectedByTokenAddress[feeToken] = feesCollectedByTokenAddress[feeToken].add(feeAmount);
        }

        // Update the collateral pool locked balance.
        contractAddressToCollateralPoolBalance[marketContractAddress] = contractAddressToCollateralPoolBalance[
            marketContractAddress
        ].add(neededCollateral);

        // mint and distribute short and long position tokens to our caller
        marketContract.mintPositionTokens(qtyToMint, msg.sender);

        emit TokensMinted(
            marketContractAddress,
            msg.sender,
            feeToken,
            qtyToMint,
            neededCollateral,
            feeAmount
        );
    }

    /// @notice Called by a user that currently holds both short and long position tokens and would like to redeem them
    /// for their collateral.
    /// @param marketContractAddress            address of the market contract to redeem tokens for
    /// @param qtyToRedeem                      quantity of long / short tokens to redeem.
    function redeemPositionTokens(
        address marketContractAddress,
        uint qtyToRedeem
    ) external onlyWhiteListedAddress(marketContractAddress)
    {
        MarketContract marketContract = MarketContract(marketContractAddress);

        marketContract.redeemLongToken(qtyToRedeem, msg.sender);
        marketContract.redeemShortToken(qtyToRedeem, msg.sender);

        // calculate collateral to return and update pool balance
        uint collateralToReturn = MathLib.multiply(qtyToRedeem, marketContract.COLLATERAL_PER_UNIT());
        contractAddressToCollateralPoolBalance[marketContractAddress] = contractAddressToCollateralPoolBalance[
            marketContractAddress
        ].subtract(collateralToReturn);

        // EXTERNAL CALL
        // transfer collateral back to user
        ERC20(marketContract.COLLATERAL_TOKEN_ADDRESS()).safeTransfer(msg.sender, collateralToReturn);

        emit TokensRedeemed(
            marketContractAddress,
            msg.sender,
            qtyToRedeem,
            qtyToRedeem,
            collateralToReturn
        );
    }

    // @notice called by a user after settlement has occurred.  This function will finalize all accounting around any
    // outstanding positions and return all remaining collateral to the caller. This should only be called after
    // settlement has occurred.
    /// @param marketContractAddress address of the MARKET Contract being traded.
    /// @param longQtyToRedeem qty to redeem of long tokens
    /// @param shortQtyToRedeem qty to redeem of short tokens
    function settleAndClose(
        address marketContractAddress,
        uint longQtyToRedeem,
        uint shortQtyToRedeem
    ) external onlyWhiteListedAddress(marketContractAddress)
    {
        MarketContract marketContract = MarketContract(marketContractAddress);
        require(marketContract.isPostSettlementDelay(), "Contract is not past settlement delay");

        // burn tokens being redeemed.
        if (longQtyToRedeem > 0) {
            marketContract.redeemLongToken(longQtyToRedeem, msg.sender);
        }

        if (shortQtyToRedeem > 0) {
            marketContract.redeemShortToken(shortQtyToRedeem, msg.sender);
        }


        // calculate amount of collateral to return and update pool balances
        uint collateralToReturn = 0;
        

        contractAddressToCollateralPoolBalance[marketContractAddress] = contractAddressToCollateralPoolBalance[
            marketContractAddress
        ].subtract(collateralToReturn);

        // return collateral tokens
        ERC20(marketContract.COLLATERAL_TOKEN_ADDRESS()).safeTransfer(msg.sender, collateralToReturn);

        emit TokensRedeemed(
            marketContractAddress,
            msg.sender,
            longQtyToRedeem,
            shortQtyToRedeem,
            collateralToReturn
        );
    }

    /// @dev allows the owner to remove the fees paid into this contract for minting
    /// @param feeTokenAddress - address of the erc20 token fees have been paid in
    /// @param feeRecipient - Recipient address of fees
    function withdrawFees(address feeTokenAddress, address feeRecipient) public onlyOwner {
        uint feesAvailableForWithdrawal = feesCollectedByTokenAddress[feeTokenAddress];
        require(feesAvailableForWithdrawal != 0, "No fees available for withdrawal");
        require(feeRecipient != address(0), "Cannot send fees to null address");
        feesCollectedByTokenAddress[feeTokenAddress] = 0;
        // EXTERNAL CALL
        ERC20(feeTokenAddress).safeTransfer(feeRecipient, feesAvailableForWithdrawal);
    }

    /// @dev allows the owner to update the mkt token address in use for fees
    /// @param mktTokenAddress address of new MKT token
    function setMKTTokenAddress(address mktTokenAddress) public onlyOwner {
        require(mktTokenAddress != address(0), "Cannot set MKT Token Address To Null");
        mktToken = mktTokenAddress;
    }

    /// @dev allows the owner to update the mkt token address in use for fees
    /// @param marketContractRegistryAddress address of new contract registry
    function setMarketContractRegistryAddress(address marketContractRegistryAddress) public onlyOwner {
        require(marketContractRegistryAddress != address(0), "Cannot set Market Contract Registry Address To Null");
        marketContractRegistry = marketContractRegistryAddress;
    }

    /*
    // MODIFIERS
    */

    /// @notice only can be called with a market contract address that currently exists in our whitelist
    /// this ensure's it is a market contract that has been created by us and therefore has a uniquely created
    /// long and short token address.  If it didn't we could have spoofed contracts minting tokens with a
    /// collateral token that wasn't the same as the intended token.
    modifier onlyWhiteListedAddress(address marketContractAddress) {
        require(
            MarketContractRegistryInterface(marketContractRegistry).isAddressWhiteListed(marketContractAddress),
            "Contract is not whitelisted"
        );
        _;
    }
}

/*
    Copyright 2017-2019 Phillip A. Elsasser

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// import "./libraries/MathLib.sol";
import "./libraries/StringLib.sol";
import "./tokens/PositionToken.sol";


/// @title MarketContract base contract implement all needed functionality for trading.
/// @notice this is the abstract base contract that all contracts should inherit from to
/// implement different oracle solutions.
/// @author Phil Elsasser <[email protected]>
contract MarketContract is Ownable {
    using StringLib for *;

    string public CONTRACT_NAME;
    address public COLLATERAL_TOKEN_ADDRESS;
    address public COLLATERAL_POOL_ADDRESS;
    int public GEOSTATS_CAP;
    int public GEOSTATS_FLOOR;
    uint public GEOSTATS_DECIMAL_PLACES;   // how to convert the geostats from decimal format (if valid) to integer
    // uint public QTY_MULTIPLIER;         // multiplier corresponding to the value of 1 increment in price to token base units
    uint public COLLATERAL_PER_UNIT;    // required collateral amount for the full range of outcome tokens
    uint public COLLATERAL_TOKEN_FEE_PER_UNIT;
    uint public MKT_TOKEN_FEE_PER_UNIT;
    uint public EXPIRATION;
    uint public SETTLEMENT_DELAY = 1 days;
    address public LONG_POSITION_TOKEN;
    address public SHORT_POSITION_TOKEN;

    // state variables
    int public lastGeostats;
    int public settlementGeostats;
    uint public settlementTimeStamp;
    bool public isSettled = false;

    // events
    event UpdatedLastGeostats(int256 geostats);
    event ContractSettled(int settleGeostats);

    /// @param contractNames bytes32 array of names
    ///     contractName            name of the market contract
    ///     longTokenSymbol         symbol for the long token
    ///     shortTokenSymbol        symbol for the short token
    /// @param baseAddresses array of 2 addresses needed for our contract including:
    ///     ownerAddress                    address of the owner of these contracts.
    ///     collateralTokenAddress          address of the ERC20 token that will be used for collateral and pricing
    ///     collateralPoolAddress           address of our collateral pool contract
   
    ///     floorPrice          minimum tradeable price of this contract, contract enters settlement if breached
    ///     capPrice            maximum tradeable price of this contract, contract enters settlement if breached
    ///     priceDecimalPlaces  number of decimal places to convert our queried price from a floating point to
    ///                         an integer
    ///     qtyMultiplier       multiply traded qty by this value from base units of collateral token.
    ///     feeInBasisPoints    fee amount in basis points (Collateral token denominated) for minting.
    ///     mktFeeInBasisPoints fee amount in basis points (MKT denominated) for minting.
    ///     expirationTimeStamp seconds from epoch that this contract expires and enters settlement
    constructor(
        bytes32[3] memory contractNames,
        address[3] memory baseAddresses,
        int geostatsFloor,
        int geostatsCap,
        uint geostatsDecimalPlaces,
        uint expiration
    ) 
    {
        GEOSTATS_FLOOR = geostatsFloor;
        GEOSTATS_CAP = geostatsCap;
        require(GEOSTATS_CAP > GEOSTATS_FLOOR, "GEOSTATS_CAP must be greater than GEOSTATS_FLOOR");

        GEOSTATS_DECIMAL_PLACES = geostatsDecimalPlaces;
        // COLLATERAL_PER_UNIT = contractSpecs[1];
        EXPIRATION = expiration;
        require(EXPIRATION > block.timestamp, "EXPIRATION must be in the future");
        //require(QTY_MULTIPLIER != 0,"QTY_MULTIPLIER cannot be 0");

        COLLATERAL_TOKEN_ADDRESS = baseAddresses[1];
        COLLATERAL_POOL_ADDRESS = baseAddresses[2];
        // COLLATERAL_PER_UNIT = QTY_MULTIPLIER;
        COLLATERAL_TOKEN_FEE_PER_UNIT = 0;
        MKT_TOKEN_FEE_PER_UNIT = 0;

        // create long and short tokens
        CONTRACT_NAME = contractNames[0].bytes32ToString();
        PositionToken longPosToken = new PositionToken(
            "MARKET Protocol Long Position Token",
            contractNames[1].bytes32ToString(),
            uint8(PositionToken.MarketSide.Long)
        );
        PositionToken shortPosToken = new PositionToken(
            "MARKET Protocol Short Position Token",
            contractNames[2].bytes32ToString(),
            uint8(PositionToken.MarketSide.Short)
        );

        LONG_POSITION_TOKEN = address(longPosToken);
        SHORT_POSITION_TOKEN = address(shortPosToken);

        transferOwnership(baseAddresses[0]);
    }

    /*
    // EXTERNAL - onlyCollateralPool METHODS
    */

    /// @notice called only by our collateral pool to create long and short position tokens
    /// @param qtyToMint    qty in base units of how many short and long tokens to mint
    /// @param minter       address of minter to receive tokens
    function mintPositionTokens(
        uint256 qtyToMint,
        address minter
    ) external onlyCollateralPool
    {
        // mint and distribute short and long position tokens to our caller
        PositionToken(LONG_POSITION_TOKEN).mintAndSendToken(qtyToMint, minter);
        PositionToken(SHORT_POSITION_TOKEN).mintAndSendToken(qtyToMint, minter);
    }

    /// @notice called only by our collateral pool to redeem long position tokens
    /// @param qtyToRedeem  qty in base units of how many tokens to redeem
    /// @param redeemer     address of person redeeming tokens
    function redeemLongToken(
        uint256 qtyToRedeem,
        address redeemer
    ) external onlyCollateralPool
    {
        // mint and distribute short and long position tokens to our caller
        PositionToken(LONG_POSITION_TOKEN).redeemToken(qtyToRedeem, redeemer);
    }

    /// @notice called only by our collateral pool to redeem short position tokens
    /// @param qtyToRedeem  qty in base units of how many tokens to redeem
    /// @param redeemer     address of person redeeming tokens
    function redeemShortToken(
        uint256 qtyToRedeem,
        address redeemer
    ) external onlyCollateralPool
    {
        // mint and distribute short and long position tokens to our caller
        PositionToken(SHORT_POSITION_TOKEN).redeemToken(qtyToRedeem, redeemer);
    }

    /*
    // Public METHODS
    */

    /// @notice checks to see if a contract is settled, and that the settlement delay has passed
    function isPostSettlementDelay() public view returns (bool) {
        return isSettled && (block.timestamp >= (settlementTimeStamp + SETTLEMENT_DELAY));
    }

    /*
    // PRIVATE METHODS
    */

    /// @dev checks our last query price to see if our contract should enter settlement due to it being past our
    //  expiration date or outside of our tradeable ranges.
    function checkSettlement() internal {
        require(!isSettled, "Contract is already settled"); // already settled.

        int newSettlementGeostats;
        if (block.timestamp > EXPIRATION) {  // note: miners can cheat this by small increments of time (minutes, not hours)
            isSettled = true;                   // time based expiration has occurred.
            newSettlementGeostats = lastGeostats;
        } else if (lastGeostats >= GEOSTATS_CAP) {    // geostats is greater or equal to our cap, settle to CAP geostats
            isSettled = true;
            newSettlementGeostats = GEOSTATS_CAP;
        } else if (lastGeostats <= GEOSTATS_FLOOR) {  // geostats is lesser or equal to our floor, settle to FLOOR geostats
            isSettled = true;
            newSettlementGeostats = GEOSTATS_FLOOR;
        }

        if (isSettled) {
            settleContract(newSettlementGeostats);
        }
    }

    /// @dev records our final settlement price and fires needed events.
    /// @param finalSettlementGeostats final query price at time of settlement
    function settleContract(int finalSettlementGeostats) internal {
        settlementTimeStamp = block.timestamp;
        settlementGeostats = finalSettlementGeostats;
        emit ContractSettled(finalSettlementGeostats);
    }

    /// @notice only able to be called directly by our collateral pool which controls the position tokens
    /// for this contract!
    modifier onlyCollateralPool {
        require(msg.sender == COLLATERAL_POOL_ADDRESS, "Only callable from the collateral pool");
        _;
    }

}

/*
    Copyright 2017-2019 Phillip A. Elsasser

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


abstract contract MarketContractRegistryInterface {
    function addAddressToWhiteList(address contractAddress) virtual external;
    function isAddressWhiteListed(address contractAddress) virtual external view returns (bool);
}

/*
    Copyright 2017-2019 Phillip A. Elsasser

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/// @title Position Token
/// @notice A token that represents a claim to a collateral pool and a short or long position.
/// The collateral pool acts as the owner of this contract and controls minting and redemption of these
/// tokens based on locked collateral in the pool.
/// NOTE: We eventually can move all of this logic into a library to avoid deploying all of the logic
/// every time a new market contract is deployed.
/// @author Phil Elsasser <[email protected]>
contract PositionToken is ERC20, Ownable {

    string _name;
    string _symbol;
    uint8 _decimals;

    MarketSide public MARKET_SIDE; // 0 = Long, 1 = Short
    enum MarketSide { Long, Short}

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 marketSide
    ) ERC20(tokenName, tokenSymbol)
    {
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = 5;
        MARKET_SIDE = MarketSide(marketSide);
    }

    /// @dev Called by our MarketContract (owner) to create a long or short position token. These tokens are minted,
    /// and then transferred to our recipient who is the party who is minting these tokens.  The collateral pool
    /// is the only caller (acts as the owner) because collateral must be deposited / locked prior to minting of new
    /// position tokens
    /// @param qtyToMint quantity of position tokens to mint (in base units)
    /// @param recipient the person minting and receiving these position tokens.
    function mintAndSendToken(
        uint256 qtyToMint,
        address recipient
    ) external onlyOwner
    {
        _mint(recipient, qtyToMint);
    }

    /// @dev Called by our MarketContract (owner) when redemption occurs.  This means that either a single user is redeeming
    /// both short and long tokens in order to claim their collateral, or the contract has settled, and only a single
    /// side of the tokens are needed to redeem (handled by the collateral pool)
    /// @param qtyToRedeem quantity of tokens to burn (remove from supply / circulation)
    /// @param redeemer the person redeeming these tokens (who are we taking the balance from)
    function redeemToken(
        uint256 qtyToRedeem,
        address redeemer
    ) external onlyOwner
    {
        _burn(redeemer, qtyToRedeem);
    }
}