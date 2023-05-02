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

/**
 * @dev Interface for reward contract
 */

interface IGovernanceRewards {
    function withdraw(address _tokenAddr, address[] calldata _delegators) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { Voting } from "../voting/Voting.sol";
import { IGovernanceRewards } from "./IGovernanceRewards.sol";
import { ID8XCoin } from "../token/ID8XCoin.sol";

/**
 * initiatives:
 *  - anyone who has at least `initiativeMinPercentageBps` of voting power can create an initiative
 *  - an initiative specifies the voting season and specifics for the initiative
 *  - token to pay is not D8X to prevent wrong-way governance risk, e.g., 250 USDC
 *  Specifics are as follows:
 *  - budget initiative: token to be sent, amount to be sent, address it should be sent to
 * Considerations:
 *  - prevent accepted initiative from being overwritten by new initiative
 *  - initiatives can be overwritten so new initiatives of same type cannot be blocked with a timestamp far in the future
 */
contract Treasury is Voting {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event InitiativeBudget(
        address tokenAddr,
        uint256 amount,
        address targetWallet,
        uint64 votingEpoch,
        string name,
        bytes32 initiativeIdentifier
    );
    event RewardReceived(address tokenAddr, address rewardAddr);

    uint64 public lastVotingEpoch;
    uint16 public immutable initiativeMinPercentageBps; // minimal amount of combined voting power to launch initiative
    uint256 public constant INITIATIVE_BUDGET_FEE = 2000000000000000000000; //$2000 * 1e18, for USD-token (1e18)
    uint256 public constant QUORUM_BUDGET_BPS = 2_000; //20%

    struct budgetInitiativeType {
        address token;
        address recipient;
        uint256 amount;
    }
    mapping(address => uint256) public budgetedAmount;
    mapping(bytes32 => budgetInitiativeType) public budgetMetaData;

    /**
     * Constructor
     * @param _eqtyTokenAddr address of the governance token
     * @param _paymentTknAddr address of the token in which fees are paid
     * @param _initiativeMinPercentageBps minimum percentage of votes required to propose an initiative (in bps)
     */
    constructor(
        address _eqtyTokenAddr,
        address _paymentTknAddr,
        uint16 _initiativeMinPercentageBps
    ) Voting(_eqtyTokenAddr, _paymentTknAddr) {
        initiativeMinPercentageBps = _initiativeMinPercentageBps;
    }

    /**
     * During governance reward season, anyone can execute claimReward which
     * sends governance reward tokens to the this treasury contract. The amount
     * sent back corresponds to the treasury voting power
     * @notice slither-disable-next-line uninitialized-local
     * @param _rewardAddr address of the governance reward contract
     * @param _tokenAddr address of the governance reward token
     */
    function claimReward(address _rewardAddr, address _tokenAddr) external {
        // execute
        // slither-disable-next-line uninitialized-local
        address[] memory empty;
        IGovernanceRewards(_rewardAddr).withdraw(_tokenAddr, empty);
        emit RewardReceived(_tokenAddr, _rewardAddr);
    }

    /**
     * Launch a budget initiative
     * @notice initiative for (token, targetwallet) can be overriden unless the initative is in voting epoch.
     * this is checked in parent class _registerInitiative. Prevents from blocking initative epoch too far in the future
     * @param _tokenAddr    address of the token to be sent. Contract must have enough tokens for all pending initiatives.
     * @param _amount       amount to be transferred
     * @param _targetWallet receiver of the amount
     * @param _name         identifying name for the initiative
     * @param _helpers      delegates that help launch the initiative
     */
    function budgetInitiative(
        address _tokenAddr,
        uint256 _amount,
        address _targetWallet,
        string calldata _name,
        address[] calldata _helpers
    ) external {
        // ensure sender and helpers have enough power to launch initiative
        require(
            ID8XCoin(equityAddr).isQualified(msg.sender, initiativeMinPercentageBps, _helpers),
            "not qualified"
        );
        uint64 ep = _epoch();
        bytes32 initiative = keccak256(abi.encodePacked(_tokenAddr, _targetWallet));
        // clean up past initiative that was declined:
        if (
            initiativeVotingSeason[initiative] != 0 &&
            ep > initiativeVotingSeason[initiative] &&
            !_isInitiativeApproved(initiative, QUORUM_BUDGET_BPS)
        ) {
            budgetedAmount[_tokenAddr] =
                budgetedAmount[_tokenAddr] -
                budgetMetaData[initiative].amount;
            // delete metadata and initiativeVotingSeason entry
            _cleanBudgetInitiativeData(initiative);
        }
        // remove previous amount when overriding initiative
        // (amount is zero if no initiative)
        budgetedAmount[_tokenAddr] =
            budgetedAmount[_tokenAddr] -
            budgetMetaData[initiative].amount;

        // ensure amount available
        require(
            IERC20Upgradeable(_tokenAddr).balanceOf(address(this)) >=
                budgetedAmount[_tokenAddr] + _amount,
            "amnt not available"
        );

        budgetedAmount[_tokenAddr] += _amount;

        budgetMetaData[initiative].amount = _amount;
        budgetMetaData[initiative].token = _tokenAddr;
        budgetMetaData[initiative].recipient = _targetWallet;

        // the following call ensures voting-epoch is in the future and
        // initiative is not currently being voted for
        // does not allow new initiative if previous initiative was not executed but approved
        uint64 votingEpoch = _registerInitiative(
            initiative,
            msg.sender,
            INITIATIVE_BUDGET_FEE,
            QUORUM_BUDGET_BPS,
            address(this)
        );
        emit InitiativeBudget(_tokenAddr, _amount, _targetWallet, votingEpoch, _name, initiative);
    }

    /**
     * Execute a budget initiative. Will fail if initiative not approved.
     * Needs to be executed before next initiative of similar type (token, targetwallet) can be launched.
     * @param _initiative encoded initiative (token, target wallet)
     */
    function executeBudget(bytes32 _initiative) external {
        // ensure voting was approved
        require(_isInitiativeApproved(_initiative, QUORUM_BUDGET_BPS), "initve not approved");
        // store last initiative timestamp
        lastVotingEpoch = initiativeVotingSeason[_initiative];
        budgetInitiativeType memory bdgt = budgetMetaData[_initiative];
        budgetedAmount[bdgt.token] = budgetedAmount[bdgt.token] - bdgt.amount;

        // mark as completed
        _cleanBudgetInitiativeData(_initiative);
        // execute
        IERC20Upgradeable(bdgt.token).safeTransfer(bdgt.recipient, bdgt.amount);
    }

    /**
     * Clean budget initiative data
     * @param _initiative   initiative identifier
     */
    function _cleanBudgetInitiativeData(bytes32 _initiative) internal {
        // mark as completed
        _deRegisterInitiative(_initiative);
        // delete budget then execute budget transfer
        delete budgetMetaData[_initiative];
    }

    /**
     * Get if an address has voted since the last epoch
     * @param _voter  address to be checked
     */
    function hasVotedRecently(address _voter) external view returns (bool) {
        return lastVote[_voter] >= lastVotingEpoch;
    }
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

    /**
     * Constructor
     * @param _eqtyTokenAddr address of the governance token
     * @param _paymentTknAddr address of the token in which governance fees are paid
     */
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
     * @param _helpers addresses of delegators
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
     * @param _helpers addresses of delegators
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

    /**
     * Get if initative is approved (at majority and quorum)
     * @param _initiative encoded initiative
     * @param _voteQuorum quorum in bps
     */
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
     * @param _sender addresse of sender
     * @param _helpers addresses of delegators
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
     * @param _voteQuorum quorum, in bps
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