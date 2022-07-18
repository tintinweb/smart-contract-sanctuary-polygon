/**
 *Submitted for verification at polygonscan.com on 2022-07-18
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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

// File: BowlBound.sol


pragma solidity 0.8.15;



contract BowlBound is ERC721, Ownable {

    string URI = "https://api.nftbackend.io/thebluechips/";

    address public oracle = 0xE8cF9826C7702411bb916c447D759E0E631d2e68;

    modifier onlyOracle {
        require(msg.sender == oracle, "Caller not oracle");
        _;
    }

    constructor() ERC721("BowlBound", "BBOUND") {
        // Snapshot on July 18th, 2022
        _mint(0xE5b33F7f6D417d78f38274D1f06B7BFB3342Bf65, 1);
        _mint(0x129345d959ae69C45569A0aA2Bc792518704e2d9, 2);
        _mint(0x781E0bc357252372A9444cD32A6F8cB7f6540C90, 3);
        _mint(0xaCDa2baBFB23f495f7cC0688F15134fB3129898F, 4);
        _mint(0xaCDa2baBFB23f495f7cC0688F15134fB3129898F, 5);
        _mint(0x6fA65eB67D7570d172221d8f7E63865223ee0900, 6);
        _mint(0xD18f71fEcc85503e0ced8Db7bFDA361D8DBe8955, 7);
        _mint(0xd5B3988eD0AB5ec375E51bB6fd10e205cEC16A2E, 8);
        _mint(0x8A56b8Aaf54A4824E3CA0dea8Ee56397260e3882, 9);
        _mint(0x13e0d0A9e4024F1804FA2a0dde4F7c38abCc63F7, 10);
        _mint(0xDd2c7FA74BBB4Bf01E2a956Ad36A223c6BE4CB8C, 11);
        _mint(0x13e0d0A9e4024F1804FA2a0dde4F7c38abCc63F7, 12);
        _mint(0x657D475a99487F7D133ACd1C295F5Bc5013e4eBc, 13);
        _mint(0x0fa1C11206e86d9317e69bE4B094b7571166993c, 14);
        _mint(0xB0e8f66E4Ce09C0C108BC96fA47BeB2041b7dD2b, 15);
        _mint(0xB0e8f66E4Ce09C0C108BC96fA47BeB2041b7dD2b, 16);
        _mint(0xB0e8f66E4Ce09C0C108BC96fA47BeB2041b7dD2b, 17);
        _mint(0xB0e8f66E4Ce09C0C108BC96fA47BeB2041b7dD2b, 18);
        _mint(0xA8e54b46ae93E14eedaE486a9EFCD4c7B5a5be20, 19);
        _mint(0xA8e54b46ae93E14eedaE486a9EFCD4c7B5a5be20, 20);
        _mint(0x68b7423Db14d2b5b9D6F8927356e489669E58Ea2, 21);
        _mint(0xfc87aDbc49931702544431f510163344Fe9b57A2, 22);
        _mint(0xfc87aDbc49931702544431f510163344Fe9b57A2, 23);
        _mint(0xf6d1B70718596F14870079dCc7da881C753563F5, 24);
        _mint(0xf6d1B70718596F14870079dCc7da881C753563F5, 25);
        _mint(0xffe0DeDa3816B62FFc8F5ABe690235C027c13E7d, 26);
        _mint(0x6fA65eB67D7570d172221d8f7E63865223ee0900, 27);
        _mint(0x54762Ceb647B974dc111CaEB4072FA020314bbc9, 28);
        _mint(0x0BF988a6cc20af0CDD6f583aD2Fcf057895888e6, 29);
        _mint(0x0BF988a6cc20af0CDD6f583aD2Fcf057895888e6, 30);
        _mint(0x96706EB471F875a9a41442f358d3B34ba02F868b, 31);
        _mint(0xBeae36aEfD7Ae78Ac1d59981bD2969d84Eb5430c, 32);
        _mint(0x4F8d175C24Ad7064882C5BBd1831F8188daa780c, 33);
        _mint(0xDa81a57188006FeAC8711B046b28A79Ea202E999, 34);
        _mint(0xDa81a57188006FeAC8711B046b28A79Ea202E999, 35);
        _mint(0x10eC3e9F9CFBAD272e7596dfFbC3466a6Ae6e225, 36);
        _mint(0x001292F42F0eC85636f652F618fEFD94bcC3ac6E, 37);
        _mint(0xac194A46D6D61B362C58ef689412dd4aEeb68f5C, 38);
        _mint(0xffe0DeDa3816B62FFc8F5ABe690235C027c13E7d, 39);
        _mint(0xffe0DeDa3816B62FFc8F5ABe690235C027c13E7d, 40);
        _mint(0x1d7F4bA2997D644d21195aaDA3F2f85F24330e6d, 41);
        _mint(0x1d7F4bA2997D644d21195aaDA3F2f85F24330e6d, 42);
        _mint(0x2a6FCCB6b2CF000128609A97004172bed81278eF, 43);
        _mint(0x2a6FCCB6b2CF000128609A97004172bed81278eF, 44);
        _mint(0x31e89Be0C67C100BFdb7FaAcdd53C5481887050C, 45);
        _mint(0x76186ca250Bef65522561a0b9fF51D4ee5608932, 46);
        _mint(0x7f368c261873FA8B874eD27E5e39C11DFBe25eff, 47);
        _mint(0xeE9A0bbD2cE67fc008fE3f7f6a86F2c6dA5F7a65, 48);
        _mint(0x139776871Ee95f55d20b10d9Ba5a0385451066cd, 49);
        _mint(0xCbbd18d3aC27ab0FFfD04BCCd091B2802c92e0ca, 50);
        _mint(0x467020116c012a3d777f04b4Fb72FedE0d31FB07, 51);
        _mint(0xBeae36aEfD7Ae78Ac1d59981bD2969d84Eb5430c, 52);
        _mint(0x1C32305A7833570fC13e0eE6D0614864412dFb1A, 53);
        _mint(0x7aa7a54D58C8b2F2a8559301C880d3cEd10B7e55, 54);
        _mint(0x7aa7a54D58C8b2F2a8559301C880d3cEd10B7e55, 55);
        _mint(0x76B687cF4E5a4e73Fa3950D6cC642bCC64e40B88, 56);
        _mint(0x76B687cF4E5a4e73Fa3950D6cC642bCC64e40B88, 57);
        _mint(0x76B687cF4E5a4e73Fa3950D6cC642bCC64e40B88, 58);
        _mint(0x76B687cF4E5a4e73Fa3950D6cC642bCC64e40B88, 59);
        _mint(0x76B687cF4E5a4e73Fa3950D6cC642bCC64e40B88, 60);
        _mint(0xE58B7265d56c4a1465Ca44357D33c240D0CEF6ca, 61);
        _mint(0xE58B7265d56c4a1465Ca44357D33c240D0CEF6ca, 62);
        _mint(0x14ae8100Ea85a11bbb36578f83AB1b5C1cFDd61c, 63);
        _mint(0xE859d127b7e68E1C8B1212e1b7925B84B2D2CE7b, 64);
        _mint(0x14ae8100Ea85a11bbb36578f83AB1b5C1cFDd61c, 65);
        _mint(0x14ae8100Ea85a11bbb36578f83AB1b5C1cFDd61c, 66);
        _mint(0x14ae8100Ea85a11bbb36578f83AB1b5C1cFDd61c, 67);
        _mint(0xE58B7265d56c4a1465Ca44357D33c240D0CEF6ca, 68);
        _mint(0xE58B7265d56c4a1465Ca44357D33c240D0CEF6ca, 69);
        _mint(0xE58B7265d56c4a1465Ca44357D33c240D0CEF6ca, 70);
        _mint(0x2cD1964E7CCE14aB960712164e95661cce78f7C9, 71);
        _mint(0x6fA65eB67D7570d172221d8f7E63865223ee0900, 72);
        _mint(0xB9d70d6fB25A0cD7e14e2997580E0EeD4b09d26B, 73);
        _mint(0xB9d70d6fB25A0cD7e14e2997580E0EeD4b09d26B, 74);
        _mint(0x4bb83EE4fB17f233D30C32213cFDE5E8B5Cdc30E, 75);
        _mint(0xfA82Be08a1809238104E5E3D94C2f19B417914Fe, 76);
        _mint(0xfA82Be08a1809238104E5E3D94C2f19B417914Fe, 77);
        _mint(0x4bb83EE4fB17f233D30C32213cFDE5E8B5Cdc30E, 78);
        _mint(0xB0e8f66E4Ce09C0C108BC96fA47BeB2041b7dD2b, 79);
        _mint(0xDff71A881a17737b6942FE1542F4b88128eA57D8, 80);
        _mint(0x0E47DD69faD380112200c29196cfc7050E28Dc39, 81);
        _mint(0xdDeFC63f0163816d3A39Dcf215F29A40df2c1975, 82);
        _mint(0xdDeFC63f0163816d3A39Dcf215F29A40df2c1975, 83);
        _mint(0x10eC3e9F9CFBAD272e7596dfFbC3466a6Ae6e225, 84);
        _mint(0x76186ca250Bef65522561a0b9fF51D4ee5608932, 85);
        _mint(0x8e8B0E17A2d9198B3Ad17c6eE1cD1d5Ad935b26F, 86);
        _mint(0xD42e5a216258286cBd74222d65D9DFC807E1410F, 87);
        _mint(0x13e0d0A9e4024F1804FA2a0dde4F7c38abCc63F7, 88);
        _mint(0x46C8577b5E7A6D522605056AcD0ec6A620cb3C8b, 89);
        _mint(0x28a0fb32Ae1190110800b4861eEe11Bf54FBBFF4, 90);
        _mint(0x28a0fb32Ae1190110800b4861eEe11Bf54FBBFF4, 91);
        _mint(0xE04885c3f1419C6E8495C33bDCf5F8387cd88846, 92);
        _mint(0xE04885c3f1419C6E8495C33bDCf5F8387cd88846, 93);
        _mint(0xDF290293C4A4d6eBe38Fd7085d7721041f927E0a, 94);
        _mint(0x8e8B0E17A2d9198B3Ad17c6eE1cD1d5Ad935b26F, 95);
        _mint(0x8e8B0E17A2d9198B3Ad17c6eE1cD1d5Ad935b26F, 96);
        _mint(0x187089B33E5812310Ed32A57F53B3fAD0383a19D, 97);
        _mint(0x187089B33E5812310Ed32A57F53B3fAD0383a19D, 98);
        _mint(0x187089B33E5812310Ed32A57F53B3fAD0383a19D, 99);
        _mint(0xB05BC03b85951725E37ACB6384c5769605693cB5, 100);
        _mint(0x1dF428833f2C9FB1eF098754e5D710432450d706, 101);
        _mint(0x380a8a30C4D62DB93b775652B8715718179997Ca, 102);
        _mint(0x614A61a3b7F2fd8750AcAAD63b2a0CFe8B8524F1, 103);
        _mint(0x45e2C1b07CcE6c0C361bB420C13FA0C6154981E9, 104);
        _mint(0x9b5C8aABf848a89B1378a930D42Fb094A7d94C74, 105);
        _mint(0xa0d9DacF387ff00aC622f5cE6ecd9E47E3f4437e, 106);
        _mint(0x01B2f8877f3e8F366eF4D4F48230949123733897, 107);
        _mint(0x01B2f8877f3e8F366eF4D4F48230949123733897, 108);
        _mint(0x5219B866323Ea879A3E34B965b776c5964433a8A, 109);
        _mint(0x5219B866323Ea879A3E34B965b776c5964433a8A, 110);
        _mint(0x5219B866323Ea879A3E34B965b776c5964433a8A, 111);
        _mint(0x204747A864c08644151c7052fA9afD0769eDd734, 112);
        _mint(0x5318E5b4321f0c9d866F65b571a4b4fEC2689617, 113);
        _mint(0x5318E5b4321f0c9d866F65b571a4b4fEC2689617, 114);
        _mint(0xb1436Af35f8F287259F7E8E8688583540e6A92A2, 115);
        _mint(0xa9E8216a4718aE7F578aC629F8e340cF55426E44, 116);
        _mint(0xb1436Af35f8F287259F7E8E8688583540e6A92A2, 117);
        _mint(0xb1436Af35f8F287259F7E8E8688583540e6A92A2, 118);
        _mint(0xb1436Af35f8F287259F7E8E8688583540e6A92A2, 119);
        _mint(0x31e89Be0C67C100BFdb7FaAcdd53C5481887050C, 120);
        _mint(0x09443af3e8bf03899A40d6026480fAb0E44D518E, 121);
        _mint(0x09443af3e8bf03899A40d6026480fAb0E44D518E, 122);
        _mint(0x09443af3e8bf03899A40d6026480fAb0E44D518E, 123);
        _mint(0x09443af3e8bf03899A40d6026480fAb0E44D518E, 124);
        _mint(0x09443af3e8bf03899A40d6026480fAb0E44D518E, 125);
        _mint(0xDF290293C4A4d6eBe38Fd7085d7721041f927E0a, 126);
        _mint(0x66b1De0f14a0ce971F7f248415063D44CAF19398, 127);
        _mint(0x66b1De0f14a0ce971F7f248415063D44CAF19398, 128);
        _mint(0x66b1De0f14a0ce971F7f248415063D44CAF19398, 129);
        _mint(0x3fDDDE5ed6f20CB9E2a8215D5E851744D9c93d17, 130);
        _mint(0x3fDDDE5ed6f20CB9E2a8215D5E851744D9c93d17, 131);
        _mint(0x001292F42F0eC85636f652F618fEFD94bcC3ac6E, 132);
        _mint(0x8e8B0E17A2d9198B3Ad17c6eE1cD1d5Ad935b26F, 133);
        _mint(0x96Bc650f098a697aa04829FD2601935A12d3Df54, 134);
        _mint(0x2be4AAa52893219eC124c8afc8168b7A6103811A, 135);
        _mint(0x1dF428833f2C9FB1eF098754e5D710432450d706, 136);
        _mint(0x80BfB857770a802f7eF375921AD5E83c76214a2d, 137);
        _mint(0x80BfB857770a802f7eF375921AD5E83c76214a2d, 138);
        _mint(0x80BfB857770a802f7eF375921AD5E83c76214a2d, 139);
        _mint(0x657D475a99487F7D133ACd1C295F5Bc5013e4eBc, 140);
        _mint(0xe7b9f33Ed46Fd994404E815ad19d0fdda0845B5F, 141);
        _mint(0x13e0d0A9e4024F1804FA2a0dde4F7c38abCc63F7, 142);
        _mint(0x8e8B0E17A2d9198B3Ad17c6eE1cD1d5Ad935b26F, 143);
        _mint(0x8e8B0E17A2d9198B3Ad17c6eE1cD1d5Ad935b26F, 144);
        _mint(0xb76E4A9932538bBAd705D2936d0dB755389cacFF, 145);
        _mint(0x8C0783BC63AdF423396229A30c66dCA231362959, 146);
        _mint(0x8C0783BC63AdF423396229A30c66dCA231362959, 147);
        _mint(0x554c5aF96E9e3c05AEC01ce18221d0DD25975aB4, 148);
        _mint(0xb1c91BF26aD7d580d0Ceb93f3f7659c347871555, 149);
        _mint(0x411F65A5032BAd0356B4f52A27E81fB5384C4420, 150);
        _mint(0x6304DdDc77F9Bd7e196F81E3Dff6384Ee5e61bA1, 151);
        _mint(0x4a948B383b43622b58a9DE20255732E629FC7f96, 152);
        _mint(0x4a948B383b43622b58a9DE20255732E629FC7f96, 153);
        _mint(0x8931d16B81EAC47FF04cE23036AE524c6a2A1A17, 154);
        _mint(0x8931d16B81EAC47FF04cE23036AE524c6a2A1A17, 155);
        _mint(0x8931d16B81EAC47FF04cE23036AE524c6a2A1A17, 156);
        _mint(0x2989D06a347f36C028CA33E1F6d7310b41c68d31, 157);
        _mint(0xd0C877B474CD51959931a7f70D7a6c60F50cdAE7, 158);
        _mint(0xd0C877B474CD51959931a7f70D7a6c60F50cdAE7, 159);
        _mint(0xd0C877B474CD51959931a7f70D7a6c60F50cdAE7, 160);
        _mint(0xd0C877B474CD51959931a7f70D7a6c60F50cdAE7, 161);
        _mint(0x92fAB452E2F14C7730f79031906E06326c916946, 162);
        _mint(0x13e0d0A9e4024F1804FA2a0dde4F7c38abCc63F7, 163);
        _mint(0x597280e365cc72352eDd384f65c22903af92f47D, 164);
        _mint(0x597280e365cc72352eDd384f65c22903af92f47D, 165);
        _mint(0x597280e365cc72352eDd384f65c22903af92f47D, 166);
        _mint(0x597280e365cc72352eDd384f65c22903af92f47D, 167);
        _mint(0x597280e365cc72352eDd384f65c22903af92f47D, 168);
        _mint(0x31e89Be0C67C100BFdb7FaAcdd53C5481887050C, 169);
        _mint(0x31e89Be0C67C100BFdb7FaAcdd53C5481887050C, 170);
        _mint(0x92fAB452E2F14C7730f79031906E06326c916946, 171);
        _mint(0x92fAB452E2F14C7730f79031906E06326c916946, 172);
        _mint(0xa873baa34eA1868194e5937E3aefD20dD2e549EA, 173);
        _mint(0x2989D06a347f36C028CA33E1F6d7310b41c68d31, 174);
        _mint(0x52a5Ff2B96B7e95F6096AC42f1B20922D2f6b2f7, 175);
        _mint(0x1A5b3eb121846C9505e271067f6feF7FA7EBb5f1, 176);
        _mint(0x1A5b3eb121846C9505e271067f6feF7FA7EBb5f1, 177);
        _mint(0xBbD9dBac3D4c95175bB99890E26a540229cfD2bF, 178);
        _mint(0x52a5Ff2B96B7e95F6096AC42f1B20922D2f6b2f7, 179);
        _mint(0x52a5Ff2B96B7e95F6096AC42f1B20922D2f6b2f7, 180);
        _mint(0xDa81a57188006FeAC8711B046b28A79Ea202E999, 181);
        _mint(0xBbD9dBac3D4c95175bB99890E26a540229cfD2bF, 182);
        _mint(0x824b122Fc83DCBB34f17506F3777D366Af2e36C2, 183);
        _mint(0xB8e570eAa4DeA126ea8C287C810ceD9226B2f0F2, 184);
        _mint(0xcf88FA6eE6D111b04bE9b06ef6fAD6bD6691B88c, 185);
        _mint(0xcf88FA6eE6D111b04bE9b06ef6fAD6bD6691B88c, 186);
        _mint(0xDd2c7FA74BBB4Bf01E2a956Ad36A223c6BE4CB8C, 187);
        _mint(0x13e0d0A9e4024F1804FA2a0dde4F7c38abCc63F7, 188);
        _mint(0xDa81a57188006FeAC8711B046b28A79Ea202E999, 189);
        _mint(0x614A61a3b7F2fd8750AcAAD63b2a0CFe8B8524F1, 190);
        _mint(0x461AE8c33224ACeB7f1259095dd2a334Ad20f322, 191);
        _mint(0x461AE8c33224ACeB7f1259095dd2a334Ad20f322, 192);
        _mint(0x461AE8c33224ACeB7f1259095dd2a334Ad20f322, 193);
        _mint(0x461AE8c33224ACeB7f1259095dd2a334Ad20f322, 194);
        _mint(0x461AE8c33224ACeB7f1259095dd2a334Ad20f322, 195);
        _mint(0x9b5C8aABf848a89B1378a930D42Fb094A7d94C74, 196);
        _mint(0x9b5C8aABf848a89B1378a930D42Fb094A7d94C74, 197);
        _mint(0x9875094945893d40979E2858B6cAf788dcCE3368, 198);
        _mint(0xE6e7bb336daCD37640311FbB099f7580172F5613, 199);
        _mint(0x824b122Fc83DCBB34f17506F3777D366Af2e36C2, 200);
    }

    function updateOracle(address newOracle) external onlyOwner {
        oracle = newOracle;
    }

    function updateURI(string memory newURI) external onlyOwner {
        URI = newURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return URI;
    }

    /**
     * @dev Sync ownerOf function with Ethereum collection.
     */
    function sync(address[] calldata newWallets, uint256[] calldata tokenIds) external onlyOracle {
        for (uint256 i; i<tokenIds.length; i++) {
            _transfer(ownerOf(tokenIds[i]), newWallets[i], tokenIds[i]);
        }
    }

    /**
     * @dev See {IERC721-transferFrom}, except with onlyOwner modifier.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override onlyOwner {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}, except with onlyOwner modifier.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override onlyOwner {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}, except with onlyOwner modifier.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override onlyOwner {
        _safeTransfer(from, to, tokenId, data);
    }
}