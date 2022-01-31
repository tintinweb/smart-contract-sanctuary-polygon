/**
 *Submitted for verification at polygonscan.com on 2022-01-21
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// File: @openzeppelin/contracts/utils/Counters.sol



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

// File: @openzeppelin/contracts/interfaces/IERC165.sol



pragma solidity ^0.8.0;


// File: @openzeppelin/contracts/interfaces/IERC2981.sol



pragma solidity ^0.8.0;


/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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

// File: contracts/BoleroNFT.sol



pragma solidity ^0.8.10;






interface IBoleroSwap {
	function openSellOffer(address _nftAddress, address _wantAddress, uint256 _nftTokenID, uint256 _wantAmount, address _owner) external;
	function openBid(address _nftAddress, address _wantAddress, uint256 _nftTokenID, uint256 _startOffer, uint256 _startTime, uint256 _endTime, address _owner) external returns (uint256);
}

contract NFTController {
    address public bolero = address(0);
    bool public isEmergencyPause = false;

	modifier onlyBolero() {
		require(msg.sender == bolero, "!authorized");
		_;
	}

    function setBolero(address _bolero) public onlyBolero {
        bolero = _bolero;
    }
}

contract RoyaltiesWrapper is NFTController {
    uint256 public constant MAXIMUM_PERCENT = 10000;
    uint256 public constant MAXIMUM_PERCENT_ARTIST = 4750;
    uint256 public royaltiesForBolero = 250;

    event SetRoyalties(uint256 royaltiesForBolero);

    /*******************************************************************************
    **	@notice Update the royalties distribution between Bolero and the Artist
    **	@param _royaltiesForBolero: the new r % for Bolero
    **	@param _royaltiesForArtist: the new r % for the Artist
    *******************************************************************************/
    function setRoyalties(uint256 _royaltiesForBolero) public onlyBolero() {
        _setRoyalties(_royaltiesForBolero);
    }
    function _setRoyalties(uint256 _royaltiesForBolero) internal {
        require (_royaltiesForBolero + MAXIMUM_PERCENT_ARTIST <= MAXIMUM_PERCENT, "invalid royalties");
        royaltiesForBolero = _royaltiesForBolero;
        emit SetRoyalties(_royaltiesForBolero);
    }

    // /*******************************************************************************
    // **	@notice Implement ERC2981
    // *******************************************************************************/
    // function royaltyInfo(uint256, uint256 value) external view returns (address receiver, uint256 royaltyAmount) {
    //     return (address(this), (value * (royaltiesForBolero + royaltiesForArtist)) / MAXIMUM_PERCENT);
    // }

}

