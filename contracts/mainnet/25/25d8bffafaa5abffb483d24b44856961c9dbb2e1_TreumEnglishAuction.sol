/**
 *Submitted for verification at polygonscan.com on 2022-03-08
*/

pragma solidity 0.8.9;


// SPDX-License-Identifier: MIT
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

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

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

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

/**
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
     * by making the `nonReentrant` function external, and make it call a
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

interface IWRAPPED {
    function deposit() external payable;

    function withdraw(uint256) external;

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
}

// this contract can be used in L2s. Wrapped on mainnet eth is WETH, on polygon is WMATIC
abstract contract WrappedNativeHelpers {
    using SafeERC20 for IERC20;
    address public wrappedAddress;

    function sendValueIfFailsSendWrapped(address payable user, uint256 amount) internal {
        require(amount > 0, "cannot send 0");

        // Cap the gas to prevent consuming all available gas to block a tx from completing successfully
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = user.call{ value: amount, gas: 60000 }("");
        if (!success) {
            // Send WETH instead
            wrap(amount);
            safeTransferWrappedTo(user, amount);
        }
    }

    function _setWrappedAddress(address wrappedNativeAssetAddress) internal {
        require(wrappedNativeAssetAddress != address(0), "zero address");
        wrappedAddress = wrappedNativeAssetAddress;
    }

    function safeTransferWrappedTo(address user, uint256 amount) internal {
        IERC20(wrappedAddress).safeTransferFrom(address(this), user, amount);
    }

    function unwrap(uint256 amount) internal {
        IWRAPPED(wrappedAddress).withdraw(amount);
    }

    function wrap(uint256 amount) internal {
        IWRAPPED(wrappedAddress).deposit{ value: amount }();
    }
}

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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * ERC20 based English auction contract for ERC721 and ERC1155 tokens.
 * - NFTs being auctioned are held in escrow, by this contract.
 * - All bids are held in escrow, by this contract.
 * - All bids placed for an auction are binding and cannot be rescinded.
 * - On being outbid, the previous winning bidder will be sent back their bid amount.
 * - Auctions in the wrapped native currency (WETH) can accept bids in the native currency, but on being outbid will be returned in WETH.
 * - On successful auctions, NFT is transfered to the buyer and all the funds are transferred to the auction fee recipients.
 * - Auctions can have multiple fee recipients with % allocations.
 * - There is no reserve price on auctions, rather a startingBid.
 */
