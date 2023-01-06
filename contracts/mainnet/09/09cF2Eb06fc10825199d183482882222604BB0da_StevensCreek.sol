// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;



// File: Address.sol

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// File: ContextMixin.sol

abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// File: EnumerableSet.sol

// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// File: EnumerableUint256Set.sol

library EnumerableUint256Set {
    struct Uint256Set {
        uint256[] values;
        mapping(uint256 => uint256) indexes;
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Uint256Set storage _set, uint256 _value) internal view returns (bool) {
        return _set.indexes[_value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(Uint256Set storage _set) internal view returns (uint256) {
        return _set.values.length;
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
    function at(Uint256Set storage _set, uint256 _index) internal view returns (uint256) {
        return _set.values[_index];
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Uint256Set storage _set, uint256 _value) internal returns (bool) {
        if (!contains(_set, _value)) {
            _set.values.push(_value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            _set.indexes[_value] = _set.values.length;
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
    function remove(Uint256Set storage _set, uint256 _value) internal returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = _set.indexes[_value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = _set.values.length - 1;

            if (lastIndex != toDeleteIndex) {
                uint256 lastvalue = _set.values[lastIndex];

                // Move the last value to the index where the value to delete is
                _set.values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                _set.indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            _set.values.pop();

            // Delete the index for the deleted slot
            delete _set.indexes[_value];

            return true;
        } else {
            return false;
        }
    }

    function asList(Uint256Set storage _set) internal view returns (uint256[] memory) {
        return _set.values;
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

// File: IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// File: IERC721Receiver.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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

// File: RoyaltiesLib.sol

library _RoyaltiesErrorChecking {
    function validateParameters(address recipient, uint256 value)
        internal
        pure
    {
        require(
            value <= 10000,
            "ERC2981Royalties: Royalties can't exceed 100%."
        );
        require(
            value == 0 || recipient != address(0),
            "ERC2981Royalties: Can't send royalties to null address."
        );
    }
}

library ContractWideRoyalties {
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

    function setRoyalties(
        RoyaltyInfo storage rd,
        address recipient,
        uint256 value
    ) external {
        _RoyaltiesErrorChecking.validateParameters(recipient, value);
        rd.recipient = recipient;
        rd.amount = uint24(value);
    }

    function getRoyaltiesRecipient(RoyaltyInfo storage rd)
        external
        view
        returns (address)
    {
        return rd.recipient;
    }

    function getRoyalties(RoyaltyInfo storage rd, uint256 saleAmount)
        public
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = rd.recipient;
        royaltyAmount = (saleAmount * rd.amount) / 10000;
    }
}

library PerTokenRoyalties {
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

    struct RoyaltiesDisbursements {
        mapping(uint256 => RoyaltyInfo) schedule;
    }

    function setRoyalties(
        RoyaltiesDisbursements storage rd,
        uint256 tokenId,
        address recipient,
        uint256 value
    ) external {
        _RoyaltiesErrorChecking.validateParameters(recipient, value);
        rd.schedule[tokenId] = RoyaltyInfo(recipient, uint24(value));
    }

    function getRoyalties(
        RoyaltiesDisbursements storage rd,
        uint256 tokenId,
        uint256 saleAmount
    ) public view returns (address receiver, uint256 royaltyAmount) {
        RoyaltyInfo memory royaltyInfo = rd.schedule[tokenId];
        receiver = royaltyInfo.recipient;
        royaltyAmount = (saleAmount * royaltyInfo.amount) / 10000;
    }
}

// File: SafeMath.sol

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// File: StateMachine.sol

/**
 * @notice An implementation of a Finite State Machine.
 * @dev A State has a name, some arbitrary data, and a set of
 *   valid transitions.
 * @dev A State Machine has an initial state and a set of states.
 */
library StateMachine {
    struct State {
        string name;
        bytes data;
        mapping(string => bool) transitions;
    }

    struct States {
        string initialState;
        mapping(string => State) states;
    }

    /**
     * @dev You must call this before using the state machine.
     * @dev creates the initial state.
     * @param _startStateName The name of the initial state.
     * @param _data The data for the initial state.
     *
     * Requirements:
     * - The state machine MUST NOT already have an initial state.
     * - `_startStateName` MUST NOT be empty.
     * - `_startStateName` MUST NOT be the same as an existing state.
     */
    function initialize(
        States storage _stateMachine,
        string memory _startStateName,
        bytes memory _data
    ) external {
        require(bytes(_startStateName).length > 0, "invalid state name");
        require(
            bytes(_stateMachine.initialState).length == 0,
            "already initialized"
        );
        State storage startState = _stateMachine.states[_startStateName];
        require(!_isValid(startState), "duplicate state");
        _stateMachine.initialState = _startStateName;
        startState.name = _startStateName;
        startState.data = _data;
    }

    /**
     * @dev Returns the name of the iniital state.
     */
    function initialStateName(States storage _stateMachine)
        external
        view
        returns (string memory)
    {
        return _stateMachine.initialState;
    }

    /**
     * @dev Creates a new state transition, creating
     *   the "to" state if necessary.
     * @param _fromState the "from" side of the transition
     * @param _toState the "to" side of the transition
     * @param _data the data for the "to" state
     *
     * Requirements:
     * - `_fromState` MUST be the name of a valid state.
     * - There MUST NOT aleady be a transition from `_fromState`
     *   and `_toState`.
     * - `_toState` MUST NOT be empty
     * - `_toState` MAY be the name of an existing state. In
     *   this case, `_data` is ignored.
     * - `_toState` MAY be the name of a non-existing state. In
     *   this case, a new state is created with `_data`.
     */
    function addStateTransition(
        States storage _stateMachine,
        string memory _fromState,
        string memory _toState,
        bytes memory _data
    ) external {
        require(bytes(_toState).length > 0, "Missing to state");
        State storage fromState = _stateMachine.states[_fromState];
        require(_isValid(fromState), "invalid from state");
        require(!fromState.transitions[_toState], "duplicate transition");

        State storage toState = _stateMachine.states[_toState];
        if (!_isValid(toState)) {
            toState.name = _toState;
            toState.data = _data;
        }
        fromState.transitions[_toState] = true;
    }

    /**
     * @dev Removes a transtion. Does not remove any states.
     * @param _fromState the "from" side of the transition
     * @param _toState the "to" side of the transition
     *
     * Requirements:
     * - `_fromState` and `toState` MUST describe an existing transition.
     */
    function deleteStateTransition(
        States storage _stateMachine,
        string memory _fromState,
        string memory _toState
    ) external {
        require(
            _stateMachine.states[_fromState].transitions[_toState],
            "invalid transition"
        );
        _stateMachine.states[_fromState].transitions[_toState] = false;
    }

    /**
     * @dev Update the data for a state.
     * @param _stateName The state to be updated.
     * @param _data The new data
     *
     * Requirements:
     * - `_stateName` MUST be the name of a valid state.
     */
    function setStateData(
        States storage _stateMachine,
        string memory _stateName,
        bytes memory _data
    ) external {
        State storage state = _stateMachine.states[_stateName];
        require(_isValid(state), "invalid state");
        state.data = _data;
    }

    /**
     * @dev Returns the data for a state.
     * @param _stateName The state to be queried.
     *
     * Requirements:
     * - `_stateName` MUST be the name of a valid state.
     */
    function getStateData(
        States storage _stateMachine,
        string memory _stateName
    ) external view returns (bytes memory) {
        State storage state = _stateMachine.states[_stateName];
        require(_isValid(state), "invalid state");
        return state.data;
    }

    /**
     * @dev Returns true if the parameters describe a valid
     *   state transition.
     * @param _fromState the "from" side of the transition
     * @param _toState the "to" side of the transition
     */
    function isValidTransition(
        States storage _stateMachine,
        string memory _fromState,
        string memory _toState
    ) external view returns (bool) {
        return _stateMachine.states[_fromState].transitions[_toState];
    }

    /**
     * @dev Returns true if the state exists.
     * @param _stateName The state to be queried.
     */
    function isValidState(
        States storage _stateMachine,
        string memory _stateName
    ) external view returns (bool) {
        return _isValid(_stateMachine.states[_stateName]);
    }

    function _isValid(State storage _state) private view returns (bool) {
        return bytes(_state.name).length > 0;
    }
}

// File: Strings.sol

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

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

// File: AccessManagement.sol

interface ChainalysisSanctionsList {
    function isSanctioned(address addr) external view returns (bool);
}

contract EmptySanctionsList is ChainalysisSanctionsList {
    function isSanctioned(address) external pure override returns (bool) {
        return false;
    }
}

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
        ChainalysisSanctionsList sanctionsList;
        bool sanctionsComplianceEnabled;
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
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
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

    function MODERATOR_ROLE_NAME() public pure returns (bytes32) {
        return "moderator";
    }

    function initSanctions(AccessManagementState storage ams) external {
        require(
            address(ams.sanctionsList) == address(0),
            "already initialized"
        );
        // The official contract is deployed at the same address on each of
        // these blockchains.
        if (
            block.chainid == 137 || // Polygon
            block.chainid == 1 || // Ethereum
            block.chainid == 56 || // Binance Smart Chain
            block.chainid == 250 || // Fantom
            block.chainid == 10 || // Optimism
            block.chainid == 42161 || // Arbitrum
            block.chainid == 43114 || // Avalanche
            block.chainid == 25 || // Cronos
            false
        ) {
            _setSanctions(
                ams,
                ChainalysisSanctionsList(
                    address(0x40C57923924B5c5c5455c48D93317139ADDaC8fb)
                )
            );
        } else if (block.chainid == 80001) {
            _setSanctions(
                ams,
                ChainalysisSanctionsList(
                    address(0x07342d7d152dd01325f777f41FeDe5D4ACc4F8EC)
                )
            );
        } else {
            _setSanctions(ams, new EmptySanctionsList());
        }

        ams.sanctionsComplianceEnabled = true;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function setContractOwner(
        AccessManagementState storage ams,
        address _newOwner
    ) external {
        if (ams.contractOwner != address(0)) {
            enforceIsContractOwner(ams, msg.sender);
        }

        enforceIsNotBanned(ams, _newOwner);
        require(_newOwner != ams.contractOwner, "AccessControl: already owner");
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
    function enforceIsContractOwner(
        AccessManagementState storage ams,
        address account
    ) public view {
        require(account == ams.contractOwner, "AccessControl: not owner");
    }

    /**
     * @dev reverts if called by an account that is not the owner and doesn't 
     *     have the moderator role.
     */
    function enforceIsModerator(
        AccessManagementState storage ams,
        address account
    ) public view {
        require(
            account == ams.contractOwner ||
                hasRole(ams, MODERATOR_ROLE_NAME(), account),
            "AccessControl: not moderator"
        );
    }

    /**
     * @dev Reverts if called by a banned or sanctioned account.
     */
    function enforceIsNotBanned(
        AccessManagementState storage ams,
        address account
    ) public view {
        enforceIsNotSanctioned(ams, account);
        require(!isBanned(ams, account), "AccessControl: banned");
    }

    /**
     * @dev Reverts if called by an account on the OFAC sanctions list.
     */
    function enforceIsNotSanctioned(
        AccessManagementState storage ams,
        address addr
    ) public view {
        if (ams.sanctionsComplianceEnabled) {
            require(
                !ams.sanctionsList.isSanctioned(addr),
                "OFAC sanctioned address"
            );
        }
    }

    /**
     * @dev reverts if called by an account that is not the owner and doesn't 
     *     have the required role.
     */
    function enforceOwnerOrRole(
        AccessManagementState storage ams,
        bytes32 _role,
        address _account
    ) public view {
        if (_account != ams.contractOwner) {
            checkRole(ams, _role, _account);
        }
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
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(AccessManagementState storage ams, bytes32 role)
        public
        view
        returns (bytes32)
    {
        return ams.roles[role].adminRole;
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function setRoleAdmin(
        AccessManagementState storage ams,
        bytes32 role,
        bytes32 adminRole
    ) public {
        enforceOwnerOrRole(ams, getRoleAdmin(ams, role), msg.sender);
        bytes32 previousAdminRole = getRoleAdmin(ams, role);
        ams.roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `_role` to `_account`.
     */
    function grantRole(
        AccessManagementState storage ams,
        bytes32 _role,
        address _account
    ) external {
        enforceIsNotBanned(ams, msg.sender);
        if (_role == BANNED_ROLE_NAME()) {
            enforceIsModerator(ams, msg.sender);
            require(_account != ams.contractOwner, "AccessControl: ban owner");
        } else {
            enforceIsNotBanned(ams, _account);
            if (msg.sender != ams.contractOwner) {
                checkRole(ams, getRoleAdmin(ams, _role), msg.sender);
            }
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
        enforceIsNotBanned(ams, msg.sender);
        require(
            _role != DEFAULT_ADMIN_ROLE() || _account != ams.contractOwner,
            "AccessControl: revoke admin from owner"
        );
        if (_role == BANNED_ROLE_NAME()) {
            enforceIsModerator(ams, msg.sender);
        } else {
            enforceOwnerOrRole(ams, getRoleAdmin(ams, _role), msg.sender);
        }

        _revokeRole(ams, _role, _account);
    }

    /**
     * @dev Revokes `_role` from the calling account.
     */
    function renounceRole(AccessManagementState storage ams, bytes32 _role)
        external
    {
        require(
            _role != DEFAULT_ADMIN_ROLE() || msg.sender != ams.contractOwner,
            "AccessControl: owner renounce admin"
        );
        require(_role != BANNED_ROLE_NAME(), "AccessControl: self unban");
        checkRole(ams, _role, msg.sender);
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

    /**
     * @notice returns whether the address is sanctioned.
     */
    function isSanctioned(AccessManagementState storage ams, address addr)
        public
        view
        returns (bool)
    {
        return
            ams.sanctionsComplianceEnabled &&
            ams.sanctionsList.isSanctioned(addr);
    }

    /**
     * @notice Sets the sanction list oracle
     * @notice Reverts unless the contract is running on a local HardHat or
     *      Ganache chain.
     * @param _sanctionsList the oracle address
     */
    function setSanctions(
        AccessManagementState storage ams,
        ChainalysisSanctionsList _sanctionsList
    ) external {
        require(block.chainid == 31337 || block.chainid == 1337, "Not testnet");
        _setSanctions(ams, _sanctionsList);
    }

    /**
     * @notice returns the address of the OFAC sanctions oracle.
     */
    function getSanctionsOracle(AccessManagementState storage ams)
        public
        view
        returns (address)
    {
        return address(ams.sanctionsList);
    }

    /**
     * @notice toggles the sanctions compliance flag
     * @notice this flag should only be turned off during testing or if there
     *     is some problem with the sanctions oracle.
     *
     * Requirements:
     * - Caller must be the contract owner
     */
    function toggleSanctionsCompliance(AccessManagementState storage ams)
        public
    {
        ams.sanctionsComplianceEnabled = !ams.sanctionsComplianceEnabled;
    }

    /**
     * @dev returns true if sanctions compliance is enabled.
     */
    function isSanctionsComplianceEnabled(AccessManagementState storage ams)
        public
        view
        returns (bool)
    {
        return ams.sanctionsComplianceEnabled;
    }

    function _setSanctions(
        AccessManagementState storage ams,
        ChainalysisSanctionsList _sanctionsList
    ) internal {
        ams.sanctionsList = _sanctionsList;
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

// File: DynamicURI.sol

interface DynamicURI is IERC165 {
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

// File: IERC1155.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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

// File: IERC2981.sol

// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// File: IERC721.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// File: OwnerOperatorApproval.sol

/**
 * @title OwnerOperatorApproval
 *
 * @dev This library manages ownership of items, and allows an owner to delegate
 *     other addresses as their agent.
 * @dev It can be used to manage ownership of various types of tokens, such as
 *     ERC20, ERC677, ERC721, ERC777, and ERC1155.
 * @dev For coin-type tokens such as ERC20, ERC677, or ERC721, always pass `1`
 *     as `thing`. Comments that refer to the use of this library to manage
 *     these types of tokens will use the shorthand `COINS:`.
 * @dev For NFT-type tokens such as ERC721, always pass `1` as the `amount`.
 *     Comments that refer to the use of this library to manage these types of
 *     tokens will use the shorthand `NFTS:`.
 * @dev For semi-fungible tokens such as ERC1155, use `thing` as the token ID
 *     and `amount` as the number of tokens with that ID.
 */
library OwnerOperatorApproval {
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableUint256Set for EnumerableUint256Set.Uint256Set;

    struct OwnerOperator {
        /*
         * For ERC20 / ERC777, there will only be one item
         */
        EnumerableUint256Set.Uint256Set allItems;
        EnumerableSet.AddressSet allOwners;
        /*
         * amount of each item
         * mapping(itemId => amount)
         * for ERC721, amount will be 1 or 0
         * for ERC20 / ERC777, there will only be one key
         */
        mapping(uint256 => uint256) totalSupply;
        /*
        // which items are owned by which owners?
        // for ERC20 / ERC777, the result will have 0 or 1 elements
         */
        mapping(address => EnumerableUint256Set.Uint256Set) itemIdsByOwner;
        /*
        // which owners hold which items?
        // For ERC20 / ERC777, there will only be 1 key
        // For ERC721, result will have 0 or 1 elements
         */
        mapping(uint256 => EnumerableSet.AddressSet) ownersByItemIds;
        /*
        // for a given item id, what is the address's balance?
        // mapping(itemId => mapping(owner => amount))
        // for ERC20 / ERC777, there will only be 1 key
        // for ERC721, result is 1 or 0
         */
        mapping(uint256 => mapping(address => uint256)) balances;
        mapping(address => mapping(uint256 => address)) itemApprovals;
        /*
        // for a given owner, how much of each item id is an operator allowed to control?
         */
        mapping(address => mapping(uint256 => mapping(address => uint256))) allowances;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    /**
     * @dev revert if the item does not exist
     */
    modifier itemExists(OwnerOperator storage oo, uint256 thing) {
        require(_exists(oo, thing), "invalid item");
        _;
    }

    /**
     * @dev revert if the user is the null address
     */
    modifier validUser(OwnerOperator storage oo, address user) {
        require(user != address(0), "invalid user");
        _;
    }

    /**
     * @dev revert if the item does not exist
     */
    function enforceItemExists(OwnerOperator storage oo, uint256 thing)
        public
        view
        itemExists(oo, thing)
    {}

    /**
     * @dev Returns the number of distict owners.
     * @dev use with `ownerAtIndex()` to iterate.
     */
    function ownerCount(OwnerOperator storage oo)
        external
        view
        returns (uint256)
    {
        return oo.allOwners.length();
    }

    /**
     * @dev Returns the address of the owner at the index.
     * @dev use with `ownerCount()` to iterate.
     *
     * @param index the index into the list of owners
     *
     * Requirements
     * - `index` MUST be less than the number of owners.
     */
    function ownerAtIndex(OwnerOperator storage oo, uint256 index)
        external
        view
        returns (address)
    {
        require(oo.allOwners.length() > index, "owner index out of bounds");
        return oo.allOwners.at(index);
    }

    /**
     * @dev Returns whether `thing` exists. Things are created by transferring
     *     from the null address, and things are destroyed by tranferring to
     *     the null address.
     * @dev COINS: returns whether any have been minted and are not all burned.
     *
     * @param thing identifies the thing.
     *
     * Requirements:
     * - COINS: `thing` SHOULD be 1.
     */
    function exists(OwnerOperator storage oo, uint256 thing)
        external
        view
        returns (bool)
    {
        return _exists(oo, thing);
    }

    /**
     * @dev Returns the number of distict items.
     * @dev use with `itemAtIndex()` to iterate.
     * @dev COINS: returns 1 or 0 depending on whether any tokens exist.
     */
    function itemCount(OwnerOperator storage oo)
        external
        view
        returns (uint256)
    {
        return oo.allItems.length();
    }

    /**
     * @dev Returns the ID of the item at the index.
     * @dev use with `itemCount()` to iterate.
     * @dev COINS: don't use this function. The ID is always 1.
     *
     * @param index the index into the list of items
     *
     * Requirements
     * - `index` MUST be less than the number of items.
     */
    function itemAtIndex(OwnerOperator storage oo, uint256 index)
        external
        view
        returns (uint256)
    {
        require(oo.allItems.length() > index, "item index out of bounds");
        return oo.allItems.at(index);
    }

    /**
     * @dev for a given item, returns the number that exist.
     * @dev NFTS: don't use this function. It returns 1 or 0 depending on
     *     whether the item exists. Use `exists()` instead.
     */
    function itemSupply(OwnerOperator storage oo, uint256 thing)
        external
        view
        returns (uint256)
    {
        return oo.totalSupply[thing];
    }

    /**
     * @dev For a given address, returns the number of distinct items.
     * @dev Returns 0 if the address doesn't own anything here.
     * @dev use with `itemOfOwnerByIndex()` to iterate.
     * @dev COINS: don't use this function. It returns 1 or 0 depending on
     *     whether the address has a balance. Use `balance()` instead.
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     * - `thing` MUST exist.
     */
    function ownerItemCount(OwnerOperator storage oo, address owner)
        external
        view
        validUser(oo, owner)
        returns (uint256)
    {
        return oo.itemIdsByOwner[owner].length();
    }

    /**
     * @dev For a given address, returns the id of the item at the index.
     * @dev COINS: don't use this function.
     *
     * @param owner the owner.
     * @param index the index in the list of items.
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     * - `index` MUST be less than the number of items.
     */
    function itemOfOwnerByIndex(
        OwnerOperator storage oo,
        address owner,
        uint256 index
    ) external view validUser(oo, owner) returns (uint256) {
        require(
            oo.itemIdsByOwner[owner].length() > index,
            "item index out of bounds"
        );
        return oo.itemIdsByOwner[owner].at(index);
    }

    /**
     * @dev For a given item, returns the number of owners.
     * @dev use with `ownerOfItemAtIndex()` to iterate.
     * @dev COINS: don't use this function. Use `ownerCount()` instead.
     * @dev NFTS: don't use this function. If `thing` exists, the answer is 1.
     *
     * Requirements:
     * - `thing` MUST exist.
     */
    function itemOwnerCount(OwnerOperator storage oo, uint256 thing)
        external
        view
        itemExists(oo, thing)
        returns (uint256)
    {
        return oo.ownersByItemIds[thing].length();
    }

    /**
     * @dev For a given item, returns the owner at the index.
     * @dev use with `itemOwnerCount()` to iterate.
     * @dev COINS: don't use this function. Use `ownerAtIndex()` instead.
     * @dev NFTS: Returns the owner.
     *
     * @param thing identifies the item.
     * @param index the index in the list of owners.
     *
     * Requirements:
     * - `thing` MUST exist.
     * - `index` MUST be less than the number of owners.
     * - NFTS: `index` MUST be 0.
     */
    function ownerOfItemAtIndex(
        OwnerOperator storage oo,
        uint256 thing,
        uint256 index
    ) external view itemExists(oo, thing) returns (address owner) {
        require(
            oo.ownersByItemIds[thing].length() > index,
            "owner index out of bounds"
        );
        return oo.ownersByItemIds[thing].at(index);
    }

    /**
     * @dev Returns how much of an item is held by an address.
     * @dev NFTS: Returns 0 or 1 depending on whether the address owns the item.
     *
     * @param owner the owner
     * @param thing identifies the item.
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     * - `thing` MUST exist.
     */
    function balance(
        OwnerOperator storage oo,
        address owner,
        uint256 thing
    )
        external
        view
        validUser(oo, owner)
        itemExists(oo, thing)
        returns (uint256)
    {
        return oo.balances[thing][owner];
    }

    /**
     * @dev Returns the list of distinct items held by an address.
     * @dev COINS: Don't use this function.
     *
     * @param user the user
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     */
    function userWallet(OwnerOperator storage oo, address user)
        external
        view
        validUser(oo, user)
        returns (uint256[] memory)
    {
        return oo.itemIdsByOwner[user].asList();
    }

    /**
     * @dev Reverts if `operator` is allowed to transfer `amount` of `thing` on
     *     behalf of `fromAddress`.
     * @dev Reverts if `fromAddress` is not an owner of at least `amount` of
     *     `thing`.
     *
     * @param operator the operator
     * @param fromAddress the owner
     * @param thing identifies the item.
     * @param amount the amount
     *
     * Requirements:
     * - NFTS: `amount` SHOULD be 1
     * - COINS: `thing` SHOULD be 1
     */
    function enforceAccess(
        OwnerOperator storage oo,
        address operator,
        address fromAddress,
        uint256 thing,
        uint256 amount
    ) external view {
        require(
            oo.balances[thing][fromAddress] >= amount &&
                _checkApproval(oo, operator, fromAddress, thing, amount),
            "not authorized"
        );
    }

    /**
     * @dev Returns whether `operator` is allowed to transfer `amount` of
     *     `thing` on behalf of `fromAddress`.
     *
     * @param operator the operator
     * @param fromAddress the owner
     * @param thing identifies the item.
     * @param amount the amount
     *
     * Requirements:
     * - NFTS: `amount` SHOULD be 1
     * - COINS: `thing` SHOULD be 1
     */
    function isApproved(
        OwnerOperator storage oo,
        address operator,
        address fromAddress,
        uint256 thing,
        uint256 amount
    ) external view returns (bool) {
        return _checkApproval(oo, operator, fromAddress, thing, amount);
    }

    /**
     * @dev transfers an amount of thing from one address to another.
     * @dev if `fromAddress` is the null address, `amount` of `thing` is
     *     created.
     * @dev if `toAddress` is the null address, `amount` of `thing` is
     *     destroyed.
     *
     * @param operator the operator
     * @param fromAddress the current owner
     * @param toAddress the current owner
     * @param thing identifies the item.
     * @param amount the amount
     *
     * Requirements:
     * - NFTS: `amount` SHOULD be 1
     * - COINS: `thing` SHOULD be 1
     * - `fromAddress` and `toAddress` MUST NOT both be the null address
     * - `amount` MUST be greater than 0
     * - if `fromAddress` is not the null address
     *   - `amount` MUST NOT be greater than the current owner's balance
     *   - `operator` MUST be approved
     */
    function doTransfer(
        OwnerOperator storage oo,
        address operator,
        address fromAddress,
        address toAddress,
        uint256 thing,
        uint256 amount
    ) external {
        // can't mint and burn in same transaction
        require(
            fromAddress != address(0) || toAddress != address(0),
            "invalid transfer"
        );

        // can't transfer nothing
        require(amount > 0, "invalid transfer");

        if (fromAddress == address(0)) {
            // minting
            oo.allItems.add(thing);
            oo.totalSupply[thing] += amount;
        } else {
            enforceItemExists(oo, thing);
            if (operator != fromAddress) {
                require(
                    _checkApproval(oo, operator, fromAddress, thing, amount),
                    "not authorized"
                );
                if (oo.allowances[fromAddress][thing][operator] > 0) {
                    oo.allowances[fromAddress][thing][operator] -= amount;
                }
            }
            require(
                oo.balances[thing][fromAddress] >= amount,
                "insufficient balance"
            );

            oo.itemApprovals[fromAddress][thing] = address(0);

            if (fromAddress == toAddress) return;

            oo.balances[thing][fromAddress] -= amount;
            if (oo.balances[thing][fromAddress] == 0) {
                oo.allOwners.remove(fromAddress);
                oo.ownersByItemIds[thing].remove(fromAddress);
                oo.itemIdsByOwner[fromAddress].remove(thing);
                if (oo.itemIdsByOwner[fromAddress].length() == 0) {
                    delete oo.itemIdsByOwner[fromAddress];
                }
            }
        }

        if (toAddress == address(0)) {
            // burning
            oo.totalSupply[thing] -= amount;
            if (oo.totalSupply[thing] == 0) {
                oo.allItems.remove(thing);
                delete oo.ownersByItemIds[thing];
            }
        } else {
            oo.allOwners.add(toAddress);
            oo.itemIdsByOwner[toAddress].add(thing);
            oo.ownersByItemIds[thing].add(toAddress);
            oo.balances[thing][toAddress] += amount;
        }
    }

    /**
     * @dev Returns whether an operator is approved for all items belonging to
     *     an owner.
     *
     * @param fromAddress the owner
     * @param operator the operator
     */
    function isApprovedForAll(
        OwnerOperator storage oo,
        address fromAddress,
        address operator
    ) external view returns (bool) {
        return oo.operatorApprovals[fromAddress][operator];
    }

    /**
     * @dev Toggles whether an operator is approved for all items belonging to
     *     an owner.
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param approved the new approval status
     *
     * Requirements:
     * - `fromUser` MUST NOT be the null address
     * - `operator` MUST NOT be the null address
     * - `operator` MUST NOT be the `fromUser`
     */
    function setApprovalForAll(
        OwnerOperator storage oo,
        address fromAddress,
        address operator,
        bool approved
    ) external validUser(oo, fromAddress) validUser(oo, operator) {
        require(operator != fromAddress, "approval to self");
        oo.operatorApprovals[fromAddress][operator] = approved;
    }

    /**
     * @dev returns the approved allowance for an operator.
     * @dev NFTS: Don't use this function. Use `getApprovedForItem()`
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param thing identifies the item.
     *
     * Requirements:
     * - COINS: `thing` SHOULD be 1
     */
    function allowance(
        OwnerOperator storage oo,
        address fromAddress,
        address operator,
        uint256 thing
    ) external view returns (uint256) {
        return oo.allowances[fromAddress][thing][operator];
    }

    /**
     * @dev sets the approval amount for an operator.
     * @dev NFTS: Don't use this function. Use `approveForItem()`
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param thing identifies the item.
     * @param amount the allowance amount.
     *
     * Requirements:
     * - COINS: `thing` SHOULD be 1
     * - `fromUser` MUST NOT be the null address
     * - `operator` MUST NOT be the null address
     * - `operator` MUST NOT be the `fromUser`
     */
    function approve(
        OwnerOperator storage oo,
        address fromAddress,
        address operator,
        uint256 thing,
        uint256 amount
    ) external validUser(oo, fromAddress) validUser(oo, operator) {
        require(operator != fromAddress, "approval to self");
        oo.allowances[fromAddress][thing][operator] = amount;
    }

    /**
     * @dev Returns the address of the operator who is approved for an item.
     * @dev Returns the null address if there is no approved operator.
     * @dev COINS: Don't use this function.
     *
     * @param fromAddress the owner
     * @param thing identifies the item.
     *
     * Requirements:
     * - `thing` MUST exist
     */
    function getApprovedForItem(
        OwnerOperator storage oo,
        address fromAddress,
        uint256 thing
    ) external view returns (address) {
        require(oo.totalSupply[thing] > 0);
        return oo.itemApprovals[fromAddress][thing];
    }

    /**
     * @dev Approves `operator` to transfer `thing` to another account.
     * @dev COINS: Don't use this function. Use `setApprovalForAll()` or
     *     `approve()`
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param thing identifies the item.
     *
     * Requirements:
     * - `fromUser` MUST NOT be the null address
     * - `operator` MAY be the null address
     * - `operator` MUST NOT be the `fromUser`
     * - `fromUser` MUST be an owner of `thing`
     */
    function approveForItem(
        OwnerOperator storage oo,
        address fromAddress,
        address operator,
        uint256 thing
    ) external validUser(oo, fromAddress) {
        require(operator != fromAddress, "approval to self");
        require(oo.ownersByItemIds[thing].contains(fromAddress));
        oo.itemApprovals[fromAddress][thing] = operator;
    }

    function _exists(OwnerOperator storage oo, uint256 thing)
        internal
        view
        returns (bool)
    {
        return oo.totalSupply[thing] > 0;
    }

    function _checkApproval(
        OwnerOperator storage oo,
        address operator,
        address fromAddress,
        uint256 thing,
        uint256 amount
    ) internal view returns (bool) {
        return (operator == fromAddress ||
            oo.operatorApprovals[fromAddress][operator] ||
            oo.itemApprovals[fromAddress][thing] == operator ||
            oo.allowances[fromAddress][thing][operator] >= amount);
    }
}

// File: Pausable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: Recallable.sol

/**
 * @title Recallable
 * @notice This contract gives the contract owner a time-limited ability to "recall"
 * an NFT.
 * @notice The purpose of the recall function is to support customers who
 * have supplied us with an incorrect address or an address that doesn't
 * support Polygon (e.g. Coinbase custodial wallet).
 * @notice An NFT cannot be recalled once this amount of time has passed
 * since it was minted.
 */
interface Recallable is IERC165 {
    event TokenRecalled(uint256 tokenId, address recallWallet);

    /**
     * @notice An NFT minted on this contact can be "recalled" by the contract
     * owner for an amount of time defined here.
     * @notice An NFT cannot be recalled once this amount of time has passed
     * since it was minted.
     * @notice The purpose of the recall function is to support customers who
     * have supplied us with an incorrect address or an address that doesn't
     * support Polygon (e.g. Coinbase custodial wallet).
     * @notice Divide the recall period by 86400 to convert from seconds to days.
     *
     * @dev The maximum amount of time after minting, in seconds, that the contract
     * owner can "recall" the NFT.
     */
    function maxRecallPeriod() external view returns (uint256);

    /**
     * @notice Returns the amount of time remaining before a token can be recalled.
     * @notice Divide the recall period by 86400 to convert from seconds to days.
     * @notice This will return 0 if the token cannot be recalled.
     * @notice Due to the way block timetamps are determined, there is a 15
     * second margin of error in the result.
     *
     * @param _tokenId the token id.
     *
     * Requirements:
     *
     * - This function MAY be called with a non-existent `_tokenId`. The
     *   function will return 0 in this case.
     */
    function recallTimeRemaining(uint256 _tokenId)
        external
        view
        returns (uint256);

        /**
     * @notice An NFT minted on this contact can be "recalled" by the contract
     * owner for an amount of time defined here.
     * @notice An NFT cannot be recalled once this amount of time has passed
     * since it was minted.
     * @notice The purpose of the recall function is to support customers who
     * have supplied us with an incorrect address or an address that doesn't
     * support Polygon (e.g. Coinbase custodial wallet).
     * @notice Divide the recall period by 86400 to convert from seconds to days.
     *
     * @dev The maximum amount of time after minting, in seconds, that the contract
     * owner can "recall" the NFT.
     *
     * @param _toAddress The address where the token will go after it has been recalled.
     * @param _tokenId The token to be recalled.
     *
     * Requirements:
     *
     * - The caller MUST be the contract owner.
     * - The current timestamp MUST be within `maxRecallPeriod` of the token's
     *    `bornOn` date.
     * - `_toAddress` MAY be 0, in which case the token is burned rather than
     *    recalled to a wallet.
     */
    function recall(address _toAddress, uint256 _tokenId) external;

    /**
     * @notice Prematurely ends the recall period for an NFT.
     * @notice This action cannot be reversed.
     * 
     * @param _tokenId The token to be recalled.
     * 
     * Requirements:
     *
     * - The caller MUST be the contract owner.
     * - The token must exist.
     * - The current timestamp MUST be within `maxRecallPeriod` of the token's
     *    `bornOn` date.
     */
    function makeUnrecallable(uint256 _tokenId) external;
}
// File: DropManagement.sol

/**
 * Information needed to start a drop.
 */
struct Drop {
    string dropName;
    uint32 dropStartTime;
    uint32 dropSize;
    string baseURI;
}

/**
 * @notice Manages tokens within a drop using a state machine. Tracks
 * the current state of each token. If there are multiple drops, each
 * drop has its own state machine. A token's URI can change when its
 * state changes.
 * @dev The state's data field contains the base URI for the state.
 */
library DropManagement {
    using Strings for string;
    using StateMachine for StateMachine.States;
    using Monotonic for Monotonic.Counter;

    struct ManagedDrop {
        Drop drop;
        Monotonic.Counter mintCount;
        bool active;
        StateMachine.States stateMachine;
        mapping(uint256 => string) stateForToken;
        DynamicURI dynamicURI;
    }

    struct DropManager {
        Monotonic.Counter tokensReserved;
        Monotonic.Counter tokensMinted;
        uint256 maxSupply;
        bool requireCategory;
        string baseURI;
        mapping(uint256 => string) customURIs;
        string[] allDropNames;
        mapping(string => ManagedDrop) dropByName;
        mapping(uint256 => string) dropNameByTokenId;
    }

    /**
     * @dev emitted when a new drop is started.
     */
    event DropAnnounced(Drop drop);

    /**
     * @dev emitted when a drop ends manually or by selling out.
     */
    event DropEnded(Drop drop);

    /**
     * @dev emitted when a token has its URI overridden via `setCustomURI`.
     * @dev not emitted when the URI changes via state changes, changes to the
     *     base uri, or by whatever tokenData.dynamicURI might do.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev emitted when a token changes state.
     */
    event StateChange(
        uint256 indexed tokenId,
        string fromState,
        string toState
    );

    /**
     * @dev reverts unless `dropName` is empty or refers to an existing drop.
     * @dev if `tokenData.requireCategory` is true, also reverts if `dropName`
     *     is empty.
     */
    modifier validDropName(DropManager storage mgr, string memory dropName) {
        if (bytes(dropName).length > 0 || mgr.requireCategory) {
            require(
                _isRealDrop(mgr.dropByName[dropName].drop),
                "invalid category"
            );
        }
        _;
    }

    /**
     * @dev reverts if `dropName` does not rever to an existing drop.
     * @dev This does not check whether the drop is active.
     */
    modifier realDrop(DropManager storage mgr, string memory dropName) {
        require(_isRealDrop(mgr.dropByName[dropName].drop), "invalid category");
        _;
    }

    /**
     * @dev reverts if the baseURI is an empty string.
     */
    modifier validBaseURI(string memory baseURI) {
        require(bytes(baseURI).length > 0, "empty base uri");
        _;
    }

    function init(DropManager storage mgr, uint256 maxSupply) public {
        mgr.maxSupply = maxSupply;
    }

    function setRequireCategory(DropManager storage mgr, bool required) public {
        mgr.requireCategory = required;
    }

    /**
     * @dev Returns the total maximum possible size for the collection.
     */
    function getMaxSupply(DropManager storage mgr)
        public
        view
        returns (uint256)
    {
        return mgr.maxSupply;
    }

    /**
     * @dev returns the amount available to be minted outside of any drops, or
     *     the amount available to be reserved in new drops.
     * @dev {total available} = {max supply} - {amount minted so far} -
     *      {amount remaining in pools reserved for drops}
     */
    function totalAvailable(DropManager storage mgr)
        public
        view
        returns (uint256)
    {
        return
            mgr.maxSupply -
            mgr.tokensMinted.current() -
            mgr.tokensReserved.current();
    }

    /**
     * @dev see IERC721Enumerable
     */
    function totalSupply(DropManager storage mgr)
        public
        view
        returns (uint256)
    {
        return mgr.tokensMinted.current();
    }

    /**
     * @dev Returns the number of tokens that may still be minted in the named drop.
     * @dev Returns 0 if `dropName` does not refer to an active drop.
     *
     * @param dropName The name of the drop
     */
    function amountRemainingInDrop(
        DropManager storage mgr,
        string memory dropName
    ) external view returns (uint256) {
        if (bytes(dropName).length == 0) {
            return totalAvailable(mgr);
        }

        ManagedDrop storage currentDrop = mgr.dropByName[dropName];
        if (!currentDrop.active) {
            return 0;
        }

        return _remaining(currentDrop);
    }

    /**
     * @dev Returns the number of tokens minted so far in a drop.
     * @dev Returns 0 if `dropName` does not refer to an active drop.
     *
     * @param dropName The name of the drop
     */
    function dropMintCount(DropManager storage mgr, string memory dropName)
        external
        view
        returns (uint256)
    {
        return mgr.dropByName[dropName].mintCount.current();
    }

    /**
     * @dev returns the drop with the given name.
     * @dev if there is no drop with the name, the function should return an
     * empty drop.
     */
    function dropForName(DropManager storage mgr, string memory dropName)
        external
        view
        returns (Drop memory)
    {
        return mgr.dropByName[dropName].drop;
    }

    /**
     * @dev Return the name of a drop at `_index`. Use along with {dropCount()} to
     * iterate through all the drop names.
     */
    function dropNameForIndex(DropManager storage mgr, uint256 _index)
        external
        view
        returns (string memory)
    {
        return mgr.allDropNames[_index];
    }

    /**
     * @notice A drop is active if it has been started and has neither run out of supply
     * nor been stopped manually.
     * @dev Returns true if the `dropName` refers to an active drop.
     */
    function isDropActive(DropManager storage mgr, string memory dropName)
        external
        view
        returns (bool)
    {
        return mgr.dropByName[dropName].active;
    }

    /**
     * @dev Returns the number of drops that have been created.
     */
    function dropCount(DropManager storage mgr)
        external
        view
        returns (uint256)
    {
        return mgr.allDropNames.length;
    }

    /**
     * @dev Base URI for computing {tokenURI}. The resulting URI for each
     * token will be he concatenation of the `baseURI` and the `tokenId`.
     */
    function getBaseURI(DropManager storage mgr)
        external
        view
        returns (string memory)
    {
        return mgr.baseURI;
    }

    /**
     * @dev Change the base URI for the named drop.
     */
    function setBaseURI(DropManager storage mgr, string memory baseURI)
        external
        validBaseURI(baseURI)
    {
        require(
            keccak256(bytes(baseURI)) != keccak256(bytes(mgr.baseURI)),
            "base uri unchanged"
        );
        mgr.baseURI = baseURI;
    }

    /**
     * @dev get the base URI for the named drop.
     * @dev if `dropName` is the empty string, returns the baseURI for any
     *     tokens minted outside of a drop.
     */
    function getBaseURI(DropManager storage mgr, string memory dropName)
        public
        view
        realDrop(mgr, dropName)
        returns (string memory)
    {
        ManagedDrop storage currentDrop = mgr.dropByName[dropName];
        return
            _getBaseURIForState(
                currentDrop,
                currentDrop.stateMachine.initialStateName()
            );
    }

    /**
     * @dev Change the base URI for the named drop.
     */
    function setBaseURI(
        DropManager storage mgr,
        string memory dropName,
        string memory baseURI
    ) external realDrop(mgr, dropName) validBaseURI(baseURI) {
        ManagedDrop storage currentDrop = mgr.dropByName[dropName];
        require(
            keccak256(bytes(baseURI)) !=
                keccak256(bytes(currentDrop.drop.baseURI)),
            "base uri unchanged"
        );
        currentDrop.drop.baseURI = baseURI;
        currentDrop.stateMachine.setStateData(
            currentDrop.stateMachine.initialStateName(),
            abi.encode(baseURI)
        );
    }

    /**
     * @dev return the base URI for the named state in the named drop.
     * @param dropName The name of the drop
     * @param stateName The state to be updated.
     *
     * Requirements:
     *
     * - `dropName` MUST refer to a valid drop.
     * - `stateName` MUST refer to a valid state for `dropName`
     * - `dropName` MAY refer to an active or inactive drop
     */
    function getBaseURIForState(
        DropManager storage mgr,
        string memory dropName,
        string memory stateName
    ) public view realDrop(mgr, dropName) returns (string memory) {
        ManagedDrop storage currentDrop = mgr.dropByName[dropName];
        return _getBaseURIForState(currentDrop, stateName);
    }

    /**
     * @dev Change the base URI for the named state in the named drop.
     */
    function setBaseURIForState(
        DropManager storage mgr,
        string memory dropName,
        string memory stateName,
        string memory baseURI
    ) external realDrop(mgr, dropName) validBaseURI(baseURI) {
        ManagedDrop storage currentDrop = mgr.dropByName[dropName];
        require(_isRealDrop(currentDrop.drop));
        require(
            keccak256(bytes(baseURI)) !=
                keccak256(bytes(currentDrop.drop.baseURI)),
            "base uri unchanged"
        );

        currentDrop.stateMachine.setStateData(stateName, abi.encode(baseURI));
    }

    /**
     * @dev Override the baseURI + tokenId scheme for determining the token
     * URI with the specified custom URI.
     *
     * @param tokenId The token to use the custom URI
     * @param newURI The custom URI
     *
     * Requirements:
     *
     * - `tokenId` MAY refer to an invalid token id. Setting the custom URI
     *      before minting is allowed.
     * - `newURI` MAY be an empty string, to clear a previously set customURI
     *      and use the default scheme.
     */
    function setCustomURI(
        DropManager storage mgr,
        uint256 tokenId,
        string memory newURI
    ) public {
        mgr.customURIs[tokenId] = newURI;
        emit URI(newURI, tokenId);
    }

    /**
     * @dev Use this contract to override the default mechanism for
     *     generating token ids.
     *
     * Requirements:
     * - `dynamicURI` MAY be the null address, in which case the override is
     *     removed and the default mechanism is used again.
     * - If `dynamicURI` is not the null address, it MUST be the address of a
     *     contract that implements the DynamicURI interface (0xc87b56dd).
     */
    function setDynamicURI(
        DropManager storage mgr,
        string memory dropName,
        DynamicURI dynamicURI
    ) public validDropName(mgr, dropName) {
        require(
            address(dynamicURI) == address(0) ||
                dynamicURI.supportsInterface(0xc87b56dd),
            "Invalid contract"
        );
        mgr.dropByName[dropName].dynamicURI = dynamicURI;
    }

    /**
     * @notice Starts a new drop.
     * @param dropName The name of the new drop
     * @param dropStartTime The unix timestamp of when the drop is active
     * @param dropSize The number of NFTs in this drop
     * @param _startStateName The initial state for the drop's state machine.
     * @param baseURI The base URI for the tokens in this drop
     */
    function startNewDrop(
        DropManager storage mgr,
        string memory dropName,
        uint32 dropStartTime,
        uint32 dropSize,
        string memory _startStateName,
        string memory baseURI
    ) external {
        require(dropSize > 0, "invalid drop");
        require(dropSize <= totalAvailable(mgr), "drop too large");
        require(bytes(dropName).length > 0, "invalid category");
        ManagedDrop storage newDrop = mgr.dropByName[dropName];
        require(!_isRealDrop(newDrop.drop), "drop exists");

        newDrop.drop = Drop(dropName, dropStartTime, dropSize, baseURI);
        _activateDrop(mgr, newDrop, _startStateName);

        mgr.tokensReserved.add(dropSize);
        emit DropAnnounced(newDrop.drop);
    }

    /**
     * @notice Ends the named drop immediately. It's not necessary to call this.
     * The current drop ends automatically once the last token is sold.
     *
     * @param dropName The name of the drop to deactivate
     */
    function deactivateDrop(DropManager storage mgr, string memory dropName)
        external
    {
        ManagedDrop storage currentDrop = mgr.dropByName[dropName];
        require(currentDrop.active, "invalid drop");

        currentDrop.active = false;
        mgr.tokensReserved.subtract(_remaining(currentDrop));
        emit DropEnded(currentDrop.drop);
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     *
     * @param tokenId the tokenId
     */
    function getTokenURI(DropManager storage mgr, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        // We have to convert string to bytes to check for existence
        bytes memory customUriBytes = bytes(mgr.customURIs[tokenId]);
        if (customUriBytes.length > 0) {
            return mgr.customURIs[tokenId];
        }

        ManagedDrop storage currentDrop = mgr.dropByName[
            mgr.dropNameByTokenId[tokenId]
        ];

        if (address(currentDrop.dynamicURI) != address(0)) {
            string memory dynamic = currentDrop.dynamicURI.tokenURI(tokenId);
            if (bytes(dynamic).length > 0) {
                return dynamic;
            }
        }

        string memory base = mgr.baseURI;
        if (_isRealDrop(currentDrop.drop)) {
            string memory stateName = currentDrop.stateForToken[tokenId];
            if (bytes(stateName).length == 0) {
                return currentDrop.drop.baseURI;
            } else {
                base = _getBaseURIForState(currentDrop, stateName);
            }
        }
        if (bytes(base).length > 0) {
            return string(abi.encodePacked(base, Strings.toString(tokenId)));
        }

        return base;
    }

    /**
     * @dev Call this function when minting a token within a drop.
     * @dev Validates drop and available quantities
     * @dev Updates available quantities
     * @dev Deactivates drop when last one is minted
     */
    function onMint(
        DropManager storage mgr,
        string memory dropName,
        uint256 tokenId,
        string memory customURI
    ) external validDropName(mgr, dropName) {
        ManagedDrop storage currentDrop = mgr.dropByName[dropName];

        if (_isRealDrop(currentDrop.drop)) {
            _preMintCheck(currentDrop, 1);

            mgr.dropNameByTokenId[tokenId] = dropName;
            currentDrop.stateForToken[tokenId] = currentDrop
                .stateMachine
                .initialStateName();
            mgr.tokensReserved.decrement();
        } else {
            require(totalAvailable(mgr) >= 1, "sold out");
        }

        if (bytes(customURI).length > 0) {
            mgr.customURIs[tokenId] = customURI;
        }

        mgr.tokensMinted.increment();
    }

    /**
     * @dev Call this function when minting a batch of tokens within a drop.
     * @dev Validates drop and available quantities
     * @dev Updates available quantities
     * @dev Deactivates drop when last one is minted
     */
    function onBatchMint(
        DropManager storage mgr,
        string memory dropName,
        uint256[] memory tokenIds
    ) external validDropName(mgr, dropName) {
        ManagedDrop storage currentDrop = mgr.dropByName[dropName];

        bool inDrop = _isRealDrop(currentDrop.drop);
        if (inDrop) {
            _preMintCheck(currentDrop, tokenIds.length);

            mgr.tokensReserved.subtract(tokenIds.length);
        } else {
            require(totalAvailable(mgr) >= tokenIds.length, "sold out");
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (inDrop) {
                mgr.dropNameByTokenId[tokenIds[i]] = dropName;
                currentDrop.stateForToken[tokenIds[i]] = currentDrop
                    .stateMachine
                    .initialStateName();
            }
        }

        mgr.tokensMinted.add(tokenIds.length);
    }

    /**
     * @dev Call this function when burning a token within a drop.
     * @dev Updates available quantities
     * @dev Will not reactivate the drop.
     */
    function postBurnUpdate(DropManager storage mgr, uint256 tokenId) external {
        ManagedDrop storage currentDrop = mgr.dropByName[
            mgr.dropNameByTokenId[tokenId]
        ];
        if (_isRealDrop(currentDrop.drop)) {
            currentDrop.mintCount.decrement();
            mgr.tokensReserved.increment();
            delete mgr.dropNameByTokenId[tokenId];
            delete currentDrop.stateForToken[tokenId];
        }

        delete mgr.customURIs[tokenId];
        mgr.tokensMinted.decrement();
    }

    /**
     * @notice Sets up a state transition
     *
     * Requirements:
     * - `dropName` MUST refer to a valid drop
     * - `fromState` MUST refer to a valid state for `dropName`
     * - `toState` MUST NOT be empty
     * - `baseURI` MUST NOT be empty
     * - A transition named `toState` MUST NOT already be defined for `fromState`
     *    in the drop named `dropName`
     */
    function addStateTransition(
        DropManager storage mgr,
        string memory dropName,
        string memory fromState,
        string memory toState,
        string memory baseURI
    ) external realDrop(mgr, dropName) validBaseURI(baseURI) {
        ManagedDrop storage drop = mgr.dropByName[dropName];

        drop.stateMachine.addStateTransition(
            fromState,
            toState,
            abi.encode(baseURI)
        );
    }

    /**
     * @notice Removes a state transition. Does not remove any states.
     *
     * Requirements:
     * - `dropName` MUST refer to a valid drop.
     * - `fromState` and `toState` MUST describe an existing transition.
     */
    function deleteStateTransition(
        DropManager storage mgr,
        string memory dropName,
        string memory fromState,
        string memory toState
    ) external realDrop(mgr, dropName) {
        ManagedDrop storage drop = mgr.dropByName[dropName];

        drop.stateMachine.deleteStateTransition(fromState, toState);
    }

    /**
     * @dev Returns the token's current state
     * @dev Returns empty string if the token is not managed by a state machine.
     */
    function getState(DropManager storage mgr, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        ManagedDrop storage currentDrop = mgr.dropByName[
            mgr.dropNameByTokenId[tokenId]
        ];

        if (!_isRealDrop(currentDrop.drop)) {
            return "";
        }

        return currentDrop.stateForToken[tokenId];
    }

    function setState(
        DropManager storage mgr,
        uint256 tokenId,
        string memory stateName,
        bool requireValidTransition
    ) internal {
        ManagedDrop storage currentDrop = mgr.dropByName[
            mgr.dropNameByTokenId[tokenId]
        ];
        require(_isRealDrop(currentDrop.drop), "no state");
        require(
            currentDrop.stateMachine.isValidState(stateName),
            "invalid state"
        );
        string memory currentStateName = currentDrop.stateForToken[tokenId];

        if (requireValidTransition) {
            require(
                currentDrop.stateMachine.isValidTransition(
                    currentStateName,
                    stateName
                ),
                "No such transition"
            );
        }

        currentDrop.stateForToken[tokenId] = stateName;
        emit StateChange(tokenId, currentStateName, stateName);
    }

    function _getBaseURIForState(
        ManagedDrop storage currentDrop,
        string memory stateName
    ) internal view returns (string memory) {
        return
            abi.decode(
                currentDrop.stateMachine.getStateData(stateName),
                (string)
            );
    }

    function _remaining(ManagedDrop storage drop)
        private
        view
        returns (uint32)
    {
        return drop.drop.dropSize - uint32(drop.mintCount.current());
    }

    function _activateDrop(
        DropManager storage mgr,
        ManagedDrop storage drop,
        string memory _startStateName
    ) private {
        mgr.allDropNames.push(drop.drop.dropName);
        drop.active = true;
        drop.stateMachine.initialize(
            _startStateName,
            abi.encode(drop.drop.baseURI)
        );
    }

    function _preMintCheck(ManagedDrop storage currentDrop, uint256 _quantity)
        private
    {
        require(currentDrop.active, "no drop");
        require(block.timestamp >= currentDrop.drop.dropStartTime, "early");
        uint32 remaining = _remaining(currentDrop);
        require(remaining >= _quantity, "sold out");

        currentDrop.mintCount.add(_quantity);
        if (remaining == _quantity) {
            currentDrop.active = false;
            emit DropEnded(currentDrop.drop);
        }
    }

    function _isRealDrop(Drop storage testDrop) private view returns (bool) {
        return testDrop.dropSize != 0;
    }
}

// File: ERC2981Base.sol

/**
 * @title ERC2981Base
 * @author Josh Davis <[email protected]>
 * @dev The subclasses come in two flavors, contract-wide and per token.
 */
abstract contract ERC2981Base is IERC2981, ERC165 {
    bytes32 public ROYALTIES_MANAGER = "royalties manager";

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @inheritdoc	IERC2981
    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return _getRoyalties(tokenId, value);
    }

    function _getRoyalties(uint256 tokenId, uint256 value)
        internal
        view
        virtual
        returns (address receiver, uint256 royaltyAmount);
}

// File: IERC721Enumerable.sol

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

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

// File: IERC721Metadata.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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

    // Role for moderator.
    bytes32 public constant MODERATOR_ROLE_NAME = "moderator";

    /**
     * @dev Emitted when `previousOwner` transfers ownership to `newOwner`.
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        ams.setContractOwner(msg.sender);
        ams.initSanctions();
        ams.setRoleAdmin(BANNED_ROLE_NAME, MODERATOR_ROLE_NAME);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
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

    /**
     * @dev reverts if called by an account that is not the owner and doesn't 
     *     have the required role.
     */
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
        ams.enforceIsContractOwner(_msgSender());
        _;
    }

    /**
     * @dev reverts if the caller is banned or on the OFAC sanctions list.
     */
    modifier noBannedAccounts() {
        ams.enforceIsNotBanned(_msgSender());
        _;
    }

    /**
     * @dev reverts if the account is banned or on the OFAC sanctions list.
     */
    modifier notBanned(address account) {
        ams.enforceIsNotBanned(account);
        _;
    }

    /**
     * @dev Revert if the address is on the OFAC sanctions list
     */
    modifier notSanctioned(address addr) {
        ams.enforceIsNotSanctioned(addr);
        _;
    }

    /**
     * @dev returns true if the account is banned.
     */
    function isBanned(address account) public view virtual returns (bool) {
        return hasRole(BANNED_ROLE_NAME, account);
    }

    /**
     * @dev returns true if the account is on the OFAC sanctions list.
     */
    function isSanctioned(address account) public view virtual returns (bool) {
        return ams.isSanctioned(account);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
        return ams.hasRole(role, account);
    }

    /**
     * @notice toggles the sanctions compliance flag
     * @notice this flag should only be turned off during testing or if there
     *     is some problem with the sanctions oracle.
     *
     * Requirements:
     * - Caller must be the contract owner
     */
    function toggleSanctionsCompliance() public onlyOwner {
        ams.toggleSanctionsCompliance();
    }

    /**
     * @dev returns true if sanctions compliance is enabled.
     */
    function sanctionsComplianceEnabled() public view returns (bool) {
        return ams.isSanctionsComplianceEnabled();
    }

    /**
     * @notice Sets the sanction list oracle
     * @notice Reverts unless the contract is running on a local HardHat or
     *      Ganache chain.
     * @param _sanctionsList the oracle address
     */
    function setSanctions(ChainalysisSanctionsList _sanctionsList) public {
        ams.setSanctions(_sanctionsList);
    }

    /**
     * @notice returns the address of the OFAC sanctions oracle.
     */
    function sanctionsOracle() public view returns (address) {
        return ams.getSanctionsOracle();
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return ams.getRoleAdmin(role);
    }

    /**
     * @dev Sets the admin role that controls a role.
     * 
     * Requirements:
     * - caller MUST be the owner or have the admin role.
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole)
        public
        onlyOwnerOrRole(DEFAULT_ADMIN_ROLE)
    {
        ams.setRoleAdmin(role, adminRole);
    }

    /**
     *  Requirements:
     *
     * - Calling user MUST have the admin role
     * - If `role` is banned, calling user MUST be the owner
     *   and `address` MUST NOT be the owner.
     * - If `role` is not banned, `account` MUST NOT be under sanctions.
     *
     * @inheritdoc IAccessControl
     */
    function grantRole(bytes32 role, address account) public virtual override {
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
    function getRoleMember(bytes32 role, uint256 index)
        public
        view
        override
        returns (address)
    {
        return ams.getRoleMember(role, index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role)
        public
        view
        override
        returns (uint256)
    {
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
    function transferOwnership(address newOwner) public virtual {
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
    function revokeRole(bytes32 role, address account) public virtual override {
        ams.revokeRole(role, account);
    }

    /**
     * Take a role away from yourself. This will throw an exception if you
     * are the contract owner and you are trying to renounce the admin role (0x00).
     *
     * Requirements:
     *
     * - if `role` is admin, calling user MUST NOT be owner.
     * - `account` is ignored.
     * - `role` MUST NOT be banned.
     *
     * @inheritdoc IAccessControl
     */
    function renounceRole(bytes32 role, address) public virtual override {
        ams.renounceRole(role);
    }

    /**
     * Take a role away from yourself. This will throw an exception if you
     * are the contract owner and you are trying to renounce the admin role (0x00).
     *
     * Requirements:
     *
     * - if `role` is admin, calling user MUST NOT be owner.
     * - `role` MUST NOT be banned.
     */
    function renounceRole(bytes32 role) public virtual {
        ams.renounceRole(role);
    }
}

// File: BaseViciContract.sol

abstract contract BaseViciContract is ViciAccess, Pausable {
	constructor() {
	}

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - Calling user MUST be owner.
     * - The contract must not be paused.
     */
	function pause() external onlyOwner {
		_pause();
	}

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - Calling user MUST be owner.
     * - The contract must be paused.
     */
	function unpause() external onlyOwner {
		_unpause();
	}
	
	function _withdrawERC20(
		uint256 amount,
		address payable toAddress,
		IERC20 tokenContract
	) internal virtual {
		tokenContract.transfer(toAddress, amount);
	}
	
	function withdrawERC20(
		uint256 amount,
		address payable toAddress,
		IERC20 tokenContract
	) public onlyOwner virtual {
		_withdrawERC20(amount, toAddress, tokenContract);
	}
	
	function _withdrawERC721(
		uint256 tokenId,
		address payable toAddress,
		IERC721 tokenContract
	) internal virtual {
		tokenContract.safeTransferFrom(address(this), toAddress, tokenId);
	}
	
	function withdrawERC721(
		uint256 tokenId,
		address payable toAddress,
		IERC721 tokenContract
	) public virtual onlyOwner {
		_withdrawERC721(tokenId, toAddress, tokenContract);
	}
	
	function _withdrawERC1155(
		uint256 tokenId,
		uint256 amount,
		address payable toAddress,
        bytes calldata data,
		IERC1155 tokenContract
	) internal virtual {
		tokenContract.safeTransferFrom(
			address(this), toAddress, tokenId, amount, data
		);
	}
	
	function withdrawERC1155(
		uint256 tokenId,
		uint256 amount,
		address payable toAddress,
        bytes calldata data,
		IERC1155 tokenContract
	) public virtual onlyOwner {
		_withdrawERC1155(tokenId, amount, toAddress, data, tokenContract);
	}
	
	function _withdraw(
		address payable toAddress
	) internal virtual {
		toAddress.transfer(address(this).balance);
	}
	
	function withdraw(
		address payable toAddress
	) public virtual onlyOwner {
		_withdraw(toAddress);
	}

	receive() external payable virtual {}
}
// File: ERC2981ContractWideRoyalties.sol

/**
 * @title Contract-Wide Royalties
 * @author Josh Davis <[email protected]>
 * @dev This is a contract used to add ERC2981 support to ERC721 and 1155
 * @dev This implementation has the same royalties for every token
 */
contract ERC2981ContractWideRoyalties is ERC2981Base {
    using ContractWideRoyalties for ContractWideRoyalties.RoyaltyInfo;

    ContractWideRoyalties.RoyaltyInfo schedule;

    /**
     * @notice Sets the royalties.
     * @param recipient recipient of the royalties.
     * @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
     *
     * Requirements:
     * - Sender MUST be the owner or have the ROYALTIES_MANAGER role.
     * - If `value` is non-zero, `recipient` MUST NOT be the zero address.
     * - If `value` is zero, `recipient` SHOULD be the zero address.
     * - `value` MUST NOT be greater than 10000.
     */
    function setRoyalties(address recipient, uint256 value) public {
        _setRoyaltiesHook(recipient, value);
        schedule.setRoyalties(recipient, value);
    }

    /**
     * @dev Implementing this function requires inheriting from AccessControl.
     * @dev We can't implement it here because we'll get a diamond inheritence
     *      pattern.
     * @dev It should be implemented like this:
     * if (_msgSender() != owner()) {
     *      _checkRole(ROYALTIES_MANAGER, _msgSender());
     *  }
     */
    function _setRoyaltiesHook(
        address recipient,
        uint256 value
    ) internal view virtual {}

    function _getRoyalties(uint256, uint256 value)
        internal
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        (receiver, royaltyAmount) = schedule.getRoyalties(value);
    }
}

// File: ERC721Operations4.sol

/**
 * Information needed to mint a single token.
 */
struct MintData {
    string dropName;
    address operator;
    bytes32 requiredRole;
    address toAddress;
    uint256 tokenId;
    string customURI;
    bytes data;
}

/**
 * Information needed to mint a batch of tokens.
 */
struct BatchMintData {
    string dropName;
    address operator;
    bytes32 requiredRole;
    address[] toAddresses;
    uint256[] tokenIds;
}

/**
 * Information needed to transfer a token.
 */
struct TransferData {
    address operator;
    address fromAddress;
    address toAddress;
    uint256 tokenId;
    bytes data;
}

/**
 * Information needed to burn a token.
 */
struct BurnData {
    address operator;
    bytes32 requiredRole;
    address fromAddress;
    uint256 tokenId;
}

/**
 * @dev offload most ERC721 behavior to an extrnal library to reduce the
 *     bytecode size of the main contract.
 * @dev pass arguments as structs to avoid "stack to deep" compilation error.
 */
library ERC721Operations4 {
    using Address for address;
    using Strings for string;
    using OwnerOperatorApproval for OwnerOperatorApproval.OwnerOperator;
    using AccessManagement for AccessManagement.AccessManagementState;
    using DropManagement for DropManagement.DropManager;
    using Monotonic for Monotonic.Counter;

    /**
     * Tracks all information for an NFT collection.
     * `owners` tracks who owns which NFT, and who is approved to act on which
     *     accounts behalf.
     * `maxSupply` is the total maximum possible size for the collection.
     * `requireCategory` can be set to `true` to prevent tokens from being
     *     minted outside of a drop (i.e. with empty category name).
     * `dynamicURI` is the address of a contract that can override the default
     *     mechanism for generating tokenURIs.
     * `baseURI` is the string prefixed to the token id to build the token URI
     *     for tokens minted outside of a drop.
     * `allDropNames` is the collection of every drop that has been started.
     * `tokensReserved` is the count of all unminted tokens reserved by all
     *     active drops.
     * `customURIs` contains URI overrides for individual tokens.
     * `dropByName` is a lookup for the ManagedDrop.
     * `dropNameByTokenId` is a lookup to match a token to the drop it was
     *     minted in.
     * `maxRecallPeriod` is the maximum amount of time after minting, in
     *     seconds, that the contract owner or other authorized user can
     *     "recall" the NFT.
     * `bornOnDate` is the block timestamp when the token was minted.
     */
    struct ERC721Data {
        OwnerOperatorApproval.OwnerOperator owners;
        DropManagement.DropManager dropManager;
        uint256 maxRecallPeriod;
        mapping(uint256 => uint256) bornOnDate;
    }

    /**
     * @dev emitted when a new drop is started.
     */
    event DropAnnounced(Drop drop);

    /**
     * @dev emitted when a drop ends manually or by selling out.
     */
    event DropEnded(Drop drop);

    /**
     * @dev emitted when a token has its URI overridden via `setCustomURI`.
     * @dev not emitted when the URI changes via state changes, changes to the
     *     base uri, or by whatever tokenData.dynamicURI might do.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev emitted when a token changes state.
     */
    event StateChange(
        uint256 indexed tokenId,
        string fromState,
        string toState
    );

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
     * @dev emitted when a token is recalled during the recall period.
     * @dev emitted when a token is recovered from a banned or OFAC sanctioned
     *     user.
     */
    event TokenRecalled(uint256 tokenId, address recallWallet);

    // @dev see ViciAccess
    modifier notBanned(
        AccessManagement.AccessManagementState storage ams,
        address account
    ) {
        ams.enforceIsNotBanned(account);
        _;
    }

    // @dev see OwnerOperatorApproval
    modifier tokenExists(ERC721Data storage tokenData, uint256 tokenId) {
        tokenData.owners.enforceItemExists(tokenId);
        _;
    }

    // @dev see ViciAccess
    modifier onlyOwnerOrRole(
        AccessManagement.AccessManagementState storage ams,
        address account,
        bytes32 role
    ) {
        ams.enforceOwnerOrRole(role, account);
        _;
    }

    /**
     * @dev reverts if the current time is past the recall window for the token
     *     or if the token has been made unrecallable.
     */
    modifier recallable(ERC721Data storage tokenData, uint256 tokenId) {
        requireRecallable(tokenData, tokenId);
        _;
    }

    function init(
        ERC721Data storage tokenData,
        uint256 maxSupply,
        uint256 maxRecall
    ) public {
        tokenData.dropManager.init(maxSupply);
        tokenData.maxRecallPeriod = maxRecall;
    }

    function setRequireCategory(ERC721Data storage tokenData, bool required)
        public
    {
        tokenData.dropManager.setRequireCategory(required);
    }

    /**
     * @dev Returns the total maximum possible size for the collection.
     */
    function getMaxSupply(ERC721Data storage tokenData)
        public
        view
        returns (uint256)
    {
        return tokenData.dropManager.getMaxSupply();
    }

    /**
     * @dev returns the amount available to be minted outside of any drops, or
     *     the amount available to be reserved in new drops.
     * @dev {total available} = {max supply} - {amount minted so far} -
     *      {amount remaining in pools reserved for drops}
     */
    function totalAvailable(ERC721Data storage tokenData)
        public
        view
        returns (uint256)
    {
        return tokenData.dropManager.totalAvailable();
    }

    /**
     * @dev see IERC721Enumerable
     */
    function totalSupply(ERC721Data storage tokenData)
        public
        view
        returns (uint256)
    {
        return tokenData.owners.itemCount();
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     * @param tokenId the token id
     * @return true if the token exists.
     */
    function exists(ERC721Data storage tokenData, uint256 tokenId)
        public
        view
        returns (bool)
    {
        return tokenData.owners.exists(tokenId);
    }

    /**
     * @dev revert if the token does not exist.
     */
    function enforceItemExists(ERC721Data storage tokenData, uint256 tokenId)
        public
        view
    {
        tokenData.owners.enforceItemExists(tokenId);
    }

    /**
     * @dev revert if `account` is not the owner of the token or is not
     *      approved to transfer the token on behalf of its owner.
     */
    function enforceAccess(
        ERC721Data storage tokenData,
        address account,
        uint256 tokenId
    ) public view {
        tokenData.owners.enforceAccess(
            account,
            ownerOf(tokenData, tokenId),
            tokenId,
            1
        );
    }

    /**
     * @dev see IERC721Enumerable
     */
    function tokenOfOwnerByIndex(
        ERC721Data storage tokenData,
        address owner,
        uint256 index
    ) public view returns (uint256) {
        return tokenData.owners.itemOfOwnerByIndex(owner, index);
    }

    /**
     * @dev see IERC721Enumerable
     */
    function tokenByIndex(ERC721Data storage tokenData, uint256 index)
        public
        view
        returns (uint256)
    {
        return tokenData.owners.itemAtIndex(index);
    }

    /**
     * @dev see IERC721
     */
    function balanceOf(ERC721Data storage tokenData, address owner)
        public
        view
        returns (uint256 balance)
    {
        return tokenData.owners.ownerItemCount(owner);
    }

    /**
     * @dev see IERC721
     */
    function ownerOf(ERC721Data storage tokenData, uint256 tokenId)
        public
        view
        returns (address owner)
    {
        return tokenData.owners.ownerOfItemAtIndex(tokenId, 0);
    }

    /**
     * @notice Returns a list of all the token ids owned by an address.
     */
    function userWallet(ERC721Data storage tokenData, address user)
        public
        view
        returns (uint256[] memory)
    {
        return tokenData.owners.userWallet(user);
    }

    /**
     * @dev Safely mints a new token and transfers it to the specified address.
     * @dev Validates drop and available quantities
     * @dev Updates available quantities
     * @dev Deactivates drop when last one is minted
     *
     * Requirements:
     *
     * - `mintData.operator` MUST be owner or have the required role.
     * - `mintData.operator` MUST NOT be banned.
     * - `mintData.category` MAY be an empty string, in which case the token will
     *      be minted in the default category.
     * - If `mintData.category` is an empty string, `tokenData.requireCategory`
     *      MUST NOT be `true`.
     * - If `mintData.category` is not an empty string it MUST refer to an
     *      existing, active drop with sufficient supply.
     * - `mintData.toAddress` MUST NOT be 0x0.
     * - `mintData.toAddress` MUST NOT be banned.
     * - If `mintData.toAddress` refers to a smart contract, it must implement
     *      {IERC721Receiver-onERC721Received}, which is called upon a safe
     *      transfer.
     * - `mintData.tokenId` MUST NOT exist.
     */
    function mint(
        ERC721Data storage tokenData,
        AccessManagement.AccessManagementState storage ams,
        MintData memory mintData
    )
        public
        onlyOwnerOrRole(ams, mintData.operator, mintData.requiredRole)
        notBanned(ams, mintData.toAddress)
    {
        tokenData.dropManager.onMint(
            mintData.dropName,
            mintData.tokenId,
            mintData.customURI
        );

        _mint(tokenData, mintData);
    }

    /**
     * @dev Safely mints the new tokens and transfers them to the specified
     *     addresses.
     * @dev Validates drop and available quantities
     * @dev Updates available quantities
     * @dev Deactivates drop when last one is minted
     *
     * Requirements:
     *
     * - `mintData.operator` MUST be owner or have the required role.
     * - `mintData.operator` MUST NOT be banned.
     * - `mintData.category` MAY be an empty string, in which case the token will
     *      be minted in the default category.
     * - If `mintData.category` is an empty string, `tokenData.requireCategory`
     *      MUST NOT be `true`.
     * - If `mintData.category` is not an empty string it MUST refer to an
     *      existing, active drop with sufficient supply.
     * - `mintData.toAddress` MUST NOT be 0x0.
     * - `mintData.toAddress` MUST NOT be banned.
     * - `_toAddresses` MUST NOT contain 0x0.
     * - `_toAddresses` MUST NOT contain any banned addresses.
     * - The length of `_toAddresses` must equal the length of `_tokenIds`.
     * - If any of `_toAddresses` refers to a smart contract, it must implement
     *      {IERC721Receiver-onERC721Received}, which is called upon a safe
     *      transfer.
     * - `mintData.tokenIds` MUST NOT exist.
     */
    function batchMint(
        ERC721Data storage tokenData,
        AccessManagement.AccessManagementState storage ams,
        BatchMintData memory mintData
    ) public onlyOwnerOrRole(ams, mintData.operator, mintData.requiredRole) {
        require(
            mintData.toAddresses.length == mintData.tokenIds.length,
            "array length mismatch"
        );

        tokenData.dropManager.onBatchMint(mintData.dropName, mintData.tokenIds);

        for (uint256 i = 0; i < mintData.tokenIds.length; i++) {
            ams.enforceIsNotBanned(mintData.toAddresses[i]);

            _mint(
                tokenData,
                MintData(
                    mintData.dropName,
                    mintData.operator,
                    mintData.requiredRole,
                    mintData.toAddresses[i],
                    mintData.tokenIds[i],
                    "",
                    ""
                )
            );
        }
    }

    /**
     * @dev Burns the identified token.
     * @dev Updates available quantities
     * @dev Will not reactivate the drop.
     *
     * Requirements:
     *
     * - `burnData.operator` MUST be owner or have the required role.
     * - `burnData.operator` MUST NOT be banned.
     * - `burnData.operator` MUST own the token or be authorized by the
     *     owner to transfer the token.
     * - `burnData.tokenId` must exist
     */
    function burn(
        ERC721Data storage tokenData,
        AccessManagement.AccessManagementState storage ams,
        BurnData memory burnData
    ) public onlyOwnerOrRole(ams, burnData.operator, burnData.requiredRole) {
        _burn(tokenData, burnData);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     * @dev See {safeTransferFrom}.
     *
     * - `transferData.fromAddress` and `transferData.toAddress` MUST NOT be
     *     the zero address.
     * - `transferData.toAddress`, `transferData.fromAddress`, and
     *     `transferData.operator` MUST NOT be banned.
     * - `transferData.tokenId` MUST belong to `transferData.fromAddress`.
     * - Calling user must be `transferData.fromAddress` or be approved by
     *     `transferData.fromAddress`.
     * - `transferData.tokenId` must exist
     */
    function transfer(
        ERC721Data storage tokenData,
        AccessManagement.AccessManagementState storage ams,
        TransferData memory transferData
    )
        public
        notBanned(ams, transferData.operator)
        notBanned(ams, transferData.fromAddress)
        notBanned(ams, transferData.toAddress)
    {
        _transfer(tokenData, transferData);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     * @dev See {safeTransferFrom}.
     *
     * - `transferData.fromAddress` and `transferData.toAddress` MUST NOT be
     *     the zero address.
     * - `transferData.toAddress`, `transferData.fromAddress`, and
     *     `transferData.operator` MUST NOT be banned.
     * - `transferData.tokenId` MUST belong to `transferData.fromAddress`.
     * - Calling user must be the `transferData.fromAddress` or be approved by
     *     the `transferData.fromAddress`.
     * - `transferData.tokenId` must exist
     */
    function safeTransfer(
        ERC721Data storage tokenData,
        AccessManagement.AccessManagementState storage ams,
        TransferData memory transferData
    )
        public
        notBanned(ams, transferData.operator)
        notBanned(ams, transferData.fromAddress)
        notBanned(ams, transferData.toAddress)
    {
        _safeTransfer(tokenData, transferData);
    }

    function _mint(ERC721Data storage tokenData, MintData memory mintData)
        internal
    {
        require(
            mintData.toAddress != address(0),
            "ERC721: mint to the zero address"
        );
        require(
            !tokenData.owners.exists(mintData.tokenId),
            "ERC721: token already minted"
        );

        tokenData.owners.doTransfer(
            mintData.operator,
            address(0),
            mintData.toAddress,
            mintData.tokenId,
            1
        );
        setBornOnDate(tokenData, mintData.tokenId);
        checkOnERC721Received(
            address(0),
            mintData.toAddress,
            mintData.tokenId,
            mintData.data
        );
        emit Transfer(address(0), mintData.toAddress, mintData.tokenId);
    }

    function _burn(ERC721Data storage tokenData, BurnData memory burnData)
        internal
    {
        address tokenowner = ownerOf(tokenData, burnData.tokenId);

        tokenData.owners.doTransfer(
            burnData.operator,
            tokenowner,
            address(0),
            burnData.tokenId,
            1
        );
        clearBornOnDate(tokenData, burnData.tokenId);

        tokenData.dropManager.postBurnUpdate(burnData.tokenId);

        emit Transfer(tokenowner, address(0), burnData.tokenId);
    }

    function _safeTransfer(
        ERC721Data storage tokenData,
        TransferData memory transferData
    ) internal {
        _transfer(tokenData, transferData);
        checkOnERC721Received(
            transferData.fromAddress,
            transferData.toAddress,
            transferData.tokenId,
            transferData.data
        );
    }

    function _transfer(
        ERC721Data storage tokenData,
        TransferData memory transferData
    ) internal {
        require(
            transferData.toAddress != address(0),
            "ERC721: transfer to the zero address"
        );

        tokenData.owners.doTransfer(
            transferData.operator,
            transferData.fromAddress,
            transferData.toAddress,
            transferData.tokenId,
            1
        );
        emit Transfer(
            transferData.fromAddress,
            transferData.toAddress,
            transferData.tokenId
        );
    }

    /**
     * Requirements
     *
     * - caller MUST be the token owner or be approved for all by the token
     *     owner.
     * - `operator` MUST NOT be the zero address.
     * - `operator` and calling user MUST NOT be banned.
     *
     * @dev see IERC721
     */
    function approve(
        ERC721Data storage tokenData,
        AccessManagement.AccessManagementState storage ams,
        address caller,
        address operator,
        uint256 tokenId
    )
        public
        notBanned(ams, caller)
        notBanned(ams, operator)
        tokenExists(tokenData, tokenId)
    {
        address owner = ownerOf(tokenData, tokenId);
        require(
            caller == owner || tokenData.owners.isApprovedForAll(owner, caller),
            "not authorized"
        );
        tokenData.owners.approveForItem(owner, operator, tokenId);
        emit Approval(owner, operator, tokenId);
    }

    /**
     * @dev see IERC721
     */
    function getApproved(ERC721Data storage tokenData, uint256 tokenId)
        public
        view
        returns (address)
    {
        return
            tokenData.owners.getApprovedForItem(
                ownerOf(tokenData, tokenId),
                tokenId
            );
    }

    /**
     * Requirements
     *
     * - Contract MUST NOT be paused.
     * - `caller` and `operator` MUST NOT be the same address.
     * - `caller` MUST NOT be banned.
     * - `operator` MUST NOT be the zero address.
     * - If `approved` is `true`, `operator` MUST NOT be banned.
     *
     * @dev see IERC721
     */
    function setApprovalForAll(
        ERC721Data storage tokenData,
        AccessManagement.AccessManagementState storage ams,
        address caller,
        address operator,
        bool approved
    ) public notBanned(ams, caller) {
        if (approved) {
            ams.enforceIsNotBanned(operator);
        }
        tokenData.owners.setApprovalForAll(caller, operator, approved);
        emit ApprovalForAll(caller, operator, approved);
    }

    /**
     * @dev see IERC721
     */
    function isApprovedForAll(
        ERC721Data storage tokenData,
        address owner,
        address operator
    ) public view returns (bool) {
        return tokenData.owners.isApprovedForAll(owner, operator);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function isApprovedOrOwner(
        ERC721Data storage tokenData,
        address spender,
        uint256 tokenId
    ) public view tokenExists(tokenData, tokenId) returns (bool) {
        return
            tokenData.owners.isApproved(
                spender,
                ownerOf(tokenData, tokenId),
                tokenId,
                1
            );
    }

    /**
     * @dev Returns the number of tokens that may still be minted in the named drop.
     * @param dropName The name of the drop
     *
     * Requirements:
     *
     * - This function MAY be called with an invalid drop name. The answer will be 0.
     * - This function MAY be called with an empty drop name. The answer will be the
     *    remaining supply for the entire collection minus the number reserved by active drops.
     */
    function amountRemainingInDrop(
        ERC721Data storage tokenData,
        string memory dropName
    ) public view returns (uint256) {
        return tokenData.dropManager.amountRemainingInDrop(dropName);
    }

    /**
     * Requirements:
     *
     * - This function MAY be called with an invalid drop name. The answer will be 0.
     * - This function MAY be called with an empty drop name. The answer will be 0.
     *
     * @param dropName The name of the drop
     */
    function dropMintCount(ERC721Data storage tokenData, string memory dropName)
        public
        view
        returns (uint256)
    {
        return tokenData.dropManager.dropMintCount(dropName);
    }

    /**
     * @dev Returns the number of drops that have been created.
     */
    function dropCount(ERC721Data storage tokenData)
        public
        view
        returns (uint256)
    {
        return tokenData.dropManager.dropCount();
    }

    /**
     * @dev returns the drop with the given name.
     * @dev if there is no drop with the name, the function should return an
     * empty drop.
     */
    function dropForName(ERC721Data storage tokenData, string memory dropName)
        public
        view
        returns (Drop memory)
    {
        return tokenData.dropManager.dropForName(dropName);
    }

    /**
     * @dev Return the name of a drop at `index`. Use along with {dropCount()} to
     * iterate through all the drop names.
     */
    function dropNameForIndex(ERC721Data storage tokenData, uint256 index)
        public
        view
        returns (string memory)
    {
        return tokenData.dropManager.dropNameForIndex(index);
    }

    /**
     * @notice A drop is active if it has been started and has neither run out of supply
     * nor been stopped manually.
     * @dev Returns true if the `dropName` refers to an active drop.
     */
    function isDropActive(ERC721Data storage tokenData, string memory dropName)
        public
        view
        returns (bool)
    {
        return tokenData.dropManager.isDropActive(dropName);
    }

    /**
     * @dev Base URI for computing {tokenURI}. The resulting URI for each
     * token will be he concatenation of the `baseURI` and the `tokenId`.
     */
    function getBaseURI(ERC721Data storage tokenData)
        public
        view
        returns (string memory)
    {
        return tokenData.dropManager.getBaseURI();
    }

    /**
     * @notice This sets the baseURI for any tokens minted outside of a drop.
     */
    function setBaseURI(ERC721Data storage tokenData, string memory baseURI)
        public
    {
        tokenData.dropManager.setBaseURI(baseURI);
    }

    /**
     * @dev get the base URI for the named drop.
     * @dev if `dropName` is the empty string, returns the baseURI for any
     *     tokens minted outside of a drop.
     */
    function getBaseURI(ERC721Data storage tokenData, string memory dropName)
        public
        view
        returns (string memory)
    {
        return tokenData.dropManager.getBaseURI(dropName);
    }

    /**
     * @dev Change the base URI for the named drop.

     * Requirements:
     *
     * - `dropName` MUST refer to a valid drop.
     * - `baseURI` MUST be different from the current `baseURI` for the named drop.
     * - `dropName` MAY refer to an active or inactive drop.
     */
    function setBaseURI(
        ERC721Data storage tokenData,
        string memory dropName,
        string memory baseURI
    ) public {
        tokenData.dropManager.setBaseURI(dropName, baseURI);
    }

    /**
     * @dev return the base URI for the named state in the named drop.
     * @param dropName The name of the drop
     * @param stateName The state to be updated.
     *
     * Requirements:
     *
     * - `dropName` MUST refer to a valid drop.
     * - `stateName` MUST refer to a valid state for `dropName`
     * - `dropName` MAY refer to an active or inactive drop
     */
    function getBaseURIForState(
        ERC721Data storage tokenData,
        string memory dropName,
        string memory stateName
    ) public view returns (string memory) {

        return tokenData.dropManager.getBaseURIForState(dropName, stateName);
    }

    /**
     * @dev Change the base URI for the named state in the named drop.
     *
     * Requirements:
     *
     * - `dropName` MUST refer to a valid drop.
     * - `fromState` MUST refer to a valid state for `dropName`
     * - `dropName` MAY refer to an active or inactive drop
     */
    function setBaseURIForState(
        ERC721Data storage tokenData,
        string memory dropName,
        string memory stateName,
        string memory baseURI
    ) public {
        tokenData.dropManager.setBaseURIForState(dropName, stateName, baseURI);
    }

    /**
     * @dev Override the baseURI + tokenId scheme for determining the token
     * URI with the specified custom URI.
     *
     * @param tokenId The token to use the custom URI
     * @param newURI The custom URI
     *
     * Requirements:
     *
     * - `tokenId` MAY refer to an invalid token id. Setting the custom URI
     *      before minting is allowed.
     * - `newURI` MAY be an empty string, to clear a previously set customURI
     *      and use the default scheme.
     */
    function setCustomURI(
        ERC721Data storage tokenData,
        uint256 tokenId,
        string memory newURI
    ) public {
        tokenData.dropManager.setCustomURI(tokenId, newURI);
    }

    /**
     * @dev Use this contract to override the default mechanism for
     *     generating token ids.
     *
     * Requirements:
     * - `dynamicURI` MAY be the null address, in which case the override is
     *     removed and the default mechanism is used again.
     * - If `dynamicURI` is not the null address, it MUST be the address of a
     *     contract that implements the DynamicURI interface (0xc87b56dd).
     */
    function setDynamicURI(
        ERC721Data storage tokenData,
        string memory dropName,
        DynamicURI dynamicURI
    ) public {
        tokenData.dropManager.setDynamicURI(dropName, dynamicURI);
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     *
     * @param tokenId the tokenId
     */
    function getTokenURI(ERC721Data storage tokenData, uint256 tokenId)
        public
        view
        tokenExists(tokenData, tokenId)
        returns (string memory)
    {
        return tokenData.dropManager.getTokenURI(tokenId);
    }

    /**
     * @notice Starts a new drop.
     * @param dropName The name of the new drop
     * @param dropStartTime The unix timestamp of when the drop is active
     * @param dropSize The number of NFTs in this drop
     * @param startStateName The initial state for the drop's state machine.
     * @param baseURI The base URI for the tokens in this drop
     *
     * Requirements:
     *
     * - There MUST be sufficient unreserved tokens for the drop size.
     * - The drop size MUST NOT be empty.
     * - The drop name MUST NOT be empty.
     * - The drop name MUST be unique.
     */
    function startNewDrop(
        ERC721Data storage tokenData,
        string memory dropName,
        uint32 dropStartTime,
        uint32 dropSize,
        string memory startStateName,
        string memory baseURI
    ) public {
        tokenData.dropManager.startNewDrop(
            dropName,
            dropStartTime,
            dropSize,
            startStateName,
            baseURI
        );
    }

    /**
     * @notice Ends the named drop immediately. It's not necessary to call this.
     * The current drop ends automatically once the last token is sold.
     *
     * @param dropName The name of the drop to deactivate
     *
     * Requirements:
     *
     * - There MUST be an active drop with the `dropName`.
     */
    function deactivateDrop(
        ERC721Data storage tokenData,
        string memory dropName
    ) public {
        tokenData.dropManager.deactivateDrop(dropName);
    }

    /**
     * @notice Sets up a state transition
     *
     * Requirements:
     * - `dropName` MUST refer to a valid drop
     * - `fromState` MUST refer to a valid state for `dropName`
     * - `toState` MUST NOT be empty
     * - `baseURI` MUST NOT be empty
     * - A transition named `toState` MUST NOT already be defined for `fromState`
     *    in the drop named `dropName`
     */
    function addStateTransition(
        ERC721Data storage tokenData,
        string memory dropName,
        string memory fromState,
        string memory toState,
        string memory baseURI
    ) public {
        tokenData.dropManager.addStateTransition(
            dropName,
            fromState,
            toState,
            baseURI
        );
    }

    /**
     * @notice Removes a state transition. Does not remove any states.
     *
     * Requirements:
     * - `dropName` MUST refer to a valid drop.
     * - `fromState` and `toState` MUST describe an existing transition.
     */
    function deleteStateTransition(
        ERC721Data storage tokenData,
        string memory dropName,
        string memory fromState,
        string memory toState
    ) public {
        tokenData.dropManager.deleteStateTransition(
            dropName,
            fromState,
            toState
        );
    }

    /**
     * @dev Move the token to a new state. Reverts if the
     * state transition is invalid.
     */
    function changeState(
        ERC721Data storage tokenData,
        uint256 tokenId,
        string memory stateName
    ) public tokenExists(tokenData, tokenId) {
        tokenData.dropManager.setState(tokenId, stateName, true);
    }

    /**
     * @dev Arbitrarily set the token state. Does not revert if the
     * transition is invalid. Will revert if the new state doesn't
     * exist.
     */
    function setState(
        ERC721Data storage tokenData,
        uint256 tokenId,
        string memory stateName
    ) public tokenExists(tokenData, tokenId) {
        tokenData.dropManager.setState(tokenId, stateName, false);
    }

    /**
     * @dev Returns the token's current state
     * @dev Returns empty string if the token is not managed by a state machine.
     */
    function getState(ERC721Data storage tokenData, uint256 tokenId)
        public
        view
        tokenExists(tokenData, tokenId)
        returns (string memory)
    {
        return tokenData.dropManager.getState(tokenId);
    }

    /**
     * @dev revert if the recall period has expired.
     */
    function requireRecallable(ERC721Data storage tokenData, uint256 tokenId)
        public
        view
    {
        require(_recallTimeRemaining(tokenData, tokenId) > 0, "not recallable");
    }

    /**
     * @dev If the bornOnDate for `tokenId` + `_maxRecallPeriod` is later than
     * the current timestamp, returns the amount of time remaining, in seconds.
     * @dev If the time is past, or if `tokenId`  doesn't exist in `_tracker`,
     * returns 0.
     */
    function recallTimeRemaining(ERC721Data storage tokenData, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return _recallTimeRemaining(tokenData, tokenId);
    }

    /**
     * @dev Returns the `bornOnDate` for `tokenId` as a Unix timestamp.
     * @dev If `tokenId` doesn't exist in `_tracker`, returns 0.
     */
    function getBornOnDate(ERC721Data storage tokenData, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return tokenData.bornOnDate[tokenId];
    }

    /**
     * @dev Returns true if `tokenId` exists in `_tracker`.
     */
    function hasBornOnDate(ERC721Data storage tokenData, uint256 tokenId)
        public
        view
        returns (bool)
    {
        return tokenData.bornOnDate[tokenId] != 0;
    }

    /**
     * @dev Sets the `bornOnDate` for `tokenId` to the current timestamp.
     * @dev This should only be called when the token is minted.
     */
    function setBornOnDate(ERC721Data storage tokenData, uint256 tokenId)
        public
    {
        require(!hasBornOnDate(tokenData, tokenId));
        tokenData.bornOnDate[tokenId] = block.timestamp;
    }

    /**
     * @dev Remove `tokenId` from `_tracker`.
     * @dev This should be called when the token is burned, or when the end
     * customer has confirmed that they can access the token.
     */
    function clearBornOnDate(ERC721Data storage tokenData, uint256 tokenId)
        public
    {
        tokenData.bornOnDate[tokenId] = 0;
    }

    /**
     * @notice An NFT minted on this contact can be "recalled" by the contract
     * owner for an amount of time defined here.
     * @notice An NFT cannot be recalled once this amount of time has passed
     * since it was minted.
     * @notice The purpose of the recall function is to support customers who
     * have supplied us with an incorrect address or an address that doesn't
     * support Polygon (e.g. Coinbase custodial wallet).
     * @notice Divide the recall period by 86400 to convert from seconds to days.
     *
     * Requirements:
     *
     * - `transferData.operator` MUST be the contract owner or have the
     *      required role.
     * - The token must exist.
     * - The current timestamp MUST be within `maxRecallPeriod` of the token's
     *    `bornOn` date.
     * - `transferData.toAddress` MAY be 0, in which case the token is burned
     *     rather than recalled to a wallet.
     */
    function recall(
        ERC721Data storage tokenData,
        AccessManagement.AccessManagementState storage ams,
        TransferData memory transferData,
        bytes32 requiredRole
    )
        public
        notBanned(ams, transferData.toAddress)
        tokenExists(tokenData, transferData.tokenId)
        recallable(tokenData, transferData.tokenId)
        onlyOwnerOrRole(ams, transferData.operator, requiredRole)
    {
        _doRecall(tokenData, transferData, requiredRole);
    }

    /**
     * @notice recover assets in banned or sanctioned accounts
     *
     * Requirements
     * - `transferData.operator` MUST be the contract owner.
     * - The owner of `transferData.tokenId` MUST be banned or OFAC sanctioned
     * - `transferData.destination` MAY be the zero address, in which case the
     *     asset is burned.
     */
    function recoverSanctionedAsset(
        ERC721Data storage tokenData,
        AccessManagement.AccessManagementState storage ams,
        TransferData memory transferData,
        bytes32 requiredRole
    )
        public
        notBanned(ams, transferData.toAddress)
        tokenExists(tokenData, transferData.tokenId)
        onlyOwnerOrRole(ams, transferData.operator, requiredRole)
    {
        require(
            ams.isBanned(transferData.fromAddress) ||
                ams.isSanctioned(transferData.fromAddress),
            "Not banned or sanctioned"
        );
        _doRecall(tokenData, transferData, requiredRole);
    }

    /**
     * @notice Prematurely ends the recall period for an NFT.
     * @notice This action cannot be reversed.
     *
     * Requirements:
     *
     * - `caller` MUST be one of the following:
     *    - the contract owner.
     *    - the a user with customer service role.
     *    - the token owner.
     *    - an address authorized by the token owner.
     * - `caller` MUST NOT be banned or on the OFAC sanctions list
     */
    function makeUnrecallable(
        ERC721Data storage tokenData,
        AccessManagement.AccessManagementState storage ams,
        address caller,
        bytes32 serviceRole,
        uint256 tokenId
    ) public notBanned(ams, caller) tokenExists(tokenData, tokenId) {
        if (
            caller != ams.getContractOwner() &&
            !ams.hasRole(serviceRole, caller)
        ) {
            tokenData.owners.enforceAccess(
                caller,
                ownerOf(tokenData, tokenId),
                tokenId,
                1
            );
        }

        clearBornOnDate(tokenData, tokenId);
    }

    function _recallTimeRemaining(ERC721Data storage tokenData, uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        uint256 currentTimestamp = block.timestamp;
        uint256 recallDeadline = tokenData.bornOnDate[tokenId] +
            tokenData.maxRecallPeriod;
        if (currentTimestamp >= recallDeadline) {
            return 0;
        }

        return recallDeadline - currentTimestamp;
    }

    function _doRecall(
        ERC721Data storage tokenData,
        TransferData memory transferData,
        bytes32 requiredRole
    ) internal {
        tokenData.owners.approveForItem(
            transferData.fromAddress,
            transferData.operator,
            transferData.tokenId
        );

        if (transferData.toAddress == address(0)) {
            _burn(
                tokenData,
                BurnData(
                    transferData.operator,
                    requiredRole,
                    transferData.fromAddress,
                    transferData.tokenId
                )
            );
        } else {
            _safeTransfer(tokenData, transferData);
        }

        emit TokenRecalled(transferData.tokenId, transferData.toAddress);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param fromAddress address representing the previous owner of the given token ID
     * @param toAddress target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     */
    function checkOnERC721Received(
        address fromAddress,
        address toAddress,
        uint256 tokenId,
        bytes memory data
    ) public {
        if (toAddress.isContract()) {
            try
                IERC721Receiver(toAddress).onERC721Received(
                    msg.sender,
                    fromAddress,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                require(
                    retval == IERC721Receiver.onERC721Received.selector,
                    "ERC721: transfer to non ERC721Receiver implementer"
                );
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }
}

// File: Mintable.sol

interface Mintable is IERC721Enumerable {
    /**
     * @notice returns the total number of tokens that may be minted.
     */
    function maxSupply() external view returns (uint256);

    /**
     * @notice mints a token into `_toAddress`.
     * @dev This should revert if it would exceed maxSupply.
     * @dev This should revert if `_toAddress` is 0.
     * @dev This should revert if `_tokenId` already exists.
     *
     * @param _category Type, group, option name etc. used or ignored by token manager.
     * @param _toAddress The account to receive the newly minted token.
     * @param _tokenId The id of the new token.
     */
    function mint(
        string memory _category,
        address _toAddress,
        uint256 _tokenId
    ) external;

    /**
     * @notice mints a token into `_toAddress`.
     * @dev This should revert if it would exceed maxSupply.
     * @dev This should revert if `_toAddress` is 0.
     * @dev This should revert if `_tokenId` already exists.
     *
     * @param _category Type, group, option name etc. used or ignored by token manager.
     * @param _toAddress The account to receive the newly minted token.
     * @param _tokenId The id of the new token.
     * @param _customURI the custom URI.
     */
    function mintCustom(
        string memory _category,
        address _toAddress,
        uint256 _tokenId,
        string memory _customURI
    ) external;

    /**
     * @notice mint several tokens into `_toAddresses`.
     * @dev This should revert if it would exceed maxSupply
     * @dev This should revert if any `_toAddresses` are 0.
     * @dev This should revert if any`_tokenIds` already exist.
     *
     * @param _category Type, group, option name etc. used or ignored by token manager.
     * @param _toAddresses The accounts to receive the newly minted tokens.
     * @param _tokenIds The ids of the new tokens.
     */
    function batchMint(
        string memory _category,
        address[] memory _toAddresses,
        uint256[] memory _tokenIds
    ) external;

    /**
     * @notice returns true if the token id is already minted.
     */
    function exists(uint256 tokenId) external returns (bool);
}

// File: ViciERC721v4.sol

/**
 * @notice Base NFT contract for ViciNFT.
 * @notice It supports recall, ERC2981 royalties, multiple drops, pausible,
 *     ownable, access roles, and OFAC sanctions compliance.
 * @notice default recall period is 14 days from minting. Once you have
 *     received your NFT and have verified you can access it, you can call
 *     `makeUnrecallable(uint256)` with your token id to turn off recall
 *     for your token.
 * @notice Roles used by the access management are
 * - DEFAULT_ADMIN_ROLE: administers the other roles
 * - MODERATOR_ROLE_NAME: administers the banned role
 * - CREATOR_ROLE_NAME: can mint/burn tokens and manage URIs/content
 * - CUSTOMER_SERVICE: can recall tokens sent to invalid/inaccessible addresses
 *     within a limited time window.
 * - BANNED_ROLE: cannot send or receive tokens
 * @notice A "drop" is a pool of reserved tokens with a common base URI,
 *     representing a subset within a collection.
 * @dev If you want an NFT that can evolve through various states, support for
 *     that is available here, but it will be more convenient to extend from
 *     MutableViciERC721
 */
contract ViciERC721v4 is
    BaseViciContract,
    Mintable,
    ERC2981ContractWideRoyalties,
    Recallable,
    ContextMixin
{
    using Address for address;
    using Strings for string;
    using SafeMath for uint256;
    using ERC721Operations4 for ERC721Operations4.ERC721Data;

    /**
     * @notice emitted when a new drop is started.
     */
    event DropAnnounced(Drop drop);

    /**
     * @dev emitted when a drop ends manually or by selling out.
     */
    event DropEnded(Drop drop);

    /**
     * @dev emitted when a token has its URI overridden via `setCustomURI`.
     * @dev not emitted when the URI changes via state changes, changes to the
     *     base uri, or by whatever tokenData.dynamicURI might do.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev emitted when a token changes state.
     */
    event StateChange(
        uint256 indexed tokenId,
        string fromState,
        string toState
    );

    string public constant INITIAL_STATE = "NEW";
    string public constant INVALID_STATE = "INVALID";

    // Creator can create a new token type and mint an initial supply.
    bytes32 public constant CREATOR_ROLE_NAME = "creator";

    // Customer service can recall tokens within time period
    bytes32 public constant CUSTOMER_SERVICE = "Customer Service";

    string public name;
    string public symbol;

    string public contractURI = "";

    ERC721Operations4.ERC721Data tokenData;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply
    ) {
        name = _name;
        symbol = _symbol;
        tokenData.init(_maxSupply, maxRecallPeriod());
    }

    // @inheritdoc ERC721
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ViciAccess, ERC2981Base, IERC165)
        returns (bool)
    {
        return (_interfaceId == type(IERC721Enumerable).interfaceId ||
            _interfaceId == type(IERC721).interfaceId ||
            _interfaceId == type(IERC721Metadata).interfaceId ||
            _interfaceId == type(Mintable).interfaceId ||
            ViciAccess.supportsInterface(_interfaceId) ||
            ERC2981Base.supportsInterface(_interfaceId) ||
            _interfaceId == type(Recallable).interfaceId ||
            super.supportsInterface(_interfaceId));
    }

    /**
     * @notice Returns the total maximum possible size for the collection.
     */
    function maxSupply() public view returns (uint256) {
        return tokenData.getMaxSupply();
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     * @param _tokenId the token id
     * @return true if the token exists.
     */
    function exists(uint256 _tokenId) public view virtual returns (bool) {
        return tokenData.exists(_tokenId);
    }

    /**
     * @notice sets a uri pointing to metadata about this token collection.
     * @dev OpenSea honors this. Other marketplaces might honor it as well.
     * @param _newContractURI the metadata uri
     *
     * Requirements:
     *
     * - Contract MUST NOT be paused.
     * - Calling user MUST be owner or have the creator role.
     * - Calling user MUST NOT be banned.
     */
    function setContractURI(string memory _newContractURI)
        public
        virtual
        noBannedAccounts
        onlyOwnerOrRole(CREATOR_ROLE_NAME)
    {
        contractURI = _newContractURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        return tokenData.getTokenURI(_tokenId);
    }

    /**
     * @notice This sets the baseURI for any tokens minted outside of a drop.
     * @param _baseURI the new base URI.
     *
     * Requirements:
     *
     * - Calling user MUST be owner or have the uri manager role.
     */
    function setBaseURI(string memory _baseURI)
        public
        onlyOwnerOrRole(CREATOR_ROLE_NAME)
    {
        tokenData.setBaseURI(_baseURI);
    }

    function getBaseURI() public view returns (string memory) {
        return tokenData.getBaseURI();
    }

    /**
     * @dev Change the base URI for the named drop.
     * Requirements:
     *
     * - Calling user MUST be owner or URI manager.
     * - `_dropName` MUST refer to a valid drop.
     * - `_baseURI` MUST be different from the current `baseURI` for the named drop.
     * - `_dropName` MAY refer to an active or inactive drop.
     */
    function setBaseURI(string memory _dropName, string memory _baseURI)
        public
        virtual
        onlyOwnerOrRole(CREATOR_ROLE_NAME)
    {
        tokenData.setBaseURI(_dropName, _baseURI);
    }

    /**
     * @dev get the base URI for the named drop.
     * @dev if `_dropName` is the empty string, returns the baseURI for any
     *     tokens minted outside of a drop.
     */
    function getBaseURIForDrop(string memory _dropName)
        public
        view
        returns (string memory)
    {
        return tokenData.getBaseURI(_dropName);
    }

    /**
     * @notice Sets a custom uri for a token
     * @param _tokenId the token id
     * @param _newURI the new base uri
     *
     * Requirements:
     *
     * - Calling user MUST be owner or have the creator role.
     * - Calling user MUST NOT be banned.
     * - `_tokenId` MAY be for a non-existent token.
     * - `_newURI` MAY be an empty string.
     */
    function setCustomURI(uint256 _tokenId, string memory _newURI)
        public
        noBannedAccounts
        onlyOwnerOrRole(CREATOR_ROLE_NAME)
    {
        tokenData.setCustomURI(_tokenId, _newURI);
    }

    /**
     * @notice Use this contract to override the default mechanism for 
     *     generating token ids.
     * 
     * Requirements:
     * - `dynamicURI` MAY be the null address, in which case the override is
     *     removed and the default mechanism is used again.
     * - If `dynamicURI` is not the null address, it MUST be the address of a
     *     contract that implements the DynamicURI interface (0xc87b56dd).
     */
    function setDynamicURI(string memory dropName, DynamicURI dynamicURI)
        public
        noBannedAccounts
        onlyOwnerOrRole(CREATOR_ROLE_NAME)
    {
        tokenData.setDynamicURI(dropName, dynamicURI);
    }

    /**
     * @inheritdoc IERC721Enumerable
     */
    function totalSupply() public view returns (uint256) {
        return tokenData.totalSupply();
    }

    /**
     * @dev returns the amount available to be minted outside of any drops, or
     *     the amount available to be reserved in new drops.
     * @dev {total available} = {max supply} - {amount minted so far} -
     *      {amount remaining in pools reserved for drops}
     */
    function totalAvailable() public view returns (uint256) {
        return tokenData.totalAvailable();
    }

    /**
     * @inheritdoc IERC721Enumerable
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        public
        view
        returns (uint256)
    {
        return tokenData.tokenOfOwnerByIndex(_owner, _index);
    }

    /**
     * @inheritdoc IERC721Enumerable
     */
    function tokenByIndex(uint256 _index) public view returns (uint256) {
        return tokenData.tokenByIndex(_index);
    }

    /**
     * @inheritdoc IERC721
     */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return tokenData.balanceOf(_owner);
    }

    /**
     * @inheritdoc IERC721
     */
    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        return tokenData.ownerOf(_tokenId);
    }

    /**
     * @notice Returns a list of all the token ids owned by an address.
     */
    function userWallet(address _user) public view returns (uint256[] memory) {
        return tokenData.userWallet(_user);
    }

    /**
     * @notice Safely mints a new token and transfers it to `_toAddress`.
     * @param _category Type, group, option name etc.
     * @param _toAddress The account to receive the newly minted token.
     * @param _tokenId The id of the new token.
     *
     * Requirements:
     *
     * - Contract MUST NOT be paused.
     * - Calling user MUST be owner or have the creator role.
     * - Calling user MUST NOT be banned.
     * - `_category` MAY be an empty string, in which case the token will be 
     *     minted in the default category.
     * - If `_category` is an empty string, `tokenData.requireCategory` MUST 
     *     NOT be `true`.
     * - If `_category` is not an empty string it MUST refer to an existing, 
     *     active drop with sufficient supply.
     * - `_toAddress` MUST NOT be 0x0.
     * - `_toAddress` MUST NOT be banned.
     * - If `_toAddress` refers to a smart contract, it must implement
     *     {IERC721Receiver-onERC721Received}, which is called upon a safe
     *     transfer.
     * - `_tokenId` MUST NOT exist.
     */
    function mint(
        string memory _category,
        address _toAddress,
        uint256 _tokenId
    ) public virtual whenNotPaused {
        tokenData.mint(
            ams,
            MintData(
                _category,
                _msgSender(),
                CREATOR_ROLE_NAME,
                _toAddress,
                _tokenId,
                "",
                ""
            )
        );

        _post_mint_hook(_toAddress, _tokenId);
    }

    /**
     * @notice Safely mints a new token with a custom URI and transfers it to
     *      `_toAddress`.
     * @param _category Type, group, option name etc.
     * @param _toAddress The account to receive the newly minted token.
     * @param _tokenId The id of the new token.
     * @param _customURI the custom URI.
     *
     * Requirements:
     *
     * - Contract MUST NOT be paused.
     * - Calling user MUST be owner or have the creator role.
     * - `_category` MAY be an empty string, in which case the token will be 
     *     minted in the default category.
     * - If `_category` is an empty string, `tokenData.requireCategory` MUST 
     *     NOT be `true`.
     * - If `_category` is not an empty string it MUST refer to an existing, 
     *     active drop with sufficient supply.
     * - `_toAddress` MUST NOT be 0x0.
     * - `_toAddress` MUST NOT be banned.
     * - If `_toAddress` refers to a smart contract, it must implement
     *      {IERC721Receiver-onERC721Received}, which is called upon a safe
     *      transfer.
     * - `_tokenId` MUST NOT exist.
     * - `_customURI` MAY be empty, in which case it will be ignored.
     */
    function mintCustom(
        string memory _category,
        address _toAddress,
        uint256 _tokenId,
        string memory _customURI
    ) public virtual whenNotPaused {
        tokenData.mint(
            ams,
            MintData(
                _category,
                _msgSender(),
                CREATOR_ROLE_NAME,
                _toAddress,
                _tokenId,
                _customURI,
                ""
            )
        );

        _post_mint_hook(_toAddress, _tokenId);
    }

    /**
     * @notice Safely mints a new token and transfers it to `_toAddress`.
     * @param _category Type, group, option name etc.
     * @param _toAddress The account to receive the newly minted token.
     * @param _tokenId The id of the new token.
     * @param _customURI the custom URI.
     * @param _data bytes optional data to send along with the call
     *
     * Requirements:
     *
     * - Contract MUST NOT be paused.
     * - Calling user MUST be owner or have the creator role.
     * - Calling user MUST NOT be banned.
     * - `_category` MAY be an empty string, in which case the token will be 
     *     minted in the default category.
     * - If `_category` is an empty string, `tokenData.requireCategory` MUST 
     *     NOT be `true`.
     * - If `_category` is not an empty string it MUST refer to an existing, 
     *     active drop with sufficient supply.
     * - `_toAddress` MUST NOT be 0x0.
     * - `_toAddress` MUST NOT be banned.
     * - If `_toAddress` refers to a smart contract, it must implement
     *      {IERC721Receiver-onERC721Received}, which is called upon a safe
     *      transfer.
     * - `_tokenId` MUST NOT exist.
     * - `_customURI` MAY be empty, in which case it will be ignored.
     */
    function safeMint(
        string memory _category,
        address _toAddress,
        uint256 _tokenId,
        string memory _customURI,
        bytes memory _data
    ) public virtual whenNotPaused {
        tokenData.mint(
            ams,
            MintData(
                _category,
                _msgSender(),
                CREATOR_ROLE_NAME,
                _toAddress,
                _tokenId,
                _customURI,
                _data
            )
        );

        _post_mint_hook(_toAddress, _tokenId);
    }

    /**
     * @notice Safely mints a batch of new tokens and transfers them to the
     *      `_toAddresses`.
     * @param _category Type, group, option name etc.
     * @param _toAddresses The accounts to receive the newly minted tokens.
     * @param _tokenIds The ids of the new tokens.
     *
     * Requirements:
     *
     * - Contract MUST NOT be paused.
     * - Calling user MUST be owner or have the creator role.
     * - Calling user MUST NOT be banned.
     * - `_category` MAY be an empty string, in which case the token will be 
     *     minted in the default category.
     * - If `_category` is an empty string, `tokenData.requireCategory` MUST 
     *     NOT be `true`.
     * - If `_category` is not an empty string it MUST refer to an existing, 
     *     active drop with sufficient supply.
     * - `_toAddresses` MUST NOT contain 0x0.
     * - `_toAddresses` MUST NOT contain any banned addresses.
     * - The length of `_toAddresses` must equal the length of `_tokenIds`.
     * - If any of `_toAddresses` refers to a smart contract, it must implement
     *      {IERC721Receiver-onERC721Received}, which is called upon a safe
     *      transfer.
     * - `_tokenIds` MUST NOT exist.
     */
    function batchMint(
        string memory _category,
        address[] memory _toAddresses,
        uint256[] memory _tokenIds
    ) public virtual whenNotPaused {
        tokenData.batchMint(
            ams,
            BatchMintData(
                _category,
                _msgSender(),
                CREATOR_ROLE_NAME,
                _toAddresses,
                _tokenIds
            )
        );

        for (uint256 i = 0; i < _toAddresses.length; i++) {
            _post_mint_hook(_toAddresses[i], _tokenIds[i]);
        }
    }

    /**
     * @notice Burns the identified token.
     * @param _tokenId The token to be burned.
     *
     * Requirements:
     *
     * - Contract MUST NOT be paused.
     * - Calling user MUST be owner or have the creator role.
     * - Calling user MUST NOT be banned.
     * - Calling user MUST own the token or be authorized by the owner to 
     *     transfer the token.
     * - `_tokenId` must exist
     */
    function burn(uint256 _tokenId) public whenNotPaused {
        _burn(_tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     * @dev See {safeTransferFrom}.
     * 
     * Requirements
     *
     * - Contract MUST NOT be paused.
     * - `_fromAddress` and `_toAddress` MUST NOT be the zero address.
     * - `_toAddress`, `_fromAddress`, and calling user MUST NOT be banned.
     * - `_tokenId` MUST belong to `_fromAddress`.
     * - Calling user must be the `_fromAddress` or be approved by the `_fromAddress`.
     * - `_tokenId` must exist
     * 
     * @inheritdoc IERC721
     */
    function transferFrom(
        address _fromAddress,
        address _toAddress,
        uint256 _tokenId
    ) public override whenNotPaused {
        tokenData.transfer(
            ams,
            TransferData(_msgSender(), _fromAddress, _toAddress, _tokenId, "")
        );
    }

    /**
     * Requirements
     *
     * - Contract MUST NOT be paused.
     * - `_fromAddress` and `_toAddress` MUST NOT be the zero address.
     * - `_toAddress`, `_fromAddress`, and calling user MUST NOT be banned.
     * - `_tokenId` MUST belong to `_fromAddress`.
     * - Calling user must be the `_fromAddress` or be approved by the `_fromAddress`.
     * - If `_toAddress` refers to a smart contract, it must implement
     *      {IERC721Receiver-onERC721Received}, which is called upon a safe
     *      transfer.
     * - `_tokenId` must exist
     *
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address _fromAddress,
        address _toAddress,
        uint256 _tokenId
    ) public override {
        safeTransferFrom(_fromAddress, _toAddress, _tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     * @dev See {safeTransferFrom}.
     *
     * - Contract MUST NOT be paused.
     * - `_fromAddress` and `_toAddress` MUST NOT be the zero address.
     * - `_toAddress`, `_fromAddress`, and calling user MUST NOT be banned.
     * - `_tokenId` MUST belong to `_fromAddress`.
     * - Calling user must be the `_fromAddress` or be approved by the `_fromAddress`.
     * - If `_toAddress` refers to a smart contract, it must implement
     *      {IERC721Receiver-onERC721Received}, which is called upon a safe
     *      transfer.
     * - `_tokenId` must exist
     * 
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address _fromAddress,
        address _toAddress,
        uint256 _tokenId,
        bytes memory _data
    ) public override whenNotPaused {
        tokenData.safeTransfer(
            ams,
            TransferData(
                _msgSender(),
                _fromAddress,
                _toAddress,
                _tokenId,
                _data
            )
        );
    }

    /**
     * Requirements
     *
     * - Contract MUST NOT be paused.
     * - caller MUST be the token owner or be approved for all by the token
     *     owner.
     * - `_operator` MUST NOT be the zero address.
     * - `_operator` and calling user MUST NOT be banned.
     *
     * @inheritdoc IERC721
     */
    function approve(address _operator, uint256 _tokenId)
        public
        override
        whenNotPaused
    {
        tokenData.approve(ams, _msgSender(), _operator, _tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function getApproved(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        return tokenData.getApproved(_tokenId);
    }

    /**
     * Requirements
     *
     * - Contract MUST NOT be paused.
     * - Calling user and `_operator` MUST NOT be the same address.
     * - Calling user MUST NOT be banned.
     * - `_operator` MUST NOT be the zero address.
     * - If `_approved` is `true`, `_operator` MUST NOT be banned.
     *
     * @inheritdoc IERC721
     */
    function setApprovalForAll(address _operator, bool _approved)
        public
        override
        whenNotPaused
    {
        tokenData.setApprovalForAll(ams, _msgSender(), _operator, _approved);
    }

    /**
     * @inheritdoc IERC721
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool)
    {
        return tokenData.isApprovedForAll(_owner, _operator);
    }

    /**
     * @dev Returns the number of tokens that may still be minted in the named drop.
     *
     * @param _dropName The name of the drop
     *
     * Requirements:
     *
     * - This function MAY be called with an invalid drop name. The answer will be 0.
     * - This function MAY be called with an empty drop name. The answer will be the
     *    remaining supply for the entire collection minus the number reserved by active drops.
     */
    function amountRemainingInDrop(string memory _dropName)
        public
        view
        returns (uint256)
    {
        return tokenData.amountRemainingInDrop(_dropName);
    }

    /**
     * @dev Returns the number of tokens minted so far in a drop.
     *
     * @param _dropName The name of the drop
     */
    function dropMintCount(string memory _dropName)
        public
        view
        returns (uint256)
    {
        return tokenData.dropMintCount(_dropName);
    }

    /**
     * @dev Returns the number of drops that have been created.
     */
    function dropCount() public view returns (uint256) {
        return tokenData.dropCount();
    }

    /**
     * @dev Return the name of a drop at `_index`. Use along with {dropCount()} to
     * iterate through all the drop names.
     */
    function dropNameForIndex(uint256 _index)
        public
        view
        returns (string memory)
    {
        return tokenData.dropNameForIndex(_index);
    }

    /**
     * @dev Return the drop at `_index`. Use along with {dropCount()} to iterate through
     * all the drops.
     */
    function dropForIndex(uint256 _index) public view returns (Drop memory) {
        return dropForName(dropNameForIndex(_index));
    }

    /**
     * @dev returns the drop with the given name.
     * @dev if there is no drop with the name, the function should return an
     * empty drop.
     */
    function dropForName(string memory _dropName)
        public
        view
        returns (Drop memory)
    {
        return tokenData.dropForName(_dropName);
    }

    /**
     * @notice A drop is active if it has been started and has neither run out of supply
     * or been stopped manually.
     * @dev Returns true if the `_dropName` refers to an active drop.
     *
     * Requirements:
     *
     * - This function MAY be called with an invalid drop name. The answer will be false.
     * - This function MAY be called with an empty drop name. The answer will be false.
     */
    function isDropActive(string memory _dropName) public view returns (bool) {
        return tokenData.isDropActive(_dropName);
    }

    /**
     * @notice Starts a new drop.
     * @param _dropName The name of the new drop
     * @param _dropStartTime The unix timestamp of when the drop is active
     * @param _dropSize The number of NFTs in this drop
     * @param _baseURI The base URI for the tokens in this drop
     *
     * Requirements:
     *
     * - Calling user MUST be owner or have the drop manager role.
     * - There MUST be sufficient unreserved tokens for the drop size.
     * - The drop size MUST NOT be empty.
     * - The drop name MUST NOT be empty.
     * - The drop name MUST be unique.
     */
    function startNewDrop(
        string memory _dropName,
        uint32 _dropStartTime,
        uint32 _dropSize,
        string memory _baseURI
    ) public onlyOwnerOrRole(CREATOR_ROLE_NAME) {
        tokenData.startNewDrop(
            _dropName,
            _dropStartTime,
            _dropSize,
            INITIAL_STATE,
            _baseURI
        );
    }

    /**
     * @notice Ends the named drop immediately. It's not necessary to call this.
     * The current drop ends automatically once the last token is sold.
     *
     * @param _dropName The name of the drop to deactivate
     *
     * Requirements:
     *
     * - Calling user MUST be owner or have the drop manager role.
     * - There MUST be an active drop with the `_dropName`.
     */
    function deactivateDrop(string memory _dropName)
        public
        onlyOwnerOrRole(CREATOR_ROLE_NAME)
    {
        tokenData.deactivateDrop(_dropName);
    }

    /**
     * @notice An NFT minted on this contact can be "recalled" by the contract
     * owner for an amount of time defined here.
     * @notice An NFT cannot be recalled once this amount of time has passed
     * since it was minted.
     * @notice The purpose of the recall function is to support customers who
     * have supplied us with an incorrect address or an address that doesn't
     * support Polygon (e.g. Coinbase custodial wallet).
     * @notice Divide the recall period by 86400 to convert from seconds to days.
     *
     * @dev The maximum amount of time after minting, in seconds, that the contract
     * owner or other authorized user can "recall" the NFT.
     */
    function maxRecallPeriod() public view virtual returns (uint256) {
        return 1209600; // 14 days
    }

    /**
     * @notice Returns the amount of time remaining before a token can be recalled.
     * @notice Divide the recall period by 86400 to convert from seconds to days.
     * @notice This will return 0 if the token cannot be recalled.
     * @notice Due to the way block timetamps are determined, there is a 15
     * second margin of error in the result.
     *
     * @param _tokenId the token id.
     *
     * Requirements:
     *
     * - This function MAY be called with a non-existent `_tokenId`. The
     *   function will return 0 in this case.
     */
    function recallTimeRemaining(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return tokenData.recallTimeRemaining(_tokenId);
    }

    /**
     * @notice An NFT minted on this contact can be "recalled" by the contract
     * owner for an amount of time defined here.
     * @notice An NFT cannot be recalled once this amount of time has passed
     * since it was minted.
     * @notice The purpose of the recall function is to support customers who
     * have supplied us with an incorrect address or an address that doesn't
     * support Polygon (e.g. Coinbase custodial wallet).
     * @notice Divide the recall period by 86400 to convert from seconds to days.
     *
     * @param _toAddress The address where the token will go after it has been recalled.
     * @param _tokenId The token to be recalled.
     *
     * Requirements:
     *
     * - The caller MUST be the contract owner or have the customer service role.
     * - The token must exist.
     * - The current timestamp MUST be within `maxRecallPeriod` of the token's
     *    `bornOn` date.
     * - `_toAddress` MAY be 0, in which case the token is burned rather than
     *    recalled to a wallet.
     */
    function recall(address _toAddress, uint256 _tokenId)
        public
        onlyOwnerOrRole(CUSTOMER_SERVICE)
    {
        address currentOwner = ownerOf(_tokenId);

        tokenData.recall(
            ams,
            TransferData(_msgSender(), currentOwner, _toAddress, _tokenId, ""),
            CUSTOMER_SERVICE
        );

        if (_toAddress == address(0)) {
            _post_burn_hook(currentOwner, _tokenId);
        }
    }

    /**
     * @notice recover assets in banned or sanctioned accounts
     * @param _destination the location to send the asset
     * @param _tokenId the token id
     *
     * Requirements
     * - Caller MUST be the contract owner.
     * - The owner of `_tokenId` MUST be banned or OFAC sanctioned
     * - `_destination` MAY be the zero address, in which case the asset is
     *      burned.
     */
    function recoverSanctionedAsset(address _destination, uint256 _tokenId)
        public
        virtual
        onlyOwner
    {
        address currentOwner = ownerOf(_tokenId);

        tokenData.recoverSanctionedAsset(
            ams,
            TransferData(
                _msgSender(),
                currentOwner,
                _destination,
                _tokenId,
                ""
            ),
            CUSTOMER_SERVICE
        );

        if (_destination == address(0)) {
            _post_burn_hook(currentOwner, _tokenId);
        }
    }

    /**
     * @notice Prematurely ends the recall period for an NFT.
     * @notice This action cannot be reversed.
     *
     * @param _tokenId The token to be recalled.
     *
     * Requirements:
     *
     * - The caller MUST be one of the following:
     *    - the contract owner.
     *    - the a user with customer service role.
     *    - the token owner.
     *    - an address authorized by the token owner.
     * - The caller MUST NOT be banned or on the OFAC sanctions list
     */
    function makeUnrecallable(uint256 _tokenId) public {
        tokenData.makeUnrecallable(
            ams,
            _msgSender(),
            CUSTOMER_SERVICE,
            _tokenId
        );
    }

    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    function _setRoyaltiesHook(
        address recipient,
        uint256 /*value*/
    ) internal view override noBannedAccounts notBanned(recipient) {
        if (_msgSender() != owner()) {
            _checkRole(ROYALTIES_MANAGER, _msgSender());
        }
    }

    /**
     * @dev Returns whether `_spender` is allowed to manage `_tokenId`.
     *
     * Requirements:
     *
     * - `_tokenId` must exist.
     */
    function _isApprovedOrOwner(address _spender, uint256 _tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        return tokenData.isApprovedOrOwner(_spender, _tokenId);
    }

    /**
     * @dev Destroys `_tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `_tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 _tokenId) internal virtual {
        address token_owner = ownerOf(_tokenId);
        tokenData.burn(
            ams,
            BurnData(_msgSender(), CREATOR_ROLE_NAME, token_owner, _tokenId)
        );

        _post_burn_hook(token_owner, _tokenId);
    }

    function _post_mint_hook(address _toAddress, uint256 _tokenId)
        internal
        virtual
    {}

    function _post_burn_hook(address _fromAddress, uint256 _tokenId)
        internal
        virtual
    {}
}

// File: StevensCreek.sol

/**
 * @title Stevens Creek Chrysler Jeep Dodge
 *
 * Welcome to the [Stevens Creek Chrysler Jeep
 * Dodge](https://www.stevenscreekchryslerjeepdodge.net/) Vehicle
 * Information Repository. The vehicles in this collection have been
 * authenticated by Stevens Creek Chrysler dealership and will be preserved
 * on the blockchain with manufacturer data, car registration information,
 * and vehicle documents.
 *
 * Stevens Creek Chrysler Jeep Dodge is the Bay Area's premier Dealer for
 * new Chrysler, Jeep, Dodge, Sprinter and quality used cars. ​​Located in
 * San Jose, California serving Sunnyvale, San Francisco, and Oakland.
 */

contract StevensCreek is ViciERC721v4 {
    constructor()
        ViciERC721v4(
            "Stevens Creek Chrysler Jeep Dodge",
            "SCCJD",
            100000
        )
    {
        setContractURI(
            "https://storage.googleapis.com/arrival-shadow-motion-newman/vici/cars/StevensCreek.json"
        );
    }
}