/**
 *Submitted for verification at polygonscan.com on 2022-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


// _
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

// _
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)
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

// _
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

// _
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

// _
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)
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

// _
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

// _
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

// _
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

// _
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)
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
     * by default, can be overridden in child contracts.
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
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
}

// _
interface ISoulBound is IERC721 {
    /**
     * @dev if the token is soulbound
     * @return true if the token is soulbound
     */
    function soulbound() external view returns (bool);
}

// _
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
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
}

// _
interface ISoulBoundMedal is ISoulBound {
    /**
     * @dev Add medals to current DAO
     * @param medalsname array of medal description
     * @param medalsuri array of medal uri
     */
    function addMedals(
        string[] calldata medalsname,
        string[] calldata medalsuri
    ) external;

    struct MedalPanel {
        uint256 _request;
        uint256 _approved;
        uint256 _rejected;
        uint256 _genesis;
    }

    /**
     * @dev get medals
     * @return array of medals
     */
    function getMedals()
        external
        view
        returns (
            string[] memory,
            string[] memory,
            MedalPanel[] memory
        );

    /**
     * @dev get medals count
     * @return uint256
     */
    function countMedals() external view returns (uint256);

    /**
     * @dev get medalIndex by tokenid
     */
    function getMedalIndexByTokenid(uint256 tokenid)
        external
        view
        returns (uint256);
 
    /**
     * @dev get cliam status by key
     * @param key key, bytes32 : request user address + medalIndex
     * @return uint256 the cliam status,  1:pending,2:rejected ,>2 tokenid
     */
    function getCliamStatusByBytes32Key(bytes32 key)
        external
        view
        returns (uint256);

    function getCliamRequestSize() external view returns (uint256);

    struct CliamRequest {
        address _address; // request address
        uint256 _medalIndex; // medal index
        uint256 _timestamp; // timestamp
        uint256 _status; // status of the cliam,  1:pending,2:rejected ,>2 tokenid
    }

    function getCliamRequest(uint256 _index)
        external
        view
        returns (CliamRequest memory);

    /**
     * @dev get Cliam Request Approved count
     * @param _medalIndex medal index
     * @return uint256
     */
    function countCliamRequestApproved(uint256 _medalIndex)
        external
        view
        returns (uint256);

    /**
     * @dev get Cliam Request Approved index by medal index
     * @param _medalIndex medal index
     * @return uint256[] CliamRequest index arrary of Cliam Request Approved
     */
    function listCliamRequestApproved(uint256 _medalIndex)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev update medal by index
     * @param medalIndex index of medal
     * @param name new name of medal
     * @param uri new uri of medal
     */
    function updateMedal(
        uint256 medalIndex,
        string calldata name,
        string calldata uri
    ) external;

    /**
     * @dev  Approved cliam
     * @param cliamId the index of the cliam id
     * Emits a {Transfer} event.
     */
    function cliamApproved(uint256 cliamId) external;

    /**
     * @dev  Rejected cliam
     * @param cliamId the index of the cliam id
     */
    function cliamRejected(uint256 cliamId) external;

    /**
     * @dev Users apply for mint medal
     * @param medalIndex the index of the medal
     */
    function cliamRequest(uint256 medalIndex) external;
}

// _
interface IDataStorage {
    function saveString(bytes4 k, string calldata v) external;

    function getString(address a, bytes4 k)
        external
        view
        returns (string memory);

    function saveStrings(bytes4[] calldata k, string[] calldata v) external;

    function getStrings(address a, bytes4[] calldata k)
        external
        view
        returns (string[] memory);

    // function addToAddressArrary(bytes4 k, address v) external;

    // function removeFromAddressArrary(bytes4 k, address v) external;

    // function getAddressArrary(address a, bytes4 k)
    //     external
    //     view
    //     returns (address[] memory);

    // function getAddressArraryIndex(
    //     address a,
    //     bytes4 k,
    //     address addr
    // ) external view returns (uint256);
}

// _
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)
/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
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

// _
interface ISoulBoundBridge {
    function onOwnerChage(address _dao) external;

    /**
    * @dev on user request a medal
    * @param _address address of user
    * @param _dao  address of dao
    * @param _medalIndex tokenid of medal
     */
    function onCliamRequest(
        address _address,
        address _dao,
        uint256 _medalIndex
    ) external;

}

