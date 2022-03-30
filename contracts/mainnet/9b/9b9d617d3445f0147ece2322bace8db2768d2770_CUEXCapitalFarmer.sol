/**
 *Submitted for verification at polygonscan.com on 2022-03-30
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/utils/Strings.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/utils/EnumerableMap.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint256(value)));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/utils/EnumerableSet.sol



pragma solidity >=0.6.0 <0.8.0;

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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/utils/Address.sol



pragma solidity >=0.6.2 <0.8.0;

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
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/math/SafeMath.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
        require(c / a == b, "SafeMath: multiplication overflow");

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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/utils/Counters.sol



pragma solidity >=0.6.0 <0.8.0;


/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

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
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/token/ERC721/IERC721Receiver.sol



pragma solidity >=0.6.0 <0.8.0;

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/introspection/IERC165.sol



pragma solidity >=0.6.0 <0.8.0;

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/introspection/ERC165.sol



pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/token/ERC721/IERC721.sol



pragma solidity >=0.6.2 <0.8.0;


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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/token/ERC721/IERC721Enumerable.sol



pragma solidity >=0.6.2 <0.8.0;


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/token/ERC721/IERC721Metadata.sol



pragma solidity >=0.6.2 <0.8.0;


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/GSN/Context.sol



pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/access/Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/token/ERC721/ERC721.sol



pragma solidity >=0.6.0 <0.8.0;












/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(_baseURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
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
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

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
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// File: contracts/nft.sol


pragma solidity ^0.7.6;





interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract CUEXCapitalFarmer is ERC721, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    //issue
    uint256 private _issuance = 0;

    //minting limit
    uint256 public _mintingLimit = 10000;

    //fee for mint
    uint256 public _mintFee = 32934131700000000000;

    //nft token tokn uri
    string public _nftTokenURI = 'https://cuep.io/nft/eth/ccap/ccap-farmer.php?id=';

    //marketing
    address payable public _marketingWallet = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    mapping(address => uint256) public holders;
    mapping(uint256 => bool) public issues;

    constructor() ERC721("CUEX Capital Farmer", "CUEXCapitalFarmer") {

        holders[0x1b1A1eb1D1FBC8bd062c3a86a325cbBd0B4050f1] = 6794;
        holders[0x1fFaF934278F247E392A7f5E1A444b9103c32e68] = 5775;
        holders[0x5e3773713f0A20806168D633652B905ee7253f83] = 6096;
        holders[0xE7852cC72bE4d13168892635D2AdD78B9A33CF1B] = 9278;
        holders[0x149203739ba7763cc9DA34C7D81A7DB97655f6db] = 1552;
        holders[0x6413995aC0e09dB909d4DD70f1814C82705800A8] = 2033;
        holders[0xef6d9100b8c32bcE46711df36642653043190350] = 8107;
        holders[0x4dF39EF2835b8d7DB11F928127508E098608904e] = 3244;
        holders[0xE1e04f0402887CfE57512EE6db4bf74E59FcA4eF] = 4467;
        holders[0x4A9a32F8a311884E3844d984779f44C661017647] = 3892;
        holders[0x2019621a5826D018989A0dB3341BbA9E0c596FF4] = 6777;
        holders[0xB18FEc5CC92A8FE8c37d3fA9E15fa1bF4726dF7a] = 9093;
        holders[0xfb9699DE6f7eFc7F7D64A40852a68602ac7ef403] = 5387;
        holders[0x91d7Cb9826148A4e1bcAe48DffcC77c2F3B2988F] = 5751;
        holders[0x6f2A8eAdaaFFc5B1FA5EC33E7bb946eE34Bb2b53] = 2045;
        holders[0x0eeD2846EBb9c21372772fa68d57523248873384] = 11;
        holders[0x6e7BE23e38EC87dab1aa9F8097FDE7FCa4223640] = 7;
        holders[0x2ddd7D23279D780C1df1430Af478f9eFab4EA1E6] = 9312;
        holders[0x9B20924eE21094F36551a3882b123F84a8843589] = 4526;
        holders[0x827BF8Bbf52e15183828878227c9a1aE8429F841] = 5987;
        holders[0x4BdA90F0127dF84c12C36cB443Da4c852eF26f4E] = 6181;
        holders[0x7ae04eD7f1082d8AA1c19893E9eC4039a666C02C] = 6907;
        holders[0x0De664c923aB3139CBA4f37720B2644F25738beE] = 8876;
        holders[0x67917E551343ad3A160501Dc491e2ED1b5960bFA] = 2210;
        holders[0xe03ffFF005daa17d0dbfd231f8d2A542f92829C9] = 5340;
        holders[0x9aeAEE775BB25f0456368006C073F4d3D95919a6] = 9342;
        holders[0x5d48EB8F079790e140e456F83C1C786B5dCae31E] = 3912;
        holders[0x99B84A93E416A41B4964b8Ff483f06040B29BFD9] = 7362;
        holders[0x642E98Ff243302aBA3e459e5BA125C6e6B062978] = 3157;
        holders[0x75A399488d7a668814f2911EA63d8077dA536D45] = 4864;
        holders[0xF83821e16b53962be9d603FD66f10E22F5539cCB] = 696;
        holders[0x0b1bf35f49083419274B4836119E86ebe7A0e14F] = 9095;
        holders[0xe03a6C5A0B8C2118ac8056FF21f117FD3E299BA7] = 965;
        holders[0x33f3b93826Cd6b65fF4aa29c903Ae18234070515] = 6371;
        holders[0x0122D6753B3D21D920555589F50b24a18E2AC480] = 6273;
        holders[0x73EAEdBA1cedEE5Bd6B17737929F3aee79264501] = 2411;
        holders[0xc39887e88336378e90b9AaB88fbf9FfDd923d2EB] = 4153;
        holders[0x8D8E13B6F914a57474Ca783DCdA112E9835B4a2C] = 6972;
        holders[0x232E3F153df9E79A20b97cC8219DB94982bd5da9] = 3626;
        holders[0x2e3249AA8f85930E865Bb04EB6F7932B86E86503] = 7079;
        holders[0xC21d48BA7109Be04909a188C3197B3651b23541D] = 6042;
        holders[0x1D570452e6a212105cfaB90B3aC293575C2dFaAD] = 7495;
        holders[0x83a5339023d4a2E17A149ADECD77A5A12c7Ee422] = 7687;
        holders[0x720a88Ce946e355BF01765ff501430f7d44fF845] = 881;
        holders[0xb0853EF854925Ed624a87432Eb147bBF7Af0e513] = 3123;
        holders[0x9902767Aa58E0210BAbf3De8164b9377f28ace7d] = 1305;
        holders[0x9fe553de68865F425d8071C81640855A7C9613eb] = 2436;
        holders[0x3eBE4857c16aCFa25ca5f7fe43A15Cf3b5433359] = 1172;
        holders[0x2393cEA39614acc2aC49cB9123f8C1418a71939f] = 2787;
        holders[0xF0C354e0142F08bc97f09b0A4B3b0457DE2769Ec] = 1280;
        holders[0xd10c4F6741f416F79b0a5011aA6367F0a1159F19] = 7084;
        holders[0xdf2A74066b91815B39d22f9f25846663597fAc5e] = 8425;
        holders[0xe839363FCAdB3045F0dD68Bb60D8466E6AddBc0C] = 6138;
        holders[0x03adDBfEC98b44159ea53de5cb50D2bf399b0896] = 5573;
        holders[0xB49f4e66e6DCeb185284C337c95A552257b84b9D] = 753;
        holders[0xcb6F7001690deb961C48CbffD7f36564321683B3] = 4871;
        holders[0x9cb2995bB8209522A63bCE059FA7A0dFFd403747] = 7234;
        holders[0x9e31B0492F6075c3DC819142F89D3028143012cB] = 9272;
        holders[0x5e501c8448d5B18D75bfB482dFFf12F83e2dc45b] = 8593;
        holders[0x49Cb2Dc4694358BB4b0303D8315db6174A48c72A] = 8405;
        holders[0x799bc40Ec2241c6B05665c3A65478faA62A0F00A] = 3592;
        holders[0xeBc8F56A8b424F1e2C029fbF2ba57d0B89b2d61d] = 408;
        holders[0x72AA98b3A949f6B2762BBDe200BF678d7AA3e595] = 2999;
        holders[0x4c7F30364e4EB3f7AB5f9A7aC82d6f92D3DE8a5b] = 7285;
        holders[0xEa8Cd45391318F1404D62533B9F7EB54e6CbD76A] = 4354;
        holders[0x4DEFc44cDfd3EeE7fAe1d5a3901E97B27cd01E3c] = 2970;
        holders[0xB99cC85C5B1fb28cA5F7A5439fCdBAd1f00a582D] = 2767;
        holders[0x59084e83e35057dF77473a1e01e5EFEaA998AD9C] = 842;
        holders[0xe79dbFa465ecC3E7816081944940238E4F1b95Ee] = 8846;
        holders[0xC78BdA13915eC02685b331C5c5558127ECa79CA2] = 9875;
        holders[0xA26D1195746758650E8C4dF94F4BeDbB3ADd5C59] = 6271;
        holders[0x529f35c805BdEE4D5699CAbf86c0D41F9C0860B0] = 6778;
        holders[0xae253A1ead89fDbD376Cf2b86Da1818Ba06fdB11] = 6228;
        holders[0x93af48D692e79E40E0e5a82438b83687fe5c05B5] = 8501;
        holders[0xfC048D020243469d6E4f02baBe216D85be55a044] = 5038;
        holders[0x6D93bEBCc1468b3aA8138dB53A9b0f487fb00Df8] = 2430;
        holders[0x9e220Aa49d95D2D26bDC93C5Fe688117383C44E4] = 7109;
        holders[0xE42000fB79C9Eb7c3c5a9C5665F30f186CCA3917] = 1433;
        holders[0x8B676bead875BDBC905659559883Ac11F378749A] = 9003;
        holders[0x79C602BBF6d372a18c99CF8508980EF95f8637C3] = 1356;
        holders[0xec8Eb5e64Cc9ba269c10144941e4917ff6d0B7bb] = 6139;
        holders[0x91FC88b9E1c1A42B5f4cdc87d5cd067A77C1fefB] = 6772;
        holders[0xA0c79E5154EE16309946668C4C331AaED665BAa3] = 8750;
        holders[0x2AD8E20722B7a74D2d3337C73c61AaDa76Ffb040] = 8128;
        holders[0x44Df1eEa15c5486cd29dabA7550F448C254B8cfe] = 4958;
        holders[0xF1FB60f8fe401F5c807d31a6b4EaD71A0a35DD8b] = 4837;
        holders[0x4Ed90C8833b0D4EbBD7b22111f9516F154e43Ebc] = 4156;
        holders[0x65C77b331962FcF205e554D7A6dAa19e9a4F6B6E] = 4926;
        holders[0xCd5F5e025Cea6E4c1d8219DA0671d6BD7546483f] = 8138;
        holders[0xcF38C9c755326B8B91D1867f40A87bd4c5F09DAF] = 9983;
        holders[0xF361C77Fe72Acfbc15D007433FFBCd31934F61F7] = 823;
        holders[0xacBB67985107F44ABb39111E4AA5B55D3063C876] = 2545;
        holders[0x1A85eAf5eE9B711ecbf8DC3D732b6B27721933d5] = 7170;
        holders[0x76720A2bf21CC202B13b421593773dd07Ea29e23] = 5132;
        holders[0x455B6117123a869a01F9DF431CD5995B08B12429] = 7096;
        holders[0x4e0675970004C24fD1cF8C59727d791173295173] = 6121;
        holders[0x323aAB76dc4697E201b3ddEd8cf5faf16ea472D9] = 1349;
        holders[0x3Cea38F19E8E94940Be00b5d440Cc0788DB49e57] = 4286;
        holders[0x5c2D8Fb84474a9E94094707321C3203f458de5F3] = 7412;
        holders[0xC83dF0125E59BfAaC85a7766cDE6CB04E757B202] = 8080;
        holders[0xeF379FE0848b4767c7E577Fe21f6c30397248889] = 567;
        holders[0xfDE3aAD873cb2f668A06D11c2E11aB33B6dB0Ef2] = 5418;
        holders[0x28ae56fd4d86c51f7f1498cdaC21De150EE16F87] = 979;
        holders[0x644F7d33F206E1894Ffa74e96653Bc55437EFb0f] = 5761;
        holders[0x2556d24cB929C0456266f83e4fdD2E7D40BA867d] = 8355;
        holders[0xa4268Ea3a990f583d2968629653BA8d6537169Ac] = 8597;
        holders[0xe2e91A3c9ED219A3039190C4C68084E37C18534D] = 9363;
        holders[0x4399518609fCDEF8d9BA544cde6F84ED45d7027D] = 7613;
        holders[0x920fC6753eDF7C41a735631204C9C5E27fd56360] = 7520;
        holders[0x0dD001066f6E8dc65DA7e5FE808415E42567087E] = 3977;
        holders[0x477794750EEE4DB9e98cbA22B0926a4cBd86523E] = 6385;
        holders[0x4Ba591f318bf7DEDDEbE8F12409B3524858EBB5b] = 429;
        holders[0x4f73dA7ac9097875D8c069030A7050d55bDe7c25] = 6374;
        holders[0x73160070C09429BCFEd61fdC6eFdfFA5D2aE65B9] = 7910;
        holders[0x68fbf7F4c8A4fB7cB639b19331DB542945a7f06B] = 761;
        holders[0x015d972B38A26cDF662166050f5fA58F19bEC4B5] = 4415;
        holders[0x3b2EA87282c9A4bAB5658E5f3eC2E392268d1A6e] = 2134;
        holders[0x564704F1Ff0a396FCE08A55c890e5603d0b62e53] = 3657;
        holders[0xf373501Cff547deb137E1A3A23710b7B0da9D86e] = 6744;
        holders[0x56387994FA1938e030f224258d7c7FB52DaE157D] = 4914;
        holders[0x2D4b56eAE356449d9e5d266e4d45F60F745ca9A6] = 3128;
        holders[0xc590175E458b83680867AFD273527Ff58f74c02b] = 5458;
        holders[0xEAc34c53c960D03296B856aD03d78043e134be81] = 2255;
        holders[0x57BfC70B53C54B2FABe5e49E5e92992396867549] = 8764;
        holders[0xf22126bB6c07e93D3EB9Bdf1BAE825007c17b853] = 9773;
        holders[0xf56eA4C0cD284850abb167c47dd60e137cAA681e] = 1648;
        holders[0x20Eb94F6C785cBc874325A7F19274B66e4bFec36] = 3587;
        holders[0x99B2B3A993cC84381Ee3B48764De04E2d6553e67] = 9153;
        holders[0x2dea3DefD7127E79CE53d82b7fA27B53f6C7eCBf] = 3580;
        holders[0x9C0b5306d5E3f75bce032bd4133f320A3415cD85] = 2765;
        holders[0x378e9CA064066a71337b9FD9Ab9A0488fcF27831] = 4720;
        holders[0xD7375912b2f71b77d5325583e16A57E6D50F22dD] = 6650;
        holders[0xB7e6Fe62C9D6736748E9E4F8483dEA237C31699a] = 4429;
        holders[0xfb7BB8D52ea9ecE5dBD97bbB0b78aD27E47529b6] = 7498;
        holders[0xEfdB0A4322b593d26806adec6AcF872E92829Cf6] = 6182;
        holders[0x8228cdaDf5972a4F772c342ABB24BEE6c7488b1f] = 7491;
        holders[0x152068a491581D44e56950AB44B770a66660058c] = 5610;
        holders[0x36277B133802379A85634C6f662672d62025A08f] = 5048;
        holders[0x7CdC713a57012129f26fD3a503b83941f803Bc0c] = 4889;
        holders[0xf544bAc1a32FF75249A1aFd9d08e0E9791c6dEc1] = 5403;
        holders[0x22CB3eE9aAd7131262101dabCD68789769f03CE6] = 1053;
        holders[0x024F4B55f39a93d27A03a213Ad553053c99EbB9E] = 5097;
        holders[0x6e94328e826e3EF7b9083DE330B30794176F3100] = 7228;
        holders[0x95e8b32ebe3Ce533D2f98C9179FeA16ED6dAf52f] = 323;
        holders[0x6Ec984d39b4E3E5c35B6f31d9D9A96Ad9C1f9c15] = 3781;
        holders[0x6c2Fe6cb49458c6Ac0854C7dE2D69D1Ff5622F29] = 4939;
        holders[0xAbA863A46ec691de896F7Bee8Ce9aBC39a3963fd] = 8718;
        holders[0xeD131541f5f72D934d613527b8E7785b9Fa12B85] = 7488;
        holders[0xA8fA9729C066448Ea2908fd4154Baa12642c3b7B] = 4805;
        holders[0xFf741C991486bd235eCbdaE5c2A4F644cDd5553D] = 4222;
        holders[0x661323249B64d348deFD2DCB5E113F82FFb9BAEe] = 568;
        holders[0x0AAF12b8eF475f9D517883da6f9147aAe38702c9] = 1279;
        holders[0x280dae7f39dEc9e7d3Fd8e02d69Cfb2f4FEF2577] = 2654;
        holders[0x417a1d63DE1A12Cb7a545E2D3A64FB75041Ce44e] = 6554;
        holders[0x5Dbb9c2490bfEd1ff288A3351a177657Dd64dc05] = 7383;
        holders[0x798a6a9482946EAd6c803ade99e538499Bb950C1] = 5030;
        holders[0x3025CfcBcaFe70F89ed61FF1CEe58054767e9A2c] = 8956;
        holders[0xB1b9b4bbe8a92d535F5Df2368e7Fd2ecFB3A1950] = 2293;
        holders[0x0Bfd38C80a5FE2Ad9f86fbBbAf73f0042d33c8fF] = 9037;
        holders[0x01A07fF8bc422078C4C14E54Fa1Acca6AD7E63a1] = 2396;
        holders[0xB185beb6b9De3197a859d66A16d3afF02525dEA3] = 7001;
        holders[0xcB100Bb044893fA9a2Ce5deDA071553F0d79dEb6] = 3628;
        holders[0xe2AcAC86D4f1702A6B179794Ef3C8953E6D579C8] = 7805;
        holders[0xB4fD10ee4766dAa27F344B9A9E3A83D234b50F68] = 6038;
        holders[0x7fdF4927d51b3F5A369a2DEe927333348c8C4a51] = 5610;
        holders[0x7842F19E3066c3d4046D51233d53A8712cC4F87A] = 2423;
        holders[0x678DA03Ee2c311Daa7ED32D4aD9C351Af3A6e9de] = 5444;
        holders[0x79b45eBA4Ed8a7F60cf0dADA1ecD0b67D852381b] = 9832;
        holders[0xE1AC33923CE52aa8EE385582AaFbc08bfE7125AB] = 6449;
        holders[0x7faa4f874485836c5ac5E95A4d1398f09f929Fa9] = 2778;
        holders[0x8172f5bF7fD1f9d1e836e8c75D2Cd017a8C2f7FD] = 6054;
        holders[0x55678Ae10d9310B59F4269Bf8fecC179C574a12c] = 1049;
        holders[0xB84b2C205B27d562345F093fb3D1B36Ce890d396] = 845;
        holders[0xc33a02c25EA09a333616bc3CFcDaC18d1aCb9710] = 8066;
        holders[0xEd7880Aab212b71E46DbAcAFf088684c612Bd210] = 3776;
        holders[0x2Fea779F7e76D164FA098339aA49919F91B50B3c] = 3837;
        holders[0x71E84A22Ae1930B7dd60891A70d7e76b81585c95] = 6835;
        holders[0x570A792343506e042b8b2056C7c8306E448B0a8B] = 7753;
        holders[0xa916077459FcA01Aec6D072B89Dd43abfc0b00eC] = 9898;
        holders[0xD09743CF6Ff624a89193de785684fB89e812C240] = 9099;
        holders[0x63202470a811381385A1e51cF5c84Fb0CE5c0fb6] = 2816;
        holders[0xaC9624ff7A1d35C564108eFB490c23FcB23Cf99B] = 5878;
        holders[0x69089A585ea3A27D8A1EA3838f235B34d5273D20] = 5620;
        holders[0xf9ACf8b27B9850fc332118Ae8f9F6112F92a7AFD] = 6952;
        holders[0x538871a05CF8CA5d6cE617293b5A5251bE01C0FA] = 3979;
        holders[0xDe3030231C6e72Fa38D62CDEFc7FE2D42931a396] = 4087;
        holders[0x246bE07A257e9C64522F10912aCc4d0Ca143B06f] = 4573;
        holders[0x96b7c266C68BAabc7Da1B4d71de453435eA2B9E7] = 6756;
        holders[0xc4a9696408e15478b001EE1B988d970746f2EBee] = 7297;
        holders[0x75ee8fe8AfF2AC7B53DCF6c8539ACd4e40ce09cF] = 7486;
        holders[0x7dD8e11380bF4828e7B94a67f0C45FC083CDDeD5] = 1393;
        holders[0x4d868da1ff15f8d742844726e339A12BAcAd9705] = 6113;
        holders[0x5bEEF6F00B002498A09837604D3da502D854A4B7] = 647;
        holders[0x9354e7AE7B4458C201a577d14AdEC37188e9dE7B] = 2492;
        holders[0x03721453746E9325B564992008DfD9b68B040ac4] = 1705;
        holders[0x225Cf2106f4144615aE45Bc20B59a1A92c2BFd38] = 753;
        holders[0x6389a415850A6f39d73814E17f7B05aDF3ebCF30] = 4301;
        holders[0x101234508BdB91E7CC2d396CDbfD2ca01CbDC8d1] = 4610;
        holders[0x5009AAf4F0a9Cd87896323E8e8aaEfA07c5B0397] = 7225;
        holders[0x48616dF86A0D02ce959903D5041b2a4d2fF344D4] = 1704;
        holders[0xA447e2B48AC061f3489443273e489731CccEeEaA] = 8464;
        holders[0xB37607B1C5d762268C7f5233BddA74c89DD7AaB7] = 4353;
        holders[0x872EFe9C4D0bB5D8b6Da003ab98bf710E0733C74] = 7817;
        holders[0x41b598A24acC085C56D2A1e57B4Dc6F27E017c44] = 2155;
        holders[0xD995b1C87EA765035b657fE995879293f769F16a] = 5420;
        holders[0x36B4f0ddcdf31f08B4CB40f6a2A9C1155E8Dc1FB] = 1911;
        holders[0x2AEBE3199ffa065438BbF46B9756Ea0303b86Bb4] = 785;
        holders[0x5745a464bc1B320387DC105AC00E307d4DE19CC8] = 4577;
        holders[0x518f0cDE678a21FaC2fADCD02aDbb65D84de91be] = 3051;
        holders[0xa8ACa89a5fa763A7A6055019d2E944780B09b4C3] = 5951;
        holders[0xcC5e3F398777800C27964efFaB0Ea30316b53FFb] = 8610;
        holders[0xb8CFF21712b5f1Fe988C99095DC5E39338C7A6a9] = 1827;
        holders[0xF950F6BCa8db86Ebc3fdc9eC53c7DF7aA45334a4] = 3443;
        holders[0xFde7cebEa7227791E27fDF6152B6702921A2ac79] = 9223;
        holders[0x15CD1328b9fE4c05a9C668c2FF68A0D5A5D308E2] = 6664;
        holders[0xF1abb84bd3a46916e64b1dF23B5e37B23ab61860] = 9673;
        holders[0x5B6C6FA53532772320b2924702e45E874f1663Ec] = 7839;
        holders[0x00d2c6f5b3F7466B6356CfcAe7bce8a84EDEF4D8] = 4814;
        holders[0xCB415F8492669b628Dd1a2261D65Fe4e2948677F] = 4148;
        holders[0xefa2401a0033D0571e0C17406f04e293DD80Cb2C] = 8859;
        holders[0x7B837312CeB8A03c0aa9cd4A1e62D0939B7d6Cf8] = 7164;
        holders[0xeE944Bf07Db1bff0653E2D7dE2E043184C7DB9bB] = 7626;
        holders[0xC98835596edb6E9327B0eDB87071E061cd035419] = 9423;
        holders[0x1FA1B70cAf74633335455d5F253B2b528797a9d6] = 4057;
        holders[0xFEbdF55FF101813221ff0A03935F11142067a9a6] = 6098;
        holders[0x2F4A329fd7873dAa7F687808003274EEdCA27c77] = 4675;
        holders[0x3888A95CD31C68125215d3FaFF41dAC6D213f9D3] = 2886;
        holders[0x10edD77a49647c2F8Fd05b6328a49D430F6743a7] = 1878;
        holders[0xD2e3B2fAD1B0E22dDa17666Afcda5F394f25fddF] = 5285;
        holders[0x8A9e20c8D380f3801cC4d71797Efe5940E851A25] = 2260;
        holders[0xB67038858000aB01592E8968014CCE31D12fC9c2] = 7057;
        holders[0x692EeAf03A1814a72FF653809C892e75d4cc1461] = 6588;
        holders[0x42b3d65094A75CB7daEfF8D92737E8A31814c2e4] = 3742;
        holders[0xb1eaFDeFc1c9B192ce5Ce76eaC28a9ef35BABF95] = 5808;
        holders[0x30d9365dEB034C475cC434348904E7C8926550b0] = 9052;
        holders[0x3b12b930525b2101D35736Af122fF7a04e9F4Fd6] = 7763;
        holders[0xDB3Ac5005261c4e8956F1f351afaD374c2e4A07A] = 1581;
        holders[0x8580571288Db02aA58955aD52Ca35B8c732Fd2d7] = 2934;
        holders[0xF6C78707f02E5B8717efC445A858366858286E8b] = 8118;
        holders[0x27eAAbAf44f17b4BCe9F9455619C3014095Ea639] = 6495;
        holders[0xdcc5c1B0543e4231B0843bEED2aA079Addc8ec33] = 9393;
        holders[0x395BDb9b3BE3c198071d1e61d887894f8EB79219] = 1712;
        holders[0x363B4ad865a39F34be551af0cD6b3d79d59527A2] = 3731;
        holders[0x167e3030A3745604C1344EDd07cE4D1472f63d07] = 4335;
        holders[0xC60604863DD799f8D72EB678D631AfD099d44C18] = 5911;
        holders[0x7aBAd192E6B0e7682329bF981399a7E14f58A5F4] = 2654;
        holders[0xc0aBedf979A3C977D1FdC540181664C850b185DB] = 455;
        holders[0x9b70553b5827AD47EF83Fb92Ad21047128a808F2] = 7387;
        holders[0x2E5DB0892F88a71140045438772E7da850Ac85ae] = 8775;
        holders[0xD3CD9E46a19e260e595219E20E9AD560fBc30505] = 9408;
        holders[0x13C65A3248726C89992FC8B98CD972dE01646560] = 2506;
        holders[0x6dA33963A12A4D426DC909fdEa65Ab48F179C234] = 8823;
        holders[0xaB4758Dec5AD0a38c236f1682d32f92aFBcbE847] = 5136;
        holders[0xB39863aCd274191921762A537deec0C970E9176A] = 2019;
        holders[0x9515a860dc2354eE399E352CA256CE9cDB6E0cd0] = 5032;
        holders[0xC65599F993ED9F14F0b32a23aaC57aB397918F8f] = 8477;
        holders[0x513b027EE8E0AB259dA90d98343e5D4552A19C3a] = 1476;
        holders[0x13b8A8642E6E790218247EB335D1B0651D272fB1] = 9180;
        holders[0x81E75C616105A78668b395c33eB0f67FD6CCF44B] = 1538;
        holders[0x357596b4d982D472644ac4F14e192899a47153bc] = 6011;
        holders[0xce02fC7c285313a6138Dc6A4d155aa222Ecc69A4] = 7280;
        holders[0x0D2959479E71577754349187b2373ca7261b7eFF] = 6384;
        holders[0x8cEB096C40a6726e1C3515C3833Ca65F60F36CaB] = 4569;
        holders[0x105E3D3779100a451b41115E0bEcBc764CD4eF5A] = 7384;
        holders[0x30E1Ad86513d0Ac3a2A1d315BAb9eacEbD20b527] = 6923;
        holders[0x07EF06509e59145BA8c1c5F394A656beF21ed4D9] = 6127;
        holders[0xD7C6C11F9E2dBE968846f01C7f3F96eb80c712A1] = 6677;
        holders[0x72be729d48211FC4aBBE06B23cb861c60b6125Cc] = 3095;
        holders[0x227F3Df1a0cF74714A3ccfBbd5b3D7ae5b1e106F] = 3166;
        holders[0x2C7185477391D313698A171f2923f1fF57207555] = 1828;
        holders[0xCA91f9577979a2117e8d33503b260f9F258b5D24] = 3215;
        holders[0x077d12A9611AB875d8A92ce22c4325e03E34fc41] = 4074;
        holders[0xE4F2bfF79Ad6D999Ec9103423a20f2aF8345Cdb6] = 6454;
        holders[0x6a857Db6bf8764Ca8fB888d0878aA077Ec399990] = 7527;
        holders[0x6efC2e284B7A786Cb95dF5A3F48E2B2650EA081A] = 8469;
        holders[0xC14b8660E965586D73F0E331D24e6898E7c0637F] = 2545;
        holders[0xDEBd306Fa45d73A1B87e2b01f7b9E2BFDD85934B] = 2046;
        holders[0xE29E55b93C620b0C745cf3f236c802EAFe51A9b3] = 5584;
        holders[0x6AB16f49a70b51369a10a2565e3E7F91213C3dD0] = 2720;
        holders[0xC75c7A2CdB74Eb66877165dD3Ff03d6369cbd37e] = 7596;
        holders[0x50bd6492733Ddf08dE9fEbC780E3e56D3BF23ed3] = 844;
        holders[0x464CD134E3002aC46e560fbf3CD1442E862353Bb] = 6979;
        holders[0xE453ba5AAC22Fbe7efFa9EE9055a315608c6a663] = 9596;
        holders[0x46C2153415b838EA4666545FE07C28229f00628E] = 8666;
        holders[0x997655f3e4A5bbFF68C3BB7B4cd9b2405de3e495] = 9685;
        holders[0xd97cbC25eBAC856CAE70D4B62ae8911087235b49] = 4828;
        holders[0xfA468bba18035DfFa82E7F2478bEae08F0FadD5A] = 1443;
        holders[0xe94602394096098617BaB187355Bcb35D7AfEc16] = 3581;
        holders[0x419308281F220d8DbDa265CC64F652b549F467f8] = 6707;
        holders[0xd64E54FfCc95878eFD467Da451CD794f7B300453] = 437;
        holders[0x0228e934195D956E1A37B09750F3737737dBFBDd] = 9735;
        holders[0xD784a0149d150C520E1a478a4B6F5e7B8dEFA98B] = 5893;
        holders[0x97d0f1A2E2dc7819A5FaBa99314c5d27dC4725E1] = 2224;
        holders[0x915Cee02bD1551C0e1555DfBa83EB0117532b49A] = 8266;
        holders[0x9e59BF2644316169B173de951B0FA821e3d51c5b] = 1500;
        holders[0x3818fd9c204EF253c5710E80F2F769Ba66Ca426C] = 5600;
        holders[0xc538403efBF213476021bC8B26b9d88b37dAc449] = 8748;
        holders[0x9c49534f51be6ea6072194830F008dEfbDE4ae5f] = 3940;
        holders[0x036d0A52bd1EDAcEf0396e685DD268F3C648b9fb] = 5135;
        holders[0x8c49da76dfB923835Da8a530a761A96fa2424290] = 8705;
        holders[0xAc4eB9209F5E682F498855Cd1F5e68496153a384] = 7983;
        holders[0xA1320666f23B6000479347D5330Ff80d411E52B4] = 7808;
        holders[0x99E8D688816f308BB06dfEd8833bCBb3ef54a401] = 4048;
        holders[0x8668e26c5284e51fd829F3F3acBF392AB8F1D82A] = 2013;
        holders[0x011211661e2c46D8ce8C64e38569fb10A636d2E5] = 5568;
        holders[0xEd2f208619DeBc33F223357d071D13153D0fCfAc] = 7327;
        holders[0xcBBe310e115A497017a1e49eE12d263A440F8FDc] = 3571;
        holders[0x5927f35a86644e822A7775964647F240655A0253] = 9655;
        holders[0xE3DC9751105fE6343f512B5ab0795ad5655935a2] = 8289;
        holders[0xc1A459640c444c78e76CAe1979Eb538A3dc37163] = 4863;
        holders[0x07F0E447ef67faA1404551297E1Ec574AC133a4A] = 3561;
        holders[0x3b2837A5ED5AAb2D3c1DDb33941Fb2edcc989Ef7] = 2540;
        holders[0x779fB29923A4c733eE23209Cc7F69711a676aA8E] = 2628;
        holders[0x04E4dAd683c609F5CbF44c22b7FfE250F1Da24A3] = 337;
        holders[0xaa0FB954B00F0119e3A44DeFFC01b7E803c63846] = 7173;
        holders[0xAc066f5887C467e51D4F27489F2986f1D92E0A62] = 7129;
        holders[0xCb9E3Ab37A31a31494c5c2F666a8FFB6Ad9AdC8E] = 7831;
        holders[0x852549b1F6c32B0Ca4A215569676Cea1bA889970] = 4275;
        holders[0x542b858b96E01f6BD0EFcF7D36a142C383dB3b6b] = 7058;
        holders[0x2f9178D7DB59D2AE61d8FC86FF41a024fC525737] = 3333;
        holders[0x71375a9A13c7F1C328531E1Ff2f48355C40730e9] = 8785;
        holders[0xf0771F5345aB5b97EE10ec58A42429a9b0252737] = 7764;
        holders[0x445b4cd1aFab9e54D3E679dD97bB8B080C0783b9] = 7716;
        holders[0x57beACb0893BC44FFEC586019506C8e2079b168a] = 6383;
        holders[0x7D947723Fb7AD62b831bCbBD9aED030311907738] = 8363;
        holders[0xb05f23E7585213f9dF9D1C838C7bbF4e7224Ff2c] = 4819;
        holders[0x0070731F480D4eCd01f448cB026e1f8129D70dc2] = 6203;
        holders[0xC43b8b16318F6b6347be6aAd1EC3359c405795f4] = 3052;
        holders[0x87e59268c89AE3b36c9173232D0b1F04946acd44] = 8205;
        holders[0x00d6cad0eb8fE405b4C27CA2071B0D0653B9c2fC] = 4101;
        holders[0x8aA70E70A0834aa543582a507c1761474820Ee6A] = 4462;
        holders[0x122A6D262c686AF02a22491F61679a0Cf7634aF4] = 7881;
        holders[0x642395cce165D899ba0caf2F821619947E059492] = 8979;
        holders[0x8eaB0Ea11881797531CA1A588779C4d981443F4E] = 933;
        holders[0x9C12Ea18c872a0bA348c8B8F48A2b8462de0FceC] = 9580;
        holders[0xffaa9A3838FD8719e5968e2Bdbf5E8937DCd0E02] = 2691;
        holders[0x80e51EedA9c41d05B54A18D53167a14D52e6760a] = 8335;
        holders[0xD4D94b1bC524414b30F8D0F933e956ea423Ec8f2] = 5862;
        holders[0x0bB0fe892528459f9AE92a0C91a560E6cb087CD2] = 6666;
        holders[0xa32e31d3a530034004a0b6Fc62B04E2e2E421F69] = 1434;
        holders[0x942b2f8D8ca3a4BE523873A3bbF11ca19df08c00] = 7989;
        holders[0xd52336e7f797e237CE29FA7bf6973890aaC72ec7] = 4011;
        holders[0x2A43618877c1185bf4Ed0b77597bA4033A4b3dcC] = 9254;
        holders[0x2a9C6270E8C4d874CE6327CFb85492dA4e531b20] = 7565;
        holders[0x0368d389DBfaDCA982E5458B32eebbeC99Ae5881] = 4324;
        holders[0x5C178FF9F3b553B17Ab44C923331273bCf5BfFB7] = 8626;
        holders[0x22e1018aa1B50Ff899569c446A30071Dae05C5aB] = 3276;
        holders[0x938b8c1359f870E989e235C127ddd5D2e6DD4f16] = 4271;
        holders[0x34f514b472eDB28ff9091Ed29A78DD385a28e1ab] = 1065;
        holders[0x8007D75752f14888F30B1466841Aaa409dC5EE05] = 5410;
        holders[0xf302DCAac125aD9F1723aAe26D3071e722fDffE4] = 8628;
        holders[0x1f2a5067659B2C06B069890C1853398A920e51f6] = 4921;
        holders[0x624299e99Aeb60eE7Ee90F8A7725e51B67bB2C4c] = 5799;
        holders[0x3EF76d4DfD339DFb2072e0E382742F0cd9685343] = 827;
        holders[0x7068422f7B8F43e33DFd06d5792B60F7CfA9C7Bd] = 1053;
        holders[0x4c277cFF00bc67508b30eCac72DE5c81f1A8BaF3] = 5625;
        holders[0xF4e8c39867Aa925f14959B82eca9176E21a8E43c] = 5484;
        holders[0xf5c7A4ed463DE86Ac3172aBCcb4e5d44885EEE23] = 5886;
        holders[0x8527e0a26D01c15EBaf6a5CC84199Ce606801a74] = 545;
        holders[0x20943CBfcDCe373254BF8B70C339A81d7218Ed10] = 992;
        holders[0x6212DC7DbbCa0E6129f136d0fb83c87562de74F0] = 5152;
        holders[0x7e820f21829d739d0606Be08215a2b7720244BE7] = 5528;
        holders[0x1d32a7bDf02D04C446B3B6AF5B726a9a2Aa33bc9] = 474;
        holders[0xDA511F4bd27731E84bf18B460F8Ba8764F16937e] = 9946;
        holders[0x6a2F7CED2004Ff644920a56b69D85481682AB558] = 8723;
        holders[0xc655f1c810C31208b13D3DD33379259f747566E4] = 6493;
        holders[0xb487B7E0655f514fCE6350271FB682b38C80ec1a] = 9744;
        holders[0xCC658b0205BD0dF55b8d20f81D5c615491B91082] = 8165;
        holders[0xb06346B9322518210cF35a42ccC23B8Ca1C5C0d0] = 437;
        holders[0x8e069327AcFF95B662DF6907F9729278193ef044] = 5095;
        holders[0xa2F2f0FA9Eb8fD64B6f97A8B6A6953ccc071D9DC] = 9902;
        holders[0x3e9eaEee05B4f16De766C553a790CB14d5eC5B62] = 8814;
        holders[0xF797be8b20d3B009fF86b5a40a3183e64C858c8f] = 4084;
        holders[0x84BDa0A69DEe9FD1D5C59Adb205803c995207CB9] = 788;
        holders[0x1905ea42846201593b1bcf0Aaf6b77B7f899b065] = 4183;
        holders[0xfc1806B2449284DB18529336afBE8DCa04f058D1] = 2894;
        holders[0xd0de00EFF606424cD3005247DF296a333DB87961] = 5973;
        holders[0x9aeCcb2722aC2eF0DA42760678EDDd881d3C2148] = 3797;
        holders[0x0C2cc8a62f389250A15E4c73Fa290bFCC8e1647B] = 3922;
        holders[0x11503900fd931c786C6e26A5AC1cbb3B9b2D2B05] = 5993;
        holders[0x22DBbc74D3AeDb7e8fbA368f49b548D1496CF0e3] = 6726;
        holders[0x068657EFDBc53dfadDA50cDd8B46279742Cc71F5] = 6134;
        holders[0x5c84317441FBe096Cf7688FDCb5e8d404bf90f0C] = 1161;
        holders[0xc3714aE59a0F38B17BFeE26a6861Ce2d493D5759] = 3232;
        holders[0x74214963C436b5Cfc4A5c59C657E2029E54b5620] = 9800;
        holders[0xFB782469989B6d1C5C9fBA4EAe3Ff68545Db6795] = 8627;
        holders[0xD562d7DfC6480120194e6008b29a68F1be6CdC1e] = 2327;
        holders[0x285E12C6c45D44Ca48bB868fdafa892aCa5764De] = 1979;
        holders[0x379944d0a37bBE18C94f5fADB68a2896f045Fa91] = 4725;
        holders[0xba546F9f4a84aDc833AFF49EAe2A1162cdb26713] = 9495;
        holders[0x860B70E1952684731f8f3CA108e02d0B8C42a467] = 3932;
        holders[0x85c6956B83855FeF96Bfe8c3D087319258A1e459] = 6786;
        holders[0xb6105090875060c76b573F7f8f4cDc4b0217bFFC] = 3064;
        holders[0xA8aAB40F52b177A16D9c0A3D9B523926Ab4657ba] = 7030;
        holders[0xe6faE74e5578b5e3468dE1C239c01fa1213e30d4] = 3544;
        holders[0x90617E87b59190CAa4e4ACBA6a1b0D52A314F5DE] = 6795;
        holders[0x05add7FFBeAA79667BdBC2d85ff8D46Da84aE127] = 795;
        holders[0x88B71015F8acE33cc0C3AB10E2332953109a24B9] = 1274;
        holders[0xe339672Fc8D8Fa0d82b7F31831cEAF337e8434b2] = 8761;
        holders[0x3469BbB6c024041B2A2D47573c891b415585CefB] = 3818;
        holders[0x1065A8326AdD1A1877fd60C72e3E98C6c988718f] = 1356;
        holders[0x890f739B54791b7C280A19edeA1207CeA2b8dCee] = 7532;
        holders[0x40904CaeD8010E35633E0e67F0Dc52E4D42c53d9] = 3843;
        holders[0xA2BD9AC1306B958C8ae715d384417829dc44Df5C] = 6042;
        holders[0x7b6960f7615cDef7A262D470a856B377C41433D0] = 5075;
        holders[0xE8aB8341Cf14aBf3A9580C163bc05194D0E224aB] = 9460;
        holders[0x9921eabAa6D7A29F271d62Db0399f36dd6f3555C] = 6883;
        holders[0x58d7bbde67bd9EFFd36b849799DFcEd03689f2cA] = 4040;
        holders[0xF22aCa5bE1c884EDBCdf1F16126311DAe3e4c22B] = 3671;
        holders[0x459de556a8330368e80a09FBa6d50e6967bd6127] = 8037;
        holders[0x1f91973e35609A39605209e15D828d41628db4BE] = 7934;
        holders[0x70e7D40f9f13653120208762a4020Bd0BEd6df0D] = 7367;
        holders[0xa29948A7C3B42994bC19a141D28717C785D46364] = 3505;
        holders[0x6Ef2abd2a07afa8326fF276831A46102Ab2FaE42] = 6744;
        holders[0x15B35d9702241D88b8643f2BC5f3902B7c2ec0Ae] = 342;
        holders[0x4bcAFC832b94537d01AdCFEC81b95Bf36c3b6923] = 3054;
        holders[0x2fB5E528B2d8b03268eC4463A90d241bd36A5Cc7] = 437;
        holders[0xC8745509ff91bF0aB2c3044dB3290014c319337F] = 6155;
        holders[0x727D079591A74aCa0fb75F4cFd8c6eAabB757029] = 421;
        holders[0x2b127Dab7233eCd0a47aA7485edb417bC779B56D] = 2910;
        holders[0x23390dfE4093897966C724083D7766CFDB4382CF] = 9521;
        holders[0xcFE6A54e5763d942E652aEaB24AaF9B6c828A729] = 1578;
        holders[0x885D8BB5f1f88A02d7F0b7D730b3D9ef010A3CeA] = 1501;
        holders[0x3dC6650D3910Edb0164CBAf6A257b65BF1cD2da5] = 4423;
        holders[0x7f8D91F91AC6ff5020F95Df1EE1032b2AfAa9F70] = 926;
        holders[0x2AD2Ea1f414FC5DCbe470053f418Ca1655a74B04] = 6964;
        holders[0x172141e01fC6bD59dF5de59A9722c86a73425670] = 6227;
        holders[0xcD3B4f1Eb3D1dc7F4D16A82921Cc90fe7AC217Db] = 8543;
        holders[0x35831155CF9eE42b5E08e3897A3Ed0E091048b07] = 6640;
        holders[0x52ff8c66C0BFEA58819A6a7EAea1A0b591Be0741] = 9694;
        holders[0x46b69f696dc676FAE578eC6d71c749e8ec95F16B] = 8044;
        holders[0x7c8cfAF7a2b039eeB6161A0B4aabBbF4cc4d3633] = 7645;
        holders[0x8Cb7E0c5368A540d1F9297B36CF6D514eB9C73Ac] = 8964;
        holders[0x166d7Ebe172FA67eEA0ABB7bf2Bd72A64384C6F0] = 2128;
        holders[0x3c02C47bf1aa95841731AF18bb22B05B1c9AcdBA] = 8146;
        holders[0x3a991e7e8f18770b3779ED4060a6f035b93E81c1] = 7851;
        holders[0xE6E5c253E11C66a2D9197f73b263Ebf43bd8B65f] = 6205;
        holders[0xBB1b9D92eE7698d6c7fED5736D986A067a0151ED] = 3359;
        holders[0x73100d549cCEF0fE9742f7b7abA427C642CC7F2d] = 1570;
        holders[0x80B9B2418782498044232276762f35fDF45e68a5] = 8100;
        holders[0x6Ad4fC57fB0d158e770f78beF34d4a8b6A84AF56] = 3278;
        holders[0x1181B2112D06a5Ff52A202e5222c83540348CC46] = 2104;
        holders[0x428C42fC0DF7Dc14fEF3161573A6241D2AC47192] = 9649;
        holders[0x71e3739b24a8Cb6d092b64D95eF589a066a08143] = 575;
        holders[0x34cC54f3C65E6e6CfD1f05E2AD0540624A5EfF24] = 9771;
        holders[0x09971e2c4B1f5C1CCfd41d34Ca7954d88bB4C2ef] = 7387;
        holders[0x1ED39654Dc705a5A6D1aD6D7ac536d9f9B6e6319] = 4798;
        holders[0xfdBfAD40A8D26b187BCE04cAc66cB8a166ad4e16] = 8179;
        holders[0x4Ea9292B67f42C0E73a3e1f89C39ceEe69088F08] = 924;
        holders[0xd482F9207281aB5bD9482B550424501D3919e064] = 3962;
        holders[0xa60fdb6427cCd2822F70A423551F770d320f7Eb0] = 6749;
        holders[0x3d929F9d3D1a0E90ee465c2f6e9F862ad8955f08] = 7371;
        holders[0x818806dd8a8E13A4c89c2F49634e8E22cAAC83cF] = 4937;
        holders[0x8f8071CdA2594d8891E440fd05B911C854094188] = 1352;
        holders[0x8C3f5e37167A28B85d6A695b1195598b1BDa0D43] = 6828;
        holders[0xa1BcB5B72FD3a34bA80ce0c3006509801Ab5BC7a] = 4218;
        holders[0xc5Ff1284b5A56a40a69292FBC9393Ed3098ABff7] = 9223;
        holders[0x3E1F96032115De870bE2E4DC65599be0B59305E8] = 5518;
        holders[0x3E618F79F9C523C191d40472fe75e27b66b1C557] = 8144;
        holders[0xDE8F5A38f81BBc7Ad4bd8A4fdA1AfDC8CcD22e79] = 2056;
        holders[0x8B310f745b1e1A6981EBbf8D7bBC2e0E114F9DE0] = 2314;
        holders[0x6eA1c834b8e30B272b16F3304325bb2763A599b5] = 4526;
        holders[0xA9881EE90390984a2476EF62e149310651c44D99] = 8068;
        holders[0xA46F34DAC42D6911C766FF2A7639BC48eB8Eeecb] = 8498;
        holders[0x808aF747DE82c52aeF5bda8f71825BCD1aC3a776] = 6875;
        holders[0xFB1910fcd3BcC640afa274FB8a104dd262a54A72] = 8936;
        holders[0x043872eee2A04A35FDef23C0c9658e08AB7b6441] = 4478;
        holders[0x7Ad75D4FF0c63b7a7361E3aD6100101036Cda55C] = 4057;
        holders[0xB6E028A03A0ceE13c481bA4842a885b1EEea20fD] = 6128;
        holders[0x816863D1aEC46346a69a50C60dbA4Ba748852959] = 8492;
        holders[0xbE74B4643943eF3F99118636EE35Bff9BF599386] = 9490;
        holders[0xF6b2F178EEfE09779B9e7a6692C80bD993e7862e] = 3653;
        holders[0x6F8098F89508f2F78411A3c358E36573B9CB9443] = 8174;
        holders[0x816C8d6a41915Ac50d78b881C93f40714Aeae1DE] = 7344;
        holders[0x41e27D5bADd864c1183208f97BA994a1455D3d1C] = 8281;
        holders[0x6567647EBDb4C4C1a782F86584c0e065eE061e42] = 4273;
        holders[0x250F10EC0212f5374A3201a0038873E41Ab18fC1] = 7659;
        holders[0x570a3FF545Daea13FC0A478aAf684976683bA4B9] = 5793;
        holders[0x22b2cb9a6F98Dcbbba031eB07F3dd97eC4167D39] = 3569;
        holders[0x768eE86af8433fa8f90B365e69bDca87be656487] = 1654;
        holders[0x2979e6Cc676a3e5cF05c105ED623246791AaA800] = 2011;
        holders[0xa48261B7278bc03d0d1B5F048Bb0e354D200C127] = 3436;
        holders[0x64E5AA4eF02b4c2f05cc2bF31b0D45f8aBB646dc] = 4833;
        holders[0x82710C1971B995ECc4016C8Dd1c6C98eA4410b4f] = 7760;
        holders[0xB9e6251dE1899dD4451B347D961aD0BC9E627F24] = 7295;
        holders[0xeFDcbF40d383C479ae807a4A405C5aD45Ab4Ce13] = 9372;
        holders[0x85FFe24399c0B8cd23eC637735e27b7e79ad9275] = 9841;
        holders[0xBEf5Ef2B375D81dB84F204da58A6374FbF99F62F] = 403;
        holders[0x76c81624B88cfFDf508F8fB466E67e6695666666] = 359;
        holders[0x039258804fda50a2cb6b93843386EE3736BC7472] = 865;
        holders[0x7252d41d8FFEDf1F4b234733018C8DfE62e8a3D8] = 3673;
        holders[0xB2D42C41d82F81ed73C4a39A678C4B0cDfF49bb8] = 7721;
        holders[0xf2FA06040F927Bdd54bD6C195EcfA977232A613e] = 5982;
        holders[0xf53D5ab3bD5e0B3D1e94D8dDA96418351aE9B4fA] = 4809;
        holders[0x1C9F85FdC7Ee6A4D03a10b401e75AAf326A12646] = 8706;
        holders[0x1f81F91FD1C079aD5369f6FDde07a5358C1738E5] = 5215;
        holders[0x3d02586E4709113f1518e028C539abf5010280CB] = 3580;
        holders[0xC234728C9EF8B120683439c9C7eEe3D919d204c5] = 7791;
        holders[0x1212d9243F72E660BD23251A2196d8A2Fe2503cc] = 8969;
        holders[0x0EAd7076993BF81447b723b1F62D4447c33E84a6] = 8904;
        holders[0xB9d955fbFFeBb6bF772091a1fFa1F83b7AEc57dE] = 9903;
        holders[0x8D701eBFA14D826a3042CbAa8Fa96E54679A6e02] = 8350;
        holders[0xb538af2f6AfE5Cbe9C83932B41339B937fcdC330] = 6588;
        holders[0xc584bAeCf23C7Fb1e7187421517bb3Cdf81557f6] = 2782;
        holders[0x0563BC8cd7002cC8E03A287698797d013e007A31] = 3413;
        holders[0xA827e7D8b33F54231bBcdb6cdA9BB3A7679Edc92] = 9138;
        holders[0x5Bc2A0F35ee957Ca76BC269a93AD9d2900d15850] = 9446;
        holders[0xE518FFe7c9FFbC55CA90c62C662439fBB7e6c62f] = 7279;
        holders[0x32fCD5EC8cEBE01FF0CE8a4390FBdF15CAaB2410] = 414;
        holders[0x657acf7C77976e1AE2186C4c7064f96b90A3DF1d] = 9164;
        holders[0x5D4801d9351C7629cDC9704AD958F051cd3A1Eb5] = 7942;
        holders[0xfCd1798ccECC839060fC001507A0583a05200888] = 4557;
        holders[0x30f0B900962f859D791B40791Ece4CC0443E1B2D] = 2724;
        holders[0x7Ef06Cae1176a971fF8A0bBd9EF97124817e295D] = 6330;
        holders[0x5f282c44D08C39f539fb2904fA9CC6f50E1e8AF7] = 2457;
        holders[0xe6935614e1029Cb7c95F69c87c7808F72D6B6D5A] = 2325;
        holders[0x7341C61AdceF8d27836d8c54A5f9FE8026a4643A] = 647;
        holders[0xe5c86b09045FF0e2D95B9a7dbbA03AD8f03457c7] = 3459;
        holders[0x53A8553ccDcC0f039af24A9Bd93098126d42691A] = 8139;
        holders[0x102E8c834D9CAF0F98717445A58a07ADBB5560A6] = 8542;
        holders[0x96A61921dd5462b3faCb1D98D4098991957140D2] = 9436;
        holders[0x4a40b28D40b8e408162Fa4919b46a0F426C16193] = 9195;
        holders[0xf53FBB8C0C1f304C67628FB10dC0730598Eaa20e] = 1261;
        holders[0x2625e9F93b3399E4D398fb80d5E1413fc141b3EA] = 3068;
        holders[0x1580240A872Fb563958eA68383722a7B8B41D6D0] = 7286;
        holders[0x7BCb8597564156eD7c70B3BB00aE8D529bf22974] = 9969;
        holders[0x30A37854A28E3A49e7E6d746920A689c05Ac3127] = 5139;
        holders[0x5cC1E15aa434cF7f18E589d9d998045F3ADEd3BC] = 9780;
        holders[0x197B1ECbd94b57864aBC4AdBE9A2a592B24D8f70] = 5152;
        holders[0x9d065f8252aB589a1c7b3d90FB4a6FA577E90142] = 7833;
        holders[0x5959D9593D0B9Ae637491af2f35A2ea7b75DB170] = 4729;
        holders[0x978eE21864cAb5aBbfb6106af1231C4d19f2C0c6] = 7191;
        holders[0xeC4C835eD98EF03fB25841Ab2dAB1ca59c50Eb36] = 6167;
        holders[0x306f1488C619C7d20beBa681D1fde040d2228D90] = 2078;
        holders[0xf56afcF80B7cDb817c741f69b0663b643DC6cBdf] = 3784;
        holders[0x5cb3a6f508E9637AF0BD8c5b0fc1d226819dd930] = 2667;
        holders[0xaD369c1E06b27e657775Ed89A6Ba82485017cd9C] = 2478;
        holders[0x02aE1C8BFD8F2E7d0452Dd2fcDbBD711fF92d321] = 1295;
        holders[0xFf8ED57c04480C61cfA6d7a0718b47a410Ef8eC4] = 3344;
        holders[0x17BC37B81A9b4AaA4550F46A9cbA1209edb77999] = 6790;
        holders[0xC8fB328352a053C59c212167fdbec571075A5a35] = 4808;
        holders[0xecB78BCcDe27e47A5fFBA97FCB94a85c68a8a0ef] = 3476;
        holders[0xC3a2de698fc7e989BDb6DB3CFB891e5d7d399c37] = 4611;
        holders[0x371B3AcB5Ae446A778DdfD196d38301593E85dAB] = 1388;
        holders[0xaD1Bc826dec3f8668240d6d459Ce8514E7404A98] = 9360;
        holders[0x630C28A746BAF7b75DD79F11aEBD6840f93c51b7] = 9233;
        holders[0xe7616DB67C2c14380b217Adc82707aa3E4dF4861] = 7105;
        holders[0x186119827E353DFa7A47C50511EABb02E4A09edC] = 3627;
        holders[0x80a9a79294751815BB4fD155FF22f3A8d02A768b] = 4103;
        holders[0xC6BAF7c4d912D6FAF06Dad2c0376fE59A541Fb07] = 764;
        holders[0x8679db4507e5bd5644b51063e70f546edD4557E2] = 5151;
        holders[0x999fda7D58fE62c4b4590F5e1e76E1068188Cae9] = 4918;
        holders[0x0C88eCf9B651D04D3bF4286164389619F42ba079] = 8483;
        holders[0x90efeD8eaCEd5893646B936180E6865E01eB9932] = 4068;
        holders[0x8DCbFC50d67a728872A36626620592d34d9cE69a] = 8160;
        holders[0x422A7b4E5f85302E24F4E76d370B9415707AB941] = 6690;
        holders[0xB4B4F0c4a4613Bc7e9848e0E4f476e339f038Be6] = 8001;
        holders[0x281e23B297D26470FA7082b23e168b364F9b3573] = 9089;
        holders[0xC084C8551b1dFb9c50400f6D80d1FcDd4c9c4d2A] = 7100;
        holders[0xbCade6F9Ec626893626B9b4d3095cd6980a11AD1] = 1005;
        holders[0x7052e4ac0465Bd35477Fd8cF254d35A657F79Dc2] = 4126;
        holders[0xbb663CBC73e02C48f577A4fbfA5aC061A24cdFB9] = 8781;
        holders[0x69B27788940c12136eE7F428C2A8A11dE538EB15] = 1598;
        holders[0xaE22B8ecFCE04daEAb22a2DfDDb82C5aD59a160a] = 1134;
        holders[0xAeBEF75b2AB050160cbD7c8422177B9B83E2Ec82] = 9856;
        holders[0x0750b0a728C7E42fb97e134D02a3B3C69Acc29f4] = 8545;
        holders[0xfACec8720C3411458a0Ac8B329c729F23E261521] = 585;
        holders[0x38C089c4495C594311920468a760C954222301b2] = 3523;
        holders[0x0046C69e8C9236173527122bdeEA44B7e00363c5] = 9379;
        holders[0xb658952A1a6c830c1aaD7aBC701B6ba92c12dF75] = 8576;
        holders[0x70d84aDf0Fc5a6764D495D95d57714Ca26c095bb] = 6993;
        holders[0xC8E5Ac6C4A17Bc97eFEee3801ad390858c431d5f] = 7168;
        holders[0xb736d8642e91F837BE49dCB41eCFDE951d2E6051] = 2001;
        holders[0x827aaFa54d7fAb00fcdB6e2E5818C2CFcBb70203] = 6317;
        holders[0x4C92EDdE0b9E1813C4E633B9E01254783f11BdEe] = 4582;
        holders[0x57a34708966b69af001a98e050c893035413d074] = 5591;
        holders[0x622B9bEa066b72435c65109D4Fa28A8bdbfdbc6b] = 9410;
        holders[0xcB81A76F877fC58e65658051EF415cdAE597E279] = 9318;
        holders[0xf0f643439Bc41faD453A830eC1ED86a73091e6D6] = 5707;
        holders[0xd6cf0dbF20D8f5194E28B169dbA3D1ef3EC58476] = 6714;
        holders[0x39dFF2433F5f23ba825226dAEc156fF2BeE33CB8] = 8191;
        holders[0xFb5A1C2ef92Ad8eA77c74DD7519EDeb6850c880F] = 3683;
        holders[0xe8f3d449f26cE8D5d1b7A5E23Ef0D6EFDCc89C27] = 5764;
        holders[0x04333b1FB8485Ae9a5A2fafC82A6da3dD764dda0] = 6466;
        holders[0x073cb26308862B4Aea1531dCB872215721b5B04f] = 2143;
        holders[0x093C2A23BD1f77653cf8a924322642493337B683] = 9029;
        holders[0x0Aed1161B0F48a6d964651677227696076e275BB] = 8353;
        holders[0x0f96D7177989E85cAfD73A4dFBC58daF2B96f147] = 1032;
        holders[0x0fBD449ded3e6cD03175568a9D5ef62534BB8663] = 9660;
        holders[0x11D73D83F0467193580CF3832A24Fe5241d25014] = 2017;
        holders[0x12A0c62709362407EA6505d523c426cB769eaaF9] = 7038;
        holders[0x132CCC1C3a275Dd9e3585a27FB07e928b0077a6B] = 3418;
        holders[0x1444c8DD68C29ffb9e1302ed839983cbA67F891b] = 6722;
        holders[0x18561c02515A88b8AA9c2F57eceb19271799C341] = 7945;
        holders[0x19303680E4717E847F8Bf48A36A86Ce403dB7Aff] = 4316;
        holders[0x1b0DF20FE719B2AAdB9b0531EAe2f97863010C18] = 6720;
        holders[0x1b1e6964763779D490d81ed6076926f2Ac2A87A3] = 9767;
        holders[0x1c9FE469F0b99001f0b40848420224B1B043E91d] = 7072;
        holders[0x1Dc170482777788E282eC2ef821caca3093e4EAb] = 2837;
        holders[0x21a69D5eD8dA849C7bC8F652c61a7cAF3DDAC068] = 3922;
        holders[0x21C0003Cc30F2976a7C5a255C201Dc7a21A98B8f] = 1201;
        holders[0x229c209d9b9BAC97a528C7F6293e6F640d342B8f] = 3635;
        holders[0x25653EbD6b281aF2647151c9895Cb4eA833FEaA0] = 4715;
        holders[0x27cE6C45638EFE71352Ff280218aaDF864490f28] = 6119;
        holders[0x27FDddDFD096386a6DAa3b4d082FD6F3A152Cd03] = 2401;
        holders[0x2bB6e6c1d1A1a6D150150fEC91ec786a228F53fE] = 2008;
        holders[0x2C278844dDaFfB4791E2e8c37E6e85C6b157e315] = 1706;
        holders[0x2D98fCAAB854DA2C6dC995d1620427d26e372A8b] = 2436;
        holders[0x2E276a4A7dd911523B225AF54602F79A9d99Fe40] = 9545;
        holders[0x33d4c99F0FB56718309844fd0E510f6bC37f239C] = 7330;
        holders[0x35Fe6F2f1C10077bb3B0aa633313eBA6cDfFa486] = 5185;
        holders[0x36ac7c6c942Aac156F898C58AaAa4C6f7b8C4F52] = 1189;
        holders[0x38d69F29448a3dBFC5e57E6414a04e97D6fDd608] = 8610;
        holders[0x3b174591c1D51c0706d5CCd44801989844058756] = 778;
        holders[0x3de1e708d1A78df2C7E0537efE61c1b96F628AAd] = 3846;
        holders[0x404dda0E1d9b26206b038bbF98a30ae327Ec9B0d] = 3330;
        holders[0x4240B670E7fbd4A9E3bDdB5844f3242943671687] = 1625;
        holders[0x446A323A78c63098903D052a47112506a4243eff] = 8288;
        holders[0x45f88EA6D42C0E5E3BdAc54582fD4ffac87949d9] = 7506;
        holders[0x49Bb195394a3fE50B6Ab93553C3906C69e503aA5] = 5241;
        holders[0x4B3cEa68208D6720022FB5D5e78bEb4beaf71C45] = 8467;
        holders[0x4cb54be4a85DFd494285e941F2A7c9212a47F683] = 8293;
        holders[0x4CEAA9Df24Dcd158841D163Ca4D65c50DEc8d301] = 5576;
        holders[0x4D00AF255c2886dA69287c6FADf059AC874E1933] = 3663;
        holders[0x4eb1f4DEeD6488b2A1776349B98671263422B1E3] = 5782;
        holders[0x50372e0eD4261804c39f3D0dD8b9b45fB40D5C70] = 3329;
        holders[0x555f18Eae8F18e62A367ee258cB5467e83d41A41] = 1474;
        holders[0x55f930e1b29f4D998ceC99c80E73847729167fe3] = 3771;
        holders[0x5a0687a349B1EDbB27d3Ea9AF9DcdDeD972fc5D8] = 6277;
        holders[0x5A5087B2F39cFBec58295E81b88B4ED7288f92Fe] = 2478;
        holders[0x5C5791bbbbA61B2611aCd8d1Afe8901cCf816e85] = 8473;
        holders[0x5C77Dc7d87BbC2fE97fE707Dedb45bC46f2dEDeF] = 5697;
        holders[0x5F0C9b503922Cdf4D0be4e4465eE598DdB3902AC] = 6395;
        holders[0x5Ff239a8c645F63a4D8A1d4DB1c98F8D35317582] = 7617;
        holders[0x619d3FA3bD7CF497d9899Ccd4d7b5663Ff318e52] = 3659;
        holders[0x62c4ED9EcF3bad929ec17C9315678FD920f7E6Da] = 1187;
        holders[0x645CEA0D1FFCfA3CB2DF0d019331c68364435140] = 9560;
        holders[0x65a8Da09F53f318972aC983bbba574f38E337647] = 9522;
        holders[0x664a61406BC472c33e8860Fa3C5f0c05A7658746] = 8880;
        holders[0x7056C48dD757E827A3D0dEdBE1C1fc7C007696e4] = 9824;
        holders[0x720B60EA529f2f4bf36B3362C9CFc902934840C4] = 9874;
        holders[0x756e1914e9349b1E3820289B7588042D67853729] = 1210;
        holders[0x765dc78D0eF3baC4BC972bB0Ca299adC407C0f4c] = 6576;
        holders[0x7848C594F674FE5351efA13B96AEd7A6e4CF3059] = 5750;
        holders[0x81bc5Cf5622c9F5A4Cdc3FC795379fdB4D61A369] = 6871;
        holders[0x8376dD9823425aE7AD238aD4771904a3Fce39DdD] = 737;
        holders[0x852B18f980aC61484380647Ad8c39201516FF70e] = 2894;
        holders[0x857F4842c4A65E4EF52615DefD3AcA97246A480F] = 2288;
        holders[0x86412aF4dFC57A29D6983761eAB2d68Aee3DDE9e] = 5371;
        holders[0x881829A7F7ee7D8d833A5B06F1B27b2d2B2148ac] = 8540;
        holders[0x89Aba875B919F8aE49F3051fBacBbE3694fdfeAB] = 6879;
        holders[0x8a3AA24274E445ABe1F1De688c595fb8D2943767] = 3759;
        holders[0x8a86f8b05291083fD4Cd5A53ea42cF71Fb907740] = 6154;
        holders[0x8A8A3d94b8888025150A962eA6662Ff8DCc66551] = 3920;
        holders[0x8B94F61e39FC1Aa8992156d6e9199D00C6c04cDf] = 9742;
        holders[0x8ce712cB5b0C431CC658fC75a0013B10c0684DAD] = 9754;
        holders[0x9492c313f500319e87937F1dA86b7938757627AD] = 5190;
        holders[0x978fD59367c02Bdc3b0ac840193EA052442Ab4A6] = 8853;
        holders[0x99b16Ce545cb4Cdb84a73e605C9Cb320818bed5b] = 8261;
        holders[0x9D932ce3DBd1B345Ac8924ED125F61589D7a6068] = 3773;
        holders[0xa08e8b0E76a55e8AC12edA5E79119069529aB8C8] = 6826;
        holders[0xa209EC832ef0076192A79FA48320b415eb91c732] = 8101;
        holders[0xA2Ab522984D1F56B9d886a1540F248C9C0b4936a] = 3373;
        holders[0xA42FE8bD2360c81585C11C4c8e762e49d40Cc901] = 7228;
        holders[0xA533CFcB30C9909DA960426e169424144eDF743C] = 8662;
        holders[0xa70130AB89C03736497B89B2F9067b0fB889DB25] = 3888;
        holders[0xa8C772b629485Ea8Ff2B042678d24b32498D111E] = 8707;
        holders[0xaB6AA68cc213dB0cC130067a74a7962812E55f60] = 1392;
        holders[0xac3959D996800e89a8247ed6003D0690f8b1c429] = 3344;
        holders[0xaDA37f634E9261DFd044c9Be8d8da2890A49C5Ce] = 6487;
        holders[0xADb89545c0543639f233A1289db87491739F987A] = 9200;
        holders[0xb12fF79668178fB36AAB162DF85Db883459f4E7A] = 6161;
        holders[0xB752dA305e7205e50901f26ecC97E1fFded3c641] = 8032;
        holders[0xB81C9E297A730334658C6B1E5F7e2598E42bB774] = 317;
        holders[0xB98a05fa7B62b1BCE7365e98Fa617A7743A30C43] = 6450;
        holders[0xbc83bFCfe0c8DFf2757Dfc7C36047a0502A7Eca4] = 6733;
        holders[0xBeCCA159e34B3D3770276ec533f50A58314b33F2] = 3901;
        holders[0xc07bb59C79b2FEc204651B3AdC680238E1999961] = 6202;
        holders[0xC335d08C209Ad4fE0CEEbCb3b0467B794D1A995A] = 3933;
        holders[0xC496Fd8EfcA0f8607161834897B8F1024175Fdcd] = 8149;
        holders[0xC73A10c47113D93DbF2132bc324235070209cA09] = 2042;
        holders[0xC746edA8414d28c4D6133f8de6fD6d3FC249aDaA] = 376;
        holders[0xC7f31F01c1C12EfE18FC0BF3DE3A83C2cBF9372C] = 5693;
        holders[0xc8Bb181336225933C2A3d538f2d086D28C09BbEA] = 8210;
        holders[0xc9C288CcBCa2c9DE6365EaCD5a1c0c25517a969e] = 7718;
        holders[0xccEd6b8A197EB40033c2dbB6fB91a41e6ba908D9] = 885;
        holders[0xce094D50029CE968C5D4EceF81EC9962Fb33F9F7] = 6447;
        holders[0xD0bB4Cd2B8425364e7c5C228Cb2E9A25Ed9cd137] = 3220;
        holders[0xD1373671Daad4A0fb11c0fBd760b3Dc79C0557FA] = 6735;
        holders[0xd366a0aDce195a11289054ece6C5E303755BA9eb] = 2042;
        holders[0xD64a1321EA6a0d9D6813D1BbDE41FeaA834c54fa] = 3863;
        holders[0xD78eab0dfc7684AeEa872C1D8792D733bB8C2CDD] = 2852;
        holders[0xD7e792ddA8C77153Ee90bbB9f4AAa11e17c8C6E0] = 5774;
        holders[0xd8Ce2FbB542947A4B020D8aa61E4f41F518c94b4] = 1265;
        holders[0xdc1ae5aB28eAa12548864249bBfF46B1f23A54Cd] = 9287;
        holders[0xdff11b84484A4801A3aD1F54277659Be60F721a8] = 2063;
        holders[0xE29E5a03F217eDde1057aC2203eD6622db029CC2] = 834;
        holders[0xE3366daEcdD8b047a297ABab547eb1fa327949fA] = 839;
        holders[0xe3B5cD3489a999da5905A2a0d037d6f7Ef887F8d] = 5614;
        holders[0xE4ed80e740AE13EC70cb39E58c91c3e0344e411b] = 4118;
        holders[0xE652e6691394F29C19acCE3b76b5ac29dc9e926C] = 7354;
        holders[0xE9bdE075Ff8688dF7E100eb8faFd3e7371c72b2F] = 6343;
        holders[0xeb752cACE3211A31dFA84d9891662211E5b66d25] = 3826;
        holders[0xF15dFB01cD110101B093fd0163Bc03342c7382B1] = 6189;
        holders[0xF34E41b29289a4ce73Dc3D07e8B37cAe71c840D8] = 5399;
        holders[0xf39a9C2CCeF49038054126384Dd98DC60f5b9117] = 527;
        holders[0xf444193492201fCcDA4d7d651ef5deA2d06b9437] = 1534;
        holders[0xF4b222cCcFB43987eF902b63cC1DB57E305b2D19] = 769;
        holders[0xf618eA57929E5f991A5c77615700f92a51145C7E] = 5309;
        holders[0xf732E1a158aD56f41E90f8fA51f2D6bBD684564A] = 6922;
        holders[0xf8376bdd53caf1eb3291296ce53847a07406A2D3] = 7639;
        holders[0xF9215965e1C886B7008f84E9b941225Abf574434] = 6679;
        holders[0xfb98170E7649fDdcAE6809C875FD0cFC57A84b52] = 5348;
        holders[0xFe6ff00dE1dd396616237F7683cAD45f7b15F853] = 3188;
        holders[0x494E7C0895776f3E1d24678BE8E0A808Fc5Fd2c5] = 7085;
        holders[0x0BF5420Aa299021cc682a005D1b0C0109A8b3f81] = 1758;
        holders[0xe9eDE81a705f16B949475f00a075c11cF9a7AEd3] = 6377;
        holders[0x265F86EAd5a9E25E0CE4AC909aF62b91cb7fa463] = 6164;
        holders[0x4CD887D08A62A2e8156589014B147840fE8bE757] = 9785;
        holders[0x7c46AbC2d2F27A13AD84db6d4E4BDCF09A456E88] = 7935;
        holders[0x5525b2292c7A3aAf42eF73d0e22Ca1DEBd154887] = 7223;
    }

    function mintNft(address receiver, uint256 issue) internal returns (uint256) {

        uint256 amountOfNFTS = _tokenIds.current();

        require(amountOfNFTS < _mintingLimit, "This NFT has reached it's minting limit. No more can be minted.");
        
        _tokenIds.increment();

        uint256 newNftTokenId = _tokenIds.current();
        _mint(receiver, newNftTokenId);

        string memory newTokenURI = concatenate(_nftTokenURI, Strings.toString(issue));

        _setTokenURI(newNftTokenId, newTokenURI);

        issues[issue] = true;

        return newNftTokenId;
    }

    function getNftIssueNumberClaim() public view returns (uint256) {

        return holders[msg.sender];
    }

    function checkNftIssueNumberExists(uint256 issue) private view returns (bool) {

        return issues[issue];
    }

    //claim nft
    function claim_nft() public payable {

        uint256 issue = getNftIssueNumberClaim();
        bool issue_exists = checkNftIssueNumberExists(issue);

        require(issue > 0, "You do not qualify to claim this NFT");
        require(issue_exists == false, "You have already claimed");
        
        //mint NFT
        mintNft(msg.sender, issue);
    }

    //gift nft
    function gift_nft(address to, uint256 issue) public payable onlyOwner {

        bool issue_exists = checkNftIssueNumberExists(issue);

        require(issue_exists == false, "Issue exists try another issue");

        //mint NFT
        mintNft(to, issue);
    }

    //buy nft
    function buy_nft(uint256[] memory data) public payable {

        require(data[0] == _issuance, "Invalid purchase");

        uint256 amountOfNFTS = _tokenIds.current();

        //check if raffle has ended
        require(amountOfNFTS < _mintingLimit, "This NFT has reached it's minting limit. No more can be minted.");

        uint256 nftOwned = isNFTOwned();

        //check if NFT is already owned
        require(nftOwned == 0, "NFT is already owned");

        //check if funds are available
        uint256 balance = address(msg.sender).balance;
        require(balance >= _mintFee, "Not enough MATIC to buy NFT");

        _marketingWallet.transfer(_mintFee);

        //mint NFT to buyer
        mintNft(msg.sender, data[1]);
    }

    //get nft token uri
    function getNftTokenUri() public view returns (string memory nftTokenURI) {

        nftTokenURI = _nftTokenURI;
    }

    //get minting limit
    function getMintingLimit() public view returns (uint256 mintingLimit) {

        mintingLimit = _mintingLimit;
    }

    //get minting count
    function getMintingCount() public view returns (uint256 mintingCount) {

        mintingCount = _tokenIds.current();
    }

    //get minting remaining
    function getMintingRemaining() public view returns (uint256 mintingRemaining) {

        mintingRemaining = _mintingLimit - _tokenIds.current();
    }

    //check if owned
    function isNFTOwned() public view returns (uint256 nftOwned) {

        uint256 nft_balance = ERC721(address(this)).balanceOf(msg.sender);

        if(nft_balance > 0) {
            nftOwned = 1;
        } else {
            nftOwned = 0;
        }
    }

    //set NFT mint fee
    function setMintFee(uint256 mintFee) public onlyOwner {

        _mintFee = mintFee;
    }

    //set NFT token uri
    function setNftTokenUri(string memory nftTokenUri) public onlyOwner {

        _nftTokenURI = nftTokenUri;
    }

    //set NFT claim issue in case of double issue
    function setNftTokenIssue(uint256 tokenId, uint256 oldIssue, uint256 issue, bool resetOldIssue) public onlyOwner {

        string memory newTokenURI = concatenate(_nftTokenURI, Strings.toString(issue));

        _setTokenURI(tokenId, newTokenURI);

        if(resetOldIssue) {
            issues[oldIssue] = false;
        }

        issues[issue] = true;
    }

    //set issuance
    function setIssuance(uint256 issuance) public onlyOwner {

        _issuance = issuance;
    }

    function concatenate(string memory a,string memory b) private pure returns (string memory) {

        return string(abi.encodePacked(a,' ',b));
    } 
}