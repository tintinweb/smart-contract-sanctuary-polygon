/**
 *Submitted for verification at polygonscan.com on 2022-06-23
*/

// File: ElectionDAO_flat.sol


// File: IDAOYieldVault.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IDAOYieldVault {

    function stake(address member) external payable;

    function unstake(address member) external returns (uint);

    //this could take no inputs but is that good we want this to be flexible and not only pay the mod
    function claim(address _receiver, uint256 _amount) external returns (uint); 

    function setMod(address _receiver, uint256 _tokenId) external;

    function deleteMod() external;

    function getTreasuryValue() external view returns (uint256);

    function getTotalLockedValue() external view returns (uint256);

    //dont need -- am not using 
    function getCurrentModID() external view returns (uint256);

    function getModTokenID() external view returns (uint256);

}
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

// File: @chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol


pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// File: ElectionDAO.sol


pragma solidity ^0.8.10;
 
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";
//using SafeMath for uint256;





error Election__NoCandidates();

 
contract ElectionDAO is ERC721, ERC721URIStorage, KeeperCompatibleInterface {
    using Counters for Counters.Counter;

    uint public maxSupply;
    uint public mintPrice = 0;
    bool public mintLive;
 
    //I have my two intervals right here
    uint256 public immutable intervalWeek = 60; //set for 2 minute updates
    uint256 public lastTimeStamp;
    //uint256 public currentMod; //we might need to use a state variable
 
    //import of daotreasury could be that we have a private treasury here and thats where we donate
    IDAOYieldVault public daoYieldVault;
 
    //should we create a modifier for the MOD
    bool public modNeeded = true;
 
    //DAO card attributes
    struct DAOAttributes {
        uint256 tokenStakeAmount;
        string imageURI;
        uint256 tokenWeight;
        uint256 birthtime;
        uint256 term;
    }
 
    enum Election {
        OPEN,
        CLOSED
    }
 
    Election public s_electionState;
 
    //DAO card mapped to a token ID
    mapping (uint256 => DAOAttributes) public dAOCardAtrributes;
 
    struct Candidate {
        uint256 tokenId;
        uint id; //proposel id
        address candidate; //canidate probably will get rid of this
        string description; //why you are running  
        uint yesVotes;
        uint noVotes;
        bool passed;
    }
 
    mapping (uint => Candidate) public candidates;
   // mapping (address => uint) public lastCandidate; 
 
    uint [] public s_candidateid;
       
    mapping(uint => mapping(address => bool)) public voterHistory;
 
    uint public immutable voterNFTThreshold = 1;
    uint public immutable candidateNFTThreshold = 1;
 
    uint public totalCandidates;
 
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _tokenSentToBurn;
 
    string[] memberStatus = [
        "DAO Member",
        "MOD ELECT",
        "MOD",
        "LAME DUCK"
    ];
 
    constructor(
       
    string memory  _name,
    string memory _symbol,
    uint _maxSupply,
   
    //for now we deploy the yield vault with the contract this will change
    address _daoYieldVault
 
    ) payable ERC721(_name,  _symbol) {
 
        daoYieldVault = IDAOYieldVault(_daoYieldVault);
        lastTimeStamp = block.timestamp;
        maxSupply = _maxSupply;
 
    }
 
    //events
    event Mint(address _from, uint _id);
 
    event CandidateCreated(address _from, uint _id);
 
    event CandidateElected(bool _passed, address _to, uint _id);
 
    event VoteCast(address _from, uint256 _votesUp, uint256 _votesDown, bool _yes, uint _id);
 
    event OwnershipTransferred(address _from, address _to);

    event ModUpdated(uint256 term, string uri, uint256 index);

    //for now im going to leave this out because its easier to test with double voting but i will come back to this
    //do
    //do it now  
    //modifier alreadyVoted(uint256 _candidateId) {
        //if() --- put something here maybe a new daocard attribute if their last vote checked in under a month put this requirmewnt down
        //require(!voterHistory[_candidateId][msg.sender], "User already voted");
        //_;
    //}
 
    function withdraw(uint256 _tokenId) external
    {
        require(ownerOf(_tokenId) == msg.sender, "not owner");
        require(dAOCardAtrributes[_tokenId].term == 120, "mods cant transfer" ); //this might be a modifier or bool
   
            daoYieldVault.unstake(msg.sender);
            _burn(_tokenId);
            delete dAOCardAtrributes[_tokenId];
    }
 
    function getTotalSupply() public view returns (uint256) {
        uint256 supply = _tokenIdCounter.current() - _tokenSentToBurn.current();
        return supply;
    }
 
    //after testing we may add string memory _name as another input
    //uint _mintAmount
    function stake() external payable {
 
        uint256 currentSupply = getTotalSupply();
 
        uint256 stakedAmount = msg.value;
 
        //require(_mintAmount > 0, "Insert mint amount"); //is this needed? we will get rid of the input i think
 
        //+ _mintAmount
        require(currentSupply  <= maxSupply, "max NFT limit exceeded");
 
        require(currentSupply <= maxSupply, "max NFT limit exceeded");
 
        //* _mintAmount
        require(msg.value >= mintPrice, "insufficient funds");
 
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
 
        //stake in the yield treasury  
        daoYieldVault.stake{value: stakedAmount }(msg.sender);
 
        _safeMint(msg.sender, tokenId);
        string memory URIMemberStatus = string(abi.encodePacked(memberStatus[0]));
       
        dAOCardAtrributes[tokenId] = DAOAttributes ({
 
                tokenStakeAmount: stakedAmount,
                imageURI: URIMemberStatus,
                tokenWeight: 0,
                birthtime: block.timestamp,
                term: 120
 
            });
 
        _setTokenURI(tokenId, tokenURI(tokenId));
        emit Mint(msg.sender, tokenId);    
        //add rentrancy
    }
 
    // set mint type
    //function setMint( uint _amount, bool _mintLive) public {
       //mintPrice = _amount;
        //mintLive = _mintLive;
    //}

    function donateToTreasury() external payable {
 
    }

    function reset(uint256 _tokenId) public {
        dAOCardAtrributes[_tokenId].term = dAOCardAtrributes[_tokenId].term + 120;
        updateURI(_tokenId);   
    }
 
    function passTime(uint256 _tokenId) public {
        dAOCardAtrributes[_tokenId].term = dAOCardAtrributes[_tokenId].term - 20;
        updateURI(_tokenId);
        emitUpdate(_tokenId);
    }

    function emitUpdate(uint256 _tokenId) internal {
        emit ModUpdated(
            dAOCardAtrributes[_tokenId].term,
            dAOCardAtrributes[_tokenId].imageURI,
            _tokenId
        );
    }
 
    function updateURI(uint256 _tokenId) private {
       
        uint256 _amount = getCurrentTreasury();  
        string memory memStatus = memberStatus[0];

        //there were 5 payouts 
        if (dAOCardAtrributes[_tokenId].term  == 100) {
 
            memStatus = memberStatus[1];
            modNeeded = false;

        } else if (dAOCardAtrributes[_tokenId].term  == 80) {
 
            memStatus = memberStatus[2];
            sendFundsToUser( _amount, _tokenId);

        
        } else if (dAOCardAtrributes[_tokenId].term  == 60) {

            memStatus = memberStatus[2];
            sendFundsToUser( _amount, _tokenId);

        }
         else if (dAOCardAtrributes[_tokenId].term == 40) {
 
            memStatus = memberStatus[2];
            sendFundsToUser( _amount, _tokenId);

        }
        else if (dAOCardAtrributes[_tokenId].term  == 20) {
 
            memStatus = memberStatus[3]; 
            sendFundsToUser( _amount, _tokenId);

        }
        else if (dAOCardAtrributes[_tokenId].term < 20) {
 
            reset(_tokenId);
            daoYieldVault.deleteMod(); 
            modNeeded = true; 

        }
 
        string memory URIStatus = string(abi.encodePacked(memStatus));
        dAOCardAtrributes[_tokenId].imageURI = URIStatus;
        _setTokenURI(_tokenId, tokenURI(_tokenId));
    }
 
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        DAOAttributes memory daoAttributes = dAOCardAtrributes[_tokenId];
 
        //I might get rid of this as Im not sure if its nessacaray
        //The metadata does not seem to work on rinkeby we are going to need to do this off chain
        string memory strTermSpent = Strings.toString(daoAttributes.term);
       
        //On-Chain Attributes
        string memory json = string(
            abi.encodePacked(
                '{"name": "Bank With Your Community!",',
                '"description": "',
                //'"image": "',
                daoAttributes.imageURI,
                '",',
                '"traits": [',
                '{"trait_type": "Term","value": ',
                strTermSpent,
                "}]",
                "}"
            )
        );
       
        string memory output = string(abi.encodePacked(json));
        return output;
    }
 
    function sendFundsToUser(uint256 _amount, uint256 _tokenID) internal {

        //does payable still work for receiving yield
        address _receiver = payable(ownerOf(_tokenID)); 
        daoYieldVault.claim(_receiver, _amount); // we could claim from treasury first then withdraw from here

        //write a withdraw function to call from daoyield
        //address(this).balance
        //TESTING
        (bool success, ) = _receiver.call{value: 0.01 ether}("");
        require(success, "Transfer failed");
   
    }
 
    function enterCandidate (string memory _ipfsHash, string memory _name, uint256 _tokenID) public {
        require(balanceOf(msg.sender) >= candidateNFTThreshold, "Use doesn't have enough NFTs to be elected");
        require(s_electionState == Election.OPEN, "Election is not open");
        //require(lastCandidate[msg.sender] == 0, "Only 1 entry per user");
        require(ownerOf(_tokenID) == msg.sender, "Not Owner Of Entrance Token");
        require(s_candidateid.length < 20, "Candidates At Capacity");
 
        Candidate memory _candidate;
 
        _candidate.tokenId = _tokenID;
        _candidate.id = totalCandidates; //could we make this tokenID -- if this is tokenID we can get rid of the candidate counter
        _candidate.candidate = msg.sender; //does this have to be payable
        _candidate.description = _ipfsHash;
 
        candidates[_candidate.id] = _candidate;
 
        //Prevents double entrance by msg.sender
        //lastCandidate[msg.sender] = _candidate.id; we dont care about double entry right now 
 
        //TESTING -- counter mostly keeps track of all the candidates
        totalCandidates +=1;
 
        //set a limit on candidates
        s_candidateid.push(totalCandidates);
 
        emit CandidateCreated(msg.sender, _candidate.id);
       
    }
 
    function getHighestVote() internal returns (uint256) {
        uint256 winningid;
        uint256 defaultNumber = 100;
 
            for (uint i = 0; i < s_candidateid.length; i++) {
                uint largestValue = 0;
                if(candidates[i].yesVotes >= largestValue){
                    largestValue = candidates[i].yesVotes;
                    winningid = candidates[i].tokenId; //we could make this a state variable 
                    //add the amount paid set the struct here percentage 28 / 100 ** getotaltreasury()
                    candidates[i].passed = true;
                    emit CandidateElected(candidates[i].passed , candidates[i].candidate, candidates[i].id);
                    delete candidates[i]; 
                    return winningid;    
                }
                else {

                    candidates[i].passed = false;
                    emit CandidateElected(candidates[i].passed , candidates[i].candidate, candidates[i].id);
                    delete candidates[i]; 
                }      
            }
            return defaultNumber;  
    }
 
    //after calling calculate winner we should have a winning token ID and previous ids and maps should be deleted - make internal
    function calculateWinner() public returns (uint256) {
        s_electionState = Election.OPEN; 
        uint256 winnerId = getHighestVote();
        s_candidateid = new uint[](0);
       return winnerId;
    }
   
    function calculateWeight(uint256 tokenID) internal view returns (uint256) {
        uint256 weightedPoints;
        uint256 timePassed = 120; //2months //2628000; //1 month //make this custom  
        uint256 stakeTime = block.timestamp - dAOCardAtrributes[tokenID].birthtime;
        if(stakeTime > timePassed){
           uint256 points = stakeTime / timePassed;
            weightedPoints = points / getTotalSupply();
        }
 
        return weightedPoints;
    }
 
    //Implement Better Algo If There Is Time - average of no and yes votes the score as a ratio of those values
    function voteOnCandidate(bool _yes, uint _candidateId, uint tokenID) public {
 
        require(s_electionState == Election.OPEN, "Election is not open");
        require(balanceOf(msg.sender) >= voterNFTThreshold, "User doesn't have enough NFTs to vote");
        require(ownerOf(tokenID) == msg.sender, "not owner");
        //require(!voterHistory[_candidateId][msg.sender], "User already voted");
 
        //TESTING
        dAOCardAtrributes[tokenID].tokenWeight = calculateWeight(tokenID);
 
            if (_yes) {
               
                candidates[_candidateId].yesVotes += (1 + calculateWeight(tokenID));
                //emit VoteCast(msg.sender, true, _candidateId);
               
 
            } else {
 
                candidates[_candidateId].noVotes += (1 + calculateWeight(tokenID));
                //emit VoteCast(msg.sender, false, _candidateId);
            }

            emit VoteCast(msg.sender, candidates[_candidateId].yesVotes,  candidates[_candidateId].noVotes, false, _candidateId);

 
        //Prevents double entrance by msg.sender - we are going to need a voter reset right now because we delete IDs they cant vote on the same id twice
        //I think we can do this with a modifier check to see if its a new election then issue the require statment if that is true else they can vote
        //voterHistory[_candidateId][msg.sender] = true;
       
    }
  
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        public
        view
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        //bool isOpen = Election.OPEN == s_electionState;
        upkeepNeeded = (block.timestamp - lastTimeStamp) > intervalWeek;
       
    }
 
    function performUpkeep(
        bytes calldata /* performData */
    ) external {
 
            if((block.timestamp - lastTimeStamp) > intervalWeek){

                if(modNeeded && s_candidateid.length > 0){

                    s_electionState = Election.CLOSED; 
                    uint256 winningtoken = calculateWinner();
                    address newMod = payable(ownerOf(winningtoken));
                    daoYieldVault.setMod(newMod, winningtoken);
                    passTime(winningtoken);

                } else if(!modNeeded) {
                
                    //this needs to be changed
                    uint256 modID = daoYieldVault.getModTokenID();
                    passTime(modID);

                    //uint256 _amount = getCurrentTreasury();
                    //sendFundsToUser( _amount, modID);

                } else {
                    revert Election__NoCandidates();
                } 

                lastTimeStamp = block.timestamp;
            }         
    }
  
    function _burn (uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        _tokenSentToBurn.increment();
        super._burn(tokenId);
 
    }
 
    //Not sure if this works but should make it non transferable
     function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) {
       
        require(dAOCardAtrributes[tokenId].term == 120, "mods cant transfer" ); //this might be a modifier or bool
        super._beforeTokenTransfer(from, to, tokenId);
    }
     
    //TESTING
    function balanceOfContract() public view  returns (uint256) {
        //require(owner != address(0), "ERC721: balance query for the zero address");
        return address(this).balance;
    }
 
    //TESTING
    function getbirthTimeStamp(uint256 tokenID) public view returns (uint256) {
        return dAOCardAtrributes[tokenID].birthtime;
    }
 
    //TESTING
    function getcurrentTimeStamp() public view returns (uint256) {
        return block.timestamp;
    }
 
    function getCurrentTreasury() public view returns (uint256) {
        return daoYieldVault.getTreasuryValue();
    }
 
    function getTotalLockedValue() public view returns (uint256) {
        return daoYieldVault.getTotalLockedValue();
    }
 
    //TESTING
    function getCurrentCandidates() public view returns (uint256) {
        return s_candidateid.length;
    }

    //TESTING - get tokenUri function 
    function getTokenUri(uint256 _tokenId) public view returns (string memory){
        string memory _tokenURI = tokenURI(_tokenId);
        return _tokenURI;
    }
 
}