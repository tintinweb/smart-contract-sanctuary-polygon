/**
 *Submitted for verification at polygonscan.com on 2022-05-31
*/

// SPDX-License-Identifier: MIT
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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
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

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

/**
 * @title PostPlazaApproved
 * @author PostPlaza
 *
 *   An approved address is a wallet that is generated in a user’s browser to 
 *   sign transactions on their behalf. Without an approved address, users would 
 *   have to sign a message for every interaction, including likes, posts, reposts, etc. 
 *   With an approved address, the UI feels more like a Web2 social network.
 */

contract PostPlazaApproved {

    event NewApprovedAddress(address indexed approverAddress, address approveAddress);

    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,address verifyingContract)");
    bytes32 private constant APPROVE_ACCOUNT_TYPEHASH = keccak256("ApproveAccount(uint256 nonce,address approveAddress)");

    // Approved address can do interactions on behalf of user to improve UI.
    mapping(address => address) public approvedAddress;

    mapping(address => uint256) public sigTransactionNonce;

    constructor() {}

    // Set an approved address for either msg.sender or the signer of an ApproveAccount signature.
    function setApprovedAddress(address _approveAddress, uint256 _nonce, bytes32 r, bytes32 s, uint8 v) public {
        if (v >= 27) {
            address signer = ecrecover(hashApproveAccountTransaction(address(this), _nonce, _approveAddress), v, r, s);
            require(_nonce > sigTransactionNonce[signer], "NonceErr");
            sigTransactionNonce[signer] = _nonce;
            approvedAddress[signer] = _approveAddress;
            emit NewApprovedAddress(signer, _approveAddress);
        }
        else {
            approvedAddress[msg.sender] = _approveAddress;
            emit NewApprovedAddress(msg.sender, _approveAddress);
        }
    }

    // It's important to change version every deploy even across chains. This is since there isn't a chainId.
    // chainId wasn't included since some wallets have trouble switching networks.
    function getDomainSeperator(address verifyingContract) public pure returns (bytes32) {
        bytes32 DOMAIN_SEPARATOR = keccak256(abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes("PostPlaza Approved Domain")),  // name
                keccak256(bytes("1")),                          // version
                verifyingContract
            ));
        return DOMAIN_SEPARATOR;
    }

    function hashApproveAccountTransaction(address verifyingContract, uint256 _nonce, address _approveAddress) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(APPROVE_ACCOUNT_TYPEHASH, _nonce, _approveAddress))));
    }
}

/**
 * @title NFP
 * @author PostPlaza
 *
 *   NFP means: NonFungiblePost.
 *   This simple NFT contract that relies heavily on the NonFungiblePosts contract.
 *   The NonFungiblePosts contract holds all of an NFP's data and interfaces.
 *   This NFP lives inside the poster's address collection.
 **/

contract NFP is ERC721Burnable, Ownable {

    address public NonFungiblePostsContract;
 
    // An NFP is created by the NonFungiblePosts contract.
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        NonFungiblePostsContract = msg.sender;
    }

    function exists(uint256 tokenId)
        public
        view
        returns (bool)
    {
        return _exists(tokenId);
    }

    function safeMint(address poster, uint256 tokenId) external {
        require(!_exists(tokenId), "TokenExists");
        require(msg.sender == NonFungiblePostsContract);
        _safeMint(poster, tokenId);
    }

    // The NonFungiblePosts contract can burn the token. Only the owner of the NFP can burn it with this
    // function. The NonFungiblePosts contract requires the current owner to have also posted the NFP.
    function burnNFP(uint256 tokenId) external {
        require(_exists(tokenId), "Token Doesn't Exist");
        require(msg.sender == NonFungiblePostsContract || msg.sender == ownerOf(tokenId));
        _burn(tokenId);
    }

    function getApprovedAddress(address _user) public view returns (address) {
        NonFungiblePosts nfposts = NonFungiblePosts(NonFungiblePostsContract);
        return nfposts.getApprovedAddress(_user);
    }

    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist Approved Address.
        if (operator == getApprovedAddress(owner)) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function setApprovalForAll(address _owner, address _operator, bool _approved) public {
        require(msg.sender == NonFungiblePostsContract || msg.sender == _owner);
        _setApprovalForAll(_owner, _operator, _approved);
    }

    // Let the NonFungiblePosts contract know of the transfer, so it can emit an Event.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        NonFungiblePosts nfposts = NonFungiblePosts(NonFungiblePostsContract);
        nfposts.nfpTransfer(from, to, tokenId);
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        NonFungiblePosts nfposts = NonFungiblePosts(NonFungiblePostsContract);
        nfposts.nfpTransfer(from, to, tokenId);
        super.transferFrom(from, to, tokenId);
    }

    // Since the NonFungiblePosts contract holds the data, get tokenURI from there.
    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        NonFungiblePosts nfposts = NonFungiblePosts(NonFungiblePostsContract);
        return nfposts.tokenURI(_tokenId);
    }
}

