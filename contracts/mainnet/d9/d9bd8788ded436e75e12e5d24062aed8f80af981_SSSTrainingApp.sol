/**
 *Submitted for verification at polygonscan.com on 2022-04-28
*/

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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

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
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

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

// File: NGonToken.sol



/*
 AN   NN    NN        GGGGGG    OOOOOO   NN    NN           w:  https://ngon.tech
      NNN   NN       GG    GG  OO    OO  NNN   NN           tw: @ngondomforreal
      NNNN  NN  ---- GG        OO    OO  NNNN  NN    
      NN  NNNN  ---- GG  GGGG  OO    OO  NN  NNNN
      NN   NNN       GG    GG  OO    OO  NN   NNN
      NN    NN        GGGGGG    OOOOOO   NN    NN  PROJECT
*/

//This token has a max hold amount of 1% of Total Supply and a max transaction size of 0.5% of Total Supply

pragma solidity >=0.8.0 <0.9.0;





contract NGonToken is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    address public devWallet;
    address public managementWallet;
    address public lotteryWallet;
    bool public isPaused;

    uint8 private _decimals;

    uint8 private dFee;    
    uint8 private mFee;
    uint8 private lFee;

    mapping (address => bool) isExemptFromFees;
    mapping (address => bool) isTeamWallet;

    uint private maxSupply;

    constructor (
        string memory _setName,
        string memory _setSymbol,
        uint _supply,
        uint8 _setDecimals
        ) {
        _name = _setName;
        _symbol = _setSymbol;
        _decimals = _setDecimals;
        maxSupply = _supply * 10**_decimals;
        devWallet = owner();
        isExemptFromFees[owner()] = true;
        _mint(owner(), maxSupply);
    }

//onlyOwner() funcs
//Standard set fees function - Capped - when setting: 10 == 1% to allow for percentages to decimal places
    function setFees(uint8 _dFee, uint8 _mFee, uint8 _lFee) public onlyOwner {
        require((_dFee + _mFee + _lFee) <= 50, "Fees cannot exceed 5%");
        dFee = _dFee;
        mFee = _mFee;
        lFee = _lFee;
    }

    function setDevWallet(address _address) public onlyOwner {
        require (devWallet != _address, "This address is already the Dev Wallet");
        if (!isExemptFromFees[_address]) {
            isExemptFromFees[_address] = true;
        }
        devWallet = _address;
    }

    function setManagementWallet(address _address) public onlyOwner {
        require (managementWallet != _address, "This address is already the management Wallet");
        if (!isExemptFromFees[_address]) {
            isExemptFromFees[_address] = true;
        } 
        managementWallet = _address;
    }

    function setLottoWallet(address _address) public onlyOwner {
        require (lotteryWallet != _address, "This address is already the management Wallet");
        if (!isExemptFromFees[_address]) {
            isExemptFromFees[_address] = true;
        } 
        lotteryWallet = _address;
    }

//Pauses transfers
    function setPause(bool _bool) public onlyOwner {
        require(isPaused != _bool, "isPaused already matches that state");
        isPaused = _bool;
    }
//Adds team wallet with fee exemption
    function addTeamWallet(address _address) public onlyOwner {
        require(!isTeamWallet[_address], "Address already registered as a Team Wallet");
        if (!isExemptFromFees[_address]) {
        isExemptFromFees[_address] = true;
        }
        isTeamWallet[_address] = true;
    }

    function removeTeamWallet(address _address) public onlyOwner {
        require(isTeamWallet[_address], "Address already not currently registered as a Team Wallet");
        removeFeeExemption(_address);
        isTeamWallet[_address] = false;
    }

    function setExemptFromFees(address _address) public onlyOwner {
        require(!isExemptFromFees[_address], "Address is already exempt");
        isExemptFromFees[_address] = true;
    }

    function removeFeeExemption(address _address) public onlyOwner {
        require(_address != owner(), "Owner cannot be removed");
        require(_address != devWallet, "DevWallet cannot be removed. Change DevWallet address first");
        require(_address != managementWallet, "Management Wallet cannot be removed. Change managementWallet address first");
        
        isExemptFromFees[_address] = false; 
    }

