/**
 *Submitted for verification at polygonscan.com on 2023-07-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

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

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

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
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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
        delete _tokenApprovals[tokenId];

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
        delete _tokenApprovals[tokenId];

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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
     * @dev Moves `amount` of tokens from `from` to `to`.
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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

interface IFeedExtension {

    struct SecondaryFee{
        address address_;
        string symbol;
        uint256 decimals;
        uint256 amount;
        uint256 id;
        bool or;
    }

    function withdraw(bytes calldata) external;

    function setInfo(address, uint256) external;

    function subscribe(address) external payable;

    function unsubscribe(address, uint256) external;

    function getPrice() external returns (uint256);

    function getTokenAddress() external returns (address);

    function getTokenId() external returns (uint256);

    function getTokenSymbol() external returns (string memory);

    function getTokenDecimals() external returns (uint256);

    function getFeedAddress() external returns (address);

    function getSecondaryFees(uint256) external returns (SecondaryFee memory);

    function supportsInterface(bytes4) external returns (bool);
}

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

library CheckFeedExtension {
    function check(address extensionAddress) external view {
        require(ERC165Checker.supportsInterface(extensionAddress, type(IFeedExtension).interfaceId), "Inv. Extension");
    }
}

contract Feed is ReentrancyGuard, Ownable {
	address immutable private MAIL_ADDRESS;
	address immutable private MAIL_FEEDS_ADDRESS;
	uint256 immutable private MAX_NUMBER_SUBSCRIBERS;
	uint256 private price;
	uint256 private timeInSecs;
	uint256 private totalSubscribers;
	uint256 private expiryTime;
	uint256 private countSubscribers;
	uint8 private rating;
	uint256 private totalRatings;
	address private extensionAddress;
	mapping(address => uint256) private addressToSubscriberId;
	mapping(address => uint8) private ratings;
	IFeedExtension private extension;
	MailERC721 private mailERC721;

	struct Subscriber{
		address address_;
		uint256 subscribeTime;
		uint256 expiryTime;
		bool isBlocked;
	}
	mapping(uint256 => Subscriber) private subscribers;

	constructor(address mailAddress, address owner_, uint256 timeInSecs_, address extensionAddress_, uint256 price_, uint256 maxNumberSubscribers) {
		MAIL_ADDRESS = mailAddress;
		mailERC721 = MailERC721(MAIL_ADDRESS);
		MAIL_FEEDS_ADDRESS = mailERC721.getMailFeedsAddress();
		transferOwnership(owner_);
		timeInSecs = timeInSecs_;

		if(extensionAddress_ != address(0)){
			CheckFeedExtension.check(extensionAddress_);
			extension = IFeedExtension(extensionAddress_);
			extension.setInfo(address(this), price_);
		}

		price = price_;
		expiryTime = block.timestamp + timeInSecs_;
		MAX_NUMBER_SUBSCRIBERS = maxNumberSubscribers;
		extensionAddress = extensionAddress_;
	}

	function subscribe() external payable {
		_subscribe(msg.sender);
	}

	function unsubscribe() external nonReentrant {
		_unsubscribe(msg.sender);
	}

	function removeSubscriber(address subscriber) external nonReentrant onlyOwner {
		_unsubscribe(subscriber);
	}

	function withdrawEther(uint256 amount) external onlyOwner {
		//the owner can withdraw only when the feed period ends - if he renews/updates the feed, he needs to wait it ends
		require(block.timestamp >= expiryTime, "Inv. withdraw");

		(bool sentEther,) = msg.sender.call{value: amount}("");
		require(sentEther, "Failed");
	}

	function withdrawToken(bytes calldata args) external onlyOwner {
		require(block.timestamp >= expiryTime, "Inv. withdraw");
		extension.withdraw(args);
	}

	function setInfo(address extensionAddress_, uint256 timeInSecs_, uint256 price_) external onlyOwner {
		require(block.timestamp >= expiryTime, "Can't set");

		if(extensionAddress_ != address(0)){
			CheckFeedExtension.check(extensionAddress_);
			extension = IFeedExtension(extensionAddress_);
			extension.setInfo(address(this), price_);
		}

		timeInSecs = timeInSecs_;
		price = price_;
		extensionAddress = extensionAddress_;
	}

	function blockAddress(address address_, bool status) external onlyOwner {
		Subscriber storage subscriber = subscribers[addressToSubscriberId[address_]];
		subscriber.isBlocked = status;
	}

	function setRating(uint8 rating_) external {
		require(subscribers[addressToSubscriberId[msg.sender]].expiryTime >= block.timestamp, "Can't set");
		require(rating_ > 0 && rating_ < 11, "Inv. rating");
		require(ratings[msg.sender] == 0, "Inv. caller");

		totalRatings = totalRatings + 1;
		rating = uint8((rating + rating_) / totalRatings);
		ratings[msg.sender] = rating_;
	}

	function renewFeed() external {
		require(msg.sender == MAIL_FEEDS_ADDRESS, "Inv. caller");
		expiryTime = block.timestamp + timeInSecs;
	}

	function getRating(address user) external view returns (uint8, uint8, uint256){
		return (ratings[user], rating, totalRatings);
	}

	function getInfo() external view returns (uint256, uint256, uint256, uint256, uint256, uint256){
		return (timeInSecs, expiryTime, price, totalSubscribers, MAX_NUMBER_SUBSCRIBERS, countSubscribers);
	}

	function getExtensionInfo() external view returns (address){
		return extensionAddress;
	}

	function getSubscribers(uint256 length) external view returns (address[] memory){
		address[] memory subscribers_ = new address[](length);
		uint256 id;

		for(uint i=1;i<=length;){
			Subscriber storage subscriber = subscribers[i];
			if(subscriber.address_ != address(0) && subscriber.expiryTime >= block.timestamp){
				subscribers_[id] = subscriber.address_;
				id++;
			}
			unchecked{i++;}
		}

		return subscribers_;
	}

	function getSubscriber(address subscriberAddress, uint256 id) external view returns (uint256, Subscriber memory){
		return (addressToSubscriberId[subscriberAddress], subscribers[id]);
	}

	function _subscribe(address subscriberAddress) private {
		require(expiryTime > block.timestamp, "Inv. subs.");

		if(address(extension) != address(0)){
			extension.subscribe{value: msg.value}(subscriberAddress);
		}
		else{
			require(msg.value >= price, "Inv. value");
		}

		uint256 subscriberId = addressToSubscriberId[subscriberAddress];
		Subscriber storage subscriber = subscribers[subscriberId];
		require(!subscriber.isBlocked, "Blocked user");

		if(subscriberId == 0){
			totalSubscribers = totalSubscribers + 1;
			subscriber = subscribers[totalSubscribers];
			subscriber.address_ = subscriberAddress;
			subscribers[totalSubscribers] = subscriber;
			addressToSubscriberId[subscriberAddress] = totalSubscribers;
			mailERC721.addSubscription(subscriberAddress);
		}
		subscriber.subscribeTime = block.timestamp;
		subscriber.expiryTime = block.timestamp + timeInSecs;

		if(MAX_NUMBER_SUBSCRIBERS != 0){
			require(countSubscribers < MAX_NUMBER_SUBSCRIBERS, "Max. subs.");
			countSubscribers = countSubscribers + 1;
		}
	}

	function _unsubscribe(address subscriberAddress) private {
		uint256 subscriberId = addressToSubscriberId[subscriberAddress];
		Subscriber storage subscriber = subscribers[subscriberId];
		require(subscriberId != 0, "Inv. user");

		uint256 value = price;
		if(msg.sender == subscriberAddress){
			require(subscriber.expiryTime > block.timestamp, "Inv. unsubs.");
			uint256 difference = subscriber.expiryTime - block.timestamp;
			value = (difference * price) / timeInSecs;
		}

		if(address(extension) != address(0)){
			extension.unsubscribe(subscriberAddress, value);
		}
		else{
			(bool sentEther,) = subscriberAddress.call{value: value}("");
			require(sentEther, "Failed");
		}

		subscriber.address_ = address(0);
		subscriber.subscribeTime = 0;
		subscriber.expiryTime = 0;
		subscribers[subscriberId] = subscriber;
		addressToSubscriberId[subscriberAddress] = 0;
		mailERC721.removeSubscription(subscriberAddress);

		if(MAX_NUMBER_SUBSCRIBERS != 0){
			countSubscribers = countSubscribers - 1;
		}
	}
}

interface IMailExtension {

    struct SecondaryFee{
        address address_;
        string symbol;
        uint256 decimals;
        uint256 amount;
        uint256 id;
        bool or;
    }

    function antiSPAM(address, address, uint256) external payable;

    function getTokenAddress() external returns (address);

    function getTokenId() external returns (uint256);

    function getTokenSymbol() external returns (string memory);

    function getTokenDecimals() external returns (uint256);

    function getSecondaryFees(uint256) external returns (SecondaryFee memory);

    function supportsInterface(bytes4) external returns (bool);
}

contract MailFeeds {
    uint24 constant private MAIL_FEED_EXPIRY_TIME = 30 days;
    mapping(address => mapping(uint256 => address)) private mailFeedOwners;
    mapping(address => uint256) private totalMailFeedsByOwner;
    mapping(uint256 => address) private mailFeedAddresses;
    mapping(uint256 => string) private mailFeedNames;
    mapping(uint256 => string) private mailFeedDescriptions;
    mapping(address => uint256) private mailFeedIds;
    mapping(address => uint256) private mailFeedAddressesToIndexes;
    mapping(address => mapping(address => uint256)) private mailFeedOwnerAddressesToIndexes;
    uint256 private totalMailFeeds;
    uint256 private totalDeletedMailFeeds;
    address private owner;

    struct MailFeed{
        string name;
        string description;
        address owner;
        uint256 expiryTime;
    }
    mapping(address => MailFeed) private mailFeeds;

    constructor(){
        owner = msg.sender;
    }

    function createMailFeed(address owner_, address feedAddress, string[2] calldata args) external {
        require(msg.sender == owner, "Inv. caller");

        MailFeed storage mailFeed = mailFeeds[feedAddress];
        mailFeed.name = args[0];
        mailFeed.description = args[1];
        mailFeed.owner = owner_;
        mailFeed.expiryTime = block.timestamp + MAIL_FEED_EXPIRY_TIME;

        uint256 total = totalMailFeedsByOwner[owner_];
        mailFeedOwners[owner_][total] = feedAddress;
        totalMailFeedsByOwner[owner_] = total + 1;
        mailFeedOwnerAddressesToIndexes[owner_][feedAddress] = total;

        total = totalMailFeeds;
        mailFeedIds[feedAddress] = total;
        mailFeedAddresses[total] = feedAddress;
        mailFeedNames[total] = args[0];
        mailFeedDescriptions[total] = args[1];
        totalMailFeeds = total + 1;
        mailFeedAddressesToIndexes[feedAddress] = total;
    }

    function renewMailFeeds(address owner_, address[] calldata feedAddresses) external {
        require(msg.sender == owner, "Inv. caller");
        uint256 length = feedAddresses.length;

        for(uint i;i<length;){
            address feedAddress = feedAddresses[i];
            MailFeed storage mailFeed = mailFeeds[feedAddress];
            require(owner_ == mailFeed.owner, "Inv. owner");
            require(block.timestamp >= mailFeed.expiryTime, "Not expired");

            mailFeed.expiryTime = block.timestamp + MAIL_FEED_EXPIRY_TIME;

            Feed(feedAddress).renewFeed();

            unchecked{i++;}
        }
    }

    function deleteMailFeeds(address[] calldata feedAddresses) external {
        uint256 length = feedAddresses.length;
        for(uint i;i<length;){
            address feedAddress = feedAddresses[i];
            MailFeed storage mailFeed = mailFeeds[feedAddress];
            require(msg.sender == mailFeed.owner, "Inv. caller");
            require(block.timestamp >= mailFeed.expiryTime, "Inv. deletion");

            uint id = mailFeedIds[feedAddress];
            mailFeedNames[id] = "";
            mailFeedDescriptions[id] = "";

            mailFeedIds[feedAddress] = 0;
            mailFeed.name = "";
            mailFeed.description = "";
            mailFeed.owner = address(0);
            mailFeed.expiryTime = 0;

            totalDeletedMailFeeds = totalDeletedMailFeeds + 1;
            totalMailFeedsByOwner[msg.sender] = totalMailFeedsByOwner[msg.sender] - 1;

            mapping(uint256 => address) storage mailFeeds_ = mailFeedOwners[msg.sender];
            uint256 index = mailFeedOwnerAddressesToIndexes[msg.sender][feedAddress];
            mailFeeds_[index] = address(0);

            index = mailFeedAddressesToIndexes[feedAddress];
            mailFeedAddresses[index] = address(0);

            unchecked{i++;}
        }
    }

    function setArgs(address feedAddress, string[2] calldata args) external {
        MailFeed storage mailFeed = mailFeeds[feedAddress];
        require(msg.sender == mailFeed.owner, "Inv. caller");

        mailFeed.name = args[0];
        mailFeed.description = args[1];
        uint256 id = mailFeedIds[feedAddress];
        mailFeedNames[id] = args[0];
        mailFeedDescriptions[id] = args[1];
    }

    function getFeeds(address owner_, uint256 fromId, uint256 length, uint256 total, bool notExpired, uint8 minRating) external view returns (address[] memory) {
        address[] memory addresses = new address[](length);
        uint256 id;

        for(uint i=fromId;i<total;){
            address addr_ = mailFeedAddresses[i];

            uint8 rating;
            uint256 expiryTime = block.timestamp;
            if(addr_ != address(0)){
                (,rating,) = Feed(addr_).getRating(owner_);
                (,expiryTime,,,,) = Feed(addr_).getInfo();
            }

            if(addr_ != address(0) && (owner_ == address(0) || owner_ == mailFeeds[addr_].owner) &&
            (rating == 0 || rating >= minRating) && (!notExpired || block.timestamp <= expiryTime)){
                addresses[id] = addr_;
                id++;

                if(id == length){
                    break;
                }
            }
            unchecked{i++;}
        }

        return addresses;
    }

    function searchFeed(string calldata search, uint256 length) external view returns (address) {
        address address_;
        for(uint i;i<length;){
            if(_contains(mailFeedNames[i], search) || _contains(mailFeedDescriptions[i], search)){
                address_ = mailFeedAddresses[i];
                break;
            }

            unchecked{i++;}
        }
        return address_;
    }

    function getInfo(address feedAddress, address owner_, uint256 id) external view returns (MailFeed memory, uint256, address, uint24){
        return (mailFeeds[feedAddress], totalMailFeedsByOwner[owner_], mailFeedOwners[owner_][id], MAIL_FEED_EXPIRY_TIME);
    }

    function getTotals(address owner_, uint8 minRating, uint256 length) external view returns(uint256, uint256, uint256){
        uint256 totalMinRatingNotExpired;
        for(uint i;i<length;){
            address addr_ = mailFeedAddresses[i];
            if(addr_ != address(0)){
                Feed feed = Feed(addr_);
                (,uint8 rating,) = feed.getRating(owner_);
                (,uint256 expiryTime,,,,) = feed.getInfo();
                if(block.timestamp <= expiryTime && rating == 0 || rating >= minRating){
                    totalMinRatingNotExpired++;
                }
            }
            unchecked{i++;}
        }

        return (totalMailFeeds, totalDeletedMailFeeds, totalMinRatingNotExpired);
    }

    function _contains(string storage where, string calldata what) private pure returns (bool){
        bytes memory whereBytes = bytes(where);
        bytes memory whatBytes = bytes(what);
        uint256 whereLength = whereBytes.length;
        uint256 whatLength = whatBytes.length;
        bool found;

        if(whereLength >= whatLength){
            uint256 length = whereLength - whatLength;
            for (uint i;i<=length;) {
                bool flag = true;

                for (uint j;j<whatLength;){
                    if (whereBytes[i + j] != whatBytes[j]) {
                        flag = false;
                        break;
                    }
                    unchecked{j++;}
                }

                if (flag) {
                    found = true;
                    break;
                }

                unchecked{i++;}
            }
        }

        return found;
    }
}

contract Contacts {
    address immutable private MAIL_ADDRESS;
    mapping(uint256 => address) private users;
    mapping(address => uint256) private totalByUser;
    mapping(address => uint256) private removedByUser;
    mapping(address => mapping(string => string)) private addressesToNicknames;
    mapping(address => mapping(string => string)) private nicknamesToAddresses;
    uint256 private usersTotal;

    struct Contact{
        uint256 id;
        string symbol;
        string address_;
        string nickname;
    }
    mapping(address => mapping(uint256 => Contact)) private contacts;

    constructor(address mailAddress){
        MAIL_ADDRESS = mailAddress;
    }

    function addContact(address user, string[5] calldata args) external {
        require(msg.sender == MAIL_ADDRESS, "Inv. caller");
        require(bytes(addressesToNicknames[user][args[3]]).length == 0 && bytes(nicknamesToAddresses[user][args[4]]).length == 0,"Inv. args");

        if(totalByUser[user] == 0){
            users[usersTotal] = user;
            usersTotal = usersTotal + 1;
        }

        uint256 id = totalByUser[user];
        contacts[user][id] = Contact(id, args[0], args[1], args[2]);
        addressesToNicknames[user][args[3]] = args[2];
        nicknamesToAddresses[user][args[4]] = args[1];
        totalByUser[user] = id + 1;
    }

    function setContact(uint256 id, string[7] calldata args) external {
        require(totalByUser[msg.sender] > 0, "Inv. caller");

        Contact storage contact = contacts[msg.sender][id];
        require(keccak256(abi.encodePacked(addressesToNicknames[msg.sender][args[5]])) == keccak256(abi.encodePacked(contact.nickname)) &&
            keccak256(abi.encodePacked(nicknamesToAddresses[msg.sender][args[6]])) == keccak256(abi.encodePacked(contact.address_)), "Inv. args");
        addressesToNicknames[msg.sender][args[5]] = "";
        nicknamesToAddresses[msg.sender][args[6]] = "";
        contacts[msg.sender][id] = Contact(id, "", "", "");

        contacts[msg.sender][id] = Contact(id, args[0], args[1], args[2]);
        addressesToNicknames[msg.sender][args[3]] = args[2];
        nicknamesToAddresses[msg.sender][args[4]] = args[1];
    }

    function removeContacts(uint256[] calldata ids, string[] calldata args) external {
        require(totalByUser[msg.sender] > 0, "Inv. caller");

        uint256 length = ids.length;
        for(uint i;i<length;){
            uint256 id = ids[i];
            uint256 argId = i % 2 == 0 ? i : i + 1;
            string memory arg0 = args[argId];
            string memory arg1 = args[argId + 1];

            Contact storage contact = contacts[msg.sender][id];
            require(keccak256(abi.encodePacked(addressesToNicknames[msg.sender][arg0])) == keccak256(abi.encodePacked(contact.nickname)) &&
            keccak256(abi.encodePacked(nicknamesToAddresses[msg.sender][arg1])) == keccak256(abi.encodePacked(contact.address_)), "Inv. args");

            addressesToNicknames[msg.sender][arg0] = "";
            nicknamesToAddresses[msg.sender][arg1] = "";
            contacts[msg.sender][id] = Contact(id, "", "", "");

            unchecked{i++;}
        }

        removedByUser[msg.sender] = removedByUser[msg.sender] + length;
    }

    function getInfo(address user, uint256 id) external view returns (address, uint256, uint256, uint256, address) {
        return (users[id], totalByUser[user], removedByUser[user], usersTotal, MAIL_ADDRESS);
    }

    function getNicknameFromAddress(address user, string calldata addressToNickname) external view returns (string memory) {
        return addressesToNicknames[user][addressToNickname];
    }

    function getAddressFromNickname(address user, string calldata nicknameToAddress) external view returns (string memory) {
        return nicknamesToAddresses[user][nicknameToAddress];
    }

    function getContacts(address from, string calldata symbol, uint256 fromId, uint256 length) external view returns (Contact[] memory) {
        Contact[] memory contacts_ = new Contact[](length);
        uint256 userTotal_ = totalByUser[from];
        uint256 id;

        for(uint i=fromId;i<=userTotal_;){
            Contact storage contact = contacts[from][i];
            if((bytes(symbol).length > 0 && keccak256(abi.encodePacked(contact.symbol)) == keccak256(abi.encodePacked(symbol))) ||
                (bytes(contact.address_).length > 0)){
                contacts_[id] = contact;
                id++;

                if(id == length){
                    break;
                }
            }
            unchecked{i++;}
        }

        return contacts_;
    }
}

library CheckMailExtension {
    function check(address extensionAddress) external view {
        if(extensionAddress != address(0)){
            require(ERC165Checker.supportsInterface(extensionAddress, type(IMailExtension).interfaceId), "Inv. Extension");
        }
    }
}

contract MailERC721 is ERC721, ReentrancyGuard {
	address immutable private LAUNCHPAD_ADDRESS;
	uint64 constant private MIN_TOTAL_CREDITS = 1 ether;
	uint80 constant private MAIL_FEED_PRICE = 10_000 ether;
	uint64 constant private CONTACTS_PRICE = 10 ether;
	uint8 constant private ALLOWED = 1;
	uint8 constant private BLOCKED = 2;
	uint8 constant private LIST_SENT = 1;
	uint8 constant private LIST_ALL_MAIL = 2;
	uint8 constant private LIST_TRASH = 3;
	uint8 constant private LIST_BLOCKED_USERS = 4;
	uint8 constant private LIST_FEEDS = 5;
	uint8 constant private LIST_SUBSCRIPTIONS = 6;
	uint256 private mailBoxId;
	uint256 private mailId;
	mapping(uint256 => address) private mailBoxIdToAddress;
	mapping(address => mapping(address => uint8)) private addressStatus;
	mapping(address => mapping(address => bool)) private freeMails;
	mapping(uint256 => uint256) private mailReceivedIdsToIndexes;
	mapping(uint256 => uint256) private mailAllMailIdsToIndexes;
	mapping(address => uint256) private blockedAddressesToIndexes;
	mapping(address => uint256) private subscriptionsAddressesToIndexes;
	ERC20 private credits;
	MailFeeds private mailFeeds;

	struct MailBox{
		uint256 id;
		string uri;
		uint256 fee;
		bool isPaid;
		address extensionAddress;
		uint256 totalEmailsReceived;
		uint256 totalEmailsSent;
		uint256 totalEmails;
		uint256 totalBurned;
		uint256 totalBlockedUsers;
		uint256 totalRemovedBlock;
		uint256 totalSubscriptions;
		uint256 totalUnsubscriptions;
		mapping(uint256 => Mail) mailReceived;
		mapping(uint256 => Mail) mailSent;
		mapping(uint256 => Mail) mailBurned;
		mapping(uint256 => Mail) allMail;
		mapping(address => mapping(uint256 => address)) subscription;
		mapping(bytes32 => uint256) sentTo;
		mapping(address => uint256) totalSentTo;
		mapping(uint256 => address) blockedUsers;
	}
	mapping(address => MailBox) private mailbox;

	struct Mail{
		uint256 id;
		string uri;
		uint256 transferBlock;
	}

	event Fee(address contract_, address indexed from, address indexed to, uint256 value);

	constructor(address creditsAddress, address launchpadAddress) ERC721("HashBox Mail", "MAIL"){
		credits = ERC20(creditsAddress);
		LAUNCHPAD_ADDRESS = launchpadAddress;
		mailFeeds = new MailFeeds();
	}

	function _mintMailBox(string calldata uri) private {
		MailBox storage mailbox_ = mailbox[msg.sender];
		require(bytes(uri).length > 0,"Inv. uri");
		require(mailbox_.id == 0,"Can't create");

		mailBoxId = mailBoxId + 1;
		mailBoxIdToAddress[mailBoxId] = msg.sender;
		mailbox_.id = mailBoxId;
		mailbox_.uri = uri;
	}

	function _mintMail(string calldata uri) private {
		MailBox storage mailbox_ = mailbox[msg.sender];
		require(bytes(uri).length > 0,"Inv. uri");
		require(mailbox_.id > 0,"No mailbox");

		mailId = mailId + 1;

		uint256 totalEmailsSent = mailbox_.totalEmailsSent + 1;
		Mail storage mail_ = mailbox_.mailSent[totalEmailsSent];
		mail_.id = mailId;
		mail_.uri = uri;
		mailbox_.totalEmailsSent = totalEmailsSent;

		_safeMint(msg.sender, mailId);
	}

	function tokenURI(uint256 _mailBoxId) public view override returns (string memory) {
		return mailbox[mailBoxIdToAddress[_mailBoxId]].uri;
	}

	function sendMail(address to, string calldata mailUri, uint256 customFee) external payable nonReentrant {
		_mintMail(mailUri);

		_antiSPAM(to, customFee, false);

		_updateTotalsAndSend(to, mailUri);

		_spendCredits(MIN_TOTAL_CREDITS);
	}

	function sendMail(address to, string calldata mailBoxUri, string calldata mailUri, uint256 customFee) external payable nonReentrant {
		_mintMailBox(mailBoxUri);

		_mintMail(mailUri);

		_antiSPAM(to, customFee, false);

		_updateTotalsAndSend(to, mailUri);
	}

	function sendMails(address[] calldata to, string[] calldata mailUri, uint256[] calldata customFees) external payable nonReentrant {
		uint256 length = to.length;
		for(uint i;i<length;){
			_mintMail(mailUri[i]);

			_antiSPAM(to[i], customFees[i], true);

			_updateTotalsAndSend(to[i], mailUri[i]);

			_spendCredits(MIN_TOTAL_CREDITS);

			unchecked{i++;}
		}
	}

	function sendFeed(address feedAddress, address[] calldata to, string[] calldata mailUri) external {
		(MailFeeds.MailFeed memory mailFeed,,,) = mailFeeds.getInfo(feedAddress, address(0), 0);
		require(mailFeed.owner == msg.sender, "Inv. caller");
		require(mailFeed.expiryTime >= block.timestamp, "Expired feed");

		Feed feed = Feed(feedAddress);
		uint256 length = to.length;

		for(uint i;i<length;){
			address user = to[i];

			(uint256 subscriberId,) = feed.getSubscriber(user, 0);
			(,Feed.Subscriber memory subscriber) = feed.getSubscriber(address(0), subscriberId);
			require(subscriber.expiryTime >= block.timestamp, "Expired subs.");
			require(!subscriber.isBlocked, "Blocked user");

			string calldata uri = mailUri[i];

			_mintMail(uri);

			_updateTotalsAndSend(user, uri);

			unchecked{i++;}
		}
	}

	function _antiSPAM(address to, uint256 customFee, bool isBatch) private {
		require(addressStatus[msg.sender][to] < BLOCKED,"Address blocked");

		MailBox storage mailboxTo = mailbox[to];
		address extensionAddress = mailboxTo.extensionAddress;
		uint256 fee = mailboxTo.fee;
		uint256 value = isBatch ? fee : msg.value;

		if((mailboxTo.isPaid && !freeMails[msg.sender][to]) ||
			(mailbox[msg.sender].totalSentTo[to] == 0 && mailboxTo.totalSentTo[msg.sender] == 0)){

			if(mailboxTo.extensionAddress != address(0)){
				require(customFee >= fee,"Fee below");
				IMailExtension extension = IMailExtension(extensionAddress);
				extension.antiSPAM{value: msg.value}(msg.sender, to, customFee);
			}
			else{
				require(msg.value >= fee,"Fee below");
				(bool sentEther,) = to.call{value: value}("");
				require(sentEther, "Failed");
			}
			addressStatus[msg.sender][to] = ALLOWED;
		}

		if(mailboxTo.extensionAddress != address(0)){
			emit Fee(extensionAddress, msg.sender, to, customFee);
		}
		else{
			emit Fee(address(0), msg.sender, to, value);
		}
	}

	function _updateTotalsAndSend(address to, string calldata uri) private {
		MailBox storage mailboxSender = mailbox[msg.sender];
		uint256 totalEmailsSent = mailboxSender.totalEmailsSent;
		Mail storage mailSent_ = mailboxSender.mailSent[totalEmailsSent];
		mailSent_.transferBlock = block.number;

		uint256 totalEmails = mailboxSender.totalEmails + 1;
		Mail storage allMail_ = mailboxSender.allMail[totalEmails];
		allMail_.id = mailId;
		allMail_.uri = uri;
		allMail_.transferBlock = block.number;
		mailboxSender.totalEmails = totalEmails;

		uint256 totalSentTo = mailboxSender.totalSentTo[to] + 1;
		mailboxSender.totalSentTo[to] = totalSentTo;

		bytes32 toIdHash = keccak256(abi.encode(to, totalSentTo));
		mailboxSender.sentTo[toIdHash] = totalEmailsSent;

		uint256 id = mailboxSender.mailSent[totalEmailsSent].id;
		_safeTransfer(msg.sender, to, id, "");

		MailBox storage mailboxReceiver = mailbox[to];
		uint256 totalEmailsReceived = mailboxReceiver.totalEmailsReceived + 1;
		mailboxReceiver.mailReceived[totalEmailsReceived].id = mailId;
		mailboxReceiver.mailReceived[totalEmailsReceived].uri = uri;
		mailboxReceiver.mailReceived[totalEmailsReceived].transferBlock = block.number;
		mailboxReceiver.totalEmailsReceived = totalEmailsReceived;
		mailReceivedIdsToIndexes[mailId] = totalEmailsReceived;

		totalEmails = mailboxReceiver.totalEmails + 1;
		mailboxReceiver.allMail[totalEmails].id = mailId;
		mailboxReceiver.allMail[totalEmails].uri = uri;
		mailboxReceiver.allMail[totalEmails].transferBlock = block.number;
		mailboxReceiver.totalEmails = totalEmails;
		mailAllMailIdsToIndexes[mailId] = totalEmails;
	}

	function _spendCredits(uint256 amount) private {
		require(credits.allowance(msg.sender, address(this)) >= amount, "No funds");
		credits.transferFrom(msg.sender, LAUNCHPAD_ADDRESS, amount);
	}

	function safeTransferFrom(address, address, uint256, bytes memory) public pure override(ERC721) {
		require(false,"Forbid");
	}

	function safeTransferFrom(address, address, uint256) public pure override(ERC721) {
		require(false,"Forbid");
	}

	function transferFrom(address, address, uint256) public pure override(ERC721) {
		require(false,"Forbid");
	}

	function burnMailBox() external {
		MailBox storage mailboxSender = mailbox[msg.sender];
		require(mailboxSender.id > 0,"No mailbox");

		uint256 totalEmailsReceived = mailboxSender.totalEmailsReceived + 1;
		for(uint i=1;i<totalEmailsReceived;){
			burnMail(mailboxSender.mailReceived[i].id);
			unchecked{i++;}
		}

		mailboxSender.id = 0;
		mailboxSender.uri = "";
		mailboxSender.fee = 0;
		mailboxSender.isPaid = false;
		mailboxSender.extensionAddress = address(0);
		mailboxSender.totalEmailsReceived = 0;
		mailboxSender.totalEmailsSent = 0;
		mailboxSender.totalEmails = 0;
		mailboxSender.totalBurned = 0;
		mailboxSender.totalBlockedUsers = 0;
		mailboxSender.totalRemovedBlock = 0;
	}

	function burnMails(uint256[] calldata ids) external {
		require(mailbox[msg.sender].id > 0,"No mailbox");

		uint256 length = ids.length;
		for(uint i=0;i<length;){
			burnMail(ids[i]);
			unchecked{i++;}
		}
	}

	function burnMail(uint256 mailId_) public {
		if(_exists(mailId_) && ownerOf(mailId_) == msg.sender){
			MailBox storage mailbox_ = mailbox[msg.sender];
			uint256 totalBurned = mailbox_.totalBurned;
			string memory uri_;

			uint256 index = mailReceivedIdsToIndexes[mailId_];
			Mail storage mail = mailbox_.mailReceived[index];
			uri_ = mail.uri;
			mail.id = 0;
			mail.uri = "";
			mail.transferBlock = block.number;

			index = mailAllMailIdsToIndexes[mailId_];
			mail = mailbox_.allMail[index];
			mail.id = 0;
			mail.uri = "";
			mail.transferBlock = block.number;

			_burn(mailId_);

			uint256 idBurned = totalBurned + 1;
			mailbox_.mailBurned[idBurned].id = mailId_;
			mailbox_.mailBurned[idBurned].uri = uri_;
			mailbox_.mailBurned[idBurned].transferBlock = block.number;
			mailbox_.totalBurned = idBurned;
		}
	}

	function getMailBoxInfo(address userAddress) external view returns (uint256, string memory, uint256, bool, uint256, uint256, uint256) {
		return (mailbox[userAddress].id, mailbox[userAddress].uri, mailbox[userAddress].fee, mailbox[userAddress].isPaid,
		mailBoxId, mailbox[userAddress].totalBlockedUsers, mailbox[userAddress].totalRemovedBlock);
	}

	function getMailInfo(address userAddress, uint256 id, uint8 type_) external view returns (uint256, uint256, string memory, uint256, uint256, uint256, uint256, uint256, uint256) {
		MailBox storage mailBox = mailbox[userAddress];
		Mail storage mail = mailBox.mailReceived[id];

		if(type_ == LIST_SENT){
			mail = mailBox.mailSent[id];
		}
		else if(type_ == LIST_ALL_MAIL){
			mail = mailBox.allMail[id];
		}
		else if(type_ == LIST_TRASH){
			mail = mailBox.mailBurned[id];
		}

		return (mailBox.totalEmails, mail.id, mail.uri, mail.transferBlock, mailId,
		mailBox.totalEmailsReceived, mailBox.totalBurned, mailBox.totalSubscriptions,
		mailBox.totalUnsubscriptions);
	}

	function getMails(address userAddress, uint256 fromId, uint256 length, uint8 type_) external view returns (uint256[] memory, string[] memory, uint256[] memory) {
		uint256[] memory ids = new uint256[](length);
		string[] memory uris = new string[](length);
		uint256[] memory blocks = new uint256[](length);
		MailBox storage mailbox_ = mailbox[userAddress];
		uint256 id;

		for(uint i=fromId;i>=1;){
			Mail storage mail = mailbox_.mailReceived[i];
			if(type_ == LIST_SENT){
				mail = mailbox_.mailSent[i];
			}
			else if(type_ == LIST_ALL_MAIL){
				mail = mailbox_.allMail[i];
			}
			else if(type_ == LIST_TRASH){
				mail = mailbox_.mailBurned[i];
			}

			if(mail.id > 0){
				ids[id] = i;
				uris[id] = mail.uri;
				blocks[id] = mail.transferBlock;
				id++;

				if(id == length){
					break;
				}
			}
			unchecked{i--;}
		}

		return (ids, uris, blocks);
	}

	function getAddresses(address userAddress, uint256 fromId, uint256 length, uint8 type_) external view returns (address[] memory) {
		address[] memory addresses = new address[](length);
		MailBox storage mailBox = mailbox[userAddress];
		uint256 id;

		uint256 total = mailBox.totalBlockedUsers;
		if(type_ == LIST_SUBSCRIPTIONS){
			total = mailBox.totalSubscriptions;
		}

		for(uint i=fromId;i<total;){
			address addr_ = mailBox.blockedUsers[i];
			if(type_ == LIST_SUBSCRIPTIONS){
				addr_ = mailBox.subscription[userAddress][i];
			}

			if(addr_ != address(0)){
				addresses[id] = addr_;
				id++;

				if(id == length){
					break;
				}
			}
			unchecked{i++;}
		}

		return addresses;
	}

	function getFromToInfo(address from, address to, uint256 fromId, uint256 length) external view returns (uint256, uint256[] memory, bool, bool) {
		uint256 totalSentTo = mailbox[from].totalSentTo[to];
		uint256[] memory ids = new uint256[](length);
		uint256 id;

		for(uint i=fromId;i>=1;){
			uint256 _mailId = mailbox[from].sentTo[keccak256(abi.encode(to, i))];

			if(_mailId > 0){
				ids[id] = _mailId;
				id++;

				if(id == length){
					break;
				}
			}
			unchecked{i--;}
		}

		uint8 status = addressStatus[from][to];
		bool isFreeMail = freeMails[from][to];
		return (totalSentTo, ids, isFreeMail, status == BLOCKED);
	}

	function blockUsers(address[] calldata users, bool[] calldata blocks) external {
		uint256 length = users.length;
		for(uint i;i<length;){
			address user = users[i];
			bool isBlock = blocks[i];
			uint8 status = addressStatus[user][msg.sender];

			if((isBlock && status != BLOCKED) || (!isBlock && status != ALLOWED)){
				addressStatus[user][msg.sender] = isBlock ? BLOCKED : ALLOWED;
				MailBox storage mailBox = mailbox[msg.sender];
				uint256 totalBlockedUsers = mailBox.totalBlockedUsers;

				if(isBlock){
					mailBox.blockedUsers[totalBlockedUsers] = user;
					mailBox.totalBlockedUsers = totalBlockedUsers + 1;
					blockedAddressesToIndexes[user] = totalBlockedUsers;
				}
				else{
					uint256 index = blockedAddressesToIndexes[user];
					mailBox.blockedUsers[index] = address(0);
					mailBox.totalRemovedBlock = mailBox.totalRemovedBlock + 1;
				}

				unchecked{i++;}
			}
		}
	}

	function createMailFeed(string[2] calldata args, uint256 timeInSecs, address extensionAddress, uint256 price, uint256 maxNumberSubscribers) external {
		Feed feed = new Feed(address(this), msg.sender, timeInSecs, extensionAddress, price, maxNumberSubscribers);
		address feedAddress = address(feed);

		mailFeeds.createMailFeed(msg.sender, feedAddress, args);
		_spendCredits(MAIL_FEED_PRICE);
	}

	function renewMailFeeds(address[] calldata feedAddresses) external {
		mailFeeds.renewMailFeeds(msg.sender, feedAddresses);
		_spendCredits(MAIL_FEED_PRICE);
	}

	function addSubscription(address subscriberAddress) external virtual {
		(MailFeeds.MailFeed memory mailFeed,,,) = mailFeeds.getInfo(msg.sender, address(0), 0);
		require(mailFeed.owner != address(0), "Inv. caller");

		MailBox storage mailbox_ = mailbox[subscriberAddress];
		uint256 total = mailbox_.totalSubscriptions;
		mailbox_.subscription[subscriberAddress][total] = msg.sender;
		mailbox_.totalSubscriptions = total + 1;
		subscriptionsAddressesToIndexes[msg.sender] = total;
	}

	function removeSubscription(address subscriberAddress) external virtual {
		(MailFeeds.MailFeed memory mailFeed,,,) = mailFeeds.getInfo(msg.sender, address(0), 0);
		require(mailFeed.owner != address(0), "Inv. caller");

		MailBox storage mailbox_ = mailbox[subscriberAddress];
		mapping(uint256 => address) storage subscriptions = mailbox_.subscription[subscriberAddress];

		uint256 index = subscriptionsAddressesToIndexes[msg.sender];
		subscriptions[index] = address(0);

		mailbox_.totalUnsubscriptions = mailbox_.totalUnsubscriptions + 1;
	}

	function getMailFeedsAddress() external view returns(address){
		return address(mailFeeds);
	}

	function setFee(address extensionAddress, uint256 fee, bool isAlwaysPaid, address from, bool free) external {
		CheckMailExtension.check(extensionAddress);
		mailbox[msg.sender].extensionAddress = extensionAddress;
		mailbox[msg.sender].fee = fee;
		mailbox[msg.sender].isPaid = isAlwaysPaid;
		freeMails[from][msg.sender] = free;
	}

	function getExtensionInfo(address user) external view returns (address){
		return (mailbox[user].extensionAddress);
	}

	function addContact(address contactsAddress, string[5] calldata args) external {
		Contacts(contactsAddress).addContact(msg.sender, args);
		_spendCredits(CONTACTS_PRICE);
	}

	function getPrices() external pure returns(uint80, uint64){
		return (MAIL_FEED_PRICE, CONTACTS_PRICE);
	}
}