contract BoleroNFT is ERC721Enumerable, RoyaltiesWrapper {
    using Counters for Counters.Counter;
    using Strings for uint256;

    struct Collection {
        address artist;
        address payment;
        address privateSaleToken;
        string collectionName;
        uint256 collectionId;
        uint256 artistRoyalty;
        uint256 cap;
        uint256 privateSaleThreshold;
    }

    struct BatchMintData {
        address _to;
        string _tokenURI;
    }
    struct BatchMintAndSellData {
        address _to;
        string _tokenURI;
        address _wantToken;
        uint256 _wantAmount;
    }
    struct BatchMintAndBidData {
        address _to;
        string _tokenURI;
        address _wantToken;
        uint256 _startOffer;
        uint256[2] _startEndTime;
    }

    Counters.Counter public _collectionIds;
    Counters.Counter public _tokenIds;
    address public boleroSwap = address(0);

    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => bool) public isSecondaryMarket;
    mapping(uint256 => Collection) public collections;
    mapping(uint256 => uint256[]) public collection_tokensIds;
    mapping(address => uint256[]) public collection_byArtist;
    mapping(uint256 => uint256) public collectionForTokenID;

    event NewCollection(uint256 collectionID, address artist, string name, uint256 royalties, uint256 cap);
    event SetSecondaryMarket(uint256 tokenID);

	/*******************************************************************************
	**	@notice Initialize the new contract.
	**	@param name Name of the erc721
	**	@param symbol Symbol of the erc721
	**	@param swap address of the swap contract
	**	@param royalties royalties split for the artist and bolero
	*******************************************************************************/
    constructor(
        string memory name,
        string memory symbol,
        address swap,
        uint256 boleroRoyalty
    ) ERC721(name, symbol) {
        bolero = msg.sender;
        boleroSwap = swap;
        _setRoyalties(boleroRoyalty);
    }

	/*******************************************************************************
	**	@notice Initialize the new contract.
	**	@param artistAddress The address of the artist
	**	@param collectionPaymentAddress payment address for this artist
	**	@param collectionName Name of the collection
	**	@param artistRoyalty amount of royalties in % for this artist
	**	@param cap the maximum amount of tokens in the collection
    **	@param privateSaleThreshold the amount of tokens needed to be able to buy
    **  a token from this collection on the swap.
	*******************************************************************************/
    function newCollection(
        address artistAddress,
        address collectionPaymentAddress,
        address privateSaleToken,
        string memory collectionName,
        uint256 artistRoyalty,
        uint256 cap,
        uint256 privateSaleThreshold
    ) public {
        _collectionIds.increment();
        uint256 newCollectionIds = _collectionIds.current();

        require(artistRoyalty < MAXIMUM_PERCENT_ARTIST, "!royalty");

        Collection memory _newCollection = Collection(
            artistAddress,
            collectionPaymentAddress,
            privateSaleToken,
            collectionName,
            newCollectionIds,
            artistRoyalty,
            cap,
            privateSaleThreshold
        );
        collections[newCollectionIds] = _newCollection;
        collection_byArtist[artistAddress].push(newCollectionIds);
        emit NewCollection(newCollectionIds, artistAddress, collectionName, artistRoyalty, cap);
    }

    /*******************************************************************************
	**	@notice Replace the payment address of a collection. Can only be called by
    **	the artist or Bolero.
	**	@param _payment new address to use as payment address
	**	@param _collectionId id of the collection to update
    *******************************************************************************/
    function setCollectionPaymentAddress(address _payment, uint256 _collectionId) public {
        Collection storage col = collections[_collectionId];
		require(msg.sender == bolero || msg.sender == col.artist, "!authorized");
        require(_payment != address(0), "!payment");
        col.payment = _payment;
    }

    /*******************************************************************************
    **	@notice Mint a new NFT for a specific address.
    **	@param _to: Address of the address receiving the new token
    **	@param _tokenURI: Data to attach to this token
    **	@param _collectionId: the collection in wich we should put this token
    *******************************************************************************/
    function _mintNFT(address _to, string memory _tokenURI, uint256 _collectionId) internal returns (uint256) {
        Collection memory workingCollection = collections[_collectionId];
		require(msg.sender == workingCollection.artist || msg.sender == bolero, "!authorized");

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        uint256 numberOfItemsInCollection = collection_tokensIds[_collectionId].length;
        require(numberOfItemsInCollection < workingCollection.cap, "!cap");

        collection_tokensIds[_collectionId].push(newItemId);
        collectionForTokenID[newItemId] = _collectionId;
        _mint(_to, newItemId);
        _setTokenURI(newItemId, _tokenURI);
        return newItemId;
    }
    function mintNFT(address _to, string memory _tokenURI, uint256 _collectionId) public returns (uint256) {
        require(_collectionId > 0, "!collection");
        return _mintNFT(_to, _tokenURI, _collectionId);
    }

    /*******************************************************************************
    **	@notice Mint a new NFT for a specific address and put a sell offer on the
    **          swap contract
    **	@param _to: Address of the address receiving the new token
    **	@param _tokenURI: Data to attach to this token
    **	@param _collectionId: the collection in wich we should put this token
    **	@param _wantToken: token expected as countervalue
    **	@param _wantAmount: amount expected as countervalue
    *******************************************************************************/
    function mintNFTAndOpenSellOffer(
        address _to,
        string memory _tokenURI,
        uint256 _collectionId,
        address _wantToken,
        uint256 _wantAmount
    ) public returns (uint256) {
        require(_collectionId > 0, "!collection");
        uint256 tokenId = _mintNFT(address(this), _tokenURI, _collectionId);
        IERC721(address(this)).approve(boleroSwap, tokenId);
        IBoleroSwap(boleroSwap).openSellOffer(
            address(this),
            _wantToken,
            tokenId,
            _wantAmount,
            _to
        );
        return tokenId;
    }

    /*******************************************************************************
    **	@notice Mint a new NFT for a specific address and put a bid offer on the
    **          swap contract
    **	@param _to: Address of the address receiving the new token
    **	@param _tokenURI: Data to attach to this token
    **	@param _collectionId: the collection in wich we should put this token
    **	@param _wantToken: token expected as countervalue
	**	@param _startOffer start price for this bid
    **	@param _startTime: start time for this auction
    **	@param _endTime: end time for this auction
    *******************************************************************************/
    function _mintNFTAndOpenBidOfferHelper(string memory _tokenURI, uint256 _collectionId) internal returns (uint256) {
        require(_collectionId > 0, "!collection");
        uint256 tokenId = _mintNFT(address(this), _tokenURI, _collectionId);
        IERC721(address(this)).approve(boleroSwap, tokenId);
        return tokenId;
    }
    function mintNFTAndOpenBidOffer(
        address _to,
        string memory _tokenURI,
        uint256 _collectionId,
        address _wantToken,
        uint256 _startOffer,
        uint256[2] memory _startEndTime
    ) public returns (uint256) {
        uint256 tokenId = _mintNFTAndOpenBidOfferHelper(_tokenURI, _collectionId);
        return IBoleroSwap(boleroSwap).openBid(
            address(this),
            _wantToken,
            tokenId,
            _startOffer,
            _startEndTime[0],
            _startEndTime[1],
            _to
        );
    }
 
    /*******************************************************************************
    **	@notice Mint a batch of new NFT. Only the Bolero Management or the artist
    **  can mint.
    **	@param _mintData: Array of BatchMintData to mint the NFT
    *******************************************************************************/
    function mintBatchNFT(BatchMintData[] memory _mintData, uint256 _collectionId) public {
        require(_collectionId > 0, "!collection");
        for (uint256 index = 0; index < _mintData.length; index++) {
            _mintNFT(_mintData[index]._to, _mintData[index]._tokenURI, _collectionId);
        }
    }
 
    /*******************************************************************************
    **	@notice Mint a batch of new NFT for a specific address and put a sell offer
    **          on the swap contract
    **	@param _mintData: Array of BatchMintAndSellData to mint the NFT
    *******************************************************************************/
    function mintBatchNFTAndOpenSellOffer(BatchMintAndSellData[] memory _mintData, uint256 _collectionId) public {
        require(_collectionId > 0, "!collection");
        for (uint256 index = 0; index < _mintData.length; index++) {
            uint256 tokenId = _mintNFT(address(this), _mintData[index]._tokenURI, _collectionId);
            IERC721(address(this)).approve(boleroSwap, tokenId);
            IBoleroSwap(boleroSwap).openSellOffer(
                address(this),
                _mintData[index]._wantToken,
                tokenId,
                _mintData[index]._wantAmount,
                _mintData[index]._to
            );
        }
    }
 
    /*******************************************************************************
    **	@notice Mint a batch of new NFT for a specific address and put a bid offer
    **          on the swap contract
    **	@param _mintData: Array of BatchMintAndBidData to mint the NFT
    *******************************************************************************/
    function mintBatchNFTAndOpenBidOffer(BatchMintAndBidData[] memory _mintData, uint256 _collectionId) public {
        require(_collectionId > 0, "!collection");
        for (uint256 index = 0; index < _mintData.length; index++) {
            uint256 tokenId = _mintNFT(address(this), _mintData[index]._tokenURI, _collectionId);
            IERC721(address(this)).approve(boleroSwap, tokenId);
            IBoleroSwap(boleroSwap).openBid(
                address(this),
                _mintData[index]._wantToken,
                tokenId,
                _mintData[index]._startOffer,
                _mintData[index]._startEndTime[0],
                _mintData[index]._startEndTime[1],
                _mintData[index]._to
            );
        }
    }

    /*******************************************************************************
    **  @dev Return the royalties for a specific token
    *******************************************************************************/
    function getRoyalties(uint256 _tokenID) external view returns (uint256) {
        uint256 collectionForToken = getCollectionIDForToken(_tokenID);
        Collection memory col = collections[collectionForToken];
        return col.artistRoyalty;
    }

    /*******************************************************************************
    **  @dev Return the collection for a specific token
    *******************************************************************************/
    function getCollectionForToken(uint256 _tokenID) public view returns (Collection memory) {
        Collection memory col = collections[collectionForTokenID[_tokenID]];
        return col;
    }

    /*******************************************************************************
    **  @dev Return the collectionID for a specific token
    *******************************************************************************/
    function getCollectionIDForToken(uint256 _tokenID) public view returns (uint256) {
        return collectionForTokenID[_tokenID];
    }

    /*******************************************************************************
    **  @dev Return the list of tokens for a specific collection
    *******************************************************************************/
    function listTokensForCollection(uint256 _collectionID) public view returns (uint256[] memory) {
        return collection_tokensIds[_collectionID];
    }

    /*******************************************************************************
    **  @dev Return the list of collections for a specific artist
    *******************************************************************************/
    function listCollectionsForArtist(address _artist) public view returns (uint256[] memory) {
        return collection_byArtist[_artist];
    }

    /*******************************************************************************
    **  @dev Return the payment address for a specific token
    *******************************************************************************/
    function artistPayment(uint256 _tokenID) external view returns (address) {
        uint256 collectionForToken = getCollectionIDForToken(_tokenID);
        Collection memory col = collections[collectionForToken];
        return col.payment;
    }

    /*******************************************************************************
    **  @dev Return the list of tokens for a specific artist
    *******************************************************************************/
    function listTokensForArtist(address _artist) public view returns (uint256[] memory)  {
        uint256[] memory _collections = listCollectionsForArtist(_artist);
        uint256 currentIndex = 0;
        uint256 len = 0;

        for (uint256 index = 0; index < _collections.length; index++) {
            uint256[] memory tokensForCollection = listTokensForCollection(_collections[index]);
            for (uint256 index2 = 0; index2 < tokensForCollection.length; index2++) {
                len += 1;
            }
        }

        uint256[] memory _tokens = new uint256[](len);
        for (uint256 index = 0; index < _collections.length; index++) {
            uint256[] memory tokensForCollection = listTokensForCollection(_collections[index]);
            for (uint256 index2 = 0; index2 < tokensForCollection.length; index2++) {
                _tokens[currentIndex] = tokensForCollection[index2];
                currentIndex += 1;
            }
        }
        return _tokens;
    }

    /*******************************************************************************
    **  @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
    *******************************************************************************/
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

	/*******************************************************************************
	**	@notice Check if a user could access the offer/bid for a specific collection
	**	@param _userAddress address to check whitelisting
	**	@param _tokenID id of the token to check
	*******************************************************************************/
    function canSwap(address _userAddress, uint256 _tokenID) public view returns (bool) {
        Collection memory col = collections[collectionForTokenID[_tokenID]];
        if (isSecondaryMarket[_tokenID]) {
            return true;
        }
        if (col.privateSaleToken == address(0) || col.privateSaleThreshold == 0) {
            return true;
        }
        uint256 balanceOfUser = IERC20(col.privateSaleToken).balanceOf(_userAddress);
        if (balanceOfUser >= col.privateSaleThreshold) {
            return true;
        }
        return false;
    }

    /*******************************************************************************
    **  @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
    **  `tokenId` must exist.
    *******************************************************************************/
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /*******************************************************************************
    **  @dev Replace the swap contract address.
    *******************************************************************************/
    function setBoleroSwap(address _swap) public onlyBolero() {
        boleroSwap = _swap;
    }

    /*******************************************************************************
    **  @dev Notify secondary market
    *******************************************************************************/
    function setSecondaryMarketStatus(uint256 _tokenID) public {
        require(msg.sender == boleroSwap, "!swap");
        isSecondaryMarket[_tokenID] = true;
        emit SetSecondaryMarket(_tokenID);
    }
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol



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

