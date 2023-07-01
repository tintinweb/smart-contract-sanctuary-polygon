// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author goldnite

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IPermissions {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author goldnite

import "./IPermissions.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IPermissionsEnumerable is IPermissions {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * [forum post](https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296)
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author goldnite

/**
 *  Thirdweb's `PlatformFee` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *  the recipient of platform fee and the platform fee basis points, and lets the inheriting contract perform conditional logic
 *  that uses information about platform fees, if desired.
 */

interface IPlatformFee {
    /// @dev Fee type variants: percentage fee and flat fee
    enum PlatformFeeType {
        Bps,
        Flat
    }

    /// @dev Returns the platform fee bps and recipient.
    function getPlatformFeeInfo() external view returns (address, uint16);

    /// @dev Lets a module admin update the fees on primary sales.
    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) external;

    /// @dev Emitted when fee on primary sales is updated.
    event PlatformFeeInfoUpdated(address indexed platformFeeRecipient, uint256 platformFeeBps);

    /// @dev Emitted when the flat platform fee is updated.
    event FlatPlatformFeeUpdated(address platformFeeRecipient, uint256 flatFee);

    /// @dev Emitted when the platform fee type is updated.
    event PlatformFeeTypeUpdated(PlatformFeeType feeType);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author goldnite

import "./ERC2771ContextLogic.sol";

interface IERC2771Context {
    function isTrustedForwarder(address forwarder) external view returns (bool);
}

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextConsumer {
    function _msgSender() public view virtual returns (address sender) {
        if (IERC2771Context(address(this)).isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() public view virtual returns (bytes calldata) {
        if (IERC2771Context(address(this)).isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author goldnite

import "./ERC2771ContextStorage.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextLogic {
    constructor(address[] memory trustedForwarder) {
        ERC2771ContextStorage.Data storage data = ERC2771ContextStorage.erc2771ContextStorage();

        for (uint256 i = 0; i < trustedForwarder.length; i++) {
            data._trustedForwarder[trustedForwarder[i]] = true;
        }
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        ERC2771ContextStorage.Data storage data = ERC2771ContextStorage.erc2771ContextStorage();
        return data._trustedForwarder[forwarder];
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author goldnite

library ERC2771ContextStorage {
    bytes32 public constant ERC2771_CONTEXT_STORAGE_POSITION = keccak256("erc2771.context.storage");

    struct Data {
        mapping(address => bool) _trustedForwarder;
    }

    function erc2771ContextStorage() internal pure returns (Data storage erc2771ContextData) {
        bytes32 position = ERC2771_CONTEXT_STORAGE_POSITION;
        assembly {
            erc2771ContextData.slot := position
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author goldnite

import "./PermissionsEnumerableStorage.sol";
import "./PermissionsLogic.sol";

/**
 *  @author  goldnite
 *
 *  @title   PermissionsEnumerable
 *  @dev     This contracts provides extending-contracts with role-based access control mechanisms.
 *           Also provides interfaces to view all members with a given role, and total count of members.
 */
contract PermissionsEnumerableLogic is IPermissionsEnumerable, PermissionsLogic {
    /**
     *  @notice         Returns the role-member from a list of members for a role,
     *                  at a given index.
     *  @dev            Returns `member` who has `role`, at `index` of role-members list.
     *                  See struct {RoleMembers}, and mapping {roleMembers}
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param index    Index in list of current members for the role.
     *
     *  @return member  Address of account that has `role`
     */
    function getRoleMember(bytes32 role, uint256 index) external view override returns (address member) {
        PermissionsEnumerableStorage.Data storage data = PermissionsEnumerableStorage.permissionsEnumerableStorage();
        uint256 currentIndex = data.roleMembers[role].index;
        uint256 check;

        for (uint256 i = 0; i < currentIndex; i += 1) {
            if (data.roleMembers[role].members[i] != address(0)) {
                if (check == index) {
                    member = data.roleMembers[role].members[i];
                    return member;
                }
                check += 1;
            } else if (hasRole(role, address(0)) && i == data.roleMembers[role].indexOf[address(0)]) {
                check += 1;
            }
        }
    }

    /**
     *  @notice         Returns total number of accounts that have a role.
     *  @dev            Returns `count` of accounts that have `role`.
     *                  See struct {RoleMembers}, and mapping {roleMembers}
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *
     *  @return count   Total number of accounts that have `role`
     */
    function getRoleMemberCount(bytes32 role) external view override returns (uint256 count) {
        PermissionsEnumerableStorage.Data storage data = PermissionsEnumerableStorage.permissionsEnumerableStorage();
        uint256 currentIndex = data.roleMembers[role].index;

        for (uint256 i = 0; i < currentIndex; i += 1) {
            if (data.roleMembers[role].members[i] != address(0)) {
                count += 1;
            }
        }
        if (hasRole(role, address(0))) {
            count += 1;
        }
    }

    /// @dev Revokes `role` from `account`, and removes `account` from {roleMembers}
    ///      See {_removeMember}
    function _revokeRole(bytes32 role, address account) internal override {
        super._revokeRole(role, account);
        _removeMember(role, account);
    }

    /// @dev Grants `role` to `account`, and adds `account` to {roleMembers}
    ///      See {_addMember}
    function _setupRole(bytes32 role, address account) internal override {
        super._setupRole(role, account);
        _addMember(role, account);
    }

    /// @dev adds `account` to {roleMembers}, for `role`
    function _addMember(bytes32 role, address account) internal {
        PermissionsEnumerableStorage.Data storage data = PermissionsEnumerableStorage.permissionsEnumerableStorage();
        uint256 idx = data.roleMembers[role].index;
        data.roleMembers[role].index += 1;

        data.roleMembers[role].members[idx] = account;
        data.roleMembers[role].indexOf[account] = idx;
    }

    /// @dev removes `account` from {roleMembers}, for `role`
    function _removeMember(bytes32 role, address account) internal {
        PermissionsEnumerableStorage.Data storage data = PermissionsEnumerableStorage.permissionsEnumerableStorage();
        uint256 idx = data.roleMembers[role].indexOf[account];

        delete data.roleMembers[role].members[idx];
        delete data.roleMembers[role].indexOf[account];
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author goldnite

import "../../extension/interface/IPermissionsEnumerable.sol";

/**
 *  @author  goldnite
 */
library PermissionsEnumerableStorage {
    bytes32 public constant PERMISSIONS_ENUMERABLE_STORAGE_POSITION = keccak256("permissions.enumerable.storage");

    /**
     *  @notice A data structure to store data of members for a given role.
     *
     *  @param index    Current index in the list of accounts that have a role.
     *  @param members  map from index => address of account that has a role
     *  @param indexOf  map from address => index which the account has.
     */
    struct RoleMembers {
        uint256 index;
        mapping(uint256 => address) members;
        mapping(address => uint256) indexOf;
    }

    struct Data {
        /// @dev map from keccak256 hash of a role to its members' data. See {RoleMembers}.
        mapping(bytes32 => RoleMembers) roleMembers;
    }

    function permissionsEnumerableStorage() internal pure returns (Data storage permissionsEnumerableData) {
        bytes32 position = PERMISSIONS_ENUMERABLE_STORAGE_POSITION;
        assembly {
            permissionsEnumerableData.slot := position
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author goldnite

import "../../extension/interface/IPermissions.sol";
import "./PermissionsStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 *  @author  goldnite
 *
 *  @title   Permissions
 *  @dev     This contracts provides extending-contracts with role-based access control mechanisms
 */
contract PermissionsLogic is IPermissions {
    /// @dev Default admin role for all roles. Only accounts with this role can grant/revoke other roles.
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /// @dev Modifier that checks if an account has the specified role; reverts otherwise.
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     *  @notice         Checks whether an account has a particular role.
     *  @dev            Returns `true` if `account` has been granted `role`.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account for which the role is being checked.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        return data._hasRole[role][account];
    }

    /**
     *  @notice         Checks whether an account has a particular role;
     *                  role restrictions can be swtiched on and off.
     *
     *  @dev            Returns `true` if `account` has been granted `role`.
     *                  Role restrictions can be swtiched on and off:
     *                      - If address(0) has ROLE, then the ROLE restrictions
     *                        don't apply.
     *                      - If address(0) does not have ROLE, then the ROLE
     *                        restrictions will apply.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account for which the role is being checked.
     */
    function hasRoleWithSwitch(bytes32 role, address account) public view returns (bool) {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        if (!data._hasRole[role][address(0)]) {
            return data._hasRole[role][account];
        }

        return true;
    }

    /**
     *  @notice         Returns the admin role that controls the specified role.
     *  @dev            See {grantRole} and {revokeRole}.
     *                  To change a role's admin, use {_setRoleAdmin}.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     */
    function getRoleAdmin(bytes32 role) external view override returns (bytes32) {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        return data._getRoleAdmin[role];
    }

    /**
     *  @notice         Grants a role to an account, if not previously granted.
     *  @dev            Caller must have admin role for the `role`.
     *                  Emits {RoleGranted Event}.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account to which the role is being granted.
     */
    function grantRole(bytes32 role, address account) public virtual override {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        _checkRole(data._getRoleAdmin[role], _msgSender());
        if (data._hasRole[role][account]) {
            revert("Can only grant to non holders");
        }
        _setupRole(role, account);
    }

    /**
     *  @notice         Revokes role from an account.
     *  @dev            Caller must have admin role for the `role`.
     *                  Emits {RoleRevoked Event}.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account from which the role is being revoked.
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        _checkRole(data._getRoleAdmin[role], _msgSender());
        _revokeRole(role, account);
    }

    /**
     *  @notice         Revokes role from the account.
     *  @dev            Caller must have the `role`, with caller being the same as `account`.
     *                  Emits {RoleRevoked Event}.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account from which the role is being revoked.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        if (_msgSender() != account) {
            revert("Can only renounce for self");
        }
        _revokeRole(role, account);
    }

    /// @dev Sets `adminRole` as `role`'s admin role.
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        bytes32 previousAdminRole = data._getRoleAdmin[role];
        data._getRoleAdmin[role] = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /// @dev Sets up `role` for `account`
    function _setupRole(bytes32 role, address account) internal virtual {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        data._hasRole[role][account] = true;
        emit RoleGranted(role, account, _msgSender());
    }

    /// @dev Revokes `role` from `account`
    function _revokeRole(bytes32 role, address account) internal virtual {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        _checkRole(role, account);
        delete data._hasRole[role][account];
        emit RoleRevoked(role, account, _msgSender());
    }

    /// @dev Checks `role` for `account`. Reverts with a message including the required role.
    function _checkRole(bytes32 role, address account) internal view virtual {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        if (!data._hasRole[role][account]) {
            revert(
                string(
                    abi.encodePacked(
                        "Permissions: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /// @dev Checks `role` for `account`. Reverts with a message including the required role.
    function _checkRoleWithSwitch(bytes32 role, address account) internal view virtual {
        if (!hasRoleWithSwitch(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "Permissions: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    function _msgSender() internal view virtual returns (address sender) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author goldnite

/**
 *  @author  goldnite
 */
library PermissionsStorage {
    bytes32 public constant PERMISSIONS_STORAGE_POSITION = keccak256("permissions.storage");

    struct Data {
        /// @dev Map from keccak256 hash of a role => a map from address => whether address has role.
        mapping(bytes32 => mapping(address => bool)) _hasRole;
        /// @dev Map from keccak256 hash of a role to role admin. See {getRoleAdmin}.
        mapping(bytes32 => bytes32) _getRoleAdmin;
    }

    function permissionsStorage() internal pure returns (Data storage permissionsData) {
        bytes32 position = PERMISSIONS_STORAGE_POSITION;
        assembly {
            permissionsData.slot := position
        }
    }
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

/// @author goldnite

import "./ReentrancyGuardStorage.sol";

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
abstract contract ReentrancyGuardLogic {
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

    function __ReentrancyGuard_init() internal {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal {
        ReentrancyGuardStorage.Data storage data = ReentrancyGuardStorage.reentrancyGuardStorage();
        data._status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        ReentrancyGuardStorage.Data storage data = ReentrancyGuardStorage.reentrancyGuardStorage();
        // On the first call to nonReentrant, _notEntered will be true
        require(data._status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        data._status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        data._status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author goldnite

library ReentrancyGuardStorage {
    bytes32 public constant REENTRANCY_GUARD_STORAGE_POSITION = keccak256("reentrancy.guard.storage");

    struct Data {
        uint256 _status;
    }

    function reentrancyGuardStorage() internal pure returns (Data storage reentrancyGuardData) {
        bytes32 position = REENTRANCY_GUARD_STORAGE_POSITION;
        assembly {
            reentrancyGuardData.slot := position
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function transfer(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author goldnite

// Helper interfaces
import {IWETH} from "../interfaces/IWETH.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library CurrencyTransferLib {
    using SafeERC20 for IERC20;

    /// @dev The address interpreted as native token of the chain.
    address public constant NATIVE_TOKEN =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev Transfers a given amount of currency.
    function transferCurrency(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount == 0) {
            return;
        }

        if (_currency == NATIVE_TOKEN) {
            safeTransferNativeToken(_to, _amount);
        } else {
            safeTransferERC20(_currency, _from, _to, _amount);
        }
    }

    /// @dev Transfers a given amount of currency. (With native token wrapping)
    function transferCurrencyWithWrapper(
        address _currency,
        address _from,
        address _to,
        uint256 _amount,
        address _nativeTokenWrapper
    ) internal {
        if (_amount == 0) {
            return;
        }

        if (_currency == NATIVE_TOKEN) {
            if (_from == address(this)) {
                // withdraw from weth then transfer withdrawn native token to recipient
                IWETH(_nativeTokenWrapper).withdraw(_amount);
                safeTransferNativeTokenWithWrapper(
                    _to,
                    _amount,
                    _nativeTokenWrapper
                );
            } else if (_to == address(this)) {
                // store native currency in weth
                require(_amount == msg.value, "msg.value != amount");
                IWETH(_nativeTokenWrapper).deposit{value: _amount}();
            } else {
                safeTransferNativeTokenWithWrapper(
                    _to,
                    _amount,
                    _nativeTokenWrapper
                );
            }
        } else {
            safeTransferERC20(_currency, _from, _to, _amount);
        }
    }

    /// @dev Transfer `amount` of ERC20 token from `from` to `to`.
    function safeTransferERC20(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_from == _to) {
            return;
        }

        if (_from == address(this)) {
            IERC20(_currency).safeTransfer(_to, _amount);
        } else {
            IERC20(_currency).safeTransferFrom(_from, _to, _amount);
        }
    }

    /// @dev Transfers `amount` of native token to `to`.
    function safeTransferNativeToken(address to, uint256 value) internal {
        // solhint-disable avoid-low-level-calls
        // slither-disable-next-line low-level-calls
        (bool success, ) = to.call{value: value}("");
        require(success, "native token transfer failed");
    }

    /// @dev Transfers `amount` of native token to `to`. (With native token wrapping)
    function safeTransferNativeTokenWithWrapper(
        address to,
        uint256 value,
        address _nativeTokenWrapper
    ) internal {
        // solhint-disable avoid-low-level-calls
        // slither-disable-next-line low-level-calls
        (bool success, ) = to.call{value: value}("");
        if (!success) {
            IWETH(_nativeTokenWrapper).deposit{value: value}();
            IERC20(_nativeTokenWrapper).safeTransfer(to, value);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author goldnite

import "./EnglishAuctionsStorage.sol";

// ====== External imports ======
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

// ====== Internal imports ======

import "../../extension/plugin/ERC2771ContextConsumer.sol";

import "../../extension/interface/IPlatformFee.sol";

import "../../extension/plugin/ReentrancyGuardLogic.sol";
import "../../extension/plugin/PermissionsEnumerableLogic.sol";
import { CurrencyTransferLib } from "../../lib/CurrencyTransferLib.sol";

/**
 * @author  goldnite
 */
contract EnglishAuctionsLogic is IEnglishAuctions, ReentrancyGuardLogic, ERC2771ContextConsumer {
    /*///////////////////////////////////////////////////////////////
                        Constants / Immutables
    //////////////////////////////////////////////////////////////*/

    /// @dev Only lister role holders can create auctions, when auctions are restricted by lister address.
    bytes32 private constant LISTER_ROLE = keccak256("LISTER_ROLE");
    /// @dev Only assets from NFT contracts with asset role can be auctioned, when auctions are restricted by asset address.
    bytes32 private constant ASSET_ROLE = keccak256("ASSET_ROLE");

    /// @dev The max bps of the contract. So, 10_000 == 100 %
    uint64 private constant MAX_BPS = 10_000;

    /// @dev The address of the native token wrapper contract.
    address private immutable nativeTokenWrapper;

    /*///////////////////////////////////////////////////////////////
                              Modifiers
    //////////////////////////////////////////////////////////////*/

    modifier onlyListerRole() {
        require(PermissionsLogic(address(this)).hasRoleWithSwitch(LISTER_ROLE, _msgSender()), "!LISTER_ROLE");
        _;
    }

    modifier onlyAssetRole(address _asset) {
        require(PermissionsLogic(address(this)).hasRoleWithSwitch(ASSET_ROLE, _asset), "!ASSET_ROLE");
        _;
    }

    /// @dev Checks whether caller is a auction creator.
    modifier onlyAuctionCreator(uint256 _auctionId) {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();

        require(data.auctions[_auctionId].auctionCreator == _msgSender(), "Marketplace: not auction creator.");
        _;
    }

    /// @dev Checks whether an auction exists.
    modifier onlyExistingAuction(uint256 _auctionId) {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();
        require(data.auctions[_auctionId].status == IEnglishAuctions.Status.CREATED, "Marketplace: invalid auction.");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            Constructor logic
    //////////////////////////////////////////////////////////////*/

    constructor(address _nativeTokenWrapper) {
        nativeTokenWrapper = _nativeTokenWrapper;
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Auction ERC721 or ERC1155 NFTs.
    function createAuction(AuctionParameters calldata _params)
        external
        onlyListerRole
        onlyAssetRole(_params.assetContract)
        returns (uint256 auctionId)
    {
        auctionId = _getNextAuctionId();
        address auctionCreator = _msgSender();
        TokenType tokenType = _getTokenType(_params.assetContract);

        _validateNewAuction(_params, tokenType);

        Auction memory auction = Auction({
            auctionId: auctionId,
            auctionCreator: auctionCreator,
            assetContract: _params.assetContract,
            tokenId: _params.tokenId,
            quantity: _params.quantity,
            currency: _params.currency,
            minimumBidAmount: _params.minimumBidAmount,
            buyoutBidAmount: _params.buyoutBidAmount,
            timeBufferInSeconds: _params.timeBufferInSeconds,
            bidBufferBps: _params.bidBufferBps,
            startTimestamp: _params.startTimestamp,
            endTimestamp: _params.endTimestamp,
            tokenType: tokenType,
            status: IEnglishAuctions.Status.CREATED
        });

        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();
        data.auctions[auctionId] = auction;

        _transferAuctionTokens(auctionCreator, address(this), auction);

        emit NewAuction(auctionCreator, auctionId, _params.assetContract, auction);
    }

    function bidInAuction(uint256 _auctionId, uint256 _bidAmount)
        external
        payable
        nonReentrant
        onlyExistingAuction(_auctionId)
    {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();
        Auction memory _targetAuction = data.auctions[_auctionId];

        require(
            _targetAuction.endTimestamp > block.timestamp && _targetAuction.startTimestamp <= block.timestamp,
            "Marketplace: inactive auction."
        );
        require(_bidAmount != 0, "Marketplace: Bidding with zero amount.");

        Bid memory newBid = Bid({ auctionId: _auctionId, bidder: _msgSender(), bidAmount: _bidAmount });

        _handleBid(_targetAuction, newBid);
    }

    function collectAuctionPayout(uint256 _auctionId) external nonReentrant onlyAuctionCreator(_auctionId) {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();

        require(!data.payoutStatus[_auctionId].paidOutBidAmount, "Marketplace: payout already completed.");
        data.payoutStatus[_auctionId].paidOutBidAmount = true;

        Auction memory _targetAuction = data.auctions[_auctionId];
        Bid memory _winningBid = data.winningBid[_auctionId];

        require(_targetAuction.status != IEnglishAuctions.Status.CANCELLED, "Marketplace: invalid auction.");
        require(_targetAuction.endTimestamp <= block.timestamp, "Marketplace: auction still active.");
        require(_winningBid.bidder != address(0), "Marketplace: no bids were made.");

        _closeAuctionForAuctionCreator(_targetAuction, _winningBid);

        if (_targetAuction.status != IEnglishAuctions.Status.COMPLETED) {
            data.auctions[_auctionId].status = IEnglishAuctions.Status.COMPLETED;
        }
    }

    function collectAuctionTokens(uint256 _auctionId) external nonReentrant {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();
        Auction memory _targetAuction = data.auctions[_auctionId];
        Bid memory _winningBid = data.winningBid[_auctionId];

        require(_targetAuction.status != IEnglishAuctions.Status.CANCELLED, "Marketplace: invalid auction.");
        require(_targetAuction.endTimestamp <= block.timestamp, "Marketplace: auction still active.");
        require(_winningBid.bidder != address(0), "Marketplace: no bids were made.");

        _closeAuctionForBidder(_targetAuction, _winningBid);

        if (_targetAuction.status != IEnglishAuctions.Status.COMPLETED) {
            data.auctions[_auctionId].status = IEnglishAuctions.Status.COMPLETED;
        }
    }

    /// @dev Cancels an auction.
    function cancelAuction(uint256 _auctionId) external onlyExistingAuction(_auctionId) onlyAuctionCreator(_auctionId) {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();
        Auction memory _targetAuction = data.auctions[_auctionId];
        Bid memory _winningBid = data.winningBid[_auctionId];

        require(_winningBid.bidder == address(0), "Marketplace: bids already made.");

        data.auctions[_auctionId].status = IEnglishAuctions.Status.CANCELLED;

        _transferAuctionTokens(address(this), _targetAuction.auctionCreator, _targetAuction);

        emit CancelledAuction(_targetAuction.auctionCreator, _auctionId);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    function isNewWinningBid(uint256 _auctionId, uint256 _bidAmount)
        external
        view
        onlyExistingAuction(_auctionId)
        returns (bool)
    {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();
        Auction memory _targetAuction = data.auctions[_auctionId];
        Bid memory _currentWinningBid = data.winningBid[_auctionId];

        return
            _isNewWinningBid(
                _targetAuction.minimumBidAmount,
                _currentWinningBid.bidAmount,
                _bidAmount,
                _targetAuction.bidBufferBps
            );
    }

    function totalAuctions() external view returns (uint256) {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();
        return data.totalAuctions;
    }

    function getAuction(uint256 _auctionId) external view returns (Auction memory _auction) {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();
        _auction = data.auctions[_auctionId];
    }

    function getAllAuctions(uint256 _startId, uint256 _endId) external view returns (Auction[] memory _allAuctions) {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();
        require(_startId <= _endId && _endId < data.totalAuctions, "invalid range");

        _allAuctions = new Auction[](_endId - _startId + 1);

        for (uint256 i = _startId; i <= _endId; i += 1) {
            _allAuctions[i - _startId] = data.auctions[i];
        }
    }

    function getAllValidAuctions(uint256 _startId, uint256 _endId)
        external
        view
        returns (Auction[] memory _validAuctions)
    {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();
        require(_startId <= _endId && _endId < data.totalAuctions, "invalid range");

        Auction[] memory _auctions = new Auction[](_endId - _startId + 1);
        uint256 _auctionCount;

        for (uint256 i = _startId; i <= _endId; i += 1) {
            uint256 j = i - _startId;
            _auctions[j] = data.auctions[i];
            if (
                _auctions[j].startTimestamp <= block.timestamp &&
                _auctions[j].endTimestamp > block.timestamp &&
                _auctions[j].status == IEnglishAuctions.Status.CREATED &&
                _auctions[j].assetContract != address(0)
            ) {
                _auctionCount += 1;
            }
        }

        _validAuctions = new Auction[](_auctionCount);
        uint256 index = 0;
        uint256 count = _auctions.length;
        for (uint256 i = 0; i < count; i += 1) {
            if (
                _auctions[i].startTimestamp <= block.timestamp &&
                _auctions[i].endTimestamp > block.timestamp &&
                _auctions[i].status == IEnglishAuctions.Status.CREATED &&
                _auctions[i].assetContract != address(0)
            ) {
                _validAuctions[index++] = _auctions[i];
            }
        }
    }

    function getWinningBid(uint256 _auctionId)
        external
        view
        onlyExistingAuction(_auctionId)
        returns (
            address _bidder,
            address _currency,
            uint256 _bidAmount
        )
    {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();
        Auction memory _targetAuction = data.auctions[_auctionId];
        Bid memory _currentWinningBid = data.winningBid[_auctionId];

        _bidder = _currentWinningBid.bidder;
        _currency = _targetAuction.currency;
        _bidAmount = _currentWinningBid.bidAmount;
    }

    function isAuctionExpired(uint256 _auctionId) external view onlyExistingAuction(_auctionId) returns (bool) {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();
        return data.auctions[_auctionId].endTimestamp >= block.timestamp;
    }

    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the next auction Id.
    function _getNextAuctionId() internal returns (uint256 id) {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();
        id = data.totalAuctions;
        data.totalAuctions += 1;
    }

    /// @dev Returns the interface supported by a contract.
    function _getTokenType(address _assetContract) internal view returns (TokenType tokenType) {
        if (IERC165(_assetContract).supportsInterface(type(IERC1155).interfaceId)) {
            tokenType = TokenType.ERC1155;
        } else if (IERC165(_assetContract).supportsInterface(type(IERC721).interfaceId)) {
            tokenType = TokenType.ERC721;
        } else {
            revert("Marketplace: auctioned token must be ERC1155 or ERC721.");
        }
    }

    /// @dev Checks whether the auction creator owns and has approved marketplace to transfer auctioned tokens.
    function _validateNewAuction(AuctionParameters memory _params, TokenType _tokenType) internal view {
        require(_params.quantity > 0, "Marketplace: auctioning zero quantity.");
        require(_params.quantity == 1 || _tokenType == TokenType.ERC1155, "Marketplace: auctioning invalid quantity.");
        require(_params.timeBufferInSeconds > 0, "Marketplace: no time-buffer.");
        require(_params.bidBufferBps > 0, "Marketplace: no bid-buffer.");
        require(
            _params.startTimestamp + 60 minutes >= block.timestamp && _params.startTimestamp < _params.endTimestamp,
            "Marketplace: invalid timestamps."
        );
        require(
            _params.buyoutBidAmount == 0 || _params.buyoutBidAmount >= _params.minimumBidAmount,
            "Marketplace: invalid bid amounts."
        );
    }

    /// @dev Processes an incoming bid in an auction.
    function _handleBid(Auction memory _targetAuction, Bid memory _incomingBid) internal {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();
        Bid memory currentWinningBid = data.winningBid[_targetAuction.auctionId];
        uint256 currentBidAmount = currentWinningBid.bidAmount;
        uint256 incomingBidAmount = _incomingBid.bidAmount;
        address _nativeTokenWrapper = nativeTokenWrapper;

        // Close auction and execute sale if there's a buyout price and incoming bid amount is buyout price.
        if (_targetAuction.buyoutBidAmount > 0 && incomingBidAmount >= _targetAuction.buyoutBidAmount) {
            incomingBidAmount = _targetAuction.buyoutBidAmount;

            _closeAuctionForBidder(_targetAuction, _incomingBid);
        } else {
            /**
             *      If there's an exisitng winning bid, incoming bid amount must be bid buffer % greater.
             *      Else, bid amount must be at least as great as minimum bid amount
             */
            require(
                _isNewWinningBid(
                    _targetAuction.minimumBidAmount,
                    currentBidAmount,
                    incomingBidAmount,
                    _targetAuction.bidBufferBps
                ),
                "Marketplace: not winning bid."
            );

            // Update the winning bid and auction's end time before external contract calls.
            data.winningBid[_targetAuction.auctionId] = _incomingBid;

            if (_targetAuction.endTimestamp - block.timestamp <= _targetAuction.timeBufferInSeconds) {
                _targetAuction.endTimestamp += _targetAuction.timeBufferInSeconds;
                data.auctions[_targetAuction.auctionId] = _targetAuction;
            }
        }

        // Payout previous highest bid.
        if (currentWinningBid.bidder != address(0) && currentBidAmount > 0) {
            CurrencyTransferLib.transferCurrencyWithWrapper(
                _targetAuction.currency,
                address(this),
                currentWinningBid.bidder,
                currentBidAmount,
                _nativeTokenWrapper
            );
        }

        // Collect incoming bid
        CurrencyTransferLib.transferCurrencyWithWrapper(
            _targetAuction.currency,
            _incomingBid.bidder,
            address(this),
            incomingBidAmount,
            _nativeTokenWrapper
        );

        emit NewBid(
            _targetAuction.auctionId,
            _incomingBid.bidder,
            _targetAuction.assetContract,
            _incomingBid.bidAmount,
            _targetAuction
        );
    }

    /// @dev Checks whether an incoming bid is the new current highest bid.
    function _isNewWinningBid(
        uint256 _minimumBidAmount,
        uint256 _currentWinningBidAmount,
        uint256 _incomingBidAmount,
        uint256 _bidBufferBps
    ) internal pure returns (bool isValidNewBid) {
        if (_currentWinningBidAmount == 0) {
            isValidNewBid = _incomingBidAmount >= _minimumBidAmount;
        } else {
            isValidNewBid = (_incomingBidAmount > _currentWinningBidAmount &&
                ((_incomingBidAmount - _currentWinningBidAmount) * MAX_BPS) / _currentWinningBidAmount >=
                _bidBufferBps);
        }
    }

    /// @dev Closes an auction for the winning bidder; distributes auction items to the winning bidder.
    function _closeAuctionForBidder(Auction memory _targetAuction, Bid memory _winningBid) internal {
        EnglishAuctionsStorage.Data storage data = EnglishAuctionsStorage.englishAuctionsStorage();

        require(
            !data.payoutStatus[_targetAuction.auctionId].paidOutAuctionTokens,
            "Marketplace: payout already completed."
        );
        data.payoutStatus[_targetAuction.auctionId].paidOutAuctionTokens = true;

        _targetAuction.endTimestamp = uint64(block.timestamp);

        data.winningBid[_targetAuction.auctionId] = _winningBid;
        data.auctions[_targetAuction.auctionId] = _targetAuction;

        _transferAuctionTokens(address(this), _winningBid.bidder, _targetAuction);

        emit AuctionClosed(
            _targetAuction.auctionId,
            _targetAuction.assetContract,
            _msgSender(),
            _targetAuction.tokenId,
            _targetAuction.auctionCreator,
            _winningBid.bidder
        );
    }

    /// @dev Closes an auction for an auction creator; distributes winning bid amount to auction creator.
    function _closeAuctionForAuctionCreator(Auction memory _targetAuction, Bid memory _winningBid) internal {
        uint256 payoutAmount = _winningBid.bidAmount;
        _payout(address(this), _targetAuction.auctionCreator, _targetAuction.currency, payoutAmount, _targetAuction);

        emit AuctionClosed(
            _targetAuction.auctionId,
            _targetAuction.assetContract,
            _msgSender(),
            _targetAuction.tokenId,
            _targetAuction.auctionCreator,
            _winningBid.bidder
        );
    }

    /// @dev Transfers tokens for auction.
    function _transferAuctionTokens(
        address _from,
        address _to,
        Auction memory _auction
    ) internal {
        if (_auction.tokenType == TokenType.ERC1155) {
            IERC1155(_auction.assetContract).safeTransferFrom(_from, _to, _auction.tokenId, _auction.quantity, "");
        } else if (_auction.tokenType == TokenType.ERC721) {
            IERC721(_auction.assetContract).safeTransferFrom(_from, _to, _auction.tokenId, "");
        }
    }

    /// @dev Pays out stakeholders in auction.
    function _payout(
        address _payer,
        address _payee,
        address _currencyToUse,
        uint256 _totalPayoutAmount,
        Auction memory _targetAuction
    ) internal {
        (address platformFeeRecipient, uint16 platformFeeBps) = IPlatformFee(address(this)).getPlatformFeeInfo();
        uint256 platformFeeCut = (_totalPayoutAmount * platformFeeBps) / MAX_BPS;

        uint256 royaltyCut;
        address royaltyRecipient;

        // Distribute royalties. See Sushiswap's https://github.com/sushiswap/shoyu/blob/master/contracts/base/BaseExchange.sol#L296
        try IERC2981(_targetAuction.assetContract).royaltyInfo(_targetAuction.tokenId, _totalPayoutAmount) returns (
            address royaltyFeeRecipient,
            uint256 royaltyFeeAmount
        ) {
            if (royaltyFeeRecipient != address(0) && royaltyFeeAmount > 0) {
                require(royaltyFeeAmount + platformFeeCut <= _totalPayoutAmount, "fees exceed the price");
                royaltyRecipient = royaltyFeeRecipient;
                royaltyCut = royaltyFeeAmount;
            }
        } catch {}

        // Distribute price to token owner
        address _nativeTokenWrapper = nativeTokenWrapper;

        CurrencyTransferLib.transferCurrencyWithWrapper(
            _currencyToUse,
            _payer,
            platformFeeRecipient,
            platformFeeCut,
            _nativeTokenWrapper
        );
        CurrencyTransferLib.transferCurrencyWithWrapper(
            _currencyToUse,
            _payer,
            royaltyRecipient,
            royaltyCut,
            _nativeTokenWrapper
        );
        CurrencyTransferLib.transferCurrencyWithWrapper(
            _currencyToUse,
            _payer,
            _payee,
            _totalPayoutAmount - (platformFeeCut + royaltyCut),
            _nativeTokenWrapper
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author goldnite

import { IEnglishAuctions } from "../IMarketplace.sol";

/**
 * @author  goldnite
 */
library EnglishAuctionsStorage {
    bytes32 public constant ENGLISH_AUCTIONS_STORAGE_POSITION = keccak256("english.auctions.storage");

    struct Data {
        uint256 totalAuctions;
        mapping(uint256 => IEnglishAuctions.Auction) auctions;
        mapping(uint256 => IEnglishAuctions.Bid) winningBid;
        mapping(uint256 => IEnglishAuctions.AuctionPayoutStatus) payoutStatus;
    }

    function englishAuctionsStorage() internal pure returns (Data storage englishAuctionsData) {
        bytes32 position = ENGLISH_AUCTIONS_STORAGE_POSITION;
        assembly {
            englishAuctionsData.slot := position
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author goldnite

/**
 *  @author  goldnite
 *
 *  The `DirectListings` extension smart contract lets you buy and sell NFTs (ERC-721 or ERC-1155) for a fixed price.
 */
interface IDirectListings {
    enum TokenType {
        ERC721,
        ERC1155
    }

    enum Status {
        UNSET,
        CREATED,
        COMPLETED,
        CANCELLED
    }

    /**
     *  @notice The parameters a seller sets when creating or updating a listing.
     *
     *  @param assetContract The address of the smart contract of the NFTs being listed.
     *  @param tokenId The tokenId of the NFTs being listed.
     *  @param quantity The quantity of NFTs being listed. This must be non-zero, and is expected to
     *                  be `1` for ERC-721 NFTs.
     *  @param currency The currency in which the price must be paid when buying the listed NFTs.
     *  @param pricePerToken The price to pay per unit of NFTs listed.
     *  @param startTimestamp The UNIX timestamp at and after which NFTs can be bought from the listing.
     *  @param endTimestamp The UNIX timestamp at and after which NFTs cannot be bought from the listing.
     *  @param reserved Whether the listing is reserved to be bought from a specific set of buyers.
     */
    struct ListingParameters {
        address assetContract;
        uint256 tokenId;
        uint256 quantity;
        address currency;
        uint256 pricePerToken;
        uint128 startTimestamp;
        uint128 endTimestamp;
        bool reserved;
    }

    /**
     *  @notice The information stored for a listing.
     *
     *  @param listingId The unique ID of the listing.
     *  @param listingCreator The creator of the listing.
     *  @param assetContract The address of the smart contract of the NFTs being listed.
     *  @param tokenId The tokenId of the NFTs being listed.
     *  @param quantity The quantity of NFTs being listed. This must be non-zero, and is expected to
     *                  be `1` for ERC-721 NFTs.
     *  @param currency The currency in which the price must be paid when buying the listed NFTs.
     *  @param pricePerToken The price to pay per unit of NFTs listed.
     *  @param startTimestamp The UNIX timestamp at and after which NFTs can be bought from the listing.
     *  @param endTimestamp The UNIX timestamp at and after which NFTs cannot be bought from the listing.
     *  @param reserved Whether the listing is reserved to be bought from a specific set of buyers.
     *  @param tokenType The type of token listed (ERC-721 or ERC-1155)
     */
    struct Listing {
        uint256 listingId;
        address listingCreator;
        address assetContract;
        uint256 tokenId;
        uint256 quantity;
        address currency;
        uint256 pricePerToken;
        uint128 startTimestamp;
        uint128 endTimestamp;
        bool reserved;
        TokenType tokenType;
        Status status;
    }

    /// @notice Emitted when a new listing is created.
    event NewListing(
        address indexed listingCreator,
        uint256 indexed listingId,
        address indexed assetContract,
        Listing listing
    );

    /// @notice Emitted when a listing is updated.
    event UpdatedListing(
        address indexed listingCreator,
        uint256 indexed listingId,
        address indexed assetContract,
        Listing listing
    );

    /// @notice Emitted when a listing is cancelled.
    event CancelledListing(
        address indexed listingCreator,
        uint256 indexed listingId
    );

    /// @notice Emitted when a buyer is approved to buy from a reserved listing.
    event BuyerApprovedForListing(
        uint256 indexed listingId,
        address indexed buyer,
        bool approved
    );

    /// @notice Emitted when a currency is approved as a form of payment for the listing.
    event CurrencyApprovedForListing(
        uint256 indexed listingId,
        address indexed currency,
        uint256 pricePerToken
    );

    /// @notice Emitted when NFTs are bought from a listing.
    event NewSale(
        address indexed listingCreator,
        uint256 indexed listingId,
        address indexed assetContract,
        uint256 tokenId,
        address buyer,
        uint256 quantityBought,
        uint256 totalPricePaid
    );

    /**
     *  @notice List NFTs (ERC721 or ERC1155) for sale at a fixed price.
     *
     *  @param _params The parameters of a listing a seller sets when creating a listing.
     *
     *  @return listingId The unique integer ID of the listing.
     */
    function createListing(
        ListingParameters memory _params
    ) external returns (uint256 listingId);

    /**
     *  @notice Update parameters of a listing of NFTs.
     *
     *  @param _listingId The ID of the listing to update.
     *  @param _params The parameters of a listing a seller sets when updating a listing.
     */
    function updateListing(
        uint256 _listingId,
        ListingParameters memory _params
    ) external;

    /**
     *  @notice Cancel a listing.
     *
     *  @param _listingId The ID of the listing to cancel.
     */
    function cancelListing(uint256 _listingId) external;

    /**
     *  @notice Approve a buyer to buy from a reserved listing.
     *
     *  @param _listingId The ID of the listing to update.
     *  @param _buyer The address of the buyer to approve to buy from the listing.
     *  @param _toApprove Whether to approve the buyer to buy from the listing.
     */
    function approveBuyerForListing(
        uint256 _listingId,
        address _buyer,
        bool _toApprove
    ) external;

    /**
     *  @notice Approve a currency as a form of payment for the listing.
     *
     *  @param _listingId The ID of the listing to update.
     *  @param _currency The address of the currency to approve as a form of payment for the listing.
     *  @param _pricePerTokenInCurrency The price per token for the currency to approve.
     */
    function approveCurrencyForListing(
        uint256 _listingId,
        address _currency,
        uint256 _pricePerTokenInCurrency
    ) external;

    /**
     *  @notice Buy NFTs from a listing.
     *
     *  @param _listingId The ID of the listing to update.
     *  @param _buyFor The recipient of the NFTs being bought.
     *  @param _quantity The quantity of NFTs to buy from the listing.
     *  @param _currency The currency to use to pay for NFTs.
     *  @param _expectedTotalPrice The expected total price to pay for the NFTs being bought.
     */
    function buyFromListing(
        uint256 _listingId,
        address _buyFor,
        uint256 _quantity,
        address _currency,
        uint256 _expectedTotalPrice
    ) external payable;

    /**
     *  @notice Returns the total number of listings created.
     *  @dev At any point, the return value is the ID of the next listing created.
     */
    function totalListings() external view returns (uint256);

    /// @notice Returns all listings between the start and end Id (both inclusive) provided.
    function getAllListings(
        uint256 _startId,
        uint256 _endId
    ) external view returns (Listing[] memory listings);

    /**
     *  @notice Returns all valid listings between the start and end Id (both inclusive) provided.
     *          A valid listing is where the listing creator still owns and has approved Marketplace
     *          to transfer the listed NFTs.
     */
    function getAllValidListings(
        uint256 _startId,
        uint256 _endId
    ) external view returns (Listing[] memory listings);

    /**
     *  @notice Returns a listing at the provided listing ID.
     *
     *  @param _listingId The ID of the listing to fetch.
     */
    function getListing(
        uint256 _listingId
    ) external view returns (Listing memory listing);
}

/**
 *  The `EnglishAuctions` extension smart contract lets you sell NFTs (ERC-721 or ERC-1155) in an english auction.
 */

interface IEnglishAuctions {
    enum TokenType {
        ERC721,
        ERC1155
    }

    enum Status {
        UNSET,
        CREATED,
        COMPLETED,
        CANCELLED
    }

    /**
     *  @notice The parameters a seller sets when creating an auction listing.
     *
     *  @param assetContract The address of the smart contract of the NFTs being auctioned.
     *  @param tokenId The tokenId of the NFTs being auctioned.
     *  @param quantity The quantity of NFTs being auctioned. This must be non-zero, and is expected to
     *                  be `1` for ERC-721 NFTs.
     *  @param currency The currency in which the bid must be made when bidding for the auctioned NFTs.
     *  @param minimumBidAmount The minimum bid amount for the auction.
     *  @param buyoutBidAmount The total bid amount for which the bidder can directly purchase the auctioned items and close the auction as a result.
     *  @param timeBufferInSeconds This is a buffer e.g. x seconds. If a new winning bid is made less than x seconds before expirationTimestamp, the
     *                             expirationTimestamp is increased by x seconds.
     *  @param bidBufferBps This is a buffer in basis points e.g. x%. To be considered as a new winning bid, a bid must be at least x% greater than
     *                      the current winning bid.
     *  @param startTimestamp The timestamp at and after which bids can be made to the auction
     *  @param endTimestamp The timestamp at and after which bids cannot be made to the auction.
     */
    struct AuctionParameters {
        address assetContract;
        uint256 tokenId;
        uint256 quantity;
        address currency;
        uint256 minimumBidAmount;
        uint256 buyoutBidAmount;
        uint64 timeBufferInSeconds;
        uint64 bidBufferBps;
        uint64 startTimestamp;
        uint64 endTimestamp;
    }

    /**
     *  @notice The information stored for an auction.
     *
     *  @param auctionId The unique ID of the auction.
     *  @param auctionCreator The creator of the auction.
     *  @param assetContract The address of the smart contract of the NFTs being auctioned.
     *  @param tokenId The tokenId of the NFTs being auctioned.
     *  @param quantity The quantity of NFTs being auctioned. This must be non-zero, and is expected to
     *                  be `1` for ERC-721 NFTs.
     *  @param currency The currency in which the bid must be made when bidding for the auctioned NFTs.
     *  @param minimumBidAmount The minimum bid amount for the auction.
     *  @param buyoutBidAmount The total bid amount for which the bidder can directly purchase the auctioned items and close the auction as a result.
     *  @param timeBufferInSeconds This is a buffer e.g. x seconds. If a new winning bid is made less than x seconds before expirationTimestamp, the
     *                             expirationTimestamp is increased by x seconds.
     *  @param bidBufferBps This is a buffer in basis points e.g. x%. To be considered as a new winning bid, a bid must be at least x% greater than
     *                      the current winning bid.
     *  @param startTimestamp The timestamp at and after which bids can be made to the auction
     *  @param endTimestamp The timestamp at and after which bids cannot be made to the auction.
     *  @param tokenType The type of NFTs auctioned (ERC-721 or ERC-1155)
     */
    struct Auction {
        uint256 auctionId;
        address auctionCreator;
        address assetContract;
        uint256 tokenId;
        uint256 quantity;
        address currency;
        uint256 minimumBidAmount;
        uint256 buyoutBidAmount;
        uint64 timeBufferInSeconds;
        uint64 bidBufferBps;
        uint64 startTimestamp;
        uint64 endTimestamp;
        TokenType tokenType;
        Status status;
    }

    /**
     *  @notice The information stored for a bid made in an auction.
     *
     *  @param auctionId The unique ID of the auction.
     *  @param bidder The address of the bidder.
     *  @param bidAmount The total bid amount (in the currency specified by the auction).
     */
    struct Bid {
        uint256 auctionId;
        address bidder;
        uint256 bidAmount;
    }

    struct AuctionPayoutStatus {
        bool paidOutAuctionTokens;
        bool paidOutBidAmount;
    }

    /// @dev Emitted when a new auction is created.
    event NewAuction(
        address indexed auctionCreator,
        uint256 indexed auctionId,
        address indexed assetContract,
        Auction auction
    );

    /// @dev Emitted when a new bid is made in an auction.
    event NewBid(
        uint256 indexed auctionId,
        address indexed bidder,
        address indexed assetContract,
        uint256 bidAmount,
        Auction auction
    );

    /// @notice Emitted when a auction is cancelled.
    event CancelledAuction(
        address indexed auctionCreator,
        uint256 indexed auctionId
    );

    /// @dev Emitted when an auction is closed.
    event AuctionClosed(
        uint256 indexed auctionId,
        address indexed assetContract,
        address indexed closer,
        uint256 tokenId,
        address auctionCreator,
        address winningBidder
    );

    /**
     *  @notice Put up NFTs (ERC721 or ERC1155) for an english auction.
     *
     *  @param _params The parameters of an auction a seller sets when creating an auction.
     *
     *  @return auctionId The unique integer ID of the auction.
     */
    function createAuction(
        AuctionParameters memory _params
    ) external returns (uint256 auctionId);

    /**
     *  @notice Cancel an auction.
     *
     *  @param _auctionId The ID of the auction to cancel.
     */
    function cancelAuction(uint256 _auctionId) external;

    /**
     *  @notice Distribute the winning bid amount to the auction creator.
     *
     *  @param _auctionId The ID of an auction.
     */
    function collectAuctionPayout(uint256 _auctionId) external;

    /**
     *  @notice Distribute the auctioned NFTs to the winning bidder.
     *
     *  @param _auctionId The ID of an auction.
     */
    function collectAuctionTokens(uint256 _auctionId) external;

    /**
     *  @notice Bid in an active auction.
     *
     *  @param _auctionId The ID of the auction to bid in.
     *  @param _bidAmount The bid amount in the currency specified by the auction.
     */
    function bidInAuction(
        uint256 _auctionId,
        uint256 _bidAmount
    ) external payable;

    /**
     *  @notice Returns whether a given bid amount would make for a winning bid in an auction.
     *
     *  @param _auctionId The ID of an auction.
     *  @param _bidAmount The bid amount to check.
     */
    function isNewWinningBid(
        uint256 _auctionId,
        uint256 _bidAmount
    ) external view returns (bool);

    /// @notice Returns the auction of the provided auction ID.
    function getAuction(
        uint256 _auctionId
    ) external view returns (Auction memory auction);

    /// @notice Returns all non-cancelled auctions.
    function getAllAuctions(
        uint256 _startId,
        uint256 _endId
    ) external view returns (Auction[] memory auctions);

    /// @notice Returns all active auctions.
    function getAllValidAuctions(
        uint256 _startId,
        uint256 _endId
    ) external view returns (Auction[] memory auctions);

    /// @notice Returns the winning bid of an active auction.
    function getWinningBid(
        uint256 _auctionId
    )
        external
        view
        returns (address bidder, address currency, uint256 bidAmount);

    /// @notice Returns whether an auction is active.
    function isAuctionExpired(uint256 _auctionId) external view returns (bool);
}

/**
 *  The `Offers` extension smart contract lets you make and accept offers made for NFTs (ERC-721 or ERC-1155).
 */

interface IOffers {
    enum TokenType {
        ERC721,
        ERC1155,
        ERC20
    }

    enum Status {
        UNSET,
        CREATED,
        COMPLETED,
        CANCELLED
    }

    /**
     *  @notice The parameters an offeror sets when making an offer for NFTs.
     *
     *  @param assetContract The contract of the NFTs for which the offer is being made.
     *  @param tokenId The tokenId of the NFT for which the offer is being made.
     *  @param quantity The quantity of NFTs wanted.
     *  @param currency The currency offered for the NFTs.
     *  @param totalPrice The total offer amount for the NFTs.
     *  @param expirationTimestamp The timestamp at and after which the offer cannot be accepted.
     */
    struct OfferParams {
        address assetContract;
        uint256 tokenId;
        uint256 quantity;
        address currency;
        uint256 totalPrice;
        uint256 expirationTimestamp;
    }

    /**
     *  @notice The information stored for the offer made.
     *
     *  @param offerId The ID of the offer.
     *  @param offeror The address of the offeror.
     *  @param assetContract The contract of the NFTs for which the offer is being made.
     *  @param tokenId The tokenId of the NFT for which the offer is being made.
     *  @param quantity The quantity of NFTs wanted.
     *  @param currency The currency offered for the NFTs.
     *  @param totalPrice The total offer amount for the NFTs.
     *  @param expirationTimestamp The timestamp at and after which the offer cannot be accepted.
     *  @param tokenType The type of token (ERC-721 or ERC-1155) the offer is made for.
     */
    struct Offer {
        uint256 offerId;
        address offeror;
        address assetContract;
        uint256 tokenId;
        uint256 quantity;
        address currency;
        uint256 totalPrice;
        uint256 expirationTimestamp;
        TokenType tokenType;
        Status status;
    }

    /// @dev Emitted when a new offer is created.
    event NewOffer(
        address indexed offeror,
        uint256 indexed offerId,
        address indexed assetContract,
        Offer offer
    );

    /// @dev Emitted when an offer is cancelled.
    event CancelledOffer(address indexed offeror, uint256 indexed offerId);

    /// @dev Emitted when an offer is accepted.
    event AcceptedOffer(
        address indexed offeror,
        uint256 indexed offerId,
        address indexed assetContract,
        uint256 tokenId,
        address seller,
        uint256 quantityBought,
        uint256 totalPricePaid
    );

    /**
     *  @notice Make an offer for NFTs (ERC-721 or ERC-1155)
     *
     *  @param _params The parameters of an offer.
     *
     *  @return offerId The unique integer ID assigned to the offer.
     */
    function makeOffer(
        OfferParams memory _params
    ) external returns (uint256 offerId);

    /**
     *  @notice Cancel an offer.
     *
     *  @param _offerId The ID of the offer to cancel.
     */
    function cancelOffer(uint256 _offerId) external;

    /**
     *  @notice Accept an offer.
     *
     *  @param _offerId The ID of the offer to accept.
     */
    function acceptOffer(uint256 _offerId) external;

    /// @notice Returns an offer for the given offer ID.
    function getOffer(
        uint256 _offerId
    ) external view returns (Offer memory offer);

    /// @notice Returns all active (i.e. non-expired or cancelled) offers.
    function getAllOffers(
        uint256 _startId,
        uint256 _endId
    ) external view returns (Offer[] memory offers);

    /// @notice Returns all valid offers. An offer is valid if the offeror owns and has approved Marketplace to transfer the offer amount of currency.
    function getAllValidOffers(
        uint256 _startId,
        uint256 _endId
    ) external view returns (Offer[] memory offers);
}