/**
 *Submitted for verification at polygonscan.com on 2022-02-15
*/

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC1155/ERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;







/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// File: VoxRunners.sol

// contracts/VoxRunners.sol

pragma solidity ^0.8.7;



contract VoxRunners is ERC1155 {

uint256 public constant GasMask = 105;
uint256 public constant Ninja = 106;
uint256 public constant OniMaskGreen = 107;
uint256 public constant OniMaskPurple = 108;
uint256 public constant OniMaskRed = 109;
uint256 public constant Oxygenmask = 110;
uint256 public constant ViralMask = 111;
uint256 public constant FullHeadBandage = 112;
uint256 public constant GasTankMask = 113;
uint256 public constant HockeyMask = 114;
uint256 public constant JackOLantern = 115;
uint256 public constant PolygonMask = 116;
uint256 public constant RoboJaw = 117;
uint256 public constant SquidMask = 118;
uint256 public constant CandyRaverEarrings = 119;
uint256 public constant ChainEarring = 120;
uint256 public constant Earpiece = 121;
uint256 public constant GoldStudCrossCombo = 122;
uint256 public constant GoldStudEarrings = 123;
uint256 public constant LargeHoopEarrings = 124;
uint256 public constant OpenFaceShield = 125;
uint256 public constant SilverStudCrossCombo = 126;
uint256 public constant SilverStudEarrings = 127;
uint256 public constant SmallHoopEarrings = 128;
uint256 public constant Blunt = 129;
uint256 public constant Cig = 130;
uint256 public constant Cigar = 131;
uint256 public constant DomRose = 132;
uint256 public constant Joint = 133;
uint256 public constant Pipe = 134;
uint256 public constant TongueOut = 135;
uint256 public constant TonguePill = 136;
uint256 public constant Aviators = 222;
uint256 public constant ChainspaceDeckBasic = 223;
uint256 public constant ChainspaceDeckEliteI = 224;
uint256 public constant ChainspaceDeckEliteII = 225;
uint256 public constant ChainspaceDeckEliteIII = 226;
uint256 public constant ChainspaceDeckPro = 227;
uint256 public constant ChainspaceDeckSE = 228;
uint256 public constant CyberneticImplants = 229;
uint256 public constant DealWithIt = 230;
uint256 public constant EyePatchMonocle = 231;
uint256 public constant EyePatchSight = 232;
uint256 public constant EyePatch = 233;
uint256 public constant GeordiVisor = 234;
uint256 public constant GlassVisor = 235;
uint256 public constant Glasses = 236;
uint256 public constant Goggles = 237;
uint256 public constant HunterEyes = 238;
uint256 public constant KanedaGoggles = 239;
uint256 public constant LennonGlasses = 240;
uint256 public constant MadEyeMonocle = 241;
uint256 public constant NightVisionGoggles = 242;
uint256 public constant Nouns = 243;
uint256 public constant RoboCyclopian = 244;
uint256 public constant RodmanWrapArounds = 245;
uint256 public constant ScouterGreen = 246;
uint256 public constant ScouterRed = 247;
uint256 public constant SingleEyeReader = 248;
uint256 public constant SniperGoggles = 249;
uint256 public constant SunGlassesRed = 250;
uint256 public constant SunGlasses = 251;
uint256 public constant TargetVisor = 252;
uint256 public constant ThinGlasses = 253;
uint256 public constant AlienHat = 254;
uint256 public constant BackwardsHat1 = 255;
uint256 public constant BackwardsHat2 = 256;
uint256 public constant BeanieHairBlonde = 257;
uint256 public constant BeanieHairGreen = 258;
uint256 public constant Beanie = 259;
uint256 public constant BlitmapHat = 260;
uint256 public constant ChainHat = 261;
uint256 public constant ChainHeadband = 262;
uint256 public constant ClassicTopHat = 263;
uint256 public constant CowboyHatBrown = 264;
uint256 public constant CowboyHatPink = 265;
uint256 public constant CowboyHatWhite = 266;
uint256 public constant CrownBald = 267;
uint256 public constant CrownLongHairBlue = 268;
uint256 public constant CrownLongHairGrey = 269;
uint256 public constant DivineRobe = 270;
uint256 public constant Dreadlocks = 271;
uint256 public constant DualHorn = 272;
uint256 public constant EGirlHair = 273;
uint256 public constant EyeHat = 274;
uint256 public constant FluxHair = 275;
uint256 public constant FunkyBandanaBald = 276;
uint256 public constant GenesisHat = 277;
uint256 public constant GogglesForehead = 278;
uint256 public constant GoodMorningBandanaTopKnot = 279;
uint256 public constant GreenShortHair = 280;
uint256 public constant HalfBuzzHalfLongBlueHair = 281;
uint256 public constant HalfBuzzHalfLongHair = 282;
uint256 public constant Hood = 283;
uint256 public constant Horns = 284;
uint256 public constant LeatherBandanaBald = 285;
uint256 public constant LongGreenFrontBraid = 286;
uint256 public constant LongPinkPigtails = 287;
uint256 public constant LongStyledHair = 288;
uint256 public constant MetalRiceHat = 289;
uint256 public constant MysticTopHat = 290;
uint256 public constant NeonGreenIndustrialDreads = 291;
uint256 public constant PyramidHat = 292;
uint256 public constant SillyCopterHat = 293;
uint256 public constant SkullSkulletorHood = 294;
uint256 public constant StraightLongHair = 295;
uint256 public constant StraightLongPurpleHair = 296;
uint256 public constant StrawHat = 297;
uint256 public constant TechnoHorns = 298;
uint256 public constant TieDyeBandanaBald = 299;
uint256 public constant TrunksHair = 300;
uint256 public constant ZorgHair = 301;
uint256 public constant BaldUnkempt = 302;
uint256 public constant BleachedVerticalSpikes = 303;
uint256 public constant BlueVerticalSpikes = 304;
uint256 public constant BobHair = 305;
uint256 public constant CornrowsDarkHair = 306;
uint256 public constant CornrowsDarkTopknotHair = 307;
uint256 public constant CornrowsGreenHair = 308;
uint256 public constant CornrowsLightHair = 309;
uint256 public constant CroppedCutDark = 310;
uint256 public constant DoublePigtailHairBrown = 311;
uint256 public constant DoublePigtailHairPink = 312;
uint256 public constant DoubleSpike = 313;
uint256 public constant FaceChain = 314;
uint256 public constant GreyCeaser = 315;
uint256 public constant MeditationCirclet = 316;
uint256 public constant MessyBun = 317;
uint256 public constant MessyHairDark = 318;
uint256 public constant MessyHairLight = 319;
uint256 public constant MetalSkullcap = 320;
uint256 public constant MohawkHairNeonBlue = 321;
uint256 public constant MohawkHairNeonPink = 322;
uint256 public constant MohawkHair = 323;
uint256 public constant Pompadour = 324;
uint256 public constant PunkerSpikeNeonGreen = 325;
uint256 public constant PunkerSpikeNeonPink = 326;
uint256 public constant PurpleFroHawk = 327;
uint256 public constant RoughPunkHairBlack = 328;
uint256 public constant RoughPunkHairPink = 329;
uint256 public constant RubyRhodHair = 330;
uint256 public constant SlickedBlondeHair = 331;
uint256 public constant SlickedDarkHair = 332;
uint256 public constant SushiChefBandana = 333;
uint256 public constant WellCombedHairBlk = 334;
uint256 public constant WellCombedHairBrwn = 335;
uint256 public constant WidowsPeakBlueHair = 336;
uint256 public constant WidowsPeakHair = 337;

    constructor() ERC1155("http://voxel.run/{id}.json") {
        _mint(msg.sender, GasMask, 88,  "");
        _mint(msg.sender, Ninja, 81,  "");
        _mint(msg.sender, OniMaskGreen, 77,  "");
        _mint(msg.sender, OniMaskPurple, 96,  "");
        _mint(msg.sender, OniMaskRed, 73,  "");
        _mint(msg.sender, Oxygenmask, 242,  "");
        _mint(msg.sender, ViralMask, 403,  "");
        _mint(msg.sender, FullHeadBandage, 187,  "");
        _mint(msg.sender, GasTankMask, 213,  "");
        _mint(msg.sender, HockeyMask, 86,  "");
        _mint(msg.sender, JackOLantern, 16,  "");
        _mint(msg.sender, PolygonMask, 13,  "");
        _mint(msg.sender, RoboJaw, 24,  "");
        _mint(msg.sender, SquidMask, 34,  "");
        _mint(msg.sender, CandyRaverEarrings, 926,  "");
        _mint(msg.sender, ChainEarring, 565,  "");
        _mint(msg.sender, Earpiece, 194,  "");
        _mint(msg.sender, GoldStudCrossCombo, 586,  "");
        _mint(msg.sender, GoldStudEarrings, 934,  "");
        _mint(msg.sender, LargeHoopEarrings, 942,  "");
        _mint(msg.sender, OpenFaceShield, 169,  "");
        _mint(msg.sender, SilverStudCrossCombo, 1268,  "");
        _mint(msg.sender, SilverStudEarrings, 1306,  "");
        _mint(msg.sender, SmallHoopEarrings, 1240,  "");
        _mint(msg.sender, Blunt, 836,  "");
        _mint(msg.sender, Cig, 2415,  "");
        _mint(msg.sender, Cigar, 545,  "");
        _mint(msg.sender, DomRose, 9,  "");
        _mint(msg.sender, Joint, 831,  "");
        _mint(msg.sender, Pipe, 276,  "");
        _mint(msg.sender, TongueOut, 516,  "");
        _mint(msg.sender, TonguePill, 141,  "");
        _mint(msg.sender, Aviators, 161,  "");
        _mint(msg.sender, ChainspaceDeckBasic, 205,  "");
        _mint(msg.sender, ChainspaceDeckEliteI, 107,  "");
        _mint(msg.sender, ChainspaceDeckEliteII, 56,  "");
        _mint(msg.sender, ChainspaceDeckEliteIII, 29,  "");
        _mint(msg.sender, ChainspaceDeckPro, 163,  "");
        _mint(msg.sender, ChainspaceDeckSE, 59,  "");
        _mint(msg.sender, CyberneticImplants, 278,  "");
        _mint(msg.sender, DealWithIt, 55,  "");
        _mint(msg.sender, EyePatchMonocle, 209,  "");
        _mint(msg.sender, EyePatchSight, 148,  "");
        _mint(msg.sender, EyePatch, 249,  "");
        _mint(msg.sender, GeordiVisor, 60,  "");
        _mint(msg.sender, GlassVisor, 311,  "");
        _mint(msg.sender, Glasses, 247,  "");
        _mint(msg.sender, Goggles, 186,  "");
        _mint(msg.sender, HunterEyes, 57,  "");
        _mint(msg.sender, KanedaGoggles, 150,  "");
        _mint(msg.sender, LennonGlasses, 213,  "");
        _mint(msg.sender, MadEyeMonocle, 51,  "");
        _mint(msg.sender, NightVisionGoggles, 92,  "");
        _mint(msg.sender, Nouns, 8,  "");
        _mint(msg.sender, RoboCyclopian, 103,  "");
        _mint(msg.sender, RodmanWrapArounds, 44,  "");
        _mint(msg.sender, ScouterGreen, 183,  "");
        _mint(msg.sender, ScouterRed, 198,  "");
        _mint(msg.sender, SingleEyeReader, 106,  "");
        _mint(msg.sender, SniperGoggles, 154,  "");
        _mint(msg.sender, SunGlassesRed, 216,  "");
        _mint(msg.sender, SunGlasses, 274,  "");
        _mint(msg.sender, TargetVisor, 235,  "");
        _mint(msg.sender, ThinGlasses, 264,  "");
        _mint(msg.sender, AlienHat, 71,  "");
        _mint(msg.sender, BackwardsHat1, 148,  "");
        _mint(msg.sender, BackwardsHat2, 132,  "");
        _mint(msg.sender, BeanieHairBlonde, 133,  "");
        _mint(msg.sender, BeanieHairGreen, 116,  "");
        _mint(msg.sender, Beanie, 91,  "");
        _mint(msg.sender, BlitmapHat, 105,  "");
        _mint(msg.sender, ChainHat, 154,  "");
        _mint(msg.sender, ChainHeadband, 140,  "");
        _mint(msg.sender, ClassicTopHat, 105,  "");
        _mint(msg.sender, CowboyHatBrown, 116,  "");
        _mint(msg.sender, CowboyHatPink, 37,  "");
        _mint(msg.sender, CowboyHatWhite, 108,  "");
        _mint(msg.sender, CrownBald, 150,  "");
        _mint(msg.sender, CrownLongHairBlue, 55,  "");
        _mint(msg.sender, CrownLongHairGrey, 58,  "");
        _mint(msg.sender, DivineRobe, 12,  "");
        _mint(msg.sender, Dreadlocks, 142,  "");
        _mint(msg.sender, DualHorn, 139,  "");
        _mint(msg.sender, EGirlHair, 140,  "");
        _mint(msg.sender, EyeHat, 135,  "");
        _mint(msg.sender, FluxHair, 17,  "");
        _mint(msg.sender, FunkyBandanaBald, 126,  "");
        _mint(msg.sender, GenesisHat, 56,  "");
        _mint(msg.sender, GogglesForehead, 147,  "");
        _mint(msg.sender, GoodMorningBandanaTopKnot, 156,  "");
        _mint(msg.sender, GreenShortHair, 150,  "");
        _mint(msg.sender, HalfBuzzHalfLongBlueHair, 134,  "");
        _mint(msg.sender, HalfBuzzHalfLongHair, 141,  "");
        _mint(msg.sender, Hood, 136,  "");
        _mint(msg.sender, Horns, 124,  "");
        _mint(msg.sender, LeatherBandanaBald, 119,  "");
        _mint(msg.sender, LongGreenFrontBraid, 132,  "");
        _mint(msg.sender, LongPinkPigtails, 166,  "");
        _mint(msg.sender, LongStyledHair, 125,  "");
        _mint(msg.sender, MetalRiceHat, 10,  "");
        _mint(msg.sender, MysticTopHat, 76,  "");
        _mint(msg.sender, NeonGreenIndustrialDreads, 74,  "");
        _mint(msg.sender, PyramidHat, 64,  "");
        _mint(msg.sender, SillyCopterHat, 71,  "");
        _mint(msg.sender, SkullSkulletorHood, 3,  "");
        _mint(msg.sender, StraightLongHair, 128,  "");
        _mint(msg.sender, StraightLongPurpleHair, 101,  "");
        _mint(msg.sender, StrawHat, 47,  "");
        _mint(msg.sender, TechnoHorns, 44,  "");
        _mint(msg.sender, TieDyeBandanaBald, 122,  "");
        _mint(msg.sender, TrunksHair, 46,  "");
        _mint(msg.sender, ZorgHair, 17,  "");
        _mint(msg.sender, BaldUnkempt, 172,  "");
        _mint(msg.sender, BleachedVerticalSpikes, 163,  "");
        _mint(msg.sender, BlueVerticalSpikes, 178,  "");
        _mint(msg.sender, BobHair, 187,  "");
        _mint(msg.sender, CornrowsDarkHair, 161,  "");
        _mint(msg.sender, CornrowsDarkTopknotHair, 193,  "");
        _mint(msg.sender, CornrowsGreenHair, 17,  "");
        _mint(msg.sender, CornrowsLightHair, 158,  "");
        _mint(msg.sender, CroppedCutDark, 206,  "");
        _mint(msg.sender, DoublePigtailHairBrown, 165,  "");
        _mint(msg.sender, DoublePigtailHairPink, 197,  "");
        _mint(msg.sender, DoubleSpike, 98,  "");
        _mint(msg.sender, FaceChain, 82,  "");
        _mint(msg.sender, GreyCeaser, 96,  "");
        _mint(msg.sender, MeditationCirclet, 53,  "");
        _mint(msg.sender, MessyBun, 119,  "");
        _mint(msg.sender, MessyHairDark, 122,  "");
        _mint(msg.sender, MessyHairLight, 118,  "");
        _mint(msg.sender, MetalSkullcap, 144,  "");
        _mint(msg.sender, MohawkHairNeonBlue, 172,  "");
        _mint(msg.sender, MohawkHairNeonPink, 171,  "");
        _mint(msg.sender, MohawkHair, 182,  "");
        _mint(msg.sender, Pompadour, 129,  "");
        _mint(msg.sender, PunkerSpikeNeonGreen, 130,  "");
        _mint(msg.sender, PunkerSpikeNeonPink, 122,  "");
        _mint(msg.sender, PurpleFroHawk, 133,  "");
        _mint(msg.sender, RoughPunkHairBlack, 121,  "");
        _mint(msg.sender, RoughPunkHairPink, 91,  "");
        _mint(msg.sender, RubyRhodHair, 18,  "");
        _mint(msg.sender, SlickedBlondeHair, 180,  "");
        _mint(msg.sender, SlickedDarkHair, 169,  "");
        _mint(msg.sender, SushiChefBandana, 73,  "");
        _mint(msg.sender, WellCombedHairBlk, 178,  "");
        _mint(msg.sender, WellCombedHairBrwn, 154,  "");
        _mint(msg.sender, WidowsPeakBlueHair, 165,  "");
        _mint(msg.sender, WidowsPeakHair, 191,  "");
    }

    function uri(uint256 _tokenId) override public pure returns (string memory) {
        return string(
            abi.encodePacked(
                "https://voxel.run/",
                Strings.toString(_tokenId),
                ".json"
            )
        );
    }

}