// File: contracts/BoleroNFTSwap.sol



pragma solidity ^0.8.10;





interface IBoleroABI {
	function management() external view returns (address);
	function rewards() external view returns (address);
}

interface IBoleroNFT {
	function royaltiesForBolero() external view returns (uint256);
	function royaltiesForArtist() external view returns (uint256);
	function artistPayment(uint256 _tokenID) external view returns (address);
    function getRoyalties(uint256 _tokenID) external view returns (uint256);
    function setSecondaryMarketStatus(uint256 _tokenID) external;
	function canSwap(address _userAddress, uint256 _tokenID) external view returns (bool);
}

contract Controller {
	address public bolero = address(0); //Management address
	address public rewards = address(0); //address used to send the rewards

	bool public isEmergencyPause = false;

	modifier onlyBoleroOrManagement() {
		require(address(msg.sender) == bolero || address(msg.sender) == IBoleroABI(bolero).management(), "!authorized");
		_;
	}
	modifier notEmergency() {
		require(isEmergencyPause == false, "emergency pause");
		_;
	}
}

contract BoleroNFTSwap is Controller {
	using Counters for Counters.Counter;
	struct Offer {
		address from; // NFT SELLER
		address to; // NFT BUYER
		address nftAddress; //ADDRESS OF THE NFT CONTRACT
		address wantAddress; //ADDRESS OF THE ERC20 CONTRACT
		uint256 nftTokenID; //TOKEN ID OF THE NFT TO EXCHANGE
		uint256 wantAmount; //AMOUNT OF THE ERC20 TO EXCHANGE
		bytes32 status; // Open, Executed, Cancelled
	}
	struct Bid {
		address from; // NFT SELLER
		address to; // Current best offer
		address nftAddress; //ADDRESS OF THE NFT CONTRACT
		address wantAddress; //ADDRESS OF THE ERC20 CONTRACT
		uint256 nftTokenID; //TOKEN ID OF THE NFT TO EXCHANGE
		uint256 startOffer; //STARTING PRICE FOR THIS AUCTION
		uint256 bestOffer; //BEST OFFER OF THE NFT TO EXCHANGE, OR INITIAL PRICE
		uint256 startTime; //TIMESTAMP OF THE START OF THE AUCTION
		uint256 endTime; //TIMESTAMP OF THE END OF THE AUCTION
		bytes32 status; // Open, Executed, Cancelled
	}
	struct BidMemory {
		address from; //Bider
		uint256 offer; //Amount of bid
		bytes32 status; // Open, Executed, Cancelled
	}
	struct LastSale {
		uint8 saleType; //0 = none, 1 = buy, 2 = sell, 3 = bid
		uint256 id; //id of the sale
		uint256 timestamp; //when executed
		uint256 amount; //amount of want token in exchange
		address	buyer; //buyer of the sale
		address wantToken; //address of the want token
	}

	bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
	mapping(uint256 => Offer) public sellOffers;
	mapping(uint256 => Offer) public buyOffers;
	mapping(uint256 => Bid) public bids;
	mapping(address => mapping(uint256 => uint256[])) public sellOffersEnum;
	mapping(address => mapping(uint256 => uint256[])) public buyOffersEnum;
	mapping(address => mapping(uint256 => uint256[])) public bidsEnum;
	mapping(address => mapping(uint256 => BidMemory[])) public bidsValues;
	mapping(address => mapping(uint256 => LastSale)) public lastSale;
	Counters.Counter private sellCounter;
	Counters.Counter private buyCounter;
	Counters.Counter private bidCounter;

	event CreateSellOffer(
		uint256 indexed sellCounter,
		address from,
		address indexed nftAddress,
		address wantAddress,
		uint256 indexed nftTokenID,
		uint256 wantAmount,
		string status
	);
	event CancelSellOffer(
		uint256 indexed sellCounter,
		address from,
		address indexed nftAddress,
		uint256 indexed nftTokenID,
		string status
	);
	event ExecuteSellOffer(
		uint256 indexed sellCounter,
		address from,
		address to,
		address indexed nftAddress,
		address wantAddress,
		uint256 indexed nftTokenID,
		uint256 wantAmount,
		string status
	);
	event CreateBuyOffer(
		uint256 indexed buyCounter,
		address from,
		address indexed nftAddress,
		address wantAddress,
		uint256 indexed nftTokenID,
		uint256 wantAmount,
		string status
	);
	event CancelBuyOffer(
		uint256 indexed buyCounter,
		address from,
		address indexed nftAddress,
		uint256 indexed nftTokenID,
		string status
	);
	event ExecuteBuyOffer(
		uint256 indexed buyCounter,
		address from,
		address to,
		address indexed nftAddress,
		address wantAddress,
		uint256 indexed nftTokenID,
		uint256 wantAmount,
		string status
	);
	event OpenBid(
		uint256 indexed bidCounter,
		address from,
		address indexed nftAddress,
		address wantAddress,
		uint256 indexed nftTokenID,
		uint256 startOffer,
		uint256 startTime,
		uint256 endTime,
		string status
	);
	event PerformBid(
		uint256 indexed bidCounter,
		address from,
		address to,
		address indexed nftAddress,
		address wantAddress,
		uint256 indexed nftTokenID,
		uint256 startOffer
	);
	event CancelBid(
		uint256 indexed bidCounter,
		address from,
		address indexed nftAddress,
		uint256 indexed nftTokenID,
		string status
	);
	event CancelBidOffer(
		uint256 indexed bidOfferCounter,
		address from,
		address indexed nftAddress,
		uint256 indexed nftTokenID,
		string status
	);
	event ExecuteBid(
		uint256 indexed bidCounter,
		address from,
		address to,
		address indexed nftAddress,
		address wantAddress,
		uint256 indexed nftTokenID,
		uint256 wantAmount,
		string status
	);


	constructor(address _bolero, address _rewards) {
		rewards = _rewards;
		bolero = _bolero;
	}

	/*************************************************************************************
	**	@notice Open a new sell offer. A sell offer can occurs when a user has
	**			a NFT and want to sell it. To a specific price.
	**			The sell order will be added on chain and available for anyone
	**			to buy it.	
	**
	**	@dev The NFT is locked in the contract until the trade is executed or cancelled.
	**       The trade will fail if the NFT is not approved.
	**
	**	@param _nftAddress address of the Bolero NFT contract to sell
	**	@param _wantAddress address of the ERC20 contract the user wants in countervalue
	**	@param _nftTokenID ID of the NFT to sell
	**	@param _wantAmount amount of the ERC20 the user wants.
	*************************************************************************************/
	function openSellOffer(
		address _nftAddress,
		address _wantAddress,
		uint256 _nftTokenID,
		uint256 _wantAmount
	) public {
		sellCounter.increment();
		uint256 _sellCounter = sellCounter.current();
		IERC721(_nftAddress).transferFrom(msg.sender, address(this), _nftTokenID);
		sellOffersEnum[_nftAddress][_nftTokenID].push(_sellCounter);
		sellOffers[_sellCounter] = Offer({
			from: msg.sender,
			to: address(0),
			nftAddress: _nftAddress,
			nftTokenID: _nftTokenID,
			wantAddress: _wantAddress,
			wantAmount: _wantAmount,
			status: "Open"
		});
		emit CreateSellOffer(_sellCounter, msg.sender, _nftAddress, _wantAddress, _nftTokenID, _wantAmount, "Open");
	}

	function openSellOffer(
		address _nftAddress,
		address _wantAddress,
		uint256 _nftTokenID,
		uint256 _wantAmount,
		address _owner
	) public {
		sellCounter.increment();
		uint256 _sellCounter = sellCounter.current();
		IERC721(_nftAddress).transferFrom(msg.sender, address(this), _nftTokenID);
		sellOffersEnum[_nftAddress][_nftTokenID].push(_sellCounter);
		sellOffers[_sellCounter] = Offer({
			from: _owner,
			to: address(0),
			nftAddress: _nftAddress,
			nftTokenID: _nftTokenID,
			wantAddress: _wantAddress,
			wantAmount: _wantAmount,
			status: "Open"
		});
		emit CreateSellOffer(_sellCounter, _owner, _nftAddress, _wantAddress, _nftTokenID, _wantAmount, "Open");
	}

	/*************************************************************************************
	**	@notice Cancel one of my existing trades. Only by the owner of the trade. Only
	**			if the trade is not executed.
	**
	**	@dev The NFT will be returned to the user and the trade set as Cancelled.
	**
	**	@param _sellCounter ID of the trade to cancel
	*************************************************************************************/
	function cancelSellOffer(uint256 _sellCounter) public {
		Offer memory offer = sellOffers[_sellCounter];
		require(msg.sender == offer.from, "!not seller");
		require(offer.status == "Open", "!open");
		sellOffers[_sellCounter].status = "Cancelled";

		IERC721(offer.nftAddress).transferFrom(address(this), offer.from, offer.nftTokenID);
		emit CancelSellOffer(_sellCounter, msg.sender, offer.nftAddress, offer.nftTokenID, "Cancelled");
	}

	/*************************************************************************************
	**	@notice Execute a trade. Can be called by anyone but the seller. The trade should
	**			be in the Open state.
	**			Some royalties will be paid to the artist and Bolero based on the values
	**			set in the NFT Contract. Theses fees will be substracted from the amount
	**			of ERC20 the seller will get and put in a treasury, ready to be claimed.
	**
	**	@param _sellCounter ID of the trade to cancel
	*************************************************************************************/
	function executeSellOffer(uint256 _sellCounter) public notEmergency() {
		Offer memory offer = sellOffers[_sellCounter];
		require(offer.status == "Open", "!open");
		require(offer.from != msg.sender, "!msg.sender");
		require(IBoleroNFT(offer.nftAddress).canSwap(msg.sender, offer.nftTokenID), "!whitelist");

		sellOffers[_sellCounter].to = msg.sender;
		sellOffers[_sellCounter].status = "Executed";

		//Compute the royalties for Bolero and the artist, and get the final amount
		//for the seller.
		uint256 royaltiesForBolero = IBoleroNFT(offer.nftAddress).royaltiesForBolero();
		uint256 royaltiesForArtist = IBoleroNFT(offer.nftAddress).getRoyalties(offer.nftTokenID);
		uint256 amountForBolero = offer.wantAmount * royaltiesForBolero / 10000;
		uint256 amountForArtist = offer.wantAmount * royaltiesForArtist / 10000;
		uint256 amountForSeller = offer.wantAmount - (amountForBolero + amountForArtist);

		//Retrieve the address of the artist and the address of BoleroRewards to increment
		//their treasures.
		address artistPayment = IBoleroNFT(offer.nftAddress).artistPayment(offer.nftTokenID);

		//Transfering the offer to this contract
		require(IERC20(offer.wantAddress).transferFrom(msg.sender, address(this), offer.wantAmount));

		//Send the fees to Bolero and the Artist paiement contract. Sending the paiement to the seller
		require(IERC20(offer.wantAddress).transfer(rewards, amountForBolero));
		require(IERC20(offer.wantAddress).transfer(artistPayment, amountForArtist));
		require(IERC20(offer.wantAddress).transfer(offer.from, amountForSeller));

		//Send the nft to the buyer
		IERC721(offer.nftAddress).transferFrom(address(this), msg.sender, offer.nftTokenID);
		IBoleroNFT(offer.nftAddress).setSecondaryMarketStatus(offer.nftTokenID);
		lastSale[offer.nftAddress][offer.nftTokenID] = LastSale(2, _sellCounter, block.timestamp, offer.wantAmount, msg.sender, offer.wantAddress);

		emit ExecuteSellOffer(_sellCounter, offer.from, msg.sender, offer.nftAddress, offer.wantAddress, offer.nftTokenID, offer.wantAmount, "Executed");
	}

	/*************************************************************************************
	**	@notice Open a new buy offer. A buy offer can occurs when a user wants to buy an
	**			NFT to a specific price, even if there is no sell order currently
	**			available.
	**			The buy order will be added on chain and available the NFT owner to sell.
	**
	**	@dev The payout is locked in the contract until the trade is executed or
	**		 cancelled. The trade will fail if the tokens are not approved.
	**
	**	@param _nftAddress address of the Bolero NFT contract to sell
	**	@param _wantAddress address of the ERC20 contract the user wants in countervalue
	**	@param _nftTokenID ID of the NFT to sell
	**	@param _wantAmount amount of the ERC20 the user wants.
	*************************************************************************************/
	function openBuyOffer(address _nftAddress, address _wantAddress, uint256 _nftTokenID, uint256 _wantAmount) public {
		require(IERC20(_wantAddress).balanceOf(msg.sender) >= _wantAmount, "!balance");
		require(IERC20(_wantAddress).allowance(msg.sender, address(this)) >= _wantAmount, "!balance");
		require(IBoleroNFT(_nftAddress).canSwap(msg.sender, _nftTokenID), "!whitelist");

		buyCounter.increment();
		uint256 _buyCounter = buyCounter.current();
		buyOffersEnum[_nftAddress][_nftTokenID].push(_buyCounter);
		buyOffers[_buyCounter] = Offer({
			from: msg.sender,
			to: address(0),
			nftAddress: _nftAddress,
			nftTokenID: _nftTokenID,
			wantAddress: _wantAddress,
			wantAmount: _wantAmount,
			status: "Open"
		});
		emit CreateBuyOffer(_buyCounter, msg.sender, _nftAddress, _wantAddress, _nftTokenID, _wantAmount, "Open");
	}

	/*************************************************************************************
	**	@notice Cancel one of my existing trades. Only by the owner of the trade. Only
	**			if the trade is not executed.
	**
	**	@dev The wantAmount will be returned to the user and the trade set as Cancelled.
	**
	**	@param _buyCounter ID of the trade to cancel
	*************************************************************************************/
	function cancelBuyOffer(uint256 _buyCounter) public {
		Offer memory offer = buyOffers[_buyCounter];
		require(msg.sender == offer.from, "!authorized");
		require(offer.status == "Open", "!open");
		buyOffers[_buyCounter].status = "Cancelled";
		emit CancelBuyOffer(_buyCounter, msg.sender, offer.nftAddress, offer.nftTokenID, "Cancelled");
	}

	/*************************************************************************************
	**	@notice Execute a trade. The trade should be in the Open state.
	**			Some royalties will be paid to the artist and Bolero based on the values
	**			set in the NFT Contract. Theses fees will be substracted from the amount
	**			of ERC20 the seller will get and put in a treasury, ready to be claimed.
	**
	**	@param _buyCounter ID of the trade to cancel
	*************************************************************************************/
	function executeBuyOffer(uint256 _buyCounter) public notEmergency() {
		Offer memory offer = buyOffers[_buyCounter];
		require(offer.status == "Open", "!open");
		require(offer.from != msg.sender, "!msg.sender");

		buyOffers[_buyCounter].to = msg.sender;
		buyOffers[_buyCounter].status = "Executed";

		//Compute the royalties for Bolero and the artist, and get the final amount
		//for the seller.
		uint256 royaltiesForBolero = IBoleroNFT(offer.nftAddress).royaltiesForBolero();
		uint256 royaltiesForArtist = IBoleroNFT(offer.nftAddress).getRoyalties(offer.nftTokenID);
		uint256 amountForBolero = offer.wantAmount * royaltiesForBolero / 10000;
		uint256 amountForArtist = offer.wantAmount * royaltiesForArtist / 10000;
		uint256 amountForSeller = offer.wantAmount - amountForBolero - amountForArtist;

		//Retrieve the address of the artist and the address of BoleroRewards to increment
		//their treasures.
		address artistPayment = IBoleroNFT(offer.nftAddress).artistPayment(offer.nftTokenID);

		//Transfering the offer to this contract
		require(IERC20(offer.wantAddress).transferFrom(offer.from, address(this), offer.wantAmount));

		//Send the fees to Bolero and the Artist paiement contract. Sending the paiement to the seller
		require(IERC20(offer.wantAddress).transfer(rewards, amountForBolero));
		require(IERC20(offer.wantAddress).transfer(artistPayment, amountForArtist));
		require(IERC20(offer.wantAddress).transfer(msg.sender, amountForSeller));

		//Send the nft to the buyer
		IERC721(offer.nftAddress).transferFrom(msg.sender, offer.from, offer.nftTokenID);
		IBoleroNFT(offer.nftAddress).setSecondaryMarketStatus(offer.nftTokenID);

		lastSale[offer.nftAddress][offer.nftTokenID] = LastSale(1, _buyCounter, block.timestamp, offer.wantAmount, offer.from, offer.wantAddress);

		emit ExecuteBuyOffer(_buyCounter, offer.from, msg.sender, offer.nftAddress, offer.wantAddress, offer.nftTokenID, offer.wantAmount, "Executed");
	}

	/*************************************************************************************
	**	@notice Create a new auction. An auction can occurs when a user wants to sell an
	**			NFT to a non specific price and let buyers bid on it.
	**
	**	@dev The NFT is locked in the contract until the trade is executed or cancelled.
	**       The trade will fail if the NFT is not approved.
	**
	**	@param _nftAddress address of the Bolero NFT contract to sell
	**	@param _wantAddress address of the ERC20 contract the user wants in countervalue
	**	@param _nftTokenID ID of the NFT to sell
	**	@param _startOffer start price for this bid
	*************************************************************************************/
	function openBid(address _nftAddress, address _wantAddress, uint256 _nftTokenID, uint256 _startOffer, uint256 _startTime, uint256 _endTime) public {
		require(_startTime >= block.timestamp || _startTime == 0, "!timestamp");
		require(_endTime > _startTime, "!endTime");
		bidCounter.increment();
		uint256 _bidCounter = bidCounter.current();
		IERC721(_nftAddress).transferFrom(msg.sender, address(this), _nftTokenID);
		bidsEnum[_nftAddress][_nftTokenID].push(_bidCounter);
		bidsValues[_nftAddress][_nftTokenID].push(BidMemory(address(0), _startOffer, "Open"));
		bids[_bidCounter] = Bid({
			from: msg.sender,
			to: address(0),
			nftAddress: _nftAddress,
			nftTokenID: _nftTokenID,
			wantAddress: _wantAddress,
			startOffer: _startOffer,
			bestOffer: _startOffer,
			startTime: _startTime,
			endTime: _endTime,
			status: "Open"
		});
		emit OpenBid(_bidCounter, msg.sender, _nftAddress, _wantAddress, _nftTokenID, _startOffer, _startTime, _endTime, "Open");
	}
	
	function openBid(address _nftAddress, address _wantAddress, uint256 _nftTokenID, uint256 _startOffer, uint256 _startTime, uint256 _endTime, address _owner) public returns (uint256) {
		require(_startTime >= block.timestamp || _startTime == 0, "!timestamp");
		require(_endTime > _startTime, "!endTime");
		bidCounter.increment();
		uint256 _bidCounter = bidCounter.current();
		IERC721(_nftAddress).transferFrom(msg.sender, address(this), _nftTokenID);
		bidsEnum[_nftAddress][_nftTokenID].push(_bidCounter);
		bidsValues[_nftAddress][_nftTokenID].push(BidMemory(address(0), _startOffer, "Open"));
		bids[_bidCounter] = Bid({
			from: _owner,
			to: address(0),
			nftAddress: _nftAddress,
			nftTokenID: _nftTokenID,
			wantAddress: _wantAddress,
			startOffer: _startOffer,
			bestOffer: _startOffer,
			startTime: _startTime,
			endTime: _endTime,
			status: "Open"
		});
		emit OpenBid(_bidCounter, _owner, _nftAddress, _wantAddress, _nftTokenID, _startOffer, _startTime, _endTime, "Open");
		return _nftTokenID;
	}

	/*************************************************************************************
	**	@notice Add a new bid to an existing auction.
	**
	**	@dev This function will check if the bidder has enough ERC20 to pay the bid, and
	**			if the ERC20 are approved by the contract. It will also check if the
	**			auction is still open, and if the bid is higher than the current best.
	**			No funds are transfered, only the approval is checked.
	**
	**	@param _bidCounter ID of the auction to bid on
	**	@param _offer amount to bid
	*************************************************************************************/
	function performBid(uint256 _bidCounter, uint256 _offer) public {
		Bid memory bid = bids[_bidCounter];
		require(bid.status == "Open", "!open");
		require(block.timestamp >= bid.startTime || bid.startTime == 0, "!timestamp");
		require(block.timestamp < bid.endTime, "!endTime");
		require(bid.from != msg.sender, "!msg.sender");
		require(bid.bestOffer < _offer, "!offer");
		require(IERC20(bid.wantAddress).balanceOf(msg.sender) >= _offer, "!balance");
		require(IERC20(bid.wantAddress).allowance(msg.sender, address(this)) >= _offer, "!balance");
		require(IBoleroNFT(bid.nftAddress).canSwap(msg.sender, bid.nftTokenID), "!whitelist");

		bids[_bidCounter].to = msg.sender;
		bids[_bidCounter].bestOffer = _offer;
		bidsValues[bid.nftAddress][bid.nftTokenID].push(BidMemory(msg.sender, _offer, "Open"));
		emit PerformBid(_bidCounter, bid.from, msg.sender, bid.nftAddress, bid.wantAddress, bid.nftTokenID, _offer);
	}

	/*************************************************************************************
	**	@notice Cancel an auction.
	**
	**	@dev This function will check if the auction is still open, and if the caller is
	**	     the owner of the auction. The NFT is transfered back to the owner.
	**
	**	@param _bidCounter ID of the auction to bid on
	*************************************************************************************/
	function cancelBid(uint256 _bidCounter) public {
		Bid memory bid = bids[_bidCounter];
		require(bid.status == "Open", "!open");
		require(bid.from == msg.sender, "!authorized");
		bids[_bidCounter].status = "Cancelled";
		IERC721(bid.nftAddress).transferFrom(address(this), bid.from, bid.nftTokenID);

		emit CancelBid(_bidCounter, bid.from, bid.nftAddress, bid.nftTokenID, "Cancelled");
	}

	/*************************************************************************************
	**	@notice Cancel an user bid
	**
	**	@param _bidCounter ID of the auction to cancel
	**	@param _bidIndex ID of the bid Offer to cancel
	*************************************************************************************/
	function cancelBidOffer(uint256 _bidCounter, uint256 _bidIndex) public {
		Bid memory bid = bids[_bidCounter];
		require(bid.status == "Open", "!open");

		BidMemory memory bidToCancel = bidsValues[bid.nftAddress][bid.nftTokenID][_bidIndex];
		require(bidToCancel.status == "Open", "!open");
		require(bidToCancel.from == msg.sender, "!authorized");
		bidsValues[bid.nftAddress][bid.nftTokenID][_bidIndex].status = "Cancelled";

		emit CancelBidOffer(_bidIndex, bidToCancel.from, bid.nftAddress, bid.nftTokenID, "Cancelled");
	}

	/*************************************************************************************
	**	@notice Allow the owner of the NFT to accept the highest bid.
	**
	**	@dev This function will check if the bid is not executed yet and will try to take
	**		 the ERC20 from the bidder to execute the paiement. This will fail is the
	**		 bidder no longer has enough funds.
	**
	**	@param _bidCounter ID of the auction to bid on
	**	@param _bidIndex ID of the bid Offer to accept
	*************************************************************************************/
	function acceptBid(uint256 _bidCounter, uint256 _bidIndex) public {
		Bid memory bid = bids[_bidCounter];
		require(bid.status == "Open", "!open");
		require(bid.from == msg.sender, "!authorized");

		BidMemory memory bidToAccept = bidsValues[bid.nftAddress][bid.nftTokenID][_bidIndex];
		require(bidToAccept.status == "Open", "!open");
		require(bidToAccept.from != address(0), "!address0");
		require(bidToAccept.offer != 0, "!offer");

		bids[_bidCounter].status = "Executed";
		bidsValues[bid.nftAddress][bid.nftTokenID][_bidIndex].status = "Executed";

		//Compute the royalties for Bolero and the artist, and get the final amount
		//for the seller.
		uint256 royaltiesForBolero = IBoleroNFT(bid.nftAddress).royaltiesForBolero();
		uint256 royaltiesForArtist = IBoleroNFT(bid.nftAddress).getRoyalties(bid.nftTokenID);
		uint256 amountForBolero = bidToAccept.offer * royaltiesForBolero / 10000;
		uint256 amountForArtist = bidToAccept.offer * royaltiesForArtist / 10000;
		uint256 amountForSeller = bidToAccept.offer - (amountForBolero + amountForArtist);

		//Retrieve the address of the artist and the address of BoleroRewards to increment
		//their treasures.
		address artistPayment = IBoleroNFT(bid.nftAddress).artistPayment(bid.nftTokenID);

		//Transfering the bid to this contract
		require(IERC20(bid.wantAddress).transferFrom(bidToAccept.from, address(this), bidToAccept.offer));

		//Send the fees to Bolero and the Artist paiement contract. Sending the paiement to the seller
		require(IERC20(bid.wantAddress).transfer(rewards, amountForBolero));
		require(IERC20(bid.wantAddress).transfer(artistPayment, amountForArtist));
		require(IERC20(bid.wantAddress).transfer(bid.from, amountForSeller));

		lastSale[bid.nftAddress][bid.nftTokenID] = LastSale(3, _bidCounter, block.timestamp, bidToAccept.offer, bidToAccept.from, bid.wantAddress);

		//Send the nft to the buyer
		IERC721(bid.nftAddress).transferFrom(address(this), bidToAccept.from, bid.nftTokenID);
		IBoleroNFT(bid.nftAddress).setSecondaryMarketStatus(bid.nftTokenID);
		emit ExecuteBid(_bidCounter, bid.from, bidToAccept.from, bid.nftAddress, bid.wantAddress, bid.nftTokenID, bidToAccept.offer, "Executed");
	}

	function countBids(address _nftAddress, uint256 _nftTokenID) public view returns (uint256) {
		return (bidsEnum[_nftAddress][_nftTokenID]).length;
	}

	function countSellOffers(address _nftAddress, uint256 _nftTokenID) public view returns (uint256) {
		return (sellOffersEnum[_nftAddress][_nftTokenID]).length;
	}
	
	function countBuyOffers(address _nftAddress, uint256 _nftTokenID) public view returns (uint256) {
		return (buyOffersEnum[_nftAddress][_nftTokenID]).length;
	}
	
	function countOffersForBid(uint256 _bidCounter) public view returns (uint256) {
        Bid memory bid = bids[_bidCounter];
		return (bidsValues[bid.nftAddress][bid.nftTokenID]).length;
	}

	function getLastBid(address _nftAddress, uint256 _nftTokenID) public view returns (Bid memory) {
		uint256 numberOfBids = (bidsEnum[_nftAddress][_nftTokenID]).length;
		uint256 lastBidEnum = bidsEnum[_nftAddress][_nftTokenID][numberOfBids - 1];
		return bids[lastBidEnum];
	}

	function getLastSell(address _nftAddress, uint256 _nftTokenID) public view returns (Offer memory) {
        uint256 numberOfSells = (sellOffersEnum[_nftAddress][_nftTokenID]).length;
		uint256 lastSellEnum = sellOffersEnum[_nftAddress][_nftTokenID][numberOfSells - 1];
		return sellOffers[lastSellEnum];
	}
}

