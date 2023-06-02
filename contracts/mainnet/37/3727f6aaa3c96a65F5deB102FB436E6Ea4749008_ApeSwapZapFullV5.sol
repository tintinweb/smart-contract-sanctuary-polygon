// SPDX-License-Identifier: MIT
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IUniswapV3PoolImmutables} from './pool/IUniswapV3PoolImmutables.sol';
import {IUniswapV3PoolState} from './pool/IUniswapV3PoolState.sol';
import {IUniswapV3PoolDerivedState} from './pool/IUniswapV3PoolDerivedState.sol';
import {IUniswapV3PoolActions} from './pool/IUniswapV3PoolActions.sol';
import {IUniswapV3PoolOwnerActions} from './pool/IUniswapV3PoolOwnerActions.sol';
import {IUniswapV3PoolErrors} from './pool/IUniswapV3PoolErrors.sol';
import {IUniswapV3PoolEvents} from './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolErrors,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Errors emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolErrors {
    error LOK();
    error TLU();
    error TLM();
    error TUM();
    error AI();
    error M0();
    error M1();
    error AS();
    error IIA();
    error L();
    error F0();
    error F1();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// @return observationIndex The index of the last oracle observation that was written,
    /// @return observationCardinality The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    /// @return The liquidity at the current price of the pool
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper
    /// @return liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// @return feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// @return feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// @return tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// @return secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// @return secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// @return initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return liquidity The amount of liquidity in the position,
    /// @return feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// @return feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// @return tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// @return tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// @return tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// @return secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// @return initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    error T();
    error R();

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert T();

            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            if (!(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO)) revert R();
            uint256 ratio = uint256(sqrtPriceX96) << 32;

            uint256 r = ratio;
            uint256 msb = 0;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

/*
  ______                     ______                                 
 /      \                   /      \                                
|  ▓▓▓▓▓▓\ ______   ______ |  ▓▓▓▓▓▓\__   __   __  ______   ______  
| ▓▓__| ▓▓/      \ /      \| ▓▓___\▓▓  \ |  \ |  \|      \ /      \ 
| ▓▓    ▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\\▓▓    \| ▓▓ | ▓▓ | ▓▓ \▓▓▓▓▓▓\  ▓▓▓▓▓▓\
| ▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓    ▓▓_\▓▓▓▓▓▓\ ▓▓ | ▓▓ | ▓▓/      ▓▓ ▓▓  | ▓▓
| ▓▓  | ▓▓ ▓▓__/ ▓▓ ▓▓▓▓▓▓▓▓  \__| ▓▓ ▓▓_/ ▓▓_/ ▓▓  ▓▓▓▓▓▓▓ ▓▓__/ ▓▓
| ▓▓  | ▓▓ ▓▓    ▓▓\▓▓     \\▓▓    ▓▓\▓▓   ▓▓   ▓▓\▓▓    ▓▓ ▓▓    ▓▓
 \▓▓   \▓▓ ▓▓▓▓▓▓▓  \▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓\▓▓▓▓  \▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓ 
         | ▓▓                                             | ▓▓      
         | ▓▓                                             | ▓▓      
          \▓▓                                              \▓▓         
 * App:             https://ApeSwap.finance
 * Medium:          https://ape-swap.medium.com
 * Twitter:         https://twitter.com/ape_swap
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * Discord:         https://ApeSwap.click/discord
 * Reddit:          https://reddit.com/r/ApeSwap
 * Instagram:       https://instagram.com/ApeSwap.finance
 * GitHub:          https://github.com/ApeSwapFinance
 */

import "./extensions/swap/ZapSwap.sol";
import "./extensions/liquidity/ZapLiquidity.sol";
import "./WrapNative.sol";
import "./extensions/bills/ApeSwapZapTBills.sol";
import "./extensions/farms/ApeSwapZapMiniApeV2.sol";
import "./extensions/pools/ApeSwapZapPools.sol";
import "./extensions/pools/libraries/ITreasury.sol";
import "./extensions/vaults/ApeSwapZapVaults.sol";
import "./extensions/lending/ApeSwapZapLending.sol";
import "./lens/ZapAnalyzer.sol";
import "./utils/Multicall.sol";
import "./interfaces/IWETH.sol";

