/**
 *Submitted for verification at polygonscan.com on 2022-06-01
*/

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

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

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



// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;


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
}
// https://github.com/ProjectOpenSea/opensea-creatures/blob/master/contracts/common/meta-transactions/Initializable.sol

pragma solidity ^0.8.0;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}


// https://github.com/ProjectOpenSea/opensea-creatures/blob/master/contracts/common/meta-transactions/EIP712Base.sol

pragma solidity ^0.8.0;

//import {Initializable} from "./Initializable.sol";

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contracts that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name
    )
        internal
        initializer
    {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// https://github.com/ProjectOpenSea/opensea-creatures/blob/master/contracts/common/meta-transactions/NativeMetaTransaction.sol

pragma solidity ^0.8.0;

// import {SafeMath} from  "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import {EIP712Base} from "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}
// https://github.com/ProjectOpenSea/opensea-creatures/blob/master/contracts/common/meta-transactions/ContentMixin.sol
pragma solidity ^0.8.0;

abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

// import "../utils/Context.sol";

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

// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

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
}


// https://github.com/ProjectOpenSea/opensea-creatures/blob/master/contracts/ERC721Tradable.sol


pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
/*import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";*/

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is ERC721, ContextMixin, NativeMetaTransaction, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    /**
     * We rely on the OZ Counter util to keep track of the next available ID.
     * We track the nextTokenId instead of the currentTokenId to save users on gas costs. 
     * Read more about it here: https://shiny.mirror.xyz/OUampBbIz9ebEicfGnQf5At_ReMHlZy0tB4glb9xQ0E
     */ 
    Counters.Counter private _nextTokenId;
    address proxyRegistryAddress;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        // nextTokenId is initialized to 1, since starting at 0 leads to higher gas cost for the first minter
        _nextTokenId.increment();
        _initializeEIP712(_name);
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to) public onlyOwner {
        uint256 currentTokenId = _nextTokenId.current();
        _nextTokenId.increment();
        _safeMint(_to, currentTokenId);
    }

    /**
        @dev Returns the total tokens minted so far.
        1 is always subtracted from the Counter since it tracks the next available tokenId.
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    function baseTokenURI() virtual public pure returns (string memory);

    // OLD function tokenURI(uint256 _tokenId) override public pure returns (string memory) {
    function tokenURI(uint256 _tokenId) virtual override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

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

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol
// Creator: Chiru Labs

pragma solidity ^0.8.4;

//import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
//import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
//import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
//import '@openzeppelin/contracts/utils/Address.sol';
//import '@openzeppelin/contracts/utils/Context.sol';
//import '@openzeppelin/contracts/utils/Strings.sol';
//import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerQueryForNonexistentToken();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
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
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
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
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
        safeTransferFrom(from, to, tokenId, '');
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
        _transfer(from, to, tokenId);
        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex &&
            !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (safe && to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
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
    ) private {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev This is equivalent to _burn(tokenId, false)
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
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
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

pragma solidity ^0.8.0;
/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes internal constant TABLE_DECODE =
        hex"0000000000000000000000000000000000000000000000000000000000000000"
        hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
        hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
        hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 4 characters
                dataPtr := add(dataPtr, 4)
                let input := mload(dataPtr)

                // write 3 bytes
                let output := add(
                    add(
                        shl(
                            18,
                            and(
                                mload(add(tablePtr, and(shr(24, input), 0xFF))),
                                0xFF
                            )
                        ),
                        shl(
                            12,
                            and(
                                mload(add(tablePtr, and(shr(16, input), 0xFF))),
                                0xFF
                            )
                        )
                    ),
                    add(
                        shl(
                            6,
                            and(
                                mload(add(tablePtr, and(shr(8, input), 0xFF))),
                                0xFF
                            )
                        ),
                        and(mload(add(tablePtr, and(input, 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}


// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

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

// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

//import "./IAccessControl.sol";
//import "../utils/Context.sol";
//import "../utils/Strings.sol";
//import "../utils/introspection/ERC165.sol";

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
        _checkRole(role);
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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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

pragma solidity ^0.8.0;

contract Formater{
    function roundUIntToString(uint256 _amount) external pure returns (string memory){
        string memory str;

        if((_amount/ (10 ** 17))>= 10000){
            // Kilo KC (xKC)
            str = Strings.toString(_amount/ (10 ** 21));
            return string(abi.encodePacked(str,'KC')) ;
        } else if( (_amount / (10 ** 17)) < 10 ){
            // Decimal C (0.xC)
            str = Strings.toString(_amount/ (10 ** 17));
            return string(abi.encodePacked('0',substring(str,0,(bytes(str).length-1)),'.',substring(str,(bytes(str).length-1),(bytes(str).length)),'C')) ;
        } else {
            // Integer C (xC)
            str = Strings.toString(_amount/ (10 ** 18));
            return string(abi.encodePacked(str,'C'));
        }
    }

    function substring(string memory str, uint startIndex, uint endIndex) public pure returns (string memory ) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

    function getCarat(uint256 _diamondId) public pure returns (uint256){
        // return the 7th last digit
        return (_diamondId - ((_diamondId / (10 ** 7)) * (10 ** 7)));
    }
    function getCut(uint256 _diamondId) public pure returns (uint256){
        // return the first digit
        return _diamondId / (10 ** 9);
    }
    function getColor(uint256 _diamondId) public pure returns (uint256){
        // return the 2nd digit
        return _diamondId / (10 ** 8) - (getCut(_diamondId) * 10) ;
    }
    function getCharacter(uint256 _diamondId) public pure returns (uint256){
        // return the 3nd digit
        return (_diamondId / (10 ** 7)) - (getColor(_diamondId) * 10) - (getCut(_diamondId)*100)  ;
    }
}

pragma solidity ^0.8.0;
/*library SVG{
    function getBottom(string memory _character, uint256 _caratAmount, uint256 _diamondId) external pure returns (string memory) {
        return string(abi.encodePacked('<text x="50%" y="320" dominant-baseline="middle" text-anchor="middle" fill="'
                            ,'purple' //slot.characterColor
                            ,'" font-family="Super Sans" font-size="10em" font-weight="bold">'
                            , _character
                            ,'</text>'
                            ,'<circle fill="',"purple",'" cx="155" cy="150" r="15"/>'
                            ,'<circle fill="',"purple",'" cx="350" cy="150" r="15"/>'
                            ,'<text x="50%" y="90%" dominant-baseline="middle" text-anchor="middle" fill="purple" font-size="6em" font-weight="bold">'
                            , F.roundUIntToString(_caratAmount * (10 ** 17))
                            ,'</text>'
                            ,'<text x="50%" y="97%" dominant-baseline="middle" text-anchor="middle" fill="purple" font-size="1em" font-weight="bold">'
                            , Strings.toString(_diamondId)
                            ,'</text>'));
    }
    function getPearCut1(string memory _c1, string memory _c2, string memory _c3) external pure returns (string memory) {

        return  string(abi.encodePacked('<path style="opacity:1;fill:'
                        , _c3 
                        , 'stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 218.96334,365.38516 -32.86979,-24.65473 -24.61936,-63.91769 -24.61937,-63.91767 10.82105,-39.44374 c 5.95158,-21.69406 11.34129,-39.93197 11.97714,-40.52869 1.21752,-1.14258 88.64554,-21.68555 92.25172,-21.67638 2.76057,0.007 91.2718,20.72082 92.10606,21.55509 0.35442,0.35442 5.58113,18.47926 11.61493,40.27743 l 10.97054,39.63304 -24.48051,63.80978 -24.4805,63.80979 -32.90107,24.85426 -32.90106,24.85426 z" id="path10371" />'
                        // path 1
                        , '<path style="opacity:1;fill:'
                        , _c3 
                        , 'stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 218.96334,365.38516 -32.86979,-24.65473 -24.61936,-63.91769 -24.61937,-63.91767 10.82105,-39.44374 c 5.95158,-21.69406 11.34129,-39.93197 11.97714,-40.52869 1.21752,-1.14258 88.64554,-21.68555 92.25172,-21.67638 2.76057,0.007 91.2718,20.72082 92.10606,21.55509 0.35442,0.35442 5.58113,18.47926 11.61493,40.27743 l 10.97054,39.63304 -24.48051,63.80978 -24.4805,63.80979 -32.90107,24.85426 -32.90106,24.85426 z" id="path10371" />'
                        // path 2
                        ,'<path style="opacity:1;fill:'
                        , _c1
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="M 77.529405,243.71393 C 62.350737,226.99333 50.075168,212.75238 50.250364,212.06739 50.425559,211.3824 59.37577,197.73794 70.139723,181.74637 l 19.570822,-29.07559 18.560135,30.36691 18.56013,30.36691 -9.9925,28.06382 c -5.49587,15.43509 -10.37923,29.09495 -10.85191,30.35521 -0.7791,2.07723 -3.43875,-0.54996 -28.456995,-28.1097 z" id="path10447" />'
                        // path 3
                        ,'<path style="opacity:1;fill:'
                        , _c1
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="M 113.63842,174.30955 C 100.46254,152.86788 97.286152,147.02879 98.539351,146.5532 c 3.910509,-1.48406 48.675459,-11.30637 49.188829,-10.79299 0.31589,0.31589 -3.47069,15.22839 -8.41464,33.13887 l -8.98898,32.56453 z" id="path10486" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,_c1
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 94.563843,114.28571 c 0,-13.35019 0.240496,-24.273068 0.534435,-24.273068 0.293939,0 15.376902,-2.287457 33.517692,-5.083238 18.14079,-2.79578 33.16518,-4.901305 33.38755,-4.678943 0.60105,0.601052 -10.48331,44.243559 -11.47163,45.167279 -0.78211,0.73099 -52.684314,13.14105 -54.959405,13.14105 -0.642586,0 -1.008642,-8.80917 -1.008642,-24.27308 z" id="path10525" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,_c1
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 48.569744,188.14299 c 1.036323,-13.55315 6.356881,-37.59286 9.329738,-42.15428 0.57375,-0.88033 3.422687,-0.8666 11.604421,0.0559 5.964188,0.6725 11.131192,1.50995 11.482229,1.86098 0.539173,0.53918 -29.317574,45.82446 -32.178876,48.80738 -0.620043,0.6464 -0.705755,-2.44631 -0.237512,-8.57003 z" id="path10564" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,_c1
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 70.58033,138.1644 -9.318534,-1.12268 4.831665,-9.13315 c 4.942546,-9.34274 10.626725,-18.15261 16.220427,-25.13993 l 3.147553,-3.931734 v 20.366624 20.36663 l -2.781289,-0.14153 c -1.52971,-0.0779 -6.97463,-0.64675 -12.099822,-1.26423 z" id="path10603" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,_c1
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 62.165361,284.45006 c -5.524669,-17.22097 -13.433291,-54.88462 -11.855906,-56.462 0.525903,-0.5259 48.2999,51.98876 48.2999,53.09275 0,0.69083 -30.876988,13.23481 -32.569455,13.23156 -0.391076,-7.6e-4 -2.134619,-4.43879 -3.874539,-9.86231 z" id="path10642" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,_c1
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 142.5593,305.83138 c -14.99422,-11.97709 -27.8865,-22.38504 -28.64952,-23.12877 -1.17167,-1.14207 0.0859,-5.53059 8.09103,-28.23429 5.21308,-14.78512 9.70746,-26.88794 9.98751,-26.89516 0.70308,-0.0181 38.75946,99.10847 38.2464,99.62154 -0.22727,0.22726 -12.68121,-9.38623 -27.67542,-21.36332 z" id="path10681" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,_c1
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="M 97.358853,361.31508 C 88.599956,346.56077 78.277366,326.21685 72.471346,312.2664 l -3.984726,-9.57432 16.768483,-6.6975 c 9.222666,-3.68363 16.888467,-6.57752 17.035117,-6.43087 0.41871,0.41872 3.46081,83.90987 3.07154,84.29914 -0.19117,0.19117 -3.79248,-5.45533 -8.002907,-12.54777 z" id="path10720" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,_c1
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 177.44511,419.21605 c -55.92966,-27.25064 -61.18101,-30.02076 -61.78122,-32.59009 -0.36078,-1.54441 -1.16822,-19.64745 -1.79432,-40.22899 -0.62609,-20.58155 -1.41252,-41.19018 -1.74762,-45.79697 l -0.60928,-8.37598 33.29083,26.69287 33.29083,26.69287 30.58846,51.34374 c 16.82365,28.23905 30.43076,51.50144 30.23801,51.69418 -0.19275,0.19274 -27.85681,-13.05149 -61.47569,-29.43163 z" id="path10759" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,_c2
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 204.76539,489.13121 c -16.23153,-14.6603 -36.85717,-35.37407 -49.9796,-50.19316 -12.09028,-13.65347 -28.11341,-33.45703 -27.53678,-34.03367 0.22139,-0.22139 26.82162,12.42425 59.11162,28.10141 l 58.70909,28.50392 -13.06579,19.5612 c -7.18619,10.75866 -13.40147,19.5505 -13.81173,19.53743 -0.41026,-0.0131 -6.45233,-5.17778 -13.42681,-11.47713 z" id="path10798" />'
                       ));
                           
    }
    function getPearCut2(string memory _c1, string memory _c2, string memory _c3) external pure returns (string memory) {
                        return  string(abi.encodePacked( '<path style="opacity:1;fill:'
                        ,_c2
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 364.10502,168.8755 c -4.90884,-17.79639 -8.61999,-32.66226 -8.24699,-33.03525 0.63527,-0.63528 48.87472,10.1483 49.87579,11.14936 0.37103,0.37103 -26.95338,45.91241 -31.49285,52.48889 -1.00783,1.46008 -2.70674,-3.66935 -10.13595,-30.603 z" id="path10874" />'
                        //path
                        ,'<path style="opacity:1;fill:'
                        ,_c2
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 332.6569,327.08042 c 1.06312,-2.71534 37.08741,-96.59178 37.93609,-98.85844 0.4778,-1.27612 3.80747,6.86229 10.52657,25.72918 7.86857,22.09453 9.57074,27.83238 8.53865,28.78296 -7.06255,6.50482 -57.5701,45.79906 -57.00131,44.3463 z" id="path10913" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,_c2
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 225.22929,406.65553 c -14.57143,-24.3906 -26.49351,-44.62976 -26.49351,-44.97592 0,-0.34615 11.03666,7.72479 24.52591,17.93544 13.48926,10.21064 25.47522,19.15093 26.63547,19.86731 1.93498,1.19471 4.29939,-0.34235 28.57143,-18.57382 14.55403,-10.93197 26.46188,-19.69766 26.46188,-19.47929 0,0.21836 -11.97173,20.46158 -26.60383,44.98492 l -26.60383,44.58789 z" id="path10952" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,_c2
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 294.57522,397.21871 30.96389,-51.83312 32.4264,-26.04311 32.4264,-26.04312 0.3184,5.30987 c 0.17512,2.92042 -0.40613,24.40568 -1.29167,47.74501 -1.17106,30.86447 -1.9473,42.64554 -2.84685,43.20675 -2.13965,1.33489 -121.77682,59.49084 -122.38327,59.49084 -0.31745,0 13.35657,-23.3249 30.3867,-51.83312 z" id="path10991" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        , _c2
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 239.73702,518.28591 c -6.0966,-4.69852 -11.71161,-9.16966 -12.4778,-9.93585 -1.18317,-1.18317 0.54614,-4.30296 11.47745,-20.70599 l 12.87052,-19.31293 13.1125,19.3988 13.1125,19.39881 -2.88576,2.34753 c -6.90068,5.61363 -21.55419,16.48245 -22.78226,16.89808 -0.73833,0.24988 -6.33055,-3.38992 -12.42715,-8.08845 z" id="path11030" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,_c2
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 273.07206,483.80061 c -6.11884,-9.2329 -11.91923,-18.0234 -12.88977,-19.53443 l -1.76461,-2.74735 58.74282,-28.56418 c 32.30855,-15.7103 58.92126,-28.38574 59.13934,-28.16766 0.62647,0.62647 -17.9633,23.29839 -30.48988,37.1852 -17.98204,19.93466 -58.20445,58.71145 -60.82377,58.63771 -0.43394,-0.0122 -5.79529,-7.5764 -11.91413,-16.80929 z" id="path11069" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,_c2
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 395.18515,265.81786 c -1.67203,-4.63218 -6.55675,-18.28516 -10.85492,-30.33995 l -7.81486,-21.91779 18.51906,-30.29282 18.51907,-30.29282 2.63318,3.66446 c 1.44825,2.01546 10.5172,15.39789 20.15322,29.73873 17.47983,26.01442 17.51568,26.07933 15.62167,28.28336 -1.0441,1.21501 -13.23856,14.74076 -27.0988,30.05722 -13.86024,15.31647 -25.52379,28.2247 -25.919,28.68495 -0.39521,0.46025 -2.08659,-2.95315 -3.75862,-7.58534 z" id="path11108" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,_c2
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 302.75869,114.40066 -37.06431,-8.74679 32.33095,-12.469694 c 17.78203,-6.858332 32.56899,-12.231661 32.85992,-11.940731 1.39088,1.390881 11.20695,42.134055 10.12473,42.024335 -0.65283,-0.0662 -17.86591,-4.05639 -38.25129,-8.86712 z" id="path11147" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,_c2
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 215.23393,88.1359 c -19.5733,-7.612914 -35.79985,-14.059761 -36.05899,-14.326327 -0.51439,-0.529108 71.25956,-46.502367 72.59999,-46.502367 1.18812,0 72.37539,45.65541 72.35279,46.402913 -0.0179,0.592705 -69.75402,27.746711 -72.16662,28.100401 -0.62664,0.0919 -17.15387,-6.061708 -36.72717,-13.67462 z" id="path11186" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,_c3
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 420.37703,287.94269 c -8.53979,-3.45065 -15.4985,-6.63172 -15.46379,-7.06904 0.0901,-1.13527 47.81148,-53.51766 48.30554,-53.02361 0.5514,0.55141 -4.19472,28.37384 -6.19928,36.34101 -3.31245,13.16542 -8.95926,30.11819 -10.01695,30.07275 -0.60425,-0.026 -8.08573,-2.87046 -16.62552,-6.32111 z" id="path11225" />'
));
    
}
    function getPearCut3(string memory _c1, string memory _c2, string memory _c3) external pure returns (string memory) {
                            return  string(abi.encodePacked('<path style="opacity:1;fill:'
                        ,_c3
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 398.01238,368.08676 c 0.0562,-10.41584 2.78163,-77.94221 3.16067,-78.30847 0.66088,-0.6386 33.2138,12.83991 33.2138,13.75214 0,0.50616 -2.99128,7.70886 -6.6473,16.00601 -6.1859,14.0386 -19.14578,38.46509 -26.56408,50.06738 l -3.19823,5.00206 z" id="path11301" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,_c3
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 438.24097,172.88417 c -19.10412,-28.39649 -18.4989,-25.38452 -5.37119,-26.73051 3.33755,-0.3422 7.51361,-0.86999 9.28014,-1.17286 l 3.21188,-0.55068 2.51648,7.9661 c 3.57155,11.30594 5.65601,22.14637 6.64683,34.56742 0.47211,5.91842 0.79911,10.81679 0.72668,10.88527 -0.0724,0.0685 -7.7273,-11.16565 -17.01082,-24.96474 z" id="path11340" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,_c3
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 418.2048,119.85475 c 0,-17.27888 0.19679,-19.81268 1.4575,-18.76639 3.8038,3.15687 21.8042,32.1678 21.8042,35.14144 0,0.57105 -3.07206,1.3406 -6.8268,1.71012 -3.75474,0.36951 -8.98863,0.94611 -11.63085,1.28134 l -4.80405,0.6095 z" id="path11418" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,_c3
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 379.26675,132.23244 c -14.46271,-3.38617 -26.52339,-6.49042 -26.80152,-6.89834 -0.97245,-1.42623 -11.36714,-44.518998 -10.86085,-45.025289 0.28105,-0.281053 15.3068,1.787333 33.39055,4.596413 18.08376,2.80908 33.15584,5.107418 33.49351,5.107418 0.33768,0 0.61396,10.922878 0.61396,24.273068 0,22.47528 -0.13109,24.26679 -1.76991,24.18824 -0.97345,-0.0467 -13.60303,-2.85534 -28.06574,-6.24151 z" id="path11457" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,_c3
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 368.64728,75.892559 c -13.07206,-2.082897 -24.50147,-3.967834 -25.39868,-4.188748 -1.32432,-0.326076 -0.55945,-2.340212 4.06449,-10.702991 3.13269,-5.665732 6.01069,-10.616214 6.39555,-11.001074 1.66113,-1.66113 29.05844,15.595489 41.3755,26.060997 l 4.41017,3.747215 -3.53982,-0.06415 c -1.94691,-0.03529 -14.23515,-1.768346 -27.30721,-3.851244 z" id="path11496" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,_c3
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 300.88496,47.948189 c -16.96587,-10.8637 -31.52971,-20.205388 -32.3641,-20.759309 -4.54868,-3.01971 33.4478,3.17698 49.55752,8.082134 11.01183,3.352925 26.06823,9.03189 26.65693,10.054447 0.49222,0.854965 -11.02347,21.788841 -12.17322,22.129186 -0.45656,0.135147 -14.71127,-8.642759 -31.67713,-19.506458 z" id="path11535" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,_c3
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 161.66633,121.71805 c 0.30317,-1.02837 2.66765,-10.28948 5.2544,-20.58025 2.58674,-10.290771 5.0503,-19.078814 5.47457,-19.528984 0.5951,-0.631432 63.07112,22.547024 64.42598,23.901884 0.16995,0.16995 -15.95302,4.06532 -35.82883,8.65637 -19.87581,4.59105 -36.97923,8.58887 -38.00759,8.88405 -1.44842,0.41575 -1.74554,0.11535 -1.31853,-1.33307 z" id="path11574" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,_c2
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 169.18419,65.486726 c -2.88864,-4.485 -11.12117,-20.093281 -10.76317,-20.406172 1.13263,-0.989891 19.90662,-7.854041 27.67253,-10.117632 10.56261,-3.078766 32.04052,-7.158871 42.98357,-8.165479 l 7.58533,-0.697746 -32.60987,20.831315 c -17.93543,11.457223 -32.78827,20.831314 -33.00631,20.831314 -0.21804,0 -1.05598,-1.02402 -1.86208,-2.2756 z" id="path11728" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,_c2
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 109.06372,75.549292 c 8.18791,-7.108905 21.92627,-16.534753 31.33024,-21.495576 4.90316,-2.586533 9.06124,-4.542523 9.24018,-4.346646 1.28959,1.411608 11.82663,21.280534 11.47313,21.634035 -0.59065,0.590652 -51.98779,8.572617 -54.77499,8.506544 -1.79411,-0.04253 -1.33107,-0.771206 2.73144,-4.298357 z" id="path11767" />'    
    
                            ));
        
    }
} */

