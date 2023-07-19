/**
 *Submitted for verification at polygonscan.com on 2023-07-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface LandSource {
    function tiles(uint256 tokenId) external returns(int128 t,uint256 mint_log,bool exists);
}

interface UsingService {
     function landUsing(uint256 landId) external view returns(bool);
}


/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
abstract contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    virtual  public returns (bytes4);
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
/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
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
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
abstract contract Governance {

    address _governance;

    constructor() {
        _governance = tx.origin;
    }

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyGovernance {
        require(msg.sender == _governance, "not governance");
        _;
    }

    function setGovernance(address governance)  public  onlyGovernance
    {
        require(governance != address(0), "new governance the zero address");
        emit GovernanceTransferred(_governance, governance);
        _governance = governance;
    }
}

abstract contract Extend {

    address _extender;

    constructor() {
        _extender = tx.origin;
    }

    modifier onlyExtender {
        require(msg.sender == _extender, "not governance");
        _;
    }
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
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, Governance {
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

    address public transMsg = address(0x0);

    event postMsg(address processor, uint256 tokenid, address totarget);

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

       if( transMsg != address(0x0) )
        { 
            (bool success, ) = transMsg.call(abi.encodeWithSelector(bytes4(keccak256("postTransfer(uint256,address)")),tokenId,to));
            if( success )
                emit postMsg(transMsg, tokenId, to);
        }
        
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

    /**
     * @dev Send message to post which token transferred.
     * @param implement address function to process when be transferred
     */
    function setTransImplement(address implement) public onlyGovernance {
        transMsg = implement;
    }

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    using SafeMath for uint256;
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    struct Zone {
        uint256[] tiles;
        uint256 sum;
        bool exists;
    }



    struct Tile {
        bool enable;
        //uint256 leasetime;
        //uint256 expire;
        bool inzone;
        bool exists;
    }

    mapping(uint256 => Tile) public tiles;
    mapping(uint256 => Zone) public zones;



    mapping(uint256 => address) public land_owner;

    address[] private LandService;
    mapping(uint256 => uint256) private LandServiceIndex;
    event LeaseStart( address from, address to, uint256 tokenid, uint256 expire );

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
    /*
        if( from != address(0x0) && tiles[tokenId].expire == 0 )
        {
            tiles[tokenId].expire = tiles[tokenId].leasetime + block.timestamp;
            tiles[tokenId].enable = true;
            emit LeaseStart(from, to, tokenId, tiles[tokenId].expire);
        }
        else if( from != address(0x0) && tiles[tokenId].expire < block.timestamp )
        {  
            if( to != address(0x0) ){
               require( tiles[tokenId].expire != 0, "Setting Lease time is needed"); 
            }
            require( msg.sender == land_owner[tokenId], "Lease time-up,only landowner can transfer");
        }
    */

        require( !checkUsingState(tokenId) , "Using state is true, not allow transfer");
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

    /**
     * @dev Gets the list of token IDs of the requested owner.
     * @param _owner address owning the tokens
     * @return uint256[] List of token IDs owned by the requested address
     */
    function _tokensOfOwner(address _owner) internal view returns(uint256[] memory) {

        uint256 _tokenCount = balanceOf(_owner);
    
        uint256[] memory _tokens = new uint256[](_tokenCount);
        for (uint256 i = 0; i < _tokenCount; i++) {
            _tokens[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return _tokens;
    }

    
    function addLandService(address serviceaddr) public onlyGovernance {
        LandServiceIndex[LandService.length] = LandService.length;
        LandService.push(serviceaddr);
    }

    function totalLandServices() public view returns (uint256) {
        return LandService.length;
    }

    function LandServiceByIndex(uint256 index) public view returns (address) {
        require(index < totalLandServices(), "LandService index out of bounds");
        return LandService[index];
    }

    function removeLandService(uint256 index) public onlyGovernance {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).
        uint256 lastSrvndex = LandService.length.sub(1);
        uint256 landIndex =  LandServiceIndex[index];
        LandService[ index ] = LandService[lastSrvndex ];
        LandServiceIndex[ lastSrvndex ] = landIndex;
        delete LandServiceIndex[index];
        LandService.pop();
    }

    function checkUsingState(uint256 landId) public view returns (bool) 
    {     
        bool use_state;
        uint arrayLen = LandService.length;
        for (uint256 i = 0; i < arrayLen; ++i) {
            UsingService usrv = UsingService(LandService[i]);
            use_state =  use_state || usrv.landUsing(landId);
        } 
        return use_state;
    }

}