// _
interface ITokenInfo {
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);

    function name() external view returns (string memory);

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() external view returns (string memory);
}

contract SoulBoundBridge is IDataStorage, ISoulBoundBridge {
    // region variables

    address[] private storageEnumerableUserArr;

    mapping(address => uint256[]) private storageEnumerableUserMap;

    mapping(bytes32 => bool) private userDAOMapping;

    mapping(address => uint256) private storageEnumerableDAOMap;

    address[] private storageEnumerableDAOArr;

    mapping(address => mapping(bytes4 => string)) private storageStrings;

    mapping(address => uint256[]) private userDaoMedalsDaoIndexMap; // key: user address,value:index-1 is the dao in the storageEnumerableDAOArr
    mapping(bytes32 => uint256[]) private userDaoMedalIndexMapIndex; // key: user address+ dao address,value:medalIndex
    mapping(bytes32 => bool) private userDaoMedalIndexMapUnique; // key: user address+ dao address+ medalIndex,value: true:has set

    mapping(address => address[]) private contractOwnerMap; // key:user address,value: dao address array
    mapping(bytes32 => uint256) private contractOwnerMapIndex; // key: user address+ dao address,value -1 is the index of the contractOwnerMap -> value

    // endregion

    // region functional
    constructor() {}

    /**
     * @dev save a string to the storage
     * @param k key
     */
    function saveString(bytes4 k, string calldata v) public override {
        storageStrings[msg.sender][k] = v;
    }

    /**
     * @dev get a string from the storage
     * @param a address
     * @param k key
     * @return string memory value
     */
    function getString(address a, bytes4 k)
        public
        view
        override
        returns (string memory)
    {
        return storageStrings[a][k];
    }

    /**
     * @dev save multiple string to the storage
     * @param k key array
     * @param v value array
     */
    function saveStrings(bytes4[] calldata k, string[] calldata v)
        public
        override
    {
        for (uint256 i = 0; i < k.length; i++) {
            storageStrings[msg.sender][k[i]] = v[i];
        }
    }

    /**
     * @dev get multiple string from the storage
     * @param a address
     * @param k key array
     * @return string[] memory value array
     */
    function getStrings(address a, bytes4[] calldata k)
        public
        view
        override
        returns (string[] memory)
    {
        string[] memory result = new string[](k.length);
        for (uint256 i = 0; i < k.length; i++) {
            result[i] = storageStrings[a][k[i]];
        }
        return result;
    }

    /**
     * @dev get multiple address & multiple string from the storage
     * @param a key
     * @param k value
     * @return string[][] memory value array
     */
    function getStrings(address[] calldata a, bytes4[] calldata k)
        public
        view
        returns (string[][] memory)
    {
        string[][] memory result = new string[][](a.length);
        for (uint256 i = 0; i < a.length; i++) {
            result[i] = getStrings(a[i], k);
        }
        return result;
    }

    modifier onlySoulBoundMedalAddress(address _soulBoundMedalAddress) {
        require(
            _soulBoundMedalAddress.code.length > 0,
            "given address is not a valid contract"
        );
        require(
            IERC165(_soulBoundMedalAddress).supportsInterface(
                type(ISoulBoundMedal).interfaceId
            ),
            "given address is not a valid soul bound medal contract"
        );

        _;
    }

    /**
     * @dev  call on DAO owner change
     * @param _dao address
     */
    function onOwnerChage(address _dao)
        public
        override
        onlySoulBoundMedalAddress(_dao)
    {
        _changeOwner(_dao);
    }

    /**
     * @dev  get the owner of the contract
     * @param _dao address
     * @return address
     */
    function getOwner(address _dao) private view returns (address) {
        ITokenInfo ownable = ITokenInfo(_dao);
        try ownable.owner() returns (address _owner) {
            return _owner;
        } catch {}
        return address(0);
    }

    /**
     * @dev  get the name of the contract
     * @param _dao address
     * @return string
     */
    function getName(address _dao) private view returns (string memory) {
        ITokenInfo ownable = ITokenInfo(_dao);
        try ownable.name() returns (string memory _name) {
            return _name;
        } catch {}
        return "";
    }

    function _changeOwner(address _dao) private {
        address owner = getOwner(_dao);
        bytes32 key = keccak256(abi.encodePacked(owner, _dao));
        if (contractOwnerMapIndex[key] == 0) {
            contractOwnerMap[owner].push(_dao);
            contractOwnerMapIndex[key] = contractOwnerMap[owner].length;
        }
    }

    /**
     * @dev on user request a medal
     * @param _address address of user
     * @param _dao  address of dao
     * @param _medalIndex tokenid of medal
     */
    function onCliamRequest(
        address _address,
        address _dao,
        uint256 _medalIndex
    ) public override {
        if (storageEnumerableDAOMap[_dao] == 0) {
            require(
                _dao.code.length > 0,
                "given address is not a valid contract"
            );
            require(
                IERC165(_dao).supportsInterface(
                    type(ISoulBoundMedal).interfaceId
                ),
                "given address is not a valid soul bound medal contract"
            );
            storageEnumerableDAOArr.push(_dao);
            storageEnumerableDAOMap[_dao] = storageEnumerableDAOArr.length;

            // register owner
            _changeOwner(_dao);
        }
        bytes32 userDAOMappingKey = keccak256(abi.encodePacked(_address, _dao));
        if (userDAOMapping[userDAOMappingKey] == false) {
            // register user
            require(
                _address.code.length == 0,
                "given address is a contract,soul bound medal can not be claimed by a contract"
            );
            userDAOMapping[userDAOMappingKey] = true;
            if (storageEnumerableUserMap[_address].length == 0) {
                storageEnumerableUserArr.push(_address);
            }
            storageEnumerableUserMap[_address].push(
                storageEnumerableDAOMap[_dao]
            );
        }

        bytes32 userDAOMedalIndexMappingKey = keccak256(
            abi.encodePacked(_address, _dao, _medalIndex)
        );
        if (userDaoMedalIndexMapUnique[userDAOMedalIndexMappingKey] == false) {
            userDaoMedalIndexMapUnique[userDAOMedalIndexMappingKey] = true;

            if (userDaoMedalIndexMapIndex[userDAOMappingKey].length == 0) {
                uint256 DAOIndex = storageEnumerableDAOMap[_dao];
                userDaoMedalsDaoIndexMap[_address].push(DAOIndex);
            }
            userDaoMedalIndexMapIndex[userDAOMappingKey].push(_medalIndex);
        }
    }

    // endregion

    // region Composability functions for other contracts

    //address[] private storageEnumerableUserArr;
    function get_storageEnumerableUserArr()
        public
        view
        returns (address[] memory)
    {
        return storageEnumerableUserArr;
    }


    //mapping(address => uint256[]) private storageEnumerableUserMap;
    function get_storageEnumerableUserMap(address _address)
        public
        view
        returns (uint256[] memory)
    {
        return storageEnumerableUserMap[_address];
    }

    //mapping(bytes32 => bool) private userDAOMapping;
    function get_userDAOMapping(bytes32 key)
        public
        view
        returns (bool)
    {
        return userDAOMapping[key];
    }

    //mapping(address => uint256) private storageEnumerableDAOMap;
    function get_storageEnumerableDAOMap(address _dao)
        public
        view
        returns (uint256)
    {
        return storageEnumerableDAOMap[_dao];
    }

    //address[] private storageEnumerableDAOArr;
    function get_storageEnumerableDAOArr()
        public
        view
        returns (address[] memory)
    {
        return storageEnumerableDAOArr;
    }

    //mapping(address => mapping(bytes4 => string)) private storageStrings;
    function get_storageStrings(address _dao, bytes4 _key)
        public
        view
        returns (string memory)
    {
        return storageStrings[_dao][_key];
    }

    //mapping(address => uint256[]) private userDaoMedalsDaoIndexMap;
    function get_userDaoMedalsDaoIndexMap(address _address)
        public
        view
        returns (uint256[] memory)
    {
        return userDaoMedalsDaoIndexMap[_address];
    }

    //mapping(bytes32 => uint256[]) private userDaoMedalIndexMapIndex;
    function get_userDaoMedalIndexMapIndex(bytes32 key)
        public
        view
        returns (uint256[] memory)
    {
        return userDaoMedalIndexMapIndex[key];
    }

    //mapping(bytes32 => bool) private userDaoMedalIndexMapUnique;
    function get_userDaoMedalIndexMapUnique(bytes32 key)
        public
        view
        returns (bool)
    {
        return userDaoMedalIndexMapUnique[key];
    }

    //mapping(address => address[]) private contractOwnerMap;
    function get_contractOwnerMap(address _owner)
        public
        view
        returns (address[] memory)
    {
        return contractOwnerMap[_owner];
    }

    //mapping(bytes32 => uint256) private contractOwnerMapIndex;
    function get_contractOwnerMapIndex(bytes32 key)
        public
        view
        returns (uint256)
    {
        return contractOwnerMapIndex[key];
    }

    // endregion

    // region DAO

    /**
     * @dev  count DAO
     * @return uint256 DAO count
     */
    function countDAO() public view returns (uint256) {
        return storageEnumerableDAOArr.length;
    }

    /**
     * @dev list DAO
     * @param offset uint256 query offset
     * @param limit uint256 query limit
     * @param medals_offset uint256 medal offset
     * @param medals_limit uint256 medal limit,no medals fetched if 0
     * @return string memory  json string
     */
    function listDAO(
        uint256 offset,
        uint256 limit,
        uint256 medals_offset,
        uint256 medals_limit // no medals fetched if 0
    ) public view returns (string memory) {
        /* 
        {
           "address": [
                            '0x1',
                            '0x2'
                        ],
            "medals": [
                        {"total":1,"medals":[
                                                    {
                                                        "index":0,
                                                        "name":"base64 string",
                                                        "uri":"base64 string",
                                                        "request":0,
                                                        "approved":0,
                                                        "rejected":0,
                                                        "genesis":1539098983
                                                    }
                                            ]
                        }
                    ]
        } 
         */
        string memory result_address = "[";
        string memory result_medals = "[";
        for (uint256 i = offset; i < offset + limit; i++) {
            if (i >= storageEnumerableDAOArr.length) {
                break;
            }
            if (i > offset) {
                result_address = string(abi.encodePacked(result_address, ","));
            }
            result_address = string(
                abi.encodePacked(
                    result_address,
                    '"',
                    Strings.toHexString(
                        uint256(uint160(storageEnumerableDAOArr[i]))
                    ),
                    '"'
                )
            );
            if (medals_limit > 0) {
                if (i > offset) {
                    result_medals = string(
                        abi.encodePacked(result_medals, ",")
                    );
                }
                result_medals = string(
                    abi.encodePacked(
                        result_medals,
                        listDAOMedals(
                            storageEnumerableDAOArr[i],
                            medals_offset,
                            medals_limit
                        )
                    )
                );
            }
        }
        result_address = string(abi.encodePacked(result_address, "]"));
        result_medals = string(abi.encodePacked(result_medals, "]"));
        return
            string(
                abi.encodePacked(
                    '{"address":',
                    result_address,
                    ',"medals":',
                    result_medals,
                    "}"
                )
            );
    }

    // endregion

    // region CliamRequest

    /**
     * @dev  count CliamRequest by DAO
     * @param _dao address DAO contract address
     * @return uint256 CliamRequest count
     */
    function countCliamRequest(address _dao) public view returns (uint256) {
        ISoulBoundMedal soulBoundMedal = ISoulBoundMedal(_dao);
        try soulBoundMedal.getCliamRequestSize() returns (uint256 _size) {
            return _size;
        } catch {
            return 0;
        }
    }

    /**
     * @dev  count approved CliamRequest by DAO
     * @param _dao address DAO contract address
     * @return string memory  json string
     */
    function countCliamRequestApproved(address _dao)
        public
        view
        returns (uint256)
    {
        ISoulBoundMedal soulBoundMedal = ISoulBoundMedal(_dao);
        uint256 count = 0;
        try soulBoundMedal.countMedals() returns (uint256 _size) {
            for (uint256 i = 0; i < _size; i++) {
                count += countCliamRequestApproved(_dao, i);
            }
        } catch {}
        return count;
    }

    /**
     * @dev  count Approved CliamRequest by DAO and medal index
     * @param _dao address DAO contract address
     * @return string memory  json string
     */
    function countCliamRequestApproved(address _dao, uint256 _madalIndex)
        public
        view
        returns (uint256)
    {
        ISoulBoundMedal soulBoundMedal = ISoulBoundMedal(_dao);
        try soulBoundMedal.countCliamRequestApproved(_madalIndex) returns (
            uint256 _size
        ) {
            return _size;
        } catch {}
        return 0;
    }

    /**
     * @dev get CliamRequest by DAO
     * @param medalContract  address  medal contract address instance
     * @param _index  uint256  CliamRequest index
     * @return string memory  json string
     */
    function getCliamRequest(ISoulBoundMedal medalContract, uint256 _index)
        private
        view
        returns (string memory)
    {
        try medalContract.getCliamRequest(_index) returns (
            ISoulBoundMedal.CliamRequest memory cr
        ) {
            /* 
        {
            "index":0,
            "address":"0x",
            "medalindex":0,
            "timestamp":0,
            "status":0 //// status of the cliam,   1:pending,2:rejected ,>2 tokenid
        }
         */
            return
                string(
                    abi.encodePacked(
                        '{"index":',
                        Strings.toString(_index),
                        ',"address":"',
                        Strings.toHexString(uint256(uint160(cr._address))),
                        '","medalindex":',
                        Strings.toString(cr._medalIndex),
                        ',"timestamp":',
                        Strings.toString(cr._timestamp),
                        ',"status":',
                        Strings.toString(cr._status),
                        "}"
                    )
                );
        } catch {}
        return "{}";
    }

    /**
     * @dev get CliamRequest list by DAO
     * @param _dao address DAO contract address
     * @param _offset uint256 query offset
     * @param _limit uint256 query limit
     * @return string memory  json string
     */
    function getCliamRequest(
        address _dao,
        uint256 _offset,
        uint256 _limit
    ) public view returns (string memory) {
        string memory result = "[";
        ISoulBoundMedal medalContract = ISoulBoundMedal(_dao);
        uint256 c = countCliamRequest(_dao);
        for (uint256 i = _offset; i < _offset + _limit; i++) {
            if (i >= c) {
                break;
            }
            if (i > _offset) {
                result = string(abi.encodePacked(result, ","));
            }
            result = string(
                abi.encodePacked(result, getCliamRequest(medalContract, i))
            );
        }
        return string(abi.encodePacked(result, "]"));
    }

    /**
     * @dev get CliamRequest Approved list by DAO
     * @param _dao address DAO contract address
     * @param _offset uint256 query offset
     * @param _limit uint256 query limit
     * @return string memory  json string
     */
    function getCliamRequestApproved(
        address _dao,
        uint256 _offset, // offset of each medal
        uint256 _limit // limit of each medal
    ) public view returns (string memory) {
        /* 

[
    {
        "medalindex":0,
        "list":[
            {
                "index":0,
                "address":"0x",
                "timestamp":0,
                "status":0 //// status of the cliam,  0: rejected , 1: pending, 2: approved
            }
        ]
    }
]
*/
        string memory result = "[";
        ISoulBoundMedal medalContract = ISoulBoundMedal(_dao);
        uint256 c = 0;
        try medalContract.countMedals() returns (uint256 _size) {
            c = _size;
        } catch {}
        for (uint256 j = 0; j < c; j++) {
            if (j > 0) {
                result = string(abi.encodePacked(result, ","));
            }
            result = string(
                abi.encodePacked(
                    result,
                    '{"medalindex":',
                    Strings.toString(j),
                    ',"list":',
                    getCliamRequestApproved(_dao, _offset, _limit, j),
                    "}"
                )
            );
        }

        return string(abi.encodePacked(result, "]"));
    }

    /**
     * @dev get CliamRequest Approved list by DAO and medal index
     * @param _dao address DAO contract address
     * @param _offset uint256 query offset
     * @param _limit uint256 query limit
     * @param _medalIndex uint256 medal index
     * @return string memory  json string
     */
    function getCliamRequestApproved(
        address _dao,
        uint256 _offset,
        uint256 _limit,
        uint256 _medalIndex
    ) public view returns (string memory) {
        string memory result = "[";
        ISoulBoundMedal medalContract = ISoulBoundMedal(_dao);
        uint256 c = countCliamRequestApproved(_dao, _medalIndex);
        for (uint256 i = _offset; i < _offset + _limit; i++) {
            if (i >= c) {
                break;
            }
            if (i > _offset) {
                result = string(abi.encodePacked(result, ","));
            }
            result = string(
                abi.encodePacked(result, getCliamRequest(medalContract, i))
            );
        }
        return string(abi.encodePacked(result, "]"));
    }

    // endregion

    // region medals

    /**
     * @dev list medals of DAO
     * @param offset the offset, from 0
     * @param limit the limit, minimum 1
     * @return string json string of query result
     */
    function listDAOMedals(
        address _address,
        uint256 offset,
        uint256 limit
    ) public view onlySoulBoundMedalAddress(_address) returns (string memory) {
        /*
        {
            "name":"base64",
            "owner":"0x",
            "total":1,"medals":[
                {
                    "index":0,
                    "name":"base64 string",
                    "uri":"base64 string",
                    "request":0,
                    "approved":0,
                    "rejected":0,
                    "genesis":1539098983
                }
            
            ]
        }
         */
        ISoulBoundMedal medalContract = ISoulBoundMedal(_address);
        string[] memory _medalnameArr;
        string[] memory _medaluriArr;
        ISoulBoundMedal.MedalPanel[] memory _medalPanel;
        try medalContract.getMedals() returns (
            string[] memory __medalnameArr,
            string[] memory __medaluriArr,
            ISoulBoundMedal.MedalPanel[] memory __medalPanel
        ) {
            _medalnameArr = __medalnameArr;
            _medaluriArr = __medaluriArr;
            _medalPanel = __medalPanel;
        } catch {}
        string memory daoName = getName(_address);
        address daoOwner = getOwner(_address);
        string memory result = string(
            abi.encodePacked(
                '{"name":"',
                Base64.encode(bytes(daoName)),
                '","owner":"',
                Strings.toHexString(uint256(uint160(daoOwner))),
                '","total":'
            )
        );
        //string memory result = '{"total":';
        result = string(
            abi.encodePacked(
                result,
                Strings.toString(_medalnameArr.length),
                ',"medals":['
            )
        );
        unchecked {
            for (uint256 i = offset; i < offset + limit; i++) {
                if (i >= _medalnameArr.length) {
                    break;
                }
                if (i > offset) {
                    result = string(abi.encodePacked(result, ","));
                }
                result = string(
                    abi.encodePacked(
                        result,
                        "{",
                        '"index":',
                        Strings.toString(i),
                        ',"name":"',
                        Base64.encode(bytes(_medalnameArr[i])),
                        '","uri":"',
                        Base64.encode(bytes(_medaluriArr[i])),
                        '","request":',
                        Strings.toString(_medalPanel[i]._request),
                        ',"approved":',
                        Strings.toString(_medalPanel[i]._approved),
                        ',"rejected":',
                        Strings.toString(_medalPanel[i]._rejected),
                        ',"genesis":',
                        Strings.toString(_medalPanel[i]._genesis),
                        "}"
                    )
                );
            }
        }
        result = string(abi.encodePacked(result, "]}"));

        return result;
    }

    // endregion

    // region tokenId

    /**
     * @dev get tokenId or cliam status by DAO and medal index
     * @param _user address user address
     * @param _dao address DAO contract address
     * @param _medalIndex uint256 medal index
     * @return uint256   1:pending,2:rejected ,>2 tokenid
     */
    function _getCliamStatusByBytes32Key(
        address _user,
        address _dao,
        uint256 _medalIndex
    ) private view returns (uint256) {
        ISoulBoundMedal medalContract = ISoulBoundMedal(_dao);
        bytes32 k = keccak256(abi.encodePacked(_user, _medalIndex));
        try medalContract.getCliamStatusByBytes32Key(k) returns (
            uint256 _status
        ) {
            return _status;
        } catch {}
        return 0;
    }

    // endregion

    // region user

    /**
     * @dev get user info
     * @param _address address user address
     * @return string json string of user info
     */
    function userDetail(address _address) public view returns (string memory) {
        /* 
{
    "owned": [
        "0x1",
        "0x2"
    ],
    "dao": [
        {
            "address": "0x1",
            "medals": [
                {
                    "medalindex": 0, 
                    "status":1, //status of the cliam,0:nodata, 1:pending,2:rejected ,>2 tokenid
                    "name": "base64 string",
                    "uri": "base64 string",
                    "request": 0,
                    "approved": 0,
                    "rejected": 0,
                    "genesis": 1539098983
                }
            ]
        }
    ]
}
         */
        string memory result = '{"owned":[';

        {
            //Stack too deep
            address[] memory _ownerArr = contractOwnerMap[_address];
            uint256 _i = 0;
            for (uint256 i = 0; i < _ownerArr.length; i++) {
                address _dao = _ownerArr[i];
                ITokenInfo ownable = ITokenInfo(_dao);
                address owner = ownable.owner();
                if (owner != _address) {
                    continue;
                }
                if (_i > 0) {
                    result = string(abi.encodePacked(result, ","));
                }
                result = string(
                    abi.encodePacked(
                        result,
                        '"',
                        Strings.toHexString(uint256(uint160(_dao))),
                        '"'
                    )
                );
                _i++;
            }
        }
        result = string(abi.encodePacked(result, '],"dao":['));
        {
            uint256[] memory userDaoMedals = userDaoMedalsDaoIndexMap[_address];

            for (uint256 i = 0; i < userDaoMedals.length; i++) {
                //for (uint256 i = _pageIndex*5; i < 5*(_pageIndex+1); i++) {
                if (i > 0) {
                    result = string(abi.encodePacked(result, ","));
                }
                address _dao = storageEnumerableDAOArr[userDaoMedals[i] - 1];
                {
                    result = string(
                        abi.encodePacked(
                            result,
                            '{"address":"',
                            Strings.toHexString(uint256(uint160(_dao))),
                            '","medals":['
                        )
                    );
                }
                {
                    ISoulBoundMedal medalContract = ISoulBoundMedal(_dao);
                    string[] memory _medalnameArr;
                    string[] memory _medaluriArr;
                    ISoulBoundMedal.MedalPanel[] memory _medalPanel;
                    {
                        try medalContract.getMedals() returns (
                            string[] memory __medalnameArr,
                            string[] memory __medaluriArr,
                            ISoulBoundMedal.MedalPanel[] memory __medalPanel
                        ) {
                            _medalnameArr = __medalnameArr;
                            _medaluriArr = __medaluriArr;
                            _medalPanel = __medalPanel;
                        } catch {}
                    }
                    uint256[]
                        memory requestedMedalIndexArrary = userDaoMedalIndexMapIndex[
                            keccak256(abi.encodePacked(_address, _dao))
                        ];

                    for (
                        uint256 j = 0;
                        j < requestedMedalIndexArrary.length;
                        j++
                    ) {
                        if (j > 0) {
                            result = string(abi.encodePacked(result, ","));
                        }
                        uint256 status = 0;
                        uint256 medalIndex = requestedMedalIndexArrary[j];
                        {
                            try
                                medalContract.getCliamStatusByBytes32Key(
                                    keccak256(
                                        abi.encodePacked(_address, medalIndex)
                                    )
                                )
                            returns (uint256 _status) {
                                status = _status;
                            } catch {}
                        }
                        {
                            result = string(
                                abi.encodePacked(
                                    result,
                                    '{"medalindex":',
                                    Strings.toString(medalIndex),
                                    ',"status":',
                                    Strings.toString(status),
                                    ',"name":"',
                                    Base64.encode(
                                        bytes(_medalnameArr[medalIndex])
                                    ),
                                    '","uri":"',
                                    Base64.encode(
                                        bytes(_medaluriArr[medalIndex])
                                    ),
                                    '","request":',
                                    Strings.toString(
                                        _medalPanel[medalIndex]._request
                                    ),
                                    ',"approved":',
                                    Strings.toString(
                                        _medalPanel[medalIndex]._approved
                                    ),
                                    ',"rejected":',
                                    Strings.toString(
                                        _medalPanel[medalIndex]._rejected
                                    ),
                                    ',"genesis":',
                                    Strings.toString(
                                        _medalPanel[medalIndex]._genesis
                                    ),
                                    "}"
                                )
                            );
                        }
                    }
                }
                result = string(abi.encodePacked(result, "]}"));
            }
        }

        result = string(abi.encodePacked(result, "]}"));

        return result;
    }

    // endregion
}