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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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

pragma solidity ^0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (common/access/Operators.sol)

/// @notice Inherit to add an Operator role which multiple addreses can be granted.
/// @dev Derived classes to implement addOperator() and removeOperator()
abstract contract Operators {
    /// @notice A set of addresses which are approved to run operations.
    mapping(address => bool) public operators;

    event AddedOperator(address indexed account);
    event RemovedOperator(address indexed account);

    error OnlyOperators(address caller);

    function _addOperator(address _account) internal {
        operators[_account] = true;
        emit AddedOperator(_account);
    }

    /// @notice Grant `_account` the operator role
    /// @dev Derived classes to implement and add protection on who can call
    function addOperator(address _account) external virtual;

    function _removeOperator(address _account) internal {
        delete operators[_account];
        emit RemovedOperator(_account);
    }

    /// @notice Revoke the operator role from `_account`
    /// @dev Derived classes to implement and add protection on who can call
    function removeOperator(address _account) external virtual;

    modifier onlyOperators() {
        if (!operators[msg.sender]) revert OnlyOperators(msg.sender);
        _;
    }
}

pragma solidity ^0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (common/CommonEventsAndErrors.sol)

/// @notice A collection of common errors thrown within the Origami contracts
library CommonEventsAndErrors {
    error InsufficientBalance(address token, uint256 required, uint256 balance);
    error InvalidToken(address token);
    error InvalidParam();
    error InvalidAddress(address addr);
    error InvalidAmount(address token, uint256 amount);
    error ExpectedNonZero();
    error Slippage(uint256 minAmountExpected, uint256 acutalAmount);

    event TokenRecovered(address indexed to, address indexed token, uint256 amount);
}

pragma solidity ^0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (common/FractionalAmount.sol)

import {CommonEventsAndErrors} from "./CommonEventsAndErrors.sol";

/// @notice Utilities to operate on fractional amounts of an input
/// - eg to calculate the split of rewards for fees.
library FractionalAmount {

    struct Data {
        uint128 numerator;
        uint128 denominator;
    }

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    /// @notice Return the fractional amount as basis points (ie fractional amount at precision of 10k)
    function asBasisPoints(Data storage self) internal view returns (uint256) {
        return (self.numerator * BASIS_POINTS_DIVISOR) / self.denominator;
    }

    /// @notice Helper to set the storage value with safety checks.
    function set(Data storage self, uint128 _numerator, uint128 _denominator) internal {
        if (_denominator == 0 || _numerator > _denominator) revert CommonEventsAndErrors.InvalidParam();
        self.numerator = _numerator;
        self.denominator = _denominator;
    }

    /// @notice Split an amount into two parts based on a fractional ratio
    /// eg: 333/1000 (33.3%) can be used to split an input amount of 600 into: (199, 401).
    /// @dev The numerator amount is truncated if necessary
    function split(Data storage self, uint256 inputAmount) internal view returns (uint256 numeratorAmount, uint256 denominatorAmount) {
        if (self.numerator == 0) {
            return (0, inputAmount);
        }
        unchecked {
            numeratorAmount = (inputAmount * self.numerator) / self.denominator;
            denominatorAmount = inputAmount - numeratorAmount;
        }
    }

    /// @notice Split an amount into two parts based on a fractional ratio
    /// eg: 333/1000 (33.3%) can be used to split an input amount of 600 into: (199, 401).
    /// @dev Overloaded version of the above, using calldata/pure to avoid a copy from storage in some scenarios
    function split(Data calldata self, uint256 inputAmount) internal pure returns (uint256 numeratorAmount, uint256 denominatorAmount) {
        if (self.numerator == 0) {
            return (0, inputAmount);
        }
        unchecked {
            numeratorAmount = (inputAmount * self.numerator) / self.denominator;
            denominatorAmount = inputAmount - numeratorAmount;
        }
    }
}

pragma solidity ^0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/common/IMintableToken.sol)

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

/// @notice An ERC20 token which can be minted/burnt, granted by the CAN_MINT role.
interface IMintableToken is IERC20, IERC20Permit {
    function mint(address to, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}

pragma solidity ^0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/external/gmx/IGlpManager.sol)

interface IGlpManager {
    function getAumInUsdg(bool maximise) external view returns (uint256);
    function glp() external view returns (address);
    function usdg() external view returns (address);
    function vault() external view returns (address);
    function getAums() external view returns (uint256[] memory);
}

pragma solidity ^0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/external/gmx/IGmxRewardRouter.sol)

interface IGmxRewardRouter {
    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;
    function stakeGmx(uint256 _amount) external;
    function unstakeGmx(uint256 _amount) external;
    function stakeEsGmx(uint256 _amount) external;
    function unstakeEsGmx(uint256 _amount) external;
    function gmx() external view returns (address);
    function glp() external view returns (address);
    function esGmx() external view returns (address);
    function bnGmx() external view returns (address);
    function weth() external view returns (address);
    function stakedGmxTracker() external view returns (address);
    function feeGmxTracker() external view returns (address);
    function stakedGlpTracker() external view returns (address);
    function feeGlpTracker() external view returns (address);
    function bonusGmxTracker() external view returns (address);
    function gmxVester() external view returns (address);
    function glpVester() external view returns (address);
    function glpManager() external view returns (address);
    function mintAndStakeGlp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp) external returns (uint256);
    function unstakeAndRedeemGlp(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver) external returns (uint256);
}

pragma solidity ^0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/external/gmx/IGmxVault.sol)

interface IGmxVault {
    function getMinPrice(address _token) external view returns (uint256);
    function BASIS_POINTS_DIVISOR() external view returns (uint256);
    function PRICE_PRECISION() external view returns (uint256);
    function usdg() external view returns (address);
    function adjustForDecimals(uint256 _amount, address _tokenDiv, address _tokenMul) external view returns (uint256);
    function getFeeBasisPoints(address _token, uint256 _usdgDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);
    function mintBurnFeeBasisPoints() external view returns (uint256);
    function taxBasisPoints() external view returns (uint256);
    function priceFeed() external view returns (address);
    function whitelistedTokens(address token) external view returns (bool);
    function getRedemptionAmount(address _token, uint256 _usdgAmount) external view returns (uint256);
    function hasDynamicFees() external view returns (bool);
    function usdgAmounts(address _token) external view returns (uint256);
    function getTargetUsdgAmount(address _token) external view returns (uint256);
    function allWhitelistedTokensLength() external view returns (uint256);
    function allWhitelistedTokens(uint256 index) external view returns (address);
    function totalTokenWeights() external view returns (uint256);
    function tokenWeights(address token) external view returns (uint256);
}

pragma solidity ^0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/external/gmx/IGmxVaultPriceFeed.sol)

