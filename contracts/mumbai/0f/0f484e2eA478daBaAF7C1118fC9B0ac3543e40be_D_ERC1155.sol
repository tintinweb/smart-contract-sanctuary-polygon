// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";// in this file already
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/access/AccessControl.sol";
// import "@openzeppelin/contracts/utils/Counters.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
//inherits from IERC165
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol"; //inherits from IERC1155
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title D_ERC1155 contract.
 * NOTE: Contract allows Admin of the contract mint ERC1155 standard tokens for different addresses, burn them,
 * and dynamically change the metadata of these tokens.
 * Metadata is updated through a `token-level` update system. URIs are initially imported into the contract
 * after minting and in order to update `level` parameter from `Token` struct must be updated
 * @dev `D` in the `D_ERC1155` contract means that token Metadata can be updated dynamically.
 * `Membership` in the `D_ERC1155` contract means that tokens are not transferable.
 */
contract D_ERC1155 is
    Context,
    IERC1155,
    IERC1155Receiver,
    IERC1155MetadataURI,
    ERC165
{
    using Address for address;

    /**
     * @dev Modifier to allow only owner to perform certain actions.
     */
    modifier onlyOwner() {
        require(
            LibDiamond.contractOwner() == msg.sender,
            "D_ERC721_OpenContract: Caller is not the owner"
        );
        _;
    }
    /**
     * @dev Emitted when new token minted.
     * @param receiver Address of the token owner.
     * @param backendTokenKey Backend token key.
     * @param tokenId Id of the created token.
     * @param amount Amount of the minted tokens.
     */
    event DynamicERC1155Minted(
        address receiver,
        string backendTokenKey,
        uint256 tokenId,
        uint256 amount
    );

    /**
     * @dev Emitted when the token URI is updated.
     * @param tokenId Id of the updated token.
     * @param newUri URI of the token after changing.
     * @param level Level of token URI.
     */
    event NFTmetadataChanged(uint256 tokenId, string newUri, uint256 level);

    /**
     * @dev Emitted when token burn occurs.
     * @param account The address where the token burning occured.
     * @param backendTokenKey Token key provided from backend.
     * @param tokenId Token Id of burned tokens.
     * @param amount Amount of the burned tokens.
     */
    event TokenBurned(
        address account,
        string backendTokenKey,
        uint256 tokenId,
        uint256 amount
    );

    /**
     * @dev Emitted when metadata for token is setted.
     * @param uris Array of all URIs for the tokenId.
     * @param backendTokenKey Token key provided from backend.
     * @param tokenId Token Id of burned tokens.
     */
    event MetadataSetted(
        string[] uris,
        string backendTokenKey,
        uint256 tokenId
    );

    /**
     * @dev This is a function to mint unique ERC1155 tokens with dynamic URIs. Available only for the Admin.
     *
     * Requirements:
     *
     * - The caller must be an `DEFAULT_ADMIN_ROLE`.
     * - `account_` cannot be address zero.
     * - `backendTokenKey_` in `backendTokenKeyToId` mapping required to not exist at the moment of minting.
     *
     * @param account_ The address where the token is to be minted.
     * @param backendTokenKey_ Token key provided from backend.
     * @param amount_ Amount of tokens to be minted.
     *
     * Emits a {DynamicERC1155Minted} event.
     */
    function mint(
        address account_,
        string memory backendTokenKey_,
        uint256 amount_
    ) external onlyOwner {
        LibDiamond.ERC1155Storage storage ds = _getERC1155Storage();
        uint256 tokenId = getTokenKeyId(backendTokenKey_);
        _mint(account_, tokenId, amount_, "");
        emit DynamicERC1155Minted(account_, backendTokenKey_, tokenId, amount_);
    }

    /**
     * @dev This is a function to set metadata of ERC1155 tokens with dynamic URIs. Available only for the Admin.
     *
     * Requirements:
     *
     * - The caller must be an `DEFAULT_ADMIN_ROLE`.
     * - The `uris_` array cannot be empty, and the first element of the array cannot be empty either.
     * - `backendTokenKey_` in `backendTokenKeyToId` mapping required to not exist at the moment of minting.
     *
     * @param backendTokenKey_ Token key provided from backend.
     * @param uris_ Array of all URIs for this token.
     *
     * Emits a {MetadataSetted} event.
     */
    function setToken(
        string memory backendTokenKey_,
        string[] memory uris_
    ) public onlyOwner {
        LibDiamond.ERC1155Storage storage ds = _getERC1155Storage();
        require(
            uris_.length > 0 && bytes(uris_[0]).length > 0,
            "D_ERC1155: Uris cannot be empty"
        );
        require(
            ds.backendTokenKeyToId[backendTokenKey_] == 0,
            "D_ERC1155: Mint need to be unique"
        );
        uint256 tokenId = ds.tokenId++;
        ds.backendTokenKeyToId[backendTokenKey_] = tokenId;
        ds.tokens[tokenId].uris = uris_;
        ds.tokens[tokenId].level = 0;
        ds.keyFallback.push(backendTokenKey_);
        emit MetadataSetted(uris_, backendTokenKey_, tokenId);
    }

    /**
     * @dev This is a function to change NFT metadata. A dynamic type NFT can have multiple NFT metadatas and
     * can be called only by  Admin.
     *
     * Requirements:
     *
     * - The caller must be an `DEFAULT_ADMIN_ROLE`.
     * - `backendTokenKey_` must be greater then 0, otherwise token doesnt exist in `backendTokenKeyToId` mapping.
     * - `level_` must be lower then length of `uris[]` in `Token` struct.
     * - Token must exist.
     *
     * @param backendTokenKey_ Token key provided from backend.
     * @param level_ Points to a value from the `uris[]` to which the token metadata will be updated.
     *
     * Emits a {NFTmetadataChanged} event.
     */
    function changeToken(
        string memory backendTokenKey_,
        uint256 level_
    ) external onlyOwner {
        uint256 tokenId = getTokenKeyId(backendTokenKey_);
        LibDiamond.ERC1155Storage storage ds = _getERC1155Storage();
        require(
            level_ < (ds.tokens[tokenId].uris).length,
            "D_ERC1155: Update not available for this token"
        );
        ds.tokens[tokenId].level = level_;
        emit NFTmetadataChanged(
            tokenId,
            ds.tokens[tokenId].uris[level_],
            level_
        );
    }

    /**
     * @dev Burns `amount_` of `backendTokenKey_` type of tokens in `account_` address.
     * Available only for the Admin.
     *
     * Requirements:
     *
     * - The caller must be an `DEFAULT_ADMIN_ROLE`.
     *
     * @param account_ The address where the tokens will be burned .
     * @param backendTokenKey_ Token key provided from backend. It's used to query `tokenId` from
     * `backendTokenKeyToId` mapping
     * @param amount_ Amount of the tokens to be burned.
     *
     * Emits a {TokenBurned} event.
     */
    function burn(
        address account_,
        string memory backendTokenKey_,
        uint256 amount_
    ) external onlyOwner {
        uint256 tokenId = getTokenKeyId(backendTokenKey_);
        _burn(account_, tokenId, amount_);
        emit TokenBurned(account_, backendTokenKey_, tokenId, amount_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev This is a function to query the Uri of a token by providing a tokenId.
     *
     * Requirements:
     *
     * - `tokens[tokenId].uris` length must be greater than 0. Otherwise URI for this token was not setted.
     *
     * @param tokenId_ Token Id of the token for the URI query.
     */
    function uri(
        uint256 tokenId_
    ) public view override returns (string memory) {
        LibDiamond.ERC1155Storage storage ds = _getERC1155Storage();
        require(
            (ds.tokens[tokenId_].uris).length > 0,
            "D_ERC1155: URI doesnt exist"
        );
        uint256 level = ds.tokens[tokenId_].level;
        string memory tokenUri = ds.tokens[tokenId_].uris[level];
        return tokenUri;
    }

    /**
     * @dev Returns TokenId by providing backend token key.
     */
    function getTokenKeyId(
        string memory backendTokenKey
    ) public view returns (uint256) {
        LibDiamond.ERC1155Storage storage ds = _getERC1155Storage();
        require(
            ds.backendTokenKeyToId[backendTokenKey] > 0,
            "D_ERC1155: No token exist with this name"
        );
        return ds.backendTokenKeyToId[backendTokenKey];
    }

    /**
     * @dev Returns Token struct with level and levelUri[] by providing tokenId.
     */
    function getTokenData(
        uint256 tokenId_
    ) internal view returns (LibDiamond.Tokens storage) {
        return _getERC1155Storage().tokens[tokenId_];
    }

    /**
     * @dev Returns array of all token keys.
     */
    function getTokenKeyList() external view returns (string[] memory) {
        LibDiamond.ERC1155Storage storage ds = _getERC1155Storage();
        return ds.keyFallback;
    }

    /**
     * @dev Returns contract Uri.
     */
    function contractURI() external view returns (string memory) {
        LibDiamond.ERC1155Storage storage ds = _getERC1155Storage();
        return ds.contractUri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(
        address account,
        uint256 id
    ) public view virtual override returns (uint256) {
        LibDiamond.ERC1155Storage storage ds = _getERC1155Storage();
        require(
            account != address(0),
            "ERC1155: address zero is not a valid owner"
        );
        return ds.balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual override returns (uint256[] memory) {
        require(
            accounts.length == ids.length,
            "ERC1155: accounts and ids length mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(
        address account,
        address operator
    ) public view virtual override returns (bool) {
        LibDiamond.ERC1155Storage storage ds = _getERC1155Storage();
        return ds.operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");
        LibDiamond.ERC1155Storage storage ds = _getERC1155Storage();

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = ds.balances[id][from];
        require(
            fromBalance >= amount,
            "ERC1155: insufficient balance for transfer"
        );
        unchecked {
            ds.balances[id][from] = fromBalance - amount;
        }
        ds.balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");
        LibDiamond.ERC1155Storage storage ds = _getERC1155Storage();
        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = ds.balances[id][from];
            require(
                fromBalance >= amount,
                "ERC1155: insufficient balance for transfer"
            );
            unchecked {
                ds.balances[id][from] = fromBalance - amount;
            }
            ds.balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri_) internal virtual {
        LibDiamond.ERC1155Storage storage ds = _getERC1155Storage();
        ds.uri = newuri_;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        LibDiamond.ERC1155Storage storage ds = _getERC1155Storage();
        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        ds.balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            id,
            amount,
            data
        );
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        LibDiamond.ERC1155Storage storage ds = _getERC1155Storage();
        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            ds.balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        LibDiamond.ERC1155Storage storage ds = _getERC1155Storage();
        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = ds.balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            ds.balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        LibDiamond.ERC1155Storage storage ds = _getERC1155Storage();
        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = ds.balances[id][from];
            require(
                fromBalance >= amount,
                "ERC1155: burn amount exceeds balance"
            );
            unchecked {
                ds.balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
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
        require(owner != operator, "ERC1155: setting approval status for self");
        LibDiamond.ERC1155Storage storage ds = _getERC1155Storage();
        ds.operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Returns the ERC1155Storage.
     * @return ERC1155Storage.
     */
    function _getERC1155Storage()
        internal
        view
        returns (LibDiamond.ERC1155Storage storage)
    {
        return LibDiamond.diamondStorage().erc1155Storage;
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(
        uint256 element
    ) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Diamond Cut Interface
 * @dev This interface lays out the structure for adding, replacing, or removing functions
 * in a Diamond contract architecture. It also includes the logic for executing a function
 * with delegatecall.
 */
interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /**
     * @notice This function allows to add, replace, or remove any number of functions
     * and optionally execute a function with delegatecall.
     * @param diamondCut_ An array of FacetCut structs containing the facet addresses
     * and function selectors for the cut.
     * @param init_ The address of the contract or facet to execute calldata_.
     * @param calldata_ A bytes array containing the function call data,
     * including function selector and arguments. calldata_ is executed with delegatecall on init_.
     */
    function diamondCut(FacetCut[] calldata diamondCut_, address init_, bytes calldata calldata_) external;

    /**
     * @dev Emitted after a successful `diamondCut` operation.
     * @param diamondCut_ The array of FacetCut structs that was passed to the function.
     * @param init_ The address of the contract or facet that was executed with delegatecall.
     * @param calldata_ The function call data that was passed to the function.
     */
    event DiamondCut(FacetCut[] diamondCut_, address init_, bytes calldata_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
/// The loupe functions are required by the EIP2535 Diamonds standard

error InitializationFunctionReverted(
    address _initializationContractAddress,
    bytes _calldata
);

/**
 * @title LibDiamond - A library implementing the EIP-2535 Diamond Standard
 * @dev This library is responsible for managing the storage and functionality related to diamonds.
 * It provides functions for adding, updating, and removing facets and their function selectors,
 * as well as managing contract ownership and supported interfaces.
 */
library LibDiamond {
    struct Token {
        string uri;
    }
    struct Tokens {
        uint256 level;
        string[] uris;
    }

    /// Basic storage for ERC721 tokens
    struct ERC721Storage {
        /// replace _owners mapping in OpenZeppelin contract
        mapping(uint256 => address) owners;
        ///replace _balances mapping in OpenZeppelin contract
        mapping(address => uint256) balances;
        /// replace _tokenApprovals mapping in OpenZeppelin contract
        mapping(uint256 => address) tokenApprovals;
        /// replace _operatorApprovals mapping in OpenZeppelin contract
        mapping(address => mapping(address => bool)) operatorApprovals;
        /// tokenId => token URI
        mapping(uint256 => string) tokenIdToURI;
        uint256 tokenId;
        uint256 maximumSupply;
        string name;
        string symbol;
        string contractUri;
        /// backend keys
        string[] keyFallback;
        /// Mapping from token ID to Token struct.
        mapping(uint256 => Token) tokens;
        /// Mapping from backend Token Key to Token Id.
        mapping(string => uint256) backendTokenKeyToId;
        ///Field for storing timestampses
        mapping(uint256 => uint256) tokenTimestamps;
    }

    /// Basic storage for ERC721 tokens
    struct ERC1155Storage {
        /// Mapping from token ID to account balances
        mapping(uint256 => mapping(address => uint256)) balances;
        /// Mapping from account to operator approvals
        mapping(address => mapping(address => bool)) operatorApprovals;
        /// Mapping from token ID to Token struct.
        mapping(uint256 => Tokens) tokens;
        /// Mapping from backend Token Key to Token Id.
        mapping(string => uint256) backendTokenKeyToId;
        /// Mapping From id to uri
        mapping(uint256 => string) uris;
        /// Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
        uint256 tokenId;
        string uri;
        string name;
        string symbol;
        string contractUri;
        string[] keyFallback;
    }

    /// Basic storage for ERC20 tokens
    struct ERC20Storage {
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        uint256 totalSupply;
        string name;
        string symbol;
        uint8 decimals;
    }

    /// Item for Marketplace
    struct Item {
        uint256 id;
        string name;
        string description;
        uint256 price;
        uint256 itemTimestamp;
    }
    /// Basic storage for a marketplace
    struct MarketplaceStorage {
        /// itemId => Item struct
        mapping(uint256 => Item) items;
        /// owner => list of items owned
        mapping(address => uint256[]) ownerItems;
        ///itemId => owner
        mapping(uint256 => address) itemOwners;
        /// itemId => price
        mapping(uint256 => uint256) itemPrices;
        mapping(address => EnumerableSet.UintSet) ownedItems;
    }

    struct CustomType {
        /// Custom type
        uint256 exampleField1;
        address exampleField2;
    }

    /// Generic Struct storage to accommodate any type of contract
    struct GenericStorage {
        /// Dynamic key-value storage for uints
        mapping(bytes32 => uint256) uintStorage;
        /// Dynamic key-value storage for addresses
        mapping(bytes32 => address) addressStorage;
        /// Dynamic key-value storage for bytes
        mapping(bytes32 => bytes) bytesStorage;
        /// Dynamic key-value storage for strings
        mapping(bytes32 => string) stringStorage;
        /// Dynamic key-value storage for bools
        mapping(bytes32 => bool) boolStorage;
        /// Nested mapping
        mapping(bytes32 => mapping(bytes32 => uint256)) nestedMappingStorage;
        /// Custom type storage
        mapping(bytes32 => CustomType) customTypeStorage;
        /// Custom type array storage
        mapping(bytes32 => CustomType[]) customTypeArrayStorage;
        /// Uint array storage
        mapping(bytes32 => uint256[]) uintArrayStorage;
        /// EnumerableSet storage
        mapping(bytes32 => EnumerableSet.UintSet) enumerableUintSetStorage;
    }

    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        /// Maps function selectors to the facets that execute the functions
        /// and maps the selectors to their position in the selectorSlots array
        /// func selector => (address facet, selector position)
        mapping(bytes4 => bytes32) facets;
        /// Array of slots holding function selectors, with each slot containing 8 selectors
        mapping(uint256 => bytes32) selectorSlots;
        /// The total number of function selectors in selectorSlots
        uint16 selectorCount;
        /// A mapping used to query if a contract implements an interface
        /// This is utilized for ERC-165 implementation
        mapping(bytes4 => bool) supportedInterfaces;
        /// The owner of the contract
        address contractOwner;
        /// marketplace storage
        MarketplaceStorage marketplaceStorage;
        /// erc721 storage
        ERC721Storage erc721Storage;
        /// erc20 storage
        ERC20Storage erc20Storage;
        /// erc1155 storage
        ERC1155Storage erc1155Storage;
        /// generic storage that can be used by any contract
        GenericStorage genericStorage;
    }

    /**
     * @notice Retrieves the DiamondStorage struct instance that holds the
     *         storage data for the diamond contract.
     *
     * @dev This function utilizes assembly to access the storage slot where
     *      the DiamondStorage struct data is stored.
     *
     * @return ds The DiamondStorage struct instance containing the contract's storage data
     */
    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @notice Transfers ownership of the diamond contract to a new owner.
     *
     * @dev This internal function updates the contract owner in the DiamondStorage struct
     *      and emits an OwnershipTransferred event.
     *
     * @param newOwner_ The address of the new owner to whom ownership is being transferred
     *
     * Emits an {OwnershipTransferred} event.
     */
    function setContractOwner(address newOwner_) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = newOwner_;
        emit OwnershipTransferred(previousOwner, newOwner_);
    }

    /**
     * @notice Gets the current owner of the diamond contract.
     *
     * @dev This internal view function retrieves the contract owner from the DiamondStorage struct.
     *
     * @return contractOwner_ The address of the current contract owner.
     */
    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    /**
     * @notice Verifies that the caller of the function is the contract owner.
     *
     * @dev This internal view function checks if the sender is the contract owner stored
     *      in the DiamondStorage struct, and reverts if the condition is not met.
     *
     * Reverts with "LibDiamond: Must be contract owner" if the sender is not the contract owner.
     */
    function enforceIsContractOwner() internal view {
        require(
            msg.sender == diamondStorage().contractOwner,
            "LibDiamond: Must be contract owner"
        );
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address init_,
        bytes _calldata
    );

    /// A constant mask used to clear the address part of a bytes32 value
    bytes32 constant CLEAR_ADDRESS_MASK =
        bytes32(uint256(0xffffffffffffffffffffffff));
    /// A constant mask used to clear the function selector part of a bytes32 value
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    /**
     * @notice Executes an internal diamond cut, modifying the contract's facets by adding,
     *         replacing, or removing functions, and optionally initializing a facet or contract.
     * @dev This internal version of diamondCut is almost identical to the external version,
     *      but it uses a memory array instead of a calldata array. This approach avoids copying
     *      calldata to memory, which would result in errors for two-dimensional arrays. The
     *      function iterates through the _diamondCut array, performing actions as specified
     *      and updating the contract's selector slots accordingly.
     *
     *      Note: This code is almost the same as the external diamondCut,
     *      except it is using 'Facet[] memory _diamondCut' instead of
     *      'Facet[] calldata _diamondCut'.
     *      The code is duplicated to prevent copying calldata to memory which
     *      causes an error for a two-dimensional array.
     *
     * @param diamondCut_ An array of FacetCut structs containing facet addresses, actions, and
     *                    function selectors to be added, replaced, or removed
     * @param init_ The address of the contract or facet to execute calldata_ using delegatecall
     * @param calldata_ Encoded function call, including function selector and arguments, to be
     *                  executed using delegatecall on init_
     *
     * Emits a {DiamondCut} event.
     *
     * Requirements:
     * - The `diamondCut_` array must not be empty.
     * - The `init_` address must contain contract code if it is non-zero.
     * - If an add action is performed, the function selector must not already exist.
     * - If a replace action is performed, the function selector must exist and cannot be replaced with the same function.
     * - If a remove action is performed, the function selector must exist and the `init_` address must be a zero address.
     * - The contract must have enough storage to store the new function selectors.
     */
    function diamondCut(
        IDiamondCut.FacetCut[] memory diamondCut_,
        address init_,
        bytes memory calldata_
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        /// Determine if the last selector slot is not fully occupied
        /// Efficient modulo by eight using bitwise AND
        if (selectorCount & 7 > 0) {
            /// Retrieve the last selectorSlot using bitwise shift for efficient division by 8
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        /// Iterate through the diamond cut array
        for (uint256 facetIndex; facetIndex < diamondCut_.length; ) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                diamondCut_[facetIndex].facetAddress,
                diamondCut_[facetIndex].action,
                diamondCut_[facetIndex].functionSelectors
            );

            unchecked {
                facetIndex++;
            }
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        /// Check if the last selector slot is not fully occupied
        /// Efficient modulo by eight using bitwise AND
        if (selectorCount & 7 > 0) {
            /// Update the selector slot using bitwise shift for efficient division by 8
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(diamondCut_, init_, calldata_);
        initializeDiamondCut(init_, calldata_);
    }

    /**
     * @dev This internal function adds, replaces, or removes function selectors for facets based on the action provided.
     *      This function ensures the selectors are properly stored in the contract's storage and maintain the gas efficient design.
     *      It also checks for valid inputs, ensuring that facets and selectors conform to the requirements of each action.
     *
     * @param selectorCount_ The current count of total selectors. This value is adjusted based on the action taken.
     * @param selectorSlot_ The current selector slot. This value is adjusted based on the action taken.
     * @param newFacetAddress_ The address of the new facet to be added or replaced. It must be address(0) when removing facets.
     * @param action_ The action to execute, which can be adding, replacing, or removing a facet.
     * @param selectors_ Array of function selectors to be added, replaced, or removed in the facet.
     *
     * @return selectorCount_ The updated count of total selectors after the function execution.
     * @return selectorSlot_ The updated selector slot after the function execution.
     *
     * Requirements:
     * - The `selectors_` array must not be empty.
     * - In the case of adding a new facet, the `newFacetAddress_` must not be a zero address, and the facet must contain code.
     * - In the case of replacing a facet, the `newFacetAddress_` must not be a zero address, and the facet must contain code. The function to be replaced must exist, and cannot be the same as the replacement function.
     * - In the case of removing a facet, the `newFacetAddress_` must be a zero address. The function to be removed must exist.
     */

    function addReplaceRemoveFacetSelectors(
        uint256 selectorCount_,
        bytes32 selectorSlot_,
        address newFacetAddress_,
        IDiamondCut.FacetCutAction action_,
        bytes4[] memory selectors_
    ) internal returns (uint256, bytes32) {
        DiamondStorage storage ds = diamondStorage();
        require(
            selectors_.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        if (action_ == IDiamondCut.FacetCutAction.Add) {
            enforceHasContractCode(
                newFacetAddress_,
                "LibDiamondCut: Add facet has no code"
            );
            for (uint256 selectorIndex; selectorIndex < selectors_.length; ) {
                bytes4 selector = selectors_[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(
                    address(bytes20(oldFacet)) == address(0),
                    "LibDiamondCut: Can't add function that already exists"
                );

                /// Adding the facet address and the selector count to the facet
                ds.facets[selector] =
                    bytes20(newFacetAddress_) |
                    bytes32(selectorCount_);

                /// Utilizing bitwise operations for efficient modulo by 8 and multiplication by 32
                uint256 selectorInSlotPosition = (selectorCount_ & 7) << 5;

                /// Clearing the selector's position in the slot and adding the selector
                selectorSlot_ =
                    (selectorSlot_ &
                        ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) |
                    (bytes32(selector) >> selectorInSlotPosition);

                /// If the slot is filled, then it is written to storage
                if (selectorInSlotPosition == 224) {
                    /// Utilizing bitwise operation for efficient division by 8
                    ds.selectorSlots[selectorCount_ >> 3] = selectorSlot_;
                    selectorSlot_ = 0;
                }

                selectorCount_++;

                unchecked {
                    selectorIndex++;
                }
            }
        } else if (action_ == IDiamondCut.FacetCutAction.Replace) {
            enforceHasContractCode(
                newFacetAddress_,
                "LibDiamondCut: Replace facet has no code"
            );
            for (uint256 selectorIndex; selectorIndex < selectors_.length; ) {
                bytes4 selector = selectors_[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));

                /// This check is relevant if immutable functions are present
                require(
                    oldFacetAddress != address(this),
                    "LibDiamondCut: Immutable functions cannot be replaced"
                );

                /// Prevents replacement of a function with an identical one
                require(
                    oldFacetAddress != newFacetAddress_,
                    "LibDiamondCut: A function cannot be replaced with the same function"
                );

                /// Ensures the function to be replaced exists
                require(
                    oldFacetAddress != address(0),
                    "LibDiamondCut: Non-existent functions cannot be replaced"
                );

                /// Substituting the old facet address with the new one
                ds.facets[selector] =
                    (oldFacet & CLEAR_ADDRESS_MASK) |
                    bytes20(newFacetAddress_);

                unchecked {
                    selectorIndex++;
                }
            }
        } else if (action_ == IDiamondCut.FacetCutAction.Remove) {
            /// The address for the removed facet should be null
            require(
                newFacetAddress_ == address(0),
                "LibDiamondCut: Address for removed facet must be null address"
            );

            /// "selectorCount_ >> 3" is a computational optimization for division by 8
            uint256 selectorSlotCount = selectorCount_ >> 3;

            /// "selectorCount_ & 7" is a computational optimization for modulo by eight
            uint256 selectorInSlotIndex = selectorCount_ & 7;
            for (uint256 selectorIndex; selectorIndex < selectors_.length; ) {
                if (selectorSlot_ == 0) {
                    /// Retrieve the last selectorSlot
                    selectorSlotCount--;
                    selectorSlot_ = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;

                /// Adding this block helps to avoid 'Stack too deep' error
                {
                    bytes4 selector = selectors_[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];

                    /// Check if function to remove exists
                    require(
                        address(bytes20(oldFacet)) != address(0),
                        "LibDiamondCut: Function to remove does not exist"
                    );

                    /// Immutable functions cannot be removed
                    require(
                        address(bytes20(oldFacet)) != address(this),
                        "LibDiamondCut: Immutable function cannot be removed"
                    );

                    /// Retrieve the last selector
                    /// " << 5" is a computational optimization for multiplication by 32
                    lastSelector = bytes4(
                        selectorSlot_ << (selectorInSlotIndex << 5)
                    );

                    if (lastSelector != selector) {
                        /// Update the last selector's slot position info
                        ds.facets[lastSelector] =
                            (oldFacet & CLEAR_ADDRESS_MASK) |
                            bytes20(ds.facets[lastSelector]);
                    }

                    /// Remove the selector from the facets
                    delete ds.facets[selector];

                    uint256 oldSelectorCount = uint16(uint256(oldFacet));

                    /// "oldSelectorCount >> 3" is a computational optimization for division by 8
                    oldSelectorsSlotCount = oldSelectorCount >> 3;

                    /// "oldSelectorCount & 7" is a computational optimization for modulo by eight
                    /// " << 5" is a computational optimization for multiplication by 32
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[
                        oldSelectorsSlotCount
                    ];

                    /// Clear the selector being deleted and replace it with the last selector
                    oldSelectorSlot =
                        (oldSelectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);

                    /// Update the storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    /// Clear the selector being deleted and replace it with the last selector
                    selectorSlot_ =
                        (selectorSlot_ &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    selectorSlot_ = 0;
                }

                unchecked {
                    selectorIndex++;
                }
            }
            selectorCount_ = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("LibDiamondCut: Incorrect FacetCutAction");
        }
        return (selectorCount_, selectorSlot_);
    }

    /**
     * @dev This internal function is used to initialize a diamond cut. It performs a delegate call to
     *      the provided address with the given calldata. This is typically used to call a function on
     *      a facet that sets initial state in the diamond storage.
     *
     * @param init_ The address of the contract to delegate call. This address should contain the logic
     *              that needs to be executed for the initialization. If it is address(0), the function
     *              returns without doing anything.
     * @param calldata_ The calldata to be passed to the delegate call. This should include the
     *                  function selector for the initialization function and any necessary parameters.
     *
     * @notice If the delegate call is not successful, the function will revert. If the call returns
     *         an error message, it will be bubbled up and reverted with. Otherwise, it will revert
     *         with the `InitializationFunctionReverted` error, which includes the `init_` address
     *         and the `calldata_`.
     *
     * Requirements:
     * - The `init_` address must contain contract code. If it is a zero address or an address without
     *   contract code, the function will revert with the "LibDiamondCut: init_ address has no code"
     *   error.
     */
    function initializeDiamondCut(
        address init_,
        bytes memory calldata_
    ) internal {
        if (init_ == address(0)) {
            return;
        }
        enforceHasContractCode(
            init_,
            "LibDiamondCut: init_ address has no code"
        );
        (bool success, bytes memory error) = init_.delegatecall(calldata_);
        if (!success) {
            if (error.length > 0) {
                /// bubble up error
                /// @solidity memory-safe-assembly
                /// Use inline assembly to load the size of the error message and revert with it.
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(init_, calldata_);
            }
        }
    }

    /**
     * @dev This internal function checks if the provided address (contract_) contains contract code.
     *      It uses low-level EVM instructions to access the contract size directly.
     *      If the contract size is 0 (meaning there's no contract code at the address), it reverts with the provided error message.
     *
     * @param contract_ The address to be checked for the presence of contract code.
     * @param errorMessage_ The error message to be reverted with if there's no contract code at the provided address.
     *
     * Requirements:
     * - The `contract_` must contain contract code. If not, it reverts with the provided `errorMessage_`.
     */
    function enforceHasContractCode(
        address contract_,
        string memory errorMessage_
    ) internal view {
        uint256 contractSize;
        /// Using EVM assembly to get the size of the code at address `contract_`
        assembly {
            contractSize := extcodesize(contract_)
        }

        /// Reverting if the contract size is zero (i.e., the address does not contain contract code)
        require(contractSize > 0, errorMessage_);
    }
}