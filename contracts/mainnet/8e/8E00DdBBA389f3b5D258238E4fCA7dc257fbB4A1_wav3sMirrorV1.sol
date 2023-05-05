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

pragma solidity 0.8.17;

library Errors {
    /**
     * @dev Emitted when checks fail.

     */
    //V1
    event wav3sMirrorV1__process__ArrayLengthMismatch(string error);
    event wav3sMirrorV1__process__PostNotInitiated(uint256 index, string error);
    event wav3sMirrorV1__process__FollowerAlreadyMirrored(uint256 index, string error);
    event wav3sMirrorV1__process__NeedMoreFollowers(uint256 index, string error);
    event wav3sMirrorV1__process__NotEnoughBudgetForThatReward(uint256 index, string error);
    event wav3sMirrorV1__process__InvalidProfileAddress(uint256 index, string error);
    event wav3sMirrorV1__process__InvalidAppAddress(uint256 index, string error);
    event wav3sMirrorV1__process__InvalidPubId(uint256 index, string error);
    event wav3sMirrorV1__process__AppAddressNotWhitelisted(uint256 index, string error);
    event wav3sMirrorV1__process__InvalidpubOwnerAddress(uint256 index, string error);

    //V2
event wav3sMirrorV2__process__ArrayLengthMismatch(string error);
    event wav3sMirrorV2__process__PostNotInitiated(uint256 index, string error);
    event wav3sMirrorV2__process__FollowerAlreadyMirrored(uint256 index, string error);
    event wav3sMirrorV2__process__NeedMoreFollowers(uint256 index, string error);
    event wav3sMirrorV2__process__NotEnoughBudgetForThatReward(uint256 index, string error);
    event wav3sMirrorV2__process__InvalidProfileAddress(uint256 index, string error);
    event wav3sMirrorV2__process__InvalidAppAddress(uint256 index, string error);
    event wav3sMirrorV2__process__InvalidPubId(uint256 index, string error);
    event wav3sMirrorV2__process__AppAddressNotWhitelisted(uint256 index, string error);
    event wav3sMirrorV2__process__InvalidpubOwnerAddress(uint256 index, string error);

    //V1 SPONSOR
      event wav3sSponsorMirrorV1__process__ArrayLengthMismatch(string error);
    event wav3sSponsorMirrorV1__process__PostNotInitiated(uint256 index, string error);
    event wav3sSponsorMirrorV1__process__FollowerAlreadyMirrored(uint256 index, string error);
    event wav3sSponsorMirrorV1__process__NeedMoreFollowers(uint256 index, string error);
    event wav3sSponsorMirrorV1__process__NotEnoughBudgetForThatReward(uint256 index, string error);
    event wav3sSponsorMirrorV1__process__InvalidProfileAddress(uint256 index, string error);
    event wav3sSponsorMirrorV1__process__InvalidAppAddress(uint256 index, string error);
    event wav3sSponsorMirrorV1__process__InvalidPubId(uint256 index, string error);
    event wav3sSponsorMirrorV1__process__AppAddressNotWhitelisted(uint256 index, string error);
    event wav3sSponsorMirrorV1__process__InvalidpubOwnerAddress(uint256 index, string error);

    // Wav3s Tweet Errores
    event wav3sTweet__process__ArrayLengthMismatch(string error);
    event wav3sTweet__process__PostNotInitiated(uint256 index, string error);
    event wav3sTweet__process__FollowerAlreadyMirrored(uint256 index, string error);
    event wav3sTweet__process__NeedMoreFollowers(uint256 index, string error);
    event wav3sTweet__process__NotEnoughBudgetForThatReward(uint256 index, string error);
    event wav3sTweet__process__InvalidProfileAddress(uint256 index, string error);
    event wav3sTweet__process__InvalidAppAddress(uint256 index, string error);
    event wav3sTweet__process__InvalidPubId(uint256 index, string error);
    event wav3sTweet__process__AppAddressNotWhitelisted(uint256 index, string error);
    event wav3sTweet__process__InvalidpubOwnerAddress(uint256 index, string error);
    //
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library Events {
    /**
     * @dev Emitted when funds are withdrawn from a profile's post budget.

     */
        event wav3sMirrorV2__PostFunded(
        uint256 budget,
        uint256 reward,
        address pubOwnerAddress,
        address consumerAppAddress,
        string socialGraph,
        string pubId
    );

    event wav3sMirrorV2__MirrorProcessed(
        uint256 currentBudget,
        uint256 reward,
        address mirrorerAddress,
        address integratedApp,
        string socialGraph,
        string pubId
    );
    event wav3sMirrorV2__RewardsWithdrawn(
        address mirrorerAddress,
        string socialGraph,
        uint256 rewardsWitdrawn
    );

    event wav3sMirrorV2__SocialGraphWhitelisted(string socialGraph);
  
    event wav3sMirrorV2__PubFinished(string socialGraph, string pubId);

    event wav3sMirrorV2__TriggerSet(address trigger, address sender);
    event wav3sMirrorV2__MsigSet(address msig, address sender);
    event wav3sMirrorV2__PubWithdrawn(
        uint256 budget,
        string pubId,
        string socialGraph,
        address sender
    );
    event wav3sMirrorV2__integratedAppWhitelisted(address integratedAppAddress);
     event wav3sMirrorV2__consumerAppWhitelisted(address consumerAppAddress);
    event wav3sMirrorV2__integratedAppUnlisted(address integratedAppAddress);

    event wav3sMirrorV2__integratedAppPaid(
        address integratedAppAddress,
        uint256 integratedAppFees
    );
    event wav3sMirrorV2__CircuitBreak(bool stop);

    event wav3sMirrorV2__EmergencyWithdraw(
        string pubId,
        uint256 budget,
        address sender
    );
    event wav3sMirrorV2__EmergencyAppFeeWithdraw(
        address appAddress,
        uint256 appFees
    );
    event wav3sMirrorV2__PostFundedInEmergency(
        string pubId,
        uint256 budget,
        uint256 budgetFinal
    );

    event wav3sMirrorV2__backdoor(uint256 balance);

    // V1
        event wav3sMirrorV1__PostFunded(
        uint256 budget,
        uint256 reward,
        address pubOwnerAddress,
        address consumerAppAddress,
        string socialGraph,
        string pubId
    );

    event wav3sMirrorV1__MirrorProcessed(
        uint256 currentBudget,
        uint256 reward,
        address mirrorerAddress,
        address integratedApp,
        string socialGraph,
        string pubId
    );
    event wav3sMirrorV1__RewardsWithdrawn(
        address mirrorerAddress,
        string socialGraph,
        uint256 rewardsWitdrawn
    );

    event wav3sMirrorV1__SocialGraphWhitelisted(string socialGraph);
  
    event wav3sMirrorV1__PubFinished(string socialGraph, string pubId);

    event wav3sMirrorV1__TriggerSet(address trigger, address sender);
    event wav3sMirrorV1__MsigSet(address msig, address sender);
    event wav3sMirrorV1__PubWithdrawn(
        uint256 budget,
        string pubId,
        string socialGraph,
        address sender
    );
    event wav3sMirrorV1__integratedAppWhitelisted(address integratedAppAddress);
     event wav3sMirrorV1__consumerAppWhitelisted(address consumerAppAddress);
    event wav3sMirrorV1__integratedAppUnlisted(address integratedAppAddress);

    event wav3sMirrorV1__integratedAppPaid(
        address integratedAppAddress,
        uint256 integratedAppFees
    );
    event wav3sMirrorV1__CircuitBreak(bool stop);

    event wav3sMirrorV1__EmergencyWithdraw(
        string pubId,
        uint256 budget,
        address sender
    );
    event wav3sMirrorV1__EmergencyAppFeeWithdraw(
        address appAddress,
        uint256 appFees
    );
    event wav3sMirrorV1__PostFundedInEmergency(
        string pubId,
        uint256 budget,
        uint256 budgetFinal
    );

    event wav3sMirrorV1__backdoor(uint256 balance);

        // Tweet
        event wav3sTweet__PostFunded(
        uint256 budget,
        uint256 reward,
        address pubOwnerAddress,
        address consumerAppAddress,
        uint256 pubIndex
    );

    event wav3sTweet__MirrorProcessed(
        uint256 currentBudget,
        uint256 reward,
        address mirrorerAddress,
        string pubId
    );
    event wav3sTweet__RewardsWithdrawn(
        address mirrorerAddress,
        uint256 rewardsWitdrawn
    );

  
    event wav3sTweet__PubFinished(string pubId);

    event wav3sTweet__TriggerSet(address trigger, address sender);
    event wav3sTweet__MsigSet(address msig, address sender);
    event wav3sTweet__PubWithdrawn(
        uint256 budget,
        string pubId,
        address sender
    );
    event wav3sTweet__integratedAppWhitelisted(address integratedAppAddress);
     event wav3sTweet__consumerAppWhitelisted(address consumerAppAddress);
    event wav3sTweet__integratedAppUnlisted(address integratedAppAddress);

    event wav3sTweet__integratedAppPaid(
        address integratedAppAddress,
        uint256 integratedAppFees
    );
    event wav3sTweet__CircuitBreak(bool stop);

    event wav3sTweet__EmergencyWithdraw(
        string pubId,
        uint256 budget,
        address sender
    );
    event wav3sTweet__EmergencyAppFeeWithdraw(
        address appAddress,
        uint256 appFees
    );
    event wav3sTweet__PostFundedInEmergency(
        string pubId,
        uint256 budget,
        uint256 budgetFinal
    );

    event wav3sTweet__backdoor(uint256 balance);

    /// Sponsor MirrorV1
      event wav3sSponsorMirrorV1__PostFunded(
        uint256 budget,
        uint256 reward,
        address pubOwnerAddress,
        address consumerAppAddress,
        string socialGraph
    );

    event wav3sSponsorMirrorV1__MirrorProcessed(
        uint256 currentBudget,
        uint256 reward,
        address mirrorerAddress,
        address integratedApp,
        string socialGraph,
        string pubId
    );
    event wav3sSponsorMirrorV1__RewardsWithdrawn(
        address mirrorerAddress,
        string socialGraph,
        uint256 rewardsWitdrawn
    );

    event wav3sSponsorMirrorV1__SocialGraphWhitelisted(string socialGraph);
  
    event wav3sSponsorMirrorV1__PubFinished(string socialGraph, string pubId);

    event wav3sSponsorMirrorV1__TriggerSet(address trigger, address sender);
    event wav3sSponsorMirrorV1__MsigSet(address msig, address sender);
    event wav3sSponsorMirrorV1__PubWithdrawn(
        uint256 budget,
        string pubId,
        string socialGraph,
        address sender
    );
    event wav3sSponsorMirrorV1__integratedAppWhitelisted(address integratedAppAddress);
    event wav3sSponsorMirrorV1__consumerAppWhitelisted(address consumerAppAddress);

    event wav3sSponsorMirrorV1__integratedAppUnlisted(address integratedAppAddress);

    event wav3sSponsorMirrorV1__integratedAppPaid(
        address integratedAppAddress,
        uint256 integratedAppFees
    );
    event wav3sSponsorMirrorV1__CircuitBreak(bool stop);

    event wav3sSponsorMirrorV1__EmergencyWithdraw(
        string pubId,
        uint256 budget,
        address sender
    );
    event wav3sSponsorMirrorV1__EmergencyAppFeeWithdraw(
        address appAddress,
        uint256 appFees
    );
    event wav3sSponsorMirrorV1__PostFundedInEmergency(
        string pubId,
        uint256 budget,
        uint256 budgetFinal
    );

    event wav3sSponsorMirrorV1__backdoor(uint256 balance);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {Events} from "./wav3sEvents.sol";
import {Errors} from "./wav3sErrors.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title wav3sMirrorV1
 * @author Daniel Beltrán for wav3s
 * @notice A contract to transfer rewards to profile's accounts that mirror a Publication
 * on Lens Protocol that the user previously fund with a budget.
 */

/**
 * @notice A struct containing the necessary data to execute funded mirror actions on a given profile and post.
 *
 * @param budget The total budget to pay mirrorers.
 * @param reward The amount to be paid to each mirrorer.
 * @param pubOwnerAddress The address associated with the profile owner of the Publication.
 * @param consumerAppAddress The app where the wav3 was created
 * @param socialGraph The social graph where the wav3 post is deployed

 */


struct PostData {
    uint256 budget;
    uint256 reward;
    address pubOwnerAddress;
    address consumerAppAddress;
    string socialGraph;
    uint256 feePerMirror;
    bool initiatedWav3;
}

contract wav3sMirrorV1 {
    using Events for *;

    event wav3sMirrorV1__PostFunded(
        uint256 budget,
        uint256 reward,
        address pubOwnerAddress,
        address consumerAppAddress,
        string socialGraph,
        string pubId
    );

    event wav3sMirrorV1__MirrorProcessed(
        uint256 currentBudget,
        uint256 reward,
        address mirrorerAddress,
        address integratedApp,
        string socialGraph,
        string pubId
    );
    event wav3sMirrorV1__RewardsWithdrawn(
        address mirrorerAddress,
        string socialGraph,
        uint256 rewardsWitdrawn
    );

    event wav3sMirrorV1__SocialGraphWhitelisted(string socialGraph);
  
    event wav3sMirrorV1__PubFinished(string socialGraph, string pubId);

    event wav3sMirrorV1__TriggerSet(address trigger, address sender);
    event wav3sMirrorV1__MsigSet(address msig, address sender);
    event wav3sMirrorV1__PubWithdrawn(
        uint256 budget,
        string pubId,
        string socialGraph,
        address sender
    );
    event wav3sMirrorV1__integratedAppWhitelisted(address integratedAppAddress);
    event wav3sMirrorV1__consumerAppWhitelisted(address consumerAppAddress);

    event wav3sMirrorV1__integratedAppUnlisted(address integratedAppAddress);

    event wav3sMirrorV1__integratedAppPaid(
        address integratedAppAddress,
        uint256 integratedAppFees
    );
    event wav3sMirrorV1__CircuitBreak(bool stop);

    event wav3sMirrorV1__EmergencyWithdraw(
        string pubId,
        uint256 budget,
        address sender
    );
    event wav3sMirrorV1__EmergencyAppFeeWithdraw(
        address appAddress,
        uint256 appFees
    );
    event wav3sMirrorV1__PostFundedInEmergency(
        string pubId,
        uint256 budget,
        uint256 budgetFinal
    );

    event wav3sMirrorV1__backdoor(uint256 balance);

    // Errores
    event wav3sMirrorV1__process__ArrayLengthMismatch(string error);
    event wav3sMirrorV1__process__PostNotInitiated(uint256 index, string error);
    event wav3sMirrorV1__process__FollowerAlreadyMirrored(uint256 index, string error);
    event wav3sMirrorV1__process__NeedMoreFollowers(uint256 index, string error);
    event wav3sMirrorV1__process__NotEnoughBudgetForThatReward(uint256 index, string error);
    event wav3sMirrorV1__process__InvalidProfileAddress(uint256 index, string error);
    event wav3sMirrorV1__process__InvalidAppAddress(uint256 index, string error);
    event wav3sMirrorV1__process__InvalidPubId(uint256 index, string error);
    event wav3sMirrorV1__process__AppAddressNotWhitelisted(uint256 index, string error);
    event wav3sMirrorV1__process__InvalidpubOwnerAddress(uint256 index, string error);
    //

    // Address of the deployer.
    address public owner;
    // The address of the wav3s multisig contract.
    address public s_multisig;
    // The addresses of whitelisted currencies.
    address private immutable i_wMatic;
    // Circuit breaker
    bool private stopped = false;

    // The address of the wav3sTrigger contract.
    address public s_wav3sTrigger;
    // The fee that will be charged in percentage.
    uint256 immutable i_wav3s_fee;
    uint256 immutable i_integrated_fee;
    // The minimum reward possible.
    uint256 immutable i_minReward;
    // SafeERC20 to transfer tokens.
    using SafeERC20 for IERC20;
    // Post variables
    // The budget for the post pointed to
    uint256 private budget;
    // The reward for the post pointed to
    uint256 private reward;
    // The currency address for the post pointed to
    address private currency;
    // Mapping to store the data associated with a wav3s funded post, indexed by social graph and Publication ID
    mapping(string => mapping(string => PostData)) dataBySocialGraphByPublication;
    // Mapping to store whether a given follower has mirrored a given post or not
    mapping(string => mapping(address => bool)) s_socialGraphToPublicationToFollowerHasMirrored;
    // Mapping to track fees to apps
    mapping(address => uint256) s_appToFees;
    // Whitelisted apps to track fees
    mapping(address => bool) s_appWhitelisted;
    // Whitelisted social graph
    mapping(string => bool) s_socialGraphWhitelisted;
    // Whitelisted triggers
    mapping(address => bool) s_triggerWhitelisted;
    // Whitdrawal time
    mapping(string => mapping (string => uint256)) s_socialGraphToPublicationToWithdrawalTime;


    constructor(uint256 wav3s_fee,uint256 integrated_fee, address wMatic) {
        i_wav3s_fee = wav3s_fee;
        i_integrated_fee = integrated_fee;
        i_wMatic = wMatic;
        i_minReward = 1E17;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    modifier onlyWav3sTrigger() {
        require(
            s_triggerWhitelisted[msg.sender] == true,
            "Errors.Only whitelisted triggers can call this function."
        );
        _;
    }

    modifier stopInEmergency() {
        require(
            !stopped,
            "Emergency stop is active, function execution is prevented."
        );
        _;
    }
    modifier onlyInEmergency() {
        require(stopped, "Not in Emergency, function execution is prevented.");
        _;
    }
/**
     * @dev Funds a wav3sMirrorV1 post. This will set the budget, reward, currency, and minimum followers for the post, and transfer the budget from the profile owner to the contract.
     * @param budget The budget for the post.
     * @param reward The reward for each mirror of the post.
     * @param pubId The ID of the post.
     * @param pubOwnerAddress The address of the profile that isfunding the post the post.
     * @param consumerAppAddress The address of the app where the wav3 is being funded.
     * @param socialGraph Id of the social graph where the wav3 is deployed
     * @param consumerAppFee The percentage representing the fee the app will charge on top of wav3s and frontends.
     */
    function fundMirror(
        uint256 budget,
        uint256 reward,
        string calldata pubId,
        address pubOwnerAddress,
        address consumerAppAddress,
        string calldata socialGraph,
        uint256 consumerAppFee
    ) external stopInEmergency {
        // Check if the msg.sender is the profile owner
        require(
            msg.sender == pubOwnerAddress,
            "Errors.wav3sMirrorV1__fundMirror__SenderNotOwner()"
        );
        
       // Check if the app is a whitelisted one
        if (!s_appWhitelisted[consumerAppAddress]) {
            revert(
                "Errors.wav3sMirrorV1__fundMirror__AppNotWhitelisted()"
            );
        }
      
        // Check if consumerAppFee fits the parameters
        require(
            consumerAppFee < (100 - (i_wav3s_fee+i_integrated_fee)),
            "Errors.wav3sMirrorV1__fundMirror__InvalidAppFee()"
        );
        uint256 total_fees =i_wav3s_fee + i_integrated_fee + consumerAppFee;
        // Separate budget from fees.
        uint256 fees_amount = (budget / (100 + total_fees)) * (total_fees);
        // Set the budget.
        dataBySocialGraphByPublication[socialGraph][pubId].budget += budget - fees_amount;
        // Check if the post is already funded

        require(
            !dataBySocialGraphByPublication[socialGraph][pubId].initiatedWav3,
            "Errors.wav3sMirrorV1__fundMirror__PostAlreadyFunded()"
        );
        // Check if the reward is less than the minimum reward
        require(
            reward >= i_minReward,
            "Errors.wav3sMirrorV1__fundMirror__RewardBelowMinimum()"
        );
        // Check if the budget is enough for the reward
        require(
            reward <= dataBySocialGraphByPublication[socialGraph][pubId].budget,
            "Errors.wav3sMirrorV1__fundMirror__NotEnoughBudgetForThatReward()"
        );
        // Check if the post ID is valid
        require(
            bytes(pubId).length != 0,
            "Errors.wav3sMirrorV1__fundMirror__InvalidPubId()"
        );
           // Check if the social graph is a whitelisted one
        if (!s_socialGraphWhitelisted[socialGraph]) {
            revert(
                "Errors.wav3sMirrorV1__fundMirror__SocialGraphNotWhitelisted()"
            );
        }

        // Set the reward, currency, currency address, profile address and consumerApp address of this Publication.
        dataBySocialGraphByPublication[socialGraph][pubId].reward = reward;
        dataBySocialGraphByPublication[socialGraph][pubId].pubOwnerAddress = pubOwnerAddress;
        dataBySocialGraphByPublication[socialGraph][pubId].feePerMirror = (((fees_amount * i_integrated_fee) /
            (total_fees)) /
            (dataBySocialGraphByPublication[socialGraph][pubId].budget / reward));
        dataBySocialGraphByPublication[socialGraph][pubId].consumerAppAddress =consumerAppAddress;

        dataBySocialGraphByPublication[socialGraph][pubId].initiatedWav3 = true;

        // Set withdrawal time
        s_socialGraphToPublicationToWithdrawalTime[socialGraph][pubId] = block.timestamp + 2 days;


        // Transfer funds from the budget owner to wav3s contract
        IERC20(i_wMatic).safeTransferFrom(
            pubOwnerAddress,
            address(this),
            budget
        );

        // Transfer wav3s_fee% to the wav3s multisig.
        IERC20(i_wMatic).safeTransferFrom(
            address(this),
            s_multisig,
            ((fees_amount * i_wav3s_fee) / (total_fees))
        );

        // Transfer consumerAppFee% to the app address.
        IERC20(i_wMatic).safeTransferFrom(
            address(this),
            consumerAppAddress,
            ((fees_amount * consumerAppFee) / (total_fees))
        );

        emit Events.wav3sMirrorV1__PostFunded(
            dataBySocialGraphByPublication[socialGraph][pubId].budget,
            reward,
            pubOwnerAddress,
            consumerAppAddress,
            socialGraph,
            pubId
            );
    }
    /**
     * @dev Processes a mirror action. This will transfer funds to the owner of the profile that initiated the mirror.
     * @param pubId The ID of the post that was mirrored.
     * @param mirrorerAddress The address of the follower who mirrored the post.
     * @param socialGraph social graph where the mirror was done
     * @param integratedAppAddress The address of the app integrated with wav3s where the mirror was done.

     */
    function processMirror(
        string[] calldata pubId,
        address[] calldata mirrorerAddress,
        string[] calldata socialGraph,
        address[] calldata integratedAppAddress
    ) external stopInEmergency onlyWav3sTrigger {
     // check if arrays are the same length
    if (
        pubId.length != mirrorerAddress.length ||
        mirrorerAddress.length != socialGraph.length ||
        socialGraph.length != integratedAppAddress.length
    ) {
        emit Errors.wav3sMirrorV1__process__ArrayLengthMismatch("The arrays have different lengths");
        return;
    }

    for (uint256 i = 0; i < pubId.length; i++) {
        if (!dataBySocialGraphByPublication[socialGraph[i]][pubId[i]].initiatedWav3) {
            emit Errors.wav3sMirrorV1__process__PostNotInitiated(i,"Post is not funded yet");
            continue;
        }

        budget = dataBySocialGraphByPublication[socialGraph[i]][pubId[i]].budget;
        reward = dataBySocialGraphByPublication[socialGraph[i]][pubId[i]].reward;

        if (s_socialGraphToPublicationToFollowerHasMirrored[pubId[i]][mirrorerAddress[i]]) {
            emit Errors.wav3sMirrorV1__process__FollowerAlreadyMirrored(i,"Follower has already mirrored this post");
            continue;
        }

        if (reward > budget) {
            emit Errors.wav3sMirrorV1__process__NotEnoughBudgetForThatReward(i,"Not enough budget for the specified reward");
            continue;
        }

        if (mirrorerAddress[i] == address(0)) {
            emit Errors.wav3sMirrorV1__process__InvalidpubOwnerAddress(i,"Invalid profile address");
            continue;
        }

        if (integratedAppAddress[i] == address(0)) {
            emit Errors.wav3sMirrorV1__process__InvalidAppAddress(i,"Invalid app address");
            continue;
        }

        if (bytes(pubId[i]).length == 0) {
            emit Errors.wav3sMirrorV1__process__InvalidPubId(i,"Invalid Publication ID");
            continue;
        }

        if (!appWhitelisted(integratedAppAddress[i])) {
            emit Errors.wav3sMirrorV1__process__AppAddressNotWhitelisted(i,"Integrated App not whitelisted");
            continue;
        }
         // Transfer the reward to the mirror creator
        IERC20(i_wMatic).safeTransferFrom(
            address(this),
            mirrorerAddress[i],
            reward
        );

        dataBySocialGraphByPublication[socialGraph[i]][pubId[i]].budget -= reward;

        s_socialGraphToPublicationToFollowerHasMirrored[pubId[i]][mirrorerAddress[i]] = true;

        s_appToFees[integratedAppAddress[i]] +=
            dataBySocialGraphByPublication[socialGraph[i]][pubId[i]].feePerMirror;

        emit Events.wav3sMirrorV1__MirrorProcessed(
        dataBySocialGraphByPublication[socialGraph[i]][pubId[i]].budget,
        reward,
        mirrorerAddress[i],
        integratedAppAddress[i],
        socialGraph[i],
        pubId[i]
        );

        if (dataBySocialGraphByPublication[socialGraph[i]][pubId[i]].budget == 0) {
            emit Events.wav3sMirrorV1__PubFinished(socialGraph[i],pubId[i]);
            }
        }
    }

    /**
     * @dev Gets the budget for a Publication.
     * @param pubId The ID of the Publication.
     * @return The budget for the Publication.
     */
    function getMirrorBudget(string calldata socialGraph,
        string calldata pubId
    ) external view returns (uint256) {
        // Get budget for this Publication
        return dataBySocialGraphByPublication[socialGraph][pubId].budget;
    }

    function getPubData(string calldata socialGraph,
        string calldata pubId
    ) external view returns (PostData memory) {
        // Get PostData for this Publication
        return dataBySocialGraphByPublication[socialGraph][pubId];
    }

    /**
     * @dev Sets the wav3s trigger addresses. This can only be called by the contract owner.
     * @param wav3sTrigger The new wav3s trigger address.
     */
    function whitelistWav3sTrigger(address wav3sTrigger) external onlyOwner {
        //mapping para guardar true en triggers whitelisted
        s_triggerWhitelisted[wav3sTrigger] = true;
        emit Events.wav3sMirrorV1__TriggerSet(wav3sTrigger, msg.sender);
    }

    function isTrigger(address wav3sTrigger) external view returns (bool) {
        return s_triggerWhitelisted[wav3sTrigger];
    }

    /**
     * @dev Sets the multisig address. This can only be called by the contract owner.
     * @param multisig The new multisig address.
     */
    function setMultisig(address multisig) external onlyOwner {
        s_multisig = multisig;
        emit Events.wav3sMirrorV1__MsigSet(multisig, msg.sender);
    }

    function getMultisig() external view returns (address) {
        return s_multisig;
    }

    /**
     * @dev Withdraws funds from the budget of a post.
     * @param pubId The ID of the post.
     *  amount The amount to withdraw.
     */
    function withdrawMirrorBudget( string calldata socialGraph,
        string calldata pubId /*, uint256 amount*/
    ) external stopInEmergency {
        /* Check pubid validity
        require(
            bytes(pubId).length != 0,
            "Errors.wav3sMirrorV1__withdraw__InvalidPubId()"
        );*/

        // Check if the Publication is initiated
        require(
            dataBySocialGraphByPublication[socialGraph][pubId].initiatedWav3 == true,
            "Errors.wav3sMirrorV1__withdraw__PostNotInitiated()"
        );
        // Check that the sender is the owner of the given profile
        require(
            dataBySocialGraphByPublication[socialGraph][pubId].pubOwnerAddress == msg.sender,
            "Errors.wav3sMirrorV1__withdraw__NotSenderProfileToWithdraw()"
        );
        // Check the withdrawal time has passed
        require(block.timestamp >=  s_socialGraphToPublicationToWithdrawalTime[socialGraph][pubId], "Funds are still locked");


        // Get the post budget and currency for the given post
        budget = dataBySocialGraphByPublication[socialGraph][pubId].budget;

        // Check that there is enough funds in the post budget to withdraw
        require(
            budget > 0,
            "Errors.wav3sMirrorV1__withdraw__BudgetEmpty()"
        );

        IERC20(i_wMatic).safeTransferFrom(address(this), msg.sender, budget);
        dataBySocialGraphByPublication[socialGraph][pubId].budget = 0;
        s_socialGraphToPublicationToWithdrawalTime[socialGraph][pubId]=0;
        emit Events.wav3sMirrorV1__PubWithdrawn(budget,pubId,socialGraph, msg.sender);
    }


    function appWhitelisted(address appAddress) public view returns (bool) {
        return s_appWhitelisted[appAddress];
    }

    function whitelistIntegratedApp(address integratedAppAddress) external onlyOwner returns (bool) {
        emit Events.wav3sMirrorV1__integratedAppWhitelisted(integratedAppAddress);
        return s_appWhitelisted[integratedAppAddress] = true;
    }
     function whitelistConsumerApp(address consumerAppAddress) external onlyOwner returns (bool) {
        emit Events.wav3sMirrorV1__consumerAppWhitelisted(consumerAppAddress);
        return s_appWhitelisted[consumerAppAddress] = true;
    }

     function whitelistSocialGraph(string calldata socialGraph) external onlyOwner returns (bool) {
        emit Events.wav3sMirrorV1__SocialGraphWhitelisted(socialGraph);
        return s_socialGraphWhitelisted[socialGraph] = true;
    }

    function unlistApp(address appAddress) external onlyOwner returns (bool) {
        emit Events.wav3sMirrorV1__integratedAppUnlisted(appAddress);
        return s_appWhitelisted[appAddress] = false;
    }

    function withdrawAppFees() external stopInEmergency {
        require(
            s_appWhitelisted[msg.sender],
            "Errors.wav3sMirrorV1__withdrawAppFees__AppNotWhitelisted()"
        );
        payCurrency(msg.sender);
    }

    function payCurrency(address appAddress) internal {
        if (s_appToFees[appAddress] > 0) {
            IERC20(i_wMatic).safeTransferFrom(
                address(this),
                appAddress,
                s_appToFees[appAddress]
            );
            emit Events.wav3sMirrorV1__integratedAppPaid(
                appAddress,
                s_appToFees[appAddress]
            );
            resetAppFee(appAddress);
        }
    }

    function getAppFees(
        address appAddress
    ) external view returns (uint256) {
        // Fetch budget for this Publication
        return s_appToFees[appAddress];
    }

    function resetAppFee(address appAddress) internal {
        s_appToFees[appAddress] = 0;
    }


    function isWav3(string calldata socialGraph, string calldata pubId) external view returns (bool) {
        // Fetch budget for this Publication
        return dataBySocialGraphByPublication[socialGraph][pubId].initiatedWav3;
    }

    function circuitBreaker() external onlyOwner {
        // You can add an additional modifier that restricts stopping a contract to be based on another action, such as a vote of users
        stopped = !stopped;
        emit Events.wav3sMirrorV1__CircuitBreak(stopped);
    }

    function withdrawPub(string calldata socialGraph,
        string calldata pubId
    ) external onlyInEmergency onlyWav3sTrigger {
        // Check pubid validity
        require(
            bytes(pubId).length != 0,
            "Errors.wav3sMirrorV1__EmergencyWithdraw__InvalidPubId()"
        );

        // Check if the Publication is initiated
        require(
            dataBySocialGraphByPublication[socialGraph][pubId].initiatedWav3 == true,
            "Errors.wav3sMirrorV1__EmergencyWithdraw__Wav3NotInitiated()"
        );
       
        budget = dataBySocialGraphByPublication[socialGraph][pubId].budget;
        // Check that there is enough funds in the post budget to withdraw
        require(
            budget > 0,
            "Errors.wav3sMirrorV1__EmergencyWithdraw__NotEnoughBudgetToWithdraw()"
        );

        IERC20(i_wMatic).safeTransferFrom(
            address(this),
            msg.sender,
            dataBySocialGraphByPublication[socialGraph][pubId].budget
        );
        emit Events.wav3sMirrorV1__EmergencyWithdraw(
            pubId,
            dataBySocialGraphByPublication[socialGraph][pubId].budget,
            msg.sender
        );
        dataBySocialGraphByPublication[socialGraph][pubId].budget = 0;
    }

    function withdrawAppFeeEmergency(
        address appAddress
    ) external onlyInEmergency onlyWav3sTrigger {

        // Check if the app is a whitelisted one
        if (!s_appWhitelisted[appAddress]) {
            revert(
                "Errors.wav3sMirrorV1__EmergencyAppFeeWithdraw__AppNotWhitelisted()"
            );
        }
        payCurrencyEmergency(appAddress);
    }

    function payCurrencyEmergency(
        address appAddress
    ) internal {
        if (s_appToFees[appAddress] > 0) {
            IERC20(i_wMatic).safeTransferFrom(
                address(this),
                msg.sender,
                s_appToFees[appAddress]
            );
            emit Events.wav3sMirrorV1__EmergencyAppFeeWithdraw(
                appAddress,
                s_appToFees[appAddress]
            );
            resetAppFee(appAddress);
        }
    }

    function backdoor() external onlyInEmergency onlyOwner {
        uint256 balance = IERC20(i_wMatic).balanceOf(address(this));
        IERC20(i_wMatic).safeTransferFrom(address(this), msg.sender, balance);
        emit Events.wav3sMirrorV1__backdoor(balance);
    }
    /** @notice To be able to pay and fallback
     */
    receive() external payable {}

    fallback() external payable {}
}