//Gets the tax amounts for each normal transaction
    function getTaxAmount(uint256 _amount) private view returns (uint, uint, uint, uint){
        uint _dFee = (_amount * dFee) / 1000;
        uint _mFee = (_amount * mFee) / 1000;
        uint _lFee = (_amount * lFee) / 1000;
        uint _tAmount = _amount - (_dFee + _mFee + _lFee);
        return (_tAmount, _dFee, _mFee, _lFee);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

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

// transfer function to account for fees
    function _transferNormal(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= maxSupply / 200, "Tx amount cant be more than 0.5% of total supply");
        
            (uint _tAmount, uint _dFee, uint _mFee, uint _lFee) = getTaxAmount(amount);
            require(_balances[recipient] + _tAmount <= maxSupply / 100, "Cant hold more than 1% of maxSupply");

            uint256 senderBalance = _balances[sender];
            require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
            unchecked {
                _balances[sender] = senderBalance - amount;
            }
            _balances[recipient] += _tAmount;
            _balances[devWallet] += _dFee;
            _balances[managementWallet] += _mFee;
            _balances[lotteryWallet] += _lFee;

            emit Transfer(sender, recipient, _tAmount);
            emit Transfer(sender, devWallet, _dFee);
            emit Transfer(sender, managementWallet, _mFee);
            emit Transfer(sender, lotteryWallet, _lFee);
    }

//Added transfer function for sending to wallets with no max hold limits
    function _transferNoFees(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

// Means of retrieval in case of tokens being sent to contract
    function withdrawToken(IERC20 token, uint256 amount) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "Contract has no balance");
        require(token.transfer(owner(), amount), "Transfer failed");
    }

    function withdrawEth(address payable _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

// Adapted transfer call to cater for fee exemptions
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(!isPaused, "Transfers are paused, check official announcements for info");
        require(balanceOf(_msgSender()) >= amount, "You don't have enough balance to transfer that amount");
            if (isExemptFromFees[_msgSender()] || isExemptFromFees[recipient]) {
                _transferNoFees(_msgSender(), recipient, amount);
            } else {
                _transferNormal(_msgSender(), recipient, amount);
            }
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(!isPaused, "Transfers are paused, check official announcements for info");
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        if (isExemptFromFees[sender] || isExemptFromFees[recipient]) {
                _transferNoFees(sender, recipient, amount);
        } else {
                _transferNormal(sender, recipient, amount);
            }
      return true;
    }

    function renounceOwnership() public view override onlyOwner {
        revert("cannot renounceOwnership here");
    }

