/**
 *Submitted for verification at polygonscan.com on 2022-08-16
*/

// SPDX-License-Identifier: GPL-3.0

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



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



// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol



pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol



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

// File: @openzeppelin/contracts/utils/Strings.sol



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

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol



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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol



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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File: @openzeppelin/contracts/utils/Context.sol



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
// File: @openzeppelin/contracts/token/ERC721/ERC721.sol



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

    // modifier used for checking if interactor is the owner of the token
    modifier ownerOfTokenId(uint256 _tokenId) {
        require(_msgSender() == ownerOf(_tokenId), "Ownable: You don't own this token");
        _;
    }

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
        require(operator != _msgSender(), "ERC721: approve to caller");

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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
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
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol



pragma solidity ^0.8.0;



/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}



// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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

// File: contracts/Polygon Test.sol

// Contains helper functions
pragma solidity ^0.8.0;

contract Helpers {

    // random number function
    function random(uint number) internal view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        msg.sender))) % number;
    }

    function chainStrings(string memory a, string memory b, string memory c, string memory d, string memory e) internal pure returns (string memory) {
    return string(abi.encodePacked(a, b, c, d, e));
    }
}


/**
Tamagotchi 3.0
*/
pragma solidity ^0.8.0;

 // Game Logic -----------------------------------
  contract TamagoPet is Helpers {

    constructor(string memory _name) {
        petName = _name;
    }

  // Usually called after hatch has occured, starts the pet's timers and resets all values to max
  // TO-DO sickness timer didn't reset - health didnt reset
  function resetAllStatsAndTimers() public {
    // Depletion timers
    foodDepletionTimerStart = block.timestamp;
    energyDepletionTimerStart = block.timestamp;
    funDepletionTimerStart = block.timestamp;
    intellectDepletionTimerStart = block.timestamp;
    cleanlinessDepletionTimerStart = block.timestamp;
    randomizedSickTimerEnd = block.timestamp + getRandomInterval() * 2;

    lastInteractionTimer = block.timestamp;

    ageTimerStart = block.timestamp;

    // Default Stats
    defHunger = maxStatValue; // when hunger is low, the monster is hungry
    defEnergy = maxStatValue;
    defFun = maxStatValue;
    defIntellect = maxStatValue;
    defHealth = maxStatValue;
    defCleanliness = maxStatValue;
    defAge = 0;
    xp = 0;
    defLevel = 1;
    xpPerLevel = 100;
  }
    // Stat depletion timers - defaulted to block.timestamp but now using test randomized timer
  uint256 foodDepletionTimerStart = block.timestamp;
  uint256 energyDepletionTimerStart = block.timestamp;
  uint256 funDepletionTimerStart = block.timestamp;
  uint256 intellectDepletionTimerStart = block.timestamp;
  uint256 cleanlinessDepletionTimerStart = block.timestamp;
  uint256 lastInteractionTimer = block.timestamp;

  // Age timer
  uint256 ageTimerStart = block.timestamp; //! needs to be changed when egg hatches

  //uint256 testIntervalSeconds = 15;

  uint256 foodDepletionInterval = getRandomInterval();
  uint256 energyDepletionInterval = getRandomInterval();
  uint256 funDepletionInterval = getRandomInterval();
  uint256 intellectDepletionInterval = getRandomInterval();
  uint256 cleanlinessDepletionInterval = getRandomInterval();
  
  function getRandomInterval() private view returns(uint256){
    return getRandomIntervalTesting();
    //return (random(8) * 1 hours) + 4 hours;
  }

// for testing purposes only
  function getRandomIntervalTesting() private view returns(uint256){
      return (random(8) * 1 minutes) + 4 minutes;
  }

  // Perpetually declining/increasing stat data
  function hungerToSub() public view returns(uint256){
    uint256 res = (block.timestamp - foodDepletionTimerStart) / foodDepletionInterval;
    if(res > maxStatValue){
        res = maxStatValue;
    }
    return res;
  }

   function energyToSub() public view returns(uint256){
    uint256 res = (block.timestamp - energyDepletionTimerStart) / energyDepletionInterval;

    if(res > maxStatValue){
        res = maxStatValue;
    }
    return res;
  }

  function funToSub() public view returns(uint256){
    uint256 res = (block.timestamp - funDepletionTimerStart) / funDepletionInterval;

    if(res > maxStatValue){
        res = maxStatValue;
    }
    return res;
  }

  function intellectToSub() public view returns(uint256){
    // TO-DO fix all subtraction values to not exceed maxStatValue
    // No more than maxStatValue because we don't want negative values
    uint256 res = (block.timestamp - intellectDepletionTimerStart) / intellectDepletionInterval;

    if(res > maxStatValue){
        res = maxStatValue;
    }
    return res;
  }

  function cleanlinessToSub() public view returns(uint256){
    uint256 res = (block.timestamp - cleanlinessDepletionTimerStart) / cleanlinessDepletionInterval;

    if(res > maxStatValue){
        res = maxStatValue;
    }
    return res;
  }

  // It gets regenerated when you heal the pet, it stays out so it doesn't keep generating random values every time we call healthToSub
  uint256 _healthToSubRandom = getHealthToSubRandomValue();
  function getHealthToSubRandomValue() private view returns (uint256){
      return random(7) + 2;
  }
  function healthToSub() private view returns(uint256){
      uint256 res = 0;
      if(block.timestamp >= randomizedSickTimerEnd){
            res = _healthToSubRandom;
      }
      return res;
  }

  function ageToAdd() private view returns(uint256){
      return (block.timestamp - ageTimerStart) / 180 days; // every 180 days default (approx 6 months, the monster will age with 1)
  }

  function xpToAdd() private view returns(uint256){
      uint256 res = defXpToAdd;
      if(isInPeakCondition()){
          res *= 2;
      }
      return res;
  }

  // Call Stats - not modifying state - these return an error and revert txn when if statement is below 0
  function hunger() public view returns(uint256){
      return defHunger - hungerToSub();
  }

   function energy() public view returns(uint256){
      return defEnergy - energyToSub();
  }

    function fun() public view returns(uint256){
      return defFun - funToSub();
  }

   function intellect() public view returns(uint256){
      return defIntellect - intellectToSub();
  }

  function cleanliness() public view returns(uint256){
      return defCleanliness - cleanlinessToSub();
  }

  function health() public view returns(uint256){
      return defHealth - healthToSub();
  }


   function age() public view returns(uint256){
      return defAge + ageToAdd();
  }

  // Constants
  uint256 constant bareCondition = 2;
  uint256 constant peakCondition = 7;
  uint256 constant defXpToAdd = 12;
  uint256 constant maxStatValue = 10;
  uint256 constant minStatValue = 0;

  // Default Stats
  uint256 defHunger = 10; // when hunger is low, the monster is hungry
  uint256 defEnergy = 10;
  uint256 defFun = 10;
  uint256 defIntellect = 10;
  uint256 defHealth = 10;
  uint256 defCleanliness = 10;

  // Major traits
  // Pet Name
  string petName; //set on mint, can change via payable function

  function getName() public view returns(string memory){
      return petName;
  }

  function changeName(string memory _newName) public {
      petName = _newName;
  }

  uint256 defAge = 0;
  uint256 public xp = 0; // 12 xp per action, 24 when in peak condition
  uint256 defLevel = 1;
  uint256 xpPerLevel = 100;
  
  //uint256 xpMultiplierPerLevel = 1; // multiples of 3 until 30

  function addToXP(uint _xp) public {
      xp += _xp; //xpToAdd(); // add the xp from interaction
      lastInteractionTimer = block.timestamp; // reset last interaction timer used for death event
  }

  function addToXpFun(uint _percentage) public {
      xp += (xpToAdd() * 2) + (xpToAdd() * (_percentage/100)); // double default xp + defaultXp * percentage score in game
      lastInteractionTimer = block.timestamp; // reset last interaction timer used for death event
  }

  function getLevel() public view returns(uint256){
      uint256 res = 1;

      if(xp >= 100 && xp < 400){ //1 - 2 = 100
          res = 2;
      }else if(xp >= 400 && xp < 1000){ //2-3 = 300
          res = 3;
      }else if(xp >= 1000 && xp < 1900){ //3-4 = 600
          res = 4;
      }else if(xp >= 1900 && xp < 3100){ //4-5 = 900
          res = 5;
      }else if(xp >= 3100 && xp < 4600){ //5-6 = 1200
          res = 6;
      }else if(xp >= 4600 && xp < 6400){ //6-7 = 1500
          res = 7;
      }else if(xp >= 6400 && xp < 8500){ //7-8 = 1800
          res = 8;
      }else if(xp >= 8500 && xp < 10900){ //8-9 = 2100
          res = 9;
      }else if(xp >= 10900 && xp < 13600){ //9-10 = 2400
          res = 10;
      }else if(xp >= 13600){ //10-11 = 2700
          // calculate based 
          res = 11 + ((xp - 13600) / 3000); //11-XX = 3000
      }
      
      return res;
  }

  function xpMultiplierPerLevel() public view returns(uint256){
      uint256 res = 1;
      if(getLevel() > 1 && getLevel() <= 10){
          res = (getLevel() - 1) * 3;
      } else if(getLevel() > 10){
          res = 30;
      }

      return res;
  }

  // Debug START, remove from release
  //function setLevel(uint256 newLevel) public onlyOwner {
  //    defLevel = newLevel;
  //}

  //function setXP(uint256 newXP) public onlyOwner {
  //    xp = newXP;
  //}

  // Debug END ^^^^^^^^^


  // Monster condition
  function isInBareCondition() public view returns (bool){
    if(hunger() >= bareCondition && energy() >= bareCondition && health() >= bareCondition){
      return true;
    }

    return false;
  }

    function isInPeakCondition() public view returns (bool){
    if(hunger() >= peakCondition && energy() >= peakCondition && health() >= peakCondition
        && fun() >= peakCondition && intellect() >= peakCondition && cleanliness() >= peakCondition){
      return true;
    }

    return false;
  }

// Death Count & Death - not in World First edition
  //uint256 deathCount;
  //function getDeathCount() public view returns (uint){
   //   uint256 res = deathCount;
      // Show death count 1 if birb isDead right now
    //if(isDead()){
    //    res += 1;
    //}
    //return res;
  //}

  //function setDeathCount(uint _newDeathCount) public {
  //    deathCount = _newDeathCount;
  //}

  //function isDead() public view returns(bool){
  //    if(hasHatched() == true && hunger() == 0 && fun() == 0 && energy() == 0 && cleanliness() == 0 && health() < maxStatValue && block.timestamp > lastInteractionTimer + 1 minutes){// 90 days){
  //        return true;
  //    }

  //    return false;
  //}

  // Action Timers in hours
  uint8 constant smallActionTimerDuration = 12;
  uint8 constant bigActionTimerDuration = 24;

  // Caring actions

  // Feed action
  // DEBUG ONLY function, remove
  //function hungerCalculatedNegative() public view returns(int256){
  //    return int256(defHunger) - int256(hungerToSub());
  //}
  //int256 public hungerCalculatedNegative = (int256)defHunger - (int256)hungerToSub();
  uint8 constant defStatToAddValue = 2;
  
    function perPetMultiStat(uint _hunger, uint _happiness, uint _energy, uint _intellect, uint _health, uint _cleanliness) public {
        // reset stats after setting them because we're setting them directly
        if(_hunger > 0){
            if(_hunger > maxStatValue){
                _hunger = maxStatValue;
            }
            // multiply the xp by the difference between old stat and new stat
            addToXP(xpToAdd()*(_hunger - hunger()));
            defHunger = _hunger;
            foodDepletionTimerStart = block.timestamp;
        }

        if(_happiness > 0){
            if(_happiness > maxStatValue){
                _happiness = maxStatValue;
            }
            // multiply the xp by the difference between old stat and new stat
            addToXP(xpToAdd()*(_happiness - fun()));
            defFun = _happiness;
            funDepletionTimerStart = block.timestamp;
        }

        if(_energy > 0){
            if(_energy > maxStatValue){
                _energy = maxStatValue;
            }
            // multiply the xp by the difference between old stat and new stat
            addToXP(xpToAdd()*(_energy - energy()));
            defEnergy = _energy;
            sleepingTimerStart = block.timestamp;
            energyDepletionTimerStart = block.timestamp; // reset the timer
        }

        if(_intellect > 0){
            if(_intellect > maxStatValue){
                _intellect = maxStatValue;
            }
            // multiply the xp by the difference between old stat and new stat
            addToXP(xpToAdd()*(_intellect - intellect()));
            defIntellect = _intellect;
            intellectDepletionTimerStart = block.timestamp;
        }

        if(_health > 0){
            if(_health > maxStatValue){
                _health = maxStatValue;
            }
            // multiply the xp by the difference between old stat and new stat
            addToXP(xpToAdd()*(_health - health()));
            defHealth = _health;
            _healthToSubRandom = getHealthToSubRandomValue(); //randomize value for next sickness
            randomizedSickTimerEnd = block.timestamp + getRandomInterval() * 2;
        }

        if(_cleanliness > 0){
            if(_cleanliness > maxStatValue){
                _cleanliness = maxStatValue;
            }
            // multiply the xp by the difference between old stat and new stat
            addToXP(xpToAdd()*(_cleanliness - cleanliness()));
            defCleanliness = _cleanliness;
            cleanlinessDepletionTimerStart = block.timestamp;
        }
    }

  // Sleep
  uint256 sleepingTimerStart;
  
  function isSleeping() public view returns(bool){
      bool res = false;
      if(sleepingTimerStart != 0 && block.timestamp < sleepingTimerStart + 1 minutes){
          res = true;
      }
      return res;
  }

  // Play -- handled in-game along with Pet function

  // Heal
  //uint256 randomizedSickTimerStart = block.timestamp;
  uint256 randomizedSickTimerEnd = block.timestamp + getRandomInterval() * 2;
  //uint256 randomizedSickTimerEnd = block.timestamp + random(120) + 300;

  function isSick() public view returns(bool){
      bool res = false;
      if(healthToSub() > 0){
          res = true;
      }

      return res;
  }

  // Hatching
  // hasHatched is set to false after reviving a dead birb and on mint
  bool _hasHatched;
  function hasHatched() public view returns(bool){
      return _hasHatched;
  }

  function setHasHatched(bool _hh) public {

      if(_hh == true){
          resetAllStatsAndTimers();
      }
      _hasHatched = _hh;
  }

  // TO-DO: Implement hatchDay - like birthday
}