// File: contracts/BoleroNFTDeployer.sol



pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;



contract WithManagement {
    address public management = address(0);
    address public pendingManagement = address(0);
    address public rewards = address(0);

	modifier onlyManagement() {
		require(msg.sender == management, "!authorized");
		_;
	}
	modifier onlyPendingManagement() {
		require(msg.sender == pendingManagement, "!authorized");
		_;
	}

    event UpdateManagement(address indexed management);
    event UpdateRewards(address indexed rewards);

    /*******************************************************************************
	**	@notice
	**		Nominate a new address to use as management.
	**		The change does not go into effect immediately. This function sets a
	**		pending change, and the management address is not updated until
	**		the proposed management address has accepted the responsibility.
	**		This may only be called by the current management address.
	**	@param _management The address requested to take over the management.
	*******************************************************************************/
    function setManagement(address _management) public onlyManagement() {
		pendingManagement = _management;
	}

	/*******************************************************************************
	**	@notice
	**		Once a new management address has been proposed using setManagement(),
	**		this function may be called by the proposed address to accept the
	**		responsibility of taking over management for this contract.
	**		This may only be called by the proposed management address.
	**	@dev
	**		setManagement() should be called by the existing management address,
	**		prior to calling this function.
	*******************************************************************************/
    function acceptManagement() public onlyPendingManagement() {
		management = msg.sender;
		emit UpdateManagement(msg.sender);
	}

	/*******************************************************************************
	**	@notice
	**		Used to change the address of `rewards`.
	**		This may only be called by Management
	**	@param _rewards The new rewards address to use.
	*******************************************************************************/
    function setRewards(address _rewards) public onlyManagement() {
		rewards = _rewards;
		emit UpdateRewards(rewards);
	}
}

contract BoleroNFTDeployer is WithManagement {
	address public swap;
	address public nft;
    mapping (address => uint256) public artistsNonce; //Current collectionID for artist
    mapping (address => mapping (uint256 => address)) public collections;

    constructor(address _management, address _rewards, uint256 royalty) {
        management = _management;
        rewards = _rewards;
		swap = address(new BoleroNFTSwap(_management, _rewards));
        nft = address(new BoleroNFT("Bolero", "BOL", swap, royalty));
    }

	function name() external pure returns (string memory) {
        return "Bolero NFT Deployer";
	}
}