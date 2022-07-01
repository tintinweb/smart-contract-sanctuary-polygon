/**
 *Submitted for verification at polygonscan.com on 2022-06-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// File: node_modules\@openzeppelin\contracts\utils\introspection\IERC165.sol
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
// File: node_modules\@openzeppelin\contracts\token\ERC721\IERC721.sol
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
// File: node_modules\@openzeppelin\contracts\token\ERC721\IERC721Receiver.sol
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
// File: node_modules\@openzeppelin\contracts\token\ERC721\extensions\IERC721Metadata.sol
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
// File: node_modules\@openzeppelin\contracts\utils\Address.sol
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
// File: node_modules\@openzeppelin\contracts\utils\Context.sol
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
// File: node_modules\@openzeppelin\contracts\utils\Strings.sol
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
// File: node_modules\@openzeppelin\contracts\utils\introspection\ERC165.sol
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
// File: @openzeppelin\contracts\token\ERC721\ERC721.sol
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
// File: @openzeppelin\contracts\access\Ownable.sol
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
// File: @openzeppelin\contracts\security\ReentrancyGuard.sol
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
// File: node_modules\witnet-solidity-bridge\contracts\interfaces\IWitnetRequest.sol
/// @title The Witnet Data Request basic interface.
/// @author The Witnet Foundation.
interface IWitnetRequest {
    /// A `IWitnetRequest` is constructed around a `bytes` value containing 
    /// a well-formed Witnet Data Request using Protocol Buffers.
    function bytecode() external view returns (bytes memory);

    /// Returns SHA256 hash of Witnet Data Request as CBOR-encoded bytes.
    function hash() external view returns (bytes32);
}
// File: node_modules\witnet-solidity-bridge\contracts\libs\Witnet.sol
library Witnet {

    /// @notice Witnet function that computes the hash of a CBOR-encoded Data Request.
    /// @param _bytecode CBOR-encoded RADON.
    function hash(bytes memory _bytecode) internal pure returns (bytes32) {
        return sha256(_bytecode);
    }

    /// Struct containing both request and response data related to every query posted to the Witnet Request Board
    struct Query {
        Request request;
        Response response;
        address from;      // Address from which the request was posted.
    }

    /// Possible status of a Witnet query.
    enum QueryStatus {
        Unknown,
        Posted,
        Reported,
        Deleted
    }

    /// Data kept in EVM-storage for every Request posted to the Witnet Request Board.
    struct Request {
        IWitnetRequest addr;    // The contract containing the Data Request which execution has been requested.
        address requester;      // Address from which the request was posted.
        bytes32 hash;           // Hash of the Data Request whose execution has been requested.
        uint256 gasprice;       // Minimum gas price the DR resolver should pay on the solving tx.
        uint256 reward;         // Escrowed reward to be paid to the DR resolver.
    }

    /// Data kept in EVM-storage containing Witnet-provided response metadata and result.
    struct Response {
        address reporter;       // Address from which the result was reported.
        uint256 timestamp;      // Timestamp of the Witnet-provided result.
        bytes32 drTxHash;       // Hash of the Witnet transaction that solved the queried Data Request.
        bytes   cborBytes;      // Witnet-provided result CBOR-bytes to the queried Data Request.
    }

    /// Data struct containing the Witnet-provided result to a Data Request.
    struct Result {
        bool success;           // Flag stating whether the request could get solved successfully, or not.
        CBOR value;             // Resulting value, in CBOR-serialized bytes.
    }

    /// Data struct following the RFC-7049 standard: Concise Binary Object Representation.
    struct CBOR {
        Buffer buffer;
        uint8 initialByte;
        uint8 majorType;
        uint8 additionalInformation;
        uint64 len;
        uint64 tag;
    }

    /// Iterable bytes buffer.
    struct Buffer {
        bytes data;
        uint32 cursor;
    }

    /// Witnet error codes table.
    enum ErrorCodes {
        // 0x00: Unknown error. Something went really bad!
        Unknown,
        // Script format errors
        /// 0x01: At least one of the source scripts is not a valid CBOR-encoded value.
        SourceScriptNotCBOR,
        /// 0x02: The CBOR value decoded from a source script is not an Array.
        SourceScriptNotArray,
        /// 0x03: The Array value decoded form a source script is not a valid Data Request.
        SourceScriptNotRADON,
        /// Unallocated
        ScriptFormat0x04,
        ScriptFormat0x05,
        ScriptFormat0x06,
        ScriptFormat0x07,
        ScriptFormat0x08,
        ScriptFormat0x09,
        ScriptFormat0x0A,
        ScriptFormat0x0B,
        ScriptFormat0x0C,
        ScriptFormat0x0D,
        ScriptFormat0x0E,
        ScriptFormat0x0F,
        // Complexity errors
        /// 0x10: The request contains too many sources.
        RequestTooManySources,
        /// 0x11: The script contains too many calls.
        ScriptTooManyCalls,
        /// Unallocated
        Complexity0x12,
        Complexity0x13,
        Complexity0x14,
        Complexity0x15,
        Complexity0x16,
        Complexity0x17,
        Complexity0x18,
        Complexity0x19,
        Complexity0x1A,
        Complexity0x1B,
        Complexity0x1C,
        Complexity0x1D,
        Complexity0x1E,
        Complexity0x1F,
        // Operator errors
        /// 0x20: The operator does not exist.
        UnsupportedOperator,
        /// Unallocated
        Operator0x21,
        Operator0x22,
        Operator0x23,
        Operator0x24,
        Operator0x25,
        Operator0x26,
        Operator0x27,
        Operator0x28,
        Operator0x29,
        Operator0x2A,
        Operator0x2B,
        Operator0x2C,
        Operator0x2D,
        Operator0x2E,
        Operator0x2F,
        // Retrieval-specific errors
        /// 0x30: At least one of the sources could not be retrieved, but returned HTTP error.
        HTTP,
        /// 0x31: Retrieval of at least one of the sources timed out.
        RetrievalTimeout,
        /// Unallocated
        Retrieval0x32,
        Retrieval0x33,
        Retrieval0x34,
        Retrieval0x35,
        Retrieval0x36,
        Retrieval0x37,
        Retrieval0x38,
        Retrieval0x39,
        Retrieval0x3A,
        Retrieval0x3B,
        Retrieval0x3C,
        Retrieval0x3D,
        Retrieval0x3E,
        Retrieval0x3F,
        // Math errors
        /// 0x40: Math operator caused an underflow.
        Underflow,
        /// 0x41: Math operator caused an overflow.
        Overflow,
        /// 0x42: Tried to divide by zero.
        DivisionByZero,
        /// Unallocated
        Math0x43,
        Math0x44,
        Math0x45,
        Math0x46,
        Math0x47,
        Math0x48,
        Math0x49,
        Math0x4A,
        Math0x4B,
        Math0x4C,
        Math0x4D,
        Math0x4E,
        Math0x4F,
        // Other errors
        /// 0x50: Received zero reveals
        NoReveals,
        /// 0x51: Insufficient consensus in tally precondition clause
        InsufficientConsensus,
        /// 0x52: Received zero commits
        InsufficientCommits,
        /// 0x53: Generic error during tally execution
        TallyExecution,
        /// Unallocated
        OtherError0x54,
        OtherError0x55,
        OtherError0x56,
        OtherError0x57,
        OtherError0x58,
        OtherError0x59,
        OtherError0x5A,
        OtherError0x5B,
        OtherError0x5C,
        OtherError0x5D,
        OtherError0x5E,
        OtherError0x5F,
        /// 0x60: Invalid reveal serialization (malformed reveals are converted to this value)
        MalformedReveal,
        /// Unallocated
        OtherError0x61,
        OtherError0x62,
        OtherError0x63,
        OtherError0x64,
        OtherError0x65,
        OtherError0x66,
        OtherError0x67,
        OtherError0x68,
        OtherError0x69,
        OtherError0x6A,
        OtherError0x6B,
        OtherError0x6C,
        OtherError0x6D,
        OtherError0x6E,
        OtherError0x6F,
        // Access errors
        /// 0x70: Tried to access a value from an index using an index that is out of bounds
        ArrayIndexOutOfBounds,
        /// 0x71: Tried to access a value from a map using a key that does not exist
        MapKeyNotFound,
        /// Unallocated
        OtherError0x72,
        OtherError0x73,
        OtherError0x74,
        OtherError0x75,
        OtherError0x76,
        OtherError0x77,
        OtherError0x78,
        OtherError0x79,
        OtherError0x7A,
        OtherError0x7B,
        OtherError0x7C,
        OtherError0x7D,
        OtherError0x7E,
        OtherError0x7F,
        OtherError0x80,
        OtherError0x81,
        OtherError0x82,
        OtherError0x83,
        OtherError0x84,
        OtherError0x85,
        OtherError0x86,
        OtherError0x87,
        OtherError0x88,
        OtherError0x89,
        OtherError0x8A,
        OtherError0x8B,
        OtherError0x8C,
        OtherError0x8D,
        OtherError0x8E,
        OtherError0x8F,
        OtherError0x90,
        OtherError0x91,
        OtherError0x92,
        OtherError0x93,
        OtherError0x94,
        OtherError0x95,
        OtherError0x96,
        OtherError0x97,
        OtherError0x98,
        OtherError0x99,
        OtherError0x9A,
        OtherError0x9B,
        OtherError0x9C,
        OtherError0x9D,
        OtherError0x9E,
        OtherError0x9F,
        OtherError0xA0,
        OtherError0xA1,
        OtherError0xA2,
        OtherError0xA3,
        OtherError0xA4,
        OtherError0xA5,
        OtherError0xA6,
        OtherError0xA7,
        OtherError0xA8,
        OtherError0xA9,
        OtherError0xAA,
        OtherError0xAB,
        OtherError0xAC,
        OtherError0xAD,
        OtherError0xAE,
        OtherError0xAF,
        OtherError0xB0,
        OtherError0xB1,
        OtherError0xB2,
        OtherError0xB3,
        OtherError0xB4,
        OtherError0xB5,
        OtherError0xB6,
        OtherError0xB7,
        OtherError0xB8,
        OtherError0xB9,
        OtherError0xBA,
        OtherError0xBB,
        OtherError0xBC,
        OtherError0xBD,
        OtherError0xBE,
        OtherError0xBF,
        OtherError0xC0,
        OtherError0xC1,
        OtherError0xC2,
        OtherError0xC3,
        OtherError0xC4,
        OtherError0xC5,
        OtherError0xC6,
        OtherError0xC7,
        OtherError0xC8,
        OtherError0xC9,
        OtherError0xCA,
        OtherError0xCB,
        OtherError0xCC,
        OtherError0xCD,
        OtherError0xCE,
        OtherError0xCF,
        OtherError0xD0,
        OtherError0xD1,
        OtherError0xD2,
        OtherError0xD3,
        OtherError0xD4,
        OtherError0xD5,
        OtherError0xD6,
        OtherError0xD7,
        OtherError0xD8,
        OtherError0xD9,
        OtherError0xDA,
        OtherError0xDB,
        OtherError0xDC,
        OtherError0xDD,
        OtherError0xDE,
        OtherError0xDF,
        // Bridge errors: errors that only belong in inter-client communication
        /// 0xE0: Requests that cannot be parsed must always get this error as their result.
        /// However, this is not a valid result in a Tally transaction, because invalid requests
        /// are never included into blocks and therefore never get a Tally in response.
        BridgeMalformedRequest,
        /// 0xE1: Witnesses exceeds 100
        BridgePoorIncentives,
        /// 0xE2: The request is rejected on the grounds that it may cause the submitter to spend or stake an
        /// amount of value that is unjustifiably high when compared with the reward they will be getting
        BridgeOversizedResult,
        /// Unallocated
        OtherError0xE3,
        OtherError0xE4,
        OtherError0xE5,
        OtherError0xE6,
        OtherError0xE7,
        OtherError0xE8,
        OtherError0xE9,
        OtherError0xEA,
        OtherError0xEB,
        OtherError0xEC,
        OtherError0xED,
        OtherError0xEE,
        OtherError0xEF,
        OtherError0xF0,
        OtherError0xF1,
        OtherError0xF2,
        OtherError0xF3,
        OtherError0xF4,
        OtherError0xF5,
        OtherError0xF6,
        OtherError0xF7,
        OtherError0xF8,
        OtherError0xF9,
        OtherError0xFA,
        OtherError0xFB,
        OtherError0xFC,
        OtherError0xFD,
        OtherError0xFE,
        // This should not exist:
        /// 0xFF: Some tally error is not intercepted but should
        UnhandledIntercept
    }
}
// File: witnet-solidity-bridge\contracts\interfaces\IWitnetRandomness.sol
/// @title The Witnet Randomness generator interface.
/// @author Witnet Foundation.
interface IWitnetRandomness {

    /// Thrown every time a new WitnetRandomnessRequest gets succesfully posted to the WitnetRequestBoard.
    /// @param from Address from which the randomize() function was called. 
    /// @param prevBlock Block number in which a randomness request got posted just before this one. 0 if none.
    /// @param witnetQueryId Unique query id assigned to this request by the WRB.
    /// @param witnetRequestHash SHA-256 hash of the WitnetRandomnessRequest actual bytecode just posted to the WRB.
    event Randomized(
        address indexed from,
        uint256 indexed prevBlock,
        uint256 witnetQueryId,
        bytes32 witnetRequestHash
    );

    /// Returns amount of wei required to be paid as a fee when requesting randomization with a 
    /// transaction gas price as the one given.
    function estimateRandomizeFee(uint256 _gasPrice) external view returns (uint256);

    /// Retrieves data of a randomization request that got successfully posted to the WRB within a given block.
    /// @dev Returns zero values if no randomness request was actually posted within a given block.
    /// @param _block Block number whose randomness request is being queried for.
    /// @return _from Address from which the latest randomness request was posted.
    /// @return _id Unique request identifier as provided by the WRB.
    /// @return _prevBlock Block number in which a randomness request got posted just before this one. 0 if none.
    /// @return _nextBlock Block number in which a randomness request got posted just after this one, 0 if none.
    function getRandomizeData(uint256 _block)
        external view returns (address _from, uint256 _id, uint256 _prevBlock, uint256 _nextBlock);

    /// Retrieves the randomness generated upon solving a request that was posted within a given block,
    /// if any, or to the _first_ request posted after that block, otherwise. Should the intended 
    /// request happen to be finalized with errors on the Witnet oracle network side, this function 
    /// will recursively try to return randomness from the next non-faulty randomization request found 
    /// in storage, if any. 
    /// @dev Fails if:
    /// @dev   i.   no `randomize()` was not called in either the given block, or afterwards.
    /// @dev   ii.  a request posted in/after given block does exist, but no result has been provided yet.
    /// @dev   iii. all requests in/after the given block were solved with errors.
    /// @param _block Block number from which the search will start.
    function getRandomnessAfter(uint256 _block) external view returns (bytes32); 

    /// Tells what is the number of the next block in which a randomization request was posted after the given one. 
    /// @param _block Block number from which the search will start.
    /// @return Number of the first block found after the given one, or `0` otherwise.
    function getRandomnessNextBlock(uint256 _block) external view returns (uint256); 

    /// Gets previous block in which a randomness request was posted before the given one.
    /// @param _block Block number from which the search will start.
    /// @return First block found before the given one, or `0` otherwise.
    function getRandomnessPrevBlock(uint256 _block) external view returns (uint256);

    /// Returns `true` only when the randomness request that got posted within given block was already
    /// reported back from the Witnet oracle, either successfully or with an error of any kind.
    function isRandomized(uint256 _block) external view returns (bool);

    /// Returns latest block in which a randomness request got sucessfully posted to the WRB.
    function latestRandomizeBlock() external view returns (uint256);

    /// Generates a pseudo-random number uniformly distributed within the range [0 .. _range), by using 
    /// the given `_nonce` value and the randomness returned by `getRandomnessAfter(_block)`. 
    /// @dev Fails under same conditions as `getRandomnessAfter(uint256)` may do.
    /// @param _range Range within which the uniformly-distributed random number will be generated.
    /// @param _nonce Nonce value enabling multiple random numbers from the same randomness value.
    /// @param _block Block number from which the search will start.
    function random(uint32 _range, uint256 _nonce, uint256 _block) external view returns (uint32);

    /// Generates a pseudo-random number uniformly distributed within the range [0 .. _range), by using 
    /// the given `_nonce` value and the given `_seed` as a source of entropy.
    /// @param _range Range within which the uniformly-distributed random number will be generated.
    /// @param _nonce Nonce value enabling multiple random numbers from the same randomness value.
    /// @param _seed Seed value used as entropy source.
    function random(uint32 _range, uint256 _nonce, bytes32 _seed) external pure returns (uint32);

    /// Requests the Witnet oracle to generate an EVM-agnostic and trustless source of randomness. 
    /// Only one randomness request per block will be actually posted to the WRB. Should there 
    /// already be a posted request within current block, it will try to upgrade Witnet fee of current's 
    /// block randomness request according to current gas price. In both cases, all unused funds shall 
    /// be transfered back to the tx sender.
    /// @return _usedFunds Amount of funds actually used from those provided by the tx sender.
    function randomize() external payable returns (uint256 _usedFunds);

    /// Increases Witnet fee related to a pending-to-be-solved randomness request, as much as it
    /// may be required in proportion to how much bigger the current tx gas price is with respect the 
    /// highest gas price that was paid in either previous fee upgrades, or when the given randomness 
    /// request was posted. All unused funds shall be transferred back to the tx sender.
    /// @return _usedFunds Amount of dunds actually used from those provided by the tx sender.
    function upgradeRandomizeFee(uint256 _block) external payable returns (uint256 _usedFunds);
}
// File: contracts\libs\Wc3Lib.sol
/// @title Wc3Lib Library: data model and helper functions
/// @author Otherplane Labs, 2022.
library Wc3Lib {

    struct Storage {
        address decorator;
        address signator;
        Settings settings;

        uint256 mintGasLimit;
        uint256 hatchingBlock;
        uint256 totalSupply;

        mapping (/* tokenId => WittyCreature */ uint256 => WittyCreature) intrinsics;
    }

    struct Settings {        
        uint256 expirationBlocks;
        uint256 totalEggs;
        uint8[] percentileMarks;
    }

    enum Status {
        Batching,
        Randomizing,
        Hatching,
        Frozen
    }

    struct WittyCreature {
        string  name;
        uint256 birthTimestamp;
        uint256 globalRanking;
        uint256 guildRanking; /// @dev same as tokenId
        uint256 index;
        uint256 mintUsdCost6;
        WittyCreatureRarity rarity;
        uint256 score;
    }

    enum WittyCreatureRarity {
        Legendary,  // 0
        Rare,       // 1
        Common      // 2
    }

    enum WittyCreatureStatus {
        Inexistent,  // 0
        Incubating,  // 1
        Randomizing, // 2
        Hatching,    // 3
        Minted,      // 4
        Frozen       // 5
    }

    // Calculate length of string-equivalent to given bytes32.
    function length(bytes32 _bytes32)
        internal pure
        returns (uint _length)
    {
        for (; _length < 32; _length ++) {
            if (_bytes32[_length] == 0) {
                break;
            }
        }
    }

    /// Generates pseudo-random number uniformly distributed in range [0 .. _range).
    function randomUint8(bytes32 _seed, uint256 _index, uint _range)
        internal pure
        returns (uint8)
    {
        assert(_range > 0 && _range <= 256);
        uint8 _flagBits = uint8(255 - _msbDeBruijn32(uint32(_range)));
        uint256 _number = uint256(keccak256(abi.encode(_seed, _index))) & uint256(2 ** _flagBits - 1);
        return uint8((_number * _range) >> _flagBits); 
    }

    /// Calculate rarity index based on a creature's ranking percentile.
    function rarity(
            Storage storage self,
            uint _percentile100
        )
        internal view
        returns (WittyCreatureRarity)
    {
        uint8 _i; uint8 _cumuled;
        if (_percentile100 > 100) {
            _percentile100 = 100;
        }
        for (; _i < self.settings.percentileMarks.length; _i ++) {
            _cumuled += self.settings.percentileMarks[_i];
            if (_percentile100 <= _cumuled) {
                break;
            }
        }
        return WittyCreatureRarity(_i);
    }

    /// Recovers address from hash and signature.
    function recoverAddr(bytes32 _hash, bytes memory _signature)
        internal pure
        returns (address)
    {
        if (_signature.length != 65) {
            return (address(0));
        }
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }
        if (v != 27 && v != 28) {
            return address(0);
        }
        return ecrecover(_hash, v, r, s);
    }    

    /// Gets tender's current status.
    function status(Storage storage self, IWitnetRandomness _randomizer)
        internal view
        returns (Status)
    {
        uint _hatchingBlock = self.hatchingBlock;
        uint _expirationBlocks = self.settings.expirationBlocks;
        if (_hatchingBlock > 0) {
            if (_randomizer.isRandomized(_hatchingBlock)) {
                if (_expirationBlocks > 0 && block.number > _hatchingBlock + _expirationBlocks) {
                    return Status.Frozen;
                } else {
                    return Status.Hatching;
                }
            } else {
                return Status.Randomizing;
            }
        } else {
            return Status.Batching;
        }
    }

    /// @dev Produces revert message when tender is not in expected status.
    function statusRevertMessage(Status _status)
        internal pure
        returns (string memory)
    {
        if (_status == Status.Frozen) {
            return "Wc3Lib: not in Frozen status";
        } else if (_status == Status.Batching) {
            return "Wc3Lib: not in Batching status";
        } else if (_status == Status.Randomizing) {
            return "Wc3Lib: not in Randomizing status";
        } else if (_status == Status.Hatching) {
            return "Wc3Lib: not in Hatching status";
        } else {
            return "Wc3Lib: bad mood";
        }
    }

    /// Gets tokens's current status.
    function tokenStatus(Storage storage self, IWitnetRandomness _randomizer, uint256 _tokenId)
        internal view
        returns (WittyCreatureStatus)
    {
        WittyCreature memory _wc3 = self.intrinsics[_tokenId];
        if (
            _tokenId == 0
                || _tokenId > self.settings.totalEggs
        ) {
            return WittyCreatureStatus.Inexistent;
        }
        else if (_wc3.birthTimestamp > 0) {
            return WittyCreatureStatus.Minted;
        }
        else {
            uint _hatchingBlock = self.hatchingBlock;
            if (_hatchingBlock > 0) {
                if (_randomizer.isRandomized(_hatchingBlock)) {
                    uint _expirationBlocks = self.settings.expirationBlocks;
                    if (
                        _expirationBlocks > 0
                            && block.number > _hatchingBlock + _expirationBlocks
                    ) {
                        return WittyCreatureStatus.Frozen;
                    } else {
                        return WittyCreatureStatus.Hatching;
                    }
                } else {
                    return WittyCreatureStatus.Randomizing;
                }
            } else {
                return WittyCreatureStatus.Incubating;
            }
        }
    }

    /// Reduces string into bytes32.
    function toBytes32(string memory _string)
        internal pure
        returns (bytes32 _result)
    {
        if (bytes(_string).length == 0) {
            return 0x0;
        } else {
            assembly {
                _result := mload(add(_string, 32))
            }
        }
    }

    /// Converts bytes32 into string.
    function toString(bytes32 _bytes32)
        internal pure
        returns (string memory)
    {
        bytes memory _bytes = new bytes(length(_bytes32));
        for (uint _i = 0; _i < _bytes.length; _i ++) {
            _bytes[_i] = _bytes32[_i];
        }
        return string(_bytes);
    }

    /// Translate rarity index into a literal string.
    function toString(WittyCreatureRarity _rarity)
        internal pure
        returns (string memory)
    {
        if (_rarity == WittyCreatureRarity.Legendary) {
            return "Legendary";
        } else if (_rarity == WittyCreatureRarity.Rare) {
            return "Rare";
        } else {
            return "Common";
        }
    }

    /// Returns index of Most Significant Bit of given number, applying De Bruijn O(1) algorithm.
    function _msbDeBruijn32(uint32 _v)
        private pure
        returns (uint8)
    {
        uint8[32] memory _bitPosition = [
                0, 9, 1, 10, 13, 21, 2, 29, 11, 14, 16, 18, 22, 25, 3, 30,
                8, 12, 20, 28, 15, 17, 24, 7, 19, 27, 23, 6, 26, 5, 4, 31
            ];
        _v |= _v >> 1;
        _v |= _v >> 2;
        _v |= _v >> 4;
        _v |= _v >> 8;
        _v |= _v >> 16;
        return _bitPosition[
            uint32(_v * uint256(0x07c4acdd)) >> 27
        ];
    }
}
// File: contracts\interfaces\IWc3Decorator.sol
/// @title Witty Creatures 3.0 Decorating interface.
/// @author Otherplane Labs, 2022.
interface IWc3Decorator {
    function baseURI() external view returns (string memory);
    function forged() external view returns (bool);
    function toJSON(bytes32, Wc3Lib.WittyCreature memory) external view returns (string memory);
    function version() external view returns (string memory);
}
// File: contracts\interfaces\IWc3Admin.sol
/// @title Witty Creatures 3.0 Token only-owner interface.
/// @author Otherplane Labs, 2022.
interface IWc3Admin {

