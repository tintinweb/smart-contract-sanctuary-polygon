/**
 *Submitted for verification at polygonscan.com on 2022-10-27
*/

// SPDX-License-Identifier: MIT LICENSE
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: contracts/GhostStaking.sol


/* Ghost Staking Contract by COSMIC ✨ Lord of the TrashPandazClub*/

//                                         J&G57                    !PP&P                              
//                .775555J7~               ^5?:7&  ^Y55557         !B~GY                               
//              .YY!~^:^:~!75!     .7!75555J~:~^!&G?^:^::!5J      7B^#?                                
//             .P5.^Y&@&@@#7:!5!~YPPP!!::::??~PPPG~:[email protected]&J::GY    ?#^&!                                 
//            :[email protected]@@@@@@@&J:!BG!^!::^^^^::::::!^[email protected]@@@@5:P5. .BJY:                          ^!.     
//            &Y::[email protected]@@@@@@@@@B:::!JP&&&&&&&&&&&&&JJJ5PY7#B&~.#5                               &J7#7    
//            #Y::[email protected]@@@@@@@P!??&&@@@@@@@@@@@@@@@@@@@@@@&&?:::#Y                          !&J: .J5~     
//            #Y::[email protected]@@&&Y!!Y&@@@@@@&PG#@@@@@@@@@@@@@@@@@#&&Y^~JJ.                         !PG5:        
//            #Y:^~???^:[email protected]@@@@&J7?7Y&#[email protected]@@@@@@@@@@@@@BP#P&&&P~^JY:                         ^5G&.      
//  ::::.     #5:^^::::[email protected]@@@@@?^:::::^[email protected]@@@@@@@@@@@@@&&@7^::!B&G~^J#    ::::::         .75?.  :~       
//  B#5?JYYYYYJ~:^^^^^[email protected]@@@@@7:^^^^^^^[email protected]@@@@@@@@@G?7Y#@&~::^::[email protected]~:JYYYYJJJJG&:        PP7PP           
//   :JJ~^^^^^::^^^^^:@@@@@@@~:::::::[email protected]@@@@@@@@@@@#B&@@@@#7:::[email protected]@!:^^^:^75Y~           .!:            
//     .?J!^^^^^^^^^^:@@@@[email protected]@#!~!~Y&&JYJ&@@@@@@@@@@@@@&[email protected]@#BP5G&[email protected]~:^:7P!                             
//      .BJ^^^^^^^^^^^J&@&B&[email protected]@@@#?:::::[email protected]@[email protected]@@[email protected]@B::^Y&@@[email protected]@^:^^^!YJ                            
// .  ~JYJ.:::^^^^^^^^::[email protected]&Y55!^^::^^^^:??:^^5~^:??:^^^::JPPGPY^^^::::^P?J.                         
// 7&BJ7!!YYYG!:^^^^^^^^::^~^^::::^^^~~^^^:^^:^:::^^::^^^^^^::^~^:^^:5PYYJ~77P&~                       
//   ~?7?YYYYG~:^^^^^^^^^^^^^^^^^^^:[email protected]@~^:?&B:^~P~^^^::^^^^^^^^^^^^^:5PY!.77??.                        
//     .??~~~::^^^^^^^^^^^^^^^^^^^^^^[email protected]@@P&@@[email protected]@@7^^?Y:^^^^^^^^^^^^^:^~7Y~                            
//    5B7YYYY5~^^^^^^^^^^^^^^^^^^^^^:[email protected]@@@@@@@@@@@&@&5:^^^^^^^^^^^^^[email protected]                           
//    !P! ..  #Y::^^^^^^^^^^^^^^^^^^^^:~~^5B&@@GBB7~!^:^^^^^^^^^^^^:&B^  :Y5       ?~   :7^            
//          ~Y7YP7::^^^^^^^^^^^^^^^^^^^::J~:^!~::::::^^^^^^^^^^^^^^@:             .BPP~YPB7            
//          @~::~!~J^^^^^^^^^^^^^^^^^^^J&@@Y:::^^^^^^^^^^^^^^^^^^^^B7               JPGG5.             
//          @~:^::~7^^^^^^^^^^^^^^^^^:^@@@5^::::::^^^^^^^^^^^^^^^^^:!#~           .&GY:7P#Y            
//          BJ^^^^^:^^^^^^::::::::::^[email protected]@@P7??????^::::::^^^^^^^^^^^:&7            ::   .:.            
//           &?:^^^^^^^^^:~?J&&&&&&&&@@@@@@@@@@@@@&&&&&#7^^^^^^^^^^^.&7                                
//          BJ^^^^^^^^^^^:[email protected]@@&&&&&&&&@@@Y7??????#&&&&&#?^^^^^^^^^^:#?                                 
//         BJ^:^^^^^^^^^^^:^J?::::::[email protected]@@!.::::::::::::::^^^^^^^^^^#!                                  
//        ^&^:^^^^^^^^^^^^^^::!!G####&@@@&##########Y!!!:^^^^^^^^^^&^                                  
//       !&:^^^^^^^^^^^^^^^:~#@@@@@@@@@@@@@@@@@@@@@@@@@@5^^^^^^^^^^:@^                                 
//     ^G?:^^^^^^^^^^^^^^^^:^5&@@?:^:[email protected]@@!:^^^^^^^:?YYYJ^^^^^^^^^^^:&!                                 
//     5#.^^^^^^^^^^^^^^^^^^^:^^^^^^:[email protected]@@?::^^^^^^^:::::^^^^^^^^^^^^:&!                                
//    PG:^^^^^^^^^^^^^^^^^^^^^^^^^^^:[email protected]@@@Y^^^^^^^^^^^^^^^^^^^^^^^^^:JP^                               
//    GG:^^^^^^^^^^^^^^^^^^^^^^^^^^^^^[email protected]@@@5:^^^^^^^^^^^^^^^^^^^^^^^^.#5                               