interface IGmxVaultPriceFeed {
    function getPrice(address _token, bool _maximise, bool _includeAmmPrice, bool _useSwapPricing) external view returns (uint256);
}

pragma solidity ^0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/investments/gmx/IOrigamiGmxEarnAccount.sol)

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {FractionalAmount} from "../../../common/FractionalAmount.sol";

interface IOrigamiGmxEarnAccount {
    // Input parameters required when claiming/compounding rewards from GMX.io
    struct HandleGmxRewardParams {
        bool shouldClaimGmx;
        bool shouldStakeGmx;
        bool shouldClaimEsGmx;
        bool shouldStakeEsGmx;
        bool shouldStakeMultiplierPoints;
        bool shouldClaimWeth;
        bool shouldConvertWethToEth;
    }

    // Rewards that Origami claimed from GMX.io
    struct ClaimedRewards {
        uint256 wrappedNativeFromGmx;
        uint256 wrappedNativeFromGlp;
        uint256 esGmxFromGmx;
        uint256 esGmxFromGlp;
        uint256 vestedGmx;
    }

    enum VaultType {
        GLP,
        GMX
    }

    function rewardRates(VaultType vaultType) external view returns (uint256 wrappedNativeTokensPerSec, uint256 esGmxTokensPerSec);
    function harvestableRewards(VaultType vaultType) external view returns (
        uint256 wrappedNativeAmount, 
        uint256 esGmxAmount
    );
    function harvestRewards(FractionalAmount.Data calldata _esGmxVestingRate) external returns (ClaimedRewards memory claimedRewards);
    function handleRewards(HandleGmxRewardParams calldata params) external returns (ClaimedRewards memory claimedRewards);
    function stakeGmx(uint256 _amount) external;
    function unstakeGmx(uint256 _maxAmount) external;
    function mintAndStakeGlp(
        uint256 fromAmount,
        address fromToken,
        uint256 minUsdg,
        uint256 minGlp,
        uint256 slippageBps
    ) external returns (uint256);
    function unstakeAndRedeemGlp(
        uint256 glpAmount, 
        address toToken, 
        uint256 minOut, 
        uint256 slippageBps,
        address receiver
    ) external returns (uint256);
    function transferStakedGlp(uint256 glpAmount, address receiver) external;
    function stakedGlp() external view returns (IERC20Upgradeable);
}

pragma solidity ^0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/investments/gmx/IOrigamiGmxManager.sol)

import {IOrigamiGmxEarnAccount} from "./IOrigamiGmxEarnAccount.sol";
import {IOrigamiInvestment} from "../IOrigamiInvestment.sol";

interface IOrigamiGmxManager {
    function harvestableRewards(IOrigamiGmxEarnAccount.VaultType vaultType) external view returns (uint256[] memory amounts);
    function projectedRewardRates(IOrigamiGmxEarnAccount.VaultType vaultType) external view returns (uint256[] memory amounts);
    function harvestRewards() external;
    function harvestSecondaryRewards() external;
    function rewardTokensList() external view returns (address[] memory tokens);

    function acceptedOGmxTokens() external view returns (address[] memory);
    function investOGmxQuote(
        uint256 fromTokenAmount,
        address fromToken
    ) external view returns (
        IOrigamiInvestment.InvestQuoteData memory quoteData, 
        uint256[] memory investFeeBps
    );
    function investOGmx(
        IOrigamiInvestment.InvestQuoteData calldata quoteData, 
        uint256 slippageBps
    ) external returns (
        uint256 investmentAmount
    );
    function exitOGmxQuote(
        uint256 investmentTokenAmount, 
        address toToken
    ) external view returns (
        IOrigamiInvestment.ExitQuoteData memory quoteData, 
        uint256[] memory exitFeeBps
    );
    function exitOGmx(
        IOrigamiInvestment.ExitQuoteData memory quoteData, 
        uint256 slippageBps, 
        address recipient
    ) external returns (uint256 amountOut);

    function acceptedGlpTokens() external view returns (address[] memory);
    function investOGlpQuote(
        uint256 fromTokenAmount, 
        address fromToken
    ) external view returns (
        IOrigamiInvestment.InvestQuoteData memory quoteData, 
        uint256[] memory investFeeBps
    );
    function investOGlp(
        address fromToken,
        IOrigamiInvestment.InvestQuoteData calldata quoteData, 
        uint256 slippageBps
    ) external returns (
        uint256 investmentAmount
    );
    function exitOGlpQuote(
        uint256 investmentTokenAmount, 
        address toToken
    ) external view returns (
        IOrigamiInvestment.ExitQuoteData memory quoteData, 
        uint256[] memory exitFeeBps
    );
    function exitOGlp(
        address toToken,
        IOrigamiInvestment.ExitQuoteData memory quoteData, 
        uint256 slippageBps, 
        address recipient
    ) external returns (uint256 amountOut);
}

pragma solidity ^0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/investments/IOrigamiInvestment.sol)

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

/**
 * @title Origami Investment
 * @notice Users invest in the underlying protocol and receive a number of this Origami investment in return.
 * Origami will apply the accepted investment token into the underlying protocol in the most optimal way.
 */
interface IOrigamiInvestment is IERC20, IERC20Permit {
    /** 
     * @notice Emitted when a user makes a new investment
     * @param user The user who made the investment
     * @param fromTokenAmount The number of `fromToken` used to invest
     * @param fromToken The token used to invest, one of `acceptedInvestTokens()`
     * @param investmentAmount The number of investment tokens received, after fees
     **/
    event Invested(address indexed user, uint256 fromTokenAmount, address indexed fromToken, uint256 investmentAmount);

    /**
     * @notice Emitted when a user exists a position in an investment
     * @param user The user who exited the investment
     * @param investmentAmount The number of Origami investment tokens sold
     * @param toToken The token the user exited into
     * @param toTokenAmount The number of `toToken` received, after fees
     * @param recipient The receipient address of the `toToken`s
     **/
    event Exited(address indexed user, uint256 investmentAmount, address indexed toToken, uint256 toTokenAmount, address indexed recipient);

    /// @notice Errors for unsupported functions - for example if native chain ETH/AVAX/etc isn't a vaild investment
    error Unsupported();

    /**
     * @notice The set of accepted tokens which can be used to invest.
     * If the native chain ETH/AVAX is accepted, 0x0 will also be included in this list.
     */
    function acceptedInvestTokens() external view returns (address[] memory);

    /**
     * @notice The set of accepted tokens which can be used to exit into.
     * If the native chain ETH/AVAX is accepted, 0x0 will also be included in this list.
     */
    function acceptedExitTokens() external view returns (address[] memory);

