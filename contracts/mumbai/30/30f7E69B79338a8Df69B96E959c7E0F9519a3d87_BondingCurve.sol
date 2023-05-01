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
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
library AddressUpgradeable {
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
pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { Equity } from "../token/Equity.sol";
import { Voting } from "../voting/Voting.sol";
import { MathUtil } from "./MathUtil.sol";

/*
    Can withdraw rewards? If so send tokens to treasury. Hard link to treasury not good
    Functions:
    - voting to replace treasury contract
    - buy with USDC

*/
contract BondingCurve is Voting, MathUtil {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event InitiativeTreasurySwitch(address newTreasury, uint64 votingEpoch);
    event TreasurySwitchedFromTo(address oldTreasuryAddr, address newTreasuryAddr);
    event TokenSwap(uint256 amountUSDTknIn, uint256 amountTknOut, address recipient);

    address public treasuryAddr;
    address public switchToTreasuryAddr;
    uint256 public amountUSDReceived;
    uint256 public amountD8XSold;

    address public immutable usdTknAddr;
    uint16 public constant INITIATIVE_MIN_PERCENTAGE_BPS = 500;
    bytes32 public constant INITIATIVE_CODE = bytes32(uint256(0x42));
    uint256 public constant INITIATIVE_FEE = 500000000000000000000; //$500 * 1e18
    uint256 public constant INITIATIVE_QUORUM = 2_000; //20%
    uint8 public constant VALUATION_FACTOR = 7;

    constructor(
        address _eqtyTokenAddr,
        address _initiativePaymentTknAddr,
        address _usdTokenAddr,
        address _treasuryAddr,
        uint256 _amountD8XSold,
        uint256 _amountUSDReceived
    ) Voting(_eqtyTokenAddr, _initiativePaymentTknAddr) {
        require(_eqtyTokenAddr != address(0), "zero addr");
        require(_initiativePaymentTknAddr != address(0), "zero addr");
        require(_usdTokenAddr != address(0), "zero addr");
        require(_treasuryAddr != address(0), "zero addr");
        usdTknAddr = _usdTokenAddr;
        treasuryAddr = _treasuryAddr;
        amountD8XSold = _amountD8XSold;
        amountUSDReceived = _amountUSDReceived;
    }

    /**
     * Swap USD token against our governance token
     * @param _amountUSDTkn how much USD-token do we deposit
     */
    function swap(uint256 _amountUSDTkn) external {
        // send specified amount of USD-tokens to treasury address
        IERC20Upgradeable(usdTknAddr).safeTransferFrom(msg.sender, treasuryAddr, _amountUSDTkn);
        uint256 amountOut = _calculateAmount(_amountUSDTkn);
        amountD8XSold = amountD8XSold + amountOut;
        // send equity tokens to msg sender
        amountUSDReceived = amountUSDReceived + _amountUSDTkn;
        IERC20Upgradeable(equityAddr).safeTransfer(msg.sender, amountOut);
        emit TokenSwap(_amountUSDTkn, amountOut, msg.sender);
    }

    function _calculateAmount(uint256 _amountUSDTknIn) internal view returns (uint256) {
        uint256 newTotalShares = _mulD18(
            amountD8XSold,
            _KthRoot(
                _divD18(amountUSDReceived + _amountUSDTknIn, amountUSDReceived),
                VALUATION_FACTOR
            )
        );
        return newTotalShares - amountD8XSold;
    }

    function _price() external view returns (uint256) {
        return (VALUATION_FACTOR * amountUSDReceived * ONE_DEC18) / amountD8XSold;
    }

    /**
     * change treasury address
     * @param _newTreasury  new address
     * @param _helpers  initiative can be launched with delegates
     */
    function treasurySwitchInitiative(address _newTreasury, address[] calldata _helpers) external {
        // ensure sender and helpers have enough power to launch initiative
        require(_newTreasury != address(0), "zero addr");
        require(
            Equity(equityAddr).isQualified(msg.sender, INITIATIVE_MIN_PERCENTAGE_BPS, _helpers),
            "not qualified"
        );
        switchToTreasuryAddr = _newTreasury;
        // the following call ensures voting-epoch is in the future and
        // initiative is not currently being voted for
        // does not allow new initiative if previous initiative was not executed but approved
        uint64 votingEpoch = _registerInitiative(
            INITIATIVE_CODE,
            msg.sender,
            INITIATIVE_FEE,
            INITIATIVE_QUORUM,
            treasuryAddr
        );
        emit InitiativeTreasurySwitch(_newTreasury, votingEpoch);
    }

    function executeTreasurySwitch() external {
        // ensure voting was approved
        require(initiativeVotingSeason[INITIATIVE_CODE] != 0, "no initiative");
        if (!_isInitiativeApproved(INITIATIVE_CODE, INITIATIVE_QUORUM)) {
            switchToTreasuryAddr = address(0x0);
            _deRegisterInitiative(INITIATIVE_CODE);
            return;
        }
        _deRegisterInitiative(INITIATIVE_CODE);
        // execute
        emit TreasurySwitchedFromTo(treasuryAddr, switchToTreasuryAddr);
        treasuryAddr = switchToTreasuryAddr;
        switchToTreasuryAddr = address(0x0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
 * @title Functions for valuation
 */
contract MathUtil {
    uint256 internal constant ONE_DEC18 = 10 ** 18;
    uint256 internal constant THRESH_DEC18 = 10000000000000000; //0.01

    /**
     * @notice K-th root with Halley approximation
     *         Number 1e18 decimal
     * @param _v     number for which we calculate x**(1/3)
     * @return returns _v**(1/3)
     */
    function _KthRoot(uint256 _v, uint8 _k) internal pure returns (uint256) {
        uint256 x = ONE_DEC18;
        uint256 xOld;
        bool cond;
        do {
            xOld = x;
            uint256 powX = _powerK(x, _k);
            x = _mulD18(
                x,
                _divD18((_k + 1) * _v + (_k - 1) * powX, (_k - 1) * _v + (_k + 1) * powX)
            );
            cond = xOld > x ? xOld - x > THRESH_DEC18 : x - xOld > THRESH_DEC18;
        } while (cond);
        return x;
    }

    function _mulD18(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a * _b) / ONE_DEC18;
    }

    function _divD18(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a * ONE_DEC18) / _b;
    }

    function _powerK(uint256 _x, uint8 _k) internal pure returns (uint256 res) {
        res = _x;
        do {
            res = _mulD18(res, _x);
            _k = _k - 1;
        } while (_k > 1);
    }
}

// SPDX-License-Identifier: MIT
// Copied and adjusted from OpenZeppelin
// Adjustments:
// - modifications to support ERC-677
// - removed require messages to save space
// - removed unnecessary require statements
// - removed GSN Context
// - upgraded to 0.8 to drop SafeMath
// - let name() and symbol() be implemented by subclass
// - infinite allowance support, with 2^255 and above considered infinite

pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC677Receiver } from "./IERC677Receiver.sol";

/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * transferAndCall
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 */
abstract contract ConcreteERC20 is IERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    uint8 public immutable decimals;

    constructor(uint8 _decimals) {
        decimals = _decimals;
    }

    // Optional functions
    function name() external view virtual returns (string memory);

    function symbol() external view virtual returns (string memory);

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        if (currentAllowance < (1 << 255)) {
            // Only decrease the allowance if it was not set to 'infinite'
            // Documented in /doc/infiniteallowance.md
            require(currentAllowance >= amount, "approval not enough");
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(recipient != address(0));

        _beforeTokenTransfer(sender, recipient, amount);
        require(_balances[sender] >= amount, "balance not enough");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    // ERC-677 functionality, can be useful for swapping and wrapping tokens
    function transferAndCall(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external returns (bool) {
        bool success = transfer(recipient, amount);
        if (success) {
            success = IERC677Receiver(recipient).onTokenTransfer(msg.sender, amount, data);
        }
        return success;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address recipient, uint256 amount) internal virtual {
        require(recipient != address(0));

        _beforeTokenTransfer(address(0), recipient, amount);

        _totalSupply += amount;
        _balances[recipient] += amount;
        emit Transfer(address(0), recipient, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        _beforeTokenTransfer(account, address(0), amount);

        _totalSupply -= amount;
        _balances[account] -= amount;
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IERC677Receiver } from "./IERC677Receiver.sol";
import { ID8XCoin } from "./ID8XCoin.sol";
import { ConcreteERC20 } from "./ConcreteERC20.sol";

/**
 * @title Equity contract manages the voting power
 * The voting power system is an adoption of Frankencoin
 */
abstract contract Equity is ID8XCoin, ConcreteERC20 {
    uint64 private totalVotesAnchorTime;
    uint192 private totalVotesAtAnchor;
    uint256 public immutable epochDurationSec; //604_800=7*24*60*60 = 7 days

    mapping(address => address) public delegates;
    mapping(address => uint64) private voteAnchor;

    event Delegation(address indexed from, address indexed to);

    constructor(uint256 _epochDurationInSeconds) ConcreteERC20(18) {
        epochDurationSec = _epochDurationInSeconds;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);
        if (amount > 0) {
            uint256 roundingLoss = _adjustRecipientVoteAnchor(to, amount);
            _adjustTotalVotes(from, amount, roundingLoss);
        }
    }

    /**
     * External: Get the current epoch (block timestamp / epochDuration)
     */
    function epoch() external view returns (uint64) {
        return _epoch();
    }

    /**
     * Get the current epoch (block timestamp / epochDuration)
     */
    function _epoch() internal view returns (uint64) {
        return uint64(block.timestamp / epochDurationSec);
    }

    /**
     * @notice Decrease the total votes anchor when tokens lose their voting power due to being moved
     * @param from      sender
     * @param amount    amount to be sent
     */
    function _adjustTotalVotes(address from, uint256 amount, uint256 roundingLoss) internal {
        uint256 lostVotes = from == address(0x0) ? 0 : (_epoch() - voteAnchor[from]) * amount;
        totalVotesAtAnchor = uint192(totalVotes() - roundingLoss - lostVotes);
        totalVotesAnchorTime = _epoch();
    }

    /**
     * @notice the vote anchor of the recipient is moved forward such that the number of calculated
     * votes does not change despite the higher balance.
     * @param to        receiver address
     * @param amount    amount to be received
     * @return the number of votes lost due to rounding errors
     */
    function _adjustRecipientVoteAnchor(address to, uint256 amount) internal returns (uint256) {
        if (to != address(0x0)) {
            uint256 recipientVotes = votes(to); // for example 21 if 7 shares were held for 3 epochs
            uint256 newbalance = balanceOf(to) + amount; // for example 11 if 4 shares are added
            voteAnchor[to] = _epoch() - uint64(recipientVotes / newbalance); // new example anchor is only 21 / 11 = 1 epochs in the past
            return recipientVotes % newbalance; // we have lost 21 % 11 = 10 votes
        } else {
            // optimization for burn, vote anchor of null address does not matter
            return 0;
        }
    }

    function votes(address holder) public view returns (uint256) {
        return balanceOf(holder) * (_epoch() - voteAnchor[holder]);
    }

    function totalVotes() public view returns (uint256) {
        return totalVotesAtAnchor + totalSupply() * (_epoch() - totalVotesAnchorTime);
    }

    function isQualified(
        address sender,
        uint16 _percentageBps,
        address[] calldata helpers
    ) external view returns (bool) {
        uint256 _votes = votes(sender);
        for (uint i = 0; i < helpers.length; i++) {
            address current = helpers[i];
            require(current != sender, "dlgt is sndr");
            require(_canVoteFor(sender, current), "wrong dlgt");
            for (uint j = i + 1; j < helpers.length; j++) {
                require(current != helpers[j], "dlgt added twice");
            }
            _votes += votes(current);
        }
        return _votes * 10000 >= _percentageBps * totalVotes();
    }

    function delegateVoteTo(address delegate) external override {
        delegates[msg.sender] = delegate;
        if (delegate == msg.sender) {
            delete delegates[msg.sender];
        }
        emit Delegation(msg.sender, delegate);
    }

    function canVoteFor(address delegate, address owner) external view override returns (bool) {
        return _canVoteFor(delegate, owner);
    }

    function _canVoteFor(address delegate, address owner) internal view returns (bool) {
        if (owner == delegate) {
            return true;
        } else if (owner == address(0x0)) {
            return false;
        } else {
            return _canVoteFor(delegate, delegates[owner]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ID8XCoin {
    function burn(uint256 _amount) external;

    function votes(address holder) external view returns (uint256);

    function canVoteFor(address delegate, address owner) external view returns (bool);

    function totalVotes() external view returns (uint256);

    function delegateVoteTo(address delegate) external;

    function epochDurationSec() external returns (uint256);

    function isQualified(
        address sender,
        uint16 _percentageBps,
        address[] calldata helpers
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC677Receiver {
    function onTokenTransfer(
        address from,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ID8XCoin } from "../token/ID8XCoin.sol";

/**
 * Parent contract for voting administration.
 * This is a general contract that can be used for any type of initiatives encoded in bytes32.
 */
contract Voting {
    event VoteSubmitted(uint256 votingPower, bool isYes, uint256 totalYes, uint256 totalNo);
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address public immutable equityAddr; // token for voting power
    address public immutable initiativePaymentTknAddr; //token to pay for initiatives
    uint256 public immutable epochDurationSec; // duration of an epoch in seconds

    mapping(bytes32 => uint64) public initiativeVoterLastVote;
    mapping(address => uint64) public lastVote; // epoch when the address last voted (active or via delegate)
    mapping(bytes32 => uint256) public initiativeYes;
    mapping(bytes32 => uint256) public initiativeNo;
    mapping(bytes32 => uint256) public initiativeTotalVP; // total VP is stored during voting epoch, required to get quorum right
    mapping(bytes32 => uint64) public initiativeVotingSeason; // voting epoch of initiative

    constructor(address _eqtyTokenAddr, address _paymentTknAddr) {
        require(_eqtyTokenAddr != address(0), "zero addr");
        require(_paymentTknAddr != address(0), "zero addr");

        equityAddr = _eqtyTokenAddr;
        epochDurationSec = ID8XCoin(_eqtyTokenAddr).epochDurationSec();
        initiativePaymentTknAddr = _paymentTknAddr;
    }

    /**
     * Vote for initiative
     * @param _initiative encoded initiative
     */
    function yea(bytes32 _initiative, address[] calldata _helpers) external {
        uint256 votingPwr = _voteAdmin(msg.sender, _initiative, _helpers);
        initiativeYes[_initiative] += votingPwr;
        uint256 V;
        if (initiativeTotalVP[_initiative] == 0) {
            // first vote for/against initiative sets total voting power
            V = ID8XCoin(equityAddr).totalVotes();
            initiativeTotalVP[_initiative] = V;
        }
        emit VoteSubmitted(votingPwr, true, initiativeYes[_initiative], initiativeNo[_initiative]);
    }

    /**
     * Vote against initiative
     * @param _initiative encoded initiative
     */
    function nai(bytes32 _initiative, address[] calldata _helpers) external {
        uint256 votingPwr = _voteAdmin(msg.sender, _initiative, _helpers);
        initiativeNo[_initiative] += votingPwr;
        uint256 V;
        if (initiativeTotalVP[_initiative] == 0) {
            // first vote for/against initiative sets total voting power
            V = ID8XCoin(equityAddr).totalVotes();
            initiativeTotalVP[_initiative] = V;
        }
        emit VoteSubmitted(
            votingPwr,
            false,
            initiativeYes[_initiative],
            initiativeNo[_initiative]
        );
    }

    function isInitiativeApprovedAtQuorum(
        bytes32 _initiative,
        uint256 _voteQuorum
    ) external view returns (bool isApproved) {
        return _isInitiativeApproved(_initiative, _voteQuorum);
    }

    function _isInitiativeApproved(
        bytes32 _initiative,
        uint256 _voteQuorum
    ) internal view returns (bool isApproved) {
        require(initiativeVotingSeason[_initiative] != 0, "no initiative");
        uint64 ep = _epoch();
        // if ep<voting season the initiative voting has not concluded
        require(ep > initiativeVotingSeason[_initiative], "initiative running");
        bool isQuorum = (initiativeYes[_initiative] + initiativeNo[_initiative]) * 10_000 >
            initiativeTotalVP[_initiative] * _voteQuorum;
        isApproved = (initiativeYes[_initiative] > initiativeNo[_initiative]) && isQuorum;
    }

    /**
     * Internal voting admin
     * - voting only if initiative is currently in voting season
     * - only vote once, including helpers
     * - voting power corresponds to the sender's voting power in this season
     * @param _initiative encoded initiative
     */
    function _voteAdmin(
        address _sender,
        bytes32 _initiative,
        address[] calldata _helpers
    ) internal returns (uint256) {
        ID8XCoin equity = ID8XCoin(equityAddr);

        uint64 ep = _epoch();
        bytes32 ivpair = keccak256(abi.encodePacked(_initiative, _sender));

        require(initiativeVotingSeason[_initiative] == ep, "not season");
        require(initiativeVoterLastVote[ivpair] != ep, "already voted");
        uint256 votingPower = equity.votes(_sender);
        initiativeVoterLastVote[ivpair] = ep;
        lastVote[_sender] = ep;
        for (uint256 i = 0; i < _helpers.length; i++) {
            address current = _helpers[i];
            require(current != _sender, "dlgt is sndr");
            require(equity.canVoteFor(_sender, current), "wrong dlgt");
            for (uint256 j = i + 1; j < _helpers.length; j++) {
                require(current != _helpers[j], "dlgt added twice");
            }
            ivpair = keccak256(abi.encodePacked(_initiative, current));
            require(initiativeVoterLastVote[ivpair] != ep, "already voted");
            initiativeVoterLastVote[ivpair] = ep;
            lastVote[current] = ep;
            votingPower += equity.votes(current);
        }

        return votingPower;
    }

    /**
     * Voting epoch should be the next epoch but at least half an epoch from now
     */
    function _determineVotingEpoch() internal view returns (uint64 epochNum) {
        // epochOf(block.timestamp + 0.5*epochDurationSec) + 1 epoch
        // = (block.timestamp + 0.5*epochDurationSec) / epochDurationSec + 1
        epochNum = uint64((block.timestamp + epochDurationSec / 2) / epochDurationSec) + 1;
    }

    /**
     *  When a new initiative is launched, reset votes for the initiative and register the
     *  voting season (the epoch when votes are accepted)
     *  - ensure voting season is in the future
     *  - ensure initative is not currently being voted on
     *  - ensure previously accepted initiative with same hash was executed
     * @param _initiative initiative hash
     * @param _initiativeSender sender of the initiative that is charged a fee
     * @param _initiativeFee fee to be paid to launch initiative
     * @param _paymentReceiver receiver of initiative payment
     * @return votingEpoch  voting epoch is the next epoch of, if less than half an epoch away, 2 epochs from now
     */
    function _registerInitiative(
        bytes32 _initiative,
        address _initiativeSender,
        uint256 _initiativeFee,
        uint256 _voteQuorum,
        address _paymentReceiver
    ) internal returns (uint64 votingEpoch) {
        if (_initiativeFee > 0) {
            // pay fee
            IERC20Upgradeable(initiativePaymentTknAddr).safeTransferFrom(
                _initiativeSender,
                _paymentReceiver,
                _initiativeFee
            );
        }
        uint64 ep = _epoch();
        votingEpoch = _determineVotingEpoch();
        require(initiativeVotingSeason[_initiative] != ep, "now voting");
        // do not allow new initiative if previous initiative was not executed but approved
        require(
            initiativeVotingSeason[_initiative] == 0 ||
                !(initiativeVotingSeason[_initiative] < ep &&
                    _isInitiativeApproved(_initiative, _voteQuorum)),
            "prev not exec"
        );
        // ensure votes start at zero
        delete initiativeYes[_initiative];
        delete initiativeNo[_initiative];
        delete initiativeTotalVP[_initiative];
        initiativeVotingSeason[_initiative] = votingEpoch;
    }

    /**
     *
     * @param _initiative initiative hash
     */
    function _deRegisterInitiative(bytes32 _initiative) internal {
        delete initiativeYes[_initiative];
        delete initiativeNo[_initiative];
        delete initiativeTotalVP[_initiative];
        delete initiativeVotingSeason[_initiative];
    }

    function _epoch() internal view returns (uint64 epochNum) {
        epochNum = uint64(block.timestamp / epochDurationSec);
    }

    function epoch() external view returns (uint64) {
        return _epoch();
    }
}