// Public Views

    function checkIfFeeExempt(address _address) public view returns (bool) {
        return isExemptFromFees[_address];
    }

    function checkIfTeam(address _address) public view returns (bool) {
        return isTeamWallet[_address];
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function lottoBalance() public view returns (uint256) {
        return balanceOf(lotteryWallet);
    }

    function fees() public view returns (uint8) {
        uint8 _fees = (dFee + lFee) + mFee;
        return (_fees);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
 
    receive() external payable {}
}
// File: rgltoken.sol



/*
 w:  https://retrogameslibrary.co.uk
 tw: @retrogamelib
*/

//This token has a max hold amount of 1% of Total Supply and a max transaction size of 0.5% of Total Supply

pragma solidity >=0.8.0 <0.9.0;





contract RGLToken is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    address public devWallet;
    address public managementWallet;
    address public communityWallet;
    bool public isPaused;

    uint8 private _decimals;

    uint8 private dFee = 50;    
    uint8 private rFee = 30;
    uint8 private cFee = 20;

    mapping (address => bool) isExemptFromFees;
    mapping (address => bool) isTeamWallet;

    mapping (address => bool) admin;

    uint private maxSupply;

    constructor (
        string memory _setName,
        string memory _setSymbol,
        uint _supply,
        uint8 _setDecimals
        ) {
        _name = _setName;
        _symbol = _setSymbol;
        _decimals = _setDecimals;
        maxSupply = _supply * 10**_decimals;
        devWallet = owner();
        isExemptFromFees[owner()] = true;
    }

    modifier isAdmin() {
        require(admin[_msgSender()], "Caller is not Admin");
        _; 
    }

//onlyOwner() funcs
//Standard set fees function - Capped - when setting: 10 == 1% to allow for percentages to decimal places
    function setFees(uint8 _dFee, uint8 _rFee, uint8 _cFee) public onlyOwner {
        require((_dFee + _rFee + _cFee) <= 100, "Fees cannot exceed 10%");
        dFee = _dFee;
        rFee = _rFee;
        cFee = _cFee;
    }

    function setDevWallet(address _address) public onlyOwner {
        require (devWallet != _address, "This address is already the Dev Wallet");
        if (!isExemptFromFees[_address]) {
            isExemptFromFees[_address] = true;
        }
        devWallet = _address;
    }

    function setManagementWallet(address _address) public onlyOwner {
        require (managementWallet != _address, "This address is already the management Wallet");
        if (!isExemptFromFees[_address]) {
            isExemptFromFees[_address] = true;
        } 
        managementWallet = _address;
    }

    function setComWallet(address _address) public onlyOwner {
        require (communityWallet != _address, "This address is already the management Wallet");
        if (!isExemptFromFees[_address]) {
            isExemptFromFees[_address] = true;
        } 
        communityWallet = _address;
    }

//Pauses transfers
    function setPause(bool _bool) public onlyOwner {
        require(isPaused != _bool, "isPaused already matches that state");
        isPaused = _bool;
    }
//Adds team wallet with fee exemption
    function addTeamWallet(address _address) public onlyOwner {
        require(!isTeamWallet[_address], "Address already registered as a Team Wallet");
        if (!isExemptFromFees[_address]) {
        isExemptFromFees[_address] = true;
        }
        isTeamWallet[_address] = true;
    }

    function removeTeamWallet(address _address) public onlyOwner {
        require(isTeamWallet[_address], "Address already not currently registered as a Team Wallet");
        removeFeeExemption(_address);
        isTeamWallet[_address] = false;
    }

    function setAdmin(address _address) public onlyOwner {
        require(!isTeamWallet[_address], "Address already registered as admin");
        if (!isExemptFromFees[_address]) {
        isExemptFromFees[_address] = true;
        }
        admin[_address] = true;
    }

    function removeAdmin(address _address) public onlyOwner {
        require(isTeamWallet[_address], "Address already not currently registered as admin");
        removeFeeExemption(_address);
        admin[_address] = false;
    }

    function setExemptFromFees(address _address) public onlyOwner {
        require(!isExemptFromFees[_address], "Address is already exempt");
        isExemptFromFees[_address] = true;
    }

    function removeFeeExemption(address _address) public onlyOwner {
        require(_address != owner(), "Owner cannot be removed");
        require(_address != devWallet, "DevWallet cannot be removed. Change DevWallet address first");
        require(_address != managementWallet, "Management Wallet cannot be removed. Change managementWallet address first");
        
        isExemptFromFees[_address] = false; 
    }

//Gets the tax amounts for each normal transaction
    function getTaxAmount(uint256 _amount) private view returns (uint, uint, uint, uint){
        uint _dFee = (_amount * dFee) / 1000;
        uint _rFee = (_amount * rFee) / 1000;
        uint _cFee = (_amount * cFee) / 1000;
        uint _tAmount = _amount - (_dFee + _rFee + _cFee);
        return (_tAmount, _dFee, _rFee, _cFee);
    }

    function mint(address account, uint256 amount) public isAdmin {
        require(_totalSupply + amount <= maxSupply, "You cannot mint more than the max supply");
        _mint(account, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

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

// transfer function to account for fees
    function _transferNormal(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= maxSupply / 200, "Tx amount cant be more than 0.5% of total supply");
        
            (uint _tAmount, uint _dFee, uint _rFee, uint _cFee) = getTaxAmount(amount);
            require(_balances[recipient] + _tAmount <= maxSupply / 100, "Cant hold more than 1% of maxSupply");

            uint256 senderBalance = _balances[sender];
            require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
            unchecked {
                _balances[sender] = senderBalance - amount;
            }
            _balances[recipient] += _tAmount;
            _balances[devWallet] += _dFee;
            _balances[managementWallet] += _rFee;
            _balances[communityWallet] += _cFee;

            emit Transfer(sender, recipient, _tAmount);
            emit Transfer(sender, devWallet, _dFee);
            emit Transfer(sender, managementWallet, _rFee);
            emit Transfer(sender, communityWallet, _cFee);
    }

//Added transfer function for sending to wallets with no max hold limits
    function _transferNoFees(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

// Means of retrieval in case of tokens being sent to contract
    function withdrawToken(IERC20 token, uint256 amount) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "Contract has no balance");
        require(token.transfer(owner(), amount), "Transfer failed");
    }

    function withdrawEth(address payable _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

// Adapted transfer call to cater for fee exemptions
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(!isPaused, "Transfers are paused, check official announcements for info");
        require(balanceOf(_msgSender()) >= amount, "You don't have enough balance to transfer that amount");
            if (isExemptFromFees[_msgSender()] || isExemptFromFees[recipient]) {
                _transferNoFees(_msgSender(), recipient, amount);
            } else {
                _transferNormal(_msgSender(), recipient, amount);
            }
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(!isPaused, "Transfers are paused, check official announcements for info");
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        if (isExemptFromFees[sender] || isExemptFromFees[recipient]) {
                _transferNoFees(sender, recipient, amount);
        } else {
                _transferNormal(sender, recipient, amount);
            }
      return true;
    }

    function renounceOwnership() public view override onlyOwner {
        revert("cannot renounceOwnership here");
    }

// Public Views

    function checkIfFeeExempt(address _address) public view returns (bool) {
        return isExemptFromFees[_address];
    }

    function checkIfTeam(address _address) public view returns (bool) {
        return isTeamWallet[_address];
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function communityBalance() public view returns (uint256) {
        return balanceOf(communityWallet);
    }

    function fees() public view returns (uint8) {
        uint8 _fees = (dFee + cFee) + rFee;
        return (_fees);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
 
    receive() external payable {}
}
// File: player.sol



/* Sensible Superstars is a Retro Games Library project
   W: https://retrogameslibrary.co.uk/
   T: https://twitter.com/retrogamelib
  */

pragma solidity >=0.7.0 <0.9.0;


abstract contract SSSPlayers is Ownable {

  struct Player {
    string name;
    string nationality;
    uint rating;
    uint maxRating;
  }

  Player[] internal player;
    
    
  mapping (address => string) public teamName;
  mapping (string => bool) public teamNameExists;
  string[] names;
  string[] nationalities;

  uint public trainingFee = 1 ether;
  uint8 maxTrainingSessions = 64;

  function checkPlayerBio(uint _playerId) public view returns (string memory, string memory, uint, uint) {
    uint id = _playerId - 1;
    return (player[id].name, player[id].nationality, player[id].rating, player[id].maxRating);
  }

  function addNames(string[] memory _names) public onlyOwner {
    for(uint i = 0; i < _names.length; i++){
    names.push(_names[i]);
    }
  }

  function addNations(string[] memory _nationalities) public onlyOwner {
    for(uint i = 0; i < _nationalities.length; i++){
    nationalities.push(_nationalities[i]);
    }
  }

  function setTraingFee(uint _fee) public onlyOwner {
    trainingFee = _fee;
  }

}
// File: sensimain.sol



/* Sensible Superstars is a Retro Games Library project
   W: https://retrogameslibrary.co.uk/
   T: https://twitter.com/retrogamelib
  */

pragma solidity >=0.7.0 <0.9.0;




contract SensiSuperstars is SSSPlayers, ERC721Enumerable {
  using Strings for uint256;

  string baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 3 ether;
  uint256 public maxSupply = 10000;
  uint8 public maxSquadCount = 14;
  bool public paused = false;
  uint rInsert;
  uint8 private baseMod = 25;
  uint8 private baseModAddition = 10;
  uint public teamNamingCost = 1 ether;

  RGLToken public rglTokenAddress;
  uint public rglRqd4Dscnt;

  bool public trainingEnabled;

  mapping (address => bool) admin;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    RGLToken _rglTknAdrs
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    admin[address(this)] = true;
    admin[msg.sender] = true;
    rglTokenAddress = _rglTknAdrs;
    rglRqd4Dscnt = 11000 * 10**rglTokenAddress.decimals();
  }

  // internal
  modifier isAdmin() {
    require(admin[_msgSender()], "Caller is not Admin");
        _; 
  }
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  
  function randomiser(uint _modulus) internal returns (uint) {
	rInsert++;
	return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, rInsert))) %  _modulus;
  }

  // public
  function mint(uint8 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused, "Contract is currently paused");
    require(_mintAmount > 0, "Mint amount must be more than zero");
    require(supply + _mintAmount <= maxSupply, "Not enough players left to mint! You'll have to go on Opensea or the Transfer Market");
    require(maxSquadCount >= balanceOf(msg.sender) + _mintAmount, "Your squad can't have more than 14 players");
   
    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintAmount, "Not enough MATIC to mint a new player. Check the cost and try again");
    }
    for (uint256 i = 1; i <= _mintAmount; i++) {
      uint randInitRating = (randomiser(baseMod) + baseModAddition);
      uint maxRating = randInitRating + maxTrainingSessions;
      string memory name = names[randomiser(names.length)];
      string memory nationality = nationalities[randomiser(nationalities.length)];

      _safeMint(msg.sender, supply + i);
      player.push(Player(name, nationality, randInitRating, maxRating));
    }
  }


  function mintWithToken(uint8 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused, "Contract is currently paused");
    require(_mintAmount > 0, "Mint amount must be more than zero");
    require(supply + _mintAmount <= maxSupply, "Not enough players left to mint! You'll have to go on Opensea or the Transfer Market");
    require(maxSquadCount >= balanceOf(msg.sender) + _mintAmount, "Your squad can't have more than 14 players");
    uint8 dec = rglTokenAddress.decimals();
    uint tokensToMint = (_mintAmount * 1000) * 10**dec;
    
    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintAmount, "Not enough MATIC to mint a new player. Check the cost and try again");
    }
    for (uint256 i = 1; i <= _mintAmount; i++) {
      uint randInitRating = (randomiser(baseMod) + baseModAddition);
      uint maxRating = randInitRating + maxTrainingSessions;
      string memory name = names[randomiser(names.length)];
      string memory nationality = nationalities[randomiser(nationalities.length)];

      _safeMint(msg.sender, supply + i);
      player.push(Player(name, nationality, randInitRating, maxRating));
    }

    rglTokenAddress.mint(msg.sender, tokensToMint);
    rglTokenAddress.mint(owner(), tokensToMint); // 50% of each NFT sale goes to RGL Token liquidity
  }


  function checkSquadIds(address _owner)
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

  function trainPlayer(uint _playerId) public isAdmin {
    require(trainingEnabled, "Training is not currently active");
    require(player[_playerId].rating < player[_playerId].maxRating, "Player is already the best version of themselves! Good work!");
    uint playerId = _playerId - 1;
    
    player[playerId].rating++;
  }

  function checkTrainingFeeForPlayer(uint _playerId) public view returns (uint) {
    uint playerId = _playerId - 1;
    uint rglBalance = rglTokenAddress.balanceOf(msg.sender);
    uint trainingFeeToPay;
    if (player[playerId].rating <= 85) {
      trainingFeeToPay = trainingFee;
    } else if (player[playerId].rating > 85) {
      trainingFeeToPay = trainingFee * 2;
    }

    if (rglBalance >= rglRqd4Dscnt) {
      trainingFeeToPay = trainingFeeToPay / 2;
    }

    return trainingFeeToPay;
  }

  function setTeamName(string memory name) public payable {
    require (!teamNameExists[name], "That Team Name exists already! Try something a little more unique");
    require (balanceOf(_msgSender()) >= 11, "You do not own enough Player Nfts to create a team! 11 or more required");
    if (msg.sender != owner()) {
      require(msg.value >= teamNamingCost, "Not enough MATIC to name your team. Check the cost and try again");
    }
    teamName[_msgSender()] = name;
    teamNameExists[name] = true;
  }

  function teamRating(address _owner) public view returns (uint) {
    uint[] memory ownedIds = checkSquadIds(_owner);
    uint _tRating;
    for (uint i = 0; i < ownedIds.length; i++) {
      _tRating += player[i].rating;
    }
    uint _fRating = _tRating / 11;
    return _fRating;
  }

  //only owner
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setTeamNamingCost(uint256 _newCost) public onlyOwner {
    teamNamingCost = _newCost;
  }

  function setRGLRqd4Dscnt(uint amount) public onlyOwner {
    uint8 dec = rglTokenAddress.decimals();
    rglRqd4Dscnt = amount * 10**dec;
  }

  function setTrainingEnabled(bool _enabled) public onlyOwner {
    trainingEnabled = _enabled;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function setBaseModBMAddMaxTrain(uint8 base, uint8 bMAddition, uint8 maxTrain) public onlyOwner {
    baseMod = base;
    baseModAddition = bMAddition;
    maxTrainingSessions = maxTrain;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
   }

  function withdrawToken(IERC20 token, uint256 amount) external onlyOwner {
    uint256 balance = token.balanceOf(address(this));
    require(balance > 0, "Contract has no balance");
    require(token.transfer(owner(), amount), "Transfer failed");
  }

  function setRetroglAddress(RGLToken _retrogl) public onlyOwner {
    rglTokenAddress = _retrogl;
  }

  function setAdmin(address newAdmin) public onlyOwner {
    admin[newAdmin] = true;
  }

  function removeAdmin(address adminAddress) public onlyOwner {
    admin[adminAddress] = false;
  }

//Overrides
  function renounceOwnership() public view override onlyOwner {
        revert("cannot renounceOwnership here");
    }


  function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) {
        //solhint-disable-next-line max-line-length
        require(maxSquadCount >= balanceOf(to) + 1, "Your squad can't have more than 14 players");

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
    ) public virtual override(ERC721, IERC721) {
        require(maxSquadCount >= balanceOf(to) + 1, "Your squad can't have more than 14 players");
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
    ) public virtual override(ERC721, IERC721) {
        require(maxSquadCount >= balanceOf(to) + 1, "Your squad can't have more than 14 players");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }
}