pragma solidity ^0.8.0;

contract Tamago3 is ERC721Enumerable, Ownable, Helpers {
  using Strings for uint256;

  string public baseURI = "https://birbz.pet/world-first-meta/";
  string public baseExtension = ".json";
  uint256 public cost = 0.01 * 10**18; //0.01 matic, for test purpose, default to 100000000000000000000 (100 matic)
  uint256 public costWL = 0.05 * 10**18; //0.01 matic, for test purpose, default to 100000000000000000000 (100 matic)
  uint256 public nameChangeCost = 20 * 10**18; //0.01 matic, for test purpose, default to 100000000000000000000 (100 matic)
  uint256 public maxSupply = 2222;
  uint256 public maxMintAmount = 50;
  // Hatch date for release only, if it's 0 there will be no hatch delay (normal hatch is tapping on the egg in game and it hatches)
  uint256 public mintHatchDate = 0;
  uint32 version = 1; //version of smart contract for upgrade checking, increment by 1 manually
  bool public paused = false;
  mapping(address => bool) public whitelisted;
  mapping(address => bool) public freeminted;
  // map the id of the NFT to the TamagoPet so we can call functions on it
  mapping(uint => TamagoPet) public petAtID;

  constructor(
    string memory _name,
    string memory _symbol
    //string memory _initBaseURI
  ) 
  
  ERC721(_name, _symbol) {
    setBaseURI(baseURI);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  

  // public main mint function
  function mint(address _to, string memory _petName) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(supply + 1 <= maxSupply);

    if(freeminted[msg.sender] == false){
        if (msg.sender != owner()) {
            if(whitelisted[msg.sender] != true) {
                require(msg.value >= cost); //normal cost if not whitelisted
            }else{
                require(msg.value >= costWL); //whitelisted cost
                // remove whitelist price
                whitelisted[msg.sender] = false;
            }
        }
    }else{
        // remove the free mint after using it once
        freeminted[msg.sender] = false;
    }

    TamagoPet newPet = new TamagoPet(_petName);
    petAtID[supply + 1] = newPet;
    _safeMint(_to, supply + 1);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }
  
  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }
  
  
  /**
   * @dev Returns an URI for a given token ID
   */
   /*
  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    return string(abi.encodePacked(_baseURI(), _tokenId.toString(), baseExtension));
  }*/

   // Hatching
   // canHatch is true when mint period has ended and all birbz are to be revealed
  function canHatch() public view returns(bool){
      if(mintHatchDate != 0 && block.timestamp >= mintHatchDate){
          return true;
      } 

      return false;
  }

  //only owner
  function setMintHatchDate(uint256 _newDate) public onlyOwner() {
    mintHatchDate = _newDate;
  }

  function setMintHatchDateToNow() public onlyOwner() {
    mintHatchDate = block.timestamp;
  }

  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }

  function setNameChangeCost(uint256 _newCost) public onlyOwner() {
    nameChangeCost = _newCost;
  }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner() {
    maxSupply = _newMaxSupply;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
 function whitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = true;
  }

  function removeWhitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = false;
  }

  function whitelistUserArray(address[] memory _users) public onlyOwner {
    for(uint i = 0; i < _users.length; i++){
        whitelisted[_users[i]] = true;
      }
  }

  function removeWhitelistUserArray(address[] memory _users) public onlyOwner {
    for(uint i = 0; i < _users.length; i++){
        whitelisted[_users[i]] = false;
      }
  }