    /// Sets Opensea-compliant Decorator contract
    function setDecorator(
        IWc3Decorator
    ) external;

    /// Set estimated gas units required for minting one single token.
    /// @param _estimatedGasLimit Estimated gas units.
    function setMintGasLimit(
        uint256 _estimatedGasLimit
    ) external;

    /// Change batch parameters. Only possible while in 'Batching' status.
    /// @param _expirationBlocks Number of blocks after Witnet randomness is generated, during which creatures may get minted.
    /// @param _totalEggs Max number of tokens that may eventually get minted.
    /// @param _percentileMarks Creature-category ordered percentile marks (Legendary first).    
    function setSettings(
        uint256 _expirationBlocks,
        uint256 _totalEggs,
        uint8[] calldata _percentileMarks
    ) external;

    /// Sets Externally Owned Account that is authorized to sign tokens' intrinsics before getting minted.
    /// @param _signator Externally-owned account to be authorized
    function setSignator(address _signator) external;

    /// Starts hatching, which means: (a) game settings cannot be altered anymore, (b) a 
    /// random number will be requested to the Witnet Decentralized Oracle Network, and (c)
    /// the contract will automatically turn to the 'Hatching' status as soon as the randomness
    /// gets solved by the Witnet oracle. While the randomness request gets solved, the contract will 
    /// remain in 'Randomizing' status.
    function startHatching() external payable;
}
// File: contracts\interfaces\IWc3Events.sol
/// @title Witty Creatures 3.0 Token events.
/// @author Otherplane Labs, 2022.
interface IWc3Events {
    event Decorator(address decorator);
    event MintGasLimit(uint256 gas);
    event Settings(uint256 expirationBlocks, uint256 totalEggs, uint8[] percentileMarks);    
    event Signator(address signator);
}
// File: contracts\interfaces\IWc3Surrogates.sol
/// @title Witty Creatures 3.0 Token surrogating interface.
/// @author Otherplane Labs, 2022.
interface IWc3Surrogates {
    function mint(
        address _tokenOwner,
        string calldata _name,
        uint256 _globalRanking,
        uint256 _guildId,
        uint256 _guildPlayers,
        uint256 _guildRanking,
        uint256 _index,
        uint256 _score,
        bytes calldata _signature
    ) external;
}
// File: ado-contracts\contracts\interfaces\IERC2362.sol
/**
* @dev EIP2362 Interface for pull oracles
* https://github.com/adoracles/EIPs/blob/erc-2362/EIPS/eip-2362.md
*/
interface IERC2362
{
	/**
	 * @dev Exposed function pertaining to EIP standards
	 * @param _id bytes32 ID of the query
	 * @return int,uint,uint returns the value, timestamp, and status code of query
	 */
	function valueFor(bytes32 _id) external view returns(int256,uint256,uint256);
}

