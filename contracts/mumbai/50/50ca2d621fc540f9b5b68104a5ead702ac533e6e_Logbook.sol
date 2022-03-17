/**
 *Submitted for verification at polygonscan.com on 2022-03-17
*/

//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)



// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)



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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)





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

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)



/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)





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
}/**
 * @dev Provides a set of functions to operate with Base64 strings.
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}
/**
 * @title The interface for NFT royalty
 */
interface IRoyalty {
    error ZeroAmount();
    error InsufficientBalance(uint256 available, uint256 required);

    enum RoyaltyPurpose {
        Fork,
        Donate
    }

    /**
     * @notice Emitted when a royalty payment is made
     * @param tokenId Token id
     * @param sender Sender address
     * @param recipient Recipient address
     * @param purpose Purpose of the payment, e.g. fork, donate
     * @param amount Amount of the payment
     */
    event Pay(
        uint256 indexed tokenId,
        address indexed sender,
        address indexed recipient,
        uint256 amount,
        RoyaltyPurpose purpose
    );

    /**
     * @notice Emitted when a withdrawal is made
     * @param account Address that receives the withdrawal
     * @param amount Amount of the withdrawal
     */
    event Withdraw(address indexed account, uint256 amount);

    /**
     * @notice Withdraw royalty fees
     * @dev Emits a {Withdraw} event
     */
    function withdraw() external;

    /**
     * @notice Get balance of a given address
     * @param account_ Address
     */
    function getBalance(address account_) external view returns (uint256);
}

/**
 * @title The interface for Logbook core contract
 * @dev The interface is inherited from IERC721 (for logbook as NFT) and IRoyalty (for royalty)
 */
interface ILogbook is IRoyalty, IERC721 {
    error Unauthorized();
    error InvalidBPS(uint256 min, uint256 max);
    error InvalidTokenId(uint256 min, uint256 max);
    error InsufficientAmount(uint256 available, uint256 required);
    error InsufficientLogs(uint32 maxEndAt);
    error TokenNotExists();
    error PublicSaleNotStarted();

    struct Log {
        address author;
        // logbook that this log first publish to
        uint256 tokenId;
    }

    struct Book {
        // end position of a range of logs
        uint32 endAt;
        // total number of logs
        uint32 logCount;
        // number of transfers
        uint32 transferCount;
        // creation time of the book
        uint160 createdAt;
        // parent book
        uint256 from;
        // fork price
        uint256 forkPrice;
        // all logs hashes in the book
        bytes32[] contentHashes;
    }

    struct SplitRoyaltyFees {
        uint256 commission;
        uint256 logbookOwner;
        uint256 perLogAuthor;
    }

    /**
     * @notice Emitted when logbook title was set
     * @param tokenId Logbook token id
     * @param title Logbook title
     */
    event SetTitle(uint256 indexed tokenId, string title);

    /**
     * @notice Emitted when logbook description was set
     * @param tokenId Logbook token id
     * @param description Logbook description
     */
    event SetDescription(uint256 indexed tokenId, string description);

    /**
     * @notice Emitted when logbook fork price was set
     * @param tokenId Logbook token id
     * @param amount Logbook fork price
     */
    event SetForkPrice(uint256 indexed tokenId, uint256 amount);

    /**
     * @notice Emitted when a new log was created
     * @param author Author address
     * @param contentHash Deterministic unique ID, hash of the content
     * @param content Content string
     */
    event Content(address indexed author, bytes32 indexed contentHash, string content);

    /**
     * @notice Emitted when logbook owner publish a new log
     * @param tokenId Logbook token id
     * @param contentHash Deterministic unique ID, hash of the content
     */
    event Publish(uint256 indexed tokenId, bytes32 indexed contentHash);

    /**
     * @notice Emitted when a logbook was forked
     * @param tokenId Logbook token id
     * @param newTokenId New logbook token id
     * @param owner New logbook owner address
     * @param end End position of contentHashes of parent logbook (one-based)
     * @param amount Fork price
     */
    event Fork(uint256 indexed tokenId, uint256 indexed newTokenId, address indexed owner, uint32 end, uint256 amount);

