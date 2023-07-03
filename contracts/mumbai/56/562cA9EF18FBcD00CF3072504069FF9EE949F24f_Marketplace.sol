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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

pragma solidity ^0.8.16;

interface IEnvisionToken {
    function updateUserContractAddress(
        address _newContractAddress
    ) external returns (bool);

    function uri(
        uint256 tokenId,
        uint256 _tokenType
    ) external view returns (string memory);

    function _setURI(
        uint256 tokenId,
        uint256 _tokenType,
        string memory tokenURI
    ) external;

    function updateMarketplaceAddress(address contractAddress) external;

    function _setBaseURI(string memory baseURI) external;

    function addMintCopiesAccess(address walletAddress) external;

    function removeMintCopiesAccess(address walletAddress) external;

    function updateTokenOwnerBatch(
        address[] memory _newOwners,
        uint256[] memory _tokenIds
    ) external;

    function tokenOwner(uint256 _id) external view returns (address);

    function mint(
        string memory _tokenURIForExclusive,
        string memory _tokenURIForLicense
    ) external;

    function mintBatch(
        uint256 _totalNFT,
        string[2][] memory _tokenURI
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external;

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory data
    ) external;

    function mintCopiesBatch(
        uint256[] memory ids,
        uint256[] memory amounts,
        address _buyerAddress
    ) external;

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function isApprovedForAll(
        address _owner,
        address _operator
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface IFeedVIS {
    function estimateAmountsOut(
        address tokenIn,
        uint128 amountIn,
        uint32 secondsAgo
    ) external view returns (uint amountsOut);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface IUser {
    function getUserBlackListStatus(
        address _userAddress
    ) external view returns (bool);

    function getUserStakingStatus(
        address _userAddress
    ) external view returns (bool);

    function getjrAdminStatus(
        address _jrAdminAddress
    ) external view returns (bool);

    function getKycAdminStatus(address _address) external view returns (bool);

    function getUserKYCLevel(
        address _userAddress
    ) external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./interfaces/IFeedVIS.sol";
import "./interfaces/IUser.sol";
import "./interfaces/IEnvisionToken.sol";

contract Marketplace is Ownable, ReentrancyGuard, ERC1155Holder {
    IEnvisionToken public nftContract;
    IUser public userContract;
    IFeedVIS public priceContract;
    using SafeERC20 for IERC20;
    IERC20 public tokenContract;
    using Counters for Counters.Counter;
    Counters.Counter public saleCounter;
    uint256 public maxPrice;
    uint256 public minPrice;
    address public feeCollectionWallet;
    uint256 public txnFee;
    address public USDCContract;
    // address public contractAddress = address(this);

    event NFTMarkedForSale(
        uint256 tokenId,
        uint256 itemPrice,
        uint8 saleType,
        uint256 indexed saleId
    );
    event NFTSold(uint8[] saleId, uint256 totalPrice, address buyer);
    event SellerWithdraws(uint256 amount, uint256 time, address sellerAddress);

    struct NFTSale {
        uint256 saleId; //on every sale this will increase
        uint256 tokenId;
        uint256 itemPrice; //price for transfering the price receiving access
        uint256 itemTotalPrice; //price including platform fees
        uint256 createdTimestamp;
        address sellerAddress;
        address buyerAddress;
        uint8 saleType; //1 for exclusive and 2 for license
        uint8 status; //1-new, 2-completed 3 - hold
    }

    mapping(uint256 => NFTSale) public allSales;
    mapping(address => uint256[]) public userSales;
    mapping(address => uint256[]) public userBuys;
    mapping(address => uint256) public sellerBalance;
    mapping(uint256 => mapping(uint8 => uint8)) public tokenSaleStatus;

    constructor(
        address _nftContractAddress,
        address _tokenContractAddress, //VIS token
        address _userContractAddress,
        address _priceContractAddress, //Uniswap V3 price conversion contract
        address _usdcContractAddress //USDC contract address for conversion
    ) {                                             
        require(_nftContractAddress != address(0));
        require(_tokenContractAddress != address(0));
        require(_userContractAddress != address(0));
        require(_priceContractAddress != address(0));
        require(_usdcContractAddress != address(0));
        nftContract = IEnvisionToken(_nftContractAddress);
        tokenContract = IERC20(_tokenContractAddress);
        userContract = IUser(_userContractAddress);
        priceContract = IFeedVIS(_priceContractAddress);
        USDCContract = _usdcContractAddress;
        minPrice = 1 * (10 ** 2); // Using 2 decimal for USDC
        maxPrice = 10000 * (10 ** 2); // Using 2 decimal for USDC
        txnFee = 5;
    }

    function updateTokenAddress(
        address _newTokenContractAddress
    ) public onlyOwner returns (bool) {
        require(_newTokenContractAddress != address(0));
        tokenContract = IERC20(_newTokenContractAddress);
        return true;
    }

    function updateNFTContractAddress(
        address _newContractAddress
    ) public onlyOwner returns (bool) {
        require(_newContractAddress != address(0));
        nftContract = IEnvisionToken(_newContractAddress);
        return true;
    }

    function updateUserContractAddress(
        address _newContractAddress
    ) public onlyOwner returns (bool) {
        require(_newContractAddress != address(0));
        userContract = IUser(_newContractAddress);
        return true;
    }

    function updatePriceContract(
        address _newAddress
    ) public onlyOwner returns (bool) {
        require(_newAddress != address(0));
        priceContract = IFeedVIS(_newAddress);
        return true;
    }

    function updateUSDCContract(
        address _newAddress
    ) public onlyOwner returns (bool) {
        require(_newAddress != address(0));
        USDCContract = _newAddress;
        return true;
    }

    function updateFeeCollectionWallet(
        address _newAddress
    ) public onlyOwner returns (bool) {
        require(address(_newAddress) != address(0), "Wrong Address");
        feeCollectionWallet = _newAddress;
        return true;
    }

    function updateTxnFee(uint256 _txnFee) public onlyOwner returns (bool) {
        txnFee = _txnFee;
        return true;
    }

    function updatPriceConstaraints(
        uint256 _minPrice,
        uint256 _maxPrice
    ) public onlyOwner returns (bool) {
        minPrice = _minPrice;
        maxPrice = _maxPrice;
        return true;
    }

    function markNFTForSale(
        uint256[]memory _tokenIds,
        uint256[]memory _itemPrices, //Price is stored in USDC | Use decimal 2 i.e for 1 USDC use 100
        uint8[]memory _saleTypes
    ) public returns (bool) {
        require((_tokenIds.length == _itemPrices.length) &&  (_itemPrices.length==_saleTypes.length),"Give Valid inputs");
         require(
            !userContract.getUserBlackListStatus(msg.sender),
            "User is blacklisted"
        );
         require(
            nftContract.isApprovedForAll(msg.sender, address(this)),
            "Approval not given"
        );
         for (uint i=0;i< _tokenIds.length;i++)
     {
        
        require(
            ((_itemPrices[i] >= minPrice) && (_itemPrices[i] <= maxPrice)),
            "Item price is incorrect"
        );
       
        require(
            nftContract.tokenOwner(_tokenIds[i]) == msg.sender,
            "Caller is not the owner of the token"
        );
       
        require(
            (tokenSaleStatus[_tokenIds[i]][_saleTypes[i]] == 0) ||
                (tokenSaleStatus[_tokenIds[i]][_saleTypes[i]] == 2),
            "Token is already marked for sale for the entered sale type."
        );
        saleCounter.increment();
         
        if (_saleTypes[i] == 1) {
            NFTSale memory currentSale = NFTSale(
                saleCounter.current(),
                _tokenIds[i],
                _itemPrices[i],
                _itemPrices[i] + ((_itemPrices[i] * txnFee) / 100),
                block.timestamp,
                msg.sender,
                address(0),
                1,
                1
            );
           
            allSales[saleCounter.current()] = currentSale;
            userSales[msg.sender].push(saleCounter.current());
            emit NFTMarkedForSale(
                _tokenIds[i],
                _itemPrices[i],
                _saleTypes[i],
                saleCounter.current() //saleId
            );
        } else if (_saleTypes[i] == 2) {
            NFTSale memory currentSale = NFTSale(
                saleCounter.current(), //saleId
                _tokenIds[i],
                _itemPrices[i],
                _itemPrices[i] + ((_itemPrices[i] * txnFee) / 100),
                block.timestamp,
                msg.sender,
                address(0),
                2,
                1
            );
            allSales[saleCounter.current()] = currentSale;
            userSales[msg.sender].push(saleCounter.current());
            emit NFTMarkedForSale(
                _tokenIds[i],
                _itemPrices[i],
                _saleTypes[i],
                saleCounter.current() //saleId
            );
        }
        tokenSaleStatus[_tokenIds[i]][_saleTypes[i]] = 1;
      }
        return true;
    }

    function holdNFTSale(uint256 _saleId) public {
        require(
            msg.sender == allSales[_saleId].sellerAddress,
            "Can only be called by NFT owners"
        );
        require(
            allSales[_saleId].status == 1,
            "Sale is not opened for the given saleId"
        );
        allSales[_saleId].status = 3; //status 3 = hold
    }

    function reopenNFTSale(uint256 _saleId) public {
        require(
            msg.sender == allSales[_saleId].sellerAddress,
            "Can only be called by NFT owners"
        );

        require(
            allSales[_saleId].status == 3,
            "Sale is not in hold for the given saleId"
        );
        allSales[_saleId].status = 1;
    }

    function updateNFTPrice(uint256 newPrice, uint256 _saleId) public {
        require(
            msg.sender == allSales[_saleId].sellerAddress ||
                msg.sender == owner(),
            "Can only be called by NFT owners"
        );
        require(
            allSales[_saleId].status == 1,
            "Sale is not opened for the given saleId"
        );
        allSales[_saleId].itemPrice = newPrice;
        allSales[_saleId].itemTotalPrice =
            newPrice +
            ((newPrice * txnFee) / 100);
    }

    function separateTypes(
        uint8[] memory _saleIds,
        address _buyerAddress
    )
        internal
        view
        returns (
            uint256[] memory exclusiveIds,
            uint256[] memory licenseIds,
            uint256[] memory licenseAmounts,
            NFTSale[] memory currentSale
        )
    {
        exclusiveIds = new uint256[](_saleIds.length);
        licenseIds = new uint256[](_saleIds.length);
        licenseAmounts = new uint256[](_saleIds.length);
        currentSale = new NFTSale[](_saleIds.length);

        uint256 exclusiveCounter = 0;
        uint256 licenseCounter = 0;
        
        for (uint256 i = 0; i < _saleIds.length; i++) {
            NFTSale storage _sale=allSales[_saleIds[i]];
            require(
                _sale.status == 1,
                "Current sale is not available or in hold for some saleId"
            );
            require(
                (_sale.saleType == 1) ||
                    (_sale.saleType == 2),
                "Some NFT is not available for Exclusive or license sale type"
            );
            require(
                tokenSaleStatus[_sale.tokenId][_sale.saleType] ==
                    1,
                "tokenSaleStatus for some saleIds is not 1"
            );
            currentSale[i] = _sale;
            if (_sale.saleType == 1) {
                exclusiveIds[exclusiveCounter] = currentSale[i].tokenId;
                exclusiveCounter++;
            } else {
                licenseIds[licenseCounter] = currentSale[i].tokenId;
                licenseAmounts[licenseCounter] = 1;
                licenseCounter++;
            }
        }

        if (exclusiveIds.length > 0) {
            require(
                (userContract.getUserKYCLevel(_buyerAddress) == 2) ||
                    (userContract.getUserKYCLevel(_buyerAddress) == 3),
                "Not eligible for purchase"
            );
        } else if (licenseIds.length > 0) {
            require(
                (userContract.getUserKYCLevel(_buyerAddress) == 1) ||
                    (userContract.getUserKYCLevel(_buyerAddress) == 2) ||
                    (userContract.getUserKYCLevel(_buyerAddress) == 3),
                "Not eligible for purchase"
            );
        }

        return (exclusiveIds, licenseIds, licenseAmounts, currentSale);
    }

    function calculateFinalPrice(
        NFTSale[] memory currentSale,
        address _buyerAddress
    )
        internal
        view
        returns (uint256 saleConsiderationPriceVIS, uint256 contractFeeVIS)
    {
        uint256 saleConsiderationPrice; //price buyer needs to pay
        uint256 itemTotalPrices; //price without transaction fees

        if (userContract.getUserStakingStatus(_buyerAddress))
            for (uint256 i = 0; i < currentSale.length; i++) {
                {
                    saleConsiderationPrice += currentSale[i].itemPrice;
                    itemTotalPrices += currentSale[i].itemPrice;
                }
            }
        else
            for (uint256 i = 0; i < currentSale.length; i++) {
                {
                    saleConsiderationPrice += currentSale[i].itemTotalPrice;
                    itemTotalPrices += currentSale[i].itemPrice;
                }
            }

        //converting price USDC to VIS
        uint256 contractFee = saleConsiderationPrice - itemTotalPrices;
        saleConsiderationPriceVIS =
            saleConsiderationPrice *
            priceContract.estimateAmountsOut(USDCContract, 10000, 1);
        contractFeeVIS =
            contractFee *
            priceContract.estimateAmountsOut(USDCContract, 10000, 1);

        return (saleConsiderationPriceVIS, contractFeeVIS);
    }

    function buyNFT(
        uint8[] memory _saleIds
    ) public nonReentrant {
        uint8[] memory saleIDS = new uint8[](_saleIds.length);
        saleIDS = _saleIds;
        address buyerAddress = msg.sender;
        require(
            !userContract.getUserBlackListStatus(msg.sender),
            "User is blacklisted"
        );
        (
            uint256[] memory exclusiveIds,
            uint256[] memory licenseIds,
            // uint256[] memory exclusiveAmounts,
            uint256[] memory licenseAmounts,
            NFTSale[] memory currentSale
        ) = separateTypes(_saleIds, buyerAddress);

        (
            uint256 saleConsiderationPriceVIS,
            // uint256 itemTotalPriceVIS,
            uint256 contractFeeVIS
        ) = calculateFinalPrice(currentSale, buyerAddress);

        require(
            tokenContract.allowance(msg.sender, address(this)) >=
                saleConsiderationPriceVIS,
            "Not enough balance approved to the contract"
        );

        tokenContract.safeTransferFrom(
            msg.sender,
            feeCollectionWallet,
            contractFeeVIS
        );

        for (uint8 i = 0; i < exclusiveIds.length; i++) {
            if (exclusiveIds[i] != 0) {
                nftContract.safeTransferFrom(
                    nftContract.tokenOwner(exclusiveIds[i]),
                    msg.sender,
                    exclusiveIds[i],
                    1,
                    ""
                );
            }
        }

        nftContract.mintCopiesBatch(licenseIds, licenseAmounts, msg.sender);
        address[] memory newOwners = new address[](exclusiveIds.length);
        for (uint256 i = 0; i < exclusiveIds.length; i++) {
            newOwners[i] = msg.sender;
            tokenSaleStatus[exclusiveIds[i]][1] = 2; //updating tokenSaleStatus for exclusive type to 2
            tokenSaleStatus[exclusiveIds[i]][2] = 2; //updating tokenSaleStatus for license type to
        }
        nftContract.updateTokenOwnerBatch(newOwners, exclusiveIds);
        for (uint256 i = 0; i < _saleIds.length; i++) {
            tokenContract.safeTransferFrom(
                msg.sender,
                currentSale[i].sellerAddress,
                currentSale[i].itemPrice *
                    priceContract.estimateAmountsOut(USDCContract, 10000, 1)
            );
            if (currentSale[i].saleType == 1) {
                allSales[i].status = 2;
                allSales[i].buyerAddress = msg.sender;
            }
            userBuys[msg.sender].push(currentSale[i].saleId);
        }
        for (uint i=0;i< licenseIds.length;i++)
        {
            tokenSaleStatus[licenseIds[i]][2]=2;
        }
        
        emit NFTSold(saleIDS, saleConsiderationPriceVIS, msg.sender);
    }

    function getAllUserBuys(
        address _userAddress
    ) public view returns (uint256[] memory saleIds) {
        return userBuys[_userAddress];
    }

    function getAllUserSells(
        address _userAddress
    ) public view returns (uint256[] memory saleIds) {
        return userSales[_userAddress];
    }
}