// add a view for the leaderboard

// add erc1155 claim if holiday event is true. Make sure there is a block limit, greater than block.timestamp + 3 Days turns off the event. 
// Store block.timestamp as variable so it can be updated to latest block.timestamp so we can have multiple events 
// variables for the erc1155 holiday event nft so can be changed.


pragma solidity 0.8.7;









contract GhostStaking is ReentrancyGuard, Ownable, Pausable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC721Enumerable public nft; //0xfb6f2e0DC62092B7c44e972773d7BA218b2e1BD2
    IERC20 public token; //0xE43c4a30CC4D3292a99cdE82940117dca49DAb75
    uint256 public tokenDecimals; // usually 18
    uint256 public rewardRate = 100; //Trash / Day
    uint256 public maxWithdrawPercentageOfContract = 500; // 500 = 0.5%, 5000 = 5%, 20000 = 20%, etc. PER NFT 
    uint256 public maxWithdrawPercentageOfContractDenominator = 100000;
    bool public maxMultiplier = true;
    uint256 public maxMultiplierCap = 1000; // 1000 / 10 = 10x max cap
    bool public bonusMultiplier = true; // earn up to % more based on number of pandaz owned.
    uint256 public bonusMultiplierAmount = 10; // extra bonus 10 = 1%, 20 = 2%

    constructor(IERC721Enumerable _nft, IERC20 _token, uint256 _tokenDecimals){
        nft = _nft;
        token = _token;
        tokenDecimals = _tokenDecimals;
        //create a null stakers value at index 0
        stakers.push(Stakers(address(0),999999999, block.timestamp));
    }

    uint256[] SM_Multipliers = [
        300,
        5,
        5,
        5,
        5,
        10,
        10
        ];
    uint256[] SM_TokenIds = [
        2028626844729816297473413048497949099433804772995310846604280455040849674265, 
        2028626844729816297473413048497949099433804772995310846604280453941338050908, 
        2028626844729816297473413048497949099433804772995310846604280456140361306460,
        2028626844729816297473413048497949099433804772995310846604280457239873029792,
        2028626844729816297473413048497949099433804772995310846604280458339384657568,
        2028626844729816297473413048497949099433804772995310846604280459438896189788,
        2028626844729816297473413048497949099433804772995310846604280460538407817564
        ];
    address[] public SM_Contracts = [
        0x2953399124F0cBB46d2CbACD8A89cF0599974963,
        0x2953399124F0cBB46d2CbACD8A89cF0599974963,
        0x2953399124F0cBB46d2CbACD8A89cF0599974963,
        0x2953399124F0cBB46d2CbACD8A89cF0599974963,
        0x2953399124F0cBB46d2CbACD8A89cF0599974963,
        0x2953399124F0cBB46d2CbACD8A89cF0599974963,
        0x2953399124F0cBB46d2CbACD8A89cF0599974963
        ];

    

    event Stake(address _owner);
    event Unstake(address _owner, uint256 _amount);
    event Claim(address _owner, uint256 _amount);

    struct Stakers {
        address owner;
        uint256 tokenId;
        uint256 stakedTime;
    }

    Stakers[] public stakers;

    mapping(uint => uint) public tokenIdToStakersIndex;
    

    struct Leaderboards {
        address owner;
        uint256 totalClaimed;
        uint256 totalStaked;
        
        address[] ownerMem;
        uint256[] totalClaimedMem;
        uint256[] totalStakedMem;
    }
    Leaderboards[] public leaderboards;
    Leaderboards public leaderboardsAll;
    uint256 leaderboardSize = 0;
    mapping(address => Leaderboards) public userStats;


    function updateLeaderboards(uint256 _staked,uint256 _claimed) internal {
        uint _len = leaderboards.length;
        uint _counter = 0;
        //uint _index = 0;
        for(uint i=0; i<_len; i++){
            if(_counter == 0){
                if(leaderboards[i].owner == msg.sender){
                    /// store the info
                    leaderboards[i].totalClaimed += _claimed;
                    leaderboards[i].totalStaked = _staked;
                    userStats[msg.sender] = leaderboards[i];
                    _counter++;
                }
            }
        }
        if(_counter==0){
            Leaderboards memory newEntry;
            newEntry.owner = msg.sender;
            newEntry.totalClaimed += _claimed;
            newEntry.totalStaked = _staked;
            leaderboards.push(newEntry);
            //add to userStats
            userStats[msg.sender] = newEntry;
        }

    }

    function viewLeaderboards() public view returns(address[] memory owners, uint[] memory totalStaked, uint[] memory totalClaimed){
        uint _len = leaderboards.length;
        address[] memory _addr = new address[](_len);
        uint[] memory _staked = new uint[](_len);
        uint[] memory _claimed = new uint[](_len);
        for(uint i=0;i<_len;i++){
            _addr[i] = leaderboards[i].owner;
            _staked[i] = leaderboards[i].totalStaked;
            _claimed[i] = leaderboards[i].totalClaimed;
        }
        return (_addr,_staked,_claimed);
    }

    

    function stake() external nonReentrant whenNotPaused{
        uint _bal = nft.balanceOf(msg.sender);
        require( _bal > 0 );
        uint[] memory _tokenIds = getTokenIdsOfOwner(msg.sender);
        uint _len = _tokenIds.length;
        for (uint i = 0; i < _len; i++) {
            //check if token exists already in stakers. If it does and owner is different, change to new owner and update timestamp, otherwise skip it. Else push to stakers.
            if (tokenIdToStakersIndex[_tokenIds[i]] > 0 ){
                Stakers storage stakedToken = stakers[tokenIdToStakersIndex[_tokenIds[i]]];
                if (stakedToken.owner != msg.sender){
                    stakedToken.owner = msg.sender;
                    stakedToken.stakedTime = block.timestamp;
                }
            }
            else {
                stakers.push(Stakers(msg.sender,_tokenIds[i], block.timestamp));
                tokenIdToStakersIndex[_tokenIds[i]] = stakers.length - 1;
            }
        }
        updateLeaderboards(_bal, 0);
        emit Stake(msg.sender);
    }

    function unstake() external nonReentrant whenNotPaused{
        // Not really needed since staking just overwrites the previous owner info
        require(nft.balanceOf(msg.sender)>0);
        uint[] memory _tokenIds = getTokenIdsOfOwner(msg.sender);
        uint _len = _tokenIds.length;
        uint _rewards = 0;
        for (uint i = 0; i < _len; i++) {
            if (tokenIdToStakersIndex[_tokenIds[i]] > 0 ){
                Stakers storage stakedToken = stakers[tokenIdToStakersIndex[_tokenIds[i]]];
                if (stakedToken.owner == msg.sender){
                    // get timestamp and calculate rewards
                    uint _stakedAt = stakedToken.stakedTime;
                    _rewards += rewardMath(_stakedAt);
                    // reset timestamp
                    stakedToken.stakedTime = block.timestamp;
                    stakedToken.owner = address(0);
                }
            }
        }        
        // get multiplier
        _rewards = _rewards * ( 100 + getMultiplier(msg.sender)) / 100 ;
        // send rewards
        _rewards = sendTokens(_rewards);
        updateLeaderboards(0, _rewards);
        emit Unstake(msg.sender, _rewards);
    }

    function claimRewards() external nonReentrant whenNotPaused{
        uint _bal = nft.balanceOf(msg.sender);
        require( _bal > 0 );
        uint[] memory _tokenIds = getTokenIdsOfOwner(msg.sender);
        uint _len = _tokenIds.length;
        uint _rewards = 0;
        for (uint i = 0; i < _len; i++) {
            if (tokenIdToStakersIndex[_tokenIds[i]] > 0 ){
                Stakers storage stakedToken = stakers[tokenIdToStakersIndex[_tokenIds[i]]];
                if (stakedToken.owner == msg.sender){
                    // get timestamp and calculate rewards
                    uint _stakedAt = stakedToken.stakedTime;
                    _rewards += rewardMath(_stakedAt);
                    // reset timestamp
                    stakedToken.stakedTime = block.timestamp;
                }
            }
        }
        // get multiplier
        _rewards = _rewards * ( 100 + getMultiplier(msg.sender)) / 100 ;
        // send rewards
        _rewards = sendTokens(_rewards);
        updateLeaderboards(_bal, _rewards);
        emit Claim(msg.sender, _rewards);
        return;
    }

    function sendTokens(uint256 _rewardAmount) internal returns(uint256){
        uint _rewards = _rewardAmount;
        uint _maxRewards = viewMaxReward(); 
        if(_rewards>=_maxRewards){
            _rewards = _maxRewards;
        }
        token.safeTransfer(msg.sender,_rewards);
        return _rewards;
    }

    


    // Utility functions ///////////////////////////////
    function viewMaxReward() public view returns(uint256){
        uint _bal = token.balanceOf(address(this));
        uint _maxRewards = _bal * maxWithdrawPercentageOfContract / maxWithdrawPercentageOfContractDenominator;
        return _maxRewards;
    }

    function viewAccumulatedRewards(address _account) public view returns(uint256){
        uint[] memory _tokenIds = getTokenIdsOfOwner(_account);
        uint _len = _tokenIds.length;
        uint _rewards = 0;
        for (uint i = 0; i < _len; i++) {
            if (tokenIdToStakersIndex[_tokenIds[i]] > 0 ){
                Stakers storage stakedToken = stakers[tokenIdToStakersIndex[_tokenIds[i]]];
                if (stakedToken.owner == _account){
                    // get timestamp and calculate rewards
                    uint _stakedAt = stakedToken.stakedTime;
                    _rewards += ( (rewardRate * ( 10 ** tokenDecimals ) ) * (block.timestamp - _stakedAt) / 1 days )  ;
                }
            }
        }
        _rewards = _rewards * ( 100 + getMultiplier(_account)) / 100;
        uint _maxRewards = viewMaxReward(); 
        if(_rewards>=_maxRewards){
            _rewards = _maxRewards;
        }
        return _rewards;
    }

    function rewardMath(uint256 _stakedAt ) internal view returns(uint256){
        uint _reward =  0;
        //_reward = ( (rewardRate * ( 10 ** tokenDecimals ) ) * (block.timestamp - _stakedAt) / 1 days ) * ( 100 + getMultiplier(_account)) / 100 ; // num * (1 + %) = % of num added to num. So we need to add 100 and divide by 100 to remove decimals
        _reward = ( (rewardRate * ( 10 ** tokenDecimals ) ) * (block.timestamp - _stakedAt) / 1 days ); 
        return  _reward; 
    }

    function getMultiplier(address _account) public view returns (uint256){ 
        uint _stakingMultiplier = 0;
        uint256 _totalTokensHeld = 0;
        uint256 _len = SM_Contracts.length;
        for (uint i = 0; i < _len; i++) {
            _totalTokensHeld = walletHoldsToken(_account, SM_Contracts[i], SM_TokenIds[i]);
            _stakingMultiplier += SM_Multipliers[i] * _totalTokensHeld;
        }
        if(maxMultiplier == true){
            if(_stakingMultiplier>maxMultiplierCap){
                _stakingMultiplier = maxMultiplierCap;
            }
        }
        if(bonusMultiplier == true){
            _stakingMultiplier += getBonusMultiplier(_account);
        }
        return _stakingMultiplier;
    }

    function getBonusMultiplier(address _account) internal view returns(uint256){
        // extra bonus 10 = 1%, 20 = 2%, up to 5% extra
        uint256 _bonus = 0;
        uint256 _tokensOwned = nft.balanceOf(_account);
        if(_tokensOwned>=10){_bonus +=bonusMultiplierAmount;}
        if(_tokensOwned>=20){_bonus +=bonusMultiplierAmount;}
        if(_tokensOwned>=30){_bonus +=bonusMultiplierAmount;}
        if(_tokensOwned>=40){_bonus +=bonusMultiplierAmount;}
        if(_tokensOwned>=50){_bonus +=bonusMultiplierAmount;}
        return _bonus;
    }

    function walletHoldsToken(address _account, address _contract, uint256 _id) internal view returns (uint256) {
        IERC1155 token1155 = IERC1155(_contract);
        return token1155.balanceOf(_account, _id); 
    }

    function getTokenIdsOfOwner(address _owner) public view returns(uint[] memory tokensOfOwner){
        uint _len = nft.balanceOf(_owner);
        uint[] memory _tokensOfOwner = new uint[](_len);
        for (uint i = 0; i < _len; i++){
            _tokensOfOwner[i] = nft.tokenOfOwnerByIndex(_owner,i);
        }
        return _tokensOfOwner;
    }

    function getStakedTokenIdsOfOwner(address _owner) public view returns(uint[] memory stakedTokensOfOwner){
        uint[] memory _tokenIds = getTokenIdsOfOwner(_owner);
        uint _len = _tokenIds.length;
        uint[] memory _stakedTokenIds = new uint[](_len);
        uint _stakedCounter = 0;
        for (uint i = 0; i < _len; i++) {
            if (tokenIdToStakersIndex[_tokenIds[i]] > 0 ){
                Stakers storage stakedToken = stakers[tokenIdToStakersIndex[_tokenIds[i]]];
                if (stakedToken.owner == _owner){
                    _stakedTokenIds[_stakedCounter]=stakedToken.tokenId;
                    _stakedCounter++;
                }
            }
        }
        return _stakedTokenIds;
    }

    function getIndexOfStakedTokenIdsOfOwner(address _owner) public view returns(uint[] memory indxeOfStakedTokensOfOwner){
        uint[] memory _tokenIds = getTokenIdsOfOwner(_owner);
        uint _len = _tokenIds.length;
        uint[] memory _stakedTokenIds = new uint[](_len);
        uint _stakedCounter = 0;
        for (uint i = 0; i < _len; i++) {
            if (tokenIdToStakersIndex[_tokenIds[i]] > 0 ){
                Stakers storage stakedToken = stakers[tokenIdToStakersIndex[_tokenIds[i]]];
                if (stakedToken.owner == _owner){
                    _stakedTokenIds[_stakedCounter]=tokenIdToStakersIndex[_tokenIds[i]];
                    _stakedCounter++;
                }
            }
        }
        return _stakedTokenIds;
    }

    function viewOwnerNFTBalance(address _owner) public view returns(uint balanceOfOwner){
        return nft.balanceOf(_owner);
    }

    function viewContractRewardBalance() public view returns(uint256){
        return token.balanceOf(address(this));
    }

    // OWNER FUNCTIONS /////////////
    // remove rewards in case of bad actors
    function removeRewardTokens(uint256 _tokenAmount) external onlyOwner{
        token.safeTransfer(msg.sender, _tokenAmount);
    }

    function setMaxWithdrawPercentage(uint _percentage, uint _percentageDenominator)external onlyOwner{
        maxWithdrawPercentageOfContract = _percentage;
        maxWithdrawPercentageOfContractDenominator = _percentageDenominator;
    }

    function setBonusMultiplier(bool _bool, uint _mult) external onlyOwner{
        bonusMultiplier = _bool;
        bonusMultiplierAmount = _mult;
    }

    function setRewardRate(uint _rewardRate) external onlyOwner{
        rewardRate = _rewardRate;
    }

    // remove staking multiplier
    function removeSM(uint _index) external onlyOwner{
        require(_index < SM_Contracts.length, "index out of bound");
        uint256 _len = SM_Contracts.length;
        for (uint i = _index; i < _len - 1; i++) {
            SM_Contracts[i] = SM_Contracts[i + 1];
            SM_TokenIds[i] = SM_TokenIds[i + 1];
            SM_Multipliers[i] = SM_Multipliers[i + 1];
        }
        SM_Contracts.pop();
        SM_TokenIds.pop();
        SM_Multipliers.pop();
    }

    // add staking multiplier
    function addSM(address _contract, uint256 _tokenId, uint256 _stakingMultiplier) external onlyOwner{
        SM_Contracts.push(_contract);
        SM_TokenIds.push(_tokenId);
        SM_Multipliers.push(_stakingMultiplier);
    }
    function SM_viewContracts() public view returns (address[] memory) {
        return SM_Contracts;
    }

    function SM_viewTokenIds() public view returns (uint256[] memory) {
        return SM_TokenIds;
    }

    function SM_viewMultipliers() public view returns (uint256[] memory) {
        return SM_Multipliers;
    }

    function setTokenDecimals(uint _tokenDecimals) external onlyOwner{
        tokenDecimals = _tokenDecimals;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }


}