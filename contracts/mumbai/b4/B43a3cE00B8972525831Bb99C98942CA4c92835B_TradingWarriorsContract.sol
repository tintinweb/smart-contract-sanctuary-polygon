/**
 *Submitted for verification at polygonscan.com on 2022-06-06
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Counters.sol


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


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

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

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;


/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// File: contracts/lol.sol


pragma solidity ^0.8.2;






contract TradingWarriorsContract is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _totalTradingWarriors;
    Counters.Counter private _totalTradingWarriorsAlpha;
    Counters.Counter private _totalTradingWarriorsDeans;
    Counters.Counter private _totalTradingWarriorsChief;
    struct _DateTime {
        uint16 year;
        uint8 month;
        uint8 day;
        uint8 hour;
        uint8 minute;
        uint8 second;
        uint8 weekday;
    }
    uint256 constant DAY_IN_SECONDS = 86400;
    uint256 constant YEAR_IN_SECONDS = 31536000;
    uint256 constant LEAP_YEAR_IN_SECONDS = 31622400;
    uint256 constant HOUR_IN_SECONDS = 3600;
    uint256 constant MINUTE_IN_SECONDS = 60;
    uint16 constant ORIGIN_YEAR = 1970;
    struct Stake {
        address owner;
        uint256 tokenId;
        uint256 since;
        uint256 room;
        uint256 lockedUntil;
        uint256 team;
    }
    struct Stakeholder {
        address user;
        Stake[] address_stakes;
    }
    struct Warrior {
        address owner;
        uint256 tokenId;
    }
    struct Holder {
        address user;
        Warrior[] address_warriors;
    }
    Holder[] internal holders;
    Stakeholder[] internal stakeholders;
    //Stakeholder[] private stakeholdersIn;
    event Staked(
        address indexed user,
        uint256 tokenId,
        uint256 index,
        uint256 room,
        uint256 timestamp,
        uint256 lockedUntil,
        uint256 team
    );
    uint256 private maxMintAlpha = 1;
    mapping(address => uint256) internal stakes;
    mapping(address => uint256) internal tw_holders;
    //uint256 private priceAlpha = 0 ether;
    //uint256 private priceDeans = 55 ether;
    //uint256 private priceChief = 65 ether;
    //uint256 private price = 80 ether;

    uint256 private priceAlpha = 0 ether;
    uint256 private priceDeans = 0.0000055 ether;
    uint256 private priceChief = 0.0000065 ether;
    uint256 private price = 0.000008 ether;

    uint256 private _allowedMintedTokenAlpha = 150;
    uint256 private _allowedMintedTokenDeans = 150;
    uint256 private _allowedMintedTokenChief = 150;
    uint256 private _allowedMintedToken = 4050;

    string private baseURI = "https://tradingwarriors.net/t0x45/json/";
    string private baseExtension = ".json";
    mapping(address => bool) private whiteList;
    mapping(address => bool) private whiteListAlpha;
    mapping(address => bool) private whiteListDeans;
    mapping(address => bool) private whiteListChief;
    mapping(address => uint256) private whiteListMintCount;

    //address private tradingAddress = 0xbDc8F9Ee9715eE63CE4df27c17fdAeFF9c2c0434;
    //address private gameTeamAddress =
    //address private gameTeamAddress =
    //   0x30Db02EbA4EeCE65954ea1D1BBc358e0fC3e12D5;
    //address private marketingAddress =
    //    0x9d971C3cAf066556A1A92986275D6d2218dE0e37;
    //address private liquidityAddress =
    //   0xF8Edf21EbC3024280af1F45D8C16464144C79419;
    //address private donationAddress =
    //  0x41efcC793A34cec99e4297B5f6cAC04472d86045;
    //uint256 private hoursStakingAllowed = 48;

    address private tradingAddress = 0x07DCb1Fe2524074fB9721101E0F1145577a8f533;
    address private gameTeamAddress =
        0x07DCb1Fe2524074fB9721101E0F1145577a8f533;
    address private marketingAddress =
        0x07DCb1Fe2524074fB9721101E0F1145577a8f533;
    address private liquidityAddress =
        0x07DCb1Fe2524074fB9721101E0F1145577a8f533;
    address private donationAddress =
        0x07DCb1Fe2524074fB9721101E0F1145577a8f533;
    uint256 private hoursStakingAllowed = 48;

    uint256 private percTradingAddress = 20;
    uint256 private percGameTeamAddress = 35;
    uint256 private percMarketingAddress = 15;
    uint256 private percLiquidityAddress = 25;
    uint256 private percDonationAddress = 5;
    address[] private ownerTokenAlpha;
    address[] private ownerTokenDeans;
    address[] private ownerTokenChief;
    address[] private userWarriors;
    uint256[] private roomWarriors;
    uint256[] private tokeIdWarriors;
    bool openAlpha = false;
    bool openDeans = false;
    bool openChief = false;
    bool openPublic = false;
    bool public blockAllTransfers = false;
    bool public stakingAllowed = true;

    //constructor() ERC721("Trading Warriors NFT ", "TWG") {
    // stakeholders.push();
    // }
    constructor() ERC721("PVG HOTN", "PVG") {
        stakeholders.push();
        holders.push();
    }

    function mintOwner(address to, uint256 amount) public onlyOwner {
        require(
            _totalTradingWarriors.current() + amount <= totalSupply(),
            "Not enough tokens left to buy."
        );

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = _totalTradingWarriors.current();
            if (tokenId < totalSupply()) {
                _totalTradingWarriors.increment();
                _safeMint(to, tokenId);
                string memory uri = string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        baseExtension
                    )
                );
                _setTokenURI(tokenId, uri);
                _addHolder(to, tokenId);
            }
        }
    }

    function mintPhase(uint256 amount, uint256 phase) public payable {
        require(whiteList[msg.sender] == true, "Not whitelisted.");

        require(
            _totalTradingWarriors.current() + amount <= totalSupply(),
            "Not enough tokens left to buy."
        );
        if (phase == 1) {
            require(
                whiteListMintCount[msg.sender] - amount >= 0,
                "Over mint limit for address."
            );
            require(whiteListAlpha[msg.sender] == true, "Not whitelisted.");
            require(openAlpha, "Alpha phase is closed.");
            require(amount > 0 && amount <= maxMintAlpha, "Mint wrong number");
        } else if (phase == 2) {
            require(whiteListDeans[msg.sender] == true, "Not whitelisted.");
            require(openDeans, "Deans phase is closed.");

            require(
                msg.value >= priceDeans * amount,
                "Amount of ether sent not correct."
            );
        } else if (phase == 3) {
            require(whiteListChief[msg.sender] == true, "Not whitelisted.");
            require(openChief, "Chief phase is closed.");

            require(
                msg.value >= priceChief * amount,
                "Amount of ether sent not correct."
            );
        }

        uint256 remainingTokens = whiteListMintCount[msg.sender];
        if (phase != 1) {
            uint256 tradingPay = ((msg.value / 100) * percTradingAddress);
            uint256 marketingPay = ((msg.value / 100) * percMarketingAddress);
            uint256 lquidityPay = ((msg.value / 100) * percLiquidityAddress);
            uint256 donationPay = ((msg.value / 100) * percDonationAddress);
            uint256 gameTeamPay = msg.value -
                tradingPay -
                marketingPay -
                lquidityPay -
                donationPay;
            payable(owner()).transfer(gameTeamPay);
            payable(tradingAddress).transfer(tradingPay);
            payable(marketingAddress).transfer(marketingPay);
            payable(liquidityAddress).transfer(lquidityPay);
            payable(donationAddress).transfer(donationPay);
        }

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = _totalTradingWarriors.current();
            if (tokenId < totalSupply()) {
                _totalTradingWarriors.increment();
                _safeMint(msg.sender, tokenId);
                string memory uri = string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        baseExtension
                    )
                );
                _setTokenURI(tokenId, uri);
                if (remainingTokens > 0) {
                    remainingTokens--;
                } else {
                    remainingTokens = 0;
                }
                _addHolder(msg.sender, tokenId);
            }
        }
        whiteListMintCount[msg.sender] = remainingTokens;
    }

    function mintPublic(uint256 amount) public payable {
        require(openPublic, "Public phase is closed.");
        require(
            _totalTradingWarriors.current() + amount <= totalSupply(),
            "Not enough tokens left to buy."
        );

        require(
            msg.value >= price * amount,
            "Amount of ether sent not correct."
        );

        uint256 tradingPay = ((msg.value / 100) * percTradingAddress);
        uint256 marketingPay = ((msg.value / 100) * percMarketingAddress);
        uint256 lquidityPay = ((msg.value / 100) * percLiquidityAddress);
        uint256 donationPay = ((msg.value / 100) * percDonationAddress);
        uint256 gameTeamPay = msg.value -
            tradingPay -
            marketingPay -
            lquidityPay -
            donationPay;
        payable(owner()).transfer(gameTeamPay);
        payable(tradingAddress).transfer(tradingPay);
        payable(marketingAddress).transfer(marketingPay);
        payable(liquidityAddress).transfer(lquidityPay);
        payable(donationAddress).transfer(donationPay);
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = _totalTradingWarriors.current();
            if (tokenId < totalSupply()) {
                _totalTradingWarriors.increment();
                _safeMint(msg.sender, tokenId);
                string memory uri = string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        baseExtension
                    )
                );
                _setTokenURI(tokenId, uri);
                _addHolder(msg.sender, tokenId);
            }
        }
    }

    function changeStakeRoomByAdmin(
        address userAddress,
        uint256 tokenId,
        uint256 lockedUntil,
        uint256 room
    ) public onlyOwner returns (string memory) {
        uint256 index = stakes[userAddress];
        string memory st = "";
        if (index != 0) {
            Stake[] storage current_stake = stakeholders[index].address_stakes;
            for (uint256 i = 0; i < current_stake.length; i++) {
                if (current_stake[i].tokenId == tokenId) {
                    current_stake[i].room = room;
                    current_stake[i].since = block.timestamp;
                    current_stake[i].team = 0;
                    current_stake[i].lockedUntil = lockedUntil;

                    st = "okUp";
                }
            }
        }
        return st;
    }

    function stakeByAdmin(
        address userAddress,
        uint256 tokenId,
        uint256 room,
        uint256 team,
        uint256 lockedUntil
    ) public onlyOwner returns (string memory) {
        bool exit = false;
        uint256 index = stakes[userAddress];
        uint256 timestamp = block.timestamp;
        address tk = ownerOf(tokenId);
        string memory st = "";
        require(tk == userAddress, "You aren't the token's owner.");
        if (index == 0) {
            index = _addStakeholder(userAddress);
            stakeholders[index].address_stakes.push(
                Stake(userAddress, tokenId, timestamp, room, lockedUntil, team)
            );

            st = "okNew";
        } else {
            Stake[] storage current_stake = stakeholders[index].address_stakes;
            for (uint256 i = 0; i < current_stake.length; i++) {
                if (current_stake[i].tokenId == tokenId) {
                    if (current_stake[i].since == 0) {
                        current_stake[i].room = room;
                        current_stake[i].since = timestamp;
                        current_stake[i].team = team;
                        current_stake[i].lockedUntil = lockedUntil;

                        st = "okUp";
                    } else {
                        st = "ko";
                    }
                    exit = true;
                }
            }
            if (!exit) {
                stakeholders[index].address_stakes.push(
                    Stake(
                        userAddress,
                        tokenId,
                        timestamp,
                        room,
                        lockedUntil,
                        team
                    )
                );

                st = "okNew";
            }
        }
        return st;
    }

    function stake(
        uint256[] calldata tokenIds,
        uint256 roomSelect,
        uint256 team
    ) public returns (string[] memory) {
        string[] memory st = new string[](tokenIds.length);
        uint256 index = stakes[msg.sender];
        uint256 timestamp = block.timestamp;
        uint256 lockedUntil = block.timestamp;
        uint256 room = roomSelect;
        if (room != 1) {
            require(stakingAllowed == true, "Staking is blocked.");
            uint256 max = (hoursStakingAllowed * HOUR_IN_SECONDS) +
                (2 * MINUTE_IN_SECONDS);
            uint256 h = getHour(block.timestamp) * HOUR_IN_SECONDS;
            uint256 m = getMinute(block.timestamp) * MINUTE_IN_SECONDS;
            uint256 s = getSecond(block.timestamp);
            uint256 locked = max - h - m - s;
            lockedUntil = block.timestamp + locked;
        }
        for (uint256 ids = 0; ids < tokenIds.length; ids++) {
            uint256 tokenId = tokenIds[ids];
            bool exit = false;
            address tk = ownerOf(tokenId);

            require(tk == msg.sender, "You aren't the token's owner.");
            if (index == 0) {
                index = _addStakeholder(msg.sender);
                stakeholders[index].address_stakes.push(
                    Stake(
                        msg.sender,
                        tokenId,
                        timestamp,
                        room,
                        lockedUntil,
                        team
                    )
                );

                st[ids] = "okNew";
            } else {
                Stake[] storage current_stake = stakeholders[index]
                    .address_stakes;
                for (uint256 i = 0; i < current_stake.length; i++) {
                    if (current_stake[i].tokenId == tokenId) {
                        if (current_stake[i].since == 0) {
                            current_stake[i].room = room;
                            current_stake[i].since = timestamp;
                            current_stake[i].team = team;
                            current_stake[i].lockedUntil = lockedUntil;

                            st[ids] = "okUp";
                        } else {
                            st[ids] = "ko";
                        }
                        exit = true;
                    } else {
                        st[ids] = "okNew";
                    }
                }
                if (!exit) {
                    stakeholders[index].address_stakes.push(
                        Stake(
                            msg.sender,
                            tokenId,
                            timestamp,
                            room,
                            lockedUntil,
                            team
                        )
                    );
                }
            }
        }

        return st;
    }

    function unStake(uint256[] calldata tokenIds)
        public
        returns (string[] memory)
    {
        uint256 index = stakes[msg.sender];
        require(index != 0, "Your warrior is NOT staking.");

        string[] memory st = new string[](tokenIds.length);
        for (uint256 ids = 0; ids < tokenIds.length; ids++) {
            uint256 tokenId = tokenIds[ids];
            address tk = ownerOf(tokenId);
            require(tk == msg.sender, "You aren't the token's owner.");
            Stake[] storage current_stake = stakeholders[index].address_stakes;
            for (uint256 i = 0; i < current_stake.length; i++) {
                if (current_stake[i].tokenId == tokenId) {
                    if (current_stake[i].room != 1) {
                        require(
                            stakingAllowed == false,
                            "UnStaking is blocked."
                        );
                    }

                    if (
                        current_stake[i].since != 0 &&
                        current_stake[i].lockedUntil < block.timestamp
                    ) {
                        current_stake[i].since = 0;
                        current_stake[i].lockedUntil = 0;
                        current_stake[i].team = 0;
                        current_stake[i].room = 0;

                        st[ids] = "okUp";
                    } else {
                        st[ids] = "ko";
                    }
                } else {
                    st[ids] = "noExit";
                }
            }
        }

        return st;
    }

    function unStakeByAdmin(address userAddress, uint256 tokenId)
        public
        onlyOwner
        returns (string memory)
    {
        uint256 index = stakes[userAddress];
        require(index != 0, "Warrior is NOT staking.");
        string memory st = "";
        address tk = ownerOf(tokenId);
        require(tk == userAddress, "Token does not exist.");
        Stake[] storage current_stake = stakeholders[index].address_stakes;
        for (uint256 i = 0; i < current_stake.length; i++) {
            if (current_stake[i].tokenId == tokenId) {
                if (current_stake[i].since != 0) {
                    current_stake[i].since = 0;
                    current_stake[i].lockedUntil = 0;
                    current_stake[i].team = 0;
                    current_stake[i].room = 0;

                    st = "okUp";
                } else {
                    st = "ko";
                }
            }
        }
        return st;
    }

    function _addHolder(address owner, uint256 tokenId) internal {
        uint256 index = tw_holders[owner];
        if (index == 0) {
            holders.push();
            uint256 userIndex = holders.length - 1;
            holders[userIndex].user = owner;
            tw_holders[owner] = userIndex;
            holders[userIndex].address_warriors.push(
                Warrior(msg.sender, tokenId)
            );
        } else {
            holders[index].address_warriors.push(Warrior(msg.sender, tokenId));
        }
    }

    function _addStakeholder(address staker) internal returns (uint256) {
        stakeholders.push();
        uint256 userIndex = stakeholders.length - 1;
        stakeholders[userIndex].user = staker;
        stakes[staker] = userIndex;
        return userIndex;
    }

    function getStakeWarriorsByRoom(uint256 room)
        public
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256
        )
    {
        uint256 wn = 0;
        uint256 arr = 0;
        for (uint256 i = 0; i < stakeholders.length; i++) {
            Stake[] memory cny = stakeholders[i].address_stakes;
            for (uint256 icny = 0; icny < cny.length; icny++) {
                if (room != 0) {
                    if (cny[icny].room == room && cny[icny].since != 0) {
                        wn++;
                    }
                }
            }
        }
        address[] memory userAdd = new address[](wn);
        uint256[] memory userTokenId = new uint256[](wn);
        for (uint256 i = 0; i < stakeholders.length; i++) {
            Stake[] memory cny = stakeholders[i].address_stakes;
            for (uint256 icny = 0; icny < cny.length; icny++) {
                if (room != 0) {
                    if (cny[icny].room == room && cny[icny].since != 0) {
                        userAdd[arr] = cny[icny].owner;
                        userTokenId[arr] = cny[icny].tokenId;
                        arr++;
                    }
                }
            }
        }
        return (userAdd, userTokenId, wn);
    }

    function getWarriorsByAddress(address trading_warrior)
        public
        view
        returns (Warrior[] memory)
    {
        uint256 index = tw_holders[trading_warrior];
        Warrior[] memory cn;
        if (index != 0) {
            cn = holders[index].address_warriors;
        }
        return cn;
    }

    function getStakeWarriorsByAddress(address staker)
        public
        view
        returns (Stake[] memory)
    {
        uint256 index = stakes[staker];
        Stake[] memory cn;
        if (index != 0) {
            cn = stakeholders[index].address_stakes;
        }
        return cn;
    }

    function addSingleAddressToWhitelist(address addr, uint256 phase)
        public
        onlyOwner
    {
        require(phase > 0 && phase <= 3, "Phase wrong number");
        whiteList[addr] = true;
        whiteListMintCount[addr] = 1;
        if (phase == 1) {
            require(
                _totalTradingWarriorsAlpha.current() + 1 <=
                    _allowedMintedTokenAlpha,
                "Whitelist is full."
            );
            ownerTokenAlpha.push(addr);
            whiteListAlpha[addr] = true;
        } else if (phase == 2) {
            require(
                _totalTradingWarriorsDeans.current() + 1 <=
                    _allowedMintedTokenDeans,
                "Whitelist is full."
            );
            ownerTokenDeans.push(addr);
            whiteListDeans[addr] = true;
        } else if (phase == 3) {
            require(
                _totalTradingWarriorsChief.current() + 1 <=
                    _allowedMintedTokenChief,
                "Whitelist is full."
            );
            ownerTokenChief.push(addr);
            whiteListChief[addr] = true;
        }

        if (phase == 1) {
            _totalTradingWarriorsAlpha.increment();
        } else if (phase == 2) {
            _totalTradingWarriorsDeans.increment();
        } else if (phase == 3) {
            _totalTradingWarriorsChief.increment();
        }
    }

    function emptyStakeHolders() public onlyOwner {
        for (uint256 i = 0; i < stakeholders.length; i++) {
            delete stakeholders[i];
        }
    }

    //["0x30Dbxxx","0x30Dbxxx","0x30Dbxxx"]
    function addListAddressToWhitelist(address[] calldata addr, uint256 phase)
        public
        onlyOwner
    {
        require(phase > 0 && phase <= 3, "Phase wrong number");
        for (uint256 i = 0; i < addr.length; i++) {
            whiteList[addr[i]] = true;
            whiteListMintCount[addr[i]] = 1;
            if (phase == 1) {
                require(
                    _totalTradingWarriorsAlpha.current() + addr.length <=
                        _allowedMintedTokenAlpha,
                    "Whitelist is full."
                );
                ownerTokenAlpha.push(addr[i]);
                whiteListAlpha[addr[i]] = true;
            } else if (phase == 2) {
                require(
                    _totalTradingWarriorsDeans.current() + addr.length <=
                        _allowedMintedTokenDeans,
                    "Whitelist is full."
                );
                ownerTokenDeans.push(addr[i]);
                whiteListDeans[addr[i]] = true;
            } else if (phase == 3) {
                require(
                    _totalTradingWarriorsChief.current() + addr.length <=
                        _allowedMintedTokenChief,
                    "Whitelist is full."
                );
                ownerTokenChief.push(addr[i]);
                whiteListChief[addr[i]] = true;
            }
            for (uint256 ia = 0; ia < addr.length; ia++) {
                if (phase == 1) {
                    _totalTradingWarriorsAlpha.increment();
                } else if (phase == 2) {
                    _totalTradingWarriorsDeans.increment();
                } else if (phase == 3) {
                    _totalTradingWarriorsChief.increment();
                }
            }
        }
    }

    function isAddressInWhitelist(address addr)
        public
        view
        virtual
        returns (bool)
    {
        return whiteList[addr] == true;
    }

    function getStatusPhase(uint256 phase) public view returns (bool) {
        if (phase == 1) {
            return openAlpha;
        } else if (phase == 2) {
            return openDeans;
        } else if (phase == 3) {
            return openChief;
        } else if (phase == 4) {
            return openPublic;
        } else {
            return false;
        }
    }

    function getWhiteListUsersByPhase(uint256 phase)
        public
        view
        returns (address[] memory)
    {
        address[] memory ownerTokenreturn;
        if (phase == 1) {
            return ownerTokenAlpha;
        } else if (phase == 2) {
            return ownerTokenDeans;
        } else if (phase == 3) {
            return ownerTokenChief;
        } else {
            return ownerTokenreturn;
        }
    }

    function updateStatusWarriosTransfers(bool status) public onlyOwner {
        blockAllTransfers = status;
    }

    function updateStatusStaking(bool status) public onlyOwner {
        stakingAllowed = status;
    }

    function updateStatusPhase(uint256 phase, bool status) public onlyOwner {
        if (phase == 1) {
            openAlpha = status;
        } else if (phase == 2) {
            openDeans = status;
        } else if (phase == 3) {
            openChief = status;
        } else if (phase == 4) {
            openPublic = status;
        }
    }

    function getCurrentMintCounter() public view returns (uint256) {
        return _totalTradingWarriors.current();
    }

    function getCurrentMintCounterAlpha() public view returns (uint256) {
        return _totalTradingWarriorsAlpha.current();
    }

    function getCurrentMintCounterDeans() public view returns (uint256) {
        return _totalTradingWarriorsDeans.current();
    }

    function getCurrentMintCounterChief() public view returns (uint256) {
        return _totalTradingWarriorsChief.current();
    }

    function burnByOwner(uint256[] calldata tokensToBurn) public onlyOwner {
        for (uint256 i = 0; i < tokensToBurn.length; i++) {
            super._burn(tokensToBurn[i]);
        }
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function inStake(address from, uint256 tokenId) public view returns (bool) {
        bool instake = true;
        bool exit = false;
        if (from != address(0)) {
            uint256 index = stakes[from];
            if (index != 0) {
                Stake[] memory current_stake = stakeholders[index]
                    .address_stakes;
                for (uint256 i = 0; i < current_stake.length; i++) {
                    if (current_stake[i].tokenId == tokenId) {
                        if (current_stake[i].since == 0) {
                            instake = false;
                        }
                        exit = true;
                    }
                }
                if (!exit) {
                    instake = false;
                }
            } else {
                instake = false;
            }
        } else {
            instake = false;
        }

        return instake;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {
        require(blockAllTransfers == false, "All transfers are blocked.");
        require(inStake(from, tokenId) == false, "Token in stake.");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function totalMintWhitelist() public view returns (uint256) {
        return
            _totalTradingWarriorsAlpha.current() +
            _totalTradingWarriorsDeans.current() +
            _totalTradingWarriorsChief.current();
    }

    function remainingMintTokens() public view returns (uint256) {
        return totalSupply() - _totalTradingWarriors.current();
    }

    function totalSupply() public view returns (uint256) {
        return
            _allowedMintedTokenAlpha +
            _allowedMintedTokenDeans +
            _allowedMintedTokenChief +
            _allowedMintedToken;
    }

    function isLeapYear(uint16 year) public pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 != 0) {
            return true;
        }
        if (year % 400 != 0) {
            return false;
        }
        return true;
    }

    function leapYearsBefore(uint256 year) public pure returns (uint256) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function getDaysInMonth(uint8 month, uint16 year)
        public
        pure
        returns (uint8)
    {
        if (
            month == 1 ||
            month == 3 ||
            month == 5 ||
            month == 7 ||
            month == 8 ||
            month == 10 ||
            month == 12
        ) {
            return 31;
        } else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        } else if (isLeapYear(year)) {
            return 29;
        } else {
            return 28;
        }
    }

    function parseTimestamp(uint256 timestamp)
        internal
        pure
        returns (_DateTime memory dt)
    {
        uint256 secondsAccountedFor = 0;
        uint256 buf;
        uint8 i;

        // Year
        dt.year = getYear(timestamp);
        buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

        // Month
        uint256 secondsInMonth;
        for (i = 1; i <= 12; i++) {
            secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                dt.month = i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }

        // Day
        for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
            if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                dt.day = i;
                break;
            }
            secondsAccountedFor += DAY_IN_SECONDS;
        }

        // Hour
        dt.hour = getHour(timestamp);

        // Minute
        dt.minute = getMinute(timestamp);

        // Second
        dt.second = getSecond(timestamp);

        // Day of week.
        //dt.weekday = getWeekday(timestamp);
    }

    function getYear(uint256 timestamp) public pure returns (uint16) {
        uint256 secondsAccountedFor = 0;
        uint16 year;
        uint256 numLeapYears;

        // Year
        year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor +=
            YEAR_IN_SECONDS *
            (year - ORIGIN_YEAR - numLeapYears);

        while (secondsAccountedFor > timestamp) {
            if (isLeapYear(uint16(year - 1))) {
                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            } else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }
        return year;
    }

    function getMonth(uint256 timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).month;
    }

    function getDay(uint256 timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).day;
    }

    function getHour(uint256 timestamp) public pure returns (uint8) {
        return uint8((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint256 timestamp) public pure returns (uint8) {
        return uint8((timestamp / 60) % 60);
    }

    function getSecond(uint256 timestamp) public pure returns (uint8) {
        return uint8(timestamp % 60);
    }
}