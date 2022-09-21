/**
 *Submitted for verification at polygonscan.com on 2022-09-20
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC721/[email protected]


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


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/token/ERC721/[email protected]


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


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/math/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}


// File @openzeppelin/contracts/utils/math/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Checkpoints.sol)
pragma solidity ^0.8.0;


/**
 * @dev This library defines the `History` struct, for checkpointing values as they change at different points in
 * time, and later looking up past values by block number. See {Votes} as an example.
 *
 * To create a history of checkpoints define a variable type `Checkpoints.History` in your contract, and store a new
 * checkpoint for the current transaction block using the {push} function.
 *
 * _Available since v4.5._
 */
library Checkpoints {
    struct Checkpoint {
        uint32 _blockNumber;
        uint224 _value;
    }

    struct History {
        Checkpoint[] _checkpoints;
    }

    /**
     * @dev Returns the value in the latest checkpoint, or zero if there are no checkpoints.
     */
    function latest(History storage self) internal view returns (uint256) {
        uint256 pos = self._checkpoints.length;
        return pos == 0 ? 0 : self._checkpoints[pos - 1]._value;
    }

    /**
     * @dev Returns the value at a given block number. If a checkpoint is not available at that block, the closest one
     * before it is returned, or zero otherwise.
     */
    function getAtBlock(History storage self, uint256 blockNumber) internal view returns (uint256) {
        require(blockNumber < block.number, "Checkpoints: block not yet mined");

        uint256 high = self._checkpoints.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (self._checkpoints[mid]._blockNumber > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high == 0 ? 0 : self._checkpoints[high - 1]._value;
    }

    /**
     * @dev Pushes a value onto a History so that it is stored as the checkpoint for the current block.
     *
     * Returns previous value and new value.
     */
    function push(History storage self, uint256 value) internal returns (uint256, uint256) {
        uint256 pos = self._checkpoints.length;
        uint256 old = latest(self);
        if (pos > 0 && self._checkpoints[pos - 1]._blockNumber == block.number) {
            self._checkpoints[pos - 1]._value = SafeCast.toUint224(value);
        } else {
            self._checkpoints.push(
                Checkpoint({_blockNumber: SafeCast.toUint32(block.number), _value: SafeCast.toUint224(value)})
            );
        }
        return (old, value);
    }

    /**
     * @dev Pushes a value onto a History, by updating the latest value using binary operation `op`. The new value will
     * be set to `op(latest, delta)`.
     *
     * Returns previous value and new value.
     */
    function push(
        History storage self,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) internal returns (uint256, uint256) {
        return push(self, op(latest(self), delta));
    }
}


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/cryptography/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ├À 2 + 1, and for v in (302): v Ôêê {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}


// File @openzeppelin/contracts/governance/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}


// File @openzeppelin/contracts/governance/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (governance/utils/Votes.sol)
pragma solidity ^0.8.0;





/**
 * @dev This is a base abstract contract that tracks voting units, which are a measure of voting power that can be
 * transferred, and provides a system of vote delegation, where an account can delegate its voting units to a sort of
 * "representative" that will pool delegated voting units from different accounts and can then use it to vote in
 * decisions. In fact, voting units _must_ be delegated in order to count as actual votes, and an account has to
 * delegate those votes to itself if it wishes to participate in decisions and does not have a trusted representative.
 *
 * This contract is often combined with a token contract such that voting units correspond to token units. For an
 * example, see {ERC721Votes}.
 *
 * The full history of delegate votes is tracked on-chain so that governance protocols can consider votes as distributed
 * at a particular block number to protect against flash loans and double voting. The opt-in delegate system makes the
 * cost of this history tracking optional.
 *
 * When using this module the derived contract must implement {_getVotingUnits} (for example, make it return
 * {ERC721-balanceOf}), and can use {_transferVotingUnits} to track a change in the distribution of those units (in the
 * previous example, it would be included in {ERC721-_beforeTokenTransfer}).
 *
 * _Available since v4.5._
 */
abstract contract Votes is IVotes, Context, EIP712 {
    using Checkpoints for Checkpoints.History;
    using Counters for Counters.Counter;

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => address) private _delegation;
    mapping(address => Checkpoints.History) private _delegateCheckpoints;
    Checkpoints.History private _totalCheckpoints;

    mapping(address => Counters.Counter) private _nonces;

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) public view virtual override returns (uint256) {
        return _delegateCheckpoints[account].latest();
    }

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotes(address account, uint256 blockNumber) public view virtual override returns (uint256) {
        return _delegateCheckpoints[account].getAtBlock(blockNumber);
    }

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber) public view virtual override returns (uint256) {
        require(blockNumber < block.number, "Votes: block not yet mined");
        return _totalCheckpoints.getAtBlock(blockNumber);
    }

    /**
     * @dev Returns the current total supply of votes.
     */
    function _getTotalSupply() internal view virtual returns (uint256) {
        return _totalCheckpoints.latest();
    }

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) public view virtual override returns (address) {
        return _delegation[account];
    }

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) public virtual override {
        address account = _msgSender();
        _delegate(account, delegatee);
    }

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= expiry, "Votes: signature expired");
        address signer = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry))),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), "Votes: invalid nonce");
        _delegate(signer, delegatee);
    }

    /**
     * @dev Delegate all of `account`'s voting units to `delegatee`.
     *
     * Emits events {DelegateChanged} and {DelegateVotesChanged}.
     */
    function _delegate(address account, address delegatee) internal virtual {
        address oldDelegate = delegates(account);
        _delegation[account] = delegatee;

        emit DelegateChanged(account, oldDelegate, delegatee);
        _moveDelegateVotes(oldDelegate, delegatee, _getVotingUnits(account));
    }

    /**
     * @dev Transfers, mints, or burns voting units. To register a mint, `from` should be zero. To register a burn, `to`
     * should be zero. Total supply of voting units will be adjusted with mints and burns.
     */
    function _transferVotingUnits(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (from == address(0)) {
            _totalCheckpoints.push(_add, amount);
        }
        if (to == address(0)) {
            _totalCheckpoints.push(_subtract, amount);
        }
        _moveDelegateVotes(delegates(from), delegates(to), amount);
    }

    /**
     * @dev Moves delegated votes from one delegate to another.
     */
    function _moveDelegateVotes(
        address from,
        address to,
        uint256 amount
    ) private {
        if (from != to && amount > 0) {
            if (from != address(0)) {
                (uint256 oldValue, uint256 newValue) = _delegateCheckpoints[from].push(_subtract, amount);
                emit DelegateVotesChanged(from, oldValue, newValue);
            }
            if (to != address(0)) {
                (uint256 oldValue, uint256 newValue) = _delegateCheckpoints[to].push(_add, amount);
                emit DelegateVotesChanged(to, oldValue, newValue);
            }
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Consumes a nonce.
     *
     * Returns the current value and increments nonce.
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }

    /**
     * @dev Returns an address nonce.
     */
    function nonces(address owner) public view virtual returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev Returns the contract's {EIP712} domain separator.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev Must return the voting units held by an account.
     */
    function _getVotingUnits(address) internal view virtual returns (uint256);
}