contract TreumEnglishAuction is ERC721Holder, ERC1155Holder, ReentrancyGuard, WrappedNativeHelpers, Ownable {
    using SafeERC20 for IERC20;

    enum TokenType { ERC721, ERC1155 }

    struct Auction {
        uint256 tokenId;
        address tokenContract;
        TokenType tokenType;
        uint256 winningBidAmount;
        uint256 duration;
        uint256 startTime;
        uint256 startingBid;
        address seller;
        address winningBidder;
        address paymentCurrency;
        uint256 extensionWindow;
        uint256 minBidIncrementBps;
        address[] feeRecipients;
        uint32[] feePercentages;
    }

    struct AuctionState {
        uint256 auctionEnd;
        uint256 previousBidAmount;
        address previousBidder;
    }

    struct SettlementState {
        bool tokenTransferred;
        bool paymentTransferred;
    }

    // auction id => auction.  deleted once an auction is successfully settled.
    mapping(uint256 => Auction) private auctionIdToAuction;

    // auction id => settlement state.  lives forever.
    mapping(uint256 => SettlementState) private auctionSettlementState;

    // start at one to avoid bad truthy checks
    uint256 private nextAuctionId = 1;

    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed seller,
        uint256 tokenId,
        address tokenContract,
        uint256 duration,
        uint256 indexed startTime,
        uint256 startingBid,
        address paymentCurrency,
        uint256 extensionWindow,
        uint256 minBidIncrementBps,
        address[] feeRecipients,
        uint32[] feePercentages
    );

    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount, bool extended);

    event AuctionSettled(uint256 indexed auctionId, address indexed seller, address indexed buyer);
    event AuctionCancelled(uint256 indexed auctionId);

    /**
     * Create a new auction contract with an optional ERC20 address for native currency (WETH).
     * Auctions created with the currency wrappedNativeAssetAddress will allow bids in either
     * the wrapped or native versions.  Passing the zero address will prevent bids in native currency.
     */
    constructor(address wrappedNativeAssetAddress) {
        if (wrappedNativeAssetAddress != address(0)) {
            _setWrappedAddress(wrappedNativeAssetAddress);
        }
    }

    /**
     * @notice Create an English auction
     * @param tokenId uint256 Token ID of the NFT to auction
     * @param tokenContract address Address of the NFT token contract
     * @param tokenType TokenType Either ERC721 or ERC1155
     * @param duration uint256 Length of the auction in seconds
     * @param startTime uint256 Start time of the auction in seconds
     * @param startingBid uint256 Minimum initial bid for the auction
     * @param paymentCurrency address Contract address of the token used to bid and pay with
     * @param extensionWindow uint256 Window where there must be no bids before auction ends, in seconds
     * @param minBidIncrementBps uint256 Each bid must be at least this % higher than the previous one
     * @param feeRecipients address[] Addresses of fee recipients
     * @param feePercentages uint32[] Percentages of winning bid paid to fee recipients, in basis points
     */
    function createAuction(
        uint256 tokenId,
        address tokenContract,
        TokenType tokenType,
        uint256 duration,
        uint256 startTime,
        uint256 startingBid,
        address paymentCurrency,
        uint256 extensionWindow,
        uint256 minBidIncrementBps,
        address[] memory feeRecipients,
        uint32[] memory feePercentages
    ) external {
        // Validate Auction config
        require(startTime < 10000000000, "enter an unix timestamp in seconds, not miliseconds");
        require(duration > 0, "invalid duration");
        require(startTime + duration >= block.timestamp, "start time + duration is before current time");
        require(startingBid > 0, "minimum starting bid not met");

        // Check fee lengths
        require(feeRecipients.length > 0, "at least 1 fee recipient is required");
        require(feeRecipients.length == feePercentages.length, "mismatched fee recipients and percentages");
        for (uint256 i = 0; i < feePercentages.length; i++) {
            require(feePercentages[i] > 0, "fee percentages cannot be zero");
        }

        uint256 auctionId = nextAuctionId;
        nextAuctionId += 1;

        // Check fee percentages add up to 100% (10000 basis points), use scope to limit variables
        {
            uint32 totalPercent;
            for (uint256 i = 0; i < feePercentages.length; i++) {
                totalPercent = totalPercent + feePercentages[i];
            }
            require(totalPercent == 10000, "fee percentages do not add up to 10000 basis points");
        }

        require(paymentCurrency != address(0), "must provide valid erc20 address");

        require(minBidIncrementBps <= 10000, "min bid increment % must be less or equal to 10000");

        auctionIdToAuction[auctionId] = Auction(
            tokenId,
            tokenContract,
            tokenType,
            0, // no bids yet so no winningBidAmount
            duration,
            startTime,
            startingBid,
            msg.sender,
            address(0), // no bids so no winningBidder
            paymentCurrency,
            extensionWindow,
            minBidIncrementBps,
            feeRecipients,
            feePercentages
        );

        emit AuctionCreated(
            auctionId,
            msg.sender,
            tokenId,
            tokenContract,
            duration,
            startTime,
            startingBid,
            paymentCurrency,
            extensionWindow,
            minBidIncrementBps,
            feeRecipients,
            feePercentages
        );

        transferNFT(msg.sender, address(this), tokenId, 1, tokenContract, tokenType);
    }

    /**
     * @notice Place bid on a running auction with an ERC20 token
     * @dev msg.value is bid amount when paying in ETH
     * @param auctionId uint256 Auction ID of the auction
     * @param bidAmount uint256 Amount of bid if non-eth currency
     */
    function placeBid(uint256 auctionId, uint256 bidAmount) public nonReentrant {
        requireValidAuction(auctionId);
        Auction storage auction = auctionIdToAuction[auctionId];

        (AuctionState memory auctionState, bool extended) = beforeBidPaymentTransfer(auction, bidAmount);

        // bid funds start in contract until auction over or outbid
        transferPayment(msg.sender, address(this), bidAmount, auction.paymentCurrency);

        afterBidPaymentTransfer(auctionState, bidAmount, extended, auctionId, auction.paymentCurrency);
    }

    /**
     * @notice Place bid on a running auction in the native currency
     * @dev msg.value is bid amount
     * @param auctionId uint256 Auction ID of the auction
     */
    function placeBidInEth(uint256 auctionId) public payable nonReentrant {
        requireValidAuction(auctionId);
        Auction storage auction = auctionIdToAuction[auctionId];
        require(auction.paymentCurrency == wrappedAddress, "Auction not in wrapped native currency");

        (AuctionState memory auctionState, bool extended) = beforeBidPaymentTransfer(auction, msg.value);

        // attempt to wrap native currency -> WETH
        wrap(msg.value);

        afterBidPaymentTransfer(auctionState, msg.value, extended, auctionId, auction.paymentCurrency);
    }

    /**
     * @notice Settle an auction to send NFT and tokens to correct parties. Anybody can call it.  This
     * is the normal flow that should be used after an auction is complete.
     * @param auctionId uint256 Id of the auction to settle.
     */
    function settleAuction(uint256 auctionId) external nonReentrant {
        Auction memory auction = getAuction(auctionId);
        require(isAuctionComplete(auctionId), "auction still in progess");

        SettlementState storage settlementState = auctionSettlementState[auctionId];

        delete auctionIdToAuction[auctionId];

        emit AuctionSettled(auctionId, auction.seller, auction.winningBidder);

        // no bidders
        if (auction.winningBidder == address(0)) {
            // transfer NFT to seller
            settlementState.paymentTransferred = true;
            if (!settlementState.tokenTransferred) {
                settlementState.tokenTransferred = true;

                transferNFT(
                    address(this),
                    auction.seller,
                    auction.tokenId,
                    1,
                    auction.tokenContract,
                    auction.tokenType
                );
            }
        } else {
            // transfer NFT to bidder, if not already done
            if (!settlementState.tokenTransferred) {
                settlementState.tokenTransferred = true;

                transferNFT(
                    address(this),
                    auction.winningBidder,
                    auction.tokenId,
                    1,
                    auction.tokenContract,
                    auction.tokenType
                );
            }

            if (!settlementState.paymentTransferred) {
                // transfer fees to fee recipients
                settlementState.paymentTransferred = true;
                transferAuctionPayment(auction);
            }
        }
    }

    /**
     * @notice Alternative way to settle the NFT side of an auction.  Only the winner can call this
     * function, and allows the winner to specify the address to transfer to.  This should only be used
     * if for some reason the settleAuction call fails.
     * @param auctionId uint256 Id of the auction to settle.
     */
    function settleAuctionNftToAddress(uint256 auctionId, address alternateAddress) external nonReentrant {
        Auction memory auction = getAuction(auctionId);
        require(isAuctionComplete(auctionId), "auction still in progess");
        require(auction.winningBidder != address(0), "no winning bidder");
        require(auction.winningBidder == msg.sender, "only winner");

        SettlementState storage settlementState = auctionSettlementState[auctionId];
        require(!settlementState.tokenTransferred, "NFT already transferred");

        bool fullySettled = false;
        if (settlementState.paymentTransferred) {
            // if payment has been transferred, and we're now transferring the token, the auction is
            // done, delete it
            fullySettled = true;
            delete auctionIdToAuction[auctionId];
        }

        settlementState.tokenTransferred = true;
        if (fullySettled) {
            emit AuctionSettled(auctionId, auction.seller, auction.winningBidder);
        }

        transferNFT(address(this), alternateAddress, auction.tokenId, 1, auction.tokenContract, auction.tokenType);
    }

    /**
     * @notice Alternative way to settle the payment side of an auction.  Only the seller can call this
     * function.  If for some reason the NFT cannot be transferred to the winning bidder and the settleAuction
     * call reverts, this will still allow the seller to get the payment.
     * @param auctionId uint256 Id of the auction to settle.
     */
    function settleAuctionPayment(uint256 auctionId) external nonReentrant {
        Auction memory auction = getAuction(auctionId);
        require(isAuctionComplete(auctionId), "auction still in progess");
        require(auction.winningBidder != address(0), "no winning bidder");
        require(auction.seller == msg.sender, "only seller");

        SettlementState storage settlementState = auctionSettlementState[auctionId];
        require(!settlementState.paymentTransferred, "Payment already transferred");

        bool fullySettled = false;
        if (settlementState.tokenTransferred) {
            // if payment has been transferred, and we're now transferring the token, the auction is
            // done, delete it
            fullySettled = true;
            delete auctionIdToAuction[auctionId];
        }

        settlementState.paymentTransferred = true;
        if (fullySettled) {
            emit AuctionSettled(auctionId, auction.seller, auction.winningBidder);
        }

        transferAuctionPayment(auction);
    }

    function isAuctionSettled(uint256 auctionId) external view returns (bool) {
        SettlementState storage settlementState = auctionSettlementState[auctionId];
        return settlementState.tokenTransferred && settlementState.paymentTransferred;
    }

    function isAuctionPaymentSettled(uint256 auctionId) external view returns (bool) {
        SettlementState storage settlementState = auctionSettlementState[auctionId];
        return settlementState.paymentTransferred;
    }

    function isAuctionNftSettled(uint256 auctionId) external view returns (bool) {
        SettlementState storage settlementState = auctionSettlementState[auctionId];
        return settlementState.tokenTransferred;
    }

    /**
     * @notice Cancel auction
     * @dev cannot cancel if auction has started and there are existing bids
     * @param auctionId uint256 Id of the auction the get details for
     */
    function cancelAuction(uint256 auctionId) external {
        Auction memory auction = getAuction(auctionId);
        // this also should cover if auction does not exist
        require(msg.sender == auction.seller, "only seller can cancel auction");
        require(auction.winningBidder == address(0), "cannot cancel auction has bidders");

        delete auctionIdToAuction[auctionId];

        emit AuctionCancelled(auctionId);

        // transfer NFT to seller
        transferNFT(address(this), auction.seller, auction.tokenId, 1, auction.tokenContract, auction.tokenType);
    }

    /**
     * @notice Returns auction details for a given auctionId.
     * @param auctionId uint256 Id of the auction the get details for
     */
    function getAuction(uint256 auctionId) public view returns (Auction memory) {
        requireValidAuction(auctionId);
        return auctionIdToAuction[auctionId];
    }

    //////////////////////////
    // INTERNAL FUNCTIONS   //
    //////////////////////////
    function checkBidIsValid(Auction storage auction, uint256 bidAmount) internal view returns (AuctionState memory) {
        uint256 auctionEnd = auction.startTime + auction.duration;
        address previousBidder = auction.winningBidder;
        uint256 previousBidAmount = auction.winningBidAmount;

        require(auction.seller != address(0), "auction does not exist");
        require(auction.startTime <= block.timestamp, "auction not started yet");
        require(auctionEnd > block.timestamp, "auction has ended");
        require(bidAmount >= auction.startingBid, "starting bid not met");
        require(previousBidder != msg.sender, " cannot outbid yourself");

        // not first bid
        if (auction.winningBidAmount != 0) {
            require(
                bidAmount >= previousBidAmount + (previousBidAmount * auction.minBidIncrementBps) / 10000,
                "invalid bid"
            );
        }

        return AuctionState(auctionEnd, previousBidAmount, previousBidder);
    }

    function extendAuctionIfWithinWindow(uint256 auctionEnd, Auction storage auction) internal returns (bool) {
        uint256 timeRemaining = auctionEnd - block.timestamp;

        if (timeRemaining < auction.extensionWindow) {
            // extension is from current time
            // auctionEnd = block.timestamp + auction.extensionWindow;
            // auctionEnd = auction.startTime + auction.duration
            // >  auction.startTime + auction.duration = block.timestamp + auction.extensionWindow;
            // >  auction.duration = block.timestamp + auction.extensionWindow - auction.startTime;
            auction.duration = block.timestamp + auction.extensionWindow - auction.startTime;
            return true;
        }
        return false;
    }

    /**
     * Should be called prior to attempting to transfer the bid payment to the contract.  This
     * will do validation on the bid amount and extend the auction if required.
     */
    function beforeBidPaymentTransfer(Auction storage auction, uint256 bidAmount)
        internal
        returns (AuctionState memory auctionState, bool extended)
    {
        auctionState = checkBidIsValid(auction, bidAmount);
        auction.winningBidAmount = bidAmount;
        auction.winningBidder = msg.sender;
        extended = extendAuctionIfWithinWindow(auctionState.auctionEnd, auction);
        return (auctionState, extended);
    }

    /**
     * Should be called after transfering bid payment to the contract.  This will refund
     * the previous bidder (if there was one), and emit the BidPlaced event.
     */
    function afterBidPaymentTransfer(
        AuctionState memory auctionState,
        uint256 bidAmount,
        bool extended,
        uint256 auctionId,
        address paymentCurrency
    ) internal {
        emit BidPlaced(auctionId, msg.sender, bidAmount, extended);

        if (auctionState.previousBidAmount != 0) {
            transferPayment(
                address(this),
                auctionState.previousBidder,
                auctionState.previousBidAmount,
                paymentCurrency
            );
        }
    }

    /*
     * Returns the percentage of the total bid (used to calculate fee payments).
     */
    function getPortionOfBid(uint256 totalBid, uint256 percentageBips) private pure returns (uint256) {
        return (totalBid * (percentageBips)) / 10000;
    }

    function requireValidAuction(uint256 auctionId) private view {
        require(auctionIdToAuction[auctionId].seller != address(0), "auction does not exist");
    }

    /**
     * Transfer the winning bid for an auction to the fee recipients.
     */
    function transferAuctionPayment(Auction memory auction) private {
        for (uint256 i = 0; i < auction.feeRecipients.length; i++) {
            uint256 fee = getPortionOfBid(auction.winningBidAmount, auction.feePercentages[i]);
            if (fee > 0) {
                transferPayment(address(this), payable(auction.feeRecipients[i]), fee, auction.paymentCurrency);
            }
        }
    }

    function transferNFT(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        address token,
        TokenType tokenType
    ) internal {
        if (tokenType == TokenType.ERC1155) {
            IERC1155(token).safeTransferFrom(from, to, tokenId, amount, "");
        } else {
            IERC721(token).safeTransferFrom(from, to, tokenId, "");
        }
    }

    function transferPayment(
        address from,
        address to,
        uint256 amount,
        address token
    ) internal {
        if (from == address(this)) {
            SafeERC20.safeTransfer(IERC20(token), to, amount);
        } else {
            SafeERC20.safeTransferFrom(IERC20(token), from, to, amount);
        }
    }

    function getAuctionEndTime(uint256 auctionId) public view returns (uint256) {
        Auction memory auction = getAuction(auctionId);
        return auction.startTime + auction.duration;
    }

    function isAuctionComplete(uint256 auctionId) public view returns (bool) {
        return block.timestamp > getAuctionEndTime(auctionId);
    }
}