// Free mint users

     function freeMintUser(address _user) public onlyOwner {
    freeminted[_user] = true;
  }

  function removeFreeMintUser(address _user) public onlyOwner {
    freeminted[_user] = false;
  }

    function freeMintUserArray(address[] memory _users) public onlyOwner {
    for(uint i = 0; i < _users.length; i++){
        freeminted[_users[i]] = true;
      }
  }

  function removeFreeMintUserArray(address[] memory _users) public onlyOwner {
    for(uint i = 0; i < _users.length; i++){
        freeminted[_users[i]] = false;
      }
  }

    function withdraw() public onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawAlt() public payable onlyOwner {
    payable(msg.sender).call{ value: address(this).balance };
}

  // GAME FUNCTIONS
  // Paid functions (shouldn't be executed too often)
  // TO-DO: Limit name to certain char length! No more than 9 for example. Also revisit any other user inputs and see if they can be abused
  function changeName(uint petID, string memory _petName) public payable ownerOfTokenId(petID) {
    require(msg.value >= cost);
    petAtID[petID].changeName(_petName);
  }

  // Pet Interactions per ID -- Public
    // new function to minimize constant interaction
    function setMultiStat(uint petID, uint _hunger, uint _happiness, uint _energy, uint _intellect, uint _health, uint _cleanliness) public ownerOfTokenId(petID) returns (bool){
        petAtID[petID].perPetMultiStat(_hunger, _happiness, _energy, _intellect, _health, _cleanliness);
        return true;
    }

  function hatchPet(uint petID) public ownerOfTokenId(petID) returns (bool){
    require(canHatch() == true, "Can't hatch yet! Please be patient");
    require(petAtID[petID].hasHatched() == false, "Pet already hatched");
    //require(petAtID[petID].isDead() == false, "Can't hatch, revive your pet first");
    petAtID[petID].setHasHatched(true);
    return true;
  }

  // Pet traits
  function getName(uint petID) public view returns (string memory){
    return petAtID[petID].getName();
  }

  function getAge(uint petID) public view returns (uint256){
    return petAtID[petID].age();
  }

  function getXP(uint petID) public view returns (uint256){
    return petAtID[petID].xp();
  }

  function getLevel(uint petID) public view returns (uint256){
    return petAtID[petID].getLevel();
  }

  // Pet main stats
  function getHunger(uint petID) public view returns (uint256){
    return petAtID[petID].hunger();
  }

  function getHappiness(uint petID) public view returns (uint256){
    return petAtID[petID].fun();
  }

  function getEnergy(uint petID) public view returns (uint256){
    return petAtID[petID].energy();
  }

  function getIntellect(uint petID) public view returns (uint256){
    return petAtID[petID].intellect();
  }

  function getHealth(uint petID) public view returns (uint256){
    return petAtID[petID].health();
  }

  function getCleanliness(uint petID) public view returns (uint256){
    return petAtID[petID].cleanliness();
  }

  // Pet condition stats
  function isInBareCondition(uint petID) public view returns (bool){
    return petAtID[petID].isInBareCondition();
  }

  function isInPeakCondition(uint petID) public view returns (bool){
    return petAtID[petID].isInPeakCondition();
  }

  function isSick(uint petID) public view returns (bool){
    return petAtID[petID].isSick();
  }

  function isSleeping(uint petID) public view returns (bool){
    return petAtID[petID].isSleeping();
  }

  //function isDead(uint petID) public view returns (bool){
  //  return petAtID[petID].isDead();
  //}

  function hasHatched(uint petID) public view returns(bool){
      return petAtID[petID].hasHatched();
  }

  //function getDeathCount(uint petID) public view returns(uint256){
  //    return petAtID[petID].getDeathCount();
  //}

  //function revive(uint petID) public {
  //    require(petAtID[petID].isDead(), "Your pet isn't dead");
  //
  //    string memory _name = petAtID[petID].getName();
  //    uint _deathCount = petAtID[petID].getDeathCount();
  //    petAtID[petID] = new TamagoPet(_name);
  //    petAtID[petID].setDeathCount(_deathCount);
  //}
}