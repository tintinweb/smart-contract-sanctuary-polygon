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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract MetaspaceNFTMarketplace is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 constant MATIC = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    enum ListingStage {
        Unlisted,
        FixedPrice,
        Auction
    }

    struct PlatformData {
        uint256 platformFeesPercentage;
        uint256 royaltyPercentage;
        address payable feeReceiver;
        uint256 totalRoyaltyEarned;
        uint256 totalPlatformFeesEarned;
        uint256 totalNFTSold;
        mapping(IERC20 => uint256) totalVolumeTraded;
        // Mapping of supported Currencies
        mapping(IERC20 => bool) isSupportedCurrency;
    }

    // Mapping of supported NFT for listing
    mapping(IERC721 => bool) public isSupportedNFT;

    PlatformData public platformData;

    struct NFTInfo {
        address payable owner;
        IERC20 tradeCurrency;
        uint256 price;
        ListingStage listingStage;
        address highestBidder;
        uint256 highestBid;
    }

    mapping(IERC721 => mapping(uint256 => NFTInfo)) public nftInfo;

    event NFTtraded(
        IERC721 indexed nftContractAddress,
        uint256 indexed tokenID,
        address newOwner,
        address previousOwner,
        uint256 price,
        IERC20 currency,
        uint256 timestamp
    );

    event AuctionStaged(
        IERC721 indexed nftContractAddress,
        uint256 indexed tokenID
    );

    event NFTPriceUpdate(
        IERC721 indexed nftContractAddress,
        uint256 indexed tokenID,
        uint256 newPrice
    );

    event BidPlaced(
        IERC721 indexed nftContractAddress,
        uint256 indexed tokenID,
        address indexed bidder,
        uint256 bidAmount,
        uint256 biddingTime
    );

    event BidWithdrawn(
        IERC721 indexed nftContractAddress,
        uint256 indexed tokenID,
        address indexed bidder,
        uint256 withdrawalTime
    );

    event NftListed(
        IERC721 indexed nftAddress,
        uint256 indexed tokenId,
        IERC20 listingCurrency,
        uint256 price,
        bool isAtAuction,
        address indexed owner,
        uint256 listingTime
    );

    modifier isNFTOwner(IERC721 _nftContract, uint256 _tokenID) {
        NFTInfo memory info = nftInfo[_nftContract][_tokenID];
        require((msg.sender == info.owner), "Not NFT owner");
        _;
    }

    modifier atAuction(IERC721 _nftContract, uint256 _tokenID) {
        NFTInfo memory info = nftInfo[_nftContract][_tokenID];
        require(
            info.listingStage == ListingStage.Auction,
            "NFT not at auction"
        );
        _;
    }

    modifier validPercentage(uint256 _percentage) {
        require(_percentage < 10, "Percentage too high");
        _;
    }

    modifier zeroAddressCheck(address _addr) {
        require(_addr != address(0), "Zero Address");
        _;
    }

    receive() external payable {}

    constructor(
        address payable _feeReceiver,
        uint256 _platformFeesPercentage,
        uint256 _royaltyPercentage
    )
        validPercentage(_royaltyPercentage)
        validPercentage(_platformFeesPercentage)
        zeroAddressCheck(_feeReceiver)
    {
        platformData.feeReceiver = _feeReceiver;
        platformData.platformFeesPercentage = _platformFeesPercentage;
        platformData.royaltyPercentage = _royaltyPercentage;

        // added matic as supported by default
        platformData.isSupportedCurrency[MATIC] = true;
    }

    function listInBatch(
        IERC721 _nftContractAddress,
        uint256[] calldata _tokenIds,
        IERC20 _currency,
        uint256[] calldata _price,
        bool[] calldata _listAsAuction
    ) external {
        uint256 tokensQuantity = _tokenIds.length;
        require(
            tokensQuantity == _listAsAuction.length &&
                _price.length == tokensQuantity,
            "Invalid list length"
        );
        for (uint256 i; i < tokensQuantity; ) {
            listNFT(
                _nftContractAddress,
                _tokenIds[i],
                _currency,
                _price[i],
                _listAsAuction[i]
            );
            unchecked {
                i = i + 1;
            }
        }
    }

    function listNFT(
        IERC721 _nftContractAddress,
        uint256 _tokenID,
        IERC20 _currency,
        uint256 _price,
        bool _listAsAuction
    ) public zeroAddressCheck(address(_nftContractAddress)) {
        NFTInfo storage info = nftInfo[_nftContractAddress][_tokenID];

        require(
            info.listingStage == ListingStage.Unlisted,
            "NFT already listed"
        );
        require(
            platformData.isSupportedCurrency[_currency] == true,
            "Unsupported currency"
        );
        require(isSupportedNFT[_nftContractAddress], "Unsupported NFT");
        require(_price != 0, "Invalid price");

        info.owner = payable(msg.sender);
        info.tradeCurrency = _currency;
        info.price = _price;
        if (_listAsAuction) info.listingStage = ListingStage.Auction;
        else info.listingStage = ListingStage.FixedPrice;
        //transfer Erc721 from sender wallet to this contract
        _nftContractAddress.transferFrom(msg.sender, address(this), _tokenID);

        emit NftListed(
            _nftContractAddress,
            _tokenID,
            _currency,
            _price,
            _listAsAuction,
            msg.sender,
            block.timestamp
        );
    }

    // changes existing Marketplace Stage from FixedPrice to Auction
    function switchToAuction(
        IERC721 _nftContract,
        uint256 _tokenID,
        IERC20 _currency,
        uint256 _basePrice
    ) external isNFTOwner(_nftContract, _tokenID) {
        NFTInfo storage info = nftInfo[_nftContract][_tokenID];

        require(
            info.listingStage == ListingStage.FixedPrice,
            "Already at auction"
        );

        info.listingStage = ListingStage.Auction;
        info.price = _basePrice;
        info.tradeCurrency = _currency;

        emit AuctionStaged(_nftContract, _tokenID);
    }

    //Updates NFT price in the listed supported currency
    function updateNFTPrice(
        IERC721 _nftContract,
        uint256 _tokenID,
        uint256 price
    ) external isNFTOwner(_nftContract, _tokenID) {
        NFTInfo storage info = nftInfo[_nftContract][_tokenID];
        require(
            info.listingStage == ListingStage.FixedPrice,
            "Should be listed for Purchase at Fixed Price"
        );
        require(price != 0, "Invalid price");

        info.price = price;

        emit NFTPriceUpdate(_nftContract, _tokenID, price);
    }

    function _trade(
        IERC721 _nftContract,
        uint256 _tokenID,
        bool _isAcceptingBid
    ) internal {
        NFTInfo memory info = nftInfo[_nftContract][_tokenID];
        address _buyer = msg.sender;
        address payable nftOwner = info.owner;
        uint256 price = info.price;
        IERC20 _currency = info.tradeCurrency;

        if (_isAcceptingBid) {
            _buyer = info.highestBidder;
            price = info.highestBid;
        }

        uint256 _royaltyAmount = (price * platformData.royaltyPercentage) / 100;
        uint256 _commission = (price * platformData.platformFeesPercentage) /
            100;
        uint256 totalFees = _royaltyAmount + _commission;
        uint256 ownerReceiveAmount = price - totalFees;

        if (_currency == MATIC) {
            platformData.feeReceiver.transfer(totalFees);
            nftOwner.transfer(ownerReceiveAmount);
        } else {
            if (!_isAcceptingBid) {
                IERC20(_currency).safeTransferFrom(
                    msg.sender,
                    platformData.feeReceiver,
                    totalFees
                );
                IERC20(_currency).safeTransferFrom(
                    msg.sender,
                    nftOwner,
                    ownerReceiveAmount
                );
            }
            IERC20(_currency).safeTransfer(platformData.feeReceiver, totalFees);
            IERC20(_currency).safeTransfer(nftOwner, ownerReceiveAmount);
        }

        platformData.totalVolumeTraded[_currency] += price;
        if (nftOwner == owner()) platformData.totalNFTSold += 1;
        //transfer nft to buyer
        _nftContract.transferFrom(address(this), _buyer, _tokenID);

        // reset nft info for new owner
        delete nftInfo[_nftContract][_tokenID];

        emit NFTtraded(
            _nftContract,
            _tokenID,
            _buyer,
            nftOwner,
            price,
            _currency,
            block.timestamp
        );
    }

    function buyAtFixedPrice(
        IERC721 _nftContract,
        uint256 _tokenID
    ) external payable nonReentrant {
        NFTInfo memory info = nftInfo[_nftContract][_tokenID];
        require((msg.sender != info.owner), "NFT owner not Authorized");
        require(
            info.listingStage == ListingStage.FixedPrice,
            "Should be listed for Purchase at Fixed Price"
        );
        require(msg.value == info.price, "Insufficient Matic");
        _trade(_nftContract, _tokenID, false);
    }

    function withdrawHighestBid(
        IERC721 _nftContract,
        uint256 _tokenID
    ) external atAuction(_nftContract, _tokenID) nonReentrant {
        NFTInfo storage info = nftInfo[_nftContract][_tokenID];
        address payable highestBidder = payable(info.highestBidder);
        require((msg.sender == highestBidder), "Not Highest bidder");

        IERC20 _currency = info.tradeCurrency;
        uint256 highestBid = info.highestBid;

        if (_currency == MATIC) {
            highestBidder.transfer(highestBid);
        } else {
            // transfer highest bid to highest bidder
            IERC20(_currency).safeTransfer(highestBidder, highestBid);
        }

        info.highestBid = 0;
        info.highestBidder = address(0);

        emit BidWithdrawn(_nftContract, _tokenID, msg.sender, block.timestamp);
    }

    function bid(
        IERC721 _nftContract,
        uint256 _tokenID,
        uint256 _biddingAmount
    ) external payable atAuction(_nftContract, _tokenID) nonReentrant {
        NFTInfo storage info = nftInfo[_nftContract][_tokenID];
        require((msg.sender != info.owner), "NFT owner not Authorized");

        IERC20 _currency = info.tradeCurrency;
        uint256 _previousHighestBid = info.highestBid;

        if (_currency == MATIC) _biddingAmount = msg.value;

        require(
            _biddingAmount >= info.price &&
                (_biddingAmount > _previousHighestBid),
            "Insufficient Bidding Amount"
        );

        address payable _previousHighestBidder = payable(info.highestBidder);

        if (_currency == MATIC && (_previousHighestBidder != address(0))) {
            _previousHighestBidder.transfer(_previousHighestBid);
        } else if (_currency != MATIC) {
            IERC20(_currency).safeTransferFrom(
                msg.sender,
                address(this),
                _biddingAmount
            );
            if (_previousHighestBidder != address(0)) {
                // transfer previous highest bid to previous highest bidder
                IERC20(_currency).safeTransfer(
                    _previousHighestBidder,
                    _previousHighestBid
                );
            }
        }

        info.highestBid = _biddingAmount;
        info.highestBidder = msg.sender;

        emit BidPlaced(
            _nftContract,
            _tokenID,
            msg.sender,
            _biddingAmount,
            block.timestamp
        );
    }

    function acceptHighestBid(
        IERC721 _nftContract,
        uint256 _tokenID
    )
        public
        atAuction(_nftContract, _tokenID)
        isNFTOwner(_nftContract, _tokenID)
        nonReentrant
    {
        NFTInfo memory info = nftInfo[_nftContract][_tokenID];
        require(
            info.listingStage == ListingStage.Auction,
            "NFT not at auction"
        );
        require(
            info.highestBid != 0 && info.highestBidder != address(0),
            "No Bids yet"
        );

        _trade(_nftContract, _tokenID, true);
    }

    function getNFTInfo(
        IERC721 _nftContract,
        uint256 _tokenID
    ) external view returns (NFTInfo memory) {
        NFTInfo memory info = nftInfo[_nftContract][_tokenID];
        require(info.listingStage == ListingStage.Unlisted, "NFT Not Listed");
        return info;
    }

    function getCurrencyVolumeTraded(
        IERC20 _currency
    ) external view returns (uint256 volumeTraded) {
        return platformData.totalVolumeTraded[_currency];
    }

    function updatePlatformFeesPercentage(
        uint256 _newCommission
    ) public onlyOwner validPercentage(_newCommission) {
        platformData.platformFeesPercentage = _newCommission;
    }

    function updateRoyaltyFeePercentage(
        uint256 _newRoyaltyPercentage
    ) public onlyOwner validPercentage(_newRoyaltyPercentage) {
        platformData.royaltyPercentage = _newRoyaltyPercentage;
    }

    function updateSupportedCurrency(
        IERC20 _currency,
        bool updateStatus
    ) public onlyOwner zeroAddressCheck(address(_currency)) {
        platformData.isSupportedCurrency[_currency] = updateStatus;
    }

    function updateSupportedNFT(
        IERC721 _nftContractAddress,
        bool updateStatus
    ) public onlyOwner zeroAddressCheck(address(_nftContractAddress)) {
        isSupportedNFT[_nftContractAddress] = updateStatus;
    }
}