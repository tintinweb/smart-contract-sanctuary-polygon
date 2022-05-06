/**
 *Submitted for verification at polygonscan.com on 2022-05-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;



// File: Address.sol

// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// File: Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: EnumerableSet.sol

// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
 * ```
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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

        assembly {
            result := store
        }

        return result;
    }
}

// File: IAccessControl.sol

// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// File: IERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// File: IERC721Receiver.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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

// File: SafeMath.sol

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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

// File: Strings.sol

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

// File: AccessManagement.sol

/**
 * @dev Library to externalize the access control features to cut down on deployed 
 * bytecode in the main contract.
 * @dev see {ViciAccess}
 * @dev Moving all of this code into this library cut the size of ViciAccess, and all of 
 * the contracts that extend from it, by about 4kb.
 */
library AccessManagement {
    using Strings for string;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    struct AccessManagementState {
        address contractOwner;
        mapping(bytes32 => EnumerableSet.AddressSet) roleMembers;
        mapping(bytes32 => RoleData) roles;
    }

    /**
     * @dev Emitted when `previousOwner` transfers ownership to `newOwner`.
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    
    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    function DEFAULT_ADMIN_ROLE() public pure returns (bytes32) {
        return 0x00;
    }

    function BANNED_ROLE_NAME() public pure returns (bytes32) {
        return "banned";
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function setContractOwner(
        AccessManagementState storage ams,
        address _newOwner
    ) external {
        require(
            ams.contractOwner == address(0) || msg.sender == ams.contractOwner
        );
        require(!isBanned(ams, _newOwner));
        require(_newOwner != address(0));
        _grantRole(ams, DEFAULT_ADMIN_ROLE(), _newOwner);
        address oldOwner = ams.contractOwner;
        ams.contractOwner = _newOwner;

        if (oldOwner != address(0)) {
            emit OwnershipTransferred(oldOwner, _newOwner);
        }
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function getContractOwner(AccessManagementState storage ams)
        public
        view
        returns (address)
    {
        return ams.contractOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function enforceIsContractOwner(AccessManagementState storage ams)
        public
        view
    {
        require(msg.sender == ams.contractOwner);
    }

    /**
     * @dev Throws if called by a banned account.
     */
    function enforceIsNotBanned(AccessManagementState storage ams)
        external
        view
    {
        require(!isBanned(ams, msg.sender));
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(
        AccessManagementState storage ams,
        bytes32 _role,
        address _account
    ) public view returns (bool) {
        return ams.roles[_role].members[_account];
    }

    /**
     * @dev Throws if `_account` does not have `_role`.
     */
    function checkRole(
        AccessManagementState storage ams,
        bytes32 _role,
        address _account
    ) public view {
        if (!hasRole(ams, _role, _account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(_account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(_role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Grants `_role` to `_account`.
     */
    function grantRole(
        AccessManagementState storage ams,
        bytes32 _role,
        address _account
    ) external {
        if (_role == BANNED_ROLE_NAME()) {
            enforceIsContractOwner(ams);
            require(_account != ams.contractOwner);
        } else {
            checkRole(ams, DEFAULT_ADMIN_ROLE(), msg.sender);
        }

        _grantRole(ams, _role, _account);
    }

    /**
     * @dev Returns `true` if `_account` is banned.
     */
    function isBanned(AccessManagementState storage ams, address _account)
        public
        view
        returns (bool)
    {
        return hasRole(ams, BANNED_ROLE_NAME(), _account);
    }

     /**
     * @dev Revokes `_role` from `_account`.
     */
    function revokeRole(
        AccessManagementState storage ams,
        bytes32 _role,
        address _account
    ) external {
        checkRole(ams, DEFAULT_ADMIN_ROLE(), msg.sender);
        require(
            _role != DEFAULT_ADMIN_ROLE() || _account != ams.contractOwner
        );
        require(
            _role != BANNED_ROLE_NAME() || msg.sender == ams.contractOwner
        );

        _revokeRole(ams, _role, _account);
    }

     /**
     * @dev Revokes `_role` from the calling account.
     */
    function renounceRole(AccessManagementState storage ams, bytes32 _role)
        external
    {
        require(
            _role != DEFAULT_ADMIN_ROLE() || msg.sender != ams.contractOwner
        );
        require(_role != BANNED_ROLE_NAME());
        _revokeRole(ams, _role, msg.sender);
    }

    /**
     * @dev Returns one of the accounts that have `_role`. `_index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     */
    function getRoleMember(
        AccessManagementState storage ams,
        bytes32 _role,
        uint256 _index
    ) external view returns (address) {
        return ams.roleMembers[_role].at(_index);
    }

    /**
     * @dev Returns the number of accounts that have `_role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(
        AccessManagementState storage ams,
        bytes32 _role
    ) external view returns (uint256) {
        return ams.roleMembers[_role].length();
    }

    function _grantRole(
        AccessManagementState storage ams,
        bytes32 _role,
        address _account
    ) private {
        if (!hasRole(ams, _role, _account)) {
            ams.roles[_role].members[_account] = true;
            ams.roleMembers[_role].add(_account);
            emit RoleGranted(_role, _account, msg.sender);
        }
    }

    function _revokeRole(
        AccessManagementState storage ams,
        bytes32 _role,
        address _account
    ) private {
        if (hasRole(ams, _role, _account)) {
            ams.roles[_role].members[_account] = false;
            ams.roleMembers[_role].remove(_account);
            emit RoleRevoked(_role, _account, msg.sender);
        }
    }
}

// File: ERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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

// File: IAccessControlEnumerable.sol

// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// File: IUriManager.sol

/**
 * @notice A URI Manager keeps track of which token has which URI.
 */
interface IUriManager is IERC165  {
    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `_tokenId` token.
     * 
     * @param _tokenId the tokenId
     */
    function getTokenURI(uint256 _tokenId) external view returns (string memory);
    
    /**
     * @dev Override the baseURI + tokenId scheme for determining the token 
     * URI with the specified custom URI.
     *
     * @param _tokenId The token to use the custom URI
     * @param _newUri The custom URI
     */
    function setCustomURI(uint256 _tokenId, string memory _newUri) external;

    /**
     * @dev Base URI for computing {tokenURI}. The resulting URI for each
     * token will be he concatenation of the `baseURI` and the `tokenId`.
     */
    function baseURI() external view returns (string memory);

    /**
     * @param _baseURI the new base URI.
     */
    function setBaseURI(string memory _baseURI) external;
}
// File: Monotonic.sol

// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)

/**
@notice Provides monotonic increasing and decreasing values, similar to
OpenZeppelin's Counter but (a) limited in direction, and (b) allowing for steps
> 1.
 */
library Monotonic {
    using SafeMath for uint256;

    /**
    @notice Holds a value that can only increase.
    @dev The internal value MUST NOT be accessed directly. Instead use current()
    and add().
     */
    struct Increaser {
        uint256 value;
    }

    /// @notice Returns the current value of the Increaser.
    function current(Increaser storage incr) internal view returns (uint256) {
        return incr.value;
    }

    /// @notice Adds x to the Increaser's value.
    function add(Increaser storage incr, uint256 x) internal {
        incr.value += x;
    }

    /**
    @notice Holds a value that can only decrease.
    @dev The internal value MUST NOT be accessed directly. Instead use current()
    and subtract().
     */
    struct Decreaser {
        uint256 value;
    }

    /// @notice Returns the current value of the Decreaser.
    function current(Decreaser storage decr) internal view returns (uint256) {
        return decr.value;
    }

    /// @notice Subtracts x from the Decreaser's value.
    function subtract(Decreaser storage decr, uint256 x) internal {
        decr.value -= x;
    }

    struct Counter{
        uint256 value;
    }

    function current(Counter storage _counter) internal view returns (uint256) {
        return _counter.value;
    }

    function add(Counter storage _augend, uint256 _addend) internal returns (uint256) {
        _augend.value += _addend;
        return _augend.value;
    }

    function subtract(Counter storage _minuend, uint256 _subtrahend) internal returns (uint256) {
        _minuend.value -= _subtrahend;
        return _minuend.value;
    }

    function increment(Counter storage _counter) internal returns (uint256) {
        return add(_counter, 1);
    }

    function decrement(Counter storage _counter) internal returns (uint256) {
        return subtract(_counter, 1);
    }

    function reset(Counter storage _counter) internal {
        _counter.value = 0;
    }
}

// File: ITokenManager.sol

/**
 * @dev Adds some functions from `IERC721Enumerable` and some callback hooks 
 * for when tokens are minted.
 */
interface ITokenManager is IUriManager {
    /**
     * @notice returns the total number of tokens that may be minted.
     */
    function maxSupply() external view returns (uint256);

    /**
     * @notice returns the current number of tokens that have been minted.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice returns the current number of tokens available to be minted.
     * @dev This should be maxSupply() - totalSupply()
     */
    function totalAvailable() external view returns (uint256);

    /**
     * @dev Returns the number of tokens in ``_owner``'s account.
     */
    function balanceOf(address _owner) external view returns (uint256 balance);

    /**
     * @dev Returns a token ID owned by `_owner` at a given `_index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``_owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 _index) external view returns (uint256);
    
    /**
     * @notice Returns a list of all the token ids owned by an address.
     */
    function userWallet(address _user) external view returns (uint256[] memory);

    /**
     * @dev Hook that is called before normal minting.
     * 
     * @param _category Type, group, option name etc.
     * @param _toAddress The account to receive the newly minted token.
     * @param _tokenId The id of the new token.
     */
    function beforeMint(
        string memory _category,
        address _toAddress,
        uint256 _tokenId
    ) external;

    /**
     * @dev Hook that is called before batch minting.
     * 
     * @param _category Type, group, option name etc.
     * @param _toAddresses The accounts to receive the newly minted tokens.
     * @param _tokenIds The ids of the new tokens.
     */
    function beforeBatchMint(
        string memory _category,
        address[] memory _toAddresses,
        uint256[] memory _tokenIds
    ) external;

    /**
     * @dev Hook that is called before custom minting.
     * 
     * @param _category Type, group, option name etc.
     * @param _toAddress The account to receive the newly minted token.
     * @param _tokenId The id of the new token.
     * @param _customURI the custom URI.
     */
    function beforeMintCustom(
        string memory _category,
        address _toAddress,
        uint256 _tokenId,
        string memory _customURI
    ) external;

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
     */
    function beforeTokenTransfer(
        address _fromAddress,
        address _toAddress,
        uint256 _tokenId
    ) external;

    /**
     * @dev Cause the transaction to revert if `_toAddress` is a contract that does 
     * not implement {onERC721Received}.
     * @dev See the warnings on {Address.isContract} for reasons why this function
     * might fail to identify an unsafe address.
     *
     * @param _fromAddress address representing the previous owner of the given token ID
     * @param _toAddress target address that will receive the tokens
     * @param _tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function checkOnERC721Received(
        address _fromAddress,
        address _toAddress,
        uint256 _tokenId,
        bytes memory _data) external returns (bool);
}

// File: ViciAccess.sol

/**
 * @title ViciAccess
 * @author Josh Davis <[email protected]>
 */
abstract contract ViciAccess is IAccessControlEnumerable, Context, ERC165 {
    using AccessManagement for AccessManagement.AccessManagementState;

    AccessManagement.AccessManagementState ams;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    // Role for banned users.
    bytes32 public constant BANNED_ROLE_NAME = "banned";

    constructor() {
        ams.setContractOwner(msg.sender);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return 
            interfaceId == type(IAccessControl).interfaceId || 
            interfaceId == type(IAccessControlEnumerable).interfaceId || 
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    modifier onlyOwnerOrRole(bytes32 role) {
        if (_msgSender() != owner()) {
            _checkRole(role, _msgSender());
        }
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender());
        _;
    }

    modifier noBannedAccounts() {
        require(!hasRole(BANNED_ROLE_NAME, _msgSender()));
        _;
    }

    function _isBanned(address account) internal virtual returns (bool) {
        return hasRole(BANNED_ROLE_NAME, account);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return ams.hasRole(role, account);
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        ams.checkRole(role, account);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32) public pure override returns (bytes32) {
        return DEFAULT_ADMIN_ROLE;
    }

    /**
     *  Requirements:
     *
     * - Calling user MUST have the admin role
     * - If `roll` is banned, calling user MUST be the owner
     *   and `address` MUST NOT be the owner.
     *
     * @inheritdoc IAccessControl
     */
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
    {
        ams.grantRole(role, account);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return ams.getContractOwner();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return ams.getRoleMember(role, index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return ams.getRoleMemberCount(role);
    }

    /**
     * Make another account the owner of this contract.
     * @param newOwner the new owner.
     *
     * Requirements:
     *
     * - Calling user MUST be owner.
     * - `newOwner` MUST NOT have the banned role.
     */
    function transferOwnership(address newOwner)
        public
        virtual
    {
        ams.setContractOwner(newOwner);
    }

    /**
     * Take the role away from the account. This will throw an exception
     * if you try to take the admin role (0x00) away from the owner.
     *
     * Requirements:
     *
     * - Calling user has admin role.
     * - If `role` is admin, `address` MUST NOT be owner.
     * - if `role` is banned, calling user MUST be owner.
     *
     * @inheritdoc IAccessControl
     */
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
    {
        ams.revokeRole(role, account);
    }

    /**
     * Take a role away from yourself. This will throw an exception if you
     * are the contract owner and you are trying to renounce the admin role (0x00).
     *
     * Requirements:
     *
     * - if `role` is admin, calling user MUST NOT be owner.
     * - `account` MUST be the same as the calling user.
     * - `role` MUST NOT be banned.
     *
     * @inheritdoc IAccessControl
     */
    function renounceRole(bytes32 role, address)
        public
        virtual
        override
    {
        ams.renounceRole(role);
    }
}

// File: ITokenDropManager.sol

struct Drop {
    string dropName;
    uint32 dropStartTime;
    uint32 dropSize;
    string baseURI;
}

/**
 * @dev A Token Drop Manager allows you to partition an NFT collection into
 * pools of various sizes and release dates, each with its own baseURI.
 */
interface ITokenDropManager is ITokenManager {
    event DropAnnounced(Drop drop);
    event DropEnded(Drop drop);
    
    /**
     * @dev Returns the number of tokens minted so far in a drop.
     *
     * @param _dropName The name of the drop
     */
    function dropMintCount(string memory _dropName)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the number of tokens that may still be minted in the named drop.
     *
     * @param _dropName The name of the drop
     */
    function amountRemainingInDrop(string memory _dropName)
        external
        view
        returns (uint256);

    /**
     * @notice A drop is active if it has been started and has neither run out of supply
     * or been stopped manually.
     * @dev Returns true if the `_dropName` refers to an active drop.
     */
    function isDropActive(string memory _dropName) external view returns (bool);

    /**
     * @dev Returns the number of drops that have been created.
     */
    function dropCount() external view returns (uint256);

    /**
     * @dev Return the name of a drop at `_index`. Use along with {dropCount()} to
     * iterate through all the drop names.
     */
    function dropNameForIndex(uint256 _index)
        external
        view
        returns (string memory);

    /**
     * @dev Return the drop at `_index`. Use along with {dropCount()} to iterate through
     * all the drops.
     */
    function dropForIndex(uint256 _index) external view returns (Drop memory);

    /**
     * @dev returns the drop with the given name.
     * @dev if there is no drop with the name, the function should return an
     * empty drop.
     */
    function dropForName(string memory _dropName)
        external
        view
        returns (Drop memory);

    /**
     * @dev Change the base URI for the named drop.
     */
    function setBaseURI(string memory _dropName, string memory _baseURI)
        external;

    /**
     * @notice Starts a new drop.
     * @param _dropName The name of the new drop
     * @param _dropStartTime The unix timestamp of when the drop is active
     * @param _dropSize The number of NFTs in this drop
     * @param _baseURI The base URI for the tokens in this drop
     */
    function startNewDrop(
        string memory _dropName,
        uint32 _dropStartTime,
        uint32 _dropSize,
        string memory _baseURI
    ) external;

    /**
     * @notice Starts a new drop within a parent drop.
     * @param _parentDropName The name of the parent drop
     * @param _dropName The name of the new drop
     * @param _dropSize The number of NFTs in this drop
     * @param _baseURI The base URI for the tokens in this drop
     */
    function startSubDrop(
        string memory _parentDropName,
        string memory _dropName,
        uint32 _dropSize,
        string memory _baseURI
    ) external;

    /**
     * @notice Ends the named drop immediately. It's not necessary to call this.
     * The current drop ends automatically once the last token is sold.
     *
     * @param _dropName The name of the drop to deactivate
     */
    function deactivateDrop(string memory _dropName) external;
}

// File: TokenEnumerator.sol

/**
 * @dev The TokenEnumerator pulls all of the code specific to the ERC721Enumerable
 * extension into a separate contract, so that the main ERC721 contract can delegate that
 * behavior and stay under the bytecode limit.
 */
abstract contract TokenEnumerator is ITokenManager {
    using Address for address;
    using SafeMath for uint256;

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private allTokensIndex;

    // Mapping owner address to token count
    mapping(address => uint256) private balances;

    uint256 public maxSupply;

    constructor(uint256 _maxSupply) {
        maxSupply = _maxSupply;
    }

    // @inheritdoc ITokenManager
    function balanceOf(address _owner) public view returns (uint256 balance) {
        require(
            _owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return balances[_owner];
    }

    // @inheritdoc ITokenManager
    function totalSupply() public view returns (uint256) {
        return allTokens.length;
    }

    // @inheritdoc ITokenManager
    function totalAvailable() public view returns (uint256) {
        return maxSupply - totalSupply();
    }

    // @inheritdoc ITokenManager
    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        public
        view
        returns (uint256)
    {
        require(
            _index < balanceOf(_owner),
            "ERC721Enumerable: _owner index out of bounds"
        );
        return ownedTokens[_owner][_index];
    }

    // @inheritdoc ITokenManager
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(
            index < totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
        return allTokens[index];
    }

    // @inheritdoc ITokenManager
    function userWallet(address _user) public view returns (uint256[] memory) {
        uint256 userTokenCount = balanceOf(_user);
        uint256[] memory ownedTokenIds = new uint256[](userTokenCount);
        for (uint256 i = 0; i < userTokenCount; i++) {
            ownedTokenIds[i] = tokenOfOwnerByIndex(_user, i);
        }

        return ownedTokenIds;
    }

   // @inheritdoc ITokenManager
    function beforeTokenTransfer(
        address _fromAddress,
        address _toAddress,
        uint256 _tokenId
    ) public virtual {
        _beforeTokenTransfer(_fromAddress, _toAddress, _tokenId);
    }

    function _beforeTokenTransfer(
        address _fromAddress,
        address _toAddress,
        uint256 _tokenId
    ) internal virtual {
        if (_fromAddress == address(0)) {
            _addTokenToAllTokensEnumeration(_tokenId);
            _post_mint_hook(_tokenId);
        } else if (_fromAddress != _toAddress) {
            _removeTokenFromOwnerEnumeration(_fromAddress, _tokenId);
            balances[_fromAddress] -= 1;
        }
        if (_toAddress == address(0)) {
            _removeTokenFromAllTokensEnumeration(_tokenId);
            _post_burn_hook(_tokenId);
        } else if (_toAddress != _fromAddress) {
            _addTokenToOwnerEnumeration(_toAddress, _tokenId);
            balances[_toAddress] += 1;
        }
    }

    function _post_mint_hook(uint256 _tokenId) internal virtual {}
    function _post_burn_hook(uint256 _tokenId) internal virtual {}

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param _toAddress address representing the new owner of the given token ID
     * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address _toAddress, uint256 _tokenId)
        private
    {
        uint256 length = balanceOf(_toAddress);
        ownedTokens[_toAddress][length] = _tokenId;
        ownedTokensIndex[_tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param _tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 _tokenId) private {
        allTokensIndex[_tokenId] = allTokens.length;
        allTokens.push(_tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the ownedTokens array.
     * @param _fromAddress address representing the previous owner of the given token ID
     * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(
        address _fromAddress,
        uint256 _tokenId
    ) private {
        // To prevent a gap in _fromAddress's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = balanceOf(_fromAddress) - 1;
        uint256 tokenIndex = ownedTokensIndex[_tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = ownedTokens[_fromAddress][lastTokenIndex];

            ownedTokens[_fromAddress][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete ownedTokensIndex[_tokenId];
        delete ownedTokens[_fromAddress][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the allTokens array.
     * @param _tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 _tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = allTokens.length - 1;
        uint256 tokenIndex = allTokensIndex[_tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = allTokens[lastTokenIndex];

        allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete allTokensIndex[_tokenId];
        allTokens.pop();
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param _fromAddress address representing the previous owner of the given token ID
     * @param _toAddress target address that will receive the tokens
     * @param _tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address _fromAddress,
        address _toAddress,
        uint256 _tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (_toAddress.isContract()) {
            try
                IERC721Receiver(_toAddress).onERC721Received(
                    msg.sender,
                    _fromAddress,
                    _tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert();
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
}

// File: TokenDropManager.sol

contract TokenDropManager is ITokenDropManager, TokenEnumerator, ViciAccess {
    using Strings for string;
    using SafeMath for uint256;
    using Monotonic for Monotonic.Counter;

    // Creator can create a new token type and mint an initial supply.
    bytes32 public constant URI_MANAGER = "URI Manager";

    // Creator can create a new token type and mint an initial supply.
    bytes32 public constant DROP_MANAGER = "Drop Manager";

    string[] internal allDropNames;

    mapping(string => Drop) internal dropByName;
    mapping(uint256 => string) internal dropNameByTokenId;
    mapping(string => Monotonic.Counter) internal dropMintCounts;
    mapping(string => bool) internal activeDrops;

    string public baseURI;
    mapping(uint256 => string) internal customURIs;
    uint256 tokensReserved;

    constructor(uint256 _maxSupply) TokenEnumerator(_maxSupply) {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ViciAccess)
        returns (bool)
    {
        return
            interfaceId == type(IUriManager).interfaceId ||
            interfaceId == type(ITokenDropManager).interfaceId ||
            interfaceId == type(ITokenManager).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * Requirements:
     *
     * - This function MAY be called with an invalid drop name. The answer will be 0.
     * - This function MAY be called with an empty drop name. The answer will be the
     *    remaining supply for the entire collection minus the number reserved by active drops.
     *
     * @inheritdoc ITokenDropManager
     */
    function amountRemainingInDrop(string memory _dropName)
        public
        view
        returns (uint256)
    {
        if (bytes(_dropName).length == 0) {
            return totalAvailable() - tokensReserved;
        }

        if (!activeDrops[_dropName]) {
            return 0;
        }

        Drop storage currentDrop = dropByName[_dropName];
        if (!_isRealDrop(currentDrop)) {
            return 0;
        }

        return currentDrop.dropSize - dropMintCounts[_dropName].current();
    }

    /**
     * Requirements:
     *
     * - This function MAY be called with an invalid drop name. The answer will be 0.
     * - This function MAY be called with an empty drop name. The answer will be 0.
     *
     * @inheritdoc ITokenDropManager
     */
    function dropMintCount(string memory _dropName)
        public
        view
        returns (uint256)
    {
        return dropMintCounts[_dropName].current();
    }

    /**
     * @inheritdoc ITokenDropManager
     */
    function dropCount() public view returns (uint256) {
        return allDropNames.length;
    }

    /**
     * @inheritdoc ITokenDropManager
     */
    function dropNameForIndex(uint256 _index)
        public
        view
        returns (string memory)
    {
        return allDropNames[_index];
    }

    /**
     * @inheritdoc ITokenDropManager
     */
    function dropForIndex(uint256 _index) public view returns (Drop memory) {
        return dropByName[dropNameForIndex(_index)];
    }

    /**
     * @inheritdoc ITokenDropManager
     */
    function dropForName(string memory _dropName)
        public
        view
        returns (Drop memory)
    {
        return dropByName[_dropName];
    }

    /**
     * Requirements:
     *
     * - This function MAY be called with an invalid drop name. The answer will be false.
     * - This function MAY be called with an empty drop name. The answer will be false.
     *
     * @inheritdoc ITokenDropManager
     */
    function isDropActive(string memory _dropName) public view returns (bool) {
        return activeDrops[_dropName];
    }

    /**
     * Requirements:
     *
     * - Calling user MUST be owner or URI manager.
     * - `_dropName` MUST refer to a valid drop.
     * - `_baseURI` MUST be different from the current `baseURI` for the named drop.
     * - `_dropName` MAY refer to an active or inactive drop.
     *
     * @inheritdoc ITokenDropManager
     */
    function setBaseURI(string memory _dropName, string memory _baseURI)
        public
        onlyOwnerOrRole(URI_MANAGER)
    {
        require(bytes(_dropName).length > 0);
        Drop storage currentDrop = dropByName[_dropName];
        require(_isRealDrop(currentDrop));
        require(
            keccak256(bytes(_dropName)) != keccak256(bytes(currentDrop.baseURI))
        );
        currentDrop.baseURI = _baseURI;
    }

    /**
     * Requirements:
     *
     * - Calling user MUST be owner or have the drop manager role.
     * - There MUST be sufficient unreserved tokens for the drop size.
     * - The drop size MUST NOT be empty.
     * - The drop name MUST NOT be empty.
     * - The drop name MUST be unique.
     *
     * @inheritdoc ITokenDropManager
     */
    function startNewDrop(
        string memory _dropName,
        uint32 _dropStartTime,
        uint32 _dropSize,
        string memory _baseURI
    ) public onlyOwnerOrRole(DROP_MANAGER) {
        require(_dropSize > 0);
        require(_dropSize <= totalAvailable() - tokensReserved);
        require(bytes(_dropName).length > 0);
        require(!_isRealDrop(dropByName[_dropName]));

        allDropNames.push(_dropName);
        _startDrop(_dropName, _dropStartTime, _dropSize, _baseURI);
    }

    /**
     * @notice If the `_dropSize` is equal to the the number of tokens
     * remaining in the parent drop, the parent drop will be ended.
     *
     * Requirements:
     *
     * - Calling user MUST be owner or have the drop manager role.
     * - The drop size MUST NOT be empty.
     * - The drop name MUST NOT be empty.
     * - The drop name MUST be unique.
     * - The parent drop MUST be active.
     * - The parent drop MUST be sufficient remaining tokens for the drop size.
     *
     * @inheritdoc ITokenDropManager
     */
    function startSubDrop(
        string memory _parentDropName,
        string memory _dropName,
        uint32 _dropSize,
        string memory _baseURI
    ) public onlyOwnerOrRole(DROP_MANAGER) {
        require(_dropSize > 0);
        require(bytes(_dropName).length > 0);
        require(activeDrops[_parentDropName]);
        require(!_isRealDrop(dropByName[_dropName]));

        Drop storage parentDrop = dropByName[_parentDropName];
        require(_isRealDrop(parentDrop));

        uint256 remainingInParent = parentDrop.dropSize -
            dropMintCounts[_parentDropName].current();
        require(remainingInParent >= _dropSize);

        if (bytes(_baseURI).length == 0) {
            _baseURI = parentDrop.baseURI;
        }

        _endDrop(parentDrop);
        if (remainingInParent > _dropSize) {
            _startDrop(
                _parentDropName,
                parentDrop.dropStartTime,
                parentDrop.dropSize - _dropSize,
                parentDrop.baseURI
            );
        }

        allDropNames.push(_dropName);
        _startDrop(_dropName, parentDrop.dropStartTime, _dropSize, _baseURI);
    }

    function _startDrop(
        string memory _dropName,
        uint32 _dropStartTime,
        uint32 _dropSize,
        string memory _baseURI
    ) internal virtual {
        Drop memory newDrop = Drop(
            _dropName,
            _dropStartTime,
            _dropSize,
            _baseURI
        );
        dropByName[_dropName] = newDrop;
        tokensReserved += _dropSize;
        activeDrops[_dropName] = true;
        emit DropAnnounced(newDrop);
    }

    /**
     * Requirements:
     *
     * - Calling user MUST be owner or have the drop manager role.
     * - There MUST be an active drop with the `_dropName`.
     *
     * @inheritdoc ITokenDropManager
     */
    function deactivateDrop(string memory _dropName)
        public
        onlyOwnerOrRole(DROP_MANAGER)
    {
        require(activeDrops[_dropName]);
        Drop storage currentDrop = dropByName[_dropName];
        _endDrop(currentDrop);
    }

    /**
     * @notice This sets the baseURI for any tokens minted outside of a drop.
     *
     * Requirements:
     *
     * - Calling user MUST be owner or have the uri manager role.
     *
     * @inheritdoc IUriManager
     */
    function setBaseURI(string memory _baseURI)
        public
        onlyOwnerOrRole(URI_MANAGER)
    {
        baseURI = _baseURI;
    }

    /**
     * Requirements:
     *
     * - Calling user MUST be owner or have the uri manager role.
     *
     * @inheritdoc IUriManager
     */
    function setCustomURI(uint256 tokenId, string memory newURI)
        public
        onlyOwnerOrRole(URI_MANAGER)
    {
        customURIs[tokenId] = newURI;
        emit URI(newURI, tokenId);
    }

    /**
     * @inheritdoc IUriManager
     */
    function getTokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        // We have to convert string to bytes to check for existence
        bytes memory customUriBytes = bytes(customURIs[_tokenId]);
        if (customUriBytes.length > 0) {
            return customURIs[_tokenId];
        }

        string memory base;
        Drop storage currentDrop = dropByName[dropNameByTokenId[_tokenId]];
        if (_isRealDrop(currentDrop)) {
            base = currentDrop.baseURI;
        } else {
            base = baseURI;
        }

        if (bytes(base).length > 0) {
            return string(abi.encodePacked(base, Strings.toString(_tokenId)));
        }

        return "";
    }

    /**
     * Requirements:
     *
     * - Calling user MUST be owner.
     *
     * @inheritdoc ITokenManager
     */
    function beforeTokenTransfer(
        address _fromAddress,
        address _toAddress,
        uint256 _tokenId
    ) public virtual override(ITokenManager, TokenEnumerator) onlyOwner {
        TokenEnumerator.beforeTokenTransfer(_fromAddress, _toAddress, _tokenId);
    }

    /**
     * Requirements:
     *
     * - Calling user MUST be owner.
     * - if `_category` is empty string, `_quantity` MUST NOT exceed generally available supply.
     * -if `_category` is not empty string
     *    - `_category` MUST refer to a valid drop
     *    - `_category` MUST refer to an active drop
     *    - the named drop's start time MUST NOT be in the future
     *    - `_quantity` MUST NOT exceed amount remaining in drop
     *
     * @inheritdoc ITokenManager
     */
    function beforeMint(
        string memory _category,
        address,
        uint256 _tokenId
    ) public virtual onlyOwner {
        require(totalAvailable() > 0, "sold out");
        Drop storage currentDrop = _pre_mint(_category, 1);
        _post_mint(currentDrop, _tokenId);
    }

    /**
     * Requirements:
     *
     * - Calling user MUST be owner.
     * - `_toAddresses` and `_tokenIds` MUST be the same length.
     * - if `_category` is empty string, `_quantity` MUST NOT exceed generally available supply.
     * -if `_category` is not empty string
     *    - `_category` MUST refer to a valid drop
     *    - `_category` MUST refer to an active drop
     *    - the named drop's start time MUST NOT be in the future
     *    - `_quantity` MUST NOT exceed amount remaining in drop
     *
     * @inheritdoc ITokenManager
     */
    function beforeBatchMint(
        string memory _category,
        address[] memory _toAddresses,
        uint256[] memory _tokenIds
    ) public virtual onlyOwner {
        require(_toAddresses.length == _tokenIds.length);
        require(totalAvailable() >= _toAddresses.length);
        Drop storage currentDrop = _pre_mint(_category, _tokenIds.length);
        _post_mint(currentDrop, _tokenIds);
    }

    /**
     * Requirements:
     * - if `_category` is empty string, `_quantity` MUST NOT exceed generally available supply.
     * -if `_category` is not empty string
     *    - `_category` MUST refer to a valid drop
     *    - `_category` MUST refer to an active drop
     *    - the named drop's start time MUST NOT be in the future
     *    - `_quantity` MUST NOT exceed amount remaining in drop
     *
     * - Calling user MUST be owner.
     *
     * @inheritdoc ITokenManager
     */
    function beforeMintCustom(
        string memory _category,
        address,
        uint256 _tokenId,
        string memory _customURI
    ) public virtual onlyOwner {
        require(totalAvailable() > 0, "sold out");

        Drop storage currentDrop = _pre_mint(_category, 1);
        bytes memory customUriBytes = bytes(_customURI);
        if (customUriBytes.length > 0) {
            setCustomURI(_tokenId, _customURI);
        }
        _post_mint(currentDrop, _tokenId);
    }

    /**
     * Requirements:
     *
     * - Calling user MUST be owner.
     *
     * @inheritdoc ITokenManager
     */
    function checkOnERC721Received(
        address _fromAddress,
        address _toAddress,
        uint256 _tokenId,
        bytes memory _data
    ) public onlyOwner returns (bool) {
        return
            _checkOnERC721Received(_fromAddress, _toAddress, _tokenId, _data);
    }

    /**
     * - if `_category` is empty string, `_quantity` MUST NOT exceed generally available supply.
     * -if `_category` is not empty string
     *    - `_category` MUST refer to a valid drop
     *    - `_category` MUST refer to an active drop
     *    - the named drop's start time MUST NOT be in the future
     *    - `_quantity` MUST NOT exceed amount remaining in drop
     */
    function _pre_mint(string memory _category, uint256 _quantity)
        internal
        returns (Drop storage currentDrop)
    {
        currentDrop = dropByName[_category];

        if (bytes(_category).length == 0) {
            require(_quantity <= totalAvailable() - tokensReserved, "sold out");
            return currentDrop;
        }

        require(activeDrops[_category], "no drop");
        require(_isRealDrop(currentDrop), "no drop");
        require(block.timestamp >= currentDrop.dropStartTime, "early");
        require(
            currentDrop.dropSize - dropMintCounts[_category].current() >=
                _quantity,
            "sold out"
        );

        tokensReserved -= _quantity;

        dropMintCounts[_category].add(_quantity);
        if (dropMintCounts[_category].current() >= currentDrop.dropSize) {
            _endDrop(currentDrop);
        }
    }

    function _post_mint(Drop storage _currentDrop, uint256 _tokenId) internal virtual {
        if (_isRealDrop(_currentDrop)) {
            dropNameByTokenId[_tokenId] = _currentDrop.dropName;
        }
    }

    function _post_mint(Drop storage _currentDrop, uint256[] memory _tokenIds)
        internal virtual
    {
        if (_isRealDrop(_currentDrop)) {
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                dropNameByTokenId[_tokenIds[i]] = _currentDrop.dropName;
            }
        }
    }

    function _isRealDrop(Drop storage testDrop) internal virtual view returns (bool) {
        return testDrop.dropSize != 0;
    }

    function _endDrop(Drop storage oldDrop) internal {
        if (activeDrops[oldDrop.dropName]) {
            activeDrops[oldDrop.dropName] = false;

            if (oldDrop.dropSize > dropMintCounts[oldDrop.dropName].current()) {
                tokensReserved -= (oldDrop.dropSize -
                    dropMintCounts[oldDrop.dropName].current());
            }
            emit DropEnded(oldDrop);
        }
    }

    function _post_burn_hook(uint256 _tokenId) internal virtual override {
        super._post_burn_hook(_tokenId);

        string memory dropName = dropNameByTokenId[_tokenId];
        Drop storage currentDrop = dropByName[dropName];
        if (_isRealDrop(currentDrop)) {
            dropMintCounts[dropName].decrement();
            delete dropNameByTokenId[_tokenId];
        }
    }
}

// File: StateMachineDropManager.sol

/**
 * @notice This contract supports NFTs that can have a different
 *   token URI depending on a current state.
 */
contract StateMachineDropManager is TokenDropManager {
    string public constant INITIAL_STATE = "NEW";
    string public constant INVALID_STATE = "INVALID";

    struct TokenState {
        string dropState;
        string stateName;
        string baseURI;
        mapping(string => bool) transitions;
    }

    mapping(string => mapping(string => TokenState)) internal dropStateMachine;
    mapping(uint256 => string) internal stateForToken;

    event StateChange(uint256 indexed tokenId, string oldState, string newState);

    constructor(uint256 _maxSupply) TokenDropManager(_maxSupply) {}

    /**
     * @notice Sets up a state transition
     * 
     * Requirements:
     * - `_dropName` MUST refer to a valid drop
     * - `_fromState` MUST refer to a valid state for `_dropName`
     * - `_toState` MUST not be empty
     * - `_baseURI` MUST not be empty
     * - A transition named `_toState` MUST NOT already be defined for `_fromState`
     *    in the drop named `_dropName`
     */
    function addStateTransition(
        string memory _dropName,
        string memory _fromState,
        string memory _toState,
        string memory _baseURI
    ) public onlyOwnerOrRole(DROP_MANAGER) {
        require(bytes(_fromState).length > 0);
        require(bytes(_toState).length > 0);
        require(bytes(_baseURI).length > 0);
        require(_isRealDrop(dropByName[_dropName]));

        TokenState storage fromState = dropStateMachine[_dropName][_fromState];
        require(_stateIsValid(fromState));
        require(!fromState.transitions[_toState]);

        TokenState storage toState = dropStateMachine[_dropName][_toState];

        if (!_stateIsValid(toState)) {
            toState.stateName = _toState;
            toState.baseURI = _baseURI;
        }

        fromState.transitions[_toState] = true;
    }

    function _stateExistsForDrop(string memory _dropName, string memory _stateName) internal view returns (bool) {
        return _stateIsValid(dropStateMachine[_dropName][_stateName]);
    }

    function _stateIsValid(TokenState storage _state) internal view returns (bool) {
        return bytes(_state.stateName).length > 0;
    }

    /**
     * @notice Changes the state for the specified token to the new state.
     *
     * Requirements
     * - `_tokenId` must be in a state with a valid state transition
     *   named `_stateName`
     */
    function changeState(uint256 _tokenId, string memory _stateName)
        public
        onlyOwnerOrRole(DROP_MANAGER)
    {
        string memory dropName = dropNameByTokenId[_tokenId];
        require(_stateExistsForDrop(dropName, _stateName));
        string memory currentStateName = stateForToken[_tokenId];
        TokenState storage currentState = dropStateMachine[dropName][currentStateName];
        require(_stateIsValid(currentState));
        require(currentState.transitions[_stateName]);

        stateForToken[_tokenId] = _stateName;
        emit StateChange(_tokenId, currentStateName, _stateName);
        emit URI(getTokenURI(_tokenId), _tokenId);
    }

    function getState(uint256 _tokenId) public view returns (string memory) {
        string memory state = stateForToken[_tokenId];
        if (bytes(state).length > 0) {
            return state;
        }

        return INVALID_STATE;
    }

    /**
     * @inheritdoc IUriManager
     */
    function getTokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory dropName = dropNameByTokenId[_tokenId];
        string memory currentStateName = stateForToken[_tokenId];
        TokenState storage currentState = dropStateMachine[dropName][currentStateName];

        if (!_stateIsValid(currentState)) {
            return super.getTokenURI(_tokenId);
        }

        // We have to convert string to bytes to check for existence
        bytes memory customUriBytes = bytes(customURIs[_tokenId]);
        if (customUriBytes.length > 0) {
            return customURIs[_tokenId];
        }

        return string(abi.encodePacked(currentState.baseURI, Strings.toString(_tokenId)));
    }

    function _startDrop(
        string memory _dropName,
        uint32 _dropStartTime,
        uint32 _dropSize,
        string memory _baseURI
    ) internal virtual override {
        super._startDrop(_dropName, _dropStartTime, _dropSize, _baseURI);
        TokenState storage initialState = dropStateMachine[_dropName][INITIAL_STATE];
        initialState.stateName = INITIAL_STATE;
        initialState.baseURI = _baseURI;
    }

    function _post_mint(Drop storage _currentDrop, uint256 _tokenId)
        internal
        virtual
        override
    {
        super._post_mint(_currentDrop, _tokenId);
        if (_isRealDrop(_currentDrop)) {
            stateForToken[_tokenId] = INITIAL_STATE;
        }
    }

    function _post_mint(Drop storage _currentDrop, uint256[] memory _tokenIds)
        internal
        virtual
        override
    {
        super._post_mint(_currentDrop, _tokenIds);
        if (_isRealDrop(_currentDrop)) {
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                stateForToken[_tokenIds[i]] = INITIAL_STATE;
            }
        }
    }

    function _post_burn_hook(uint256 _tokenId) internal virtual override {
        delete stateForToken[_tokenId];
        super._post_burn_hook(_tokenId);
    }
}