// File: witnet-solidity-bridge\contracts\interfaces\IWitnetPriceRouter.sol
/// @title The Witnet Price Router basic interface.
/// @dev Guides implementation of price feeds aggregation contracts.
/// @author The Witnet Foundation.
abstract contract IWitnetPriceRouter
    is
        IERC2362 
{
    /// Emitted everytime a currency pair is attached to a new price feed contract
    /// @dev See https://github.com/adoracles/ADOIPs/blob/main/adoip-0010.md 
    /// @dev to learn how these ids are created.
    event CurrencyPairSet(bytes32 indexed erc2362ID, IERC165 pricefeed);

    /// Helper pure function: returns hash of the provided ERC2362-compliant currency pair caption (aka ID).
    function currencyPairId(string memory) external pure virtual returns (bytes32);

    /// Returns the ERC-165-compliant price feed contract currently serving 
    /// updates on the given currency pair.
    function getPriceFeed(bytes32 _erc2362id) external view virtual returns (IERC165);

    /// Returns human-readable ERC2362-based caption of the currency pair being
    /// served by the given price feed contract address. 
    /// @dev Should fail if the given price feed contract address is not currently
    /// @dev registered in the router.
    function getPriceFeedCaption(IERC165) external view virtual returns (string memory);

    /// Returns human-readable caption of the ERC2362-based currency pair identifier, if known.
    function lookupERC2362ID(bytes32 _erc2362id) external view virtual returns (string memory);

    /// Register a price feed contract that will serve updates for the given currency pair.
    /// @dev Setting zero address to a currency pair implies that it will not be served any longer.
    /// @dev Otherwise, should fail if the price feed contract does not support the `IWitnetPriceFeed` interface,
    /// @dev or if given price feed is already serving another currency pair (within this WitnetPriceRouter instance).
    function setPriceFeed(
            IERC165 _pricefeed,
            uint256 _decimals,
            string calldata _base,
            string calldata _quote
        )
        external virtual;

    /// Returns list of known currency pairs IDs.
    function supportedCurrencyPairs() external view virtual returns (bytes32[] memory);

    /// Returns `true` if given pair is currently being served by a compliant price feed contract.
    function supportsCurrencyPair(bytes32 _erc2362id) external view virtual returns (bool);

    /// Returns `true` if given price feed contract is currently serving updates to any known currency pair. 
    function supportsPriceFeed(IERC165 _priceFeed) external view virtual returns (bool);
}
// File: contracts\interfaces\IWc3View.sol
/// @title Witty Creatures 3.0 Token viewing interface.
/// @author Otherplane Labs, 2022.
interface IWc3View {
    function decorator() external view returns (IWc3Decorator);
    function randomizer() external view returns (IWitnetRandomness);
    function router() external view returns (IWitnetPriceRouter);
    function signator() external view returns (address);