contract ApeSwapZapFullV5 is
    WrapNative,
    ZapSwap,
    ZapLiquidity,
    ApeSwapZapTBills,
    ApeSwapZapMiniApeV2,
    ApeSwapZapPools,
    ApeSwapZapVaults,
    ApeSwapZapLending,
    Multicall
{
    /// @dev ZapAnalyzer lens contract for estimating swap returns.
    IZapAnalyzer public zapAnalyzer;

    constructor(
        IWETH wNative,
        ITreasury goldenBananaTreasury,
        address _zapAnalyzer
    ) WrapNative(wNative) ApeSwapZapPools(goldenBananaTreasury) {
        zapAnalyzer = ZapAnalyzer(_zapAnalyzer);
    }

    /**
     * @dev This function estimates the swap returns based on the given parameters.
     * @param params The struct containing the necessary parameters for estimating swap returns.
     *  See {IZapAnalyzer.SwapReturnsParams} for more information.
     * @return returnValues The struct containing the estimated swap returns.
     *  See {IZapAnalyzer.SwapReturns} for more information.
     */
    function estimateSwapReturns(IZapAnalyzer.SwapReturnsParams memory params)
        external
        view
        returns (IZapAnalyzer.SwapReturns memory returnValues)
    {
        return zapAnalyzer.estimateSwapReturns(params);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./libraries/ICustomBill.sol";
import "../swap/features/univ2/lib/IV2SwapRouter02.sol";
import "../liquidity/features/univ2/lib/IApePair.sol";
import "../../libraries/Constants.sol";
import "../../utils/TransferHelper.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract ApeSwapZapTBills is TransferHelper {
    using SafeERC20 for IERC20;

    struct zapTBillParams {
        ICustomBill bill;
        uint256 inputAmount;
        uint256 maxPrice;
        address recipient;
    }

    event ZapTBill(zapTBillParams params);

    function zapTBill(zapTBillParams memory params) external payable {
        IERC20 inputToken = IERC20(params.bill.principalToken());
        params.inputAmount = _transferIn(inputToken, params.inputAmount);

        if (params.recipient == Constants.MSG_SENDER) params.recipient = msg.sender;
        else if (params.recipient == Constants.ADDRESS_THIS) params.recipient = address(this);

        inputToken.approve(address(params.bill), params.inputAmount);
        params.bill.deposit(params.inputAmount, params.maxPrice, params.recipient);
        inputToken.approve(address(params.bill), 0);
        emit ZapTBill(params);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface ICustomBill {
    function principalToken() external returns (address);

    function deposit(uint256 _amount, uint256 _maxPrice, address _depositor) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./libraries/IMiniApeV2.sol";
import "../../libraries/Constants.sol";
import "../../utils/TransferHelper.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract ApeSwapZapMiniApeV2 is TransferHelper {
    using SafeERC20 for IERC20;

    struct zapMiniApeV2Params {
        uint256 inputAmount;
        IMiniApeV2 miniApe;
        uint256 pid;
        address recipient;
    }

    event ZapMiniApeV2(zapMiniApeV2Params params);

    function zapMiniApeV2(zapMiniApeV2Params memory params) external payable {
        IERC20 inputToken = IERC20(IMiniApeV2(params.miniApe).lpToken(params.pid));
        params.inputAmount = _transferIn(inputToken, params.inputAmount);

        if (params.recipient == Constants.MSG_SENDER) params.recipient = msg.sender;
        else if (params.recipient == Constants.ADDRESS_THIS) params.recipient = address(this);

        inputToken.approve(address(params.miniApe), params.inputAmount);
        params.miniApe.deposit(params.pid, params.inputAmount, params.recipient);
        inputToken.approve(address(params.miniApe), 0);
        emit ZapMiniApeV2(params);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMiniApeV2 {
    function lpToken(uint256 pid) external returns (address);

    function deposit(uint256 pid, uint256 amount, address to) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./lib/ICErc20.sol";
import "../../utils/TransferHelper.sol";

abstract contract ApeSwapZapLending is TransferHelper {
    using SafeERC20 for IERC20;
    using SafeERC20 for ICErc20;

    /// @dev Native token market underlying
    address public constant LENDING_NATIVE_UNDERLYING = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    event ZapLending(uint256 inputAmount, ICErc20 market, uint256 outputAmount);
    event ZapLendingMarket(uint256 inputAmount, ICErc20 market);

    /// @notice Zap token single asset lending market
    /// @param inputAmount Amount of input tokens to zap
    /// @param market Lending market to deposit to
    /// @param recipient Recipient of cTokens
    function zapLendingMarket(uint256 inputAmount, ICErc20 market, address recipient) external payable {
        IERC20 underlyingToken = IERC20(market.underlying());

        if (address(underlyingToken) == LENDING_NATIVE_UNDERLYING) {
            uint256 depositAmount = inputAmount == Constants.CONTRACT_BALANCE ? address(this).balance : inputAmount;
            market.mint{value: depositAmount}();
        } else {
            inputAmount = _transferIn(underlyingToken, inputAmount);
            uint256 depositAmount = underlyingToken.balanceOf(address(this));
            underlyingToken.approve(address(market), depositAmount);
            uint256 mintFailure = market.mint(depositAmount);
            require(mintFailure == 0, "ApeSwapZapLending: Mint failed");
            underlyingToken.approve(address(market), 0);
        }
        uint256 cTokensReceived = market.balanceOf(address(this));
        require(cTokensReceived > 0, "ApeSwapZapLending: Nothing deposited");

        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;

        if (recipient != Constants.ADDRESS_THIS && recipient != address(this)) {
            underlyingToken.transfer(recipient, cTokensReceived);
        }

        emit ZapLending(inputAmount, market, cTokensReceived);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface EIP20NonStandardInterface {
    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     */
    function transferFrom(address src, address dst, uint256 amount) external;

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved
     * @return success Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return remaining The number of tokens allowed to be spent
     */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./EIP20NonStandardInterface.sol";

/// @title Compound's CErc20 Contract
/// @notice CTokens which wrap an EIP-20 underlying and are delegated to a CTokenDelegate
/// @dev Interface from CErc20V0_05.sol
interface ICErc20 is EIP20NonStandardInterface {
    /**
     * @notice EIP-20 token name for this token
     */
    function name() external view returns (string memory);

    /**
     * @notice EIP-20 token symbol for this token
     */
    function symbol() external view returns (string memory);

    /**
     * @notice EIP-20 token decimals for this token
     */
    function decimals() external view returns (uint8);

    /**
     * @notice Underlying asset for this CToken
     */
    function underlying() external view returns (address);

    /**
     * @notice Sender supplies assets into the market and receives cTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function mint(uint mintAmount) external returns (uint);

    /**
     * @notice Sender supplies assets into the market and receives cTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     */
    function mint() external payable;

    /**
     * @notice Sender redeems cTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of cTokens to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint redeemTokens) external returns (uint);

    /**
     * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlying(uint redeemAmount) external returns (uint);

    /**
     * @notice Sender borrows assets from the protocol to their own address
     * @param borrowAmount The amount of the underlying asset to borrow
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function borrow(uint borrowAmount) external returns (uint);

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrow(uint repayAmount) external returns (uint);

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @param borrower the account with the debt being payed off
     * @param repayAmount The amount to repay
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);

    /**
     * @notice The sender liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of this cToken to be liquidated
     * @param repayAmount The amount of the underlying borrowed asset to repay
     * @param cTokenCollateral The market in which to seize collateral from the borrower
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function liquidateBorrow(address borrower, uint repayAmount, address cTokenCollateral) external returns (uint);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

/*
  ______                     ______                                 
 /      \                   /      \                                
|  ▓▓▓▓▓▓\ ______   ______ |  ▓▓▓▓▓▓\__   __   __  ______   ______  
| ▓▓__| ▓▓/      \ /      \| ▓▓___\▓▓  \ |  \ |  \|      \ /      \ 
| ▓▓    ▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\\▓▓    \| ▓▓ | ▓▓ | ▓▓ \▓▓▓▓▓▓\  ▓▓▓▓▓▓\
| ▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓    ▓▓_\▓▓▓▓▓▓\ ▓▓ | ▓▓ | ▓▓/      ▓▓ ▓▓  | ▓▓
| ▓▓  | ▓▓ ▓▓__/ ▓▓ ▓▓▓▓▓▓▓▓  \__| ▓▓ ▓▓_/ ▓▓_/ ▓▓  ▓▓▓▓▓▓▓ ▓▓__/ ▓▓
| ▓▓  | ▓▓ ▓▓    ▓▓\▓▓     \\▓▓    ▓▓\▓▓   ▓▓   ▓▓\▓▓    ▓▓ ▓▓    ▓▓
 \▓▓   \▓▓ ▓▓▓▓▓▓▓  \▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓\▓▓▓▓  \▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓ 
         | ▓▓                                             | ▓▓      
         | ▓▓                                             | ▓▓      
          \▓▓                                              \▓▓         
 * App:             https://ApeSwap.finance
 * Medium:          https://ape-swap.medium.com
 * Twitter:         https://twitter.com/ape_swap
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * Discord:         https://ApeSwap.click/discord
 * Reddit:          https://reddit.com/r/ApeSwap
 * Instagram:       https://instagram.com/ApeSwap.finance
 * GitHub:          https://github.com/ApeSwapFinance
 */

import "./lib/IArrakisPool.sol";
import "./lib/IArrakisFactoryV1.sol";

library ArrakisHelper {
    /// @notice get arrakis pool from uniV3 pool
    /// @param uniV3Pool uniV3 pool
    /// @param arrakisFactory arrakis factory
    /// @return pool Arrakis pool
    function getArrakisPool(address uniV3Pool, IArrakisFactoryV1 arrakisFactory) internal view returns (address) {
        address[] memory deployers = arrakisFactory.getDeployers();
        for (uint256 i = 0; i < deployers.length; i++) {
            address[] memory pools = arrakisFactory.getPools(deployers[i]);
            for (uint256 n = 0; n < pools.length; n++) {
                address pool = pools[n];
                if (address(IArrakisPool(pool).pool()) == uniV3Pool) {
                    return pool;
                }
            }
        }
        revert("ArrakisHelper: Arrakis pool not found");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IArrakisFactoryV1 {
    function deployVault(
        address token0,
        address token1,
        uint24 uniFee,
        address manager,
        uint16 managerFee,
        int24 lowerTick,
        int24 upperTick
    ) external returns (address pool);

    function getTokenName(address token0, address token1) external view returns (string memory);

    function upgradePools(address[] memory pools) external;

    function upgradePoolsAndCall(address[] memory pools, bytes[] calldata datas) external;

    function makePoolsImmutable(address[] memory pools) external;

    function isPoolImmutable(address pool) external view returns (bool);

    function getGelatoPools() external view returns (address[] memory);

    function getDeployers() external view returns (address[] memory);

    function getPools(address deployer) external view returns (address[] memory);

    function numPools() external view returns (uint256 result);

    function numDeployers() external view returns (uint256);

    function numPools(address deployer) external view returns (uint256);

    function getProxyAdmin(address pool) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

interface IArrakisPool {
    function mint(
        uint256 mintAmount,
        address receiver
    ) external returns (uint256 amount0, uint256 amount1, uint128 liquidityMinted);

    function burn(
        uint256 burnAmount,
        address receiver
    ) external returns (uint256 amount0, uint256 amount1, uint128 liquidityBurned);

    function getMintAmounts(
        uint256 amount0Max,
        uint256 amount1Max
    ) external view returns (uint256 amount0, uint256 amount1, uint256 mintAmount);

    function getUnderlyingBalances() external view returns (uint256 amount0, uint256 amount1);

    function getPositionID() external view returns (bytes32 positionID);

    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);

    function upperTick() external view returns (int24);

    function lowerTick() external view returns (int24);

    function pool() external view returns (IUniswapV3Pool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

import {IArrakisPool} from "./IArrakisPool.sol";

interface IArrakisRouter {
    function factory() external view returns (address);

    function addLiquidity(
        IArrakisPool pool,
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 amount0Min,
        uint256 amount1Min,
        address receiver
    ) external returns (uint256 amount0, uint256 amount1, uint256 mintAmount);

    function addLiquidityETH(
        IArrakisPool pool,
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 amount0Min,
        uint256 amount1Min,
        address receiver
    ) external payable returns (uint256 amount0, uint256 amount1, uint256 mintAmount);

    function rebalanceAndAddLiquidity(
        IArrakisPool pool,
        uint256 amount0In,
        uint256 amount1In,
        bool zeroForOne,
        uint256 swapAmount,
        uint160 swapThreshold,
        uint256 amount0Min,
        uint256 amount1Min,
        address receiver
    ) external returns (uint256 amount0, uint256 amount1, uint256 mintAmount);

    function rebalanceAndAddLiquidityETH(
        IArrakisPool pool,
        uint256 amount0In,
        uint256 amount1In,
        bool zeroForOne,
        uint256 swapAmount,
        uint160 swapThreshold,
        uint256 amount0Min,
        uint256 amount1Min,
        address receiver
    ) external payable returns (uint256 amount0, uint256 amount1, uint256 mintAmount);

    function removeLiquidity(
        IArrakisPool pool,
        uint256 burnAmount,
        uint256 amount0Min,
        uint256 amount1Min,
        address receiver
    ) external returns (uint256 amount0, uint256 amount1, uint128 liquidityBurned);

    function removeLiquidityETH(
        IArrakisPool pool,
        uint256 burnAmount,
        uint256 amount0Min,
        uint256 amount1Min,
        address payable receiver
    ) external returns (uint256 amount0, uint256 amount1, uint128 liquidityBurned);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface Hypervisor {
    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);

    function whitelistedAddress() external view returns (address);

    function withdraw(
        uint256 shares,
        address to,
        address from,
        uint256[4] memory minAmounts
    ) external returns (uint256 amount0, uint256 amount1);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

interface UniProxy {
    function deposit(
        uint256 deposit0,
        uint256 deposit1,
        address to,
        address pos,
        uint256[4] memory inMin
    ) external returns (uint256 shares);

    function getDepositAmount(
        address pos,
        address token,
        uint256 _deposit
    ) external view returns (uint256 amountStart, uint256 amountEnd);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.6.6;

interface IApeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address token0, address token1) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address token0, address token1) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.6.6;

interface IApePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IV2LiquidityRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address token0,
        address token1,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address token0,
        address token1,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address token0,
        address token1,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./IV2LiquidityRouter01.sol";

interface IV2LiquidityRouter02 is IV2LiquidityRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title ERC721 with permit
/// @notice Extension to ERC721 that includes a permit function for signature based approvals
interface IERC721Permit is IERC721 {
    /// @notice The permit typehash used in the permit signature
    /// @return The typehash for the permit
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /// @notice The domain separator used in the permit signature
    /// @return The domain seperator used in encoding of permit signature
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Approve of a specific token ID for spending by spender via signature
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(address spender, uint256 tokenId, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import "./IPoolInitializer.sol";
import "./IERC721Permit.sol";
import "./IPeripheryPayments.sol";
import "./IPeripheryImmutableState.sol";

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is
    IPoolInitializer,
    IPeripheryPayments,
    IPeripheryImmutableState,
    IERC721Metadata,
    IERC721Enumerable,
    IERC721Permit
{
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(
        MintParams calldata params
    ) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(
        IncreaseLiquidityParams calldata params
    ) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(address token, uint256 amountMinimum, address recipient) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

/// @title Creates and initializes V3 Pools
/// @notice Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
/// require the pool to exist.
interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action
    ///   (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the
    ///  newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

/*
  ______                     ______                                 
 /      \                   /      \                                
|  ▓▓▓▓▓▓\ ______   ______ |  ▓▓▓▓▓▓\__   __   __  ______   ______  
| ▓▓__| ▓▓/      \ /      \| ▓▓___\▓▓  \ |  \ |  \|      \ /      \ 
| ▓▓    ▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\\▓▓    \| ▓▓ | ▓▓ | ▓▓ \▓▓▓▓▓▓\  ▓▓▓▓▓▓\
| ▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓    ▓▓_\▓▓▓▓▓▓\ ▓▓ | ▓▓ | ▓▓/      ▓▓ ▓▓  | ▓▓
| ▓▓  | ▓▓ ▓▓__/ ▓▓ ▓▓▓▓▓▓▓▓  \__| ▓▓ ▓▓_/ ▓▓_/ ▓▓  ▓▓▓▓▓▓▓ ▓▓__/ ▓▓
| ▓▓  | ▓▓ ▓▓    ▓▓\▓▓     \\▓▓    ▓▓\▓▓   ▓▓   ▓▓\▓▓    ▓▓ ▓▓    ▓▓
 \▓▓   \▓▓ ▓▓▓▓▓▓▓  \▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓\▓▓▓▓  \▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓ 
         | ▓▓                                             | ▓▓      
         | ▓▓                                             | ▓▓      
          \▓▓                                              \▓▓         
 * App:             https://ApeSwap.finance
 * Medium:          https://ape-swap.medium.com
 * Twitter:         https://twitter.com/ape_swap
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * Discord:         https://ApeSwap.click/discord
 * Reddit:          https://reddit.com/r/ApeSwap
 * Instagram:       https://instagram.com/ApeSwap.finance
 * GitHub:          https://github.com/ApeSwapFinance
 */

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

library UniV3LiquidityHelper {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    function getLPAddRatio(
        address uniV3Factory,
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper
    ) internal view returns (uint256 amount0, uint256 amount1) {
        uint160 lowPrice = TickMath.getSqrtRatioAtTick(tickLower);
        (uint160 currentPrice, , , , , , ) = IUniswapV3Pool(
            IUniswapV3Factory(uniV3Factory).getPool(token0, token1, fee)
        ).slot0();
        uint160 highPrice = TickMath.getSqrtRatioAtTick(tickUpper);
        uint256 intermediate = FullMath.mulDiv(currentPrice, highPrice, FixedPoint96.Q96);
        uint128 liquidity = toUint128(FullMath.mulDiv(1e18, intermediate, highPrice - currentPrice));
        amount0 = 1e18;
        amount1 = FullMath.mulDivRoundingUp(liquidity, currentPrice - lowPrice, FixedPoint96.Q96);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

/*
  ______                     ______                                 
 /      \                   /      \                                
|  ▓▓▓▓▓▓\ ______   ______ |  ▓▓▓▓▓▓\__   __   __  ______   ______  
| ▓▓__| ▓▓/      \ /      \| ▓▓___\▓▓  \ |  \ |  \|      \ /      \ 
| ▓▓    ▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\\▓▓    \| ▓▓ | ▓▓ | ▓▓ \▓▓▓▓▓▓\  ▓▓▓▓▓▓\
| ▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓    ▓▓_\▓▓▓▓▓▓\ ▓▓ | ▓▓ | ▓▓/      ▓▓ ▓▓  | ▓▓
| ▓▓  | ▓▓ ▓▓__/ ▓▓ ▓▓▓▓▓▓▓▓  \__| ▓▓ ▓▓_/ ▓▓_/ ▓▓  ▓▓▓▓▓▓▓ ▓▓__/ ▓▓
| ▓▓  | ▓▓ ▓▓    ▓▓\▓▓     \\▓▓    ▓▓\▓▓   ▓▓   ▓▓\▓▓    ▓▓ ▓▓    ▓▓
 \▓▓   \▓▓ ▓▓▓▓▓▓▓  \▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓\▓▓▓▓  \▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓ 
         | ▓▓                                             | ▓▓      
         | ▓▓                                             | ▓▓      
          \▓▓                                              \▓▓         
 * App:             https://ApeSwap.finance
 * Medium:          https://ape-swap.medium.com
 * Twitter:         https://twitter.com/ape_swap
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * Discord:         https://ApeSwap.click/discord
 * Reddit:          https://reddit.com/r/ApeSwap
 * Instagram:       https://instagram.com/ApeSwap.finance
 * GitHub:          https://github.com/ApeSwapFinance
 */

import "./features/arrakis/lib/IArrakisRouter.sol";
import "./features/arrakis/lib/IArrakisPool.sol";
import "./features/arrakis/ArrakisHelper.sol";
import "./features/univ3/lib/INonfungiblePositionManager.sol";
import "./features/univ2/lib/IApePair.sol";
import "./features/univ2/lib/IV2LiquidityRouter02.sol";
import "./features/gamma/lib/IGammaUniProxy.sol";
import "./features/gamma/lib/IGammaHypervisor.sol";
import "../../libraries/Constants.sol";
import "../../utils/TransferHelper.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

contract ZapLiquidity is TransferHelper {
    using SafeERC20 for IERC20;

    struct AddLiquidityV2Params {
        address lpRouter;
        address token0;
        address token1;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    struct RemoveLiquidityV2Params {
        IV2LiquidityRouter02 router;
        IApePair lp;
        uint256 amount;
        uint256 amountAMinRemove;
        uint256 amountBMinRemove;
        address recipient;
        uint256 deadline;
    }

    struct AddLiquidityV3Params {
        address lpRouter;
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    struct AddLiquidityArrakisParams {
        address lpRouter;
        address token0;
        address token1;
        uint24 fee;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
        address arrakisFactory;
    }

    struct AddLiquidityGammaParams {
        address hypervisor;
        address token0;
        address token1;
        uint256 amount0Desired;
        uint256 amount1Desired;
        address recipient;
        uint256[4] inMin;
    }

    struct RemoveLiquidityGammaParams {
        address hypervisor;
        uint256 shares;
        address recipient;
        uint256[4] minAmounts;
    }

    event AddLiquidityV2(AddLiquidityV2Params params);
    event RemoveLiquidityV2(RemoveLiquidityV2Params params);
    event AddLiquidityV3(AddLiquidityV3Params params);
    event AddLiquidityArrakis(AddLiquidityArrakisParams params);
    event AddLiquidityGamma(AddLiquidityGammaParams params);
    event RemoveLiquidityGamma(RemoveLiquidityGammaParams params);

    function addLiquidityV2(
        AddLiquidityV2Params memory params
    ) external payable returns (uint256 amount0Lp, uint256 amount1Lp) {
        params.amount0Desired = _transferIn(IERC20(params.token0), params.amount0Desired);
        params.amount1Desired = _transferIn(IERC20(params.token1), params.amount1Desired);

        IERC20(params.token0).approve(address(params.lpRouter), params.amount0Desired);
        IERC20(params.token1).approve(address(params.lpRouter), params.amount1Desired);

        if (params.recipient == Constants.MSG_SENDER) params.recipient = msg.sender;
        else if (params.recipient == Constants.ADDRESS_THIS) params.recipient = address(this);

        (amount0Lp, amount1Lp, ) = IV2LiquidityRouter02(params.lpRouter).addLiquidity(
            params.token0,
            params.token1,
            params.amount0Desired,
            params.amount1Desired,
            params.amount0Min,
            params.amount1Min,
            params.recipient,
            params.deadline
        );

        _transferOut(IERC20(params.token0), Constants.CONTRACT_BALANCE, msg.sender);
        _transferOut(IERC20(params.token1), Constants.CONTRACT_BALANCE, msg.sender);
        emit AddLiquidityV2(params);
    }

    function removeLiquidityV2(
        RemoveLiquidityV2Params memory params
    ) public payable returns (uint256 amountAReceived, uint256 amountBReceived) {
        if (params.recipient == Constants.MSG_SENDER) params.recipient = msg.sender;
        else if (params.recipient == Constants.ADDRESS_THIS) params.recipient = address(this);

        address token0 = params.lp.token0();
        address token1 = params.lp.token1();

        params.amount = _transferIn(IERC20(address(params.lp)), params.amount);
        params.lp.approve(address(params.router), params.amount);
        (amountAReceived, amountBReceived) = params.router.removeLiquidity(
            token0,
            token1,
            params.amount,
            params.amountAMinRemove,
            params.amountBMinRemove,
            params.recipient,
            params.deadline
        );
        emit RemoveLiquidityV2(params);
    }

    function addLiquidityV3(
        AddLiquidityV3Params memory params
    ) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) {
        require(params.token0 < params.token1, "ZapLiquidity: token0 must be strictly less than token1 by sort order");

        params.amount0Desired = _transferIn(IERC20(params.token0), params.amount0Desired);
        params.amount1Desired = _transferIn(IERC20(params.token1), params.amount1Desired);

        IERC20(params.token0).approve(params.lpRouter, params.amount0Desired);
        IERC20(params.token1).approve(params.lpRouter, params.amount1Desired);

        if (params.recipient == Constants.MSG_SENDER) params.recipient = msg.sender;
        else if (params.recipient == Constants.ADDRESS_THIS) params.recipient = address(this);

        (tokenId, liquidity, amount0, amount1) = INonfungiblePositionManager(params.lpRouter).mint(
            INonfungiblePositionManager.MintParams({
                token0: params.token0,
                token1: params.token1,
                fee: params.fee,
                tickLower: params.tickLower,
                tickUpper: params.tickUpper,
                amount0Desired: params.amount0Desired,
                amount1Desired: params.amount1Desired,
                amount0Min: params.amount0Min,
                amount1Min: params.amount1Min,
                recipient: params.recipient,
                deadline: params.deadline
            })
        );

        _transferOut(IERC20(params.token0), Constants.CONTRACT_BALANCE, msg.sender);
        _transferOut(IERC20(params.token1), Constants.CONTRACT_BALANCE, msg.sender);
        emit AddLiquidityV3(params);
    }

    function addLiquidityArrakis(
        AddLiquidityArrakisParams memory params
    ) external payable returns (uint256 amount0Lp, uint256 amount1Lp) {
        params.amount0Desired = _transferIn(IERC20(params.token0), params.amount0Desired);
        params.amount1Desired = _transferIn(IERC20(params.token1), params.amount1Desired);

        IERC20(params.token0).approve(address(params.lpRouter), params.amount0Desired);
        IERC20(params.token1).approve(address(params.lpRouter), params.amount1Desired);

        if (params.recipient == Constants.MSG_SENDER) params.recipient = msg.sender;
        else if (params.recipient == Constants.ADDRESS_THIS) params.recipient = address(this);

        address uniV3Pool = IUniswapV3Factory(IArrakisRouter(params.lpRouter).factory()).getPool(
            params.token0,
            params.token1,
            params.fee
        );
        address arrakisPool = ArrakisHelper.getArrakisPool(uniV3Pool, IArrakisFactoryV1(params.arrakisFactory));

        (amount0Lp, amount1Lp, ) = IArrakisRouter(params.lpRouter).addLiquidity(
            IArrakisPool(arrakisPool),
            params.amount0Desired,
            params.amount1Desired,
            params.amount0Min,
            params.amount1Min,
            params.recipient
        );

        _transferOut(IERC20(params.token0), Constants.CONTRACT_BALANCE, msg.sender);
        _transferOut(IERC20(params.token1), Constants.CONTRACT_BALANCE, msg.sender);
        emit AddLiquidityArrakis(params);
    }

    function addLiquidityGamma(AddLiquidityGammaParams memory params) external payable returns (uint256 shares) {
        params.amount0Desired = _transferIn(IERC20(params.token0), params.amount0Desired);
        params.amount1Desired = _transferIn(IERC20(params.token1), params.amount1Desired);

        IERC20(params.token0).approve(address(params.hypervisor), params.amount0Desired);
        IERC20(params.token1).approve(address(params.hypervisor), params.amount1Desired);

        if (params.recipient == Constants.MSG_SENDER) params.recipient = msg.sender;
        else if (params.recipient == Constants.ADDRESS_THIS) params.recipient = address(this);

        shares = UniProxy(Hypervisor(params.hypervisor).whitelistedAddress()).deposit(
            params.amount0Desired,
            params.amount1Desired,
            params.recipient,
            params.hypervisor,
            params.inMin
        );

        _transferOut(IERC20(params.hypervisor), Constants.CONTRACT_BALANCE, params.recipient);
        _transferOut(IERC20(params.token0), Constants.CONTRACT_BALANCE, msg.sender);
        _transferOut(IERC20(params.token1), Constants.CONTRACT_BALANCE, msg.sender);
        emit AddLiquidityGamma(params);
    }

    function removeLiquidityGamma(
        RemoveLiquidityGammaParams memory params
    ) external payable returns (uint256 amount0, uint256 amount1) {
        if (params.recipient == Constants.MSG_SENDER) params.recipient = msg.sender;
        else if (params.recipient == Constants.ADDRESS_THIS) params.recipient = address(this);

        (amount0, amount1) = Hypervisor(params.hypervisor).withdraw(
            params.shares,
            params.recipient,
            msg.sender,
            params.minAmounts
        );

        emit RemoveLiquidityGamma(params);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./libraries/IBEP20RewardApeV5.sol";
import "./libraries/ITreasury.sol";
import "../../libraries/Constants.sol";
import "../../utils/TransferHelper.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract ApeSwapZapPools is TransferHelper {
    using SafeERC20 for IERC20;

    struct ZapPoolParams {
        uint256 inputAmount;
        IBEP20RewardApeV5 pool;
        address recipient;
    }

    IERC20 public immutable BANANA;
    IERC20 public immutable GNANA;
    ITreasury public immutable GNANA_TREASURY; // Golden Banana Treasury

    event ZapPool(ZapPoolParams params);

    constructor(ITreasury goldenBananaTreasury) {
        ITreasury gnanaTreasury;
        IERC20 banana;
        IERC20 gnana;
        if (block.chainid == 56) {
            /// @dev The Golden Banana Treasury only exists on BNB Chain
            require(address(goldenBananaTreasury) != address(0), "Must provide Golden BANANA Treasury for BNB Chain");
        }

        if (address(goldenBananaTreasury) != address(0)) {
            gnanaTreasury = goldenBananaTreasury;
            banana = gnanaTreasury.banana();
            gnana = gnanaTreasury.goldenBanana();
        } else {
            gnanaTreasury = ITreasury(address(0));
            banana = IERC20(address(0));
            gnana = IERC20(address(0));
        }
        /// @dev Can't access immutable variables in constructor
        /// @dev Can't initialize immutable variables in if statement.
        GNANA_TREASURY = gnanaTreasury;
        BANANA = banana;
        GNANA = gnana;
    }

    function zapPool(ZapPoolParams memory params) external payable {
        IERC20 inputToken = params.pool.STAKE_TOKEN();
        params.inputAmount = _transferIn(inputToken, params.inputAmount);

        if (params.recipient == Constants.MSG_SENDER) params.recipient = msg.sender;
        else if (params.recipient == Constants.ADDRESS_THIS) params.recipient = address(this);

        if (inputToken == GNANA) {
            IERC20(BANANA).approve(address(GNANA_TREASURY), params.inputAmount);
            uint256 beforeAmount = inputToken.balanceOf(address(this));
            GNANA_TREASURY.buy(params.inputAmount);
            params.inputAmount = inputToken.balanceOf(address(this)) - beforeAmount;
        }

        inputToken.approve(address(params.pool), params.inputAmount);
        params.pool.depositTo(params.inputAmount, params.recipient);
        inputToken.approve(address(params.pool), 0);
        emit ZapPool(params);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBEP20RewardApeV5 {
    function REWARD_TOKEN() external view returns (IERC20);

    function STAKE_TOKEN() external view returns (IERC20);

    function bonusEndBlock() external view returns (uint256);

    function owner() external view returns (address);

    function poolInfo()
        external
        view
        returns (address lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accRewardTokenPerShare);

    function renounceOwnership() external;

    function rewardPerBlock() external view returns (uint256);

    function startBlock() external view returns (uint256);

    function totalRewardsAllocated() external view returns (uint256);

    function totalRewardsPaid() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function userInfo(address) external view returns (uint256 amount, uint256 rewardDebt);

    function initialize(
        address _stakeToken,
        address _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) external;

    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);

    function setBonusEndBlock(uint256 _bonusEndBlock) external;

    function pendingReward(address _user) external view returns (uint256);

    function updatePool() external;

    function deposit(uint256 _amount) external;

    function depositTo(uint256 _amount, address _user) external;

    function withdraw(uint256 _amount) external;

    function rewardBalance() external view returns (uint256);

    function getUnharvestedRewards() external view returns (uint256);

    function depositRewards(uint256 _amount) external;

    function totalStakeTokenBalance() external view returns (uint256);

    function getStakeTokenFeeBalance() external view returns (uint256);

    function setRewardPerBlock(uint256 _rewardPerBlock) external;

    function skimStakeTokenFees(address _to) external;

    function emergencyWithdraw() external;

    function emergencyRewardWithdraw(uint256 _amount) external;

    function sweepToken(address token) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITreasury {
    function adminAddress() external view returns (address);

    function banana() external view returns (IERC20);

    function bananaReserves() external view returns (uint256);

    function buy(uint256 _amount) external;

    function buyFee() external view returns (uint256);

    function emergencyWithdraw(uint256 _amount) external;

    function goldenBanana() external view returns (IERC20);

    function goldenBananaReserves() external view returns (uint256);

    function maxBuyFee() external view returns (uint256);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function sell(uint256 _amount) external;

    function setAdmin(address _adminAddress) external;

    function setBuyFee(uint256 _fee) external;

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

/*
  ______                     ______                                 
 /      \                   /      \                                
|  ▓▓▓▓▓▓\ ______   ______ |  ▓▓▓▓▓▓\__   __   __  ______   ______  
| ▓▓__| ▓▓/      \ /      \| ▓▓___\▓▓  \ |  \ |  \|      \ /      \ 
| ▓▓    ▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\\▓▓    \| ▓▓ | ▓▓ | ▓▓ \▓▓▓▓▓▓\  ▓▓▓▓▓▓\
| ▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓    ▓▓_\▓▓▓▓▓▓\ ▓▓ | ▓▓ | ▓▓/      ▓▓ ▓▓  | ▓▓
| ▓▓  | ▓▓ ▓▓__/ ▓▓ ▓▓▓▓▓▓▓▓  \__| ▓▓ ▓▓_/ ▓▓_/ ▓▓  ▓▓▓▓▓▓▓ ▓▓__/ ▓▓
| ▓▓  | ▓▓ ▓▓    ▓▓\▓▓     \\▓▓    ▓▓\▓▓   ▓▓   ▓▓\▓▓    ▓▓ ▓▓    ▓▓
 \▓▓   \▓▓ ▓▓▓▓▓▓▓  \▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓\▓▓▓▓  \▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓ 
         | ▓▓                                             | ▓▓      
         | ▓▓                                             | ▓▓      
          \▓▓                                              \▓▓         
 * App:             https://ApeSwap.finance
 * Medium:          https://ape-swap.medium.com
 * Twitter:         https://twitter.com/ape_swap
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * Discord:         https://ApeSwap.click/discord
 * Reddit:          https://reddit.com/r/ApeSwap
 * Instagram:       https://instagram.com/ApeSwap.finance
 * GitHub:          https://github.com/ApeSwapFinance
 */

import "../../../../utils/TokenHelper.sol";
import "./lib/IAlgebraFactory.sol";
import "./lib/IAlgebraPool.sol";

library AlgebraSwapHelper {
    /// @notice Returns value based on other token
    /// @param token0 initial token
    /// @param token1 end token that needs value based of token0
    /// @param uniV3Factory uniV3 factory
    /// @return price value of token1 based of token0
    function pairTokensAndValue(
        address token0,
        address token1,
        address uniV3Factory
    ) internal view returns (uint256 price) {
        address tokenPegPair = IAlgebraFactory(uniV3Factory).poolByPair(token0, token1);

        // if the address has no contract deployed, the pair doesn't exist
        uint256 size;
        assembly {
            size := extcodesize(tokenPegPair)
        }
        require(size != 0, "UniV3 pair not found");

        uint256 sqrtPriceX96;

        (sqrtPriceX96, , , , , , ) = IAlgebraPool(tokenPegPair).globalState();

        uint256 token0Decimals = TokenHelper.getTokenDecimals(token0);
        uint256 token1Decimals = TokenHelper.getTokenDecimals(token1);

        if (token1 < token0) {
            price = (2**192) / ((sqrtPriceX96)**2 / uint256(10**(token0Decimals + 18 - token1Decimals)));
        } else {
            price = ((sqrtPriceX96)**2) / ((2**192) / uint256(10**(token0Decimals + 18 - token1Decimals)));
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma abicoder v2;

/// @title The interface for the Algebra Factory
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraFactory {
    /// @notice Emitted when a process of ownership renounce is started
    /// @param timestamp The timestamp of event
    /// @param finishTimestamp The timestamp when ownership renounce will be possible to finish
    event RenounceOwnershipStart(uint256 timestamp, uint256 finishTimestamp);

    /// @notice Emitted when a process of ownership renounce cancelled
    /// @param timestamp The timestamp of event
    event RenounceOwnershipStop(uint256 timestamp);

    /// @notice Emitted when a process of ownership renounce finished
    /// @param timestamp The timestamp of ownership renouncement
    event RenounceOwnershipFinish(uint256 timestamp);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param pool The address of the created pool
    event Pool(address indexed token0, address indexed token1, address pool);

    /// @notice Emitted when the farming address is changed
    /// @param newFarmingAddress The farming address after the address was changed
    event FarmingAddress(address indexed newFarmingAddress);

    /// @notice Emitted when the default community fee is changed
    /// @param newDefaultCommunityFee The new default community fee value
    event DefaultCommunityFee(uint8 newDefaultCommunityFee);

    /// @notice role that can change communityFee and tickspacing in pools
    function POOLS_ADMINISTRATOR_ROLE() external view returns (bytes32);

    /// @dev Returns `true` if `account` has been granted `role` or `account` is owner.
    function hasRoleOrOwner(bytes32 role, address account) external view returns (bool);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via transferOwnership(address newOwner)
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the current poolDeployerAddress
    /// @return The address of the poolDeployer
    function poolDeployer() external view returns (address);

    /// @dev Is retrieved from the pools to restrict calling certain functions not by a tokenomics contract
    /// @return The tokenomics contract address
    function farmingAddress() external view returns (address);

    /// @notice Returns the current communityVaultAddress
    /// @return The address to which community fees are transferred
    function communityVault() external view returns (address);

    /// @notice Returns the default community fee
    /// @return Fee which will be set at the creation of the pool
    function defaultCommunityFee() external view returns (uint8);

    /// @notice Returns the pool address for a given pair of tokens, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @return pool The pool address
    function poolByPair(address tokenA, address tokenB) external view returns (address pool);

    /// @return timestamp The timestamp of the beginning of the renounceOwnership process
    function renounceOwnershipStartTimestamp() external view returns (uint256 timestamp);

    /// @notice Creates a pool for the given two tokens
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0.
    /// The call will revert if the pool already exists or the token arguments are invalid.
    /// @return pool The address of the newly created pool
    function createPool(address tokenA, address tokenB) external returns (address pool);

    /// @dev updates tokenomics address on the factory
    /// @param newFarmingAddress The new tokenomics contract address
    function setFarmingAddress(address newFarmingAddress) external;

    /// @dev updates default community fee for new pools
    /// @param newDefaultCommunityFee The new community fee, _must_ be <= MAX_COMMUNITY_FEE
    function setDefaultCommunityFee(uint8 newDefaultCommunityFee) external;

    /// @notice Starts process of renounceOwnership. After that, a certain period
    /// of time must pass before the ownership renounce can be completed.
    function startRenounceOwnership() external;

    /// @notice Stops process of renounceOwnership and removes timer.
    function stopRenounceOwnership() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPool {
    /// @notice The globalState structure in the pool stores many values but requires only one slot
    /// and is exposed as a single method to save gas when accessed externally.
    /// @return price The current price of the pool as a sqrt(dToken1/dToken0) Q64.96 value;
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run;
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(price) if the price is on a tick boundary;
    /// @return prevInitializedTick The previous initialized tick
    /// @return fee The last pool fee value in hundredths of a bip, i.e. 1e-6
    /// @return timepointIndex The index of the last written timepoint
    /// @return communityFee The community fee percentage of the swap fee in thousandths (1e-3)
    /// @return unlocked Whether the pool is currently locked to reentrancy
    function globalState()
        external
        view
        returns (
            uint160 price,
            int24 tick,
            int24 prevInitializedTick,
            uint16 fee,
            uint16 timepointIndex,
            uint8 communityFee,
            bool unlocked
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Algebra
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
interface IAlgebraSwapRouter {
    struct ExactInputSingleParamsAlgebra {
        address factory;
        address tokenIn;
        address tokenOut;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 limitSqrtPrice;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParamsAlgebra` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingleAlgebra(ExactInputSingleParamsAlgebra calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactInputParamsAlgebra {
        address factory;
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParamsAlgebra` in calldata
    /// @return amountOut The amount of the received token
    function exactInputAlgebra(ExactInputParamsAlgebra calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParamsAlgebra {
        address factory;
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 limitSqrtPrice;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParamsAlgebra` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingleAlgebra(ExactOutputSingleParamsAlgebra calldata params)
        external
        payable
        returns (uint256 amountIn);

    struct ExactOutputParamsAlgebra {
        address factory;
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParamsAlgebra` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputAlgebra(ExactOutputParamsAlgebra calldata params) external payable returns (uint256 amountIn);

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Unlike standard swaps, handles transferring from user before the actual swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParamsAlgebra` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingleSupportingFeeOnTransferTokensAlgebra(ExactInputSingleParamsAlgebra calldata params)
        external
        returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../../univ2/lib/IV2SwapRouter.sol";
import "../../univ3/lib/IV3SwapRouter.sol";
import "../../algebra/lib/IAlgebraSwapRouter.sol";

/// @title Uniswap V2 and V3 Swap Router
interface IApeSwapMultiSwapRouter is IV2SwapRouter, IV3SwapRouter, IAlgebraSwapRouter {
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);

    function wrapETH(uint256 value) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./IV2SwapRouter02.sol";

/// @title Router token swapping functionality interface
/// @notice Functions for swapping tokens via Uniswap V2
interface IV2SwapRouter {
    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param amountIn The amount of token to swap
    /// @param amountOutMin The minimum amount of output that must be received
    /// @param path The ordered list of tokens to swap through
    /// @param to The recipient address
    /// @return amountOut The amount of the received token
    function swapExactTokensForTokens(
        IV2SwapRouter02 router,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amountOut);

    /// @notice Swaps as little as possible of one token for an exact amount of another token
    /// @param amountOut The amount of token to swap for
    /// @param amountInMax The maximum amount of input that the caller will pay
    /// @param path The ordered list of tokens to swap through
    /// @param to The recipient address
    /// @return amountIn The amount of token to pay
    function swapTokensForExactTokens(
        IV2SwapRouter02 router,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amountIn);

    function addLiquidity(
        IV2SwapRouter02 router,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IV2SwapRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./IV2SwapRouter01.sol";

interface IV2SwapRouter02 is IV2SwapRouter01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IV3SwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address factory;
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        address factory;
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address factory;
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        address factory;
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

/*
  ______                     ______                                 
 /      \                   /      \                                
|  ▓▓▓▓▓▓\ ______   ______ |  ▓▓▓▓▓▓\__   __   __  ______   ______  
| ▓▓__| ▓▓/      \ /      \| ▓▓___\▓▓  \ |  \ |  \|      \ /      \ 
| ▓▓    ▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\\▓▓    \| ▓▓ | ▓▓ | ▓▓ \▓▓▓▓▓▓\  ▓▓▓▓▓▓\
| ▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓    ▓▓_\▓▓▓▓▓▓\ ▓▓ | ▓▓ | ▓▓/      ▓▓ ▓▓  | ▓▓
| ▓▓  | ▓▓ ▓▓__/ ▓▓ ▓▓▓▓▓▓▓▓  \__| ▓▓ ▓▓_/ ▓▓_/ ▓▓  ▓▓▓▓▓▓▓ ▓▓__/ ▓▓
| ▓▓  | ▓▓ ▓▓    ▓▓\▓▓     \\▓▓    ▓▓\▓▓   ▓▓   ▓▓\▓▓    ▓▓ ▓▓    ▓▓
 \▓▓   \▓▓ ▓▓▓▓▓▓▓  \▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓\▓▓▓▓  \▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓ 
         | ▓▓                                             | ▓▓      
         | ▓▓                                             | ▓▓      
          \▓▓                                              \▓▓         
 * App:             https://ApeSwap.finance
 * Medium:          https://ape-swap.medium.com
 * Twitter:         https://twitter.com/ape_swap
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * Discord:         https://ApeSwap.click/discord
 * Reddit:          https://reddit.com/r/ApeSwap
 * Instagram:       https://instagram.com/ApeSwap.finance
 * GitHub:          https://github.com/ApeSwapFinance
 */

import "../../../../utils/TokenHelper.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

library UniV3SwapHelper {
    /// @notice Returns value based on other token
    /// @param token0 initial token
    /// @param token1 end token that needs value based of token0
    /// @param fee uniV3 pool fee
    /// @param uniV3Factory uniV3 factory
    /// @return price value of token1 based of token0
    function pairTokensAndValue(
        address token0,
        address token1,
        uint24 fee,
        address uniV3Factory
    ) internal view returns (uint256 price) {
        address tokenPegPair = IUniswapV3Factory(uniV3Factory).getPool(token0, token1, fee);

        // if the address has no contract deployed, the pair doesn't exist
        uint256 size;
        assembly {
            size := extcodesize(tokenPegPair)
        }
        require(size != 0, "UniV3 pair not found");

        uint256 sqrtPriceX96;

        (sqrtPriceX96, , , , , , ) = IUniswapV3Pool(tokenPegPair).slot0();

        uint256 token0Decimals = TokenHelper.getTokenDecimals(token0);
        uint256 token1Decimals = TokenHelper.getTokenDecimals(token1);

        if (token1 < token0) {
            price = (2**192) / ((sqrtPriceX96)**2 / uint256(10**(token0Decimals + 18 - token1Decimals)));
        } else {
            price = ((sqrtPriceX96)**2) / ((2**192) / uint256(10**(token0Decimals + 18 - token1Decimals)));
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

/*
  ______                     ______                                 
 /      \                   /      \                                
|  ▓▓▓▓▓▓\ ______   ______ |  ▓▓▓▓▓▓\__   __   __  ______   ______  
| ▓▓__| ▓▓/      \ /      \| ▓▓___\▓▓  \ |  \ |  \|      \ /      \ 
| ▓▓    ▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\\▓▓    \| ▓▓ | ▓▓ | ▓▓ \▓▓▓▓▓▓\  ▓▓▓▓▓▓\
| ▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓    ▓▓_\▓▓▓▓▓▓\ ▓▓ | ▓▓ | ▓▓/      ▓▓ ▓▓  | ▓▓
| ▓▓  | ▓▓ ▓▓__/ ▓▓ ▓▓▓▓▓▓▓▓  \__| ▓▓ ▓▓_/ ▓▓_/ ▓▓  ▓▓▓▓▓▓▓ ▓▓__/ ▓▓
| ▓▓  | ▓▓ ▓▓    ▓▓\▓▓     \\▓▓    ▓▓\▓▓   ▓▓   ▓▓\▓▓    ▓▓ ▓▓    ▓▓
 \▓▓   \▓▓ ▓▓▓▓▓▓▓  \▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓\▓▓▓▓  \▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓ 
         | ▓▓                                             | ▓▓      
         | ▓▓                                             | ▓▓      
          \▓▓                                              \▓▓         
 * App:             https://ApeSwap.finance
 * Medium:          https://ape-swap.medium.com
 * Twitter:         https://twitter.com/ape_swap
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * Discord:         https://ApeSwap.click/discord
 * Reddit:          https://reddit.com/r/ApeSwap
 * Instagram:       https://instagram.com/ApeSwap.finance
 * GitHub:          https://github.com/ApeSwapFinance
 */

import "./features/apeswap-ms-router/lib/IApeSwapMultiSwapRouter.sol";
import "../../libraries/Constants.sol";
import "../../utils/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ZapSwap is TransferHelper, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum SwapType2 {
        MultiSwapRouter
    }

    struct SwapParams {
        IERC20 inputToken;
        uint256 inputAmount;
        SwapType2 swapType;
        address caller;
        bytes[] swapData;
        address to;
        uint256 deadline;
    }

    event Swap(SwapParams params);

    /// @notice Zap single token to LP
    /// @param params all parameters for zap
    function swap(SwapParams memory params) external payable nonReentrant {
        require(params.to != address(0), "ZapSwap: Can't zap to null address");
        require(params.caller != address(0), "ZapSwap: caller can't be null address");

        params.inputAmount = _transferIn(params.inputToken, params.inputAmount);
        params.inputToken.approve(params.caller, params.inputAmount);

        if (params.swapType == SwapType2.MultiSwapRouter) {
            IApeSwapMultiSwapRouter(params.caller).multicall(params.swapData);
        } else {
            revert("ZapSwap: Swap type not supported");
        }
        emit Swap(params);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./libraries/IMaximizerVaultApe.sol";
import "./libraries/IBaseBananaMaximizerStrategy.sol";
import "../../libraries/Constants.sol";
import "../../utils/TransferHelper.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract ApeSwapZapVaults is TransferHelper {
    using SafeERC20 for IERC20;

    struct zapVaultParams {
        uint256 inputAmount;
        IMaximizerVaultApe maximizerVaultApe;
        uint256 vaultPid;
        address recipient;
    }

    event ZapVault(IERC20 inputToken, uint256 inputAmount, uint256 vaultPid);

    function zapVault(zapVaultParams memory params) external payable {
        IBaseBananaMaximizerStrategy vault = IBaseBananaMaximizerStrategy(
            params.maximizerVaultApe.vaults(params.vaultPid)
        );
        IERC20 inputToken = IERC20(vault.STAKE_TOKEN_ADDRESS());
        params.inputAmount = _transferIn(inputToken, params.inputAmount);

        if (params.recipient == Constants.MSG_SENDER) params.recipient = msg.sender;
        else if (params.recipient == Constants.ADDRESS_THIS) params.recipient = address(this);

        inputToken.approve(address(params.maximizerVaultApe), params.inputAmount);
        params.maximizerVaultApe.depositTo(params.vaultPid, params.recipient, params.inputAmount);
        inputToken.approve(address(params.maximizerVaultApe), 0);
        emit ZapVault(inputToken, params.inputAmount, params.vaultPid);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBaseBananaMaximizerStrategy {
    function STAKE_TOKEN_ADDRESS() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IMaximizerVaultApe {
    function KEEPER_FEE_UL() external view returns (uint256);

    function PLATFORM_FEE_UL() external view returns (uint256);

    function BUYBACK_RATE_UL() external view returns (uint256);

    function WITHDRAW_FEE_UL() external view returns (uint256);

    function WITHDRAW_REWARDS_FEE_UL() external view returns (uint256);

    function WITHDRAW_FEE_PERIOD_UL() external view returns (uint256);

    struct Settings {
        address treasury;
        uint256 keeperFee;
        address platform;
        uint256 platformFee;
        uint256 buyBackRate;
        uint256 withdrawFee;
        uint256 withdrawFeePeriod;
        uint256 withdrawRewardsFee;
    }

    function getSettings() external view returns (Settings memory);

    function userInfo(
        uint256 _pid,
        address _user
    ) external view returns (uint256 stake, uint256 autoBananaShares, uint256 rewardDebt, uint256 lastDepositedTime);

    function vaults(uint256 _pid) external view returns (address);

    function vaultsLength() external view returns (uint256);

    function addVault(address _strat) external;

    function stakedWantTokens(uint256 _pid, address _user) external view returns (uint256);

    function depositTo(uint256 _pid, address _to, uint256 _wantAmt) external;

    function deposit(uint256 _pid, uint256 _wantAmt) external;

    function withdraw(uint256 _pid, uint256 _wantAmt) external;

    function withdrawAll(uint256 _pid) external;

    function earnAll() external;

    function earnSome(uint256[] memory pids) external;

    function harvest(uint256 _pid, uint256 _wantAmt) external;

    function harvestAll(uint256 _pid) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;
pragma abicoder v2;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function balanceOf(address) external returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IZapAnalyzer {
    enum SwapType {
        V2,
        V3,
        ALGEBRA
    }

    struct SwapPath {
        address swapRouter;
        SwapType swapType;
        address[] path;
        uint24[] uniV3PoolFees; // Required if dexType == V3
    }

    enum LiquidityType {
        V2,
        V3,
        Arrakis,
        Gamma
    }

    struct LiquidityPath {
        address lpRouter;
        LiquidityType liquidityType;
        uint24 uniV3PoolLPFee;
        int24 tickLower;
        int24 tickUpper;
        address arrakisFactory; // Required if lpType == Arrakis
    }

    struct SwapReturnsParams {
        uint256 inputAmount;
        SwapPath[] swapPath0;
        SwapPath[] swapPath1;
        LiquidityPath liquidityPath;
    }

    struct SwapReturns {
        uint256 swapToToken0;
        uint256 swapToToken1;
        uint256 minAmountSwap0;
        uint256 minAmountSwap1;
    }

    /// @notice get min amounts for swaps
    /// @param params all params
    function estimateSwapReturns(
        SwapReturnsParams memory params
    ) external view returns (SwapReturns memory returnValues);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

/*
  ______                     ______                                 
 /      \                   /      \                                
|  ▓▓▓▓▓▓\ ______   ______ |  ▓▓▓▓▓▓\__   __   __  ______   ______  
| ▓▓__| ▓▓/      \ /      \| ▓▓___\▓▓  \ |  \ |  \|      \ /      \ 
| ▓▓    ▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\\▓▓    \| ▓▓ | ▓▓ | ▓▓ \▓▓▓▓▓▓\  ▓▓▓▓▓▓\
| ▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓    ▓▓_\▓▓▓▓▓▓\ ▓▓ | ▓▓ | ▓▓/      ▓▓ ▓▓  | ▓▓
| ▓▓  | ▓▓ ▓▓__/ ▓▓ ▓▓▓▓▓▓▓▓  \__| ▓▓ ▓▓_/ ▓▓_/ ▓▓  ▓▓▓▓▓▓▓ ▓▓__/ ▓▓
| ▓▓  | ▓▓ ▓▓    ▓▓\▓▓     \\▓▓    ▓▓\▓▓   ▓▓   ▓▓\▓▓    ▓▓ ▓▓    ▓▓
 \▓▓   \▓▓ ▓▓▓▓▓▓▓  \▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓\▓▓▓▓  \▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓ 
         | ▓▓                                             | ▓▓      
         | ▓▓                                             | ▓▓      
          \▓▓                                              \▓▓         
 * App:             https://ApeSwap.finance
 * Medium:          https://ape-swap.medium.com
 * Twitter:         https://twitter.com/ape_swap
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * Discord:         https://ApeSwap.click/discord
 * Reddit:          https://reddit.com/r/ApeSwap
 * Instagram:       https://instagram.com/ApeSwap.finance
 * GitHub:          https://github.com/ApeSwapFinance
 */

import "./IZapAnalyzer.sol";
import "../extensions/liquidity/features/univ2/lib/IApeFactory.sol";
import "../extensions/liquidity/features/univ3/UniV3LiquidityHelper.sol";
import "../extensions/liquidity/features/arrakis/lib/IArrakisRouter.sol";
import "../extensions/liquidity/features/arrakis/lib/IArrakisFactoryV1.sol";
import "../extensions/liquidity/features/arrakis/ArrakisHelper.sol";
import "../extensions/liquidity/features/gamma/lib/IGammaHypervisor.sol";
import "../extensions/liquidity/features/gamma/lib/IGammaUniProxy.sol";
import "../extensions/swap/features/algebra/lib/IAlgebraFactory.sol";
import "../extensions/swap/features/algebra/lib/IAlgebraPool.sol";
import "../extensions/swap/features/algebra/AlgebraSwapHelper.sol";
import "../extensions/swap/features/univ2/lib/IV2SwapRouter02.sol";
import "../extensions/swap/features/univ3/UniV3SwapHelper.sol";
import "../utils/TokenHelper.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract ZapAnalyzer is IZapAnalyzer {
    struct minAmountsLocalVars {
        address token0;
        address token1;
        address inputToken;
        address uniV3Pool;
        address arrakisPool;
        uint256 weightedPrice0;
        uint256 weightedPrice1;
    }

    /**
     * @dev This function estimates the swap returns based on the given parameters.
     * @param params The struct containing the necessary parameters for estimating swap returns.
     *  See {SwapReturnsParams} for more information.
     * @return returnValues The struct containing the estimated swap returns.
     *  See {SwapReturns} for more information.
     */
    function estimateSwapReturns(SwapReturnsParams memory params)
        external
        view
        override
        returns (SwapReturns memory returnValues)
    {
        minAmountsLocalVars memory vars;

        vars.token0 = params.swapPath0.length == 0
            ? params.swapPath1[0].path[0]
            : params.swapPath0[params.swapPath0.length - 1].path[
                params.swapPath0[params.swapPath0.length - 1].path.length - 1
            ];
        vars.token1 = params.swapPath1.length == 0
            ? params.swapPath0[0].path[0]
            : params.swapPath1[params.swapPath1.length - 1].path[
                params.swapPath1[params.swapPath1.length - 1].path.length - 1
            ];
        vars.inputToken = params.swapPath0.length > 0 ? params.swapPath0[0].path[0] : params.swapPath1[0].path[0];

        if (params.liquidityPath.liquidityType == LiquidityType.V2) {
            //V2 swap amounts
            returnValues.swapToToken0 = params.inputAmount / 2;
            returnValues.swapToToken1 = params.inputAmount / 2;
        } else if (params.liquidityPath.liquidityType == LiquidityType.V3) {
            //V3 swap amounts
            SwapRatioParams memory swapRatioParams = SwapRatioParams({
                inputToken: vars.inputToken,
                inputAmount: params.inputAmount,
                token0: vars.token0,
                token1: vars.token1,
                swapPath0: params.swapPath0,
                swapPath1: params.swapPath1,
                fee: params.liquidityPath.uniV3PoolLPFee,
                tickLower: params.liquidityPath.tickLower,
                tickUpper: params.liquidityPath.tickUpper,
                uniV3Factory: params.liquidityPath.lpRouter,
                gammaHypervisor: address(0)
            });
            (returnValues.swapToToken0, returnValues.swapToToken1) = getSwapRatio(swapRatioParams);
        } else if (params.liquidityPath.liquidityType == LiquidityType.Arrakis) {
            //Arrakis swap amounts
            vars.uniV3Pool = IUniswapV3Factory(IArrakisRouter(params.liquidityPath.lpRouter).factory()).getPool(
                vars.token0,
                vars.token1,
                params.liquidityPath.uniV3PoolLPFee
            );
            vars.arrakisPool = ArrakisHelper.getArrakisPool(
                vars.uniV3Pool,
                IArrakisFactoryV1(params.liquidityPath.arrakisFactory)
            );
            SwapRatioParams memory swapRatioParams = SwapRatioParams({
                inputToken: vars.inputToken,
                inputAmount: params.inputAmount,
                token0: vars.token0,
                token1: vars.token1,
                swapPath0: params.swapPath0,
                swapPath1: params.swapPath1,
                fee: params.liquidityPath.uniV3PoolLPFee,
                tickLower: IArrakisPool(vars.arrakisPool).lowerTick(),
                tickUpper: IArrakisPool(vars.arrakisPool).upperTick(),
                uniV3Factory: IArrakisRouter(params.liquidityPath.lpRouter).factory(),
                gammaHypervisor: address(0)
            });
            (returnValues.swapToToken0, returnValues.swapToToken1) = getSwapRatio(swapRatioParams);
        } else if (params.liquidityPath.liquidityType == LiquidityType.Gamma) {
            //Gamma swap amounts
            SwapRatioParams memory swapRatioParams = SwapRatioParams({
                inputToken: vars.inputToken,
                inputAmount: params.inputAmount,
                token0: vars.token0,
                token1: vars.token1,
                swapPath0: params.swapPath0,
                swapPath1: params.swapPath1,
                fee: 0,
                tickLower: 0,
                tickUpper: 0,
                uniV3Factory: address(0),
                gammaHypervisor: params.liquidityPath.lpRouter
            });
            (returnValues.swapToToken0, returnValues.swapToToken1) = getSwapRatio(swapRatioParams);
        }

        vars.weightedPrice0 = vars.inputToken == vars.token0 ? 1e18 : getWeightedPrice(params.swapPath0);
        vars.weightedPrice1 = vars.inputToken == vars.token1 ? 1e18 : getWeightedPrice(params.swapPath1);
        returnValues.minAmountSwap0 = (returnValues.swapToToken0 * vars.weightedPrice0) / 1e18;
        returnValues.minAmountSwap1 = (returnValues.swapToToken1 * vars.weightedPrice1) / 1e18;

        return returnValues;
    }

    struct SwapRatioParams {
        address inputToken;
        uint256 inputAmount;
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        SwapPath[] swapPath0;
        SwapPath[] swapPath1;
        address uniV3Factory;
        address gammaHypervisor;
    }

    struct SwapRatioLocalVars {
        uint256 underlying0;
        uint256 underlying1;
        uint256 token0decimals;
        uint256 token1decimals;
        uint256 weightedPrice1;
        uint256 percentage0;
        uint256 percentage1;
    }

    /// @notice Get ratio of how much of input token to swap to underlying tokens for lp to match ratio in pool
    /// @param swapRatioParams swap ratio params
    function getSwapRatio(SwapRatioParams memory swapRatioParams)
        internal
        view
        returns (uint256 amount0, uint256 amount1)
    {
        SwapRatioLocalVars memory vars;

        (vars.underlying0, vars.underlying1) = getLPAddRatio(
            swapRatioParams.uniV3Factory,
            swapRatioParams.token0,
            swapRatioParams.token1,
            swapRatioParams.fee,
            swapRatioParams.tickLower,
            swapRatioParams.tickUpper,
            swapRatioParams.gammaHypervisor
        );

        vars.token0decimals = IERC20Metadata(address(swapRatioParams.token0)).decimals();
        vars.token1decimals = IERC20Metadata(address(swapRatioParams.token1)).decimals();
        vars.underlying0 = TokenHelper.normalizeTokenDecimals(vars.underlying0, vars.token0decimals);
        vars.underlying1 = TokenHelper.normalizeTokenDecimals(vars.underlying1, vars.token1decimals);

        vars.weightedPrice1 = swapRatioParams.inputToken == swapRatioParams.token1
            ? 1e18
            : getWeightedPrice(swapRatioParams.swapPath1);

        uint256 lpRatio = ((vars.underlying0 * 1e18) / vars.underlying1);
        amount0 =
            (lpRatio * swapRatioParams.inputAmount * vars.weightedPrice1) /
            (1e36 + lpRatio * vars.weightedPrice1);
        amount1 = swapRatioParams.inputAmount - amount0;

        if (swapRatioParams.token1 < swapRatioParams.token0) {
            (amount0, amount1) = (amount1, amount0);
        }
    }

    function getLPAddRatio(
        address uniV3Factory,
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        address gammaHypervisor
    ) internal view returns (uint256 amount0, uint256 amount1) {
        if (uniV3Factory != address(0)) {
            (amount0, amount1) = UniV3LiquidityHelper.getLPAddRatio(
                uniV3Factory,
                token0,
                token1,
                fee,
                tickLower,
                tickUpper
            );
        } else if (gammaHypervisor != address(0)) {
            (uint256 amountStart, uint256 amountEnd) = UniProxy(Hypervisor(gammaHypervisor).whitelistedAddress())
                .getDepositAmount(gammaHypervisor, token0, 1e18);
            amount0 = 1e18;
            amount1 = (amountStart + amountEnd) / 2;
        } else {
            revert("Liquidity address not set");
        }
    }

    /// @notice Returns value based on other token
    /// @param fullPath swap path
    /// @return weightedPrice value of last token of path based on first
    function getWeightedPrice(SwapPath[] memory fullPath) internal view returns (uint256 weightedPrice) {
        weightedPrice = 1e18;
        for (uint256 i = 0; i < fullPath.length; i++) {
            SwapPath memory path = fullPath[i];
            if (path.swapType == SwapType.V2) {
                uint256 tokenDecimals = TokenHelper.getTokenDecimals(path.path[path.path.length - 1]);

                uint256[] memory amountsOut0 = IV2SwapRouter02(path.swapRouter).getAmountsOut(1e18, path.path);
                weightedPrice =
                    (weightedPrice *
                        TokenHelper.normalizeTokenDecimals(amountsOut0[amountsOut0.length - 1], tokenDecimals)) /
                    1e18;
            } else if (path.swapType == SwapType.V3) {
                for (uint256 index = 0; index < path.path.length - 1; index++) {
                    weightedPrice =
                        (weightedPrice *
                            UniV3SwapHelper.pairTokensAndValue(
                                path.path[index],
                                path.path[index + 1],
                                path.uniV3PoolFees[index],
                                path.swapRouter
                            )) /
                        1e18;
                }
            } else if (path.swapType == SwapType.ALGEBRA) {
                for (uint256 index = 0; index < path.path.length - 1; index++) {
                    weightedPrice =
                        (weightedPrice *
                            AlgebraSwapHelper.pairTokensAndValue(
                                path.path[index],
                                path.path[index + 1],
                                path.swapRouter
                            )) /
                        1e18;
                }
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.15;

/// @title Constant state
/// @notice Constant state used by the swap router
library Constants {
    /// @dev Used for identifying cases when this contract's balance of a token is to be used
    uint256 internal constant CONTRACT_BALANCE = 0;

    /// @dev Used as a flag for identifying msg.sender, saves gas by sending more 0 bytes
    address internal constant MSG_SENDER = address(1);

    /// @dev Used as a flag for identifying address(this), saves gas by sending more 0 bytes
    address internal constant ADDRESS_THIS = address(2);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;
pragma abicoder v2;

import "../interfaces/IMulticall.sol";

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall {
    /// @inheritdoc IMulticall
    function multicall(bytes[] calldata data) public payable override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

/*
  ______                     ______                                 
 /      \                   /      \                                
|  ▓▓▓▓▓▓\ ______   ______ |  ▓▓▓▓▓▓\__   __   __  ______   ______  
| ▓▓__| ▓▓/      \ /      \| ▓▓___\▓▓  \ |  \ |  \|      \ /      \ 
| ▓▓    ▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\\▓▓    \| ▓▓ | ▓▓ | ▓▓ \▓▓▓▓▓▓\  ▓▓▓▓▓▓\
| ▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓    ▓▓_\▓▓▓▓▓▓\ ▓▓ | ▓▓ | ▓▓/      ▓▓ ▓▓  | ▓▓
| ▓▓  | ▓▓ ▓▓__/ ▓▓ ▓▓▓▓▓▓▓▓  \__| ▓▓ ▓▓_/ ▓▓_/ ▓▓  ▓▓▓▓▓▓▓ ▓▓__/ ▓▓
| ▓▓  | ▓▓ ▓▓    ▓▓\▓▓     \\▓▓    ▓▓\▓▓   ▓▓   ▓▓\▓▓    ▓▓ ▓▓    ▓▓
 \▓▓   \▓▓ ▓▓▓▓▓▓▓  \▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓\▓▓▓▓  \▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓ 
         | ▓▓                                             | ▓▓      
         | ▓▓                                             | ▓▓      
          \▓▓                                              \▓▓         
 * App:             https://ApeSwap.finance
 * Medium:          https://ape-swap.medium.com
 * Twitter:         https://twitter.com/ape_swap
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * Discord:         https://ApeSwap.click/discord
 * Reddit:          https://reddit.com/r/ApeSwap
 * Instagram:       https://instagram.com/ApeSwap.finance
 * GitHub:          https://github.com/ApeSwapFinance
 */

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

library TokenHelper {
    function getTokenDecimals(address token) internal view returns (uint256 decimals) {
        try IERC20Metadata(token).decimals() returns (uint8 dec) {
            decimals = dec;
        } catch {
            decimals = 18;
        }
    }

    /// @notice Normalize token decimals to 18
    /// @param amount Amount of tokens
    /// @param decimals Decimals of given token amount to scale. MUST be <=18
    function normalizeTokenDecimals(uint256 amount, uint256 decimals) internal pure returns (uint256) {
        return amount * 10 ** (18 - decimals);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

import "../libraries/Constants.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TransferHelper {
    using SafeERC20 for IERC20;

    /// @notice transfer tokens in if necessary
    /// @param token input token
    /// @param inputAmount input amount
    function _transferIn(IERC20 token, uint256 inputAmount) internal returns (uint256) {
        if (inputAmount == Constants.CONTRACT_BALANCE) {
            inputAmount = _getBalance(token);
        } else {
            uint256 balanceBefore = _getBalance(token);
            token.safeTransferFrom(msg.sender, address(this), inputAmount);
            inputAmount = _getBalance(token) - balanceBefore;
        }
        return inputAmount;
    }

    /// @notice transfer tokens out if necessary
    /// @param token input token
    /// @param outputAmount output amount
    /// @param recipient transfer tokens to this address
    function _transferOut(IERC20 token, uint256 outputAmount, address recipient) internal returns (uint256) {
        if (outputAmount == Constants.CONTRACT_BALANCE) {
            /// @dev Returns balance in contract. Does not transfer tokens out.
            outputAmount = _getBalance(token);
        }
        if (outputAmount > 0) {
            token.safeTransfer(recipient, outputAmount);
        }
        return outputAmount;
    }

    function _getBalance(IERC20 token) internal view returns (uint256 balance) {
        balance = token.balanceOf(address(this));
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

import "./interfaces/IWETH.sol";
import "./libraries/Constants.sol";

contract WrapNative {
    IWETH public WNative;

    constructor(IWETH _wNative) {
        WNative = _wNative;
    }

    function wrapNative(uint256 amount, address recipient) external payable {
        IWETH(WNative).deposit{value: amount}();

        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        if (recipient != Constants.ADDRESS_THIS && recipient != address(this)) {
            WNative.transfer(recipient, amount);
        }
    }

    function unwrapNative(uint256 amount, address recipient) external {
        IWETH(WNative).withdraw(amount);

        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        if (recipient != Constants.ADDRESS_THIS && recipient != address(this)) {
            // 2600 COLD_ACCOUNT_ACCESS_COST plus 2300 transfer gas - 1
            // Intended to support transfers to contracts, but not allow for further code execution
            (bool success, ) = recipient.call{value: amount, gas: 4899}(new bytes(0));
            require(success, "Native transfer failed");
        }
    }
}