/**
 *Submitted for verification at polygonscan.com on 2023-06-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

//import "forge-std/console.sol";

contract NFTAuction is Ownable, ReentrancyGuard, IERC721Receiver {
    // Testnet REKT dogs contract address
    address constant REKT_DOGS_CONTRACT_ADDRESS = address(0x2bB109E6AC64e926965A06Df08808C85f6eabb61);
    address constant REKT_STAKING_CONTRACT_ADDRESS = address(0xe5a77D9508b4BC25F3C346f8f005F2cF6Bf282b4);
    address constant REKT_CONTRACT_ADDRESS = address(0x0E5E0AC61eB468375EF333778dAB7436B9226beA);
    address constant ETH_CONTRACT_ADDRESS = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);

    using SafeERC20 for IERC20;

    struct AuctionInfo {
        /// IERC-20 interface for this auction, only this token can be used to buy tickets, pay for base fee & sales fee.
        IERC20 token;
        /// ERC-721 contract for NFTs.
        address nftContract;
        /// The token Id for the NFT which is the reward of the auction.
        uint256 nftTokenId;
        /// The lowest price to bid at the first time.
        uint256 reservePrice;
        /// The minimum increment of each bid, in percentage.
        uint256 minIncrement;
        /// The auction start time in timestamp
        uint256 startTime;
        /// The auction end time in timestamp.
        uint256 endTime;
        /// The time span before the end time, when in this time span, every bid will
        /// reset the end time to `last bid time + addTime`
        uint256 addTime;
        /// The admin of the auction.
        address auctionAdmin;
        /// In 'holder only mode', the user which has the NFT in this list can bid.
        address[] holderOnlyContractList;
        /// Has the auction been cancelled?
        bool isAuctionCancelled;
        /// Has the auction NFT been withdraw yet?
        bool isNFTWithdrew;
        /// Has the revenue been claimed yet?
        bool isRevenueClaimed;
    }

    /// Auction infos.
    AuctionInfo[] public auctions;

    /// Mapping of auction id => bidder => bid price.
    mapping(uint256 => mapping(address => uint256)) public bids;

    /// Highest bidder of auctions.
    mapping(uint256 => address) public highestBidders;

    /// Highest bid price of auctions.
    mapping(uint256 => uint256) public highestBidPrices;

    /// Sales fee percentage, charge for the auction admin after the end of auction.
    uint256 public SALES_FEE_PCT;

    /// Max buy per address percentage.
    uint256 public immutable PERCENTAGE_DENOMINATOR = 100;

    /// Only NFTs in the whitelist are allowed to start a auction.
    mapping(address => bool) public NFTWhiteList;

    event AuctionStarted(
        uint256 indexed auctionId,
        uint256 tokenId,
        uint256 reservePrice,
        uint256 startTime,
        uint256 endTime,
        uint256 addTime
    );
    event Bid(uint256 indexed auctionId, address indexed bidder, uint256 price);
    event AuctionCancelled(uint256 indexed auctionId, address indexed admin);
    event WithdrawBid(uint256 indexed auctionId, address indexed bidder, uint256 bidPrice);
    event NFTWithrew(uint256 indexed auctionId, address indexed admin);
    event NFTClaimed(uint256 indexed auctionId, address indexed winner);
    event RevenueClaimed(uint256 indexed auctionId, address indexed admin, uint256 amount);

    modifier hasAuction(uint256 auctionId) {
        require(auctionId < auctions.length, "auction does not exist");
        _;
    }

    modifier auctionHasEnded(uint256 auctionId) {
        AuctionInfo storage auction = auctions[auctionId];
        require(block.timestamp >= auction.endTime, "auction has not ended yet");
        _;
    }

    constructor(uint256 _salesFeePercentage) {
        require(0 < _salesFeePercentage && _salesFeePercentage <= 100, "Sales fee percentage out of bound");

        //SALES_FEE_PCT = _salesFeePercentage;
    }

    function getAuctionsCount() public view returns (uint256) {
        return auctions.length;
    }

    function getAuction(uint256 auctionId) public view returns (AuctionInfo memory) {
        return auctions[auctionId];
    }

    function getAuctions(uint256[] calldata auctionIds) external view returns (AuctionInfo[] memory) {
        AuctionInfo[] memory _auctions = new AuctionInfo[](auctionIds.length);
        for (uint256 i = 0; i < auctionIds.length; i++) {
            _auctions[i] = auctions[auctionIds[i]];
        }
        return _auctions;
    }

    function getWinner(uint256 _auctionId)
        external
        view
        hasAuction(_auctionId)
        auctionHasEnded(_auctionId)
        returns (address)
    {
        address _highestBidder = highestBidders[_auctionId];
        require(_highestBidder != address(0), "No winner yet");

        return _highestBidder;
    }

    function modifyNFTWhitelist(address[] calldata addrs, bool isAdd) external onlyOwner {
        uint256 len = addrs.length;
        if (isAdd) {
            for (uint256 i = 0; i < len; i++) {
                NFTWhiteList[addrs[i]] = true;
            }
        } else {
            for (uint256 i = 0; i < len; i++) {
                NFTWhiteList[addrs[i]] = false;
            }
        }
    }

    function modifySellFeePercentage(uint256 _sellFeePercentage) external onlyOwner {
        require(0 < _sellFeePercentage && _sellFeePercentage <= 100, "Sell fee percentage out of bound");
        SALES_FEE_PCT = _sellFeePercentage;
    }

    /// Creates a new auction, `_nftContract` approve should be called before calling this.
    function startAuction(
        address _token,
        address _nftContract,
        uint256 _nftId,
        uint256 _reservePrice,
        uint256 _startTime,
        uint256 _duration,
        uint256 _addTime,
        uint256 _minIncrement,
        address[] calldata _holderOnlyContractList
    ) external {
        // Zero address for MATIC
        //require(
        //    _token == REKT_CONTRACT_ADDRESS || _token == ETH_CONTRACT_ADDRESS || _token == address(0),
        //    "Only support REKT, ETH or MATIC."
        //);
        require(NFTWhiteList[_nftContract], "Only NFTs in the whitelist are allowed to start a auction");

        for (uint256 i = 0; i < _holderOnlyContractList.length; i++) {
            require(NFTWhiteList[_holderOnlyContractList[i]], "holder only contract is not in NFT whitelist.");
        }

        uint256 endTime;
        if (_startTime <= block.timestamp) {
            _startTime = block.timestamp;
            endTime = block.timestamp + _duration;
        } else {
            endTime = _startTime + _duration;
        }

        AuctionInfo memory _auction = AuctionInfo(
            IERC20(_token),
            _nftContract,
            _nftId,
            _reservePrice,
            _minIncrement,
            _startTime,
            endTime,
            _addTime,
            msg.sender,
            _holderOnlyContractList,
            false,
            false,
            false
        );
        auctions.push(_auction);

        IERC721(_nftContract).safeTransferFrom(msg.sender, address(this), _nftId);

        emit AuctionStarted(auctions.length, _nftId, _reservePrice, _startTime, endTime, _addTime);
    }

    /// Create auction only when ERC721 token is received.
    function onERC721Received(address, address, uint256, bytes calldata) public pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    /// Bid on the auction.
    function bid(uint256 _auctionId, uint256 _bidPrice) external payable hasAuction(_auctionId) {
        AuctionInfo storage auction = auctions[_auctionId];
        require(!auction.isAuctionCancelled, "Auction is already cancelled");
        require(msg.sender != auction.auctionAdmin, "Cannot bid on what you own");
        require(block.timestamp >= auction.startTime, "Auction has not started.");
        require(block.timestamp <= auction.endTime, "Auction has ended.");

        {
            uint256 increment;
            uint256 _highestBidPrice = highestBidPrices[_auctionId];
            if (_highestBidPrice == 0) {
                increment = auction.reservePrice * auction.minIncrement / PERCENTAGE_DENOMINATOR;
            } else {
                increment = _highestBidPrice * auction.minIncrement / PERCENTAGE_DENOMINATOR;
            }
            require(_bidPrice >= _highestBidPrice + increment, "Bid price is lower than minimum requirement.");
        }

        if (auction.holderOnlyContractList.length > 0) {
            bool isHolder;
            for (uint256 i = 0; i < auction.holderOnlyContractList.length; i++) {
                if (IERC721(auction.holderOnlyContractList[i]).balanceOf(msg.sender) > 0) {
                    isHolder = true;
                    break;
                }
            }
            require(isHolder, "This auction is in `Holder Only Mode`, only holders can bid.");
        }

        uint256 lastBidPrice = bids[_auctionId][msg.sender];
        if (auction.token == IERC20(address(0))) {
            require(msg.value == _bidPrice - lastBidPrice, "Send wrong amount of bid price.");
        } else {
            auction.token.transferFrom(msg.sender, address(this), _bidPrice - lastBidPrice);
        }

        highestBidders[_auctionId] = msg.sender;
        highestBidPrices[_auctionId] = _bidPrice;
        bids[_auctionId][msg.sender] = _bidPrice;

        emit Bid(_auctionId, msg.sender, _bidPrice);
    }

    /// Admin can cancel the auction before anyone bid.
    function adminCancelAuction(uint256 _auctionId) external hasAuction(_auctionId) {
        AuctionInfo storage auction = auctions[_auctionId];

        require(msg.sender == auction.auctionAdmin, "Not auction admin.");
        require(highestBidPrices[_auctionId] == 0, "Cannot cancel the auction, someone has already bid.");

        auction.isAuctionCancelled = true;
        auction.isNFTWithdrew = true;
        IERC721(auction.nftContract).transferFrom(address(this), msg.sender, auction.nftTokenId);

        emit AuctionCancelled(_auctionId, auction.auctionAdmin);
        emit NFTWithrew(_auctionId, auction.auctionAdmin);
    }

    function withdrawBid(uint256 _auctionId) public payable nonReentrant {
        AuctionInfo storage auction = auctions[_auctionId];

        require(block.timestamp >= auction.endTime, "Auction has not ended yet.");
        require(msg.sender != highestBidders[_auctionId], "Highest bidder cannot withdraw bid.");

        uint256 bidPrice = bids[_auctionId][msg.sender];
        require(bidPrice > 0, "No bid to withdraw.");

        bids[_auctionId][msg.sender] = 0;
        if (auction.token == IERC20(address(0))) {
            _transferMatic(payable(msg.sender), bidPrice);
        } else {
            auction.token.transfer(owner(), bidPrice);
        }

        emit WithdrawBid(_auctionId, msg.sender, bidPrice);
    }

    /// Winner can claim his reward NFT.
    function winnerClaimNFT(uint256 _auctionId) external hasAuction(_auctionId) nonReentrant {
        AuctionInfo storage auction = auctions[_auctionId];

        require(block.timestamp >= auction.endTime, "Auction has not ended yet.");
        require(!auction.isNFTWithdrew, "NFT has been withdrawn.");
        require(msg.sender == highestBidders[_auctionId], "Not auction winner.");

        auction.isNFTWithdrew = true;
        IERC721(auction.nftContract).transferFrom(address(this), msg.sender, auction.nftTokenId);

        emit NFTClaimed(_auctionId, msg.sender);
    }

    /// auction admin claim the highest bid price.
    /// And charged for a sales fee of SALES_FEE_PCT.
    /// Rekt Dogs NFT holder can save half of sales fee.
    function adminClaimRevenue(uint256 _auctionId) external payable hasAuction(_auctionId) nonReentrant {
        AuctionInfo storage auction = auctions[_auctionId];

        require(!auction.isRevenueClaimed, "Revenue has been claimed.");
        require(block.timestamp >= auction.endTime, "Auction has not ended yet.");
        require(msg.sender == auction.auctionAdmin, "Not auction admin.");

        uint256 _highestBidPrice = highestBidPrices[_auctionId];
        uint256 salesFeeAmount = _highestBidPrice * SALES_FEE_PCT / PERCENTAGE_DENOMINATOR;
        if (_userHasSalesFeeDiscount(auction)) {
            salesFeeAmount = salesFeeAmount / 2;
        }
        uint256 adminRevenueAfterFee = _highestBidPrice - salesFeeAmount;

        auction.isRevenueClaimed = true;
        if (auction.token == IERC20(address(0))) {
            _transferMatic(payable(owner()), salesFeeAmount);
            _transferMatic(payable(auction.auctionAdmin), adminRevenueAfterFee);
        } else {
            auction.token.transfer(owner(), salesFeeAmount);
            auction.token.transfer(auction.auctionAdmin, adminRevenueAfterFee);
        }

        emit RevenueClaimed(_auctionId, auction.auctionAdmin, adminRevenueAfterFee);
    }

    function _userHasSalesFeeDiscount(AuctionInfo storage auction) internal returns (bool) {
        // If admin has REKT dogs in their wallet or use it for auction, or staking them in the staking contract, the sales fee will have a 50% discount.
        bool hasStaking;
        (bool success, bytes memory result) =
            REKT_STAKING_CONTRACT_ADDRESS.call(abi.encodeWithSignature("balanceOf(address)", msg.sender));
        if (success && uint256(bytes32(result)) > 0) {
            hasStaking = true;
        }
        if (
            IERC721(REKT_DOGS_CONTRACT_ADDRESS).balanceOf(auction.auctionAdmin) > 0
                || auction.nftContract == REKT_DOGS_CONTRACT_ADDRESS || hasStaking
        ) {
            return true;
        }

        return false;
    }

    function _transferMatic(address payable _to, uint256 amount) internal {
        if (amount == 0) {
            return;
        }
        require(_to != address(0), "Cannot transfer to zero address.");

        (bool sent,) = _to.call{value: amount}("");
        require(sent, "Error, failed to send MATIC");
    }
}