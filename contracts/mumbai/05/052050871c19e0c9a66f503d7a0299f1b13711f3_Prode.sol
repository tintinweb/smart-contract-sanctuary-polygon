/**
 *Submitted for verification at polygonscan.com on 2022-11-14
*/

pragma solidity ^0.8.12;

// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.
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

library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
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
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
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
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
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
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
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
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
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
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
    }
}

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

// SPDX-License-Identifier: UNLICENSED
contract Prode { 

    event Received(address, uint);
    event ScoreUpdated(address player, uint256 score, uint256 phase);
    
    constructor() {
        owner = msg.sender;
        uint256[] memory phase1Matches = new uint256[](48);
        uint256[] memory phase2Matches = new uint256[](8);
        uint256[] memory phase3Matches = new uint256[](4);
        for (uint256 i=1; i<=48; i++) {
            phase1Matches[i-1] = i;
            matchToPhaseId[i] = 1;
        }
        phaseToMatchIds[1] = phase1Matches;
        for (uint256 i=49; i<=56; i++) {
            phase2Matches[i-49] = i;
            matchToPhaseId[i] = 2;
        }
        phaseToMatchIds[2] = phase2Matches;
        for (uint256 i=57; i <=60; i++) {
            phase3Matches[i-57] = i;
            matchToPhaseId[i] = 3;
        }
        phaseToMatchIds[3] = phase3Matches;
        phaseToMatchIds[4] = [61,62];
        matchToPhaseId[61] = 4;
        matchToPhaseId[62] = 4;
        phaseToMatchIds[5] = [63];
        matchToPhaseId[63] = 5;
        phaseToMatchIds[6] = [64];
        matchToPhaseId[64] = 6;

        EnumerableMap.set(uploadableMatchIds, 1, 1668960000);
        EnumerableMap.set(uploadableMatchIds, 2, 1669046400);
        EnumerableMap.set(uploadableMatchIds, 3, 1669035600);
        EnumerableMap.set(uploadableMatchIds, 4, 1669057200);
        EnumerableMap.set(uploadableMatchIds, 5, 1669143600);
        EnumerableMap.set(uploadableMatchIds, 6, 1669122000);
        EnumerableMap.set(uploadableMatchIds, 7, 1669132800);
        EnumerableMap.set(uploadableMatchIds, 8, 1669111200);
        EnumerableMap.set(uploadableMatchIds, 9, 1669230000);
        EnumerableMap.set(uploadableMatchIds, 10, 1669219200);
        EnumerableMap.set(uploadableMatchIds, 11, 1669208400);
        EnumerableMap.set(uploadableMatchIds, 12, 1669197600);
        EnumerableMap.set(uploadableMatchIds, 13, 1669284000);
        EnumerableMap.set(uploadableMatchIds, 14, 1669294800);
        EnumerableMap.set(uploadableMatchIds, 15, 1669305600);
        EnumerableMap.set(uploadableMatchIds, 16, 1669316400);
        EnumerableMap.set(uploadableMatchIds, 17, 1669370400);
        EnumerableMap.set(uploadableMatchIds, 18, 1669381200);
        EnumerableMap.set(uploadableMatchIds, 19, 1669392000);
        EnumerableMap.set(uploadableMatchIds, 20, 1669402800);
        EnumerableMap.set(uploadableMatchIds, 21, 1669456800);
        EnumerableMap.set(uploadableMatchIds, 22, 1669467600);
        EnumerableMap.set(uploadableMatchIds, 23, 1669478400);
        EnumerableMap.set(uploadableMatchIds, 24, 1669489200);
        EnumerableMap.set(uploadableMatchIds, 25, 1669543200);
        EnumerableMap.set(uploadableMatchIds, 26, 1669554000);
        EnumerableMap.set(uploadableMatchIds, 27, 1669564800);
        EnumerableMap.set(uploadableMatchIds, 28, 1669575600);
        EnumerableMap.set(uploadableMatchIds, 29, 1669629600);
        EnumerableMap.set(uploadableMatchIds, 30, 1669640400);
        EnumerableMap.set(uploadableMatchIds, 31, 1669651200);
        EnumerableMap.set(uploadableMatchIds, 32, 1669662000);
        EnumerableMap.set(uploadableMatchIds, 33, 1669748400);
        EnumerableMap.set(uploadableMatchIds, 34, 1669748400);
        EnumerableMap.set(uploadableMatchIds, 35, 1669734000);
        EnumerableMap.set(uploadableMatchIds, 36, 1669734000);
        EnumerableMap.set(uploadableMatchIds, 37, 1669820400);
        EnumerableMap.set(uploadableMatchIds, 38, 1669820400);
        EnumerableMap.set(uploadableMatchIds, 39, 1669834800);
        EnumerableMap.set(uploadableMatchIds, 40, 1669834800);
        EnumerableMap.set(uploadableMatchIds, 41, 1669906800);
        EnumerableMap.set(uploadableMatchIds, 42, 1669906800);
        EnumerableMap.set(uploadableMatchIds, 43, 1669921200);
        EnumerableMap.set(uploadableMatchIds, 44, 1669921200);
        EnumerableMap.set(uploadableMatchIds, 45, 1669993200);
        EnumerableMap.set(uploadableMatchIds, 46, 1669993200);
        EnumerableMap.set(uploadableMatchIds, 47, 1670007600);
        EnumerableMap.set(uploadableMatchIds, 48, 1670007600);
        EnumerableMap.set(uploadableMatchIds, 49, 1670079600);
        EnumerableMap.set(uploadableMatchIds, 50, 1670094000);
        EnumerableMap.set(uploadableMatchIds, 51, 1670180400);
        EnumerableMap.set(uploadableMatchIds, 52, 1670166000);
        EnumerableMap.set(uploadableMatchIds, 53, 1670252400);
        EnumerableMap.set(uploadableMatchIds, 54, 1670266800);
        EnumerableMap.set(uploadableMatchIds, 55, 1670338800);
        EnumerableMap.set(uploadableMatchIds, 56, 1670353200);
        EnumerableMap.set(uploadableMatchIds, 57, 1670612400);
        EnumerableMap.set(uploadableMatchIds, 58, 1670598000);
        EnumerableMap.set(uploadableMatchIds, 59, 1670698800);
        EnumerableMap.set(uploadableMatchIds, 60, 1670684400);
        EnumerableMap.set(uploadableMatchIds, 61, 1670958000);
        EnumerableMap.set(uploadableMatchIds, 62, 1671044400);
        EnumerableMap.set(uploadableMatchIds, 63, 1671289200);
        EnumerableMap.set(uploadableMatchIds, 64, 1671375600);
    }

    struct Goals {
        uint256 firstTeamGoals;
        uint256 secondTeamGoals;
        bool isCompleted;
    }

    address owner;

    //PHASES
    mapping(uint256 => uint256[]) phaseToMatchIds;
    mapping(uint256 => uint256) matchToPhaseId;

    //PREDICTIONS
    mapping(address => mapping(uint256 => Goals)) gamePredictionsByPlayer;
    mapping(address => EnumerableMap.UintToUintMap) predictedGamesByPlayerId;

    //RESULTS
    mapping(uint256 => Goals) gameResults;
    EnumerableMap.UintToUintMap completedGameResults;

    //SCORES
    mapping(address => mapping(uint256 => uint256)) playerScoresByPhase;

    //CONDITIONS
    EnumerableMap.UintToUintMap uploadableMatchIds;
    EnumerableMap.AddressToUintMap whitelist;
    bool prodeInProgress;

    function isContract(address _address) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);//Warning: will return false if the call is made from the constructor of a smart contract
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can perform this operation.");
        _;
    }

    modifier onlyWhitelisted {
        require(isWhitelisted(msg.sender), "Only whitelisted users can interact with this method.");
        _;
    }

    modifier onlyProdeInProgress {
        require(prodeInProgress, "This action can only be performed while the prode is in progress.");
        _;
    }

    modifier notContract {
        require(!isContract(msg.sender), "Contracts cannot call prode.");
        _;
    }

    function getPhaseMatchIds(uint256 phase) public view returns(uint256[] memory) {
        return phaseToMatchIds[phase];
    }

    function setPlayerWhitelist(address[] calldata _whitelist) external notContract onlyOwner {
        for(uint256 i = 0; i < _whitelist.length; i++) {
            require(!isContract(_whitelist[i]), string.concat(toAsciiString(_whitelist[i]), " is a contract."));
            EnumerableMap.set(whitelist, _whitelist[i], 1);
        }
    }

    function removeFromWhitelist(address playerToRemove) external notContract onlyOwner {
        EnumerableMap.set(whitelist, playerToRemove, 0);
    }

    function isWhitelisted(address playerWallet) public view returns(bool) {
        (bool existsInWhitelist, uint256 whitelistValue) = EnumerableMap.tryGet(whitelist, playerWallet);
        return existsInWhitelist && whitelistValue == 1;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function updateOwner(address newOwner) external notContract onlyOwner {
        owner = newOwner;
    }

    function getBalance() external view returns(uint256) {
        return address(this).balance;
    }

    function setProdeInProgress(bool inProgress) external notContract onlyOwner {
        prodeInProgress = inProgress;
    }

    function getProdeInProgress() external view returns(bool) {
        return prodeInProgress;
    }

    function uploadGamePredictions(uint256[] calldata matchIds, uint256[] calldata firstTeamGoals, uint256[] calldata secondTeamGoals) external notContract onlyWhitelisted onlyProdeInProgress {
        require(matchIds.length == firstTeamGoals.length && matchIds.length == secondTeamGoals.length, "All array lengths must match.");
        for(uint256 i=0; i< matchIds.length; i++) {
            uploadGamePrediction(matchIds[i], firstTeamGoals[i], secondTeamGoals[i]);
        }
    }

    function uploadGamePrediction(uint256 matchId, uint256 firstTeamGoals, uint256 secondTeamGoals) private {
        (bool uploadableMatchExists, uint256 timestamp) = EnumerableMap.tryGet(uploadableMatchIds, matchId);
        require(uploadableMatchExists && timestamp >= block.timestamp + 86400, "Match id cannot be uploaded at the moment.");
        Goals memory goals = Goals(firstTeamGoals, secondTeamGoals, true);
        gamePredictionsByPlayer[msg.sender][matchId] = goals;
        EnumerableMap.set(predictedGamesByPlayerId[msg.sender], matchId, 1);
    }

    function updateUploadableMatchIds(uint256[] memory matchIds, uint256[] memory uploadable) external notContract onlyOwner {
        require(uploadable.length == matchIds.length, "Arrays should be of the same size.");
        for(uint256 i = 0; i < matchIds.length; i++){
            //uploadable[i]: 0=false (not uploadable), >0=true (uploadable)
            EnumerableMap.set(uploadableMatchIds, matchIds[i], uploadable[i]);
        }
    }

    function getPlayerGamePredictions(address playerWallet) external view returns(uint256[] memory matchIds, uint256[2][] memory goals) {
        uint256 resultLength = EnumerableMap.length(predictedGamesByPlayerId[playerWallet]);
        matchIds = new uint256[](resultLength);
        goals = new uint256[2][](resultLength);
        for(uint256 i=0; i< resultLength; i++) {
            (uint256 matchId, uint256 uploaded) = EnumerableMap.at(predictedGamesByPlayerId[playerWallet], i);
            matchIds[i] = matchId;
            Goals memory matchGoals = gamePredictionsByPlayer[playerWallet][matchId];
            goals[i][0] = matchGoals.firstTeamGoals;
            goals[i][1] = matchGoals.secondTeamGoals;
        }
    }

    function getUploadableMatchIds() external view returns(uint256[] memory uploadableMatches) {
        uint256 length = 0;
        for(uint256 i=0; i< EnumerableMap.length(uploadableMatchIds); i++) {
            (bool uploadable, uint256 matchId) = matchIsUploadableByIndex(i);
            if(uploadable) {
                length++;
            }
        }
        uploadableMatches = new uint256[](length);
        uint256 uploadableMatchIdCount = 0;
        for(uint256 i=0; i< EnumerableMap.length(uploadableMatchIds); i++) {
            (bool uploadable, uint256 matchId) = matchIsUploadableByIndex(i);
            if(uploadable){
                uploadableMatches[uploadableMatchIdCount] = matchId;
                uploadableMatchIdCount++;
            }
        }
    }

    function matchIsUploadableByIndex(uint256 index) private view returns (bool, uint256) {
        (uint256 matchId, uint256 timestamp) = EnumerableMap.at(uploadableMatchIds, index);
        return (matchUploadableTimestamp(timestamp), matchId);
    }

    function matchIsUploadableByMatchId(uint256 matchId) private view returns (bool) {
        return matchUploadableTimestamp(EnumerableMap.get(uploadableMatchIds, matchId));
    }

    function matchUploadableTimestamp(uint256 stamp) private view returns (bool) {
        return stamp >= block.timestamp + 86400;
    }

    function uploadGameResult(uint256 matchId, uint256 firstTeamGoals, uint256 secondTeamGoals) external notContract onlyOwner onlyProdeInProgress {
        require(!matchIsUploadableByMatchId(matchId), "Match id is still uploadable.");
        Goals memory goals = Goals(firstTeamGoals, secondTeamGoals, true);
        updateWhitelistedPlayerScores(matchId, goals);
        gameResults[matchId] = goals;
        EnumerableMap.set(completedGameResults, matchId, 1);
    }

    function updateWhitelistedPlayerScores(uint256 matchId, Goals memory result) private {
        uint256 phase = matchToPhaseId[matchId];
        for(uint256 i=0; i< EnumerableMap.length(whitelist); i++) {
            (address player, uint256 whitelisted) = EnumerableMap.at(whitelist, i);
            if(whitelisted == 1) {
                uint256 currentPhaseScore = getScore(player, phase);
                uint256 globalScore = getScore(player, 99);
                Goals memory prediction = gamePredictionsByPlayer[player][matchId];
                uint256 playerUpdatedPhaseScore = currentPhaseScore;
                uint256 playerUpdatedGlobalScore = globalScore;
                if(prediction.isCompleted) {
                    uint256 pointsScored = getPoints(prediction, result);
                    playerUpdatedPhaseScore += pointsScored;
                    playerUpdatedGlobalScore += pointsScored;

                    Goals memory previousResult = gameResults[matchId];
                    if(previousResult.isCompleted) {
                        uint256 previousPointsScored = getPoints(prediction, previousResult);
                        playerUpdatedPhaseScore -= previousPointsScored;
                        playerUpdatedGlobalScore -= previousPointsScored;
                    }
                }
                playerScoresByPhase[player][99] = playerUpdatedGlobalScore;
                emit ScoreUpdated(player, playerUpdatedGlobalScore, 99);
                playerScoresByPhase[player][phase] = playerUpdatedPhaseScore;
                emit ScoreUpdated(player, playerUpdatedPhaseScore, phase);
            }   
        }
    }

    function getGameResults() external view returns(uint256[] memory matchIds, uint256[2][] memory goals) {
        uint256 resultLength = EnumerableMap.length(completedGameResults);
        matchIds = new uint256[](resultLength);
        goals = new uint256[2][](resultLength);
        for(uint256 i=0; i< resultLength; i++) {
            (uint256 matchId, uint256 resultUploaded) = EnumerableMap.at(completedGameResults, i);
            matchIds[i] = matchId;
            Goals memory matchGoals = gameResults[matchId];
            goals[i][0] = matchGoals.firstTeamGoals;
            goals[i][1] = matchGoals.secondTeamGoals;
        }
    }

    function getScore(address player, uint256 phase) public view returns(uint256) {
        return playerScoresByPhase[player][phase];
    }

    function getGlobalScore(address player) external view returns(uint256) {
        return getScore(player, 99);
    }

    function getLeaderboard() external view returns(address[] memory players, uint256[] memory scores){
        return getLeaderboard(99);
    }

    function getLeaderboard(uint256 phase) public view returns(address[] memory players, uint256[] memory scores){
        uint256 whiteListLength = EnumerableMap.length(whitelist); 
        players = new address[](whiteListLength);
        scores = new uint256[](whiteListLength);
        for(uint256 i = 0; i < whiteListLength; i++) {
            (address currentPlayer, uint256 currentIsWhitelisted) = EnumerableMap.at(whitelist, i);
            if(currentIsWhitelisted == 1) {
                players[i] = currentPlayer;
                scores[i] = getScore(currentPlayer, phase);
            }
        }
    }

    function getAllLeaderboards() external view returns(address[] memory players, uint256[7][] memory scores) {
        uint256 whiteListLength = EnumerableMap.length(whitelist); 
        players = new address[](whiteListLength);
        scores = new uint256[7][](whiteListLength);
        for(uint256 i = 0; i < whiteListLength; i++) {
            (address currentPlayer, uint256 currentIsWhitelisted) = EnumerableMap.at(whitelist, i);
            if(currentIsWhitelisted == 1) {
                players[i] = currentPlayer;
                for(uint256 j=1; j<=6; j++) {
                    scores[i][j-1] = playerScoresByPhase[currentPlayer][j];
                }
                scores[i][6] = playerScoresByPhase[currentPlayer][99];
            }
        }
    }

    function getPoints(Goals memory matchPrediction, Goals memory matchResult) private pure returns(uint256 score){
        uint256 winnerPrediction = getWinnerId(matchPrediction);
        uint256 winnerResult = getWinnerId(matchResult);
        bool firstTeamGoalsPredictionCorrect = matchPrediction.firstTeamGoals == matchResult.firstTeamGoals;
        bool secondTeamGoalsPredictionCorrect = matchPrediction.secondTeamGoals == matchResult.secondTeamGoals;

        if(firstTeamGoalsPredictionCorrect && secondTeamGoalsPredictionCorrect) {
            // 5 puntos
            score += 5;
        } else if(firstTeamGoalsPredictionCorrect || secondTeamGoalsPredictionCorrect) {
            // 2 puntos
            score += 2;
        }

        if(winnerPrediction == winnerResult) {
            // 5 puntos
            score += 5;
        }
    }

    function getWinnerId(Goals memory game) private pure returns(uint256){
        if(game.firstTeamGoals > game.secondTeamGoals) {
            return 1;
        }
        if(game.firstTeamGoals < game.secondTeamGoals) {
            return 2;
        }
        return 0;
    }

    function getProdeResults() public view returns(uint256[3] memory amountOfWinnersPerPosition, uint256[3] memory maxScorePerPosition, address[][3] memory winnersPerPosition) {
        uint256 whiteListLength = EnumerableMap.length(whitelist); 
        
        for(uint256 i = 0; i < whiteListLength; i++) {
            (address currentPlayer, uint256 currentIsWhitelisted) = EnumerableMap.at(whitelist, i);
            if(currentIsWhitelisted == 1) {
                uint256 currentScore = getScore(currentPlayer, 99);
                if(currentScore > maxScorePerPosition[0]) {
                    maxScorePerPosition[2] = maxScorePerPosition[1];
                    amountOfWinnersPerPosition[2] = amountOfWinnersPerPosition[1];
                    
                    maxScorePerPosition[1] = maxScorePerPosition[0];
                    amountOfWinnersPerPosition[1] = amountOfWinnersPerPosition[0];
                    
                    maxScorePerPosition[0] = currentScore;
                    amountOfWinnersPerPosition[0] = 1;
                } else if(currentScore == maxScorePerPosition[0]) {
                    amountOfWinnersPerPosition[0]++;
                } else if(currentScore > maxScorePerPosition[1]) {
                    maxScorePerPosition[2] = maxScorePerPosition[1];
                    amountOfWinnersPerPosition[2] = amountOfWinnersPerPosition[1];

                    maxScorePerPosition[1] = currentScore;
                    amountOfWinnersPerPosition[1] = 1;
                } else if(currentScore == maxScorePerPosition[1]) {
                    amountOfWinnersPerPosition[1]++;
                } else if(currentScore > maxScorePerPosition[2]) {
                    maxScorePerPosition[2] = currentScore;
                    amountOfWinnersPerPosition[2] = 1;
                } else if(currentScore == maxScorePerPosition[2]) {
                    amountOfWinnersPerPosition[2]++;
                }
            }
        }
        
        uint256[3] memory winnersLenghtsPerPositions;
        winnersPerPosition[0] = new address[](amountOfWinnersPerPosition[0]);
        winnersPerPosition[1] = new address[](amountOfWinnersPerPosition[1]);
        winnersPerPosition[2] = new address[](amountOfWinnersPerPosition[2]);
        for(uint256 i = 0; i < whiteListLength; i++) {
            (address currentPlayer, uint256 currentIsWhitelisted) = EnumerableMap.at(whitelist, i);
            if(currentIsWhitelisted == 1) {
                uint256 currentScore = getScore(currentPlayer, 99);
                if(currentScore == maxScorePerPosition[0]) {
                    winnersPerPosition[0][winnersLenghtsPerPositions[0]] = currentPlayer;
                    winnersLenghtsPerPositions[0]++;
                } else if(currentScore == maxScorePerPosition[1]) {
                    winnersPerPosition[1][winnersLenghtsPerPositions[1]] = currentPlayer;
                    winnersLenghtsPerPositions[1]++;
                } else if(currentScore == maxScorePerPosition[2]) {
                    winnersPerPosition[2][winnersLenghtsPerPositions[2]] = currentPlayer;
                    winnersLenghtsPerPositions[2]++;
                }
            }
        }
    }

    function claimPhasePrize(uint256 amount, address player) external notContract onlyOwner  {
        payable(player).transfer(amount);
    }

    function noTies(uint256[3] memory amountOfWinnersPerPosition) private pure returns(bool) {
        return amountOfWinnersPerPosition[0] == 1 && amountOfWinnersPerPosition[1] == 1 && amountOfWinnersPerPosition[2] == 1;
    }

    function claim() external payable notContract onlyOwner {
        require(!prodeInProgress, "Prode is still in progress. You cannot claim your reward.");

        (uint256[3] memory amountOfWinnersPerPosition, uint256[3] memory maxScorePerPosition, address[][3] memory winnersPerPosition) = getProdeResults();
        require(noTies(amountOfWinnersPerPosition), "There is a tie for the Prode winner. This must be resolved manually.");
    
        uint256 firstPlayerPrize = address(this).balance * 50/100;
        uint256 secondPlayerPrize = address(this).balance * 30/100;
        uint256 thirdPlayerPrize = address(this).balance * 20/100;
        payable(winnersPerPosition[0][0]).transfer(firstPlayerPrize);
        payable(winnersPerPosition[1][0]).transfer(secondPlayerPrize);
        payable(winnersPerPosition[2][0]).transfer(thirdPlayerPrize);
    }

    function emergencyClaim() external payable notContract onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function emergencyERC20Claim(address erc20Address) external payable notContract onlyOwner {
        IERC20(erc20Address).transfer(msg.sender, IERC20(erc20Address).balanceOf(address(this)));
    }
}