/**
 * @title NonFungiblePosts
 * @author PostPlaza
 *
 *   The posting contract for PostPlaza. 
 *   All text content is stored on-chain.
 **/

contract NonFungiblePosts is Ownable {

    event NewPost(string content, address indexed poster, address parentPostContract, uint256 indexed parentPostId, uint256 postTimestamp, string[] tags, address tokenContract, uint256 tokenId);
    event DeletePost(uint256 indexed tokenId);
    event Upvote(address indexed upvoter, uint256 indexed tokenId, bytes32 indexed seed);
    event RemoveUpvote(address indexed upvoter, uint256 indexed tokenId, bytes32 indexed seed);
    event Downvote(address indexed downvoter, uint256 indexed tokenId, bytes32 indexed seed);
    event RemoveDownvote(address indexed downvoter, uint256 indexed tokenId, bytes32 indexed seed);
    event Repost(address indexed reposter, uint256 indexed tokenId, bytes32 indexed seed);
    event RemoveRepost(address indexed reposter, uint256 indexed tokenId, bytes32 indexed seed);
    event NewNFPCollection(address indexed creator, address indexed collectionAddress, string name);
    event NFPTransfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event NFPApproved(address indexed contractAddress, address indexed owner, address indexed operator, bool approved);

    // Approved address can do interactions on behalf of user to improve UI.
    address public approvedAddressContract;

    // When someone signs a message, the message must include a nonce which is greater
    // than this value. This is to prevent someone submitting the same signed transacation twice.
    mapping(address => uint256) public sigTransactionNonce;

    // The default link for a post without the tokenId.
    string basePostLink;

    mapping(address => address) public addressCollection;

    // --------- For Post ---------
    mapping(uint256 => bytes32) public seed;                // Seed also exists so as to have different tokenIds for two posts with the same content.
    mapping(uint256 => string) public content;              // Can include link to ipfs content.
    mapping(uint256 => string) metadataURI;                 // This is only set when a post includes an image. With no image an svg is generated with the text.
    mapping(uint256 => address) public poster;
    mapping(uint256 => address) public parentPostAddress;   // Contract of post replying to
    mapping(uint256 => uint256) public parentPostId;        // TokenID of post replying to
    mapping(uint256 => uint256) public postTimestamp;
    mapping(uint256 => string[]) public tags;               // Can be used for title, tags, etc.

    constructor(address postPlazaApproved) {
        approvedAddressContract = postPlazaApproved;
    }

    function getApprovedAddress(address _user) public view returns (address) {
        PostPlazaApproved postPlazaApproved = PostPlazaApproved(approvedAddressContract);
        return postPlazaApproved.approvedAddress(_user);
    }

    // Calls the setApprovalForAll function of the given _nfpContract for the _owner and sets 
    // _operator as approved.
    function setApprovalForAllByApprovedAddress(address _nfpContract, address _owner, address _operator, bool _approved, uint256 _nonce, bytes32 r, bytes32 s, uint8 v) public {
        if (v >= 27) { // Use signature
            address signer = ecrecover(HashTransaction.hashSetApprovalTransaction(address(this), _nonce, _nfpContract, _owner, _operator, _approved), v, r, s);
            require(_nonce > sigTransactionNonce[signer], "NonceErr");
            sigTransactionNonce[signer] = _nonce;
            require(signer == _owner || signer == getApprovedAddress(_owner), "ApproveErr1");
        }
        else {
            require(msg.sender == _owner || msg.sender == getApprovedAddress(_owner), "ApproveErr2");
        }
        NFP nfp = NFP(_nfpContract);
        nfp.setApprovalForAll(_owner, _operator, _approved);
        emit NFPApproved(_nfpContract, _owner, _operator, _approved);
    }

    // Creates a collection for the address's NFT posts. 
    // If this isn’t called, a collection is automatically created when the address mints their first post.
    function createCollectionProfile(address _creator, string memory _name, bytes32 r, bytes32 s, uint8 v) public {
        if (v >= 27) { // Use signature
            address signer = ecrecover(HashTransaction.hashCreateCollectionTransaction(address(this), _creator, _name), v, r, s);
            require(signer == _creator || signer == getApprovedAddress(_creator), "ApproveErr1");
        }
        else {
            require(msg.sender == _creator || msg.sender == getApprovedAddress(_creator), "ApproveErr2");
        }

        if (addressCollection[_creator] == address(0)) {
            NFP newNFPContract = new NFP(_name, _name);
            addressCollection[_creator] = address(newNFPContract);
            emit NewNFPCollection(_creator, address(newNFPContract), _name);
            newNFPContract.transferOwnership(_creator);
        }
    }

    // Mint a post.
    // A post's text data is stored on-chain. 
    // Inside the content parameter: 
    //  ...“;IpfsImageHash:[imgIPFSHash]” is used to set an image.
    //  ...";PostNFT:[nft_addr]_[nft_id]” is used to set an external NFT image.
    // _metadataURI is only to be used if there is an image, in which case the 
    // NFT's image is off-chain instead of svg generated.
    // Tags can be used to differentiate between types of posts and types of platforms posts should be shown on.
    function mintPost(address _poster, string memory _content, string memory _metadataURI, address _parentPostContract, uint256 _parentPostId, string[] memory _tags, bytes32 _seed, bytes32 r, bytes32 s, uint8 v) public {
        if (v >= 27) { // Use signature
            address signer = ecrecover(HashTransaction.hashMintTransaction(address(this), _poster, _content, _metadataURI, _parentPostContract, _parentPostId, _tags, _seed), v, r, s);
            require(signer == _poster || signer == getApprovedAddress(_poster), "ApproveErr1");
        }
        else {
            require(msg.sender == _poster || msg.sender == getApprovedAddress(_poster), "ApproveErr2");
        }

        if (addressCollection[_poster] == address(0)) {
            // Creates address collection for poster if they don't have one already.
            string memory addressString = TokenURIHelper.addressToString(_poster);
            NFP newNFPContract = new NFP(string(abi.encodePacked("NFPs from ", addressString)), string(abi.encodePacked(addressString, "NFP")));
            addressCollection[_poster] = address(newNFPContract);
            emit NewNFPCollection(_poster, address(newNFPContract), string(abi.encodePacked("NFPs from ", addressString)));
            newNFPContract.transferOwnership(_poster);
        }
        address tokenContract = addressCollection[_poster];
        NFP nfp = NFP(tokenContract);

        uint256 tokenId = uint256(uint256(keccak256(abi.encodePacked(_content, _poster, _seed)))/1000000000000000000000000000000000000000000000000000000000);
        require(_tags.length < 11, "TagsLimit");

        // Check to see if post has already been minted but transfered or deleted. This check is not needed for mintFromBridge.
        require(seed[tokenId] == 0, "Token has already been minted in the past.");

        nfp.safeMint(_poster, tokenId);
        postTimestamp[tokenId] = block.timestamp;
        poster[tokenId] = _poster;
        content[tokenId] = _content;
        metadataURI[tokenId] = _metadataURI;
        tags[tokenId] = _tags;
        parentPostAddress[tokenId] = _parentPostContract;
        parentPostId[tokenId] = _parentPostId;
        seed[tokenId] = _seed;

        emit NewPost(_content, _poster, _parentPostContract, _parentPostId, postTimestamp[tokenId], _tags, tokenContract, tokenId);
    }

    function getTokenId(address _poster, string memory _content, bytes32 _seed) public pure returns (uint256) {
        uint256 tokenId = uint256(uint256(keccak256(abi.encodePacked(_content, _poster, _seed)))/1000000000000000000000000000000000000000000000000000000000);
        return tokenId;
    }

    function batchMintPosts(address[] memory _posters, string[] memory _content, string[] memory _metadataURI, address[] memory _parentPostContract, uint256[] memory _parentPostId, string[][] memory _tags, bytes32[] memory _seed, bytes32[] memory r, bytes32[] memory s, uint8[] memory v) public {
        for(uint256 i=0; i<_posters.length; i++) {
            mintPost(_posters[i], _content[i], _metadataURI[i], _parentPostContract[i], _parentPostId[i], _tags[i], _seed[i], r[i], s[i], v[i]);
        }
    }

    // nfpTransfer is called by the NFP NFT when it is being transferred.
    // This allows for easier indexing since it emits an event with the transfer.
    // An indexer only needs to listen to this contract to get all NFP transfer events.
    function nfpTransfer (address from, address to, uint256 tokenId) external {
        require(msg.sender == addressCollection[poster[tokenId]]);
        emit NFPTransfer(from, to, tokenId);
    }

    function deletePost(address _owner, uint256 _tokenId, uint256 _nonce, bytes32 r, bytes32 s, uint8 v) public {
        if (v >= 27) { // Use signature
            address signer = ecrecover(HashTransaction.hashDeletePostTransaction(address(this), _nonce, _owner, _tokenId), v, r, s);
            require(_nonce > sigTransactionNonce[signer], "NonceErr");
            sigTransactionNonce[signer] = _nonce;
            require(signer == _owner || signer == getApprovedAddress(_owner), "ApproveErr1");
        }
        else {
            require(msg.sender == _owner || msg.sender == getApprovedAddress(_owner), "ApproveErr2");
        }
        NFP nfp = NFP(addressCollection[poster[_tokenId]]);

        require(nfp.exists(_tokenId), "Token ID doesn't exist.");
        require(_owner == poster[_tokenId], "NotCreator");
        require(_owner == nfp.ownerOf(_tokenId), "NotOwner");
        
        nfp.burnNFP(_tokenId);
        delete content[_tokenId];
        delete metadataURI[_tokenId];
        delete poster[_tokenId];
        delete postTimestamp[_tokenId];
        delete parentPostAddress[_tokenId];
        delete parentPostId[_tokenId];
        delete tags[_tokenId];
        // Does not delete seed so that token can't be re-minted.

        emit DeletePost(_tokenId);
    }

    // ----------------------- Upvotes, Downvotes, Reposts -----------------------

    // Upvotes, downvotes, and reposts are only stored as events. It would be too expensive to store
    // this information in EVM storage.

    // Instead of using a nonce, a seed is used. This way, when indexing, an upvote can be ignored if re-sent.
    // So if upvote with seed a, downvote with seed b, then upvote with seed a again are sent.
    // The second upvote with seed a is ignored and database isn't updated with it.
    function upvote(address _upvoter, uint256 _tokenId, bytes32 _seed, bytes32 r, bytes32 s, uint8 v) public {
        if (v >= 27) { // Use signature
            address signer = ecrecover(HashTransaction.hashUpvoteTransaction(address(this), _seed, _upvoter, _tokenId), v, r, s);
            require(signer == _upvoter || signer == getApprovedAddress(_upvoter), "ApproveErr1");
        }
        else {
            require(msg.sender == _upvoter || msg.sender == getApprovedAddress(_upvoter), "ApproveErr2");
        }
        emit Upvote(_upvoter, _tokenId, _seed);
    }

    function batchUpvotes(address[] memory _upvoters, uint256[] memory _tokenIds, bytes32[] memory _seeds, bytes32[] memory r, bytes32[] memory s, uint8[] memory v) public {
        for(uint256 i=0; i<_upvoters.length; i++) {
            upvote(_upvoters[i], _tokenIds[i], _seeds[i], r[i], s[i], v[i]);
        }
    }

    function removeUpvote(address _upvoter, uint256 _tokenId, bytes32 _seed, bytes32 r, bytes32 s, uint8 v) public {
        if (v >= 27) { // Use signature
            address signer = ecrecover(HashTransaction.hashRemoveUpvoteTransaction(address(this), _seed, _upvoter, _tokenId), v, r, s);
            require(signer == _upvoter || signer == getApprovedAddress(_upvoter), "ApproveErr1");
        }
        else {
            require(msg.sender == _upvoter || msg.sender == getApprovedAddress(_upvoter), "ApproveErr2");
        }
        emit RemoveUpvote(_upvoter, _tokenId, _seed);
    }

    function batchRemoveUpvotes(address[] memory _upvoters, uint256[] memory _tokenIds, bytes32[] memory _seeds, bytes32[] memory r, bytes32[] memory s, uint8[] memory v) public {
        for(uint256 i=0; i<_upvoters.length; i++) {
            removeUpvote(_upvoters[i], _tokenIds[i], _seeds[i], r[i], s[i], v[i]);
        }
    }

    function downvote(address _downvoter, uint256 _tokenId, bytes32 _seed, bytes32 r, bytes32 s, uint8 v) public {
        if (v >= 27) { // Use signature
            address signer = ecrecover(HashTransaction.hashDownvoteTransaction(address(this), _seed, _downvoter, _tokenId), v, r, s);
            require(signer == _downvoter || signer == getApprovedAddress(_downvoter), "ApproveErr1");
        }
        else {
            require(msg.sender == _downvoter || msg.sender == getApprovedAddress(_downvoter), "ApproveErr2");
        }
        emit Downvote(_downvoter, _tokenId, _seed);
    }

    function batchDownvotes(address[] memory _downvoters, uint256[] memory _tokenIds, bytes32[] memory _seeds, bytes32[] memory r, bytes32[] memory s, uint8[] memory v) public {
        for(uint256 i=0; i<_downvoters.length; i++) {
            downvote(_downvoters[i], _tokenIds[i], _seeds[i], r[i], s[i], v[i]);
        }
    }

    function removeDownvote(address _downvoter, uint256 _tokenId, bytes32 _seed, bytes32 r, bytes32 s, uint8 v) public {
        if (v >= 27) { // Use signature
            address signer = ecrecover(HashTransaction.hashRemoveDownvoteTransaction(address(this), _seed, _downvoter, _tokenId), v, r, s);
            require(signer == _downvoter || signer == getApprovedAddress(_downvoter), "ApproveErr1");
        }
        else {
            require(msg.sender == _downvoter || msg.sender == getApprovedAddress(_downvoter), "ApproveErr2");
        }
        emit RemoveDownvote(_downvoter, _tokenId, _seed);
    }

    function batchRemoveDownvotes(address[] memory _downvoters, uint256[] memory _tokenIds, bytes32[] memory _seeds, bytes32[] memory r, bytes32[] memory s, uint8[] memory v) public {
        for(uint256 i=0; i<_downvoters.length; i++) {
            removeDownvote(_downvoters[i], _tokenIds[i], _seeds[i], r[i], s[i], v[i]);
        }
    }

    function repost(address _reposter, uint256 _tokenId, bytes32 _seed, bytes32 r, bytes32 s, uint8 v) public {
        if (v >= 27) { // Use signature
            address signer = ecrecover(HashTransaction.hashRepostTransaction(address(this), _seed, _reposter, _tokenId), v, r, s);
            require(signer == _reposter || signer == getApprovedAddress(_reposter), "ApproveErr1");
        }
        else {
            require(msg.sender == _reposter || msg.sender == getApprovedAddress(_reposter), "ApproveErr2");
        }
        emit Repost(_reposter, _tokenId, _seed);
    }

    function batchReposts(address[] memory _reposters, uint256[] memory _tokenIds, bytes32[] memory _seeds, bytes32[] memory r, bytes32[] memory s, uint8[] memory v) public {
        for(uint256 i=0; i<_reposters.length; i++) {
            repost(_reposters[i], _tokenIds[i], _seeds[i], r[i], s[i], v[i]);
        }
    }

    function removeRepost(address _reposter, uint256 _tokenId, bytes32 _seed, bytes32 r, bytes32 s, uint8 v) public {
        if (v >= 27) { // Use signature
            address signer = ecrecover(HashTransaction.hashRemoveRepostTransaction(address(this), _seed, _reposter, _tokenId), v, r, s);
            require(signer == _reposter || signer == getApprovedAddress(_reposter), "ApproveErr1");
        }
        else {
            require(msg.sender == _reposter || msg.sender == getApprovedAddress(_reposter), "ApproveErr2");
        }
        emit RemoveRepost(_reposter, _tokenId, _seed);
    }

    // ----------------------- tokenURI -----------------------

    function setBasePostLink(string memory base) public onlyOwner {
        basePostLink = base;
    }

    // Returns an SVG with the content if it has no metadata, otherwise returns metadata.
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        if (bytes(metadataURI[_tokenId]).length == 0) {
            return TokenURIHelper.getTokenData(_tokenId, content[_tokenId], parentPostId[_tokenId], basePostLink);
        }
        else {
            return metadataURI[_tokenId];
        }
    }
}