// File: sensisstraining.sol



/* Sensible Superstars is a Retro Games Library project
   W: https://retrogameslibrary.co.uk/
   T: https://twitter.com/retrogamelib
*/

pragma solidity >=0.7.0 <0.9.0;






contract SSSTrainingApp is Ownable {

    RGLToken public rglTokenAddress;
    SensiSuperstars public sensiSSNFT;
    NGonToken public ngonAddress;

    mapping (address => bool) admin;

    mapping (address => uint) public trainingSessions;
    mapping (address => uint) timeLock;
    uint256 public ngonReqdForBonus = 5000;
    uint8 public freeTrainingSessions = 2; //Claimable every 3 days
    uint8 public minPlayersForFreeTraining = 7;

    constructor (
        RGLToken rglAddress,
        SensiSuperstars sssAddress,
        NGonToken ngonTokAddress
    ){
        rglTokenAddress = rglAddress;
        sensiSSNFT = sssAddress;
        ngonAddress = ngonTokAddress;
    }

    modifier isAdmin() {
    require(admin[_msgSender()], "Caller is not Admin");
        _; 
  }

    function trainPlayerPaid(uint _playerId) public payable {
        uint trainingFeeToPay = sensiSSNFT.checkTrainingFeeForPlayer(_playerId);
        require(msg.value >= trainingFeeToPay, "You need to pay the correct training fee");
    
        sensiSSNFT.trainPlayer(_playerId);
    }

    function trainPlayerFree(uint _playerId) public {
        require(trainingSessions[msg.sender] > 0, "You do not have any training sessions available. Claim, pay or wait a few days!");
        trainingSessions[msg.sender] = trainingSessions[msg.sender] - 1;
        sensiSSNFT.trainPlayer(_playerId);
    }

    function awardTrainingSessions(address receiver, uint8 amount) public isAdmin {
        require(amount <= 10, "Maximum amount is set to 10 to prevent error. Send multiple times if you need to send more");
        trainingSessions[receiver] += amount;
    }

    function claimTrainingSessions() public {
        require(sensiSSNFT.balanceOf(msg.sender) >= minPlayersForFreeTraining, "You do not own enough players to qualify for free training sessions");
        require(rglTokenAddress.balanceOf(msg.sender) >= sensiSSNFT.rglRqd4Dscnt(), "You do not own enough RGL Token to earn free training sessions");
        if (timeLock[msg.sender] != 0) {   
            require(block.timestamp >= timeLock[msg.sender] + 3 days,  "You can only claim once every 3 days!");
        }
    
        uint8 amount = freeTrainingSessions;
        if (ngonAddress.balanceOf(msg.sender) >= ngonReqdForBonus * 10**ngonAddress.decimals()) {
            amount++;
        }
        trainingSessions[msg.sender] += amount;

        if (timeLock[msg.sender] == 0) {
            timeLock[msg.sender] = block.timestamp + 3 days;
        } else {
        timeLock[msg.sender] = timeLock[msg.sender] + 3 days;
        }
    }

    function setFreeTrainingSessions(uint8 amount) public onlyOwner {
        freeTrainingSessions = amount;
    }

    function withdrawToken(IERC20 token, uint256 amount) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "Contract has no balance");
        require(token.transfer(owner(), amount), "Transfer failed");
    }

    function withdrawEth(address payable _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }

    function setAdmin(address _address) public onlyOwner {
        require(!admin[_address], "Address already registered as admin");
        admin[_address] = true;
    }

    function removeAdmin(address _address) public onlyOwner {
        require(admin[_address], "Address already not currently registered as admin");
        admin[_address] = false;
    }

    function renounceOwnership() public view override onlyOwner {
        revert("cannot renounceOwnership here");
    }

    function setNgonRqdForBonus(uint amount) public onlyOwner {
        ngonReqdForBonus = amount;
    }

    function setMinPlayersForFreeTraining(uint8 minAmount) public onlyOwner {
        minPlayersForFreeTraining = minAmount;
    }

}