    /**
     * @notice Emitted when a logbook received a donation
     * @param tokenId Logbook token id
     * @param donor Donor address
     * @param amount Fork price
     */
    event Donate(uint256 indexed tokenId, address indexed donor, uint256 amount);

    /**
     * @notice Set logbook title
     * @dev Access Control: logbook owner
     * @dev Emits a {SetTitle} event
     * @param tokenId_ logbook token id
     * @param title_ logbook title
     */
    function setTitle(uint256 tokenId_, string calldata title_) external;

    /**
     * @notice Set logbook description
     * @dev Access Control: logbook owner
     * @dev Emits a {SetDescription} event
     * @param tokenId_ Logbook token id
     * @param description_ Logbook description
     */
    function setDescription(uint256 tokenId_, string calldata description_) external;

    /**
     * @notice Set logbook fork price
     * @dev Access Control: logbook owner
     * @dev Emits a {SetForkPrice} event
     * @param tokenId_ Logbook token id
     * @param amount_ Fork price
     */
    function setForkPrice(uint256 tokenId_, uint256 amount_) external;

    /**
     * @notice Batch calling methods of this contract
     * @param data Array of calldata
     */
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);

    /**
     * @notice Publish a new log in a logbook
     * @dev Access Control: logbook owner
     * @dev Emits a {Publish} event
     * @param tokenId_ Logbook token id
     * @param content_ Log content
     */
    function publish(uint256 tokenId_, string calldata content_) external;

    /**
     * @notice Pay to fork a logbook
     * @dev Emits {Fork} and {Pay} events
     * @param tokenId_ Logbook token id
     * @param endAt_ End position of contentHashes of parent logbook  (one-based)
     * @return tokenId New logobok token id
     */
    function fork(uint256 tokenId_, uint32 endAt_) external payable returns (uint256 tokenId);

    /**
     * @notice Pay to fork a logbook with commission
     * @dev Emits {Fork} and {Pay} events
     * @param tokenId_ Logbook token id
     * @param endAt_ End position of contentHashes of parent logbook (one-based)
     * @param commission_ Address (frontend operator) to earn commission
     * @param commissionBPS_ Basis points of the commission
     * @return tokenId New logobok token id
     */
    function forkWithCommission(
        uint256 tokenId_,
        uint32 endAt_,
        address commission_,
        uint256 commissionBPS_
    ) external payable returns (uint256 tokenId);

    /**
     * @notice Donate to a logbook
     * @dev Emits {Donate} and {Pay} events
     * @param tokenId_ Logbook token id
     */
    function donate(uint256 tokenId_) external payable;

    /**
     * @notice Donate to a logbook with commission
     * @dev Emits {Donate} and {Pay} events
     * @param tokenId_ Logbook token id
     * @param commission_ Address (frontend operator) to earn commission
     * @param commissionBPS_ Basis points of the commission
     */
    function donateWithCommission(
        uint256 tokenId_,
        address commission_,
        uint256 commissionBPS_
    ) external payable;

    /**
     * @notice Get a logbook
     * @param tokenId_ Logbook token id
     * @return book Logbook data
     */
    function getLogbook(uint256 tokenId_) external view returns (Book memory book);

    /**
     * @notice Get a logbook's logs
     * @param tokenId_ Logbook token id
     * @return contentHashes All logs' content hashes
     * @return authors All logs' authors
     */
    function getLogs(uint256 tokenId_) external view returns (bytes32[] memory contentHashes, address[] memory authors);

    /**
     * @notice Claim a logbook with a Traveloggers token
     * @dev Access Control: contract deployer
     * @param to_ Traveloggers token owner
     * @param logrsId_ Traveloggers token id (1-1500)
     */
    function claim(address to_, uint256 logrsId_) external;

    /**
     * @notice Mint a logbook
     */
    function publicSaleMint() external payable returns (uint256 tokenId);

    /**
     * @notice Set public sale
     * @dev Access Control: contract deployer
     */
    function setPublicSalePrice(uint256 price_) external;

    /**
     * @notice Turn on public sale
     * @dev Access Control: contract deployer
     */
    function turnOnPublicSale() external;

    /**
     * @notice Turn off public sale
     * @dev Access Control: contract deployer
     */
    function turnOffPublicSale() external;
}abstract contract Royalty is IRoyalty, Ownable {
    mapping(address => uint256) internal _balances;

    /// @inheritdoc IRoyalty
    function withdraw() public {
        uint256 amount = getBalance(msg.sender);

        if (amount == 0) revert ZeroAmount();
        if (address(this).balance < amount) revert InsufficientBalance(address(this).balance, amount);

        _balances[msg.sender] = 1 wei;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success);

        emit Withdraw(msg.sender, amount);
    }

    /// @inheritdoc IRoyalty
    function getBalance(address account_) public view returns (uint256 amount) {
        uint256 balance = _balances[account_];

        amount = balance <= 1 wei ? 0 : balance - 1 wei;
    }
}library NFTSVG {
    struct SVGParams {
        uint32 logCount;
        uint32 transferCount;
        uint160 createdAt;
        uint256 tokenId;
    }

    function generateSVG(SVGParams memory params) internal pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<svg width="800" height="800" xmlns="http://www.w3.org/2000/svg"><g fill="none" fill-rule="evenodd">',
                generateSVGBackground(params),
                generateSVGPathsA(params),
                generateSVGPathsB(params),
                generateSVGTexts(params),
                "</g></svg>"
            )
        );
    }

    function generateSVGBackground(SVGParams memory params) internal pure returns (string memory svg) {
        string memory colorBackground = params.logCount < 10 ? "#F3F1EA" : "#41403F";

        svg = string(abi.encodePacked('<path d="M0 0h800v800H0z" fill="', colorBackground, '"/>'));
    }

    function generateSVGPathsA(SVGParams memory params) internal pure returns (string memory svg) {
        string memory color = string(
            abi.encodePacked(
                "rgb(",
                Strings.toString(uint8((params.createdAt * _max(params.logCount, 1) * 10) % 256)),
                ",",
                Strings.toString(uint8((params.createdAt * params.transferCount * 80) % 256)),
                ",",
                Strings.toString(uint8(params.tokenId % 256)),
                ")"
            )
        );

        svg = string(
            abi.encodePacked(
                '<path d="M670.7 535.7a30 30 0 0 1 30 30V648a30 30 0 0 1-30 30h-79a30 30 0 0 1-30-30v-4.5a30 30 0 0 1 30-30h18.1a30 30 0 0 0 30-30v-17.8a30 30 0 0 1 30-30h1Zm-386.7.4a30 30 0 0 1 30 30V648a30 30 0 0 1-30 30h-1a30 30 0 0 1-30-30v-82a30 30 0 0 1 30-30Zm-150 77.6a30 30 0 0 1 30 30v3.6a30 30 0 0 1-30 30h-5.8a30 30 0 0 1-30-30v-3.5a30 30 0 0 1 30-30ZM519 536a30 30 0 0 1 30 30v5.4a30 30 0 0 1-30 30h-81.8a30 30 0 0 1-30-30v-5.4a30 30 0 0 1 30-30Zm-2.5-154.6a30 30 0 0 1 30 30v82a30 30 0 0 1-30 30h-.9a30 30 0 0 1-30-30v-82a30 30 0 0 1 30-30Zm-76-76.7a30 30 0 0 1 30 30v82a30 30 0 0 1-30 30h-82.1a30 30 0 0 1-30-30v-2.2a30 30 0 0 1 30-30h17.7a30 30 0 0 0 30-30v-19.8a30 30 0 0 1 30-30ZM210 381a30 30 0 0 1 30 30v3.6a30 30 0 0 1-30 30h-5.8a30 30 0 0 1-30-30V411a30 30 0 0 1 30-30h5.8Zm74.1-154.7a30 30 0 0 1 30 30V274a30 30 0 0 0 30 30h18.2a30 30 0 0 1 30 30v4.5a30 30 0 0 1-30 30h-79a30 30 0 0 1-30-30v-82.3a30 30 0 0 1 30-30Zm386.6 0a30 30 0 0 1 30 30v82.3a30 30 0 0 1-30 30h-79a30 30 0 0 1-30-30V334a30 30 0 0 1 30-30h18.1a30 30 0 0 0 30-30v-17.8a30 30 0 0 1 30-30h1ZM207.2 145a30 30 0 0 1 30 30v82.3a30 30 0 0 1-30 30h-.9a30 30 0 0 1-30-30v-17.8a30 30 0 0 0-30-30h-18.1a30 30 0 0 1-30-30V175a30 30 0 0 1 30-30Zm387.2.3a30 30 0 0 1 30 30v82a30 30 0 0 1-30 30h-.9a30 30 0 0 1-30-30v-82a30 30 0 0 1 30-30Zm-156.5 0a30 30 0 0 1 30 30v7.2a30 30 0 0 1-30 30h-.9a30 30 0 0 1-30-30v-7.2a30 30 0 0 1 30-30Z" fill-opacity=".5" fill="',
                color,
                '"/>'
            )
        );
    }

    function generateSVGPathsB(SVGParams memory params) internal pure returns (string memory svg) {
        string memory color = string(
            abi.encodePacked(
                "rgb(",
                Strings.toString(uint8((params.createdAt * _max(params.logCount, 1) * 20) % 256)),
                ",",
                Strings.toString(uint8((params.createdAt * params.transferCount * 40) % 256)),
                ",",
                Strings.toString(uint8(params.tokenId % 256)),
                ")"
            )
        );

        svg = string(
            abi.encodePacked(
                '<path d="M356.8 535.7a30 30 0 0 1 30 30v17.8a30 30 0 0 0 30 30H435a30 30 0 0 1 30 30v4.5a30 30 0 0 1-30 30h-79a30 30 0 0 1-30-30v-82.3a30 30 0 0 1 30-30Zm-149.8 0a30 30 0 0 1 30 30V648a30 30 0 0 1-30 30h-.9a30 30 0 0 1-30-30v-17.8a30 30 0 0 0-30-30H128a30 30 0 0 1-30-30v-4.5a30 30 0 0 1 30-30Zm312.1 78a30 30 0 0 1 30 30v3.6a30 30 0 0 1-30 30h-5.8a30 30 0 0 1-30-30v-3.5a30 30 0 0 1 30-30Zm78-77.3a30 30 0 0 1 30 30v3.6a30 30 0 0 1-30 30h-5.9a30 30 0 0 1-30-30v-3.6a30 30 0 0 1 30-30h5.9Zm-4.5-154a30 30 0 0 1 30 30V430a30 30 0 0 0 30 30h18.1a30 30 0 0 1 30 30v4.5a30 30 0 0 1-30 30h-79a30 30 0 0 1-30-30v-82.3a30 30 0 0 1 30-30Zm-308.5 0a30 30 0 0 1 30 30V430a30 30 0 0 0 30 30h18.2a30 30 0 0 1 30 30v4.5a30 30 0 0 1-30 30h-79a30 30 0 0 1-30-30v-82.3a30 30 0 0 1 30-30ZM129 381a30 30 0 0 1 30 30v17.8a30 30 0 0 0 30 30H207a30 30 0 0 1 30 30v4.5a30 30 0 0 1-30 30h-79a30 30 0 0 1-30-30V411a30 30 0 0 1 30-30Zm311.6 78a30 30 0 0 1 30 30v4.3a30 30 0 0 1-30 30h-.9a30 30 0 0 1-30-30V489a30 30 0 0 1 30-30Zm230-77a30 30 0 0 1 30 30v7.2a30 30 0 0 1-30 30h-7.2a30 30 0 0 1-30-30V412a30 30 0 0 1 30-30Zm-154-78a30 30 0 0 1 30 30v7.2a30 30 0 0 1-30 30h-.9a30 30 0 0 1-30-30V334a30 30 0 0 1 30-30ZM209.8 307a30 30 0 0 1 30 30v1a30 30 0 0 1-30 30H128a30 30 0 0 1-30-30v-1a30 30 0 0 1 30-30ZM362.3 145a30 30 0 0 1 30 30v82.3a30 30 0 0 1-30 30h-1a30 30 0 0 1-30-30v-17.8a30 30 0 0 0-30-30h-18a30 30 0 0 1-30-30V175a30 30 0 0 1 30-30Zm156.8.3a30 30 0 0 1 30 30v82a30 30 0 0 1-30 30H437a30 30 0 0 1-30-30V255a30 30 0 0 1 30-30h17.7a30 30 0 0 0 30-30v-19.8a30 30 0 0 1 30-30Zm-385 81a30 30 0 0 1 30 30v1a30 30 0 0 1-30 30h-6a30 30 0 0 1-30-30v-1a30 30 0 0 1 30-30h6Zm536.3-81a30 30 0 0 1 30 30v7.2a30 30 0 0 1-30 30h-.9a30 30 0 0 1-30-30v-7.2a30 30 0 0 1 30-30Z" fill="',
                color,
                '"/>'
            )
        );
    }

    function generateSVGTexts(SVGParams memory params) internal pure returns (string memory svg) {
        string memory colorBackground = params.logCount < 10 ? "#F3F1EA" : "#41403F";
        string memory colorText = params.logCount < 10 ? "#333" : "#fff";

        string[3] memory texts;

        // title
        texts[0] = string(
            abi.encodePacked(
                '<text fill="',
                colorText,
                '" font-family="Roboto, Tahoma-Bold, Tahoma" font-size="48" font-weight="bold"><tspan x="99.3" y="105.4">LOGBOOK</tspan></text>',
                '<path stroke="',
                colorText,
                '" stroke-width="8" d="M387 88h314M99 718h602"/>'
            )
        );

        // metadata
        string memory numbers = string(
            abi.encodePacked(
                "Logs/",
                Strings.toString(params.logCount),
                "    Transfers/",
                Strings.toString(params.transferCount - 1),
                "    ID/",
                Strings.toString(params.tokenId)
            )
        );

        uint256 len = bytes(numbers).length;
        string memory placeholders;
        for (uint256 i = 0; i < len; i++) {
            placeholders = string(abi.encodePacked(placeholders, "g"));
        }
        texts[1] = string(
            abi.encodePacked(
                '<text stroke="',
                colorBackground,
                '" stroke-width="20" font-family="Roboto, Tahoma-Bold, Tahoma" font-size="18" font-weight="bold" fill="',
                colorText,
                '"><tspan x="98" y="724.2">',
                placeholders,
                "</tspan></text>"
            )
        );
        texts[2] = string(
            abi.encodePacked(
                '<text fill="',
                colorText,
                '" font-family="Roboto, Tahoma-Bold, Tahoma" font-size="18" font-weight="bold" xml:space="preserve"><tspan x="98" y="724.2">',
                numbers,
                "</tspan></text>"
            )
        );

        svg = string(abi.encodePacked(texts[0], texts[1], texts[2]));
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
}
contract Logbook is ERC721, Ownable, ILogbook, Royalty {
    uint256 private constant _ROYALTY_BPS_LOGBOOK_OWNER = 8000;
    uint256 private constant _ROYALTY_BPS_COMMISSION_MAX = 10000 - _ROYALTY_BPS_LOGBOOK_OWNER;
    uint256 private constant _PUBLIC_SALE_ON = 1;
    uint256 private constant _PUBLIC_SALE_OFF = 2;
    uint256 public publicSale = _PUBLIC_SALE_OFF;
    uint256 public publicSalePrice;

    // contentHash to log
    mapping(bytes32 => Log) public logs;

    // tokenId to logbook
    mapping(uint256 => Book) private books;

    // starts at 1501 since 1-1500 are reseved for Traveloggers claiming
    using Counters for Counters.Counter;
    Counters.Counter internal _tokenIdCounter = Counters.Counter(1500);

    /**
     * @dev Throws if called by any account other than the logbook owner.
     */
    modifier onlyLogbookOwner(uint256 tokenId_) {
        if (!_isApprovedOrOwner(msg.sender, tokenId_)) revert Unauthorized();
        _;
    }

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    /// @inheritdoc ILogbook
    function setTitle(uint256 tokenId_, string calldata title_) external onlyLogbookOwner(tokenId_) {
        emit SetTitle(tokenId_, title_);
    }

    /// @inheritdoc ILogbook
    function setDescription(uint256 tokenId_, string calldata description_) external onlyLogbookOwner(tokenId_) {
        emit SetDescription(tokenId_, description_);
    }

    /// @inheritdoc ILogbook
    function setForkPrice(uint256 tokenId_, uint256 amount_) external onlyLogbookOwner(tokenId_) {
        books[tokenId_].forkPrice = amount_;
        emit SetForkPrice(tokenId_, amount_);
    }

    /// @inheritdoc ILogbook
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results) {
        results = new bytes[](data.length);

        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            require(success);
            results[i] = result;
        }

        return results;
    }

    /// @inheritdoc ILogbook
    function publish(uint256 tokenId_, string calldata content_) external onlyLogbookOwner(tokenId_) {
        bytes32 contentHash = keccak256(abi.encodePacked(content_));

        // log
        Log memory log = logs[contentHash];
        if (log.author == address(0)) {
            logs[contentHash] = Log(msg.sender, tokenId_);
            emit Content(msg.sender, contentHash, content_);
        }

        // logbook
        books[tokenId_].contentHashes.push(contentHash);
        books[tokenId_].logCount++;
        emit Publish(tokenId_, contentHash);
    }

    /// @inheritdoc ILogbook
    function fork(uint256 tokenId_, uint32 endAt_) external payable returns (uint256 tokenId) {
        (Book memory book, uint256 newTokenId) = _fork(tokenId_, endAt_);
        tokenId = newTokenId;

        if (msg.value > 0) {
            address logbookOwner = ERC721.ownerOf(tokenId_);
            _splitRoyalty(tokenId_, book, logbookOwner, msg.value, RoyaltyPurpose.Fork, address(0), 0);
        }
    }

    /// @inheritdoc ILogbook
    function forkWithCommission(
        uint256 tokenId_,
        uint32 endAt_,
        address commission_,
        uint256 commissionBPS_
    ) external payable returns (uint256 tokenId) {
        if (commissionBPS_ > _ROYALTY_BPS_COMMISSION_MAX) revert InvalidBPS(0, _ROYALTY_BPS_COMMISSION_MAX);

        (Book memory book, uint256 newTokenId) = _fork(tokenId_, endAt_);
        tokenId = newTokenId;

        if (msg.value > 0) {
            address logbookOwner = ERC721.ownerOf(tokenId_);
            _splitRoyalty(tokenId_, book, logbookOwner, msg.value, RoyaltyPurpose.Fork, commission_, commissionBPS_);
        }
    }

    /// @inheritdoc ILogbook
    function donate(uint256 tokenId_) external payable {
        if (msg.value <= 0) revert ZeroAmount();
        if (!_exists(tokenId_)) revert TokenNotExists();

        Book memory book = books[tokenId_];
        address logbookOwner = ERC721.ownerOf(tokenId_);

        _splitRoyalty(tokenId_, book, logbookOwner, msg.value, RoyaltyPurpose.Donate, address(0), 0);

        emit Donate(tokenId_, msg.sender, msg.value);
    }

    /// @inheritdoc ILogbook
    function donateWithCommission(
        uint256 tokenId_,
        address commission_,
        uint256 commissionBPS_
    ) external payable {
        if (msg.value <= 0) revert ZeroAmount();
        if (!_exists(tokenId_)) revert TokenNotExists();
        if (commissionBPS_ > _ROYALTY_BPS_COMMISSION_MAX) revert InvalidBPS(0, _ROYALTY_BPS_COMMISSION_MAX);

        Book memory book = books[tokenId_];
        address logbookOwner = ERC721.ownerOf(tokenId_);

        _splitRoyalty(tokenId_, book, logbookOwner, msg.value, RoyaltyPurpose.Donate, commission_, commissionBPS_);

        emit Donate(tokenId_, msg.sender, msg.value);
    }

    /// @inheritdoc ILogbook
    function getLogbook(uint256 tokenId_) external view returns (Book memory book) {
        book = books[tokenId_];
    }

    /// @inheritdoc ILogbook
    function getLogs(uint256 tokenId_)
        external
        view
        returns (bytes32[] memory contentHashes, address[] memory authors)
    {
        Book memory book = books[tokenId_];
        uint32 logCount = book.logCount;

        contentHashes = _logs(tokenId_);
        authors = new address[](logCount);
        for (uint32 i = 0; i < logCount; i++) {
            bytes32 contentHash = contentHashes[i];
            authors[i] = logs[contentHash].author;
        }
    }

    /// @inheritdoc ILogbook
    function claim(address to_, uint256 logrsId_) external onlyOwner {
        if (logrsId_ < 1 || logrsId_ > 1500) revert InvalidTokenId(1, 1500);

        _safeMint(to_, logrsId_);

        books[logrsId_].createdAt = uint160(block.timestamp);
    }

    /// @inheritdoc ILogbook
    function publicSaleMint() external payable returns (uint256 tokenId) {
        if (publicSale != _PUBLIC_SALE_ON) revert PublicSaleNotStarted();
        if (msg.value < publicSalePrice) revert InsufficientAmount(msg.value, publicSalePrice);

        // forward value
        address deployer = owner();
        (bool success, ) = deployer.call{value: msg.value}("");
        require(success);

        // mint
        tokenId = _mint(msg.sender);
    }

    /// @inheritdoc ILogbook
    function setPublicSalePrice(uint256 price_) external onlyOwner {
        publicSalePrice = price_;
    }

    /// @inheritdoc ILogbook
    function turnOnPublicSale() external onlyOwner {
        publicSale = _PUBLIC_SALE_ON;
    }

    /// @inheritdoc ILogbook
    function turnOffPublicSale() external onlyOwner {
        publicSale = _PUBLIC_SALE_OFF;
    }

    function tokenURI(uint256 tokenId_) public view override returns (string memory) {
        if (!_exists(tokenId_)) revert TokenNotExists();

        Book memory book = books[tokenId_];
        uint32 logCount = book.logCount;

        string memory tokenName = string(abi.encodePacked("Logbook #", Strings.toString(tokenId_)));
        string memory description = string(abi.encodePacked("A book that records owners' journey in Matterverse."));
        string memory attributeLogs = string(
            abi.encodePacked('{"trait_type": "Logs","value":', Strings.toString(logCount), "}")
        );

        NFTSVG.SVGParams memory svgParams = NFTSVG.SVGParams({
            logCount: logCount,
            transferCount: book.transferCount,
            createdAt: book.createdAt,
            tokenId: tokenId_
        });
        string memory image = Base64.encode(bytes(NFTSVG.generateSVG(svgParams)));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        tokenName,
                        '", "description": "',
                        description,
                        '", "attributes": [',
                        attributeLogs,
                        '], "image": "data:image/svg+xml;base64,',
                        image,
                        '"}'
                    )
                )
            )
        );

        string memory output = string(abi.encodePacked("data:application/json;base64,", json));

        return output;
    }

    /**
     * @notice Get logs of a book
     * @param tokenId_ Logbook token id
     */
    function _logs(uint256 tokenId_) internal view returns (bytes32[] memory contentHashes) {
        Book memory book = books[tokenId_];

        contentHashes = new bytes32[](book.logCount);
        uint32 index = 0;

        // copy from parents
        Book memory parent = books[book.from];
        uint32 takes = book.endAt;
        bool hasParent = book.from == 0 ? false : true;

        while (hasParent) {
            bytes32[] memory parentContentHashes = parent.contentHashes;
            for (uint32 i = 0; i < takes; i++) {
                contentHashes[index] = parentContentHashes[i];
                index++;
            }

            if (parent.from == 0) {
                hasParent = false;
            } else {
                takes = parent.endAt;
                parent = books[parent.from];
            }
        }

        // copy from current
        bytes32[] memory currentContentHashes = book.contentHashes;
        for (uint32 i = 0; i < currentContentHashes.length; i++) {
            contentHashes[index] = currentContentHashes[i];
            index++;
        }
    }

    function _mint(address to) internal returns (uint256 tokenId) {
        _tokenIdCounter.increment();
        tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);

        books[tokenId].createdAt = uint160(block.timestamp);
    }

    function _fork(uint256 tokenId_, uint32 endAt_) internal returns (Book memory newBook, uint256 newTokenId) {
        if (!_exists(tokenId_)) revert TokenNotExists();

        Book memory book = books[tokenId_];
        uint32 maxEndAt = uint32(book.contentHashes.length);
        uint32 logCount = book.logCount;

        if (logCount <= 0 || endAt_ <= 0 || maxEndAt < endAt_) revert InsufficientLogs(maxEndAt);
        if (msg.value < book.forkPrice) revert InsufficientAmount(msg.value, book.forkPrice);

        // mint new logbook
        newTokenId = _mint(msg.sender);

        bytes32[] memory contentHashes = new bytes32[](0);
        newBook = Book({
            endAt: endAt_,
            logCount: logCount - maxEndAt + endAt_,
            transferCount: 0,
            createdAt: uint160(block.timestamp),
            from: tokenId_,
            forkPrice: 0 ether,
            contentHashes: contentHashes
        });

        books[newTokenId] = newBook;

        emit Fork(tokenId_, newTokenId, msg.sender, endAt_, msg.value);
    }

    /**
     * @notice Split royalty payments
     * @dev No repetitive checks, please make sure all arguments are valid
     * @param tokenId_ Logbook token id
     * @param book_ Logbook to be split royalty
     * @param amount_ Total amount to split royalty
     * @param purpose_ Payment purpose
     * @param commission_ commission_ Address (frontend operator) to earn commission
     * @param commissionBPS_ Basis points of the commission
     */
    function _splitRoyalty(
        uint256 tokenId_,
        Book memory book_,
        address logbookOwner_,
        uint256 amount_,
        RoyaltyPurpose purpose_,
        address commission_,
        uint256 commissionBPS_
    ) internal {
        uint32 logCount = book_.logCount;
        bytes32[] memory contentHashes = _logs(tokenId_);

        // fees calculation
        SplitRoyaltyFees memory fees;
        bool isNoCommission = commission_ == address(0) || commissionBPS_ == 0;
        if (!isNoCommission) {
            fees.commission = (amount_ * commissionBPS_) / 10000;
        }

        if (logCount <= 0) {
            fees.logbookOwner = amount_ - fees.commission;
        } else {
            fees.logbookOwner = (amount_ * _ROYALTY_BPS_LOGBOOK_OWNER) / 10000;
            fees.perLogAuthor = (amount_ - fees.logbookOwner - fees.commission) / logCount;
        }

        // split royalty
        // -> logbook owner
        _balances[logbookOwner_] += fees.logbookOwner;
        emit Pay({
            tokenId: tokenId_,
            sender: msg.sender,
            recipient: logbookOwner_,
            amount: fees.logbookOwner,
            purpose: purpose_
        });

        // -> commission
        if (!isNoCommission) {
            _balances[commission_] += fees.commission;
            emit Pay({
                tokenId: tokenId_,
                sender: msg.sender,
                recipient: commission_,
                amount: fees.commission,
                purpose: purpose_
            });
        }

        // -> logs' authors
        if (logCount > 0) {
            for (uint32 i = 0; i < logCount; i++) {
                Log memory log = logs[contentHashes[i]];
                _balances[log.author] += fees.perLogAuthor;
                emit Pay({
                    tokenId: tokenId_,
                    sender: msg.sender,
                    recipient: log.author,
                    amount: fees.perLogAuthor,
                    purpose: purpose_
                });
            }
        }
    }

    function _afterTokenTransfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal virtual override {
        super._afterTokenTransfer(from_, to_, tokenId_); // Call parent hook

        books[tokenId_].transferCount++;

        // warm up _balances[to] to reduce gas of SSTORE on _splitRoyalty
        if (_balances[to_] == 0) {
            _balances[to_] = 1 wei;
        }
    }
}