// File @openzeppelin/contracts/access/[email protected]


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


// File contracts/external/interfaces/StateHash.sol


pragma solidity 0.8.9;

/**
 * @title interface for state hash tokens
 */
interface StateHash {
    function stateHash(uint256 _tokenId) external view returns (bytes32);
}


// File contracts/Stake.sol


pragma solidity 0.8.9;
/**
 * @dev total supply of the token is assumed to be less than 2^96
 */
contract Stake is Context, ERC165, IERC721, IERC721Enumerable, StateHash, Votes, Ownable {
    using Address for address;
    
    uint256 private constant SECONDS_IN_TWO_YEARS = 24 * 30 days;

    IERC20 public immutable token;
    address public burnAddress;

    uint256 public lastUpdate;  // integer 40 bits
    // lock balance is not available for rewards
    uint256 public lastLockBalance;  // fixed point arithmetics, 96, 32 bits, [96,32]
    uint256 internal rewardPerWeightedToken;  // fixed point arithmetics, 128, 96 bits, [128,96]
    uint256 public totalWeightedTokens;  // fixed point arithmetics, 96, 32 bits, [96,32]

    struct StakeData {
        address owner;
        uint256 amount;
        uint256 weightedAmount;  // fixed point arithmetics, 96, 32 bits, [96,32]
        uint256 creationDate;
        uint256 duration;
        uint256 lastRewardPerWeightedToken;  // fixed point arithmetics, 128, 96 bits, [128,96]
    }

    // stakeId => stake
    mapping(uint256 => StakeData) public stakes;
    uint256 public lastStakeId;

    mapping(address => uint256) private _balances;
    // Mapping from owner to list of owned stake IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedStakes;

    // Mapping from stake ID to index of the owner stakes list
    mapping(uint256 => uint256) private _ownedStakesIndex;

    // Array with all stake ids, used for enumeration
    uint256[] private _allStakes;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allStakesIndex;

    // Mapping from stake Id to approved address
    mapping(uint256 => address) private _stakeApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping stake owner to sum of Vote Power
    mapping(address => uint256) private _accountVotes;

    event PoolBalanceUpdated(uint256 balanceIncrease);
    event StakeCreated(address indexed owner, uint256 indexed stakeId, uint256 duration, uint256 amount);
    event RewardClaimed(address indexed owner, uint256 indexed stakeId, uint256 reward, uint256 penalty);
    event StakeRetrieved(address indexed owner, uint256 indexed stakeId);
    event NewBurnAddress(address indexed burnAddress);

    constructor (IERC20 _token, address _burnAddress) EIP712("Stake", "1.0.0"){
        token = _token;
        burnAddress = _burnAddress;
        lastUpdate = block.timestamp;
        lastLockBalance = 0;
        rewardPerWeightedToken = 0;
        totalWeightedTokens = 0;
        emit NewBurnAddress(burnAddress);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(StateHash).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // --------------------------------- IERC721 & IERC721Enumerable ------------------------------- //
    // Code implements below IERC721 & IERC721Enumerable
    // It is copied from OZ with a few modifications
    // - stakes[stakeId].owner is used instead of _owners
    // - renamed: stakeId, _ownedStakes, _allStakes, _ownedStakesIndex, just to comply with naming convention
    // - _beforeTokenTransfer() and _afterTokenTransfer() are dropped
    // - enumeration functions are inlined
    // - no mint and burn, there are stake creation and retrieving functions

    /**
    * @dev See {ERC721Enumerable-tokenOfOwnerByIndex} from OpenZeppelin.
    * The function copied without changes.
    */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view override returns (uint256) {
        require(_index < _balances[_owner], "Stake: owner index out of bounds");
        return _ownedStakes[_owner][_index];
    }

    /**
    * @dev See {ERC721Enumerable-totalSupply} from OpenZeppelin.
    * The function copied without changes.
    */
    function totalSupply() external view override returns (uint256) {
        return _allStakes.length;
    }

    /**
    * @dev See {ERC721Enumerable-tokenByIndex} from OpenZeppelin.
    * The function copied without changes.
    */
    function tokenByIndex(uint256 _index) external view override returns (uint256){
        require(_index < _allStakes.length, "Stake: global index out of bounds");
        return _allStakes[_index];
    }

    /**
    * @dev See {ERC721Enumerable-_addTokenToOwnerEnumeration} from OpenZeppelin.
    * The function copied without changes.
    */
    function _addTokenToOwnerEnumeration(address to, uint256 stakeId) private {
        uint256 length = _balances[to];
        _ownedStakes[to][length] = stakeId;
        _ownedStakesIndex[stakeId] = length;
    }

    /**
    * @dev See {ERC721Enumerable-_addTokenToAllTokensEnumeration} from OpenZeppelin.
    * The function copied without changes.
    */
    function _addTokenToAllTokensEnumeration(uint256 stakeId) private {
        _allStakesIndex[stakeId] = _allStakes.length;
        _allStakes.push(stakeId);
    }

    /**
    * @dev See {ERC721Enumerable-_removeTokenFromOwnerEnumeration} from OpenZeppelin.
    * The function copied without changes.
    */
    function _removeTokenFromOwnerEnumeration(address from, uint256 stakeId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastStakeIndex = _balances[from] - 1;
        uint256 stakeIndex = _ownedStakesIndex[stakeId];

        // When the stake to delete is the last stake, the swap operation in unnecesssary
        if(stakeIndex != lastStakeIndex) {
            uint256 _lastStakeId = _ownedStakes[from][lastStakeIndex];

            _ownedStakes[from][stakeIndex] = _lastStakeId;
            _ownedStakesIndex[_lastStakeId] = stakeIndex;
        }

        delete _ownedStakesIndex[stakeId];
        delete _ownedStakes[from][lastStakeIndex];

    }
    
    /**
    * @dev See {ERC721Enumerable-_removeTokenFromAllTokensEnumeration} from OpenZeppelin.
    * The function copied without changes.
    */
    function _removeTokenFromAllTokensEnumeration(uint256 stakeId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastStakeIndex = _allStakes.length - 1;
        uint256 stakeIndex = _allStakesIndex[stakeId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)

        uint256 _lastStakeId = _allStakes[lastStakeIndex];

        _allStakes[stakeIndex] = _lastStakeId;
        _allStakesIndex[_lastStakeId] = stakeIndex;

        // This also deletes the contents at the last position of the array
        delete _allStakesIndex[stakeId];
        _allStakes.pop();

    }
    
    /**
    * @dev See {ERC721-balanceOf} from OpenZeppelin.
    * The function copied without changes.
    */
    function balanceOf(address _owner) external view override returns (uint256) {
        require(_owner != address(0), "Stake: address zero is not a valid owner");
        return _balances[_owner];
    } 

    /**
    * @dev See {ERC721-ownerOf} from OpenZeppelin.
    * The function copied without changes.
    */
    function ownerOf(uint256 stakeId) public view virtual override returns (address) {
        address owner = stakes[stakeId].owner;
        require(owner != address(0), "Stake: invalid stake ID");
        return owner;
    }

    /**
    * @dev See {ERC721-safeTransferFrom(address,address,uint256)} from OpenZeppelin.
    * The function copied without changes.
    */
    function safeTransferFrom(
        address from,
        address to,
        uint256 stakeId
    ) public virtual override {
        safeTransferFrom(from, to, stakeId, "");
    }
    
    /**
    * @dev See {ERC721-safeTransferFrom(address,address,uint256,bytes)} from OpenZeppelin.
    * The function copied without changes.
    */
    function safeTransferFrom(
        address from,
        address to,
        uint256 stakeId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), stakeId), "Stake: caller is not stake owner nor approved");
        _safeTransfer(from, to, stakeId, data);
    }

    /**
    * @dev See {ERC721-_safeTransfer} from OpenZeppelin.
    * The function copied without changes.
    */
    function _safeTransfer( 
        address from,
        address to,
        uint256 stakeId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, stakeId);
        require(_checkOnStakeReceived(from, to, stakeId, data), "Stake: transfer to non ERC721Receiver implementer");
    }

    /**
    * @dev See {ERC721-transferFrom} from OpenZeppelin.
    * The function copied without changes.
    */
    function transferFrom(
        address from,
        address to,
        uint256 stakeId
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), stakeId), "Stake: caller is not stake owner nor approved");
        _transfer(from, to, stakeId);
    }

    /**
    * @dev See {ERC721-_transfer} from OpenZeppelin.
    * The function copied with changes.
    */
    function _transfer(
        address from,
        address to,
        uint256 stakeId
    ) internal virtual {
        require(ownerOf(stakeId) == from, "Stake: transfer from incorrect owner");
        require(to != address(0), "Stake: transfer to the zero address");

        /* change start **/ 
            // deleted _beforeTokenTransfer(from, to, tokenId);
        _transferVotes(from, to, stakes[stakeId].weightedAmount);
       
        _addTokenToOwnerEnumeration(to, stakeId);
        _removeTokenFromOwnerEnumeration(from, stakeId);

        // Clear approvals from the previous owner
        _approve(address(0), stakeId);

        _balances[from] -= 1;
        _balances[to] += 1;
        
        /* change started **/
        stakes[stakeId].owner = to;
        /* change ended **/

        emit Transfer(from, to, stakeId);
        /* change started **/
            // deleted _afterTokenTransfer(from, to, tokenId);
        /* change ended **/

    }

    /**
    * @dev See {ERC721-approve} from OpenZeppelin.
    * The function copied without changes.
    */
    function approve(address to, uint256 stakeId) external{
        address owner = Stake.ownerOf(stakeId);
        require(to != owner, "Stake: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "Stake: approve caller is not stake owner nor approved for all"
        );

        _approve(to, stakeId);
    }

    /**
    * @dev See {ERC721-_approve} from OpenZeppelin.
    * The function copied without changes.
    */
    function _approve(address to, uint256 stakeId) internal virtual {
        _stakeApprovals[stakeId] = to;
        emit Approval(Stake.ownerOf(stakeId), to, stakeId);
    }

    /**
    * @dev See {ERC721-setApprovalForAll} from OpenZeppelin.
    * The function copied without changes.
    */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
    * @dev See {ERC721-_setApprovalForAll} from OpenZeppelin.
    * The function copied without changes.
    */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "Stake: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
    * @dev See {ERC721-getApproved} from OpenZeppelin.
    * The function copied without changes.
    */
    function getApproved(uint256 stakeId) public view virtual override returns (address) {
        _requireMinted(stakeId);

        return _stakeApprovals[stakeId];
    }

    /**
    * @dev See {ERC721-_requireMinted} from OpenZeppelin.
    * The function copied without changes.
    */
    function _requireMinted(uint256 stakeId) internal view virtual {
        require(_exists(stakeId), "Stake: invalid stake ID");
    }

    /**
    * @dev See {ERC721-_exists} from OpenZeppelin.
    * The function copied without changes.
    */
    function _exists(uint256 stakeId) internal view virtual returns (bool) {
        return stakes[stakeId].owner != address(0);
    }

    /**
    * @dev See {ERC721-isApprovedForAll} from OpenZeppelin.
    * The function copied without changes.
    */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
    * @dev See {ERC721-_isApprovedOrOwner} from OpenZeppelin.
    * The function copied without changes.
    */
    function _isApprovedOrOwner(address spender, uint256 stakeId) internal view virtual returns (bool) {
        address owner = Stake.ownerOf(stakeId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(stakeId) == spender);
    }

    /**
    * @dev See {ERC721-_checkOnStakeReceived} from OpenZeppelin.
    * The function copied without changes.
    */
    function _checkOnStakeReceived(
        address from,
        address to,
        uint256 stakeId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, stakeId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("Stake: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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

    // -------------------------- end of IERC721 & IERC721Enumerable ------------------------------- //
    // -------------------------- IVote ------------------------------------------------------------ //
    /**
    * @dev Before calling _transferVotingUnits this function increments the _accountVotes mapping to track
    *      the amount of total voting units each user has (delegated and not delegated).
    */
    function _transferVotes(
        address from,
        address to,
        uint256 amount
    ) internal {
        if (from != address(0)) {
            _accountVotes[from] -= amount;
        }
        if (to != address(0)) {
            _accountVotes[to] += amount;
        }
        _transferVotingUnits(from, to, amount);
    }

    /**
    * @dev See {Votes-_getVotingUnits} from OpenZeppelin.
    * The function is overriden and retuns how many total votes has each user.
    */
    function _getVotingUnits(address account) internal view override returns (uint256){
        return _accountVotes[account];
    } 

    // -------------------------- end IVote -------------------------------------------------------- //

    function updateBurnAddress(address newBurnAddress) external onlyOwner {
        burnAddress = newBurnAddress;
        emit NewBurnAddress(burnAddress);
    }

    function stakeWithoutDuration(uint256 amount) external {
        require(amount > 0, "Stake: the amount is zero");
        require(totalWeightedTokens + (amount << 32) < 2**128, "Stake: total staked tokens cannot exceed 2**94");
        lastStakeId ++;
        _updatePoolState(0);
        StakeData memory stakeData = StakeData(
            _msgSender(),
            amount,
            amount << 32,  // boost = 0, weight = 1
            block.timestamp,
            0,
            rewardPerWeightedToken
        );
        totalWeightedTokens += stakeData.weightedAmount;
        stakes[lastStakeId] = stakeData;

        _addTokenToAllTokensEnumeration(lastStakeId);
        _addTokenToOwnerEnumeration(stakeData.owner, lastStakeId);
        _balances[stakeData.owner] += 1;

        _transferVotes(address(0), _msgSender(), stakeData.weightedAmount);

        emit StakeCreated(_msgSender(), lastStakeId, 0 , amount);
        emit Transfer(address(0), _msgSender(), lastStakeId);

        token.transferFrom(_msgSender(), address(this), amount);
    }

    /**
     * @param duration in seconds, min 1 month, max 24 months
     */
    function stakeWithDuration(uint256 amount, uint256 duration) external {
        require(amount > 0, "Stake: the amount is zero");
        require(duration >= 30 days, "Stake: min duration is 1 month");
        require(duration <= SECONDS_IN_TWO_YEARS, "Stake: max duration is 24 months");

        uint256 boost = (3 << 32) * duration / (SECONDS_IN_TWO_YEARS);  // fixed point arithmetics [40,32]
        require(totalWeightedTokens + (amount * ((1<<32) + boost)) < 2**128, "Stake: total staked tokens cannot exceed 2**94");

        lastStakeId ++;
        _updatePoolState(0);
        StakeData memory stakeData = StakeData(
            _msgSender(),
            amount,
            amount * ((1<<32) + boost), // it is actually [96,32]
            block.timestamp,
            duration,
            rewardPerWeightedToken
        );
        totalWeightedTokens += stakeData.weightedAmount;
        stakes[lastStakeId] = stakeData;

        _addTokenToAllTokensEnumeration(lastStakeId);
        _addTokenToOwnerEnumeration(stakeData.owner, lastStakeId);
        _balances[stakeData.owner] += 1;

        _transferVotes(address(0), _msgSender(), stakeData.weightedAmount);

        emit StakeCreated(_msgSender(), lastStakeId, duration , amount);
        emit Transfer(address(0), _msgSender(), lastStakeId);

        token.transferFrom(_msgSender(), address(this), amount);
    }

    function claimReward(uint256 stakeId) external {
        StakeData memory stakeData = stakes[stakeId];
        require(stakeData.owner == _msgSender(), "Stake: only owner can claim the reward");

        (uint256 reward, uint256 penalty, uint256 currentRewardPerWeightedToken) = _calculateReward(stakeData);

        stakes[stakeId].lastRewardPerWeightedToken = currentRewardPerWeightedToken;
        emit RewardClaimed(_msgSender(), stakeId, reward, penalty);

        token.transfer(_msgSender(), reward);
        if (penalty > 0) {
            token.transfer(burnAddress, penalty);
        }
    }

    /**
     * @notice calculate reward for the stake
     * @return reward, penalty
     */
    function calculateReward(uint256 stakeId) external view returns (uint256, uint256) {
        StakeData memory stakeData = stakes[stakeId];

        (uint256 reward, uint256 penalty, ) = _calculateReward(stakeData);

        return (reward, penalty);
    }

    /**
     * @return reward, penalty, current calculated rewardPerWeightedToken
     */
    function _calculateReward(StakeData memory stakeData) internal view returns (uint256, uint256, uint256) {
        uint256 lockRate = calculateLockRate(block.timestamp - lastUpdate);
        // fixed point arithmetics
        // [0,128] * [96,32] / [96, 32] = [96, 160] / [96, 32] = [128,128]
        // so we need to cut the precision by 32 bits
        // it is [128,96] actually
        uint256 currentRewardPerWeightedToken =
            rewardPerWeightedToken + (((2**128 - lockRate) * lastLockBalance / totalWeightedTokens) >> 32);
        uint256 deltaRewardPerWeightedToken = currentRewardPerWeightedToken - stakeData.lastRewardPerWeightedToken;
        // fixed point arithmetics
        // [128,96] * [96,32] = [224,128]
        // baseRewards can exceed uint256 only theoretically. Total Paid Rewards should never exceed 2**128
        // this implicates that baseReward will never be greater the 2**128
        uint256 baseReward = deltaRewardPerWeightedToken * stakeData.weightedAmount;
        // fixed point arithmetics [128,128]
        uint256 reward = baseReward;
        uint256 stakeDuration75 = (3 * stakeData.duration / 4);
        if (block.timestamp - stakeData.creationDate < stakeDuration75) {  // 75% of duration
            // fixed point arithmetics, result is [0,32]
            // calculation is 0.75 * (1 - dt/(0.75*duration))
            uint256 earlyWithdrawalPenalty = (3<<32)/4 * (stakeDuration75 + stakeData.creationDate - block.timestamp) / stakeDuration75;
            // fixed point arithmetics
            // [128,96] * [0,32] = [128,128]
            reward = (reward >> 32) * ((1<<32) - earlyWithdrawalPenalty);
        }
        if (block.timestamp - stakeData.creationDate <= 30 days) {  // 30 days penalty
            reward = reward / 2;
        }
        //cut precisions
        baseReward = baseReward >> 128;
        reward = reward >> 128;

        return (reward, baseReward - reward, currentRewardPerWeightedToken);
    }

    function retrieveStake(uint256 stakeId) external {
        StakeData memory stakeData = stakes[stakeId];
        require(stakeData.owner == _msgSender(), "Stake: only owner can claim the reward");
        require(stakeData.creationDate + stakeData.duration < block.timestamp, "Cannot retrieve, stake is locked.");

        (uint256 reward, uint256 penalty, ) = _calculateReward(stakeData);

        _updatePoolState(0);
        totalWeightedTokens -= stakeData.weightedAmount;

        _removeTokenFromAllTokensEnumeration(stakeId);
        _removeTokenFromOwnerEnumeration(stakeData.owner, stakeId);
        _balances[stakeData.owner] -= 1;

        _transferVotes(_msgSender(), address(0), stakeData.weightedAmount);

        delete stakes[stakeId];
        emit RewardClaimed(_msgSender(), stakeId, reward, penalty);
        emit StakeRetrieved(_msgSender(), stakeId);
        emit Transfer(stakeData.owner, address(0), stakeId);

        token.transfer(_msgSender(), stakeData.amount + reward);
        if (penalty > 0) {
            token.transfer(burnAddress, penalty);
        }
    }

    /**
     * @notice updates the state of the pool
     * @dev the treasury contract first must approve funds to this pool and then call this function with the amount of approved new funds
     * @param balanceIncrease integer 96 bits
     */
    function updatePoolBalance(uint256 balanceIncrease) external {
        _updatePoolState(balanceIncrease);
        emit PoolBalanceUpdated(balanceIncrease);
        token.transferFrom(_msgSender(), address(this), balanceIncrease);
    }

    /**
     * @notice updates the state of the pool
     * @param balanceIncrease integer 96 bits
     */
    function _updatePoolState(uint256 balanceIncrease) internal {
        
        // If there are no weightedTokens (0 stakes) then increase the lastLockBalance by balanceIncrease arg
        if(totalWeightedTokens == 0){
            // fixed point arithmetics
            // [96,32]
            lastLockBalance += balanceIncrease << 32;
        } else {
            uint256 lockRate = calculateLockRate(block.timestamp - lastUpdate);
            // fixed point arithmetics
            // [0,128] * [96,32] / [96, 32] = [96, 160] / [96, 32] = [128,128]
            // so we need to cut the precision by 32 bits
            // it is [128,96] actually
            rewardPerWeightedToken += ((2**128 - lockRate) * lastLockBalance / totalWeightedTokens) >> 32;
            assert(rewardPerWeightedToken < 2**224);
            // fixed point arithmetics
            // [96,32] * [0,128] + [96,0] = [96,160] + [96,0]
            // so we need to adjust the precisions
            lastLockBalance = ((lastLockBalance * lockRate) >> 128) + (balanceIncrease << 32);
        }
       
        assert(lastLockBalance < 2**128);
        lastUpdate = block.timestamp;
        
    }

    /**
     * @notice calculates the current locked balance, helper function
     * @dev fixed point arithmetics, [96,32]
     */
    function currentLockBalance() external view returns (uint256) {
        if(totalWeightedTokens == 0) {
            return lastLockBalance;
        }

        uint256 lockRate = calculateLockRate(block.timestamp - lastUpdate);
        return ((lastLockBalance * lockRate) >> 128);
        
    }

    /**
     * @dev calculates the fraction of pool that remains locked over the deltaTime
     * the function is pretty ugly, it is because 'Constants of non-value type not yet implemented' in solidity
     * @return fixed point arithmetics, [0,128] bits, possibly 2^128
     */
    function calculateLockRate(uint256 deltaTime) public pure returns (uint256) {
        // unchecked saves 2.4k gas for deltaTime == 1 day
        unchecked {
            uint256 lockRate = 2**128;

            if (deltaTime == 0) {
                return lockRate;
            }
            if (deltaTime % 2 == 1) {
                lockRate = lockRate * 0xffffffce43cdcba99c56f0ae02202751 / 2**128;
            }
            deltaTime = deltaTime / 2;

            if (deltaTime == 0) {
                return lockRate;
            }
            if (deltaTime % 2 == 1) {
                lockRate = lockRate * 0xffffff9c879ba0fcce3fb12589ca9e35 / 2**128;
            }
            deltaTime = deltaTime / 2;

            if (deltaTime == 0) {
                return lockRate;
            }
            if (deltaTime % 2 == 1) {
                lockRate = lockRate * 0xffffff390f37689ff2bf1f30eab8c084 / 2**128;
            }
            deltaTime = deltaTime / 2;

            if (deltaTime == 0) {
                return lockRate;
            }
            if (deltaTime % 2 == 1) {
                lockRate = lockRate * 0xfffffe721e6f6bd93e411ff74e3e0fee / 2**128;
            }
            deltaTime = deltaTime / 2;

            if (deltaTime == 0) {
                return lockRate;
            }
            if (deltaTime % 2 == 1) {
                lockRate = lockRate * 0xfffffce43ce14217ddad3636a8674d43 / 2**128;
            }
            deltaTime = deltaTime / 2;

            if (deltaTime == 0) {
                return lockRate;
            }
            if (deltaTime % 2 == 1) {
                lockRate = lockRate * 0xfffff9c879cc2dc53101c5333292a30a / 2**128;
            }
            deltaTime = deltaTime / 2;

            if (deltaTime == 0) {
                return lockRate;
            }
            if (deltaTime % 2 == 1) {
                lockRate = lockRate * 0xfffff390f3bf01dfc07cebf241e94bac / 2**128;
            }
            deltaTime = deltaTime / 2;

            if (deltaTime == 0) {
                return lockRate;
            }
            if (deltaTime % 2 == 1) {
                lockRate = lockRate * 0xffffe721e8189d1139bf6622f3b75299 / 2**128;
            }
            deltaTime = deltaTime / 2;

            if (deltaTime == 0) {
                return lockRate;
            }
            if (deltaTime % 2 == 1) {
                lockRate = lockRate * 0xffffce43d29b9f4b4d968c7c7518059d / 2**128;
            }
            deltaTime = deltaTime / 2;

            if (deltaTime == 0) {
                return lockRate;
            }
            if (deltaTime % 2 == 1) {
                lockRate = lockRate * 0xffff9c87aee0d249bbacc0068bb689f5 / 2**128;
            }
            deltaTime = deltaTime / 2;

            if (deltaTime == 0) {
                return lockRate;
            }
            if (deltaTime % 2 == 1) {
                lockRate = lockRate * 0xffff390f8467ebddbba4127efa7ece29 / 2**128;
            }
            deltaTime = deltaTime / 2;

            if (deltaTime == 0) {
                return lockRate;
            }
            if (deltaTime % 2 == 1) {
                lockRate = lockRate * 0xfffe721fa368b8d2af3e64ad2cb5656a / 2**128;
            }
            deltaTime = deltaTime / 2;

            if (deltaTime == 0) {
                return lockRate;
            }
            if (deltaTime % 2 == 1) {
                lockRate = lockRate * 0xfffce441b1331574bb78f9adc54415f5 / 2**128;
            }
            deltaTime = deltaTime / 2;

            if (deltaTime == 0) {
                return lockRate;
            }
            if (deltaTime % 2 == 1) {
                lockRate = lockRate * 0xfff9c88d0bddb5cf401c98a766d2aadc / 2**128;
            }
            deltaTime = deltaTime / 2;

            if (deltaTime == 0) {
                return lockRate;
            }
            if (deltaTime % 2 == 1) {
                lockRate = lockRate * 0xfff39140bd2175bf0dbe97dafaf94e33 / 2**128;
            }
            deltaTime = deltaTime / 2;

            if (deltaTime == 0) {
                return lockRate;
            }
            if (deltaTime % 2 == 1) {
                lockRate = lockRate * 0xffe7231c0c1a1cb729ed83aefcbc4563 / 2**128;
            }
            deltaTime = deltaTime / 2;

            if (deltaTime == 0) {
                return lockRate;
            }
            if (deltaTime % 2 == 1) {
                lockRate = lockRate * 0xffce48a2418a8ab68237a9dd639d3234 / 2**128;
            }
            deltaTime = deltaTime / 2;

            uint256 rate = 0xffce48a2418a8ab68237a9dd639d3234;
            while (deltaTime > 0) {
                rate = rate * rate / 2**128;
                if (deltaTime % 2 == 1) {
                    lockRate = lockRate * rate / 2**128;
                }
                deltaTime = deltaTime / 2;
            }
            return lockRate;
        }
    }

    function stateHash(uint256 stakeId) external view returns (bytes32) {
        require(stakes[stakeId].owner != address(0), "Stake: stake does not exist");
        // add 1 because state hash shouldn't be 0
        return bytes32(stakes[stakeId].lastRewardPerWeightedToken + 1);
    }

}