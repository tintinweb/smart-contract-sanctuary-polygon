/**
 *Submitted for verification at polygonscan.com on 2022-05-10
*/

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)
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

// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)
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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)
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

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)
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

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)
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

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)
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

// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)
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

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)
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

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)
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

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)
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

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Holder.sol)
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

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)
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
abstract contract AbsEnglishAuction is ERC721Holder, ERC1155Holder, ReentrancyGuard, WrappedNativeHelpers {
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
    function _createAuction(
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
    ) internal {
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
     * @notice Place bid on a running auction with an ERC20 token, internal. Caller should perform nonReentrant check
     * @dev msg.value is bid amount when paying in ETH
     * @param auctionId uint256 Auction ID of the auction
     * @param bidAmount uint256 Amount of bid if non-eth currency
     */
    function _placeBid(uint256 auctionId, uint256 bidAmount) internal {
        requireValidAuction(auctionId);
        Auction storage auction = auctionIdToAuction[auctionId];

        (AuctionState memory auctionState, bool extended) = beforeBidPaymentTransfer(auction, bidAmount);

        // bid funds start in contract until auction over or outbid
        transferPayment(msg.sender, address(this), bidAmount, auction.paymentCurrency);

        afterBidPaymentTransfer(auctionState, bidAmount, extended, auctionId, auction.paymentCurrency);
    }

    /**
     * @notice Place bid on a running auction in the native currency. Caller should perform nonReentrant check
     * @dev msg.value is bid amount
     * @param auctionId uint256 Auction ID of the auction
     */
    function _placeBidInEth(uint256 auctionId) internal {
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

// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)
/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)
/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)
/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)
/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

contract AbsSignatureRestricted is AccessControl {
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    constructor(address _initialSigner) {
        _grantRole(SIGNER_ROLE, _initialSigner);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function hashCalldata(
        bytes memory data,
        uint256 expiresAt,
        uint256 value,
        address sender
    ) public pure returns (bytes32) {
        return ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(data, expiresAt, value, sender)));
    }

    function verifySignedData(
        bytes memory data,
        uint256 expiresAt,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        require(expiresAt > block.timestamp, "Expired timestamp");

        address recoveredSigner = ecrecover(hashCalldata(data, expiresAt, msg.value, msg.sender), v, r, s);

        require(recoveredSigner != address(0), "Invalid signature");
        require(hasRole(SIGNER_ROLE, recoveredSigner), "Invalid signature");
    }
}

contract RestrictedEnglishAuction is AbsEnglishAuction, AbsSignatureRestricted {
    bytes32 public constant AUCTION_CREATOR_ROLE = keccak256("AUCTION_CREATOR_ROLE");

    constructor(address wrappedNativeAsset) AbsEnglishAuction(wrappedNativeAsset) AbsSignatureRestricted(msg.sender) {
        _grantRole(AUCTION_CREATOR_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC1155Receiver)
        returns (bool)
    {
        return interfaceId == type(IAccessControl).interfaceId || interfaceId == type(IERC1155Receiver).interfaceId;
    }

    /**
     * @notice Create an English auction, restricted to AUCTION_CREATOR_ROLE
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
    ) public onlyRole(AUCTION_CREATOR_ROLE) {
        super._createAuction(
            tokenId,
            tokenContract,
            tokenType,
            duration,
            startTime,
            startingBid,
            paymentCurrency,
            extensionWindow,
            minBidIncrementBps,
            feeRecipients,
            feePercentages
        );
    }

    /**
     * @notice Place bid on a running auction with an ERC20 token with SIGNER restriction
     * @param auctionId uint256 Auction ID of the auction
     * @param bidAmount uint256 Amount of bid if non-eth currency
     * @param expiresAt uint256 Timestamp until which singature is value
     * @param v uint8 Signature of input params with SIGNERs key
     * @param r bytes32  Signature of input params with SIGNERs key
     * @param s bytes32 Signature of input params with SIGNERs key
     */
    function placeBid(
        uint256 auctionId,
        uint256 bidAmount,
        uint256 expiresAt,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable nonReentrant {
        verifySignedData(abi.encodePacked(auctionId, bidAmount), expiresAt, v, r, s);
        super._placeBid(auctionId, bidAmount);
    }

    /**
     * @notice Place bid on a running auction in the native currency with SIGNER restriction
     * @dev msg.value is bid amount
     * @param auctionId uint256 Auction ID of the auction
     * @param expiresAt uint256 Timestamp until which singature is value
     * @param v uint8 Signature of input params with SIGNERs key
     * @param r bytes32  Signature of input params with SIGNERs key
     * @param s bytes32 Signature of input params with SIGNERs key
     */
    function placeBidInEth(
        uint256 auctionId,
        uint256 expiresAt,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable nonReentrant {
        verifySignedData(abi.encodePacked(auctionId), expiresAt, v, r, s);
        super._placeBidInEth(auctionId);
    }
}