abstract contract ERC721Metadata is ERC721Enumerable {

    // Base URI
    string private _baseURI_;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Optional mapping for token Properties
    mapping(uint256 => uint256) private _tokenProperties;

       /**
     * @dev Returns the URI for a given token ID. May return an empty string.
     *
     * If the token's URI is non-empty and a base URI was set (via
     * {_setBaseURI}), it will be added to the token ID's URI as a prefix.
     *
     * Reverts if the token ID does not exist.
     */
    function tokenURI_site(uint256 tokenId) internal view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // Even if there is a base URI, it is only appended to non-empty token-specific URIs
        if (bytes(_tokenURI).length == 0) {
            return "";
        } else {
            // abi.encodePacked is being used to concatenate strings
            return string(abi.encodePacked(_baseURI_, _tokenURI )); 
        }
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     *
     * Reverts if the token ID does not exist.
     *
     * TIP: if all token IDs share a prefix (e.g. if your URIs look like
     * `http://api.myproject.com/token/<id>`), use {_setBaseURI} to store
     * it and save gas.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI}.
     *
     * _Available since v2.5.0._
     */
    function _setBaseURI(string memory baseURI_) internal {
        _baseURI_ = baseURI_;
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a preffix in {tokenURI} to each token's URI, when
    * they are non-empty.
    *
    * _Available since v2.5.0._
    */
    function baseURI() external view returns (string memory) {
        return _baseURI_;
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use _burn(uint256) instead.
     * @param tokenId uint256 ID of the token being burned by the msg.sender
     */
    function _burnToken(uint256 tokenId) internal {
        super._burn(tokenId);
        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
            delete _tokenProperties[tokenId];
        }
    } 


    /**
     * @dev set the token Properties for a given token.
     *
     * Reverts if the token ID does not exist.
     *
     */
    function _setTokenProperties(uint256 tokenId, uint256 _data) internal {
        require(_exists(tokenId), "ERC721Metadata: Properties set of nonexistent token");
        _tokenProperties[tokenId] = _data;
    }  

}



interface IERC20Token {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

interface ERC721nft {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
}

interface Extendnft {
    function getExtend(uint256 tokenId) external view returns (uint256 rightsId,uint256 second, uint256 deadline);
    function burn(uint256 tokenId) external;
}

interface ITokenId
{
    function transferFrom(uint256 from_id, uint256 to_id, uint256 value) external returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address);
    function approve(uint256 tokenId, address spender, uint256 amount) external returns (bool);    
}

interface IMetaId
{
    function tokenmap(string memory symbol) external view returns (address);    
}

