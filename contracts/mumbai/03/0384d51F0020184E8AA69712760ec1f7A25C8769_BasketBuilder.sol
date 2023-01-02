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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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

// SPDX-License-Identifier: No License
pragma solidity >=0.8.17;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IProtonB} from "./external/charged-particles/IProtonB.sol";
import {IChargedParticles} from "./external/charged-particles/IChargedParticles.sol";
import {IChargedState} from "./external/charged-particles/IChargedState.sol";

import {IBasketBlueprintRegistry} from "./interfaces/IBasketBlueprintRegistry.sol";
import {IBasketManager} from "./interfaces/IBasketManager.sol";
import {IBasketBuilder} from "./interfaces/IBasketBuilder.sol";
import {MultiSwap} from "./MultiSwap.sol";

error BasketBuilder__BasketBlueprintNotDefined();
error BasketBuilder__Unauthorized();
error BasketBuilder__InvalidParams();

contract BasketBuilder is MultiSwap, Ownable, IBasketBuilder, ERC721Holder {
    using SafeERC20 for IERC20;

    // default hardcoded values for now for formula "modifiers"
    uint32 public constant dx = 7; // increases significance of difference user risk Rate to asset risk rate
    uint32 public constant wx = 1; // increases significance of basketAsset weight

    IBasketBlueprintRegistry public immutable basketBlueprintRegistry;
    IBasketManager public immutable basketManager;

    IProtonB public immutable protonB;
    IChargedParticles public immutable chargedParticles;

    constructor(
        IBasketBlueprintRegistry _basketBlueprintRegistry,
        IBasketManager _basketManager,
        IProtonB _protonB,
        IChargedParticles _chargedParticles,
        address _zeroXSwapTarget
    ) MultiSwap(_zeroXSwapTarget) Ownable() {
        basketBlueprintRegistry = _basketBlueprintRegistry;
        basketManager = _basketManager;
        protonB = _protonB;
        chargedParticles = _chargedParticles;
    }

    /***********************************|
    |            PUBLIC API             |
    |__________________________________*/

    function swapAndBuild(
        IERC20 inputToken,
        uint256 maxAmountInputToken,
        bytes[] calldata swapQuotes,
        bytes32 basketBlueprintName,
        address receiver,
        uint32 riskRate,
        string memory tokenMetaUri,
        uint256 unlockBlock
    ) external returns (uint256 tokenId) {
        IBasketBlueprintRegistry.BasketAsset[]
            memory basketAssets = _validBasketBlueprint(basketBlueprintName);

        uint256[] memory assetAmounts;
        uint256[] memory spentAmounts;
        (assetAmounts, spentAmounts) = _swapInputToBasketAssets(
            inputToken,
            maxAmountInputToken,
            swapQuotes,
            basketAssets
        );

        _validBuildValues(basketAssets, riskRate, spentAmounts);

        tokenId = _buildBasket(
            basketAssets,
            assetAmounts,
            receiver,
            tokenMetaUri,
            unlockBlock
        );

        // store particle token Id -> basketBlueprintName, user riskRate in BasketManager
        basketManager.createBasketMeta(tokenId, basketBlueprintName, riskRate);

        emit BasketCreated(basketBlueprintName, receiver, tokenId);
    }

    /// expects transferFrom from msg.sender for each asset is executable (this is swaps logic agnostic)
    /// use swapAndBuild instead if going from one input token to a basket directly
    /// @param assetAmounts amount for each basketBlueprint asset in the same order (!)
    ///                     as basketAssets (BasketBlueprintRegistry.basketBlueprintAssets())
    function build(
        bytes32 basketBlueprintName,
        address receiver,
        uint32 riskRate,
        uint256[] calldata assetAmounts,
        string memory tokenMetaUri,
        uint256 unlockBlock
    ) external returns (uint256 tokenId) {
        IBasketBlueprintRegistry.BasketAsset[]
            memory basketAssets = _validBasketBlueprint(basketBlueprintName);

        // Todo: has to be adjusted to decimals
        // Validation with assetAmounts instead of spend amounts not functional right now,
        // assetAmounts would have to be brought to same decimals
        // _validBuildValues(basketAssets, riskRate, assetAmounts);

        uint256 _assetsLength = basketAssets.length;
        // transferFrom each basketAsset in; according to assetAmounts (assumes ERC20 approve has been executed)
        for (uint256 i; i < _assetsLength; ) {
            basketAssets[i].asset.safeTransferFrom(
                msg.sender,
                address(this),
                assetAmounts[i]
            );

            // gas optimized for loop
            unchecked {
                ++i;
            }
        }

        tokenId = _buildBasket(
            basketAssets,
            assetAmounts,
            receiver,
            tokenMetaUri,
            unlockBlock
        );

        // store particle token Id -> basketBlueprintName, user riskRate in BasketManager
        basketManager.createBasketMeta(tokenId, basketBlueprintName, riskRate);
    }

    /// @notice Returns the amounts of input asset that should be spent for each basket asset given a certain risk rate
    /// @param basketBlueprintName   basketBlueprint name as in BasketBlueprintRegistry
    /// @param riskRate     user risk rate to build weighting amounts for
    /// @param inputAmount  total amount of an input token that will be spent to acquire a basket basket
    /// @return assets -> the assets addresses in the same order as the amounts
    /// @return amounts -> the amounts of input token to be spent for acquiring each basket asset
    function getSpendAmounts(
        bytes32 basketBlueprintName,
        uint32 riskRate,
        uint256 inputAmount
    ) public view returns (address[] memory assets, uint256[] memory amounts) {
        IBasketBlueprintRegistry.BasketAsset[]
            memory basketAssets = _validBasketBlueprint(basketBlueprintName);

        uint256 amountsSum;
        (amounts, assets, amountsSum) = _getBasketAssetsRatios(
            riskRate,
            basketAssets
        );

        amounts = _alignBasketAssetsRatiosToInput(
            amounts,
            inputAmount,
            amountsSum
        );

        return (assets, amounts);
    }

    /***********************************|
    |              INTERNAL             |
    |__________________________________*/

    function _swapInputToBasketAssets(
        IERC20 inputToken,
        uint256 maxAmountInputToken,
        bytes[] calldata swapQuotes,
        IBasketBlueprintRegistry.BasketAsset[] memory basketAssets
    )
        internal
        returns (uint256[] memory assetAmounts, uint256[] memory spentAmounts)
    {
        uint256 _assetsLength = basketAssets.length;
        IERC20[] memory toAssets = new IERC20[](_assetsLength);
        for (uint256 i; i < _assetsLength; ) {
            toAssets[i] = basketAssets[i].asset;

            // gas optimized for loop
            unchecked {
                ++i;
            }
        }

        (assetAmounts, spentAmounts) = multiSwap(
            inputToken,
            maxAmountInputToken,
            toAssets,
            swapQuotes,
            msg.sender
        );
    }

    function _getBasketAssetsRatios(
        uint32 riskRate,
        IBasketBlueprintRegistry.BasketAsset[] memory basketAssets
    )
        internal
        view
        returns (
            uint256[] memory amounts,
            address[] memory assets,
            uint256 amountsSum
        )
    {
        if (riskRate > basketBlueprintRegistry.riskRateMaxValue()) {
            revert BasketBuilder__InvalidParams();
        }

        uint256 _assetsLength = basketAssets.length;

        amounts = new uint256[](_assetsLength);
        assets = new address[](_assetsLength);

        // get basketBlueprint amounts generalized not specific to inputAmount yet
        for (uint256 i; i < _assetsLength; ) {
            assets[i] = address(basketAssets[i].asset);
            amounts[i] = _getBasketAssetRatio(riskRate, basketAssets[i]);
            amountsSum += amounts[i];

            // gas optimized for loop
            unchecked {
                ++i;
            }
        }
    }

    function _getBasketAssetRatio(
        uint32 riskRate,
        IBasketBlueprintRegistry.BasketAsset memory basketAsset
    ) internal view returns (uint256 ratio) {
        // FORMULA: y = riskRateMaxValue * dx - d * dx + w * wx
        // d must be > 0 and can be maximally `riskRateMaxValue`
        // w must be > 0
        // d = differenceAbs of riskRate to assetRiskRate. because of risk rates can be maximally riskRateMaxValue
        // the diff abs is also maximally riskRateMaxValue

        uint256 riskRateDifference = _absDifference(
            riskRate,
            basketAsset.riskRate
        ); // = d in formula

        ratio =
            (basketBlueprintRegistry.riskRateMaxValue() * dx) -
            (riskRateDifference * dx) +
            (basketAsset.weight * wx);
    }

    function _buildBasket(
        IBasketBlueprintRegistry.BasketAsset[] memory basketAssets,
        uint256[] memory assetAmounts,
        address receiver,
        string memory tokenMetaUri,
        uint256 unlockBlock
    ) internal returns (uint256 tokenId) {
        // 1. create charged particle NFT with first asset wrapped
        basketAssets[0].asset.safeApprove(address(protonB), assetAmounts[0]);

        tokenId = protonB.createChargedParticle(
            owner(), // creator
            address(this), // receiver -> this is initially this contract to have permissions for timelocking.
            // the NFT is transferred to the receiver at the end of this process.
            address(0), // referrer
            tokenMetaUri, // tokenMetaUri
            // walletManagerId -> either generic.B or aave.B (aave.B is yield bearing)
            _mapAssetTypeToWalletManagerId(basketAssets[0].assetType),
            address(basketAssets[0].asset), // assetToken
            assetAmounts[0], // assetAmount
            0 // annuityPercent
        );

        uint256 _assetsLength = basketAssets.length;

        // 2. ChargedParticles.energizeParticle forEach asset (except first, which is already in)
        for (uint256 i = 1; i < _assetsLength; ) {
            basketAssets[i].asset.safeApprove(
                address(chargedParticles),
                assetAmounts[i]
            );

            chargedParticles.energizeParticle(
                address(protonB), // contractAddress -> The address to the contract of the NFT token (Particle)
                tokenId, // tokenId
                _mapAssetTypeToWalletManagerId(basketAssets[i].assetType), // walletManagerId -> same as above
                address(basketAssets[i].asset), // assetToken
                assetAmounts[i], // assetAmount
                address(0) // referrer
            );

            // gas optimized for loop
            unchecked {
                ++i;
            }
        }

        /**
         * Timelocking would work like implemented below, but a crucial part is missing.
         * This part has to be implemented next:
         * With the current logic, after transferring the NFT to the "receiver",
         * the "receiver" can freely interact with Charged Particles
         * contracts. This can lead to invalid states in our BasketMetadata,
         * and means that the "receiver" can lift the timelock or execute any other action on it.
         *
         * We can solve this by implementing an intermediary contract, a wallet contract that will
         * be the owner of the NFT instead of the "receiver" directly. The "receiver" still has non-custodial
         * access to the NFT, BUT the actions executable on it are within whatever boundaries we see fit.
         * Also, this means that our BasketMetadata can be updated.
         * Every user would get a clone of BasketManager and have his own BasketManager.
         * This allows to implement the TrustAccount use-case,
         * or pocket money (limited discharge amount per blocks) for a child.
         * Each user gets a wallet, can be a EIP-1167 minimal proxy clone or BeaconProxy clone similar to
         * https://github.com/notional-finance/wrapped-fcash/tree/master/contracts/proxy
         *
         * The tokenMetaUri of the protonB NFT is not modifiable so the off-chain metadata would either have to be
         * permanent or it could use an IPFS naming service such as IPNS https://docs.ipfs.io/concepts/ipns/
         * Permanent would be preferrable.
         */

        IChargedState chargedState = IChargedState(
            chargedParticles.getStateAddress()
        );
        if (unlockBlock != 0) {
            chargedState.setReleaseTimelock( // principle amount
                address(protonB), // contractAddress
                tokenId, // tokenId
                unlockBlock
            );
            chargedState.setDischargeTimelock( // yield amount
                address(protonB), // contractAddress
                tokenId, // tokenId
                unlockBlock
            );
        }

        // transfer NFT to receiver
        protonB.approve(receiver, tokenId);
        protonB.safeTransferFrom(address(this), receiver, tokenId);
    }

    function _validBuildValues(
        IBasketBlueprintRegistry.BasketAsset[] memory basketAssets,
        uint32 riskRate,
        uint256[] memory assetAmounts
    ) internal view {
        uint256 _assetsLength = basketAssets.length;
        if (_assetsLength > 0 && assetAmounts.length != _assetsLength) {
            revert BasketBuilder__InvalidParams();
        }

        // can't get actual basketAssetAmounts (would need price related to inputToken -> asset)
        // instead expect amounts for each basketAsset in input params

        // get should be asset ratios / amounts
        uint256[] memory shouldBeAmounts;
        (shouldBeAmounts, , ) = _getBasketAssetsRatios(riskRate, basketAssets);
        // and ensure ratios of input param asset amounts are matching with the given user riskRate
        for (uint256 i; i < _assetsLength - 1; ) {
            // compare ratio of asset to next asset

            // assetAmounts have to be brought to same decimals
            uint256 isRatio = (assetAmounts[i] * 1e18) / assetAmounts[i + 1];
            uint256 shouldBeRatio = (shouldBeAmounts[i] * 1e18) /
                shouldBeAmounts[i + 1];

            // Todo: has to be adjusted to decimals
            if (_absDifference(isRatio, shouldBeRatio) > 1e15) {
                // allow for some tolerance in divergence to make up for decimals / potential minor changes in swap outcome
                revert BasketBuilder__InvalidParams();
            }

            // gas optimized for loop
            unchecked {
                ++i;
            }
        }
    }

    function _validBasketBlueprint(bytes32 basketBlueprintName)
        internal
        view
        returns (IBasketBlueprintRegistry.BasketAsset[] memory basketAssets)
    {
        if (
            !basketBlueprintRegistry.basketBlueprintDefined(basketBlueprintName)
        ) {
            revert BasketBuilder__BasketBlueprintNotDefined();
        }

        basketAssets = basketBlueprintRegistry.basketBlueprintAssets(
            basketBlueprintName
        );
    }

    function _alignBasketAssetsRatiosToInput(
        uint256[] memory amounts,
        uint256 inputAmount,
        uint256 amountsSum
    ) internal pure returns (uint256[] memory) {
        // align the sum of amounts to the actual requested total input Amount
        if (amountsSum > inputAmount) {
            // total sum is too big, we have to divide values down
            uint256 denominator = (amountsSum * 1e18) / inputAmount; // denominator will be in 1e18
            for (uint256 i; i < amounts.length; ) {
                amounts[i] = (amounts[i] * 1e18) / denominator; // result will be in decimals of amounts

                // gas optimized for loop
                unchecked {
                    ++i;
                }
            }
        } else if (amountsSum < inputAmount) {
            // total sum is too small, we have to multiply values up
            uint256 multiplicator = (inputAmount * 1e18) / amountsSum; // multiplicator will be in 1e18
            for (uint256 i; i < amounts.length; ) {
                amounts[i] = (amounts[i] * multiplicator) / 1e18; // result will be in decimals of amounts

                // gas optimized for loop
                unchecked {
                    ++i;
                }
            }
        }

        return amounts;
    }

    function _absDifference(uint256 num1, uint256 num2)
        internal
        pure
        returns (uint256)
    {
        // can't underflow because we explicitly check for it
        unchecked {
            if (num1 == num2) {
                return 0;
            } else if (num1 > num2) {
                return num1 - num2;
            } else {
                return num2 - num1;
            }
        }
    }

    function _mapAssetTypeToWalletManagerId(uint32 assetType)
        public
        pure
        returns (string memory)
    {
        if (assetType == 0) {
            return "generic.B";
        } else if (assetType == 1) {
            return "aave.B";
        } else {
            // not supported for now. If more walletManagerIds become available in the future this has to be adjusted
            revert BasketBuilder__InvalidParams();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IChargedParticles {
    /***********************************|
    |             Public API            |
    |__________________________________*/

    function getStateAddress() external view returns (address stateAddress);

    function getSettingsAddress()
        external
        view
        returns (address settingsAddress);

    function getManagersAddress()
        external
        view
        returns (address managersAddress);

    function getFeesForDeposit(uint256 assetAmount)
        external
        view
        returns (uint256 protocolFee);

    function baseParticleMass(
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken
    ) external returns (uint256);

    function currentParticleCharge(
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken
    ) external returns (uint256);

    function currentParticleKinetics(
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken
    ) external returns (uint256);

    function currentParticleCovalentBonds(
        address contractAddress,
        uint256 tokenId,
        string calldata basketManagerId
    ) external view returns (uint256);

    /***********************************|
  |        Particle Mechanics         |
  |__________________________________*/

    function energizeParticle(
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken,
        uint256 assetAmount,
        address referrer
    ) external returns (uint256 yieldTokensAmount);

    function dischargeParticle(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken
    ) external returns (uint256 creatorAmount, uint256 receiverAmount);

    function dischargeParticleAmount(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken,
        uint256 assetAmount
    ) external returns (uint256 creatorAmount, uint256 receiverAmount);

    function dischargeParticleForCreator(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken,
        uint256 assetAmount
    ) external returns (uint256 receiverAmount);

    function releaseParticle(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken
    ) external returns (uint256 creatorAmount, uint256 receiverAmount);

    function releaseParticleAmount(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken,
        uint256 assetAmount
    ) external returns (uint256 creatorAmount, uint256 receiverAmount);

    function covalentBond(
        address contractAddress,
        uint256 tokenId,
        string calldata basketManagerId,
        address nftTokenAddress,
        uint256 nftTokenId,
        uint256 nftTokenAmount
    ) external returns (bool success);

    function breakCovalentBond(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        string calldata basketManagerId,
        address nftTokenAddress,
        uint256 nftTokenId,
        uint256 nftTokenAmount
    ) external returns (bool success);

    /***********************************|
    |          Particle Events          |
    |__________________________________*/

    event Initialized(address indexed initiator);
    event ControllerSet(address indexed controllerAddress, string controllerId);
    event DepositFeeSet(uint256 depositFee);
    event ProtocolFeesCollected(
        address indexed assetToken,
        uint256 depositAmount,
        uint256 feesCollected
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IChargedState {
    /***********************************|
    |             Public API            |
    |__________________________________*/

    function getDischargeTimelockExpiry(
        address contractAddress,
        uint256 tokenId
    ) external view returns (uint256 lockExpiry);

    function getReleaseTimelockExpiry(address contractAddress, uint256 tokenId)
        external
        view
        returns (uint256 lockExpiry);

    function getBreakBondTimelockExpiry(
        address contractAddress,
        uint256 tokenId
    ) external view returns (uint256 lockExpiry);

    function isApprovedForDischarge(
        address contractAddress,
        uint256 tokenId,
        address operator
    ) external returns (bool);

    function isApprovedForRelease(
        address contractAddress,
        uint256 tokenId,
        address operator
    ) external returns (bool);

    function isApprovedForBreakBond(
        address contractAddress,
        uint256 tokenId,
        address operator
    ) external returns (bool);

    function isApprovedForTimelock(
        address contractAddress,
        uint256 tokenId,
        address operator
    ) external returns (bool);

    function isEnergizeRestricted(address contractAddress, uint256 tokenId)
        external
        view
        returns (bool);

    function isCovalentBondRestricted(address contractAddress, uint256 tokenId)
        external
        view
        returns (bool);

    function getDischargeState(
        address contractAddress,
        uint256 tokenId,
        address sender
    )
        external
        returns (
            bool allowFromAll,
            bool isApproved,
            uint256 timelock,
            uint256 tempLockExpiry
        );

    function getReleaseState(
        address contractAddress,
        uint256 tokenId,
        address sender
    )
        external
        returns (
            bool allowFromAll,
            bool isApproved,
            uint256 timelock,
            uint256 tempLockExpiry
        );

    function getBreakBondState(
        address contractAddress,
        uint256 tokenId,
        address sender
    )
        external
        returns (
            bool allowFromAll,
            bool isApproved,
            uint256 timelock,
            uint256 tempLockExpiry
        );

    /***********************************|
  |      Only NFT Owner/Operator      |
  |__________________________________*/

    function setDischargeApproval(
        address contractAddress,
        uint256 tokenId,
        address operator
    ) external;

    function setReleaseApproval(
        address contractAddress,
        uint256 tokenId,
        address operator
    ) external;

    function setBreakBondApproval(
        address contractAddress,
        uint256 tokenId,
        address operator
    ) external;

    function setTimelockApproval(
        address contractAddress,
        uint256 tokenId,
        address operator
    ) external;

    function setApprovalForAll(
        address contractAddress,
        uint256 tokenId,
        address operator
    ) external;

    function setPermsForRestrictCharge(
        address contractAddress,
        uint256 tokenId,
        bool state
    ) external;

    function setPermsForAllowDischarge(
        address contractAddress,
        uint256 tokenId,
        bool state
    ) external;

    function setPermsForAllowRelease(
        address contractAddress,
        uint256 tokenId,
        bool state
    ) external;

    function setPermsForRestrictBond(
        address contractAddress,
        uint256 tokenId,
        bool state
    ) external;

    function setPermsForAllowBreakBond(
        address contractAddress,
        uint256 tokenId,
        bool state
    ) external;

    function setDischargeTimelock(
        address contractAddress,
        uint256 tokenId,
        uint256 unlockBlock
    ) external;

    function setReleaseTimelock(
        address contractAddress,
        uint256 tokenId,
        uint256 unlockBlock
    ) external;

    function setBreakBondTimelock(
        address contractAddress,
        uint256 tokenId,
        uint256 unlockBlock
    ) external;

    /***********************************|
  |         Only NFT Contract         |
  |__________________________________*/

    function setTemporaryLock(
        address contractAddress,
        uint256 tokenId,
        bool isLocked
    ) external;

    /***********************************|
  |          Particle Events          |
  |__________________________________*/

    event Initialized(address indexed initiator);
    event ControllerSet(address indexed controllerAddress, string controllerId);

    event DischargeApproval(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed owner,
        address operator
    );
    event ReleaseApproval(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed owner,
        address operator
    );
    event BreakBondApproval(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed owner,
        address operator
    );
    event TimelockApproval(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed owner,
        address operator
    );

    event TokenDischargeTimelock(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed operator,
        uint256 unlockBlock
    );
    event TokenReleaseTimelock(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed operator,
        uint256 unlockBlock
    );
    event TokenBreakBondTimelock(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed operator,
        uint256 unlockBlock
    );
    event TokenTempLock(
        address indexed contractAddress,
        uint256 indexed tokenId,
        uint256 unlockBlock
    );

    event PermsSetForRestrictCharge(
        address indexed contractAddress,
        uint256 indexed tokenId,
        bool state
    );
    event PermsSetForAllowDischarge(
        address indexed contractAddress,
        uint256 indexed tokenId,
        bool state
    );
    event PermsSetForAllowRelease(
        address indexed contractAddress,
        uint256 indexed tokenId,
        bool state
    );
    event PermsSetForRestrictBond(
        address indexed contractAddress,
        uint256 indexed tokenId,
        bool state
    );
    event PermsSetForAllowBreakBond(
        address indexed contractAddress,
        uint256 indexed tokenId,
        bool state
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IProtonB is IERC721 {
    event UniverseSet(address indexed universe);
    event ChargedStateSet(address indexed chargedState);
    event ChargedSettingsSet(address indexed chargedSettings);
    event ChargedParticlesSet(address indexed chargedParticles);

    /***********************************|
    |             Public API            |
    |__________________________________*/

    function createProtonForSale(
        address creator,
        address receiver,
        string memory tokenMetaUri,
        uint256 annuityPercent,
        uint256 royaltiesPercent,
        uint256 salePrice
    ) external returns (uint256 newTokenId);

    function createChargedParticle(
        address creator,
        address receiver,
        address referrer,
        string memory tokenMetaUri,
        string memory walletManagerId,
        address assetToken,
        uint256 assetAmount,
        uint256 annuityPercent
    ) external returns (uint256 newTokenId);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBasketBlueprintRegistry {
    // tightly packed to 32 bytes
    struct BasketAsset {
        IERC20 asset; // 20 bytes
        // risk rate should be 1e6, i.e. a risk rate of 1% would be 1_000_000. 10% 10_000_000 etc.
        // must be >0 and <=100% (1 and 100_000_000)
        uint32 riskRate; // 4 bytes
        // weight should be 1e6, i.e. a weight of 1 would be 1_000_000. default weight is 10_000_000
        // must be >0
        uint32 weight; // 4 bytes
        // assetType is basically an Enum that is mapped to ChargedParticles walletManagerId
        // 0 = "generic.B" (for generic all ERC20 tokens)
        // 1 = "aave.B" (for yield bearing Aave tokens)
        uint32 assetType; // 4 bytes
    }

    // later maybe: basketBluePrintNames array[]
    // verified status of basketBluePrint

    event BasketBlueprintDefined(bytes32 basketBlueprintName, address owner);
    event BasketBlueprintOwnerChanged(
        bytes32 basketBlueprintName,
        address previousOwner,
        address newOwner
    );

    function riskRateMaxValue() external view returns (uint32);

    function defaultWeight() external view returns (uint32);

    function basketBlueprintDefined(bytes32 basketBlueprintName)
        external
        view
        returns (bool);

    function basketBlueprintOwner(bytes32 basketBlueprintName)
        external
        view
        returns (address);

    function basketBlueprintAssets(bytes32 basketBlueprintName)
        external
        view
        returns (BasketAsset[] memory);

    function defineBasketBlueprint(
        bytes32 basketBlueprintName,
        BasketAsset[] calldata assets,
        address owner
    ) external;

    function transferBasketBlueprintOwnership(
        bytes32 basketBlueprintName,
        address newOwner
    ) external;

    function basketBlueprintRiskRate(bytes32 basketBlueprintName)
        external
        view
        returns (uint256 riskRate);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBasketBuilder {
    event BasketCreated(
        bytes32 basketBlueprintName,
        address owner,
        uint256 tokenId
    );

    function swapAndBuild(
        IERC20 inputToken,
        uint256 maxAmountInputToken,
        bytes[] calldata swapQuotes,
        bytes32 basketBlueprintName,
        address receiver,
        uint32 riskRate,
        string memory tokenMetaUri,
        uint256 unlockBlock
    ) external returns (uint256 tokenId);

    function build(
        bytes32 basketBlueprintName,
        address receiver,
        uint32 riskRate,
        uint256[] calldata assetAmounts,
        string memory tokenMetaUri,
        uint256 unlockBlock
    ) external returns (uint256 tokenId);

    /// @notice Returns the amounts of input asset that should be spent for each basket asset given a certain risk rate
    /// @param basketBlueprintName   basketBlueprint name as in BasketBlueprintRegistry
    /// @param riskRate     user risk rate to build weighting amounts for. value between 1000 and 10.000?
    /// @param inputAmount  total amount of an input token that will be spent to acquire a basket basket
    /// @return assets -> the assets addresses in the same order as the amounts
    /// @return amounts -> the amounts of input token to be spent for acquiring each basket asset
    function getSpendAmounts(
        bytes32 basketBlueprintName,
        uint32 riskRate,
        uint256 inputAmount
    ) external returns (address[] memory assets, uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IBasketManager {
    struct BasketMeta {
        bytes32 blueprintName;
        uint32 riskRate; // user risk rate
    }

    function createBasketMeta(
        uint256 tokenId,
        bytes32 basketBlueprintName,
        uint32 riskRate
    ) external;

    function setBasketBuilder(address basketBuilder, bool allowed) external;

    function getBasketAssetAmounts(uint256 tokenId)
        external
        returns (address[] memory assets, uint256[] memory amounts);
}

// SPDX-License-Identifier: No License
pragma solidity >=0.8.17;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error MultiSwap__InvalidParams();

contract MultiSwap {
    using SafeERC20 for IERC20;

    address public immutable zeroXSwapTarget;

    constructor(address _zeroXSwapTarget) {
        zeroXSwapTarget = _zeroXSwapTarget;
    }

    /// @param swapQuotes    The encoded 0x transactions to execute.
    ///                      Should include sellAmount (BasketBuilder.getSpendAmounts()), sellToken, buyToken etc.
    function multiSwap(
        IERC20 inputToken,
        uint256 maxAmountInputToken,
        IERC20[] memory toAssets,
        bytes[] calldata swapQuotes,
        address from
    )
        public
        returns (
            uint256[] memory obtainedAmounts,
            uint256[] memory spentAmounts
        )
    {
        // for now per default via 0x, later there could be
        // adapters, e.g. 0xAdapter etc. which can be defined per token?

        uint256 _swapQuotesLength = swapQuotes.length;

        obtainedAmounts = new uint256[](_swapQuotesLength);
        spentAmounts = new uint256[](_swapQuotesLength);

        inputToken.safeTransferFrom(from, address(this), maxAmountInputToken);
        _safeApprove(inputToken, zeroXSwapTarget, maxAmountInputToken);

        uint256 fillObtainedAmountsIndex;
        for (uint256 i; i < _swapQuotesLength; ) {
            // if inputToken == outputToken then there is no need for a swap
            if (address(inputToken) == address(toAssets[i])) {
                obtainedAmounts[i] = 0; // will be set later from leftover
                if (fillObtainedAmountsIndex != 0) {
                    // inputToken == outputToken is only supported if it is not included multiple times
                    // in toAssets[], which wouldn't make sense anyway
                    revert MultiSwap__InvalidParams();
                }
                fillObtainedAmountsIndex = i;
            } else {
                uint256 outputTokenBalanceBefore = toAssets[i].balanceOf(
                    address(this)
                );
                uint256 inputTokenBalanceBefore = inputToken.balanceOf(
                    address(this)
                );

                _fillQuote(swapQuotes[i]);

                uint256 outputTokenBalanceAfter = toAssets[i].balanceOf(
                    address(this)
                );
                uint256 inputTokenBalanceAfter = inputToken.balanceOf(
                    address(this)
                );

                obtainedAmounts[i] = (outputTokenBalanceAfter -
                    outputTokenBalanceBefore);
                spentAmounts[i] = (inputTokenBalanceBefore -
                    inputTokenBalanceAfter);
            }

            // gas optimized for loop
            unchecked {
                ++i;
            }
        }

        if (fillObtainedAmountsIndex != 0) {
            // inputToken == outputToken was true once, set the left over balance to obtained amounts at that index
            uint256 inputTokenBalance = inputToken.balanceOf(address(this));
            obtainedAmounts[fillObtainedAmountsIndex] = inputTokenBalance;
            spentAmounts[fillObtainedAmountsIndex] = inputTokenBalance;
        }
    }

    /// @notice Execute a 0x Swap quote
    /// @param _quote          Swap quote as returned by 0x API
    function _fillQuote(bytes memory _quote) internal {
        (bool success, bytes memory returndata) = zeroXSwapTarget.call(_quote);

        if (!success) {
            // get revert reason if available, based on https://ethereum.stackexchange.com/a/83577
            // as used by uniswap (https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol)
            if (returndata.length > 68) {
                assembly {
                    returndata := add(returndata, 0x04)
                }
                string memory revertReason = abi.decode(returndata, (string));
                revert(revertReason);
            } else {
                revert("UNKNOWN_REASON");
            }
        }
    }

    /// @notice Sets a max approval limit for an ERC20 token, provided the current allowance
    /// is less than the required allownce.
    /// @param _token    Token to approve
    /// @param _spender  Spender address to approve
    function _safeApprove(
        IERC20 _token,
        address _spender,
        uint256 _requiredAllowance
    ) internal {
        uint256 allowance = _token.allowance(address(this), _spender);
        if (allowance < _requiredAllowance) {
            _token.safeIncreaseAllowance(
                _spender,
                type(uint256).max - allowance
            );
        }
    }
}