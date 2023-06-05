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
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakeWithOption is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum UserAction{Stake, Swap, Withdraw, CreatePool}
    enum PoolStatus{Active, Stopped, Finished}

    error You_should_deposit_at_least_20_percent_of_USDT();
    error The_pool_is_not_fully_funded__Please_withdraw_your_token_with_compensation();
    error The_pool_is_fully_funded__Please_swap_your_token();

    error Pool_status_error();
    error Pool_is_not_unlocked_yet__Please_wait_until_unlock_time();
    error Pool_is_not_ended_yet__Please_wait_72_hours_after_unlock_time();
    error Pool_is_full__Please_wait_for_the_next_activity();

    error It_is_too_late_to_fully_fund_USDT__And_will_compensate_users();
    error Swap_Time_Expired__Please_Withdraw_Your_Token();

    error You_are_not_the_pool_owner__Please_check_your_wallet();
    error You_are_not_in_the_staking_period__Please_wait_for_the_next_activity();

    error Max_stake_per_address_can_not_be_greater_than_max_stake_of_the_pool();
    error You_can_not_stake_more_than_max_stake_per_address();

    error You_do_not_have_a_token_to_swap();
    error You_do_not_have_a_token_to_withdraw();
    error You_can_not_stake_in_your_own_pool();
    error You_should_create_a_pool_with_at_least_25_USDT();

    error Invalid_time_inputs();
    error Insufficient_balance__Please_check_your_balance();

    error Ensure_the_balance_of_the_contract_failed();

    struct PoolExt {
        string title;
        string banner;
        string icon;
        string[] links;
    }

    struct PoolCap {
        uint256 tokenStaked;
        uint256 usdtStaked;
    }

    struct PoolChange {
        uint256 tokenSwapped;
        uint256 usdtSpent;
        uint256 nftSwapped;
        uint256 tokenWithdrawn;
    }

    struct PoolConfig {
        IERC20 stakeToken;
        uint256 exchangeRate;
        IERC721 nft;
        uint256 maxStake;
        uint256 startTime;
        uint256 expireTime;
        uint256 unlockTime;
        uint256 maxStakePerAddress;
    }

    struct Pool {
        uint256 id;
        PoolCap cap;
        PoolConfig config;
        PoolChange change;
        PoolStatus status;
        PoolExt ext;
    }

    struct UserHistory {
        uint256 poolId;
        uint256 tokenAmount;
        uint256 createdAt;
        UserAction action;
    }

    struct Deposit {
        uint256 tokenAmount;
        uint256 nftId;
        bool swapped;
    }

    IERC20 public usdt = IERC20(0x382bB369d343125BfB2117af9c149795C6C65C50); // USDT in OKC
    uint256 public constant usdFee = 1000000; // 1 USDT
    uint256 public nextPoolId = 0;
    mapping(uint256 => Pool) public pools;
    mapping(uint256 => mapping(address => Deposit)) public poolDeposits;
    mapping(uint256 => address) public poolOwners;
    mapping(address => UserHistory[]) public userHistories;
    mapping(address => uint256) public selfTokenBalance;

    // governance part
    bool public safeMode = true;
    uint256 public minPoolUSDTCap = 25000000;

    event PoolCreated(uint256 id, address creator);
    event StakeMade(uint256 poolId, address staker, uint256 amount);
    event PoolClosed(uint256 poolId, address owner);

    modifier onlyPoolOwner(uint256 poolId) {
        if (poolOwners[poolId] != msg.sender) {
            revert You_are_not_the_pool_owner__Please_check_your_wallet();
        }
        _;
    }

    constructor(address _usdt) Ownable() {
        usdt = IERC20(_usdt);
    }

    function getCompensate(uint256 poolId) view public returns (uint256) {
        (Pool storage pool, Deposit storage deposit) = _poolAndMyDeposit(poolId);

        return deposit.tokenAmount * pool.cap.usdtStaked / pool.cap.tokenStaked / 2;
    }

    function allPools() public view returns (Pool[] memory) {
        Pool[] memory _pools = new Pool[](nextPoolId);
        for (uint256 i = 0; i < nextPoolId; i++) {
            _pools[i] = pools[i];
        }
        return _pools;
    }

    function allUserHistories(address user) public view returns (UserHistory[] memory) {
        return userHistories[user];
    }

    function createPool(
        IERC20 stakeToken,
        uint256 exchangeRate,
        IERC721 nft,
        uint256 maxStake,
        uint256 startTime,
        uint256 expireTime,
        uint256 unlockTime,
        uint256 maxStakePerAddress,
        uint256 usdtAmount,
        PoolExt memory ext
    ) nonReentrant public {
        if (startTime >= expireTime || expireTime >= unlockTime) {
            revert Invalid_time_inputs();
        }

        if (maxStakePerAddress > maxStake) {
            revert Max_stake_per_address_can_not_be_greater_than_max_stake_of_the_pool();
        }

        if (maxStake / exchangeRate < 25) {
           revert You_should_create_a_pool_with_at_least_25_USDT();
        }

        if (usdtAmount < maxStake * 1e6 / exchangeRate / 5) {
            revert You_should_deposit_at_least_20_percent_of_USDT();
        }

        _transferToSelf(usdt, usdtAmount);

        Pool storage pool = pools[nextPoolId];
        pool.id = nextPoolId;
        pool.config.stakeToken = stakeToken;
        pool.config.exchangeRate = exchangeRate;
        pool.config.nft = nft;
        pool.config.maxStake = maxStake;
        pool.config.startTime = startTime;
        pool.config.expireTime = expireTime;
        pool.config.unlockTime = unlockTime;
        pool.config.maxStakePerAddress = maxStakePerAddress;
        pool.cap.usdtStaked = usdtAmount;
        pool.ext = ext;

        poolOwners[nextPoolId] = msg.sender;

        userHistories[msg.sender].push(UserHistory({
            poolId: nextPoolId,
            tokenAmount: 0,
            createdAt: block.timestamp,
            action: UserAction.CreatePool
        }));

        emit PoolCreated(nextPoolId, msg.sender);
        nextPoolId++;
    }

    function setSafeMode(bool _safeMode) public onlyOwner {
        safeMode = _safeMode;
    }

    function _checkStake(uint256 poolId, uint256 amount) view private {
        Pool storage pool = pools[poolId];
        _ensurePoolStatus(poolId, PoolStatus.Active);

        if (block.timestamp < pool.config.startTime || block.timestamp > pool.config.expireTime) {
            revert You_are_not_in_the_staking_period__Please_wait_for_the_next_activity();
        }

        if (pool.cap.tokenStaked + amount > pool.config.maxStake) {
            revert Pool_is_full__Please_wait_for_the_next_activity();
        }

        if (pool.config.stakeToken.balanceOf(msg.sender) < amount) {
            revert Insufficient_balance__Please_check_your_balance();
        }

        if (poolDeposits[poolId][msg.sender].tokenAmount + amount > pool.config.maxStakePerAddress) {
            revert You_can_not_stake_more_than_max_stake_per_address();
        }

        if (msg.sender == poolOwners[poolId]) {
            revert You_can_not_stake_in_your_own_pool();
        }
    }

    function _isUSDTFullyDeposited(uint256 poolId) view private returns (bool) {
        Pool storage pool = pools[poolId];
        return (1e6 * pool.cap.tokenStaked / pool.config.exchangeRate <= pool.cap.usdtStaked);
    }

    function _calcFee(uint256 usdAmount) pure private returns (uint256) {
        if (usdAmount < 1e7) {
            return 0;
        }

        return usdFee;
    }

    function _transferToSelf(IERC20 token, uint256 amount) private {
        token.safeTransferFrom(msg.sender, address(this), amount);
    }

    function _transferToOther(IERC20 token, address user, uint256 amount) private {
        token.safeTransfer(user, amount);
    }

    function _poolAndMyDeposit(uint256 poolId) view private returns (Pool storage, Deposit storage) {
        Pool storage pool = pools[poolId];
        mapping(address => Deposit) storage _poolDeposit = poolDeposits[poolId];
        Deposit storage deposit = _poolDeposit[msg.sender];
        return (pool, deposit);
    }

    function _ensurePoolStatus(uint256 poolId, PoolStatus status) private view {
        if (pools[poolId].status != status) {
            revert Pool_status_error();
        }
    }

    function _ensurePoolUnlock(uint256 poolId) private view {
        if (block.timestamp < pools[poolId].config.unlockTime) {
            revert Pool_is_not_unlocked_yet__Please_wait_until_unlock_time();
        }
    }

    function _ensurePoolEnded(uint256 poolId) private view {
        if (block.timestamp < pools[poolId].config.unlockTime + 72 hours) {
            revert Pool_is_not_ended_yet__Please_wait_72_hours_after_unlock_time();
        }
    }

    function _ensureSelfUSDTBalance() private view {
        if (!safeMode) {
            return;
        }

        // calc all usdt in the contract
        uint256 totalUSDT = 0;
        for (uint256 i = 0; i < nextPoolId; i++) {
            Pool storage pool = pools[i];
            if (pool.status == PoolStatus.Finished) {
                continue;
            }
            totalUSDT += pool.cap.usdtStaked - pool.change.usdtSpent;
        }

        if (usdt.balanceOf(address(this)) < totalUSDT) {
            revert Ensure_the_balance_of_the_contract_failed();
        }
    }

    function _ensureSelfTokenBalance(uint256 poolId) private view {
        if (!safeMode) {
            return;
        }

        Pool storage pool = pools[poolId];
        IERC20 token = pool.config.stakeToken;

        uint256 totalToken = 0;
        for (uint256 i = 0; i < nextPoolId; i++) {
            Pool storage _pool = pools[i];
            if (_pool.config.stakeToken != token) {
                continue;
            }

            if (_pool.status == PoolStatus.Finished) {
                totalToken += _pool.cap.tokenStaked - _pool.change.tokenWithdrawn -_pool.change.tokenSwapped;
            } else {
                totalToken += _pool.cap.tokenStaked - _pool.change.tokenWithdrawn;
            }
        }

        if (token.balanceOf(address(this)) < totalToken) {
            revert Ensure_the_balance_of_the_contract_failed();
        }
    }

    function stakeUSDT(uint256 poolId, uint256 amount) onlyPoolOwner(poolId) nonReentrant public {
        Pool storage pool = pools[poolId];
        if (block.timestamp >= pool.config.unlockTime) {
            revert It_is_too_late_to_fully_fund_USDT__And_will_compensate_users();
        }

        _transferToSelf(usdt, amount);
        pool.cap.usdtStaked += amount;

        _ensureSelfUSDTBalance();
    }

    function stake(uint256 poolId, uint256 amount) public nonReentrant {
        _checkStake(poolId, amount);

        Pool storage pool = pools[poolId];
        mapping(address => Deposit) storage _poolDeposit = poolDeposits[poolId];

        _transferToSelf(pool.config.stakeToken, amount);

        pool.cap.tokenStaked += amount;

        Deposit storage deposit = _poolDeposit[msg.sender];

        if (deposit.tokenAmount == 0) {
            _poolDeposit[msg.sender] = Deposit({
                tokenAmount: amount,
                nftId: 0,
                swapped: false
            });
        } else {
            deposit.tokenAmount += amount;
        }

        userHistories[msg.sender].push(UserHistory({
            poolId: poolId,
            tokenAmount: amount,
            createdAt: block.timestamp,
            action: UserAction.Stake
        }));

        _ensureSelfTokenBalance(poolId);
        _ensureSelfUSDTBalance();
        emit StakeMade(poolId, msg.sender, amount);
    }

    /**
    */
    function swap(uint256 poolId, uint256 nftId) public nonReentrant {
        if (!_isUSDTFullyDeposited(poolId)) {
            revert The_pool_is_not_fully_funded__Please_withdraw_your_token_with_compensation();
        }

        _ensurePoolUnlock(poolId);
        _ensurePoolStatus(poolId, PoolStatus.Active);

        (Pool storage pool, Deposit storage deposit) = _poolAndMyDeposit(poolId);

        if (block.timestamp > pool.config.unlockTime + 72 hours) {
            revert Swap_Time_Expired__Please_Withdraw_Your_Token();
        }

        if (deposit.tokenAmount == 0 || deposit.swapped || deposit.nftId != 0) {
            revert You_do_not_have_a_token_to_swap();
        }

        // destroy nft
        pool.config.nft.safeTransferFrom(msg.sender, address(1), nftId);

        // swap token to usd
        uint256 usdtSwapped = 1e6 * deposit.tokenAmount / pool.config.exchangeRate;

        uint256 fee = _calcFee(usdtSwapped);

        _transferToOther(usdt, owner(), fee);
        _transferToOther(usdt, msg.sender, usdtSwapped - fee);

        // update pool
        pool.change.tokenSwapped += deposit.tokenAmount;
        pool.change.usdtSpent += usdtSwapped;
        pool.change.nftSwapped += 1;

        deposit.tokenAmount = 0;
        deposit.nftId = nftId;
        deposit.swapped = true;

        userHistories[msg.sender].push(UserHistory({
            poolId: poolId,
            tokenAmount: deposit.tokenAmount,
            createdAt: block.timestamp,
            action: UserAction.Swap
        }));

        _ensureSelfUSDTBalance();
        _ensureSelfTokenBalance(poolId);
    }

    function _withdrawToken(uint256 poolId, uint256 fee) private {
        (Pool storage pool, Deposit storage deposit) = _poolAndMyDeposit(poolId);

        if (deposit.tokenAmount == 0) {
            revert You_do_not_have_a_token_to_withdraw();
        }
        uint256 amount = deposit.tokenAmount;
        deposit.tokenAmount = 0;

        _transferToOther(pool.config.stakeToken, msg.sender, amount - fee);
        _transferToOther(pool.config.stakeToken, owner(), fee);

        pool.change.tokenWithdrawn += amount;
    }

    /*
    * withdraw token and usdt by pool owner
    * can only run once
    */
    function _withdrawPool(uint256 poolId) onlyPoolOwner(poolId) private {
        Pool storage pool = pools[poolId];

        if (pool.status == PoolStatus.Finished) {
            revert Pool_status_error();
        }
        pool.status = PoolStatus.Finished;

        _transferToOther(usdt, msg.sender, pool.cap.usdtStaked - pool.change.usdtSpent);

        _transferToOther(pool.config.stakeToken, msg.sender, pool.change.tokenSwapped);
    }

    /**
    * after unlock time, if pool is not fully usdt-deposited,
    * a user can withdraw all tokes and get compensated
    */
    function withdrawDueToLackUSDT(uint256 poolId) nonReentrant public {
        _ensurePoolStatus(poolId, PoolStatus.Active);
        _ensurePoolUnlock(poolId);

        if (_isUSDTFullyDeposited(poolId)) {
            revert The_pool_is_fully_funded__Please_swap_your_token();
        }

        uint256 compensate = getCompensate(poolId);

        _transferToOther(usdt, msg.sender, compensate);
        _transferToOther(usdt, owner(), compensate);

        pools[poolId].change.usdtSpent += compensate * 2;

        _withdrawToken(poolId, 0);

        _ensureSelfUSDTBalance();
        _ensureSelfTokenBalance(poolId);
    }

    /**
    * a user can withdraw all tokens if pool is stopped (by owner)
    */
    function withdrawDueToStop(uint256 poolId) nonReentrant public {
        _ensurePoolStatus(poolId, PoolStatus.Stopped);

        if (msg.sender != poolOwners[poolId]) {
            // normal user can only withdraw token
            _withdrawToken(poolId, 0);
        } else {
            // pool owner can only withdraw usdt and swapped tokens
            _withdrawPool(poolId);
        }

        _ensureSelfUSDTBalance();
        _ensureSelfTokenBalance(poolId);
    }

    /**
    * after unlock time, a user can withdraw all tokens at any condition
    */
    function withdrawToken(uint256 poolId) nonReentrant public {
        _ensurePoolUnlock(poolId);

        _withdrawToken(poolId, 0);

        _ensureSelfUSDTBalance();
        _ensureSelfTokenBalance(poolId);
    }

    /*
    * poll owner withdraw usdt remaining in the pool
    * and the swapped tokens
    * should after end time (72 hours after the pool is unlocked)
    */
    function withdrawPool(uint256 poolId) onlyPoolOwner(poolId) nonReentrant public {
        _ensurePoolEnded(poolId);

        _withdrawPool(poolId);

        _ensureSelfUSDTBalance();
        _ensureSelfTokenBalance(poolId);
    }

    /**
     * owner could stop pool if there is any bug or issue
     * if a pool is stopped. users can withdraw their tokens
     * and pool creator could withdraw their usdt
     */
    function stopPool(uint256 poolId) onlyOwner public {
        Pool storage pool = pools[poolId];
        pool.status = PoolStatus.Stopped;

        emit PoolClosed(poolId, msg.sender);
    }
}