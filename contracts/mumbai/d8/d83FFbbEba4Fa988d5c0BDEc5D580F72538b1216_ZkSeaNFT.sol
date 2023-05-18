// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// contract with transaction func
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "Subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "Multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

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
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

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
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return functionCall(target, data, "low-level call failed");
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "low-level static call failed");
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionDelegateCall(
                target,
                data,
                "low-level delegate call failed"
            );
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
        require(isContract(target), "delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
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
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

    // Token URI
    //string private _tokenURI;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    struct nftdeails {
        string mintname;
        uint256 timeofmint;
        string nftowner;
        string description;
        uint256 copies;
    }

    mapping(uint256 => nftdeails) nftinfo;

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
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(
        address owner
    ) public view virtual override returns (uint256) {
        require(owner != address(0), "Balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(
        uint256 tokenId
    ) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Owner query for nonexistent token");
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
    // function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    //     require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    //     string memory baseURI = _baseURI();
    //     return bytes(baseURI).length > 0
    //         ? string(abi.encodePacked(baseURI, tokenId.toString()))
    //         : '';
    // }

    // /**
    //  * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
    //  * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
    //  * by default, can be overriden in child contracts.
    //  */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    mapping(uint256 => string) private _tokenURIs;

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

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

        return tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(
        uint256 tokenId,
        string memory _tokenURI
    ) internal virtual {
        require(_exists(tokenId), "URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "Not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(
        uint256 tokenId
    ) public view virtual override returns (address) {
        require(_exists(tokenId), "Query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) public view virtual override returns (bool) {
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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Not owner nor approved"
        );

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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "Non ERC721Receiver implementer"
        );
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        require(_exists(tokenId), "Query for nonexistent token");

        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "Non ERC721Receiver implementer"
        );
    }

    function mint(
        address to,
        uint256 tokenId,
        string memory _tokenURI,
        string memory _mintname,
        uint256 _timeperiod,
        string memory _nftowner,
        uint256 _copies,
        string memory description
    ) internal {
        _mint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        nftinfo[tokenId].mintname = _mintname;
        nftinfo[tokenId].timeofmint = _timeperiod;
        nftinfo[tokenId].nftowner = _nftowner;
        nftinfo[tokenId].copies = _copies;
        nftinfo[tokenId].description = description;
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "Mint to the zero address");
        require(!_exists(tokenId), "Token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        //require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "Transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

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
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, ERC721) returns (bool) {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "Owner index out of bounds");
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
    function tokenByIndex(
        uint256 index
    ) public view virtual override returns (uint256) {
        require(
            index < ERC721Enumerable.totalSupply(),
            "Global index out of bounds"
        );
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
    function _removeTokenFromOwnerEnumeration(
        address from,
        uint256 tokenId
    ) private {
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

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external;
}

interface ILayerZeroEndpoint {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint nativeFee, uint zroFee);
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(owner() == _msgSender(), "Caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
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

abstract contract NonblockingReceiver is ILayerZeroReceiver, Ownable {
    ILayerZeroEndpoint public endpoint;

    struct FailedMessages {
        uint payloadLength;
        bytes32 payloadHash;
    }

    mapping(uint16 => mapping(bytes => mapping(uint => FailedMessages)))
        public failedMessages;
    mapping(uint16 => bytes) public trustedRemoteLookup;

    event EndpointChanged(address newAddress);
    event TrustedRemoteSet(uint16 chainId, bytes trustedRemote);
    event MessageFailed(
        uint16 _srcChainId,
        bytes _srcAddress,
        uint64 _nonce,
        bytes _payload
    );

    function lzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) external override {
        require(msg.sender == address(endpoint)); // boilerplate! lzReceive must be called by the endpoint for security
        require(
            _srcAddress.length == trustedRemoteLookup[_srcChainId].length &&
                keccak256(_srcAddress) ==
                keccak256(trustedRemoteLookup[_srcChainId]),
            "Invalid source sending contract"
        );

        // try-catch all errors/exceptions
        // having failed messages does not block messages passing
        try this.onLzReceive(_srcChainId, _srcAddress, _nonce, _payload) {
            // do nothing
        } catch {
            // error / exception
            failedMessages[_srcChainId][_srcAddress][_nonce] = FailedMessages(
                _payload.length,
                keccak256(_payload)
            );
            emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload);
        }
    }

    function onLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) public {
        // only internal transaction
        require(msg.sender == address(this), "Caller must be Bridge.");

        // handle incoming message
        _LzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // abstract function
    function _LzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual;

    function _lzSend(
        uint16 _dstChainId,
        bytes memory _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _txParam
    ) internal {
        endpoint.send{value: msg.value}(
            _dstChainId,
            trustedRemoteLookup[_dstChainId],
            _payload,
            _refundAddress,
            _zroPaymentAddress,
            _txParam
        );
    }

    function retryMessage(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external payable {
        // assert there is message to retry
        FailedMessages storage failedMsg = failedMessages[_srcChainId][
            _srcAddress
        ][_nonce];
        require(
            failedMsg.payloadHash != bytes32(0),
            "NonblockingReceiver: no stored message"
        );
        require(
            _payload.length == failedMsg.payloadLength &&
                keccak256(_payload) == failedMsg.payloadHash,
            "LayerZero: invalid payload"
        );
        // clear the stored message
        failedMsg.payloadLength = 0;
        failedMsg.payloadHash = bytes32(0);
        // execute the message. revert if it fails again
        this.onLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    function setTrustedRemote(
        uint16 _chainId,
        bytes calldata _trustedRemote
    ) external onlyOwner {
        trustedRemoteLookup[_chainId] = _trustedRemote;

        emit TrustedRemoteSet(_chainId, _trustedRemote);
    }

    function setEndpoint(address _endpoint) external onlyOwner {
        endpoint = ILayerZeroEndpoint(_endpoint);

        emit EndpointChanged(_endpoint);
    }
}

contract ZkSeaNFT is ERC721Enumerable, NonblockingReceiver {
    using SafeMath for uint256;
    address devwallet;
    address treasuryWallet;

    struct collectioninfo {
        address collectionowner;
        bytes Cname;
        bytes Dname;
        bytes websiteURL;
        bytes description;
        bytes imghash;
        uint256 marketfees;
    }

    struct auction {
        uint256 time;
        uint256 minprice;
        bool inlist;
        uint256 biddingamount;
    }

    struct fixedsale {
        uint256 price;
        bool inlist;
    }

    uint256 public tokenidmint;
    uint public nextMintId;
    uint public maxMintId;

    uint256 public collectionform;
    uint256 public csdogefees = 2;
    uint256 public auctionfees = 20;
    uint256 public mintfee = 0;
    address _stackingContract;
    mapping(uint256 => fixedsale) nftprice;
    mapping(uint256 => uint256[]) public collectionstored;
    mapping(uint256 => collectioninfo) collection;
    mapping(address => uint256[]) public userinfo;
    mapping(address => uint256) public totalcollection;
    mapping(uint256 => uint256) public totalnft;
    uint256[] salenft;
    uint256[] auctionnft;
    mapping(uint256 => uint256) public salenftlist;
    mapping(uint256 => uint256) public auctionnftlist;
    mapping(uint256 => mapping(uint256 => uint256)) idnumber;
    mapping(uint256 => auction) timeforauction;
    mapping(uint256 => mapping(address => uint256)) amountforauction;
    mapping(uint256 => uint256) public nftcollectionid;
    mapping(uint256 => address) finalowner;
    mapping(string => bool) public stopduplicate;
    mapping(uint256 => address) public originalowner;
    string public baseURI = "/";

    uint256 gasForDestinationLzReceive = 350000;

    constructor(
        string memory name_,
        string memory symbol_,
        address _devwallet,
        address _endpoint,
        uint _startMintId,
        uint _endMintId
    ) ERC721(name_, symbol_) {
        devwallet = _devwallet;
        treasuryWallet = _devwallet;
        tokenidmint = _startMintId;
        maxMintId = _endMintId;
        endpoint = ILayerZeroEndpoint(_endpoint);
    }

    function create(
        uint256 collectionid,
        address to,
        string memory _tokenURI,
        string memory _mintname,
        string memory _nftowner,
        uint256 _copies,
        string memory description
    ) external payable {
        require(!stopduplicate[_tokenURI], "Token URI not allowed");
        require(tokenidmint < maxMintId, "ZkSeaNFT: max mint limit reached");

        tokenidmint += 1;
        uint256 timeperiod = block.timestamp;
        collectionstored[collectionid].push(tokenidmint);
        totalnft[collectionid] += 1;
        idnumber[collectionid][tokenidmint] = totalnft[collectionid] - 1;
        nftcollectionid[tokenidmint] = collectionid;
        originalowner[tokenidmint] = msg.sender;

        mint(
            to,
            tokenidmint,
            _tokenURI,
            _mintname,
            timeperiod,
            _nftowner,
            _copies,
            description
        );
        stopduplicate[_tokenURI] = true;
    }

    function createMulti(
        uint256 collectionid,
        address to,
        string memory _tokenURI,
        string memory _mintname,
        string memory _nftowner,
        uint256 _copies,
        string memory description,
        uint256 _times,
        uint256 _price
    ) external payable {
        for (uint256 i = 1; i <= _times; i++) {
            //require(!stopduplicate[_tokenURI],"value not allowed");
            require(
                tokenidmint < maxMintId,
                "ZkSeaNFT: max mint limit reached"
            );

            tokenidmint += 1;
            uint256 timeperiod = block.timestamp;
            collectionstored[collectionid].push(tokenidmint);
            totalnft[collectionid] += 1;
            idnumber[collectionid][tokenidmint] = totalnft[collectionid] - 1;
            nftcollectionid[tokenidmint] = collectionid;
            originalowner[tokenidmint] = msg.sender;
            mint(
                to,
                tokenidmint,
                _tokenURI,
                string(
                    abi.encodePacked(_mintname, " - ", uint2str(tokenidmint))
                ),
                timeperiod,
                _nftowner,
                _copies,
                description
            );

            //stopduplicate[_tokenURI]=true;
            if (_price != 0) fixedsales(tokenidmint, _price);
        }
    }

    // This function transfers the nft from your address on the
    // source chain to the same address on the destination chain
    function traverseChains(uint16 _chainId, uint256 _tokenId) public payable {
        require(
            msg.sender == ownerOf(_tokenId),
            "You must own the token to traverse"
        );
        require(
            trustedRemoteLookup[_chainId].length > 0,
            "This chain is currently unavailable for travel"
        );

        nftdeails storage nftInfo = nftinfo[_tokenId];
        uint256 collectionId = nftcollectionid[tokenidmint];

        // abi.encode() the payload with the values to send
        bytes memory payload = abi.encode(
            collectionId,
            msg.sender,
            tokenURI(_tokenId),
            nftInfo.mintname,
            nftInfo.timeofmint,
            nftInfo.nftowner,
            nftInfo.copies,
            nftInfo.description,
            _tokenId,
            originalowner[_tokenId]
        );

        burn(_tokenId);

        // encode adapterParams to specify more gas for the destination
        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(
            version,
            gasForDestinationLzReceive
        );

        // get the fees we need to pay to LayerZero + Relayer to cover message delivery
        // you will be refunded for extra gas paid
        (uint256 messageFee, ) = endpoint.estimateFees(
            _chainId,
            address(this),
            payload,
            false,
            adapterParams
        );

        require(msg.value >= messageFee, "Fees too low");

        endpoint.send{value: msg.value}(
            _chainId, // destination chainId
            trustedRemoteLookup[_chainId], // destination address of nft contract
            payload, // abi.encoded()'ed bytes
            payable(msg.sender), // refund address
            address(0x0), // 'zroPaymentAddress' unused for this
            adapterParams // txParameters
        );
    }

    function createcollection(
        string memory _Cname,
        string memory _Dname,
        string memory _wensiteURL,
        string memory _description,
        string memory _imghash,
        uint256 _marketfee
    ) external {
        require(!stopduplicate[_imghash], "value not allowed");
        collectionform += 1;
        collection[collectionform].collectionowner = msg.sender;
        collection[collectionform].Cname = bytes(_Cname);
        collection[collectionform].Dname = bytes(_Dname);
        collection[collectionform].websiteURL = bytes(_wensiteURL);
        collection[collectionform].description = bytes(_description);
        collection[collectionform].imghash = bytes(_imghash);
        collection[collectionform].marketfees = _marketfee;
        userinfo[msg.sender].push(collectionform);
        totalcollection[msg.sender] = collectionform;
        stopduplicate[_imghash] = true;
    }

    function deletecollection(uint256 _collectionid) external {
        require(msg.sender == devwallet, "not devwallet");

        delete userinfo[(collection[_collectionid].collectionowner)];
        delete totalcollection[(collection[_collectionid].collectionowner)];
        stopduplicate[string(collection[_collectionid].imghash)] = false;
        delete collection[_collectionid];
    }

    function fixedsales(uint256 tokenid, uint256 price) public {
        require(!timeforauction[tokenid].inlist, "already in sale");
        require(!nftprice[tokenid].inlist, "already in sale");
        require(ownerOf(tokenid) == msg.sender, "You are not owner");
        nftprice[tokenid].price = price;
        nftprice[tokenid].inlist = true;
        salenftlist[tokenid] = salenft.length;
        salenft.push(tokenid);

        address firstowner = ownerOf(tokenid);
        transferFrom(firstowner, address(this), tokenid);
    }

    function cancelfixedsale(uint256 tokenid) external {
        require(originalowner[tokenid] == msg.sender, "not owner");

        nftprice[tokenid].price = 0;
        nftprice[tokenid].inlist = false;
        _transfer(address(this), msg.sender, tokenid);
        delete salenft[(salenftlist[tokenid])];
    }

    function buynft(uint256 _collectionid, uint256 tokenid) external payable {
        require(nftprice[tokenid].inlist, "nft not in sale");
        uint256 val = uint256(100) - csdogefees;

        uint256 values = msg.value;
        require(values >= nftprice[tokenid].price, "price should be greater");
        uint256 amount = ((values * uint256(val)) / uint256(100));
        uint256 ownerinterest = values - amount;
        address firstowner = originalowner[tokenid];
        (bool success, ) = firstowner.call{value: amount}("");
        require(success, "refund failed");
        (bool csdoges, ) = treasuryWallet.call{value: ownerinterest}("");
        require(csdoges, "refund failed");
        _transfer(address(this), msg.sender, tokenid);
        nftinfo[tokenid].timeofmint = block.timestamp;
        changecollection(_collectionid, tokenid);
    }

    function changecollection(uint256 _collectionid, uint256 tokenid) internal {
        delete collectionstored[_collectionid][
            (idnumber[_collectionid][tokenid])
        ];
        collectionstored[(totalcollection[msg.sender])].push(tokenid);
        totalnft[(totalcollection[msg.sender])] += 1;
        idnumber[(totalcollection[msg.sender])][tokenid] =
            totalnft[(totalcollection[msg.sender])] -
            1;
        nftprice[tokenid].price = 0;
        nftprice[tokenid].inlist = false;
        nftcollectionid[tokenid] = totalcollection[msg.sender];
        originalowner[tokenid] = msg.sender;
        delete salenft[(salenftlist[tokenid])];
    }

    function startauction(
        uint256 tokenid,
        uint256 price,
        uint256 endday,
        uint256 endhours
    ) external {
        require(!timeforauction[tokenid].inlist, "already in sale");
        require(!nftprice[tokenid].inlist, "already in sale");
        require(ownerOf(tokenid) == msg.sender, "You are not owner");
        timeforauction[tokenid].time =
            block.timestamp +
            (endday * uint256(86400)) +
            (endhours * uint256(3600));
        timeforauction[tokenid].minprice = price;
        timeforauction[tokenid].inlist = true;
        auctionnftlist[tokenid] = auctionnft.length;
        auctionnft.push(tokenid);
        address firstowner = ownerOf(tokenid);
        transferFrom(firstowner, address(this), tokenid);
    }

    function buyauction(uint256 tokenid) external payable {
        require(timeforauction[tokenid].inlist, "nft not in sale");
        require(
            msg.value >= timeforauction[tokenid].minprice,
            "amount should be greater"
        );
        require(
            msg.value > timeforauction[tokenid].biddingamount,
            "previous bidding amount"
        );
        require(timeforauction[tokenid].time >= block.timestamp, "auction end");
        timeforauction[tokenid].biddingamount = msg.value;
        amountforauction[tokenid][msg.sender] = msg.value;
        finalowner[tokenid] = msg.sender;
        uint256 values = msg.value;
        (bool success, ) = address(this).call{value: values}("");
        require(success, "refund failed");
    }

    function claim(uint256 collectionid, uint256 tokenid) external {
        require(timeforauction[tokenid].inlist, "nft not in sale");
        require(
            timeforauction[tokenid].time < block.timestamp,
            "auction not end"
        );
        uint256 val = uint256(100) - csdogefees;
        if (finalowner[tokenid] == msg.sender) {
            uint256 totalamount = timeforauction[tokenid].biddingamount;
            uint256 amount = ((totalamount * uint256(val)) / uint256(100));
            uint256 ownerinterest = ((totalamount * uint256(csdogefees)) /
                uint256(100));
            address firstowner = originalowner[tokenid];
            (bool success, ) = firstowner.call{value: amount}("");
            require(success, "refund failed");
            (bool csdoges, ) = treasuryWallet.call{value: ownerinterest}("");
            require(csdoges, "refund failed");
            _transfer(address(this), msg.sender, tokenid);
            changeauctioncollection(collectionid, tokenid);
        } else {
            require(
                amountforauction[tokenid][msg.sender] > 0,
                "You dont allow"
            );
            uint256 totalamount = amountforauction[tokenid][msg.sender];
            uint256 amount = ((totalamount * uint256(val)) / uint256(100));
            uint256 ownerinterest = ((totalamount * uint256(auctionfees)) /
                uint256(100));
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "refund failed");
            (bool csdoges, ) = treasuryWallet.call{value: ownerinterest}("");
            require(csdoges, "refund failed");
            amountforauction[tokenid][msg.sender] = 0;
        }
    }

    function changeauctioncollection(
        uint256 _collectionid,
        uint256 tokenid
    ) internal {
        delete collectionstored[_collectionid][
            (idnumber[_collectionid][tokenid])
        ];
        collectionstored[(totalcollection[msg.sender])].push(tokenid);
        totalnft[(totalcollection[msg.sender])] += 1;
        idnumber[(totalcollection[msg.sender])][tokenid] =
            totalnft[(totalcollection[msg.sender])] -
            1;
        timeforauction[tokenid].minprice = 0;
        timeforauction[tokenid].biddingamount = 0;
        timeforauction[tokenid].inlist = false;
        originalowner[tokenid] = msg.sender;
        timeforauction[tokenid].time = 0;
        finalowner[tokenid] = address(0);
        nftcollectionid[tokenid] = totalcollection[msg.sender];
        delete auctionnft[(auctionnftlist[tokenid])];
    }

    function upgradeauction(uint256 tokenid, bool choice) external payable {
        require(timeforauction[tokenid].time >= block.timestamp, "auction end");
        uint256 val = uint256(100) - auctionfees;
        if (choice) {
            amountforauction[tokenid][msg.sender] += msg.value;
            if (
                amountforauction[tokenid][msg.sender] >
                timeforauction[tokenid].biddingamount
            ) {
                timeforauction[tokenid].biddingamount = msg.value;
                finalowner[tokenid] = msg.sender;
                uint256 values = msg.value;
                (bool success, ) = address(this).call{value: values}("");
                require(success, "refund failed");
            }
        } else {
            if (finalowner[tokenid] != msg.sender) {
                require(
                    amountforauction[tokenid][msg.sender] > 0,
                    "You dont allow"
                );
                uint256 totalamount = amountforauction[tokenid][msg.sender];
                uint256 amount = ((totalamount * uint256(val)) / uint256(100));
                uint256 ownerinterest = ((totalamount * uint256(auctionfees)) /
                    uint256(100));
                (bool success, ) = msg.sender.call{value: amount}("");
                require(success, "refund failed");
                (bool csdoges, ) = treasuryWallet.call{value: ownerinterest}(
                    ""
                );
                require(csdoges, "refund failed");
                amountforauction[tokenid][msg.sender] = 0;
            }
        }
    }

    function removesfromauction(uint256 tokenid) external {
        require(originalowner[tokenid] == msg.sender, "Not originalowner");
        timeforauction[tokenid].minprice = 0;
        timeforauction[tokenid].biddingamount = 0;
        timeforauction[tokenid].inlist = false;
        timeforauction[tokenid].time = 0;
        _transfer(address(this), msg.sender, tokenid);
        delete auctionnft[(auctionnftlist[tokenid])];
    }

    function burnorinalnft(uint256 _collectionid, uint256 tokenid) external {
        require(msg.sender == devwallet, "not devwallet");
        delete collectionstored[_collectionid][
            (idnumber[_collectionid][tokenid])
        ];
        originalowner[tokenid] = address(0);
        stopduplicate[(tokenURI(tokenid))] = false;
        _burn(tokenid);
    }

    function changecsdogefees(uint256 fees) external {
        require(msg.sender == devwallet, "not devwallet");
        csdogefees = fees;
    }

    function changeauctionreturnamountfees(uint256 fees) external {
        require(msg.sender == devwallet, "not devwallet");
        auctionfees = fees;
    }

    function setstackingContract(address _address) external {
        require(msg.sender == devwallet, "not devwallet");
        _stackingContract = _address;
    }

    function withdrawbnb(uint256 amount) external {
        require(msg.sender == devwallet, "not devwallet");
        (bool success, ) = devwallet.call{value: amount}("");
        require(success, "refund failed");
    }

    function nftauctionend(
        uint256 tokenid
    ) external view returns (bool auctionnftbool) {
        require(timeforauction[tokenid].time <= block.timestamp, "auction end");
        if (finalowner[tokenid] != address(0)) {
            return true;
        }
    }

    function collectionnft(
        uint256 collectionid
    ) external view returns (uint[] memory) {
        return (collectionstored[collectionid]);
    }

    function totalcollectiondetails() external view returns (uint[] memory) {
        return userinfo[msg.sender];
    }

    function auctiondetail(
        uint256 tokenid
    ) external view returns (uint256, address) {
        return (timeforauction[tokenid].biddingamount, finalowner[tokenid]);
    }

    function timing(uint256 tokenid) external view returns (uint256) {
        if (timeforauction[tokenid].time >= block.timestamp) {
            return (timeforauction[tokenid].time - block.timestamp);
        } else {
            return uint256(0);
        }
    }

    function collectiondetails(
        uint256 id
    )
        external
        view
        returns (
            uint256,
            address,
            string memory,
            string memory,
            string memory,
            string memory,
            string memory,
            uint256
        )
    {
        string memory Cname = string(collection[id].Cname);
        string memory Dname = string(collection[id].Dname);
        string memory URL = string(collection[id].websiteURL);
        string memory description = string(collection[id].description);
        string memory imghash = string(collection[id].imghash);
        uint256 value = id;
        uint256 fees = collection[value].marketfees;
        address collectionowners = collection[value].collectionowner;

        return (
            value,
            collectionowners,
            Cname,
            Dname,
            URL,
            description,
            imghash,
            fees
        );
    }

    function listofsalenft(
        uint256 tokenid
    )
        external
        view
        returns (uint256[] memory, uint256[] memory, uint256, uint256)
    {
        return (
            salenft,
            auctionnft,
            timeforauction[tokenid].minprice,
            nftprice[tokenid].price
        );
    }

    function nftinformation(
        uint256 id
    )
        external
        view
        returns (
            uint256,
            string memory,
            uint256,
            string memory,
            uint256,
            string memory,
            string memory,
            uint256,
            address
        )
    {
        uint256 value = id;
        return (
            id,
            nftinfo[id].mintname,
            nftinfo[id].timeofmint,
            nftinfo[id].nftowner,
            nftinfo[value].copies,
            nftinfo[value].description,
            tokenURI(value),
            nftcollectionid[value],
            ownerOf(value)
        );
    }

    function setBaseURI(string memory _baseURI) external {
        require(msg.sender == devwallet, "not devwallet");
        baseURI = _baseURI;
    }

    function setDevWallet(address _devWallet) external {
        require(msg.sender == devwallet, "not devwallet");
        devwallet = _devWallet;
    }

    function setTreasuryWallet(address _treasury) external {
        require(msg.sender == devwallet, "not devwallet");
        treasuryWallet = _treasury;
    }

    function setMintFeeInWei(uint256 _fee) external {
        require(msg.sender == devwallet, "not devwallet");
        mintfee = _fee;
    }

    receive() external payable {}

    function burn(uint256 tokenId) private {
        require(_exists(tokenId), "Token does not exist");

        nftcollectionid[tokenId] = 0;
        originalowner[tokenId] = address(0);
        _setTokenURI(tokenId, "");
        nftinfo[tokenId].mintname = "";
        nftinfo[tokenId].timeofmint = 0;
        nftinfo[tokenId].nftowner = "";
        nftinfo[tokenId].copies = 0;
        nftinfo[tokenId].description = "";
        _burn(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }

        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }

        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + (j % 10)));
            j /= 10;
        }
        str = string(bstr);
    }

    function _LzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal override {
        (
            uint256 collectionId,
            address to,
            string memory _tokenURI,
            string memory _mintname,
            uint256 timeofmint,
            string memory _nftowner,
            uint256 _copies,
            string memory description,
            uint256 _tokenId,
            address originalOwner
        ) = abi.decode(
                _payload,
                (
                    uint256,
                    address,
                    string,
                    string,
                    uint256,
                    string,
                    uint256,
                    string,
                    uint256,
                    address
                )
            );

        collectionstored[collectionId].push(_tokenId);
        totalnft[collectionId] += 1;
        idnumber[collectionId][_tokenId] = totalnft[collectionId] - 1;
        nftcollectionid[_tokenId] = collectionId;
        originalowner[_tokenId] = originalOwner;

        mint(
            to,
            tokenidmint,
            _tokenURI,
            _mintname,
            timeofmint,
            _nftowner,
            _copies,
            description
        );
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }
}