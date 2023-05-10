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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
pragma solidity ^0.8.9;

interface IKnowledgeLayerCourse {
    struct Course {
        uint256 ownerId;
        uint256 platformId;
        uint256 price;
        address token;
        string dataUri;
    }

    function getCourse(uint256 _courseId) external view returns (Course memory);

    function buyCourse(uint256 _profileId, uint256 _courseId) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IKnowledgeLayerID {
    function balanceOf(address _user) external view returns (uint256);

    function mint(uint256 _platformId, string calldata _handle) external payable returns (uint256);

    function mintForAddress(
        address _address,
        uint256 _platformId,
        string calldata _handle
    ) external payable returns (uint256);

    function updateProfileData(uint256 _tokenId, string memory _newCid) external;

    function freeMint(uint256 _platformId, address _userAddress, string calldata _handle) external returns (uint256);

    function isValid(uint256 _tokenId) external view;

    function whitelistMint(
        uint256 _platformId,
        string calldata _handle,
        bytes32[] calldata _proof
    ) external payable returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function ownersOf(uint256 _tokenId1, uint256 _tokenId2) external view returns (address, address);

    function getOriginatorPlatformIdByAddress(address _address) external view returns (uint256);

    function isDelegate(uint256 _tokenId, address _address) external view returns (bool);

    function isOwnerOrDelegate(uint256 _tokenId, address _address) external view returns (bool);

    function ids(address _user) external view returns (uint256);

    function setHasActivity(uint256 _profileId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IKnowledgeLayerPlatformID is IERC721 {
    struct Platform {
        uint256 id;
        string name;
        string dataUri;
        uint16 originFee;
        uint16 buyFee;
        uint256 postingFee;
        address signer;
    }

    function balanceOf(address _platformAddress) external view returns (uint256);

    function getOriginFee(uint256 _platformId) external view returns (uint16);

    function getBuyFee(uint256 _platformId) external view returns (uint16);

    function getSigner(uint256 _platformId) external view returns (address);

    function getPlatform(uint256 _platformId) external view returns (Platform memory);

    function mint(string memory _platformName) external payable returns (uint256);

    function mintForAddress(string memory _platformName, address _platformAddress) external payable returns (uint256);

    function totalSupply() external view returns (uint256);

    function updateProfileData(uint256 _platformId, string memory _newCid) external;

    function updateOriginFee(uint256 _platformId, uint16 _originFee) external;

    function updateBuyFee(uint256 _platformId, uint16 _buyFee) external;

    function updateRecoveryRoot(bytes32 _newRoot) external;

    function updateMintFee(uint256 _mintFee) external;

    function withdraw() external;

    function isValid(uint256 _platformId) external view;

    function updateMinArbitrationFeeTimeout(uint256 _minArbitrationFeeTimeout) external;

    function getPostingFee(uint256 _platformId) external view returns (uint256);

    function updatePostingFee(uint256 _platformId, uint256 _postingFee) external;

    function ids(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IKnowledgeLayerID} from "./interfaces/IKnowledgeLayerID.sol";
import {IKnowledgeLayerPlatformID} from "./interfaces/IKnowledgeLayerPlatformID.sol";
import {IKnowledgeLayerCourse} from "./interfaces/IKnowledgeLayerCourse.sol";

contract KnowledgeLayerEscrow is Ownable {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    /**
     * @notice Payment type
     */
    enum PaymentType {
        Release,
        Reimburse
    }

    /**
     * @notice Transaction struct
     * @param id Id of the transaction
     * @param sender The party paying the escrow amount
     * @param receiver The intended receiver of the escrow amount
     * @param token The token used for the transaction
     * @param amount The amount of the transaction EXCLUDING FEES
     * @param courseId The ID of the associated course
     * @param buyPlatformId The ID of the platform where the course is being bought
     * @param protocolFee The % fee (per ten thousands) to be paid to the protocol
     * @param originFee The % fee (per ten thousands) to be paid to the platform where the course was created
     * @param buyFee The % fee (per ten thousands) to be paid to the platform where the course is being bought
     */
    struct Transaction {
        uint256 id;
        address sender;
        address receiver;
        address token;
        uint256 amount;
        uint256 courseId;
        uint256 buyPlatformId;
        uint16 protocolFee;
        uint16 originFee;
        uint16 buyFee;
    }

    // Divider used for fees
    uint16 private constant FEE_DIVIDER = 10000;

    // Index used to represent protocol where platform id is used
    uint8 private constant PROTOCOL_INDEX = 0;

    // Transaction id to transaction
    mapping(uint256 => Transaction) private transactions;

    // Transaction id counter
    Counters.Counter nextTransactionId;

    // Protocol fee per sale (percentage per 10,000, upgradable)
    uint16 public protocolFee;

    // Platform id to balance accumulated for fees for each token
    mapping(uint256 => mapping(address => uint256)) public platformBalance;

    // Address which will receive the protocol fees
    address payable public protocolTreasuryAddress;

    // KnowledgeLayerID contract
    IKnowledgeLayerID private knowledgeLayerId;

    // KnowledgeLayerPlatformID contract
    IKnowledgeLayerPlatformID private knowledgeLayerPlatformId;

    // KnowledgeLayerCourse contract
    IKnowledgeLayerCourse private knowledgeLayerCourse;

    // =========================== Events ==============================

    /**
     * @dev Emitted when a transaction is created
     */
    event TransactionCreated(
        uint256 id,
        uint256 senderId,
        uint256 receiverId,
        address token,
        uint256 amount,
        uint256 courseId,
        uint16 protocolFee,
        uint16 originFee,
        uint16 buyFee
    );

    /**
     * @dev Emitted when the protocol fee is updated
     */
    event ProtocolFeeUpdated(uint16 fee);

    /**
     * @dev Emitted when a payment is made for a transaction
     */
    event Payment(uint256 transactionId, PaymentType paymentType);

    // =========================== Modifiers ==============================

    /**
     * @notice Check if the given address is either the owner of the delegate of the given user
     * @param _profileId The TalentLayer ID of the user
     */
    modifier onlyOwnerOrDelegate(uint256 _profileId) {
        require(knowledgeLayerId.isOwnerOrDelegate(_profileId, _msgSender()), "Not owner or delegate");
        _;
    }

    // =========================== Constructor ==============================

    /**
     * @param _knowledgeLayerIdAddress Address of the KnowledgeLayerID contract
     */
    constructor(
        address _knowledgeLayerIdAddress,
        address _knowledgeLayerPlatformIdAddress,
        address _knowledgeLayerCourseAddress,
        address _protocolTreasuryAddress
    ) {
        knowledgeLayerId = IKnowledgeLayerID(_knowledgeLayerIdAddress);
        knowledgeLayerPlatformId = IKnowledgeLayerPlatformID(_knowledgeLayerPlatformIdAddress);
        knowledgeLayerCourse = IKnowledgeLayerCourse(_knowledgeLayerCourseAddress);
        nextTransactionId.increment();
        protocolTreasuryAddress = payable(_protocolTreasuryAddress);

        setProtocolFee(100);
    }

    // =========================== User functions ==============================

    function createTransaction(
        uint256 _profileId,
        uint256 _courseId,
        uint256 _platformId
    ) external payable returns (uint256) {
        IKnowledgeLayerCourse.Course memory course = knowledgeLayerCourse.getCourse(_courseId);
        (address sender, address receiver) = knowledgeLayerId.ownersOf(_profileId, course.ownerId);

        require(sender == _msgSender(), "Not the owner");

        IKnowledgeLayerPlatformID.Platform memory originPlatform = knowledgeLayerPlatformId.getPlatform(
            course.platformId
        );
        IKnowledgeLayerPlatformID.Platform memory buyPlatform = course.platformId != _platformId
            ? knowledgeLayerPlatformId.getPlatform(_platformId)
            : originPlatform;
        uint256 totalAmount = _getAmountWithFees(course.price, originPlatform.originFee, buyPlatform.buyFee);

        if (course.token == address(0)) {
            require(msg.value == totalAmount, "Non-matching funds");
        } else {
            require(msg.value == 0, "Non-matching funds");
        }

        uint256 id = nextTransactionId.current();

        nextTransactionId.increment();
        transactions[id] = Transaction({
            id: id,
            sender: sender,
            receiver: receiver,
            token: course.token,
            amount: course.price,
            courseId: _courseId,
            buyPlatformId: _platformId,
            protocolFee: protocolFee,
            originFee: originPlatform.originFee,
            buyFee: buyPlatform.buyFee
        });

        if (course.token != address(0)) {
            IERC20(course.token).safeTransferFrom(sender, address(this), totalAmount);
        }

        knowledgeLayerCourse.buyCourse(_profileId, _courseId);

        emit TransactionCreated(
            id,
            _profileId,
            course.ownerId,
            course.token,
            course.price,
            _courseId,
            protocolFee,
            originPlatform.originFee,
            buyPlatform.buyFee
        );

        return id;
    }

    function release(uint256 _profileId, uint256 _transactionId) public onlyOwnerOrDelegate(_profileId) {
        require(_transactionId < nextTransactionId.current(), "Invalid transaction id");
        Transaction memory transaction = transactions[_transactionId];

        require(transaction.receiver == knowledgeLayerId.ownerOf(_profileId), "Not the receiver");

        _distributeFees(_transactionId);

        _transferBalance(transaction.receiver, transaction.token, transaction.amount);

        emit Payment(_transactionId, PaymentType.Release);
    }

    // =========================== Platform functions ==============================

    /**
     * @dev Allows a platform owner to claim its balances accumulated from fees, for a specific token.
     * @param _platformId The ID of the platform.
     * @param _tokenAddress The address of the token to claim.
     */
    function claim(uint256 _platformId, address _tokenAddress) external {
        address payable recipient;

        if (owner() == _msgSender()) {
            require(_platformId == PROTOCOL_INDEX, "Access denied");
            recipient = protocolTreasuryAddress;
        } else {
            knowledgeLayerPlatformId.isValid(_platformId);
            recipient = payable(knowledgeLayerPlatformId.ownerOf(_platformId));
        }

        uint256 amount = platformBalance[_platformId][_tokenAddress];
        require(amount > 0, "Nothing to claim");
        platformBalance[_platformId][_tokenAddress] = 0;

        _transferBalance(recipient, _tokenAddress, amount);
    }

    // =========================== Owner functions ==============================

    /**
     * @dev Sets the protocol fee per sale
     * @param _protocolFee Protocol fee per sale (percentage per 10,000)
     */
    function setProtocolFee(uint16 _protocolFee) public onlyOwner {
        protocolFee = _protocolFee;

        emit ProtocolFeeUpdated(_protocolFee);
    }

    /**
     * @dev Sets the address which will receive the protocol fees
     * @param _protocolTreasuryAddress The address
     */
    function setProtocolTreasuryAddress(address payable _protocolTreasuryAddress) external onlyOwner {
        protocolTreasuryAddress = _protocolTreasuryAddress;
    }

    // =========================== Private functions ==============================

    function _getAmountWithFees(
        uint256 _amount,
        uint16 _originFee,
        uint16 _buyFee
    ) private view returns (uint256 totalEscrowAmount) {
        return _amount + ((_amount * (protocolFee + _originFee + _buyFee)) / FEE_DIVIDER);
    }

    function _distributeFees(uint256 _transactionId) private {
        Transaction storage transaction = transactions[_transactionId];
        IKnowledgeLayerCourse.Course memory course = knowledgeLayerCourse.getCourse(transaction.courseId);

        uint256 protocolFeeAmount = (transaction.protocolFee * transaction.amount) / FEE_DIVIDER;
        uint256 originFeeAmount = (transaction.originFee * transaction.amount) / FEE_DIVIDER;
        uint256 buyFeeAmount = (transaction.buyFee * transaction.amount) / FEE_DIVIDER;

        platformBalance[PROTOCOL_INDEX][transaction.token] += protocolFeeAmount;
        platformBalance[course.platformId][transaction.token] += originFeeAmount;
        platformBalance[transaction.buyPlatformId][transaction.token] += buyFeeAmount;
    }

    /**
     * @notice Transfers a token or ETH balance from the escrow to a recipient's address.
     * @param _recipient The address to transfer the balance to
     * @param _tokenAddress The token address, or zero address for ETH
     * @param _amount The amount to transfer
     */
    function _transferBalance(address _recipient, address _tokenAddress, uint256 _amount) private {
        if (address(0) == _tokenAddress) {
            payable(_recipient).call{value: _amount}("");
        } else {
            IERC20(_tokenAddress).transfer(_recipient, _amount);
        }
    }
}