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

//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IBastionV3} from "./interfaces/IBastionV3.sol";
import {IFlashLiquidityFactory} from "./interfaces/IFlashLiquidityFactory.sol";
import {IFlashLiquidityRouter} from "./interfaces/IFlashLiquidityRouter.sol";
import {IFlashLiquidityPair} from "./interfaces/IFlashLiquidityPair.sol";
import {ILiquidFarm} from "./interfaces/ILiquidFarm.sol";
import {ILiquidFarmFactory} from "./interfaces/ILiquidFarmFactory.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Guardable} from "./types/Guardable.sol";
import {FullMath} from "./libraries/FullMath.sol";

contract BastionV3 is IBastionV3, Guardable {
    using SafeERC20 for IERC20;

    address public immutable factory;
    address public immutable router;
    address public immutable farmFactory;
    IWETH public immutable weth;
    uint256 public maxDeviationFactor;
    uint256 public maxStaleness;
    uint256 public whitelistDelay = 3 days;
    mapping(address => bool) public isExtManagerSetter;
    mapping(address => bool) public isWhitelisted;
    mapping(address => uint256) public whitelistReqTimestamp;
    mapping(address => AggregatorV3Interface) internal priceFeeds;
    mapping(address => uint256) internal tokenDecimals;

    error AlreadyWhitelisted();
    error AlreadyRequested();
    error WhitelistingNotRequested();
    error NotWhitelisted();
    error NotManagerSetter();
    error CannotConvert();
    error ZeroAmount();
    error InvalidPrice();
    error InvalidPair();
    error InvalidFarm();
    error AmountOutTooLow();
    error ReservesValuesMismatch();
    error MissingPriceFeed();
    error DecimalsMismatch();
    error StalenessToHigh();

    event DeviatonFactorChanged(uint256 indexed newFactor);
    event StalenessChanged(uint256 indexed newStaleness);
    event ExtManagerSettersChanged(address[] indexed setters, bool[] indexed isSetter);
    event PriceFeedsChanged(address[] indexed tokens, address[] indexed priceFeeds);
    event TokensDecimalsChanged(address[] indexed tokens, uint256[] indexed decimals);
    event TokensTransferred(
        address indexed recipient,
        address[] indexed tokens,
        uint256[] indexed amounts
    );

    event Swapped(address indexed tokenA, address indexed tokenB, uint256 amountA, uint256 amountB);

    event Liquefied(
        address indexed token0,
        address indexed token1,
        uint256 token0Amount,
        uint256 token1Amount
    );

    event Solidified(
        address indexed token0,
        address indexed token1,
        uint256 token0Amount,
        uint256 token1Amount
    );

    event Staked(address indexed lpToken, uint256 indexed amount);
    event Unstaked(address indexed lpToken, uint256 indexed amount);
    event ClaimedRewards(address indexed farm, address indexed lpToken);
    event UnstakedAndClaimed(address indexed farm, address indexed lpToken);

    constructor(
        address _governor,
        address _factory,
        address _router,
        address _farmFactory,
        IWETH _weth,
        uint256 _maxDeviationFactor,
        uint256 _maxStaleness,
        uint256 _transferGovernanceDelay
    ) Guardable(_governor, _transferGovernanceDelay) {
        factory = _factory;
        router = _router;
        farmFactory = _farmFactory;
        weth = _weth;
        maxDeviationFactor = _maxDeviationFactor;
        maxStaleness = _maxStaleness;
    }

    receive() external payable {}

    function requestWhitelisting(address[] calldata _recipients)
        external
        onlyGuardian
        whenNotPaused
    {
        for (uint256 i = 0; i < _recipients.length; ) {
            if (isWhitelisted[_recipients[i]]) {
                revert AlreadyWhitelisted();
            }
            if (whitelistReqTimestamp[_recipients[i]] != 0) {
                revert AlreadyRequested();
            }
            whitelistReqTimestamp[_recipients[i]] = block.timestamp;
            unchecked {
                i++;
            }
        }
    }

    function abortWhitelisting(address[] calldata _recipients) external onlyGovernor {
        for (uint256 i = 0; i < _recipients.length; ) {
            if (isWhitelisted[_recipients[i]]) {
                revert AlreadyWhitelisted();
            }
            if (whitelistReqTimestamp[_recipients[i]] == 0) {
                revert WhitelistingNotRequested();
            }
            whitelistReqTimestamp[_recipients[i]] = 0;
            unchecked {
                i++;
            }
        }
    }

    function executeWhitelisting(address[] calldata _recipients)
        external
        onlyGovernor
        whenNotPaused
    {
        uint256 _whitelistDelay = whitelistDelay;
        for (uint256 i = 0; i < _recipients.length; ) {
            uint256 _timestamp = whitelistReqTimestamp[_recipients[i]];
            if (isWhitelisted[_recipients[i]]) {
                revert AlreadyWhitelisted();
            }
            if (whitelistReqTimestamp[_recipients[i]] == 0) {
                revert WhitelistingNotRequested();
            }
            if (block.timestamp - _timestamp < _whitelistDelay) {
                revert TooEarly();
            }
            isWhitelisted[_recipients[i]] = true;
            whitelistReqTimestamp[_recipients[i]] = 0;
            unchecked {
                i++;
            }
        }
    }

    function removeFromWhitelist(address[] calldata _recipients) external onlyGovernor {
        for (uint256 i = 0; i < _recipients.length; ) {
            if (!isWhitelisted[_recipients[i]]) {
                revert NotWhitelisted();
            }
            isWhitelisted[_recipients[i]] = false;
            unchecked {
                i++;
            }
        }
    }

    function transferToWhitelisted(
        address _recipient,
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external onlyGovernor whenNotPaused {
        if (!isWhitelisted[_recipient]) {
            revert NotWhitelisted();
        }
        for (uint256 i = 0; i < _tokens.length; ) {
            IERC20(_tokens[i]).safeTransfer(_recipient, _amounts[i]);
            unchecked {
                i++;
            }
        }
        emit TokensTransferred(_recipient, _tokens, _amounts);
    }

    function setMaxDeviationFactor(uint256 _maxDeviationFactor) external onlyGovernor {
        maxDeviationFactor = _maxDeviationFactor;
        emit DeviatonFactorChanged(_maxDeviationFactor);
    }

    function setMaxStaleness(uint256 _maxStaleness) external onlyGovernor {
        maxStaleness = _maxStaleness;
        emit StalenessChanged(_maxStaleness);
    }

    function setPairManager(address _pair, address _manager) public {
        if (!isExtManagerSetter[msg.sender]) {
            revert NotManagerSetter();
        }
        IFlashLiquidityFactory(factory).setPairManager(_pair, _manager);
    }

    function setMainManagerSetter(address _managerSetter) external onlyGovernor {
        IFlashLiquidityFactory(factory).setPairManagerSetter(_managerSetter);
    }

    function setExtManagerSetters(address[] calldata _extManagerSetters, bool[] calldata _enabled)
        external
        onlyGovernor
    {
        for (uint256 i = 0; i < _extManagerSetters.length; ) {
            isExtManagerSetter[_extManagerSetters[i]] = _enabled[i];
            unchecked {
                i++;
            }
        }
        emit ExtManagerSettersChanged(_extManagerSetters, _enabled);
    }

    function setPriceFeeds(address[] calldata _tokens, address[] calldata _priceFeeds)
        external
        onlyGovernor
    {
        for (uint256 i = 0; i < _tokens.length; ) {
            priceFeeds[_tokens[i]] = AggregatorV3Interface(_priceFeeds[i]);
            unchecked {
                i++;
            }
        }
        emit PriceFeedsChanged(_tokens, _priceFeeds);
    }

    function setTokensDecimals(address[] calldata _tokens, uint256[] calldata _decimals)
        external
        onlyGovernor
    {
        for (uint256 i = 0; i < _tokens.length; ) {
            tokenDecimals[_tokens[i]] = _decimals[i];
            unchecked {
                i++;
            }
        }
        emit TokensDecimalsChanged(_tokens, _decimals);
    }

    function wrapETH(uint256 _amount) external onlyGovernor {
        weth.deposit{value: _amount}();
    }

    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external onlyGovernor whenNotPaused {
        IFlashLiquidityFactory _factory = IFlashLiquidityFactory(factory);
        IFlashLiquidityPair _pair = IFlashLiquidityPair(_factory.getPair(_tokenIn, _tokenOut));
        if (address(_pair) == address(0)) {
            revert CannotConvert();
        }
        address _manager = _pair.manager();
        if (_manager != address(0)) {
            _swapOnSelfBalancingPool(_factory, _pair, _manager, _tokenIn, _tokenOut, _amountIn);
        } else {
            _swapOnOpenPool(_pair, _tokenIn, _tokenOut, _amountIn);
        }
    }

    function liquefy(
        address _token0,
        address _token1,
        uint256 _token0Amount,
        uint256 _token1Amount
    ) external onlyGovernor whenNotPaused {
        address manager = IFlashLiquidityPair(
            IFlashLiquidityFactory(factory).getPair(_token0, _token1)
        ).manager();
        if (manager != address(0)) {
            _liquefyOnSelfBalancingPool(_token0, _token1, _token0Amount, _token1Amount);
        } else {
            _liquefyOnOpenPool(_token0, _token1, _token0Amount, _token1Amount);
        }
    }

    function solidify(address _lpToken, uint256 _lpAmount) external onlyGovernor whenNotPaused {
        address _router = router;
        IFlashLiquidityPair _pair = IFlashLiquidityPair(_lpToken);
        _pair.approve(_router, _lpAmount);
        if (_pair.manager() != address(0)) {
            _solidifyFromSelfBalancingPool(_pair, _router, _lpAmount);
        } else {
            _solidifyFromOpenPool(_pair, _router, _lpAmount);
        }
        _pair.approve(_router, 0);
    }

    function stakeLpTokens(address _lpToken, uint256 _amount) external onlyGovernor whenNotPaused {
        ILiquidFarmFactory _arbFarmFactory = ILiquidFarmFactory(farmFactory);
        address _farm = _arbFarmFactory.lpTokenFarm(_lpToken);
        if (_farm == address(0)) {
            revert InvalidFarm();
        }
        IERC20 lpToken_ = IERC20(_lpToken);
        lpToken_.approve(_farm, _amount);
        ILiquidFarm(_farm).stake(_amount);
        lpToken_.approve(_farm, 0);
        emit Staked(_lpToken, _amount);
    }

    function unstakeLpTokens(address _lpToken, uint256 _amount)
        external
        onlyGovernor
        whenNotPaused
    {
        ILiquidFarmFactory _arbFarmFactory = ILiquidFarmFactory(farmFactory);
        address _farm = _arbFarmFactory.lpTokenFarm(_lpToken);
        if (_farm == address(0)) {
            revert InvalidFarm();
        }
        ILiquidFarm(_farm).withdraw(_amount);
        emit Unstaked(_lpToken, _amount);
    }

    function exitStaking(address _lpToken) external onlyGovernor whenNotPaused {
        ILiquidFarmFactory _arbFarmFactory = ILiquidFarmFactory(farmFactory);
        address _farm = _arbFarmFactory.lpTokenFarm(_lpToken);
        if (_farm == address(0)) {
            revert InvalidFarm();
        }
        ILiquidFarm(_farm).exit();
        emit UnstakedAndClaimed(_farm, _lpToken);
    }

    function claimStakingRewards(address _lpToken) external onlyGovernor whenNotPaused {
        ILiquidFarmFactory _arbFarmFactory = ILiquidFarmFactory(farmFactory);
        address _farm = _arbFarmFactory.lpTokenFarm(_lpToken);
        if (_farm == address(0)) {
            revert InvalidFarm();
        }
        ILiquidFarm(_farm).getReward();
        emit ClaimedRewards(_farm, _lpToken);
    }

    function _swapOnOpenPool(
        IFlashLiquidityPair _pair,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) internal {
        uint256 _amountInWithFee = _amountIn * 9970;
        (uint256 _reserve0, uint256 _reserve1, ) = _pair.getReserves();
        uint256 _amountOutCheck;
        // avoid stack too deep
        {
            (
                uint256 _priceIn, 
                uint256 _priceOut, 
                uint256 _tokenInDecimals, 
                uint256 _tokenOutDecimals
            ) = _getPricesAndDecimals(_tokenIn, _tokenOut);
            _amountOutCheck = FullMath.mulDiv(
                _amountIn,
                FullMath.mulDiv(_priceIn, _tokenOutDecimals, _priceOut),
                _tokenInDecimals
            );
        }
        uint256 _amountOut;
        if (_tokenIn == _pair.token0()) {
            _amountOut = FullMath.mulDiv(
                _amountInWithFee,
                _reserve1,
                (_reserve0 * 10000) + _amountInWithFee
            );
            if (_amountOut < _amountOutCheck - (_amountOutCheck / maxDeviationFactor)) {
                revert AmountOutTooLow();
            }
            IERC20(_tokenIn).safeTransfer(address(_pair), _amountIn);
            _pair.swap(0, _amountOut, address(this), new bytes(0));
        } else {
            _amountOut = FullMath.mulDiv(
                _amountInWithFee,
                _reserve0,
                (_reserve1 * 10000) + _amountInWithFee
            );
            if (_amountOut < _amountOutCheck - (_amountOutCheck / maxDeviationFactor)) {
                revert AmountOutTooLow();
            }
            IERC20(_tokenIn).safeTransfer(address(_pair), _amountIn);
            _pair.swap(_amountOut, 0, address(this), new bytes(0));
        }
        emit Swapped(_tokenIn, _tokenOut, _amountIn, _amountOut);
    }

    function _swapOnSelfBalancingPool(
        IFlashLiquidityFactory _factory,
        IFlashLiquidityPair _pair,
        address _manager,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) internal {
        uint256 _amountInWithFee = _amountIn * 9994;
        _factory.setPairManager(address(_pair), address(this));
        (uint256 _reserve0, uint256 _reserve1, ) = _pair.getReserves();
        uint256 _amountOut;
        if (_tokenIn == _pair.token0()) {
            _amountOut = FullMath.mulDiv(
                _amountInWithFee,
                _reserve1,
                (_reserve0 * 10000) + _amountInWithFee
            );
            IERC20(_tokenIn).safeTransfer(address(_pair), _amountIn);
            _pair.swap(0, _amountOut, address(this), new bytes(0));
        } else {
            _amountOut = FullMath.mulDiv(
                _amountInWithFee,
                _reserve0,
                (_reserve1 * 10000) + _amountInWithFee
            );
            IERC20(_tokenIn).safeTransfer(address(_pair), _amountIn);
            _pair.swap(_amountOut, 0, address(this), new bytes(0));
        }
        _factory.setPairManager(address(_pair), _manager);
        emit Swapped(_tokenIn, _tokenOut, _amountIn, _amountOut);
    }

    function _liquefyOnOpenPool(
        address _token0,
        address _token1,
        uint256 _amountToken0,
        uint256 _amountToken1
    ) internal {
        address _router = router;
        uint256 _maxDeviationFactor = maxDeviationFactor;
        IERC20 token0_ = IERC20(_token0);
        IERC20 token1_ = IERC20(_token1);
        // avoid stack to deep
        {
            (
                uint256 _price0, 
                uint256 _price1, 
                uint256 _token0Decimals, 
                uint256 _token1Decimals
            ) = _getPricesAndDecimals(_token0, _token1);
            (uint256 rate1to0, uint256 rate0to1) = (
                FullMath.mulDiv(uint256(_price1), _token0Decimals, uint256(_price0)),
                FullMath.mulDiv(uint256(_price0), _token1Decimals, uint256(_price1))
            );
            uint256 _zeroToOneAmount = FullMath.mulDiv(_amountToken1, rate1to0, _token1Decimals);
            if (_zeroToOneAmount != 0 && _zeroToOneAmount <= _amountToken0) {
                _amountToken0 = _zeroToOneAmount;
            } else {
                _amountToken1 = FullMath.mulDiv(_amountToken0, rate0to1, _token0Decimals);
            }
            if (_amountToken0 == 0 || _amountToken1 == 0) {
                revert ZeroAmount();
            }
        }
        token0_.approve(_router, _amountToken0);
        token1_.approve(_router, _amountToken1);
        (uint256 _amount0, uint256 _amount1, ) = IFlashLiquidityRouter(_router).addLiquidity(
            _token0,
            _token1,
            _amountToken0,
            _amountToken1,
            _amountToken0 - (_amountToken0 / _maxDeviationFactor),
            _amountToken1 - (_amountToken1 / _maxDeviationFactor),
            address(this),
            block.timestamp
        );
        token0_.approve(_router, 0);
        token1_.approve(_router, 0);
        emit Liquefied(_token0, _token1, _amount0, _amount1);
    }

    function _liquefyOnSelfBalancingPool(
        address _token0,
        address _token1,
        uint256 _amountToken0,
        uint256 _amountToken1
    ) internal {
        address _router = router;
        IERC20 token0_ = IERC20(_token0);
        IERC20 token1_ = IERC20(_token1);
        token0_.approve(_router, _amountToken0);
        token1_.approve(_router, _amountToken1);
        (uint256 _amount0, uint256 _amount1, ) = IFlashLiquidityRouter(_router).addLiquidity(
            _token0,
            _token1,
            _amountToken0,
            _amountToken1,
            1,
            1,
            address(this),
            block.timestamp
        );
        token0_.approve(_router, 0);
        token1_.approve(_router, 0);
        emit Liquefied(_token0, _token1, _amount0, _amount1);
    }

    function _solidifyFromOpenPool(
        IFlashLiquidityPair _pair,
        address _router,
        uint256 _lpTokenAmount
    ) internal {
        (address _token0, address _token1) = (_pair.token0(), _pair.token1());
        (uint256 _reserve0, uint256 _reserve1, ) = _pair.getReserves();
        // avoid stack too deep
        {
            (
                uint256 _price0, 
                uint256 _price1, 
                uint256 _token0Decimals, 
                uint256 _token1Decimals
            ) = _getPricesAndDecimals(_token0, _token1);
            uint256 _reserve0Value = FullMath.mulDiv(_reserve0, uint256(_price0), _token0Decimals);
            uint256 _reserve1Value = FullMath.mulDiv(_reserve1, uint256(_price1), _token1Decimals);
            if (_reserve0Value > _reserve1Value) {
                if (_reserve0Value - _reserve1Value > _reserve0Value / maxDeviationFactor) {
                    revert ReservesValuesMismatch();
                }
            } else {
                if (_reserve1Value - _reserve0Value > _reserve1Value / maxDeviationFactor) {
                    revert ReservesValuesMismatch();
                }
            }
        }
        _pair.approve(_router, _lpTokenAmount);
        (uint256 _amount0, uint256 _amount1) = IFlashLiquidityRouter(_router).removeLiquidity(
            _token0,
            _token1,
            _lpTokenAmount,
            1,
            1,
            address(this),
            block.timestamp
        );
        _pair.approve(_router, 0);
        emit Solidified(_token0, _token1, _amount0, _amount1);
    }

    function _solidifyFromSelfBalancingPool(
        IFlashLiquidityPair _pair,
        address _router,
        uint256 _lpTokenAmount
    ) internal {
        (address _token0, address _token1) = (_pair.token0(), _pair.token1());
        (uint256 _amount0, uint256 _amount1) = IFlashLiquidityRouter(_router).removeLiquidity(
            _token0,
            _token1,
            _lpTokenAmount,
            1,
            1,
            address(this),
            block.timestamp
        );
        emit Solidified(_token0, _token1, _amount0, _amount1);
    }

    function _getPricesAndDecimals(address _token0, address _token1) 
        internal  
        returns (uint256, uint256, uint256, uint256) 
    {
        uint256 _maxStaleness = maxStaleness;
        (, int256 _price0, , uint256 _price0UpdatedAt, ) = priceFeeds[_token0].latestRoundData();
        (, int256 _price1, , uint256 _price1UpdateAt, ) = priceFeeds[_token1].latestRoundData();
        uint256 _token0Decimals = tokenDecimals[_token0];
        uint256 _token1Decimals = tokenDecimals[_token1];
        if (_price0 <= int256(0) || _price1 <= int256(0)) {
            revert InvalidPrice();
        }
        if (block.timestamp - _price0UpdatedAt > _maxStaleness) {
            revert StalenessToHigh();
        }
        if (block.timestamp - _price1UpdateAt > _maxStaleness) {
            revert StalenessToHigh();
        }
        if (_token0Decimals == 0) {
            _token0Decimals = 10**ERC20(_token0).decimals();
            tokenDecimals[_token0] = _token0Decimals;
        }
        if (_token1Decimals == 0) {
            _token1Decimals = 10**ERC20(_token1).decimals();
            tokenDecimals[_token1] = _token1Decimals;
        }
        if (_token0Decimals == 0 || _token1Decimals == 0) {
            revert DecimalsMismatch();
        }
        return (uint256(_price0), uint256(_price1), _token0Decimals, _token1Decimals);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBastionV3 {
    function factory() external view returns (address);

    function router() external view returns (address);

    function farmFactory() external view returns (address);

    function maxDeviationFactor() external view returns (uint256);

    function whitelistDelay() external view returns (uint256);

    function isExtManagerSetter(address) external view returns (bool);

    function isWhitelisted(address) external view returns (bool);

    function whitelistReqTimestamp(address) external view returns (uint256);

    function requestWhitelisting(address[] calldata _recipients) external;

    function abortWhitelisting(address[] calldata _recipients) external;

    function executeWhitelisting(address[] calldata _recipients) external;

    function removeFromWhitelist(address[] calldata _recipients) external;

    function setMaxDeviationFactor(uint256 _maxDeviationFactor) external;

    function setPairManager(address _pair, address _manager) external;

    function setMainManagerSetter(address _managerSetter) external;

    function setExtManagerSetters(address[] calldata _extManagerSetter, bool[] calldata _enabled)
        external;

    function setPriceFeeds(address[] calldata _tokens, address[] calldata _priceFeeds) external;

    function setTokensDecimals(address[] calldata _tokens, uint256[] calldata _decimals) external;

    function transferToWhitelisted(
        address _recipient,
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external;

    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external;

    function liquefy(
        address _token0,
        address _token1,
        uint256 _token0Amount,
        uint256 _token1Amount
    ) external;

    function solidify(address _lpToken, uint256 _lpAmount) external;

    function stakeLpTokens(address _lpToken, uint256 _amount) external;

    function unstakeLpTokens(address _lpToken, uint256 _amount) external;

    function exitStaking(address _lpToken) external;

    function claimStakingRewards(address _lpToken) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFlashBorrower {
    function onFlashLoan(
        address sender,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFlashLiquidityFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function managerSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setPairManager(address _pair, address _manager) external;

    function setPairManagerSetter(address _managerSetter) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFlashLiquidityPair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function manager() external view returns (address);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;

    function setPairManager(address) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IFlashLiquidityRouter01.sol";

interface IFlashLiquidityRouter is IFlashLiquidityRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFlashLiquidityRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IFlashBorrower.sol";

interface ILiquidFarm {
    error StakingZero();
    error WithdrawingZero();
    error FlashLoanNotRepaid();
    error TransferLocked(uint256 _unlockTime);

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event LogFlashLoan(
        address indexed borrower,
        address indexed receiver,
        address indexed rewardsToken,
        uint256 amount,
        uint256 fee
    );
    event FreeFlashloanerChanged(address indexed flashloaner, bool indexed free);

    function farmsFactory() external view returns (address);

    function stakingToken() external view returns (address);

    function rewardsToken() external view returns (address);

    function rewardPerToken() external view returns (uint256);

    function transferLock() external view returns (uint32);

    function getTransferUnlockTime(address _account) external view returns (uint64);

    function lastClaimedRewards(address _account) external view returns (uint64);

    function earned(address account) external view returns (uint256);

    function earnedRewardToken(address account) external view returns (uint256);

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;

    function flashLoan(
        IFlashBorrower borrower,
        address receiver,
        uint256 amount,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILiquidFarmFactory {
    error AlreadyDeployed();

    event FarmDeployed(address indexed _stakingToken, address indexed _rewardsToken);

    function lpTokenFarm(address _stakingToken) external view returns (address);

    function isFreeFlashLoan(address sender) external view returns (bool);

    function setFreeFlashLoan(address _target, bool _isExempted) external;

    function deploy(
        string memory name,
        string memory symbol,
        address stakingToken,
        address rewardsToken
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        unchecked {
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Governable {
    address public governor;
    address public pendingGovernor;
    uint256 public govTransferReqTimestamp;
    uint256 public immutable transferGovernanceDelay;

    error ZeroAddress();
    error NotAuthorized();
    error TooEarly();

    event GovernanceTrasferred(address indexed _oldGovernor, address indexed _newGovernor);
    event PendingGovernorChanged(address indexed _pendingGovernor);

    constructor(address _governor, uint256 _transferGovernanceDelay) {
        governor = _governor;
        transferGovernanceDelay = _transferGovernanceDelay;
        emit GovernanceTrasferred(address(0), _governor);
    }

    function setPendingGovernor(address _pendingGovernor) external onlyGovernor {
        if (_pendingGovernor == address(0)) {
            revert ZeroAddress();
        }
        pendingGovernor = _pendingGovernor;
        govTransferReqTimestamp = block.timestamp;
        emit PendingGovernorChanged(_pendingGovernor);
    }

    function transferGovernance() external {
        address _newGovernor = pendingGovernor;
        address _oldGovernor = governor;
        if (_newGovernor == address(0)) {
            revert ZeroAddress();
        }
        if (msg.sender != _oldGovernor && msg.sender != _newGovernor) {
            revert NotAuthorized();
        }
        if (block.timestamp - govTransferReqTimestamp < transferGovernanceDelay) {
            revert TooEarly();
        }
        pendingGovernor = address(0);
        governor = _newGovernor;
        emit GovernanceTrasferred(_oldGovernor, _newGovernor);
    }

    modifier onlyGovernor() {
        if (msg.sender != governor) {
            revert NotAuthorized();
        }
        _;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Governable} from "./Governable.sol";

abstract contract Guardable is Governable {
    bool public isPaused;
    mapping(address => bool) public isGuardian;

    error NotGuardian();
    error NotPaused();
    error AlreadyPaused();

    event PausedStateChanged(address indexed seneder, bool indexed isPaused);
    event GuardiansChanged(address[] indexed _guardians, bool[] indexed _enabled);

    constructor(address _governor, uint256 _transferGovernanceDelay)
        Governable(_governor, _transferGovernanceDelay)
    {
        isGuardian[_governor] = true;
    }

    function setGuardians(address[] calldata _guardians, bool[] calldata _enabled)
        external
        onlyGovernor
    {
        for (uint256 i = 0; i < _guardians.length; ) {
            isGuardian[_guardians[i]] = _enabled[i];
            unchecked {
                i++;
            }
        }
        emit GuardiansChanged(_guardians, _enabled);
    }

    function pause() external onlyGuardian whenNotPaused {
        isPaused = true;
        emit PausedStateChanged(msg.sender, true);
    }

    function unpause() external onlyGovernor whenPaused {
        isPaused = false;
        emit PausedStateChanged(msg.sender, false);
    }

    modifier onlyGuardian() {
        if (!isGuardian[msg.sender]) {
            revert NotGuardian();
        }
        _;
    }

    modifier whenPaused() {
        if (!isPaused) {
            revert NotPaused();
        }
        _;
    }

    modifier whenNotPaused() {
        if (isPaused) {
            revert AlreadyPaused();
        }
        _;
    }
}