    function estimateMintUsdCost6(uint _gasPrice) external view returns (uint64);
    
    function getHatchingBlock() external view returns (uint256);
    function getSettings() external view returns (Wc3Lib.Settings memory);    
    function getStatus() external view returns (Wc3Lib.Status);
    function getTokenIntrinsics(uint256 _tokenId) external view returns (Wc3Lib.WittyCreature memory);
    function getTokenStatus(uint256 _tokenId) external view returns (Wc3Lib.WittyCreatureStatus);

    function preview(
        string calldata _name,
        uint256 _globalRanking,
        uint256 _guildId,
        uint256 _guildPlayers,
        uint256 _guildRanking,
        uint256 _index,
        uint256 _score
    ) external view returns (string memory);
    
    function totalSupply() external view returns (uint256);
    function version() external view returns (string memory);
}
// File: contracts\Wc3Token.sol
// import "@openzeppelin/contracts/utils/Strings.sol";





/// @title Witty Creatures 3.0 - ERC721 Token contract
/// @author Otherplane Labs, 2022.
contract Wc3Token
    is
        ERC721,
        Ownable,
        ReentrancyGuard,
        IWc3Admin,
        IWc3Events,
        IWc3Surrogates,
        IWc3View
{
    // using Strings for bytes32;
    using Strings for uint256;
    using Wc3Lib for bytes32;
    using Wc3Lib for string;
    using Wc3Lib for Wc3Lib.Storage;

    IWitnetRandomness immutable public override randomizer;
    IWitnetPriceRouter immutable public override router;

    uint256 immutable public guildId;
    bytes32 immutable public usdPriceAssetId;
    bytes32 immutable internal __version;

    Wc3Lib.Storage internal __storage;    

    modifier inStatus(Wc3Lib.Status _status) {
        require(
            __storage.status(randomizer) == _status,
            Wc3Lib.statusRevertMessage(_status)
        );
        _;
    }

    modifier tokenExists(uint256 _tokenId) {
        require(
            _exists(_tokenId),
            "Wc3Token: inexistent token"
        );
        _;
    }

    constructor(
            string memory _version,
            address _randomizer,
            address _router,
            address _decorator,
            address _signator,
            uint8[] memory _percentileMarks,
            uint256 _expirationBlocks,
            uint256 _totalEggs,
            string memory _currencySymbol,
            uint256 _mintGasLimit            
        )
        ERC721("Witty Creatures EthCC'5", "WC3")
    {
        assert(_randomizer != address(0));
        assert(_router != address(0));

        guildId = block.chainid;        
        __version = _version.toBytes32();      

        randomizer = IWitnetRandomness(_randomizer);
        router = IWitnetPriceRouter(_router);

        setDecorator(
            IWc3Decorator(_decorator)
        );
        setMintGasLimit(
            _mintGasLimit
        );
        setSettings(
            _expirationBlocks,
            _totalEggs,
            _percentileMarks
        );
        setSignator(
            _signator
        );        

        string memory _usdPriceCaption = string(abi.encodePacked(
           "Price-",
           _currencySymbol,
           "/USD-6" 
        ));
        require(
            router.supportsCurrencyPair(keccak256(bytes(_usdPriceCaption))),
            string(abi.encodePacked(
                bytes("Wc3Token: unsupported currency pair: "),
                _usdPriceCaption
            ))
        );
        usdPriceAssetId = keccak256(bytes(_usdPriceCaption));
    }

    /// @dev Required for receiving unused funds back when calling to `randomizer.randomize()`
    receive() external payable {}


    // ========================================================================
    // --- 'ERC721Metadata' overriden functions -------------------------------
  
    function baseURI()
        public view
        virtual
        returns (string memory)
    {
        return decorator().baseURI();
    }
    
    function metadata(uint256 _tokenId)
        external view 
        virtual 
        tokenExists(_tokenId)
        returns (string memory)
    {
        return decorator().toJSON(
            randomizer.getRandomnessAfter(__storage.hatchingBlock),
            __storage.intrinsics[_tokenId]
        );
    }

    function tokenURI(uint256 _tokenId)
        public view
        virtual override
        tokenExists(_tokenId)
        returns (string memory)
    {
        return string(abi.encodePacked(
            baseURI(),
            "metadata/",
            _tokenId.toString()
        ));
    }


    // ========================================================================
    // --- Implementation of 'IWc3Admin' --------------------------------------

    /// Sets Opensea-compliant Decorator contract
    /// @dev Only callable by the owner, when in 'Batching' status.
    function setDecorator(IWc3Decorator _decorator)
        public
        override
        onlyOwner
        inStatus(Wc3Lib.Status.Batching)
    {
        require(
            address(_decorator) != address(0),
            "Wc3Token: no decorator"
        );
        __storage.decorator = address(_decorator);
        emit Decorator(address(_decorator));
    }

    /// Set estimated gas units required for minting one single token.
    /// @dev Only callable by the owner, at any time.
    /// @param _estimatedGasLimit Estimated gas units.
    function setMintGasLimit(
            uint256 _estimatedGasLimit
        )
        public override
        onlyOwner
    {
        __storage.mintGasLimit = _estimatedGasLimit;
        emit MintGasLimit(_estimatedGasLimit);
    }

    /// Sets Externally Owned Account that is authorized to sign tokens' intrinsics before getting minted.
    /// @dev Only callable by the owner, at any time.
    /// @dev Cannot be set to zero address.
    /// @param _signator Externally-owned account to be authorized    
    function setSignator(address _signator)
        public override
        onlyOwner
    {
        require(
            _signator != address(0),
            "Wc3Token: no signator"
        );
        __storage.signator = _signator;
        emit Signator(_signator);
    }

    /// Change batch parameters. Only possible while in 'Batching' status.
    /// @dev Only callable by the owner, while on 'Batching' status.
    /// @param _expirationBlocks Number of blocks after Witnet randomness is generated, during which creatures may get minted.
    /// @param _totalEggs Max number of tokens that may eventually get minted.
    /// @param _percentileMarks Creature-category ordered percentile marks (Legendary first).   
    function setSettings(
            uint256 _expirationBlocks,
            uint256 _totalEggs,
            uint8[] memory _percentileMarks
        )
        public
        virtual override
        onlyOwner
        inStatus(Wc3Lib.Status.Batching)
    {
        require(
            _totalEggs > 0,
            "Wc3Token: zero eggs"
        );
        require(
            _percentileMarks.length == uint8(Wc3Lib.WittyCreatureRarity.Common) + 1,
            "Wc3Token: bad percentile marks"
        );        

        __storage.settings.expirationBlocks = _expirationBlocks;
        __storage.settings.totalEggs = _totalEggs;
        __storage.settings.percentileMarks = new uint8[](_percentileMarks.length);

        uint8 _checkSum; for (uint8 _i = 0; _i < _percentileMarks.length; _i ++) {
            uint8 _mark = _percentileMarks[_i];
            __storage.settings.percentileMarks[_i] = _mark;
            _checkSum += _mark;
        }
        require(_checkSum == 100, "Wc3Token: bad percentile checksum");

        emit Settings(
            _expirationBlocks,
            _totalEggs,
            _percentileMarks
        );
    }

    /// Starts hatching, which means: (a) game settings cannot be altered anymore, (b) a 
    /// random number will be requested to the Witnet Decentralized Oracle Network, and (c)
    /// the contract will automatically turn to the 'Hatching' status as soon as the randomness
    /// gets solved by the Witnet oracle. While the randomness request gets solved, the contract will 
    /// remain in 'Randomizing' status.
    /// @dev Only callable by the owner, while in 'Batching' status.
    function startHatching()
        external payable
        virtual
        nonReentrant
        onlyOwner
        inStatus(Wc3Lib.Status.Batching)
    {   
        // Decorator must be forged first:
        require(
            decorator().forged(),
            "Wc3Token: unforged decorator"
        );

        // Request randomness from the Witnet oracle:
        uint _usedFunds = randomizer.randomize{ value: msg.value }();

        // Sets hatching block number:
        __storage.hatchingBlock = block.number;
        
        // Transfer back unused funds:
        if (_usedFunds < msg.value ) {
            payable(msg.sender).transfer(msg.value - _usedFunds);   
        }
    }

    // ========================================================================
    // --- Implementation of 'IWc3Surrogates' -------------------------------

    function mint(
            address _tokenOwner,
            string calldata _name,
            uint256 _globalRanking,
            uint256 _guildId,
            uint256 _guildPlayers,
            uint256 _guildRanking,
            uint256 _index,
            uint256 _score,
            bytes calldata _signature
        )
        external
        virtual override
        nonReentrant
        inStatus(Wc3Lib.Status.Hatching)
    {
        // Verify guildfundamental facts:
        _verifyGuildFacts(
            _guildId,
            _guildPlayers,
            _guildRanking
        );

        // Verify signature:
        _verifySignature(
            _tokenOwner,
            _name,
            _globalRanking,
            _guildId,
            _guildPlayers,
            _guildRanking,
            _index,
            _score,            
            _signature
        );

        // Token id will be the same as the achieved guild ranking for this egg during EthCC'5:
        uint256 _tokenId = _guildRanking;

        // Verify the token has not been already minted:
        require(
            __storage.intrinsics[_tokenId].birthTimestamp == 0,
            "Wc3Token: already minted"
        );

        // Save token intrinsics to storage:
        __mintWittyCreature(
            _name,
            _globalRanking,
            _guildPlayers,
            _guildRanking,
            _index,
            _score
        );

        // Mint the actual ERC-721 token:
        _safeMint(_tokenOwner, _tokenId);

        // Increment token supply:
        __storage.totalSupply ++;
    }


    // ========================================================================
    // --- Implementation of 'IWc3View' ------------------------------------

    
    function decorator()
        public view
        override
        returns (IWc3Decorator)
    {
        return IWc3Decorator(__storage.decorator);
    }
    
    function estimateMintUsdCost6(uint _gasPrice)
        public view
        override
        returns (uint64)
    {
        (int _lastKnownPrice,,) = router.valueFor(usdPriceAssetId);
        uint _estimatedFee = _gasPrice * __storage.mintGasLimit;
        return uint64((_estimatedFee * uint(_lastKnownPrice)) / 10 ** 18);
    }

    function getHatchingBlock()
        external view
        override
        returns (uint256)
    {
        return __storage.hatchingBlock;
    }

    function getSettings()
        external view
        override
        returns (Wc3Lib.Settings memory)
    {
        return __storage.settings;
    }

    function getStatus()
        public view
        override
        returns (Wc3Lib.Status)
    {
        return __storage.status(randomizer);
    }

    function getTokenIntrinsics(uint256 _tokenId)
        external view
        override
        returns (Wc3Lib.WittyCreature memory)
    {
        return __storage.intrinsics[_tokenId];
    }

    function getTokenStatus(uint256 _tokenId)
        external view
        override
        returns (Wc3Lib.WittyCreatureStatus)
    {
        return __storage.tokenStatus(randomizer, _tokenId);
    }

    function preview(
            string calldata _name,
            uint256 _globalRanking,
            uint256 _guildId,
            uint256 _guildPlayers,
            uint256 _guildRanking,
            uint256 _index,
            uint256 _score
        )
        external view
        virtual override
        inStatus(Wc3Lib.Status.Hatching)
        returns (string memory)
    {
        // Verify guild facts:
        _verifyGuildFacts(
            _guildId,
            _guildPlayers,
            _guildRanking
        );

        // Preview creature image:
        return decorator().toJSON(
            randomizer.getRandomnessAfter(__storage.hatchingBlock),
            Wc3Lib.WittyCreature({
                name: _name,
                birthTimestamp: 0,
                mintUsdCost6: estimateMintUsdCost6(tx.gasprice),
                globalRanking: _globalRanking,
                guildRanking: _guildRanking,
                index: _index,
                rarity: __storage.rarity((_guildRanking * 100) / _guildPlayers),
                score: _score
            })
        );
    }

    function signator()
        external view
        override
        returns (address)
    {
        return __storage.signator;
    }

    function totalSupply()
        public view
        override
        returns (uint256)
    {
        return __storage.totalSupply;
    }

    function version()
        external view
        override
        returns (string memory)
    {
        return __version.toString();
    }

    
    // ------------------------------------------------------------------------
    // --- INTERNAL VIRTUAL METHODS -------------------------------------------
    // ------------------------------------------------------------------------

    function __mintWittyCreature(
            string calldata _name,
            uint256 _globalRanking,
            uint256 _guildPlayers,
            uint256 _guildRanking,
            uint256 _index,
            uint256 _score
        )
        internal
        virtual
    {
        __storage.intrinsics[_guildRanking] = Wc3Lib.WittyCreature({
            name: _name,
            birthTimestamp: block.timestamp,
            mintUsdCost6: estimateMintUsdCost6(tx.gasprice),
            globalRanking: _globalRanking,
            guildRanking: _guildRanking,
            index: _index,
            rarity: __storage.rarity((_guildRanking * 100) / _guildPlayers),
            score: _score
        });
    }

    function _verifyGuildFacts(
            uint _guildId,
            uint _guildPlayers,
            uint _guildRanking
        )
        internal view
        virtual
    {
        require(_guildId == guildId, "Wc3Token: bad guild");
        
        require(_guildPlayers > 0, "Wc3Token: no players");
        require(_guildPlayers <= __storage.settings.totalEggs, "Wc3Token: bad players");
        
        require(_guildRanking > 0, "Wc3Token: no ranking");
        require(_guildRanking <= _guildPlayers, "Wc3Token: bad ranking");
    }

    function _verifySignature(
            address _tokenOwner,
            string calldata _name,
            uint256 _globalRanking,
            uint256 _guildId,
            uint256 _guildPlayers,
            uint256 _guildRanking,
            uint256 _index,
            uint256 _score,
            bytes calldata _signature
        )
        internal view
        virtual
    {
        bytes32 _hash = keccak256(abi.encodePacked(
            _tokenOwner,
            _name,
            _globalRanking,
            _guildId,
            _guildPlayers,
            _guildRanking,
            _index,
            _score
        ));
        require(
            Wc3Lib.recoverAddr(_hash, _signature) == __storage.signator,
            "Wc3Token: bad signature"
        );
    }

}