    /**
     * @notice Quote data required when entering into this investment.
     */
    struct InvestQuoteData {
        /// @notice The token used to invest, which must be one of `acceptedInvestTokens()`
        address fromToken;

        /// @notice The quantity of `fromToken` to invest with
        uint256 fromTokenAmount;

        /// @notice The expected amount of this Origami Investment token to receive in return
        /// @dev Note slippage is applied to this when calling `invest()`
        uint256 expectedInvestmentAmount;

        /// @notice Any extra quote parameters required by the underlying investment
        bytes underlyingInvestmentQuoteData;
    }

    /**
     * @notice Quote data required when exoomg this investment.
     */
    struct ExitQuoteData {
        /// @notice The amount of this investment to sell
        uint256 investmentTokenAmount;

        /// @notice The token to sell into, which must be one of `acceptedExitTokens()`
        address toToken;

        /// @notice The expected amount of `toToken` to receive in return
        /// @dev Note slippage is applied to this when calling `invest()`
        uint256 expectedToTokenAmount;

        /// @notice Any extra quote parameters required by the underlying investment
        bytes underlyingInvestmentQuoteData;
    }

    /**
     * @notice Get a quote to buy this Origami investment using one of the accepted tokens. 
     * @dev The 0x0 address can be used for native chain ETH/AVAX
     * @param fromTokenAmount How much of `fromToken` to invest with
     * @param fromToken What ERC20 token to purchase with. This must be one of `acceptedInvestTokens`
     * @return quoteData The quote data, including any params required for the underlying investment type.
     * @return investFeeBps Any fees expected when investing with the given token, either from Origami or from the underlying investment.
     */
    function investQuote(
        uint256 fromTokenAmount, 
        address fromToken
    ) external view returns (
        InvestQuoteData memory quoteData, 
        uint256[] memory investFeeBps
    );

    /** 
      * @notice User buys this Origami investment with an amount of one of the approved ERC20 tokens. 
      * @param quoteData The quote data received from investQuote()
      * @param slippageBps Acceptable slippage, applied to the `quoteData` params
      * @return investmentAmount The actual number of this Origami investment tokens received.
      */
    function investWithToken(
        InvestQuoteData calldata quoteData, 
        uint256 slippageBps
    ) external returns (
        uint256 investmentAmount
    );

    /** 
      * @notice User buys this Origami investment with an amount of native chain token (ETH/AVAX)
      * @param quoteData The quote data received from investQuote()
      * @param slippageBps Acceptable slippage, applied to the `quoteData` params
      * @return investmentAmount The actual number of this Origami investment tokens received.
      */
    function investWithNative(
        InvestQuoteData calldata quoteData, 
        uint256 slippageBps
    ) external payable returns (
        uint256 investmentAmount
    );

    /**
     * @notice Get a quote to sell this Origami investment to receive one of the accepted tokens.
     * @dev The 0x0 address can be used for native chain ETH/AVAX
     * @param investmentAmount The number of Origami investment tokens to sell
     * @param toToken The token to receive when selling. This must be one of `acceptedExitTokens`
     * @return quoteData The quote data, including any params required for the underlying investment type.
     * @return exitFeeBps Any fees expected when exiting the investment to the nominated token, either from Origami or from the underlying investment.
     */
    function exitQuote(
        uint256 investmentAmount,
        address toToken
    ) external view returns (
        ExitQuoteData memory quoteData, 
        uint256[] memory exitFeeBps
    );

    /** 
      * @notice Sell this Origami investment to receive one of the accepted tokens.
      * @param quoteData The quote data received from exitQuote()
      * @param slippageBps Acceptable slippage, applied to the `quoteData` params
      * @param recipient The receiving address of the `toToken`
      * @return toTokenAmount The number of `toToken` tokens received upon selling the Origami investment tokens.
      */
    function exitToToken(
        ExitQuoteData calldata quoteData,
        uint256 slippageBps, 
        address recipient
    ) external returns (
        uint256 toTokenAmount
    );

    /** 
      * @notice Sell this Origami investment to native ETH/AVAX.
      * @param quoteData The quote data received from exitQuote()
      * @param slippageBps Acceptable slippage, applied to the `quoteData` params
      * @param recipient The receiving address of the native chain token.
      * @return nativeAmount The number of native chain ETH/AVAX/etc tokens received upon selling the Origami investment tokens.
      */
    function exitToNative(
        ExitQuoteData calldata quoteData, 
        uint256 slippageBps,
        address payable recipient
    ) external returns (
        uint256 nativeAmount
    );
}

pragma solidity ^0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (investments/gmx/OrigamiGmxManager.sol)

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

import {IGmxRewardRouter} from "../../interfaces/external/gmx/IGmxRewardRouter.sol";
import {IOrigamiInvestment} from "../../interfaces/investments/IOrigamiInvestment.sol";
import {IOrigamiGmxManager} from "../../interfaces/investments/gmx/IOrigamiGmxManager.sol";
import {IOrigamiGmxEarnAccount} from "../../interfaces/investments/gmx/IOrigamiGmxEarnAccount.sol";
import {IMintableToken} from "../../interfaces/common/IMintableToken.sol";
import {IGmxVault} from "../../interfaces/external/gmx/IGmxVault.sol";
import {IGlpManager} from "../../interfaces/external/gmx/IGlpManager.sol";
import {IGmxVaultPriceFeed} from "../../interfaces/external/gmx/IGmxVaultPriceFeed.sol";

import {Operators} from "../../common/access/Operators.sol";
import {FractionalAmount} from "../../common/FractionalAmount.sol";
import {CommonEventsAndErrors} from "../../common/CommonEventsAndErrors.sol";