library TokenURIHelper {

    function intToString(uint256 value) public pure returns (string memory) {
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

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function addressToString(address x) public pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function getTokenData(uint256 tokenId, string memory content, uint256 parentPostId, string memory basePostLink) public pure returns (string memory) {
        string[16] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 550 550"> <defs> <linearGradient id="Gradient1"> <stop class="stop1" offset="0%"/> <stop class="stop2" offset="50%"/> <stop class="stop3" offset="100%"/> </linearGradient> <linearGradient id="Gradient2" x1="" x2="1" y1="0" y2="1"> <stop offset="0%" stop-color="#833ab4"/> <stop offset="100%" stop-color="#1d85fd"/> </linearGradient> <style type="text/css"><![CDATA[ #rect1 { fill: url(#Gradient1); } .stop1 { stop-color: red; } .stop2 { stop-color: black; stop-opacity: 0; } .stop3 { stop-color: blue; } ]]></style><rect id="rect" x="25%" y="12%" width="50%" height="50%" rx="15"/><clipPath id="clip"><use href="#rect"/></clipPath></defs> <rect width="100%" height="100%" fill="url(#Gradient2)" /> <rect x="5%" y="5%" width="90%" height="85%" style="fill:#fff" rx="15" /> <text x="520" y="530" fill="#fff" text-anchor="end" font-size="1em">';
        parts[1] = 'View this post at ';
        parts[2] = basePostLink;
        parts[3] = intToString(tokenId);
        parts[4] = '</text>';
        parts[5] = '<foreignObject class="node" x="50" y="50" width="460" height="430" requiredFeatures="http://www.w3.org/TR/SVG11/feature#Extensibility">';

        if (parentPostId != 0) {
            parts[6] = '<div xmlns="http://www.w3.org/1999/xhtml" style="font-family: avenir; font-weight: bold; font-size: 14px; color: lightgrey; text-align: left; margin-bottom: 10px">';
            parts[7] = 'Reply to ';
            parts[8] = basePostLink;
            parts[9] = intToString(parentPostId);
            parts[10] = '</div>';
            parts[11] = '<div xmlns="http://www.w3.org/1999/xhtml" style="font-family: avenir; font-weight: bold; font-size: 25px; text-align: left;">';
            parts[12] = content;
            parts[13] = '</div>';
            parts[14] = '</foreignObject>';
            parts[15] = '</svg>';
        }
        else {
            parts[6] = '<div xmlns="http://www.w3.org/1999/xhtml" style="font-family: avenir; font-weight: bold; font-size: 25px; text-align: left;">';
            parts[7] = content;
            parts[8] = '</div>';
            parts[9] = '</foreignObject>';
            parts[10] = '</svg>';
        }

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));
        output = string(abi.encodePacked(output, parts[7], parts[8], parts[9], parts[10], parts[11], parts[12]));
        output = string(abi.encodePacked(output, parts[13], parts[14], parts[15]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "NFT Post. Id: ', intToString(tokenId), '", "description": "View at PostPlaza, a web3 social platform. ', basePostLink, intToString(tokenId), ' | ', content , '", "external_url": "', basePostLink, intToString(tokenId), '", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }
}

library HashTransaction {
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant CREATE_COLLECTION_TYPEHASH = keccak256("CreateCollection(address creator,string name)");
    bytes32 private constant POST_TYPEHASH = keccak256("Post(address poster,string content,string metadataURI,address parentPostContract,uint256 parentPostId,string[] tags,bytes32 seed)");
    bytes32 private constant DELETE_POST_TYPEHASH = keccak256("DeletePost(uint256 nonce,address poster,uint256 tokenId)");
    bytes32 private constant UPVOTE_TYPEHASH = keccak256("Upvote(bytes32 seed,address upvoter,uint256 tokenId)");
    bytes32 private constant REMOVE_UPVOTE_TYPEHASH = keccak256("RemoveUpvote(bytes32 seed,address upvoter,uint256 tokenId)");
    bytes32 private constant DOWNVOTE_TYPEHASH = keccak256("Downvote(bytes32 seed,address downvoter,uint256 tokenId)");
    bytes32 private constant REMOVE_DOWNVOTE_TYPEHASH = keccak256("RemoveDownvote(bytes32 seed,address downvoter,uint256 tokenId)");
    bytes32 private constant REPOST_TYPEHASH = keccak256("Repost(bytes32 seed,address reposter,uint256 tokenId)");
    bytes32 private constant REMOVE_REPOST_TYPEHASH = keccak256("RemoveRepost(bytes32 seed,address reposter,uint256 tokenId)");
    bytes32 private constant PIN_TYPEHASH = keccak256("PinPost(uint256 nonce,address pinner,uint256 tokenId)");
    bytes32 private constant SET_APPROVAL_TYPEHASH = keccak256("SetApproval(uint256 nonce,address nfpContract,address owner,address operator,bool approved)");
    uint256 constant chainId = 137;

    function getDomainSeperator(address verifyingContract) public pure returns (bytes32) {
        bytes32 DOMAIN_SEPARATOR = keccak256(abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes("PostPlaza Post Domain")),      // name
                keccak256(bytes("1")),                          // version
                chainId,
                verifyingContract
            ));
        return DOMAIN_SEPARATOR;
    }

    function encodeStringArray(string[] memory strings) public pure returns(bytes memory){
        bytes memory data;
        for(uint i=0; i<strings.length; i++){
            data = abi.encodePacked(data, keccak256(bytes(strings[i])));
        }
        return data;
    }

    function hashCreateCollectionTransaction(address verifyingContract, address _creator, string memory _name) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(CREATE_COLLECTION_TYPEHASH, _creator, keccak256(bytes(_name))))));
    }

    function hashMintTransaction(address verifyingContract, address _poster, string memory _content, string memory _metadataURI, address _parentPostContract, uint256 _parentPostId, string[] memory _tags, bytes32 _seed) public pure returns (bytes32) {
        bytes memory encodedTags = encodeStringArray(_tags);
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(POST_TYPEHASH, _poster, keccak256(bytes(_content)), keccak256(bytes(_metadataURI)), _parentPostContract, _parentPostId, keccak256(encodedTags), _seed))));
    }

    function hashDeletePostTransaction(address verifyingContract, uint256 _nonce, address _poster, uint256 _tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(DELETE_POST_TYPEHASH, _nonce, _poster, _tokenId))));
    }

    function hashUpvoteTransaction(address verifyingContract, bytes32 _seed, address _upvoter, uint256 _tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(UPVOTE_TYPEHASH, _seed, _upvoter, _tokenId))));
    }

    function hashRemoveUpvoteTransaction(address verifyingContract, bytes32 _seed, address _upvoter, uint256 _tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(REMOVE_UPVOTE_TYPEHASH, _seed, _upvoter, _tokenId))));
    }

    function hashDownvoteTransaction(address verifyingContract, bytes32 _seed, address _downvoter, uint256 _tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(DOWNVOTE_TYPEHASH, _seed, _downvoter, _tokenId))));
    }

    function hashRemoveDownvoteTransaction(address verifyingContract, bytes32 _seed, address _downvoter, uint256 _tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(REMOVE_DOWNVOTE_TYPEHASH, _seed, _downvoter, _tokenId))));
    }

    function hashRepostTransaction(address verifyingContract, bytes32 _seed, address _reposter, uint256 _tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(REPOST_TYPEHASH, _seed, _reposter, _tokenId))));
    }

    function hashRemoveRepostTransaction(address verifyingContract, bytes32 _seed, address _reposter, uint256 _tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(REMOVE_REPOST_TYPEHASH, _seed, _reposter, _tokenId))));
    }

    function hashPinPostTransaction(address verifyingContract, uint256 _nonce, address _pinner, uint256 _tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(PIN_TYPEHASH, _nonce, _pinner, _tokenId))));
    }

    function hashSetApprovalTransaction(address verifyingContract, uint256 _nonce, address _nfpContract, address _owner, address _operator, bool _approved) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(SET_APPROVAL_TYPEHASH, _nonce, _nfpContract, _owner, _operator, _approved))));
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes public constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}