contract AlphaZone is ERC721Metadata, Extend {
   
    using SafeMath for uint256;
    using Strings for uint256;

    address public landNft = address(0x0);
    address public idNft = address(0x0);
    address public extendContract = address(0x0);
    uint256[] private _allNft;

    uint256 public _tokenIds = 1;
    string constant nftId_title = "Housing";

    // Mapping from NFT-id to position in the allNft array
    mapping(uint256 => uint256) private _allNftIndex;

    event NFTReceived(address operator, address from, uint256 tokenId, bytes data);
    event ClaimBack(address nftaddress, uint256 tokenId, address owner);

    struct District {
        string name;
        address submit;
        uint256 sum;
        uint256 ext;
        uint256 reserve;
        uint256 count;
        uint256 mintstart;
        uint256 expiry;
        string buildhash;
        uint256 builderid;
        uint256 unitcost;
        uint256[] distrilist;
        bool exists;
    }

    struct Housing {
        string name;
        address builder;
        uint256 sum;
        string buildhash;
        uint256 hid;
    }

    uint256 public total_dist = 0;

    mapping(string => District) public districts;
    mapping(string => uint256[]) distriready;
    mapping(string => uint256[]) distriminted;
    mapping(uint256 => string) public agreenow;
    mapping(uint256 => Housing) public housings;

    address public metaid_contract = address(0x0);
    string external_url = "";
    string collect_description = "";
    string metaverse_name = "";

    bytes constant svgEnd = hex"3c2f7376673e";
    bytes constant svgHead = hex"3c73766720786d6c6e733d27687474703a2f2f7777772e77332e6f72672f323030302f7376672720786d6c6e733a786c696e6b3d27687474703a2f2f7777772e77332e6f72672f313939392f786c696e6b272077696474683d2735303027206865696768743d27353030272076696577426f783d273020302035303020353030273e";
    bytes constant defsHead = hex"3c646566733e";   // </defs>
    bytes constant defsEnd = hex"3c2f646566733e";  // </defs>
    bytes backimage = hex"";
    bytes linearGradient = hex"";
    bytes defsGeneral = hex"";
    string public constant PAY_TOKEN = "XLIT";

    constructor() ERC721("Xhousing", "XHO") {
        
        metaverse_name = "Lofitown";
        external_url = "https://lofitown.world/";
        collect_description = "The housing asset created by builder and land owner in metaverse";
    
        defsGeneral = bytes.concat( defsHead,
            abi.encodePacked(
                '<style>.a{fill:#fff;}.b{fill:none;stroke:#d9c8db;stroke-miterlimit:10;stroke-width:2px;}.c,.d,.e,.f,.g,.h,.i,.j,.k,.l,.m,.n,.o{isolation:isolate;}.c,.d,.e,.f,.g,.i,.j,.k{font-size:55px;}.c,.e{fill:#e96b5d;}.c,.d,.e,.f,.g,.k{font-family:LustDisplay-Didone, Lust Didone;}.d,.f{fill:#9b4a8d;}.e{letter-spacing:0.02em;}.f{letter-spacing:0.02em;}.g{fill:#9b4a8c;}.h{font-size:45px;fill:#0cb6ea;font-family:Lust-Italic, Lust;font-style:italic;}.i,.k{fill:#50ae58;}.i,.j{font-family:Lust-Regular, Lust;letter-spacing:0.05em;}.j{fill:#ef8916;}.l,.m{font-size:32px;}.l,.n{font-family:Arial-BoldMT, Arial;font-weight:700;}.m,.o{font-family:ArialMT, Arial; margin-left: auto; margin-right: auto; width: 40%;}.n{font-size:20px;fill:#a2743d;}.o{font-size:18px;}.p{font-size:36px;fill:#17489d;font-weight:600;}</style>'
            ),
            defsEnd
        );
    
        linearGradient = bytes.concat( defsHead,
            abi.encodePacked(
            "<linearGradient id='gradient_id' x1='100%' y1='100%'><stop offset='0%' stop-color='#5cc83a' stop-opacity='0.85' /><stop offset='100%' stop-color='#5bc8ff' stop-opacity='0.85' /></linearGradient>"
            ),
            defsEnd
        );  

        backimage =  abi.encodePacked("<g transform='translate(50,100) scale(1,1)' fill='#888888' stroke='none'><path d='M 173.4 20.3 C 158.6 29.6 138.6 42.3 129 48.4 C 119.4 54.5 102.1 65.4 90.5 72.7 C 61.3 91.3 59.2 92.6 53.2 96.1 L 48 99.3 L 48 197.7 L 48 296.1 L 71 296.1 L 94 296.1 L 94 210.7 L 94 125.4 L 103.3 119.4 C 108.3 116.1 127.4 103.8 145.5 92.1 C 163.7 80.4 183.3 67.7 189.1 64 C 194.9 60.2 200 57.1 200.4 57.1 C 200.8 57.1 210 62.9 220.8 69.9 C 231.6 77 243.7 84.8 247.5 87.3 C 253.5 91.1 266 99.2 299.2 120.8 L 306 125.2 L 306.2 210.4 L 306.5 295.6 L 329.3 295.9 L 352 296.1 L 352 197.6 L 352 99.1 L 347.8 96.5 C 345.4 95 341.3 92.4 338.5 90.6 C 335.8 88.9 322.3 80.3 308.5 71.6 C 294.8 62.9 281.3 54.4 278.5 52.6 C 275.8 50.9 269 46.6 263.5 43.2 C 258 39.8 246.5 32.5 238 27 C 229.5 21.6 220.3 15.8 217.5 14.1 C 214.8 12.4 209.8 9.3 206.4 7.2 L 200.4 3.3 L 173.4 20.3 Z M 173 231.1 L 173 296.1 L 200.5 296.1 L 228 296.1 L 227.8 231.3 L 227.5 166.6 L 200.3 166.3 L 173 166.1 L 173 231.1 Z'/></g>"); 
    

    }

    function setLandContract(address _landnft) public onlyGovernance {
        landNft = _landnft;
    }

    function setIdContract(address _IDnft) public onlyGovernance {
        idNft = _IDnft;
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public returns (bytes4) 
    {
        if( msg.sender == landNft)
        {
            land_owner[tokenId] = operator;
            _addNft( tokenId );

            /*
            if( data.length > 0 )
            {
                (uint256 sec, bool en) = abi.decode(data, (uint256, bool));
                lease_mint( from, tokenId, sec, en);
            }
            else{
                lease_mint( from, tokenId, 0, false);
            }
            */

            LandSource r =  LandSource(landNft);
            (,,bool exists) =  r.tiles(tokenId);
            tiles[tokenId] = Tile(true, false, exists); 


        }
        // from, operator maybe orginal NFT holder
        emit NFTReceived(operator, from, tokenId, data);
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    
    function compare(string memory str1, string memory str2) internal pure returns (bool) {
        if (bytes(str1).length != bytes(str2).length) {
            return false;
        }
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }
    
    function mint( uint256 landid , string memory zone_name, uint256 unitcost, uint256 payerid) public
    {
        //require(tiles[landid].exists, "landid invalid");
        //require(land_owner[landid]==msg.sender, "land owner invalid");
        require(compare(agreenow[landid],zone_name),"landid not agree");
        require(districts[zone_name].unitcost == unitcost,"cost error");

        uint256 mint_count =0;
        for (uint j; j< distriminted[zone_name].length;j++)
        {
            if (distriminted[zone_name][j] == landid )
            {
                mint_count += 1;
            }  
        }
        require(mint_count < districts[zone_name].ext, "landid has minted");

        distriminted[zone_name].push(landid);

        uint256 newTokenId = districts[zone_name].mintstart;
        _mint(msg.sender, newTokenId);
        districts[zone_name].mintstart = newTokenId + 1;

        housings[newTokenId] = Housing( zone_name, districts[zone_name].submit, districts[zone_name].sum, districts[zone_name].buildhash, mint_count+1 );

        IMetaId _metaaddr = IMetaId(metaid_contract);
        ITokenId _contract = ITokenId(_metaaddr.tokenmap(PAY_TOKEN));
        require( msg.sender == _contract.ownerOf(payerid), "tx source invalid");        
        _contract.transferFrom(payerid, districts[zone_name].builderid, unitcost);

    }

    function activeZone(string memory zone_name, string memory buildinghash, uint256 builderid ) public 
    {   
        require( districts[zone_name].submit == msg.sender, "submit invalid");
        require( bytes(buildinghash).length != 0, "buildinghash invalid");
        require( agree_rate(zone_name) > 50, "agree rate invalid");

        districts[zone_name].mintstart = _tokenIds;
        _tokenIds +=  districts[zone_name].count;
        districts[zone_name].buildhash = buildinghash;
        districts[zone_name].builderid = builderid;
    }

    function TEST_1() public
    {
        uint256[] memory alist = new uint256[](4);
        alist[0] = 100;
        alist[1] = 101;
        alist[2] = 102;
        alist[3] = 103;
        proposalZone("Skysea", alist ,4, 2, 3, 1692407206, 4000000000000000000);
        agree(100, "Skysea");
        agree(101, "Skysea");
        agree(102, "Skysea");
        activeZone("Skysea", "a1b2c3d4e5", 5 );

        proposalZone("Nouse", alist ,4, 2, 3, 1692407206, 4000000000000000000);
    }

    function TEST_2() public
    {
        mint( 100, "Skysea", 4000000000000000000, 1 );
    }


    function proposalZone(string memory zone_name, uint256[] memory tokenIds, uint256 sum, uint256 ext, uint256 reserve, uint256 expiry, uint256 unitcost ) public 
    {
        //distriname[next_dist] = zone_name;
        //next_dist = next_dist + 1;
        require(!districts[zone_name].exists, "name was exists");
        require( expiry > block.timestamp, "expiry invalid");
        require( ext <= 3, "ext number invalid");
        require( reserve < sum, "reserve number invalid");

        districts[zone_name] = District( zone_name, msg.sender, sum, ext, reserve, (sum*ext+reserve), 0, expiry, "", 0, unitcost, tokenIds, true);
        total_dist = total_dist + 1;

    } 

    function get_distri(string memory zone_name) public view returns(string memory name,address sumbit,uint256 sum,bool exists){

        return ( districts[zone_name].name, districts[zone_name].submit, districts[zone_name].sum, districts[zone_name].exists);
    }

    function minted(string memory zone_name) public view returns(uint256[] memory)
    {
       uint len = distriminted[zone_name].length;
       uint256[] memory m_minted = new uint256[](len);
           
       for(uint256 j; j< len;j++)
       {
         m_minted[j] = distriminted[zone_name][j];
       }
       return m_minted;
    }

    function distrilist(string memory zone_name) public view returns(uint256[] memory){
       uint len = districts[zone_name].distrilist.length;
       uint256[] memory list = new uint256[](len);
           
       for(uint256 j; j< len;j++)
       {
         list[j] = districts[zone_name].distrilist[j];
       }
       return list;
    }

    function ready(string memory zone_name) public view returns(uint256[] memory){
       uint len = distriready[zone_name].length;
       uint256[] memory nowready = new uint256[](len);
           
       for(uint256 j; j< len;j++)
       {
         nowready[j] = distriready[zone_name][j];
       }
       return nowready;
    }
    
    /**
     * @dev The percentage rate of land agree by owner
     */
    function agree_rate(string memory zone_name) public view returns(uint256){
       uint256 sum = districts[zone_name].distrilist.length;
       uint256 r = distriready[zone_name].length;
       return r.mul(100).div(sum);
    }

    function agree(uint256 landid, string memory zone_name ) public
    {
        //require(tiles[landid].exists, "landid invalid");
        //require(land_owner[landid]==msg.sender, "land owner invalid");
        if( bytes(agreenow[landid]).length != 0)
        {
            string memory lastname = agreenow[landid];
            for (uint j; j< distriready[lastname].length;j++)
            {
                if (distriready[lastname][j] == landid )
                {
                  //delete distriready[lastname][j];
                  distriready[lastname][j] = distriready[lastname][distriready[lastname].length - 1];
                  distriready[lastname].pop();
                   break;
                }  
            }
        }

        bool list_in = false;
        for (uint i; i< districts[zone_name].distrilist.length;i++)
        {
          if (districts[zone_name].distrilist[i] == landid )
          {
              distriready[zone_name].push(landid);
              agreenow[landid] = zone_name;
              list_in = true;
          }  
        }
        require( list_in==true, "invalid landid");
    }


    
    /**
     * @dev Gets the list of token IDs of the requested owner.
     * @param owner address owning the tokens
     * @return uint256[] List of token IDs owned by the requested address
     */
    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        return _tokensOfOwner(owner);
    }

    function setBaseURI(string memory baseURI) public onlyGovernance {
        _setBaseURI(baseURI);
    }
    
    function setExtendContract(address _contract) public onlyExtender {
        extendContract = _contract;
    }

    function section_3_fill() private pure returns (bytes memory) {
         return abi.encodePacked('<rect fill="url(#gradient_id)" width="500" height="500"/>');
    }

   function section_4_text(uint256 id) private view returns (bytes memory) {
         return 
         abi.encodePacked(
                    '<text class="n"><tspan class="n" text-anchor="middle" x="50%" y="42%">',
                    '</tspan></text><text transform="translate(60 90)" font-size="18" font-family="ArialMT, Arial">',
                    '<tspan text-anchor="middle" x="37.5%" y="300">',
                    housings[id].buildhash,
                    '</tspan>',
                    '<tspan class="l" text-anchor="middle" x="37.5%" y="80">',
                    housings[id].name,
                    '</tspan>',
                    '<tspan class="l" text-anchor="middle" x="37.5%" y="150">',                    
                    housings[id].hid.toString(),
                    '</tspan><tspan class="l" text-anchor="middle" x="37.5%" y="220">',
                    metaverse_name                                        
        );
    }

   function section_5_text() private pure returns (bytes memory) {
         return 
         abi.encodePacked(                                        
                    '</tspan><tspan class="p" text-anchor="middle" x="190" y="0">',
                    'Housing ownership',
                    '</tspan><tspan class="n" text-anchor="center" x="0" y="40">',
                    
                    '</tspan><tspan text-anchor="middle" x="37.5%" y="270">',
                    'Housing hash',
                    ':</tspan></text>'
        );
    }

    function Get_Pattern() private pure returns(bytes memory)
    {
        return abi.encodePacked("<path></path>");
    }

   /**
     * @notice Generate SVG by index
     */
    function generateSVG(uint256 id) private view returns (bytes memory) 
    {
        return
            bytes.concat( 
                svgHead,
                defsGeneral,   // Text define of svg
                linearGradient,  // Color define  of svg
                backimage,  // Bottm-layer ( Back image )
                section_3_fill(),  // Bottm-layer ( Back Fill color )
                Get_Pattern(),     
                section_4_text(id),  // Top-layer ( Text )                
                section_5_text(),  // Top-layer ( Text )
                svgEnd
            );
    }


    /**
     * @notice Generate SVG, b64 encode it, construct an ERC721 token URI.
     */
    function constructTokenURI(uint256 id)
        private
        view
        returns (string memory)
    { 

        string memory pageSVG = Base64.encode(bytes(generateSVG(id)));
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked( 
                             '{"name":"',
                                nftId_title,
                                " #", id.toString(),
                                '", "description":"',collect_description,'',
                                '", "external_url":"',external_url,'",',
                                '"attributes": [',
                                getAllTraits(id),
                                '],"image":"',
                                "data:image/svg+xml;base64,",
                                pageSVG,
                                '"}'
                            )
                        )
                    )
                )
            );
    }


    /**
     * @notice Receives json from constructTokenURI
     */
    function tokenURI(uint256 tokenId) public override view returns (string memory) {
        require(_exists(tokenId), "tokenId does not exist");

        return constructTokenURI(tokenId);
    }

    /**
     * @dev Gets the token ID at a given index of all the NFT in this contract
     * Reverts if the index is greater or equal to the total number of NFT.
     * @param index uint256 representing the index to be accessed of the NFT list
     * @return uint256 token ID at the given index of the NFT list
     */
    function nftByIndex(uint256 index) public view returns (uint256) {
        require(index < totalLANDs(), "ERC721: global index out of bounds");
        return _allNft[index];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param nftId uint256 ID of the token to be removed from the tokens list
     */
    function _removeNft(uint256 nftId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastNftIndex = _allNft.length.sub(1);
        uint256 NftIndex = _allNftIndex[nftId];

        uint256 lastNftId = _allNft[lastNftIndex];

        _allNft[NftIndex] = lastNftId; 
        _allNftIndex[lastNftId] = NftIndex; 

        delete _allNftIndex[nftId];
        _allNft.pop();
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addNft(uint256 tokenId) private {
        _allNftIndex[tokenId] = _allNft.length;
        _allNft.push(tokenId);
    }
    
    /**
     * @dev Gets the total amount of NFT stored by the contract.
     * @return uint256 representing the total amount of NFT
     */
    function totalLANDs() public view returns (uint256) {
        return _allNft.length;
    }

    function claim_back(uint256 tokenId) external 
    {
      //  if( tiles[tokenId].expire == 0 || tiles[tokenId].expire < block.timestamp )
      //  {
              require( msg.sender == land_owner[tokenId] , "Invalid Land owner");
      //  }
      //  else{
      //          require(
      //              _isApprovedOrOwner(_msgSender(), tokenId),
      //              "caller is not token owner nor approved"
      //          );
      //  }

        _removeNft( tokenId );
        ERC721nft _landNft =  ERC721nft(landNft);
        _landNft.safeTransferFrom( address(this), land_owner[tokenId], tokenId );
        
        land_owner[tokenId] = address(0x0);
        
        emit ClaimBack(land_owner[tokenId], tokenId, msg.sender );

    }

    function currentTimeStamp() public view returns (uint256) {
        return block.timestamp;
    }

    function setMetaIdAddress( address _metaaddr ) external onlyGovernance
    {
        metaid_contract = _metaaddr;
    }

    function setCollection(string memory _url, string memory _desc) public onlyGovernance {
         external_url = _url;
         collect_description = _desc;
    }

    function getTrait(string memory thisTrait, string memory thisValue) internal pure returns ( bytes memory )
    {
        return abi.encodePacked(' {"trait_type": "',thisTrait,'", "value": "',thisValue,'"}');
    } 

    function getAllTraits(uint256 tokenId) internal view returns ( bytes memory )
    {
        bytes memory split = hex"2c";
        bytes memory now_trait_1 = getTrait( "metaverse", metaverse_name);
        bytes memory now_trait_2 = getTrait( "housing name", housings[tokenId].name);
        bytes memory now_trait_3 = getTrait( "housing id", housings[tokenId].hid.toString());
        bytes memory now_trait_4 = getTrait( "housing hash", housings[tokenId].buildhash);
        return bytes.concat(now_trait_1,split,now_trait_2,split,now_trait_3,split,now_trait_4);
    }

}