/// @title Origami GMX/GLP Manager
/// @notice Manages Origami's GMX and GLP positions, policy decisions and rewards harvesting/compounding.
contract OrigamiGmxManager is IOrigamiGmxManager, Ownable, Operators, Pausable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IMintableToken;
    using FractionalAmount for FractionalAmount.Data;

    // Note: The below (GMX.io) contracts can be found here: https://gmxio.gitbook.io/gmx/contracts

    /// @notice $GMX (GMX.io)
    IERC20 public gmxToken;

    /// @notice $GLP (GMX.io)
    IERC20 public glpToken;

    /// @notice The GMX glpManager contract, responsible for buying/selling $GLP (GMX.io)
    IGlpManager public glpManager;

    /// @notice The GMX Vault contract, required for calculating accurate quotes for buying/selling $GLP (GMX.io)
    IGmxVault public gmxVault;

    /// @notice $wrappedNative - wrapped ETH/AVAX
    address public wrappedNativeToken;

    /// @notice $oGMX - The Origami ERC20 receipt token over $GMX
    /// Users get oGMX for initial $GMX deposits, and for each esGMX which Origami is rewarded,
    /// minus a fee.
    IMintableToken public immutable oGmxToken;

    /// @notice $oGLP - The Origami ECR20 receipt token over $GLP
    /// Users get oGLP for initial $GLP deposits.
    IMintableToken public immutable oGlpToken;

    /// @notice Percentages of oGMX rewards (minted based off esGMX rewards) that Origami retains as a fee
    FractionalAmount.Data public oGmxRewardsFeeRate;

    /// @notice Percentages of oGMX/oGLP that Origami retains as a fee when users sell out of their position
    FractionalAmount.Data public sellFeeRate;

    /// @notice Percentage of esGMX rewards that Origami will vest into GMX (1/365 per day).
    /// The remainder is staked.
    FractionalAmount.Data public esGmxVestingRate;

    /// @notice The GMX vault rewards aggregator - any harvested rewards from staked GMX/esGMX/mult points are sent here
    address public gmxRewardsAggregator;

    /// @notice The GLP vault rewards aggregator - any harvested rewards from staked GLP are sent here.
    address public glpRewardsAggregator;

    /// @notice The set of reward tokens that the GMX manager yields to users.
    /// [ ETH/AVAX, oGMX ]
    address[] public rewardTokens;

    /// @notice The address used to collect the Origami fees.
    address public feeCollector;

    // @notice The Origami contract holding the majority of staked GMX/GLP/multiplier points/esGMX.
    // @dev When users sell GMX/GLP positions are unstaked from this account.
    // GMX positions are also deposited directly into this account (no cooldown for GMX, unlike GLP)
    IOrigamiGmxEarnAccount public primaryEarnAccount;

    // @notice The Origami contract holding a small amount of staked GMX/GLP/multiplier points/esGMX.
    // @dev This account is used to accept user deposits for GLP, such that the cooldown clock isn't reset
    // in the primary earn account (which may block any user withdrawals)
    // Staked GLP positions are transferred to the primaryEarnAccount on a schedule (eg daily), which does
    // not reset the cooldown clock.
    IOrigamiGmxEarnAccount public secondaryEarnAccount;

    struct GlpUnderlyingInvestQuoteData {
        uint256 expectedUsdg;
    }

    event OGmxRewardsFeeRateSet(uint128 numerator, uint128 denominator);
    event SellFeeRateSet(uint128 numerator, uint128 denominator);
    event EsGmxVestingRateSet(uint128 numerator, uint128 denominator);
    event FeeCollectorSet(address indexed feeCollector);
    event RewardsAggregatorsSet(address gmxRewardsAggregator, address glpRewardsAggregator);
    event PrimaryEarnAccountSet(address indexed account);
    event SecondaryEarnAccountSet(address indexed account);

    constructor(
        address _gmxRewardRouter,
        address _glpRewardRouter,
        address _oGmxTokenAddr,
        address _oGlpTokenAddr,
        address _feeCollectorAddr,
        address _primaryEarnAccount,
        address _secondaryEarnAccount
    ) {
        initGmxContracts(_gmxRewardRouter, _glpRewardRouter);

        oGmxToken = IMintableToken(_oGmxTokenAddr);
        oGlpToken = IMintableToken(_oGlpTokenAddr);

        // Reward tokens are effectively immutable
        rewardTokens = [wrappedNativeToken, _oGmxTokenAddr];

        primaryEarnAccount = IOrigamiGmxEarnAccount(_primaryEarnAccount);
        secondaryEarnAccount = IOrigamiGmxEarnAccount(_secondaryEarnAccount);
        feeCollector = _feeCollectorAddr;

        // All numerators start at 0 on construction
        oGmxRewardsFeeRate.denominator = 100;
        sellFeeRate.denominator = 100;
        esGmxVestingRate.denominator = 100;
    }

    /// @dev In case any of the upstream GMX contracts are upgraded this can be re-initialized.
    function initGmxContracts(
        address _gmxRewardRouter, 
        address _glpRewardRouter
    ) public onlyOwner {
        IGmxRewardRouter gmxRewardRouter = IGmxRewardRouter(_gmxRewardRouter);
        IGmxRewardRouter glpRewardRouter = IGmxRewardRouter(_glpRewardRouter);
        glpManager = IGlpManager(glpRewardRouter.glpManager());
        wrappedNativeToken = gmxRewardRouter.weth();
        
        gmxToken = IERC20(gmxRewardRouter.gmx());
        glpToken = IERC20(glpRewardRouter.glp());
        gmxVault = IGmxVault(glpManager.vault());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Set the fee rate Origami takes on oGMX rewards
    /// (which are minted based off the quantity of esGMX rewards we receive)
    function setOGmxRewardsFeeRate(uint128 _numerator, uint128 _denominator) external onlyOwner {
        oGmxRewardsFeeRate.set(_numerator, _denominator);
        emit OGmxRewardsFeeRateSet(_numerator, _denominator);
    }

    /// @notice Set the proportion of esGMX that we vest whenever rewards are harvested.
    /// The remainder are staked.
    function setEsGmxVestingRate(uint128 _numerator, uint128 _denominator) external onlyOwner {
        esGmxVestingRate.set(_numerator, _denominator);
        emit EsGmxVestingRateSet(_numerator, _denominator);
    }

    /// @notice Set the proportion of fees oGMX/oGLP Origami retains when users sell out
    /// of their position.
    function setSellFeeRate(uint128 _numerator, uint128 _denominator) external onlyOwner {
        sellFeeRate.set(_numerator, _denominator);
        emit SellFeeRateSet(_numerator, _denominator);
    }

    /// @notice Set the address for where Origami fees are sent
    function setFeeCollector(address _feeCollector) external onlyOwner {
        feeCollector = _feeCollector;
        emit FeeCollectorSet(_feeCollector);
    }

    /// @notice Set the Origami account responsible for holding the majority of staked GMX/GLP/esGMX/mult points on GMX.io
    function setPrimaryEarnAccount(address _primaryEarnAccount) external onlyOwner {
        if (_primaryEarnAccount == address(0)) revert CommonEventsAndErrors.InvalidAddress(address(0));
        primaryEarnAccount = IOrigamiGmxEarnAccount(_primaryEarnAccount);
        emit PrimaryEarnAccountSet(_primaryEarnAccount);
    }

    /// @notice Set the Origami account responsible for holding a smaller/initial amount of staked GMX/GLP/esGMX/mult points on GMX.io
    /// @dev This is allowed to be set to 0x, ie unset.
    function setSecondaryEarnAccount(address _secondaryEarnAccount) external onlyOwner {
        secondaryEarnAccount = IOrigamiGmxEarnAccount(_secondaryEarnAccount);
        emit SecondaryEarnAccountSet(_secondaryEarnAccount);
    }

    /// @notice Set the Origami GMX/GLP rewards aggregators
    function setRewardsAggregators(address _gmxRewardsAggregator, address _glpRewardsAggregator) external onlyOwner {
        gmxRewardsAggregator = _gmxRewardsAggregator;
        glpRewardsAggregator = _glpRewardsAggregator;
        emit RewardsAggregatorsSet(_gmxRewardsAggregator, _glpRewardsAggregator);
    }

    function addOperator(address _address) external override onlyOwner {
        _addOperator(_address);
    }

    function removeOperator(address _address) external override onlyOwner {
        _removeOperator(_address);
    }

    /// @notice The set of reward tokens we give to the staking contract.
    function rewardTokensList() external view override returns (address[] memory tokens) {
        return rewardTokens;
    }

    /// @notice The amount of rewards up to this block that Origami is due to distribute to users.
    /// @param vaultType If GLP, get the reward rates for just staked GLP rewards. If GMX, get the reward rates for combined GMX/esGMX/mult points
    /// ie the net amount after Origami has deducted it's fees.
    function harvestableRewards(IOrigamiGmxEarnAccount.VaultType vaultType) external override view returns (uint256[] memory amounts) {
        amounts = new uint256[](2);

        // Pull the currently claimable amount from Origami's staked positions at GMX.
        // Secondary earn account rewards aren't automatically harvested, so intentionally not included here.
        (uint256 nativeAmount, uint256 esGmxAmount) = primaryEarnAccount.harvestableRewards(vaultType);

        // Ignore any portions we will be retaining as fees.
        amounts[0] = nativeAmount;
        (, amounts[1]) = oGmxRewardsFeeRate.split(esGmxAmount);
    }

    /// @notice The current native token and oGMX reward rates per second
    /// @param vaultType If GLP, get the reward rates for just staked GLP rewards. If GMX, get the reward rates for combined GMX/esGMX/mult points
    /// @dev Based on the current total Origami rewards, minus any portion of fees which we will take
    function projectedRewardRates(IOrigamiGmxEarnAccount.VaultType vaultType) external override view returns (uint256[] memory amounts) {
        amounts = new uint256[](2);

        // Pull the reward rates from Origami's staked positions at GMX.
        (uint256 primaryNativeRewardRate, uint256 primaryEsGmxRewardRate) = primaryEarnAccount.rewardRates(vaultType);

        // Also include any native rewards from the secondary earn account (GLP deposits)
        // as native rewards (ie ETH) from the secondary earn account are harvested and distributed to users periodically.
        // esGMX rewards are not included from the secondary earn account, as these are perpetually staked and not automatically 
        // distributed to users.
        (uint256 secondaryNativeRewardRate,) = (address(secondaryEarnAccount) == address(0))
            ? (0, 0)
            : secondaryEarnAccount.rewardRates(vaultType);

        // Ignore any portions we will be retaining as fees.
        amounts[0] = primaryNativeRewardRate + secondaryNativeRewardRate;
        (, amounts[1]) = oGmxRewardsFeeRate.split(primaryEsGmxRewardRate);
    }

    /** 
     * @notice Harvest any claimable rewards up to this block from GMX.io, from the primary earn account.
     * 1/ Claimed esGMX:
     *     Vest a portion, and stake the rest -- according to `esGmxVestingRate` ratio
     *     Mint oGMX 1:1 for any esGMX that has been claimed.
     * 2/ Claimed GMX (from vested esGMX):
     *     Stake the GMX at GMX.io
     * 3/ Claimed ETH/AVAX
     *     Collect a portion as protocol fees and send the rest to the reward aggregators
     * 4/ Minted oGMX (from esGMX 1:1)
     *     Collect a portion as protocol fees and send the rest to the reward aggregators
     */
    function harvestRewards() external override whenNotPaused {
        // Harvest the rewards from the primary earn account which has staked positions at GMX.io
        IOrigamiGmxEarnAccount.ClaimedRewards memory claimed = primaryEarnAccount.harvestRewards(esGmxVestingRate);

        // Apply any of the newly vested GMX
        if (claimed.vestedGmx > 0) {
            _applyGmx(claimed.vestedGmx);
        }

        // Handle esGMX rewards -- mint oGMX rewards and collect fees
        uint256 totalFees;
        uint256 _fees;
        uint256 _rewards;
        {
            // Any rewards claimed from staked GMX/esGMX/mult points => GMX Rewards Aggregator
            if (claimed.esGmxFromGmx > 0) {
                (_fees, _rewards) = oGmxRewardsFeeRate.split(claimed.esGmxFromGmx);
                totalFees += _fees;
                if (_rewards > 0) oGmxToken.mint(gmxRewardsAggregator, _rewards);
            }

            // Any rewards claimed from staked GLP => GLP Rewards Aggregator
            if (claimed.esGmxFromGlp > 0) {
                (_fees, _rewards) = oGmxRewardsFeeRate.split(claimed.esGmxFromGlp);
                totalFees += _fees;
                if (_rewards > 0) oGmxToken.mint(glpRewardsAggregator, _rewards);
            }

            // Mint the total oGMX fees
            if (totalFees > 0) {
                oGmxToken.mint(feeCollector, totalFees);
            }
        }

        // Handle ETH/AVAX rewards
        _processNativeRewards(claimed);
    }

    function _processNativeRewards(IOrigamiGmxEarnAccount.ClaimedRewards memory claimed) internal {
        // Any rewards claimed from staked GMX/esGMX/mult points => GMX Investment Manager
        if (claimed.wrappedNativeFromGmx > 0) {
            IERC20(wrappedNativeToken).safeTransfer(gmxRewardsAggregator, claimed.wrappedNativeFromGmx);
        }

        // Any rewards claimed from staked GLP => GLP Investment Manager
        if (claimed.wrappedNativeFromGlp > 0) {
            IERC20(wrappedNativeToken).safeTransfer(glpRewardsAggregator, claimed.wrappedNativeFromGlp);
        }
    }

    /** 
     * @notice Claim any ETH/AVAX rewards from the secondary earn account,
     * and perpetually stake any esGMX/multiplier points.
     */
    function harvestSecondaryRewards() external override whenNotPaused {
        IOrigamiGmxEarnAccount.ClaimedRewards memory claimed = secondaryEarnAccount.handleRewards(
            IOrigamiGmxEarnAccount.HandleGmxRewardParams({
                shouldClaimGmx: false,
                shouldStakeGmx: false,
                shouldClaimEsGmx: true,
                shouldStakeEsGmx: true,
                shouldStakeMultiplierPoints: true,
                shouldClaimWeth: true,
                shouldConvertWethToEth: false
            })
        );

        _processNativeRewards(claimed);
    }

    /// @notice The amount of native ETH/AVAX rewards up to this block that the secondary earn account is due to distribute to users.
    /// @param vaultType If GLP, get the reward rates for just staked GLP rewards. If GMX, get the reward rates for combined GMX/esGMX/mult points
    /// ie the net amount after Origami has deducted it's fees.
    function harvestableSecondaryRewards(IOrigamiGmxEarnAccount.VaultType vaultType) external view returns (uint256[] memory amounts) {
        amounts = new uint256[](2);

        // esGMX rewards aren't harvestable from the secondary earn account as they are perpetually staked - so intentionally not included here.
        (amounts[0],) = secondaryEarnAccount.harvestableRewards(vaultType);
    }

    /// @notice Apply any unstaked GMX (eg from user deposits) of $GMX into Origami's GMX staked position.
    function applyGmx(uint256 _amount) external whenNotPaused {
        if (_amount == 0) revert CommonEventsAndErrors.ExpectedNonZero();
        _applyGmx(_amount);
    }

    function _applyGmx(uint256 _amount) internal {
        gmxToken.safeTransfer(address(primaryEarnAccount), _amount);
        primaryEarnAccount.stakeGmx(_amount);
    }

    /// @notice The set of accepted tokens which can be used to invest/exit into oGMX.
    function acceptedOGmxTokens() external view override returns (address[] memory tokens) {
        tokens = new address[](1);
        tokens[0] = address(gmxToken);
    }

    /**
     * @notice Get a quote to buy the oGMX using GMX.
     * @param fromTokenAmount How much of GMX to invest with
     * @param fromToken This must be the address of the GMX token
     * @return quoteData The quote data, including any other quote params required for this investment type. To be passed through when executing the quote.
     * @return investFeeBps [GMX.io's fee when depositing with `fromToken`]
     */
    function investOGmxQuote(
        uint256 fromTokenAmount,
        address fromToken
    ) external override view returns (
        IOrigamiInvestment.InvestQuoteData memory quoteData, 
        uint256[] memory investFeeBps
    ) {
        if (fromToken != address(gmxToken)) revert CommonEventsAndErrors.InvalidToken(fromToken);
        if (fromTokenAmount == 0) revert CommonEventsAndErrors.ExpectedNonZero();

        // oGMX is minted 1:1, no fees
        quoteData.fromToken = fromToken;
        quoteData.fromTokenAmount = fromTokenAmount;
        quoteData.expectedInvestmentAmount = fromTokenAmount;
        // No extra underlyingInvestmentQuoteData

        investFeeBps = new uint256[](0);
    }

    /** 
      * @notice User buys oGMX with an amount GMX.
      * @param quoteData The quote data received from investQuote()
      * @return investmentAmount The actual number of receipt tokens received, inclusive of any fees.
      */
    function investOGmx(
        IOrigamiInvestment.InvestQuoteData calldata quoteData, 
        uint256 /*slippageBps currently unused*/
    ) external override onlyOperators returns (
        uint256 investmentAmount
    ) {
        // Transfer the GMX straight to the primary earn account which stakes the GMX at GMX.io
        // NB: There is no cooldown when transferring GMX, so using the primary earn account for deposits is fine.
        gmxToken.safeTransfer(address(primaryEarnAccount), quoteData.fromTokenAmount);
        primaryEarnAccount.stakeGmx(quoteData.fromTokenAmount);

        // User gets 1:1 oGMX for the GMX provided.
        investmentAmount = quoteData.fromTokenAmount;
    }

    /**
     * @notice Get a quote to sell oGMX to GMX.
     * @param investmentTokenAmount The amount of oGMX to sell
     * @param toToken This must be the address of the GMX token
     * @return quoteData The quote data, including any other quote params required for this investment type. To be passed through when executing the quote.
     * @return exitFeeBps [Origami's exit fee]
     */
    function exitOGmxQuote(
        uint256 investmentTokenAmount, 
        address toToken
    ) external override view returns (
        IOrigamiInvestment.ExitQuoteData memory quoteData, 
        uint256[] memory exitFeeBps
    ) {
        if (investmentTokenAmount == 0) revert CommonEventsAndErrors.ExpectedNonZero();
        if (toToken != address(gmxToken)) revert CommonEventsAndErrors.InvalidToken(toToken);

        quoteData.investmentTokenAmount = investmentTokenAmount;
        quoteData.toToken = toToken;
        // No extra underlyingInvestmentQuoteData

        exitFeeBps = new uint256[](1);
        exitFeeBps[0] = sellFeeRate.asBasisPoints();
        (, quoteData.expectedToTokenAmount) = sellFeeRate.split(investmentTokenAmount);
    }
    
    /** 
      * @notice Sell oGMX to receive GMX. 
      * @param quoteData The quote data received from exitQuote()
      * @param recipient The receiving address of the `t\oToken`
      */
    function exitOGmx(
        IOrigamiInvestment.ExitQuoteData memory quoteData, 
        uint256 /*slippageBps currently unused*/,
        address recipient
    ) external override onlyOperators returns (uint256) {
        (uint256 fees, uint256 nonFees) = sellFeeRate.split(quoteData.investmentTokenAmount);

        // Send the oGlp fees to the fee collector
        if (fees > 0) {
            oGmxToken.safeTransfer(feeCollector, fees);
        }

        if (nonFees > 0) {
            // Burn the users oGmx
            oGmxToken.burn(address(this), nonFees);

            // Unstake the GMX - NB this burns any multiplier points
            primaryEarnAccount.unstakeGmx(nonFees);

            // Send the GMX to the recipient
            gmxToken.safeTransfer(recipient, nonFees);
        }

        return nonFees;
    }

    /// @notice The set of whitelisted GMX.io tokens which can be used to buy GLP (and hence oGLP)
    /// @dev Native tokens (ETH/AVAX) and using staked GLP can also be used.
    function acceptedGlpTokens() external view override returns (address[] memory tokens) {
        uint256 length = gmxVault.allWhitelistedTokensLength();
        tokens = new address[](length + 2);

        // Add in the GMX.io whitelisted tokens
        // uint256 tokenIdx;
        uint256 i;
        for (; i < length; ++i) {
            tokens[i] = gmxVault.allWhitelistedTokens(i);
        }

        // ETH/AVAX is at [length-1 + 1]. Already instantiated as 0x
        // staked GLP is at [length-1 + 2]
        tokens[i+1] = address(primaryEarnAccount.stakedGlp());
    }

    /**
     * @notice Get a quote to buy the oGLP using one of the approved tokens, inclusive of GMX.io fees.
     * @dev The 0x0 address can be used for native chain ETH/AVAX
     * @param fromTokenAmount How much of `fromToken` to invest with
     * @param fromToken What ERC20 token to purchase with. This must be one of `acceptedInvestTokens`
     * @return quoteData The quote data, including any other quote params required for the underlying investment type. To be passed through when executing the quote.
     * @return investFeeBps [GMX.io's fee when depositing with `fromToken`]
     */
    function investOGlpQuote(
        uint256 fromTokenAmount, 
        address fromToken
    ) external view override returns (
        IOrigamiInvestment.InvestQuoteData memory quoteData, 
        uint256[] memory investFeeBps
    ) {
        if (fromTokenAmount == 0) revert CommonEventsAndErrors.ExpectedNonZero();

        quoteData.fromToken = fromToken;
        quoteData.fromTokenAmount = fromTokenAmount;

        uint256 expectedUsdg;
        if (fromToken == address(primaryEarnAccount.stakedGlp())) {
            quoteData.expectedInvestmentAmount = fromTokenAmount; // 1:1 for staked GLP
            investFeeBps = new uint256[](1); // investFeeBps[0]=0, expectedUsdg=0
        } else {
            address tokenIn = (fromToken == address(0)) ? wrappedNativeToken : fromToken;

            // GMX.io don't provide on-contract external functions to obtain the quote. Logic extracted from:
            // https://github.com/gmx-io/gmx-contracts/blob/83bd5c7f4a1236000e09f8271d58206d04d1d202/contracts/core/GlpManager.sol#L160
            investFeeBps = new uint256[](1);
            uint256 aumInUsdg = glpManager.getAumInUsdg(true); // Assets Under Management
            uint256 glpSupply = IERC20(glpToken).totalSupply();

            (investFeeBps[0], expectedUsdg) = buyUsdgQuote(fromTokenAmount, tokenIn);

            quoteData.expectedInvestmentAmount = (aumInUsdg == 0) ? expectedUsdg : expectedUsdg * glpSupply / aumInUsdg;
        }
        
        quoteData.underlyingInvestmentQuoteData = abi.encode(GlpUnderlyingInvestQuoteData(expectedUsdg));
    }

    /** 
      * @notice User buys oGLP with an amount of one of the approved ERC20 tokens. 
      * @param fromToken The token override to invest with. May be different from the `quoteData.fromToken`
      * @param quoteData The quote data received from investQuote()
      * @param slippageBps Acceptable slippage, applied to the encodedQuote params
      * @return investmentAmount The actual number of receipt tokens received, inclusive of any fees.
      */
    function investOGlp(
        address fromToken,
        IOrigamiInvestment.InvestQuoteData calldata quoteData, 
        uint256 slippageBps
    ) external override onlyOperators returns (
        uint256 investmentAmount
    ) {
        if (fromToken == address(primaryEarnAccount.stakedGlp())) {
            // Pull staked GLP tokens from the user and transfer directly to the primary Origami earn account contract, responsible for staking.
            // This doesn't reset the cooldown clock for withdrawals, so it's ok to send directly to the primary earn account.
            IERC20(fromToken).safeTransfer(address(primaryEarnAccount), quoteData.fromTokenAmount);
            investmentAmount = quoteData.fromTokenAmount;
        } else {
            // Pull ERC20 tokens from the user and send to the secondary Origami earn account contract which purchases GLP on GMX.io and stakes it
            // This DOES reset the cooldown clock for withdrawals, so the secondary account is used in order 
            // to avoid withdrawals blocking from cooldown in the primary account.
            IERC20(fromToken).safeTransfer(address(secondaryEarnAccount), quoteData.fromTokenAmount);

            GlpUnderlyingInvestQuoteData memory underlyingQuoteData = abi.decode(quoteData.underlyingInvestmentQuoteData, (GlpUnderlyingInvestQuoteData));
            investmentAmount = secondaryEarnAccount.mintAndStakeGlp(
                quoteData.fromTokenAmount, fromToken, underlyingQuoteData.expectedUsdg, quoteData.expectedInvestmentAmount, slippageBps
            );
        }
    }

    /**
     * @notice Get a quote to sell oGLP to receive one of the accepted tokens.
     * @dev The 0x0 address can be used for native chain ETH/AVAX
     * @param investmentTokenAmount The amount of oGLP to sell
     * @param toToken The token to receive when selling. This must be one of `acceptedExitTokens`
     * @return quoteData The quote data, including any other quote params required for this investment type. To be passed through when executing the quote.
     * @return exitFeeBps [Origami's exit fee, GMX.io's fee when selling to `toToken`]
     */
    function exitOGlpQuote(
        uint256 investmentTokenAmount, 
        address toToken
    ) external override view returns (
        IOrigamiInvestment.ExitQuoteData memory quoteData, 
        uint256[] memory exitFeeBps
    ) {
        if (investmentTokenAmount == 0) revert CommonEventsAndErrors.ExpectedNonZero();

        quoteData.investmentTokenAmount = investmentTokenAmount;
        quoteData.toToken = toToken;
        // No extra underlyingInvestmentQuoteData on exit

        exitFeeBps = new uint256[](2);  // [Origami's exit fee, GMX's exit fee]
        exitFeeBps[0] = sellFeeRate.asBasisPoints();
        (, uint256 glpAmount) = sellFeeRate.split(investmentTokenAmount);
        if (glpAmount == 0) return (quoteData, exitFeeBps);

        if (toToken == address(primaryEarnAccount.stakedGlp())) {
            // No GMX related fees for staked GLP transfers
            quoteData.expectedToTokenAmount = glpAmount;
        } else {
            address tokenOut = (toToken == address(0)) ? wrappedNativeToken : toToken;

            // GMX.io don't provide on-contract external functions to obtain the quote. Logic extracted from:
            // https://github.com/gmx-io/gmx-contracts/blob/83bd5c7f4a1236000e09f8271d58206d04d1d202/contracts/core/GlpManager.sol#L183
            uint256 aumInUsdg = glpManager.getAumInUsdg(false); // Assets Under Management
            uint256 glpSupply = IERC20(glpToken).totalSupply();
            uint256 usdgAmount = (glpSupply == 0) ? 0 : glpAmount * aumInUsdg / glpSupply;
            
            (exitFeeBps[1], quoteData.expectedToTokenAmount) = sellUsdgQuote(usdgAmount, tokenOut);
        }
    }

    /** 
      * @notice Sell oGLP to receive one of the accepted tokens. 
      * @param toToken The token override to invest with. May be different from the `quoteData.toToken`
      * @param quoteData The quote data received from exitQuote()
      * @param slippageBps Acceptable slippage, applied to the encodedQuote params
      * @param recipient The receiving address of the `toToken`
      * @return amountOut The number of `toToken` tokens received upon selling the Origami receipt token.
      */
    function exitOGlp(
        address toToken,
        IOrigamiInvestment.ExitQuoteData calldata quoteData, 
        uint256 slippageBps, 
        address recipient
    ) external override onlyOperators returns (uint256 amountOut) {
        (uint256 fees, uint256 nonFees) = sellFeeRate.split(quoteData.investmentTokenAmount);

        // Send the oGlp fees to the fee collector
        if (fees > 0) {
            oGlpToken.safeTransfer(feeCollector, fees);
        }

        if (nonFees > 0) {
            // Burn the remaining oGlp
            oGlpToken.burn(address(this), nonFees);

            if (toToken == address(primaryEarnAccount.stakedGlp())) {
                // Transfer the remaining staked GLP to the recipient
                primaryEarnAccount.transferStakedGlp(
                    nonFees,
                    recipient
                );
                amountOut = nonFees;
            } else {
                // Sell from the primary earn account and send the resulting token to the recipient.
                amountOut = primaryEarnAccount.unstakeAndRedeemGlp(
                    nonFees,
                    toToken,
                    quoteData.expectedToTokenAmount,
                    slippageBps,
                    recipient
                );
            }
        }
    }

    function buyUsdgQuote(uint256 fromAmount, address fromToken) internal view returns (
        uint256 feeBasisPoints,
        uint256 usdgAmountOut
    ) {
        // Used as part of the quote to buy GLP. Forked from:
        // https://github.com/gmx-io/gmx-contracts/blob/83bd5c7f4a1236000e09f8271d58206d04d1d202/contracts/core/Vault.sol#L452
        if (!gmxVault.whitelistedTokens(fromToken)) revert CommonEventsAndErrors.InvalidToken(fromToken);
        uint256 price = IGmxVaultPriceFeed(gmxVault.priceFeed()).getPrice(fromToken, false, true, true);
        uint256 pricePrecision = gmxVault.PRICE_PRECISION();
        uint256 basisPointsDivisor = FractionalAmount.BASIS_POINTS_DIVISOR;
        address usdg = gmxVault.usdg();
        uint256 usdgAmount = fromAmount * price / pricePrecision;
        usdgAmount = gmxVault.adjustForDecimals(usdgAmount, fromToken, usdg);

        feeBasisPoints = getFeeBasisPoints(
            fromToken, usdgAmount, 
            true  // true for buy, false for sell
        );

        uint256 amountAfterFees = fromAmount * (basisPointsDivisor - feeBasisPoints) / basisPointsDivisor;
        usdgAmountOut = gmxVault.adjustForDecimals(amountAfterFees * price / pricePrecision, fromToken, usdg);
    }

    function sellUsdgQuote(
        uint256 usdgAmount, address toToken
    ) internal view returns (uint256 feeBasisPoints, uint256 amountOut) {
        // Used as part of the quote to sell GLP. Forked from:
        // https://github.com/gmx-io/gmx-contracts/blob/83bd5c7f4a1236000e09f8271d58206d04d1d202/contracts/core/Vault.sol#L484
        if (usdgAmount == 0) return (feeBasisPoints, amountOut);
        if (!gmxVault.whitelistedTokens(toToken)) revert CommonEventsAndErrors.InvalidToken(toToken);
        uint256 pricePrecision = gmxVault.PRICE_PRECISION();
        uint256 price = IGmxVaultPriceFeed(gmxVault.priceFeed()).getPrice(toToken, true, true, true);
        address usdg = gmxVault.usdg();
        uint256 redemptionAmount = gmxVault.adjustForDecimals(usdgAmount * pricePrecision / price, usdg, toToken);

        feeBasisPoints = getFeeBasisPoints(
            toToken, usdgAmount,
            false  // true for buy, false for sell
        );

        uint256 basisPointsDivisor = FractionalAmount.BASIS_POINTS_DIVISOR;
        amountOut = redemptionAmount * (basisPointsDivisor - feeBasisPoints) / basisPointsDivisor;
    }

    function getFeeBasisPoints(address _token, uint256 _usdgDelta, bool _increment) internal view returns (uint256) {
        // Used as part of the quote to buy/sell GLP. Forked from:
        // https://github.com/gmx-io/gmx-contracts/blob/83bd5c7f4a1236000e09f8271d58206d04d1d202/contracts/core/VaultUtils.sol#L143
        uint256 feeBasisPoints = gmxVault.mintBurnFeeBasisPoints();
        uint256 taxBasisPoints = gmxVault.taxBasisPoints();
        if (!gmxVault.hasDynamicFees()) { return feeBasisPoints; }

        // The GMX.io website sell quotes are slightly off when calculating the fee. When actually selling, 
        // the code already has the sell amount (_usdgDelta) negated from initialAmount and usdgSupply,
        // however when getting a quote, it doesn't have this amount taken off - so we get slightly different results.
        // To have the quotes match the exact amounts received when selling, this tweak is required.
        // https://github.com/gmx-io/gmx-contracts/issues/28
        uint256 initialAmount = gmxVault.usdgAmounts(_token);
        uint256 usdgSupply = IERC20(gmxVault.usdg()).totalSupply();
        if (!_increment) {
            initialAmount = (_usdgDelta > initialAmount) ? 0 : initialAmount - _usdgDelta;
            usdgSupply = (_usdgDelta > usdgSupply) ? 0 : usdgSupply - _usdgDelta;
        }
        // End tweak

        uint256 nextAmount = initialAmount + _usdgDelta;
        if (!_increment) {
            nextAmount = _usdgDelta > initialAmount ? 0 : initialAmount - _usdgDelta;
        }

        uint256 targetAmount = (usdgSupply == 0)
            ? 0
            : gmxVault.tokenWeights(_token) * usdgSupply / gmxVault.totalTokenWeights();
        if (targetAmount == 0) { return feeBasisPoints; }

        uint256 initialDiff = initialAmount > targetAmount ? initialAmount - targetAmount : targetAmount - initialAmount;
        uint256 nextDiff = nextAmount > targetAmount ? nextAmount - targetAmount : targetAmount - nextAmount;

        // action improves relative asset balance
        if (nextDiff < initialDiff) {
            uint256 rebateBps = taxBasisPoints * initialDiff / targetAmount;
            return rebateBps > feeBasisPoints ? 0 : feeBasisPoints - rebateBps;
        }

        uint256 averageDiff = (initialDiff + nextDiff) / 2;
        if (averageDiff > targetAmount) {
            averageDiff = targetAmount;
        }

        uint256 taxBps = taxBasisPoints * averageDiff / targetAmount;
        return feeBasisPoints + taxBps;
    }

    /// @notice Owner can recover tokens
    function recoverToken(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).safeTransfer(_to, _amount);
        emit CommonEventsAndErrors.TokenRecovered(_to, _token, _amount);
    }
}