pragma solidity ^0.8.0;

contract OXXRDisplay  {

    Formater public F; 

     constructor(address _formaterAddress)
    {
        F = Formater(_formaterAddress);
        //_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    struct SlotInfo {
            uint256 color;
            uint256 character;
            uint256 caratAmount;
            string lightColor;
            string middleColor;
            string darkColor;
            string characterColor;
            uint256 diamondId; 
            uint256 cut;
        }

    function stringCutById(uint256 _cut) external pure returns(string memory){
        SlotInfo memory slot;
        slot.cut = _cut;

        if(slot.cut==0){
            return "Raw"; // old Round
        } else if(slot.cut==1){
            return "Princess";
        } else if(slot.cut==2){
            return "Oval";
        } else if(slot.cut==3){
            return "Cushion";
        } else if(slot.cut==4){
            return "Pear";
        } else if(slot.cut==5){
            return "Radiant";
        } else if(slot.cut==6){
            return "Emerald";
        } else if(slot.cut==7){
            return "Round"; // old Asscher
        } else if(slot.cut==8){
            return "Marquise";
        } else if(slot.cut==9){
            return "Heart";
        } else {
            return "Error";
        }
    }

    function stringClarityById(uint8 _clarity) public pure returns(string memory){
        if(_clarity==0){
            return "Internally Flawless (IF)";
        } else if(_clarity==1){
            return "Very Very Small Inclusions 1 (VVS1)";
        } else if(_clarity==2){
            return "Very Very Small Inclusions 2 (VVS2)";
        } else if(_clarity==3){
            return "Very Small Inclusions 1 (VS1)";
        } else if(_clarity==4){
            return "Very Small Inclusions 2 (VS2)";
        } else if(_clarity==5){
            return "Small Inclusions 1 (SI1)";
        } else if(_clarity==6){
            return "Small Inclusions 2 (SI2)";
        } else if(_clarity==7){
            return "Inclusions 1 (I1)";
        } else if(_clarity==8){
            return "Inclusions 2 (I2)";
        } else if(_clarity==9){
            return "Inclusions 3 (I3)";
        } else {
            return "Error";
        }
    }

    function stringCharacterById(uint256 _character) public pure returns(string memory){
        SlotInfo memory slot;
        slot.character = _character;

        if(slot.character==0){
            return "";
        } else if(slot.character==1){
            return ".";
        } else if(slot.character==2){
            return "-";
        } else if(slot.character==3){
            return "v";
        } else if(slot.character==4){
            return ",";
        } else if(slot.character==5){
            return "/";
        } else if(slot.character==6){
            return "*";
        } else if(slot.character==7){
            return "=";
        } else if(slot.character==8){
            return "@";
        } else if(slot.character==9){
            return "~";
        } else {
            return "E";
        }
    }

    function stringColorById(uint256 _color) public pure returns(string memory){

        SlotInfo memory slot;
        slot.color = _color;
        if(slot.color==0){
            return "Yellow";
        } else if(slot.color==1){
            return "Pink";
        } else if(slot.color==2){
            return "Blue";
        } else if(slot.color==3){
            return "Green";
        } else if(slot.color==4){
            return "Orange";
        } else if(slot.color==5){
            return "Red";
        } else if(slot.color==6){
            return "Purple";
        } else if(slot.color==7){
            return "Black";
        } else if(slot.color==8){
            return "Gray";
        } else if(slot.color==9){
            return "Transparent"; // old: White
        } else {
            return "Error";
        }
    }

    function svgMaker(uint256 _diamondId ) public view returns(string memory){
        SlotInfo memory slot;
        slot.color = F.getColor(_diamondId);
        slot.lightColor = "#d1f9f7";
        slot.middleColor = "#c3f6f9";
        slot.darkColor = "#9ee7e7";
        //slot.characterColor ="purple";
        slot.caratAmount = F.getCarat(_diamondId);
        slot.character = F.getCharacter(_diamondId);
        slot.diamondId = _diamondId;

        if(slot.color==0){
            //Yellow
            slot.lightColor  = "#f5fad2";
            slot.middleColor = "#eaf1b4";
            slot.darkColor   = "#c9d47e";

        } else if(slot.color==1){
            // Pink;
            slot.lightColor  = "#f9dff0";
            slot.middleColor = "#f0bddf";
            slot.darkColor   = "#d47eb8";
        } else if(slot.color==2){
            // Blue
            slot.lightColor  = "#d1f9f7";
            slot.middleColor = "#c3f6f9";
            slot.darkColor   = "#9ee7e7";
        } else if(slot.color==3){
            // return "Green";
            slot.lightColor  = "#f5fad2";
            slot.middleColor = "#eaf1b4";
            slot.darkColor   = "#c9d47e";
        } else if(slot.color==4){
            // return "Orange";
            slot.lightColor  = "#f9eed1";
            slot.middleColor = "#f9ecc3";
            slot.darkColor   = "#e7c79e";
        } else if(slot.color==5){
            // Red;
            slot.lightColor  = "#ffc7c7";
            slot.middleColor = "#fe8787";
            slot.darkColor   = "#cc6262";
            //slot.characterColor = "#ffffff";
        } else if(slot.color==6){
            // return "Purple";
            slot.lightColor  = "#f3ddff";
            slot.middleColor = "#d8b1ec";
            slot.darkColor   = "#a76cc5";
        } else if(slot.color==7){
            // return "Violet";
            slot.lightColor  = "#f3ddff";
            slot.middleColor = "#d8b1ec";
            slot.darkColor   = "#a76cc5";
        } else if(slot.color==8){
            // return Black
            slot.lightColor  = "#5a5a5a";
            slot.middleColor = "#434343";
            slot.darkColor   = "#222222";
            //slot.characterColor = "#ffffff";
        } else if(slot.color==9){
            // return "Transparent";
            slot.lightColor  = "#5a5a5a";
            slot.middleColor = "#434343";
            slot.darkColor   = "#222222";
        } else {
            slot.lightColor  = "#d1f9f7";
            slot.middleColor = "#c3f6f9";
            slot.darkColor   = "#c3f6f9";
        }
    
       /* if(false){
            return string(abi.encodePacked(
                "data:image/svg+xml;base64,",
                    Base64.encode(bytes(abi.encodePacked(
                        ' <svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 512 650" style="enable-background:new 0 0 512 650;" xml:space="preserve" >'
                        , SVG.getPearCut1(slot.lightColor, slot.middleColor, slot.darkColor)
                        , SVG.getPearCut2(slot.lightColor, slot.middleColor, slot.darkColor)
                        //, SVG.getPearCut3(slot.lightColor, slot.middleColor, slot.darkColor)
                        /* path 1
                        , '<path style="opacity:1;fill:'
                        , slot.darkColor 
                        , 'stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 218.96334,365.38516 -32.86979,-24.65473 -24.61936,-63.91769 -24.61937,-63.91767 10.82105,-39.44374 c 5.95158,-21.69406 11.34129,-39.93197 11.97714,-40.52869 1.21752,-1.14258 88.64554,-21.68555 92.25172,-21.67638 2.76057,0.007 91.2718,20.72082 92.10606,21.55509 0.35442,0.35442 5.58113,18.47926 11.61493,40.27743 l 10.97054,39.63304 -24.48051,63.80978 -24.4805,63.80979 -32.90107,24.85426 -32.90106,24.85426 z" id="path10371" />'
                        /* path 2
                        ,'<path style="opacity:1;fill:'
                        , slot.lightColor
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="M 77.529405,243.71393 C 62.350737,226.99333 50.075168,212.75238 50.250364,212.06739 50.425559,211.3824 59.37577,197.73794 70.139723,181.74637 l 19.570822,-29.07559 18.560135,30.36691 18.56013,30.36691 -9.9925,28.06382 c -5.49587,15.43509 -10.37923,29.09495 -10.85191,30.35521 -0.7791,2.07723 -3.43875,-0.54996 -28.456995,-28.1097 z" id="path10447" />'
                        // path 3
                        ,'<path style="opacity:1;fill:'
                        , slot.lightColor
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="M 113.63842,174.30955 C 100.46254,152.86788 97.286152,147.02879 98.539351,146.5532 c 3.910509,-1.48406 48.675459,-11.30637 49.188829,-10.79299 0.31589,0.31589 -3.47069,15.22839 -8.41464,33.13887 l -8.98898,32.56453 z" id="path10486" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,slot.lightColor
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 94.563843,114.28571 c 0,-13.35019 0.240496,-24.273068 0.534435,-24.273068 0.293939,0 15.376902,-2.287457 33.517692,-5.083238 18.14079,-2.79578 33.16518,-4.901305 33.38755,-4.678943 0.60105,0.601052 -10.48331,44.243559 -11.47163,45.167279 -0.78211,0.73099 -52.684314,13.14105 -54.959405,13.14105 -0.642586,0 -1.008642,-8.80917 -1.008642,-24.27308 z" id="path10525" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,slot.lightColor
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 48.569744,188.14299 c 1.036323,-13.55315 6.356881,-37.59286 9.329738,-42.15428 0.57375,-0.88033 3.422687,-0.8666 11.604421,0.0559 5.964188,0.6725 11.131192,1.50995 11.482229,1.86098 0.539173,0.53918 -29.317574,45.82446 -32.178876,48.80738 -0.620043,0.6464 -0.705755,-2.44631 -0.237512,-8.57003 z" id="path10564" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,slot.lightColor
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 70.58033,138.1644 -9.318534,-1.12268 4.831665,-9.13315 c 4.942546,-9.34274 10.626725,-18.15261 16.220427,-25.13993 l 3.147553,-3.931734 v 20.366624 20.36663 l -2.781289,-0.14153 c -1.52971,-0.0779 -6.97463,-0.64675 -12.099822,-1.26423 z" id="path10603" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,slot.lightColor
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 62.165361,284.45006 c -5.524669,-17.22097 -13.433291,-54.88462 -11.855906,-56.462 0.525903,-0.5259 48.2999,51.98876 48.2999,53.09275 0,0.69083 -30.876988,13.23481 -32.569455,13.23156 -0.391076,-7.6e-4 -2.134619,-4.43879 -3.874539,-9.86231 z" id="path10642" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,slot.lightColor
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 142.5593,305.83138 c -14.99422,-11.97709 -27.8865,-22.38504 -28.64952,-23.12877 -1.17167,-1.14207 0.0859,-5.53059 8.09103,-28.23429 5.21308,-14.78512 9.70746,-26.88794 9.98751,-26.89516 0.70308,-0.0181 38.75946,99.10847 38.2464,99.62154 -0.22727,0.22726 -12.68121,-9.38623 -27.67542,-21.36332 z" id="path10681" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,slot.lightColor
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="M 97.358853,361.31508 C 88.599956,346.56077 78.277366,326.21685 72.471346,312.2664 l -3.984726,-9.57432 16.768483,-6.6975 c 9.222666,-3.68363 16.888467,-6.57752 17.035117,-6.43087 0.41871,0.41872 3.46081,83.90987 3.07154,84.29914 -0.19117,0.19117 -3.79248,-5.45533 -8.002907,-12.54777 z" id="path10720" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,slot.lightColor
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 177.44511,419.21605 c -55.92966,-27.25064 -61.18101,-30.02076 -61.78122,-32.59009 -0.36078,-1.54441 -1.16822,-19.64745 -1.79432,-40.22899 -0.62609,-20.58155 -1.41252,-41.19018 -1.74762,-45.79697 l -0.60928,-8.37598 33.29083,26.69287 33.29083,26.69287 30.58846,51.34374 c 16.82365,28.23905 30.43076,51.50144 30.23801,51.69418 -0.19275,0.19274 -27.85681,-13.05149 -61.47569,-29.43163 z" id="path10759" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,slot.middleColor
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 204.76539,489.13121 c -16.23153,-14.6603 -36.85717,-35.37407 -49.9796,-50.19316 -12.09028,-13.65347 -28.11341,-33.45703 -27.53678,-34.03367 0.22139,-0.22139 26.82162,12.42425 59.11162,28.10141 l 58.70909,28.50392 -13.06579,19.5612 c -7.18619,10.75866 -13.40147,19.5505 -13.81173,19.53743 -0.41026,-0.0131 -6.45233,-5.17778 -13.42681,-11.47713 z" id="path10798" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,slot.middleColor
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 364.10502,168.8755 c -4.90884,-17.79639 -8.61999,-32.66226 -8.24699,-33.03525 0.63527,-0.63528 48.87472,10.1483 49.87579,11.14936 0.37103,0.37103 -26.95338,45.91241 -31.49285,52.48889 -1.00783,1.46008 -2.70674,-3.66935 -10.13595,-30.603 z" id="path10874" />'
                        /* path
                        ,'<path style="opacity:1;fill:'
                        ,slot.middleColor
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 332.6569,327.08042 c 1.06312,-2.71534 37.08741,-96.59178 37.93609,-98.85844 0.4778,-1.27612 3.80747,6.86229 10.52657,25.72918 7.86857,22.09453 9.57074,27.83238 8.53865,28.78296 -7.06255,6.50482 -57.5701,45.79906 -57.00131,44.3463 z" id="path10913" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,slot.middleColor
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 225.22929,406.65553 c -14.57143,-24.3906 -26.49351,-44.62976 -26.49351,-44.97592 0,-0.34615 11.03666,7.72479 24.52591,17.93544 13.48926,10.21064 25.47522,19.15093 26.63547,19.86731 1.93498,1.19471 4.29939,-0.34235 28.57143,-18.57382 14.55403,-10.93197 26.46188,-19.69766 26.46188,-19.47929 0,0.21836 -11.97173,20.46158 -26.60383,44.98492 l -26.60383,44.58789 z" id="path10952" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,slot.middleColor
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 294.57522,397.21871 30.96389,-51.83312 32.4264,-26.04311 32.4264,-26.04312 0.3184,5.30987 c 0.17512,2.92042 -0.40613,24.40568 -1.29167,47.74501 -1.17106,30.86447 -1.9473,42.64554 -2.84685,43.20675 -2.13965,1.33489 -121.77682,59.49084 -122.38327,59.49084 -0.31745,0 13.35657,-23.3249 30.3867,-51.83312 z" id="path10991" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        , slot.middleColor
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 239.73702,518.28591 c -6.0966,-4.69852 -11.71161,-9.16966 -12.4778,-9.93585 -1.18317,-1.18317 0.54614,-4.30296 11.47745,-20.70599 l 12.87052,-19.31293 13.1125,19.3988 13.1125,19.39881 -2.88576,2.34753 c -6.90068,5.61363 -21.55419,16.48245 -22.78226,16.89808 -0.73833,0.24988 -6.33055,-3.38992 -12.42715,-8.08845 z" id="path11030" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,slot.middleColor
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 273.07206,483.80061 c -6.11884,-9.2329 -11.91923,-18.0234 -12.88977,-19.53443 l -1.76461,-2.74735 58.74282,-28.56418 c 32.30855,-15.7103 58.92126,-28.38574 59.13934,-28.16766 0.62647,0.62647 -17.9633,23.29839 -30.48988,37.1852 -17.98204,19.93466 -58.20445,58.71145 -60.82377,58.63771 -0.43394,-0.0122 -5.79529,-7.5764 -11.91413,-16.80929 z" id="path11069" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,slot.middleColor
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 395.18515,265.81786 c -1.67203,-4.63218 -6.55675,-18.28516 -10.85492,-30.33995 l -7.81486,-21.91779 18.51906,-30.29282 18.51907,-30.29282 2.63318,3.66446 c 1.44825,2.01546 10.5172,15.39789 20.15322,29.73873 17.47983,26.01442 17.51568,26.07933 15.62167,28.28336 -1.0441,1.21501 -13.23856,14.74076 -27.0988,30.05722 -13.86024,15.31647 -25.52379,28.2247 -25.919,28.68495 -0.39521,0.46025 -2.08659,-2.95315 -3.75862,-7.58534 z" id="path11108" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,slot.middleColor
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 302.75869,114.40066 -37.06431,-8.74679 32.33095,-12.469694 c 17.78203,-6.858332 32.56899,-12.231661 32.85992,-11.940731 1.39088,1.390881 11.20695,42.134055 10.12473,42.024335 -0.65283,-0.0662 -17.86591,-4.05639 -38.25129,-8.86712 z" id="path11147" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,slot.middleColor
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 215.23393,88.1359 c -19.5733,-7.612914 -35.79985,-14.059761 -36.05899,-14.326327 -0.51439,-0.529108 71.25956,-46.502367 72.59999,-46.502367 1.18812,0 72.37539,45.65541 72.35279,46.402913 -0.0179,0.592705 -69.75402,27.746711 -72.16662,28.100401 -0.62664,0.0919 -17.15387,-6.061708 -36.72717,-13.67462 z" id="path11186" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,slot.darkColor
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 420.37703,287.94269 c -8.53979,-3.45065 -15.4985,-6.63172 -15.46379,-7.06904 0.0901,-1.13527 47.81148,-53.51766 48.30554,-53.02361 0.5514,0.55141 -4.19472,28.37384 -6.19928,36.34101 -3.31245,13.16542 -8.95926,30.11819 -10.01695,30.07275 -0.60425,-0.026 -8.08573,-2.87046 -16.62552,-6.32111 z" id="path11225" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,slot.darkColor
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 398.01238,368.08676 c 0.0562,-10.41584 2.78163,-77.94221 3.16067,-78.30847 0.66088,-0.6386 33.2138,12.83991 33.2138,13.75214 0,0.50616 -2.99128,7.70886 -6.6473,16.00601 -6.1859,14.0386 -19.14578,38.46509 -26.56408,50.06738 l -3.19823,5.00206 z" id="path11301" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,slot.darkColor
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 438.24097,172.88417 c -19.10412,-28.39649 -18.4989,-25.38452 -5.37119,-26.73051 3.33755,-0.3422 7.51361,-0.86999 9.28014,-1.17286 l 3.21188,-0.55068 2.51648,7.9661 c 3.57155,11.30594 5.65601,22.14637 6.64683,34.56742 0.47211,5.91842 0.79911,10.81679 0.72668,10.88527 -0.0724,0.0685 -7.7273,-11.16565 -17.01082,-24.96474 z" id="path11340" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,slot.darkColor
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 418.2048,119.85475 c 0,-17.27888 0.19679,-19.81268 1.4575,-18.76639 3.8038,3.15687 21.8042,32.1678 21.8042,35.14144 0,0.57105 -3.07206,1.3406 -6.8268,1.71012 -3.75474,0.36951 -8.98863,0.94611 -11.63085,1.28134 l -4.80405,0.6095 z" id="path11418" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,slot.darkColor
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 379.26675,132.23244 c -14.46271,-3.38617 -26.52339,-6.49042 -26.80152,-6.89834 -0.97245,-1.42623 -11.36714,-44.518998 -10.86085,-45.025289 0.28105,-0.281053 15.3068,1.787333 33.39055,4.596413 18.08376,2.80908 33.15584,5.107418 33.49351,5.107418 0.33768,0 0.61396,10.922878 0.61396,24.273068 0,22.47528 -0.13109,24.26679 -1.76991,24.18824 -0.97345,-0.0467 -13.60303,-2.85534 -28.06574,-6.24151 z" id="path11457" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,slot.darkColor
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 368.64728,75.892559 c -13.07206,-2.082897 -24.50147,-3.967834 -25.39868,-4.188748 -1.32432,-0.326076 -0.55945,-2.340212 4.06449,-10.702991 3.13269,-5.665732 6.01069,-10.616214 6.39555,-11.001074 1.66113,-1.66113 29.05844,15.595489 41.3755,26.060997 l 4.41017,3.747215 -3.53982,-0.06415 c -1.94691,-0.03529 -14.23515,-1.768346 -27.30721,-3.851244 z" id="path11496" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,slot.darkColor
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 300.88496,47.948189 c -16.96587,-10.8637 -31.52971,-20.205388 -32.3641,-20.759309 -4.54868,-3.01971 33.4478,3.17698 49.55752,8.082134 11.01183,3.352925 26.06823,9.03189 26.65693,10.054447 0.49222,0.854965 -11.02347,21.788841 -12.17322,22.129186 -0.45656,0.135147 -14.71127,-8.642759 -31.67713,-19.506458 z" id="path11535" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,slot.darkColor
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 161.66633,121.71805 c 0.30317,-1.02837 2.66765,-10.28948 5.2544,-20.58025 2.58674,-10.290771 5.0503,-19.078814 5.47457,-19.528984 0.5951,-0.631432 63.07112,22.547024 64.42598,23.901884 0.16995,0.16995 -15.95302,4.06532 -35.82883,8.65637 -19.87581,4.59105 -36.97923,8.58887 -38.00759,8.88405 -1.44842,0.41575 -1.74554,0.11535 -1.31853,-1.33307 z" id="path11574" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,slot.middleColor
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 169.18419,65.486726 c -2.88864,-4.485 -11.12117,-20.093281 -10.76317,-20.406172 1.13263,-0.989891 19.90662,-7.854041 27.67253,-10.117632 10.56261,-3.078766 32.04052,-7.158871 42.98357,-8.165479 l 7.58533,-0.697746 -32.60987,20.831315 c -17.93543,11.457223 -32.78827,20.831314 -33.00631,20.831314 -0.21804,0 -1.05598,-1.02402 -1.86208,-2.2756 z" id="path11728" />'
                        // path
                        ,'<path style="opacity:1;fill:'
                        ,slot.middleColor
                        ,';stroke-width:0;stroke-miterlimit:4;stroke-dasharray:none" d="m 109.06372,75.549292 c 8.18791,-7.108905 21.92627,-16.534753 31.33024,-21.495576 4.90316,-2.586533 9.06124,-4.542523 9.24018,-4.346646 1.28959,1.411608 11.82663,21.280534 11.47313,21.634035 -0.59065,0.590652 -51.98779,8.572617 -54.77499,8.506544 -1.79411,-0.04253 -1.33107,-0.771206 2.73144,-4.298357 z" id="path11767" />'
                        
                        , SVG.getBottom(stringCharacterById(slot.character), slot.caratAmount, slot.diamondId)
                            /*,'<text x="50%" y="320" dominant-baseline="middle" text-anchor="middle" fill="'
                            ,"purple", //slot.characterColor
                            '" font-family="Super Sans" font-size="10em" font-weight="bold">'
                            ,stringCharacterById(slot.character)
                            ,'</text>',
                            '<circle fill="',"purple",'" cx="155" cy="150" r="15"/>',
                            '<circle fill="',"purple",'" cx="350" cy="150" r="15"/>',
                            '<text x="50%" y="90%" dominant-baseline="middle" text-anchor="middle" fill="purple" font-size="6em" font-weight="bold">'
                            , F.roundUIntToString(slot.caratAmount * (10 ** 17))
                            ,'</text>',
                            '<text x="50%" y="97%" dominant-baseline="middle" text-anchor="middle" fill="purple" font-size="1em" font-weight="bold">'
                            , Strings.toString(slot.diamondId)
                            ,'</text>'
                    ,' </svg>'
            )))));



        } */
            //return slot.middleColor;
            return string(abi.encodePacked(
                "data:image/svg+xml;base64,"
                , Base64.encode(bytes(abi.encodePacked('<?xml version="1.0" encoding="iso-8859-1"?><svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 512 650" style="enable-background:new 0 0 512 650;" xml:space="preserve"><polygon style="fill:'
                    ,slot.middleColor,
                    ';" points="256,499.47 512,146.167 414.217,12.53 97.784,12.53 0.001,146.167 "/><g>'
                    ,'<polygon style="fill:'
                    ,slot.lightColor,
                    ';" points="97.786,12.53 170.663,146.172 0,146.172"/>'
                    ,'<polygon style="fill:',
                    slot.lightColor ,
                    ';" points="414.217,12.53 341.327,146.172 255.995,12.53"/>'
                    ,'<polygon style="fill:',
                    slot.lightColor,
                    ';" points="341.327,146.172 255.995,499.467 170.663,146.172"/></g>'
                    ,'<g><polygon style="fill:'
                    ,slot.darkColor,
                    ';" points="414.217,12.53 511.99,146.172 341.327,146.172"/>'
                    ,'<polygon style="fill:'
                    ,slot.darkColor,
                    ';" points="255.995,12.53 341.327,146.172 170.663,146.172"/>'
                    ,'<polygon style="fill:'
                    ,slot.darkColor,
                    ';" points="170.663,146.172 255.995,499.467 0,146.172"/>'
                    ,'</g><g></g><g></g><g></g><g></g><g></g><g></g><g></g><g></g><g></g><g></g><g></g><g></g><g></g><g></g><g></g>'
                    /*,'<text x="50%" y="320" dominant-baseline="middle" text-anchor="middle" fill="'
                    ,"purple" //slot.characterColor
                    ,'" font-family="Super Sans" font-size="10em" font-weight="bold">'
                    ,stringCharacterById(slot.character)
                    ,'</text>'
                    ,'<circle fill="',"purple",'" cx="155" cy="150" r="15"/>'
                    ,'<circle fill="',"purple",'" cx="350" cy="150" r="15"/>'
                    '<text x="50%" y="90%" dominant-baseline="middle" text-anchor="middle" fill="purple" font-size="6em" font-weight="bold">'
                    , F.roundUIntToString(slot.caratAmount * (10 ** 17))
                    ,'</text>'
                    ,'<text x="50%" y="97%" dominant-baseline="middle" text-anchor="middle" fill="purple" font-size="1em" font-weight="bold">'
                    , Strings.toString(slot.diamondId)
                    ,'</text>'*/
                    ,'</svg>'
                    )))));
                    /*Base64.encode(bytes(abi.encodePacked(
                        '<?xml version="1.0" encoding="iso-8859-1"?><svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 512 650" style="enable-background:new 0 0 512 650;" xml:space="preserve"><polygon style="fill:'
                            ,slot.middleColor,
                            ';" points="256,499.47 512,146.167 414.217,12.53 97.784,12.53 0.001,146.167 "/><g>'
                            ,'<polygon style="fill:'
                            ,slot.lightColor,
                            ';" points="97.786,12.53 170.663,146.172 0,146.172"/>'
                            ,'<polygon style="fill:',
                            slot.lightColor ,
                            ';" points="414.217,12.53 341.327,146.172 255.995,12.53"/>'
                            ,'<polygon style="fill:',
                            slot.lightColor,
                            ';" points="341.327,146.172 255.995,499.467 170.663,146.172"/></g>'
                            ,'<g><polygon style="fill:'
                            ,slot.darkColor,
                            ';" points="414.217,12.53 511.99,146.172 341.327,146.172"/>'
                            ,'<polygon style="fill:'
                            ,slot.darkColor,
                            ';" points="255.995,12.53 341.327,146.172 170.663,146.172"/>'
                            ,'<polygon style="fill:'
                            ,slot.darkColor,
                            ';" points="170.663,146.172 255.995,499.467 0,146.172"/>'
                            ,'</g><g></g><g></g><g></g><g></g><g></g><g></g><g></g><g></g><g></g><g></g><g></g><g></g><g></g><g></g><g></g>'
                            ,'<text x="50%" y="320" dominant-baseline="middle" text-anchor="middle" fill="'
                            ,"purple", //slot.characterColor
                            '" font-family="Super Sans" font-size="10em" font-weight="bold">'
                            ,stringCharacterById(slot.character)
                            ,'</text>',
                            '<circle fill="',"purple",'" cx="155" cy="150" r="15"/>',
                            '<circle fill="',"purple",'" cx="350" cy="150" r="15"/>',
                            '<text x="50%" y="90%" dominant-baseline="middle" text-anchor="middle" fill="purple" font-size="6em" font-weight="bold">'
                            , F.roundUIntToString(slot.caratAmount * (10 ** 17))
                            ,'</text>',
                            '<text x="50%" y="97%" dominant-baseline="middle" text-anchor="middle" fill="purple" font-size="1em" font-weight="bold">'
                            , Strings.toString(slot.diamondId)
                            ,'</text>'
                        ,'</svg>'
                        )))));
        //} else {
            //return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(abi.encodePacked('<?xml version="1.0" encoding="iso-8859-1"?><svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 512 512" style="enable-background:new 0 0 512 512;" xml:space="preserve"><polygon style="fill:',middleColor,';" points="256,499.47 512,146.167 414.217,12.53 97.784,12.53 0.001,146.167 "/><g><polygon style="fill:',lightColor,';" points="97.786,12.53 170.663,146.172 0,146.172"/><polygon style="fill:',lightColor,';" points="414.217,12.53 341.327,146.172 255.995,12.53"/><polygon style="fill:',lightColor,';" points="341.327,146.172 255.995,499.467 170.663,146.172"/></g><g><polygon style="fill:',darkColor,';" points="414.217,12.53 511.99,146.172 341.327,146.172"/><polygon style="fill:',darkColor,';" points="255.995,12.53 341.327,146.172 170.663,146.172"/><polygon style="fill:',darkColor,';" points="170.663,146.172 255.995,499.467 0,146.172"/></g><g transform="translate(0.000000,1280.000000) scale(0.100000,-0.100000)" fill="#555555" stroke="none"><path d="M550 12465 c-105 -35 -200 -141 -222 -248 -43 -206 163 -412 369 -369 155 32 275 190 260 339 -11 105 -90 213 -190 262 -61 29 -155 36 -217 16z"/><path d="M1830 12465 c-151 -50 -253 -216 -222 -362 25 -119 136 -230 254 -255 194 -41 395 142 375 339 -11 105 -90 213 -190 262 -61 29 -155 36 -217 16z"/><path d="M3110 12465 c-105 -35 -200 -141 -222 -248 -43 -206 163 -412 369 -369 155 32 275 190 260 339 -11 105 -90 213 -190 262 -61 29 -155 36 -217 16z"/><path d="M4390 12465 c-105 -35 -200 -141 -222 -248 -43 -206 163 -412 369 -369 155 32 275 190 260 339 -11 105 -90 213 -190 262 -61 29 -155 36 -217 16z"/><path d="M550 11185 c-105 -35 -200 -141 -222 -248 -43 -206 163 -412 369 -369 155 32 275 190 260 339 -11 105 -90 213 -190 262 -61 29 -155 36 -217 16z"/><path d="M1830 11185 c-151 -50 -253 216 -222 -362 25 -119 136 -230 254 -255 194 -41 395 142 375 339 -11 105 -90 213 -190 262 -61 29 -155 36 -217 16z"/><path d="M3110 11185 c-105 -35 -200 -141 -222 -248 -43 -206 163 -412 369 -369 155 32 275 190 260 339 -11 105 -90 213 -190 262 -61 29 -155 36 -217 16z"/><path d="M4390 11185 c-105 -35 -200 -141 -222 -248 -43 -206 163 -412 369 -369 155 32 275 190 260 339 -11 105 -90 213 -190 262 -61 29 -155 36 -217 16z"/><path d="M550 9905 c-105 -35 -200 -141 -222 -248 -43 -206 163 -412 369 -369 155 32 275 190 260 339 -11 105 -90 213 -190 262 -61 29 -155 36 -217 16z"/><path d="M1830 9905 c-105 -35 -200 -141 -222 -248 -43 -206 163 -412 369 -369 155 32 275 190 260 339 -11 105 -90 213 -190 262 -61 29 -155 36 -217 16z"/><path d="M3110 9905 c-105 -35 -200 -141 -222 -248 -43 -206 163 -412 369 -369 155 32 275 190 260 339 -11 105 -90 213 -190 262 -61 29 -155 36 -217 16z"/><path d="M4390 9905 c-105 -35 -200 -141 -222 -248 -43 -206 163 -412 369 -369 155 32 275 190 260 339 -11 105 -90 213 -190 262 -61 29 -155 36 -217 16z"/><path d="M550 8625 c-105 -35 -200 -141 -222 -248 -43 -206 163 -412 369 -369 155 32 275 190 260 339 -11 105 -90 213 -190 262 -61 29 -155 36 -217 16z"/><path d="M1830 8625 c-105 -35 -200 -141 -222 -248 -43 -206 163 -412 369 -369 155 32 275 190 260 339 -11 105 -90 213 -190 262 -61 29 -155 36 -217 16z"/><path d="M3110 8625 c-105 -35 -200 -141 -222 -248 -43 -206 163 -412 369 -369 155 32 275 190 260 339 -11 105 -90 213 -190 262 -61 29 -155 36 -217 16z"/><path d="M4390 8625 c-105 -35 -200 -141 -222 -248 -43 -206 163 -412 369 -369 155 32 275 190 260 339 -11 105 -90 213 -190 262 -61 29 -155 36 -217 16z"/></g><g></g><g></g><g></g><g></g><g></g><g></g><g></g><g></g><g></g><g></g><g></g><g></g><g></g><g></g><g></g></svg>')))));
        //}
    */}
}

contract OXXRTest is ERC721Tradable{
    mapping(uint256 => uint256) public diamondId; 
    mapping(uint256 => bool) private mintedDiamondList;
    string public baseURI;

     constructor(address _proxyRegistryAddress)
    ERC721Tradable("OXXRTest", "OXXRTest", _proxyRegistryAddress )
    {

    }

    function baseTokenURI() override public pure returns (string memory) {
        return "https://xcircle.s3.eu-west-3.amazonaws.com/nfts/metadata/metadata.json?id=";
    }

}
/**
 * @title Diamond
 * Diamond - a contract for non-fungible Diamonds holding Carats ERC20. // ERC721Tradable 
 */
contract OXXR is ERC721Tradable {
    // ERC20 smartcontract
    ERC20 public ERC20Token;
    OXXRDisplay public OD; 
    Formater public F; 
    // Mapping from ERC20 token mount by NFT token ID
    mapping(uint256 => uint256) public balanceOfERC20ByTokenId;
    // Parameters of NFTs Diamonds
    mapping(uint256 => uint256) public diamondId; 
    mapping(uint256 => bool) private mintedDiamondList;
    // mapping(uint256=> uint8) private color;
    // mapping(uint256=> uint8) private cut;
    // mapping(uint256=> uint8) private character;
    bytes4 public constant IID_ITEST = type(IERC721).interfaceId;   
    //bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");


    constructor(address _proxyRegistryAddress ,
     address _tokenAddress, address _OXXRDisplay, address _formaterAddress)
    ERC721Tradable("OXXR", "OXXR", _proxyRegistryAddress )
    {
        ERC20Token = ERC20(_tokenAddress);
        OD = OXXRDisplay(_OXXRDisplay);
        F = Formater(_formaterAddress);
        //_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    function setDisplayContractAddress(address _address) public onlyOwner {
        OD = OXXRDisplay(_address);
    }

    
    function baseTokenURI() override public pure returns (string memory) {
        return "http://testdia.io/nft/nft1.json?id=";
    }

    function contractURI() public pure returns (string memory) {
        return "http://testdia.io/nft/contract/nft1";
    }


    function tokenURI(uint256 _tokenId) override(ERC721Tradable) public view returns (string memory) {
        /*
        * @DEV To override this function from ERC721Tradable I needed to add virtual in the ERC721Trable and change pure to view
        */

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"attributes":[{',
                                '"trait_type":"Cut", "value":"',OD.stringCutById(F.getCut(_tokenId)) ,'"},'
                                ,'{"trait_type":"Carat", "value":', 
                                Strings.toString(balanceOfERC20ByTokenId[_tokenId]/(10** uint256(ERC20Token.decimals())))
                                ,'},'
                                ,'{"trait_type":"Color", "value":"',OD.stringColorById(F.getColor(_tokenId)),'"},'
                                ,'{"trait_type":"Character", "value":"',OD.stringCharacterById(F.getCharacter(_tokenId)),'"}],'
                            '"description": "Diamond description.",'
                            // Diamond from https://iconmonstr.com/diamond-5-svg/
                            '"image": "'
                            , OD.svgMaker(_tokenId)
                            ,'",',
                            //'"image": "http://testsss.io/nft/nft1.jpg",',
                            '"name": "Diamond ',Strings.toString(diamondId[_tokenId]),'"}'
                        )
                    )
                )
            )
        );
    }

    /* 
    *  Allowing any senders to mint with there ERC20
    *  Sender need to approve before this smartcontract address to do the transaction 
    */
    /* function mintWithERC20(uint256 amount) public {
        require(ERC20Token.transferFrom(msg.sender, address(this), amount), "Insufficient funds");
        mintTo(msg.sender);
        uint256 newTokenId = totalSupply();
        balanceOfERC20ByTokenId[(newTokenId)]=amount;
    }
    */

    function mintPP( uint256 _ppID) public{
        require(_ppID<8, "pp id too big");
       
        mintTo(msg.sender);
        uint256 newTokenId = totalSupply();
    }

    /*function breakDiamond(uint256 _tokenId) public {
        require(ERC20Token.balanceOf(address(this)) >= balanceOfERC20ByTokenId[_tokenId], "Insufficient funds");
        require(msg.sender == this.ownerOf(_tokenId), "Sorry, you are not the nft token owner");
        require(ERC20Token.transfer(msg.sender, balanceOfERC20ByTokenId[_tokenId]), "Sorry, couldn't transfer the token");
        
        _burn(_tokenId);
        balanceOfERC20ByTokenId[_tokenId] = 0;
    }*/


}