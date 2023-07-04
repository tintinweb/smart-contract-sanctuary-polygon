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
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./Symbols.sol";

 contract CoGSymbols {
    using EnumerableSet for EnumerableSet.UintSet;
    using Symbols for Symbols.ID;
    mapping(Symbols.ID => int256) public symbolsInitPayout;
    mapping(Symbols.ID => string) public symbolsToString;
    mapping(string => EnumerableSet.UintSet) internal category;

    constructor() {
        symbolsToString[Symbols.ID.A1] = "A1";
        symbolsToString[Symbols.ID.A2] = "A2";
        symbolsToString[Symbols.ID.A3] = "A3";
        symbolsToString[Symbols.ID.B1] = "B1";
        symbolsToString[Symbols.ID.B2] = "B2";
        symbolsToString[Symbols.ID.B3] = "B3";
        symbolsToString[Symbols.ID.B4] = "B4";
        symbolsToString[Symbols.ID.B5] = "B5";
        symbolsToString[Symbols.ID.B6] = "B6";
        symbolsToString[Symbols.ID.B7] = "B7";
        symbolsToString[Symbols.ID.B8] = "B8";
        symbolsToString[Symbols.ID.B9] = "B9";
        symbolsToString[Symbols.ID.B10] = "B10";
        symbolsToString[Symbols.ID.B11] = "B11";
        symbolsToString[Symbols.ID.B12] = "B12";
        symbolsToString[Symbols.ID.B13] = "B13";
        symbolsToString[Symbols.ID.B14] = "B14";
        symbolsToString[Symbols.ID.B15] = "B15";
        symbolsToString[Symbols.ID.B16] = "B16";
        symbolsToString[Symbols.ID.C1] = "C1";
        symbolsToString[Symbols.ID.C2] = "C2";
        symbolsToString[Symbols.ID.C3] = "C3";
        symbolsToString[Symbols.ID.C4] = "C4";
        symbolsToString[Symbols.ID.C5] = "C5";
        symbolsToString[Symbols.ID.C6] = "C6";
        symbolsToString[Symbols.ID.C7] = "C7";
        symbolsToString[Symbols.ID.C8] = "C8";
        symbolsToString[Symbols.ID.C9] = "C9";
        symbolsToString[Symbols.ID.C10] = "C10";
        symbolsToString[Symbols.ID.C11] = "C11";
        symbolsToString[Symbols.ID.C12] = "C12";
        symbolsToString[Symbols.ID.C13] = "C13";
        symbolsToString[Symbols.ID.C14] = "C14";
        symbolsToString[Symbols.ID.C15] = "C15";
        symbolsToString[Symbols.ID.C16] = "C16";
        symbolsToString[Symbols.ID.C17] = "C17";
        symbolsToString[Symbols.ID.C18] = "C18";
        symbolsToString[Symbols.ID.C19] = "C19";
        symbolsToString[Symbols.ID.D1] = "D1";
        symbolsToString[Symbols.ID.D2] = "D2";
        symbolsToString[Symbols.ID.D3] = "D3";
        symbolsToString[Symbols.ID.D4] = "D4";
        symbolsToString[Symbols.ID.D5] = "D5";
        symbolsToString[Symbols.ID.D6] = "D6";
        symbolsToString[Symbols.ID.D7] = "D7";
        symbolsToString[Symbols.ID.D8] = "D8";
        symbolsToString[Symbols.ID.E1] = "E1";
        symbolsToString[Symbols.ID.E2] = "E2";
        symbolsToString[Symbols.ID.E3] = "E3";
        symbolsToString[Symbols.ID.E4] = "E4";
        symbolsToString[Symbols.ID.E5] = "E5";
        symbolsToString[Symbols.ID.F1] = "F1";
        symbolsToString[Symbols.ID.F2] = "F2";
        symbolsToString[Symbols.ID.F3] = "F3";
        symbolsToString[Symbols.ID.F4] = "F4";
        symbolsToString[Symbols.ID.G1] = "G1";
        symbolsToString[Symbols.ID.G2] = "G2";
        symbolsToString[Symbols.ID.G3] = "G3";
        symbolsToString[Symbols.ID.G4] = "G4";
        symbolsToString[Symbols.ID.G5] = "G5";
        symbolsToString[Symbols.ID.G6] = "G6";
        symbolsToString[Symbols.ID.G7] = "G7";
        symbolsToString[Symbols.ID.G8] = "G8";
        symbolsToString[Symbols.ID.H1] = "H1";
        symbolsToString[Symbols.ID.H2] = "H2";
        symbolsToString[Symbols.ID.H3] = "H3";
        symbolsToString[Symbols.ID.H4] = "H4";
        symbolsToString[Symbols.ID.H5] = "H5";
        symbolsToString[Symbols.ID.H6] = "H6";
        symbolsToString[Symbols.ID.H7] = "H7";
        symbolsToString[Symbols.ID.H8] = "H8";
        symbolsToString[Symbols.ID.H9] = "H9";
        symbolsToString[Symbols.ID.H10] = "H10";
        symbolsToString[Symbols.ID.H11] = "H11";
        symbolsToString[Symbols.ID.H12] = "H12";
        symbolsToString[Symbols.ID.I1] = "I1";
        symbolsToString[Symbols.ID.J1] = "J1";
        symbolsToString[Symbols.ID.J2] = "J2";
        symbolsToString[Symbols.ID.K1] = "K1";
        symbolsToString[Symbols.ID.K2] = "K2";
        symbolsToString[Symbols.ID.L1] = "L1";
        symbolsToString[Symbols.ID.L2] = "L2";
        symbolsToString[Symbols.ID.L3] = "L3";
        symbolsToString[Symbols.ID.M1] = "M1";
        symbolsToString[Symbols.ID.M2] = "M2";
        symbolsToString[Symbols.ID.M3] = "M3";
        symbolsToString[Symbols.ID.M4] = "M4";
        symbolsToString[Symbols.ID.M5] = "M5";
        symbolsToString[Symbols.ID.M6] = "M6";
        symbolsToString[Symbols.ID.M7] = "M7";
        symbolsToString[Symbols.ID.M8] = "M8";
        symbolsToString[Symbols.ID.M9] = "M9";
        symbolsToString[Symbols.ID.M10] = "M10";
        symbolsToString[Symbols.ID.M11] = "M11";
        symbolsToString[Symbols.ID.M12] = "M12";
        symbolsToString[Symbols.ID.M13] = "M13";
        symbolsToString[Symbols.ID.M14] = "M14";
        symbolsToString[Symbols.ID.M15] = "M15";
        symbolsToString[Symbols.ID.M16] = "M16";
        symbolsToString[Symbols.ID.M17] = "M17";
        symbolsToString[Symbols.ID.M18] = "M18";
        symbolsToString[Symbols.ID.N1] = "N1";
        symbolsToString[Symbols.ID.O1] = "O1";
        symbolsToString[Symbols.ID.O2] = "O2";
        symbolsToString[Symbols.ID.O3] = "O3";
        symbolsToString[Symbols.ID.O4] = "O4";
        symbolsToString[Symbols.ID.O5] = "O5";
        symbolsToString[Symbols.ID.P1] = "P1";
        symbolsToString[Symbols.ID.P2] = "P2";
        symbolsToString[Symbols.ID.P3] = "P3";
        symbolsToString[Symbols.ID.P4] = "P4";
        symbolsToString[Symbols.ID.P5] = "P5";
        symbolsToString[Symbols.ID.P6] = "P6";
        symbolsToString[Symbols.ID.P7] = "P7";
        symbolsToString[Symbols.ID.R1] = "R1";
        symbolsToString[Symbols.ID.R2] = "R2";
        symbolsToString[Symbols.ID.R3] = "R3";
        symbolsToString[Symbols.ID.R4] = "R4";
        symbolsToString[Symbols.ID.R5] = "R5";
        symbolsToString[Symbols.ID.R6] = "R6";
        symbolsToString[Symbols.ID.R7] = "R7";
        symbolsToString[Symbols.ID.S1] = "S1";
        symbolsToString[Symbols.ID.S2] = "S2";
        symbolsToString[Symbols.ID.S3] = "S3";
        symbolsToString[Symbols.ID.S4] = "S4";
        symbolsToString[Symbols.ID.S5] = "S5";
        symbolsToString[Symbols.ID.S6] = "S6";
        symbolsToString[Symbols.ID.S7] = "S7";
        symbolsToString[Symbols.ID.S8] = "S8";
        symbolsToString[Symbols.ID.S9] = "S9";
        symbolsToString[Symbols.ID.S10] = "S10";
        symbolsToString[Symbols.ID.S11] = "S11";
        symbolsToString[Symbols.ID.S12] = "S12";
        symbolsToString[Symbols.ID.T1] = "T1";
        symbolsToString[Symbols.ID.T2] = "T2";
        symbolsToString[Symbols.ID.T3] = "T3";
        symbolsToString[Symbols.ID.T4] = "T4";
        symbolsToString[Symbols.ID.T5] = "T5";
        symbolsToString[Symbols.ID.T6] = "T6";
        symbolsToString[Symbols.ID.T7] = "T7";
        symbolsToString[Symbols.ID.T8] = "T8";
        symbolsToString[Symbols.ID.T9] = "T9";
        symbolsToString[Symbols.ID.U1] = "U1";
        symbolsToString[Symbols.ID.V1] = "V1";
        symbolsToString[Symbols.ID.V2] = "V2";
        symbolsToString[Symbols.ID.V3] = "V3";
        symbolsToString[Symbols.ID.W1] = "W1";
        symbolsToString[Symbols.ID.W2] = "W2";
        symbolsToString[Symbols.ID.W3] = "W3";
        symbolsToString[Symbols.ID.W4] = "W4";
        symbolsToString[Symbols.ID.W5] = "W5";
        symbolsToString[Symbols.ID.W6] = "W6";
    }

    function setPayout(Symbols.ID[] memory _str, int256[] memory payout) public {
        for (uint256 i=0; i< _str.length;++i){
            symbolsInitPayout[_str[i]] = payout[i];
        }
      
    }

    function setCategory(string memory sort, Symbols.ID[] memory comp) public {
        for (uint256 i = 0; i < comp.length; ++i) {
            category[sort].add(uint256(comp[i]));
        }
    }

    function contains(string memory sort, uint256 symbol)
        public
        view
        returns (bool)
    {
        return category[sort].contains(symbol);
    }
    // function findSymbol(uint256 index) public pure returns (Symbols.ID) {
    //     if (index == 1) return Symbols.ID.A1;
    //     if (index == 2) return Symbols.ID.A2;
    //     if (index == 3) return Symbols.ID.A3;
    //     if (index == 4) return Symbols.ID.B1;
    //     if (index == 5) return Symbols.ID.B2;
    //     if (index == 6) return Symbols.ID.B3;
    //     if (index == 7) return Symbols.ID.B4;
    //     if (index == 8) return Symbols.ID.B5;
    //     if (index == 9) return Symbols.ID.B6;
    //     if (index == 10) return Symbols.ID.B7;
    //     if (index == 11) return Symbols.ID.B8;
    //     if (index == 12) return Symbols.ID.B9;
    //     if (index == 13) return Symbols.ID.B10;
    //     if (index == 14) return Symbols.ID.B11;
    //     if (index == 15) return Symbols.ID.B12;
    //     if (index == 16) return Symbols.ID.B13;
    //     if (index == 17) return Symbols.ID.B14;
    //     if (index == 18) return Symbols.ID.B15;
    //     if (index == 19) return Symbols.ID.B16;
    //     if (index == 20) return Symbols.ID.C1;
    //     if (index == 21) return Symbols.ID.C2;
    //     if (index == 22) return Symbols.ID.C3;
    //     if (index == 23) return Symbols.ID.C4;
    //     if (index == 24) return Symbols.ID.C5;
    //     if (index == 25) return Symbols.ID.C6;
    //     if (index == 26) return Symbols.ID.C7;
    //     if (index == 27) return Symbols.ID.C8;
    //     if (index == 28) return Symbols.ID.C9;
    //     if (index == 29) return Symbols.ID.C10;
    //     if (index == 30) return Symbols.ID.C11;
    //     if (index == 31) return Symbols.ID.C12;
    //     if (index == 32) return Symbols.ID.C13;
    //     if (index == 33) return Symbols.ID.C14;
    //     if (index == 34) return Symbols.ID.C15;
    //     if (index == 35) return Symbols.ID.C16;
    //     if (index == 36) return Symbols.ID.C17;
    //     if (index == 37) return Symbols.ID.C18;
    //     if (index == 38) return Symbols.ID.C19;
    //     if (index == 39) return Symbols.ID.D1;
    //     if (index == 40) return Symbols.ID.D2;
    //     if (index == 41) return Symbols.ID.D3;
    //     if (index == 42) return Symbols.ID.D4;
    //     if (index == 43) return Symbols.ID.D5;
    //     if (index == 44) return Symbols.ID.D6;
    //     if (index == 45) return Symbols.ID.D7;
    //     if (index == 46) return Symbols.ID.D8;
    //     if (index == 47) return Symbols.ID.E1;
    //     if (index == 48) return Symbols.ID.E2;
    //     if (index == 49) return Symbols.ID.E3;
    //     if (index == 50) return Symbols.ID.E4;
    //     if (index == 51) return Symbols.ID.E5;
    //     if (index == 52) return Symbols.ID.F1;
    //     if (index == 53) return Symbols.ID.F2;
    //     if (index == 54) return Symbols.ID.F3;
    //     if (index == 55) return Symbols.ID.F4;
    //     if (index == 56) return Symbols.ID.G1;
    //     if (index == 57) return Symbols.ID.G2;
    //     if (index == 58) return Symbols.ID.G3;
    //     if (index == 59) return Symbols.ID.G4;
    //     if (index == 60) return Symbols.ID.G5;
    //     if (index == 61) return Symbols.ID.G6;
    //     if (index == 62) return Symbols.ID.G7;
    //     if (index == 63) return Symbols.ID.G8;
    //     if (index == 64) return Symbols.ID.H1;
    //     if (index == 65) return Symbols.ID.H2;
    //     if (index == 66) return Symbols.ID.H3;
    //     if (index == 67) return Symbols.ID.H4;
    //     if (index == 68) return Symbols.ID.H5;
    //     if (index == 69) return Symbols.ID.H6;
    //     if (index == 70) return Symbols.ID.H7;
    //     if (index == 71) return Symbols.ID.H8;
    //     if (index == 72) return Symbols.ID.H9;
    //     if (index == 73) return Symbols.ID.H10;
    //     if (index == 74) return Symbols.ID.H11;
    //     if (index == 75) return Symbols.ID.H12;
    //     if (index == 76) return Symbols.ID.I1;
    //     if (index == 77) return Symbols.ID.J1;
    //     if (index == 78) return Symbols.ID.J2;
    //     if (index == 79) return Symbols.ID.K1;
    //     if (index == 80) return Symbols.ID.K2;
    //     if (index == 81) return Symbols.ID.L1;
    //     if (index == 82) return Symbols.ID.L2;
    //     if (index == 83) return Symbols.ID.L3;
    //     if (index == 84) return Symbols.ID.M1;
    //     if (index == 85) return Symbols.ID.M2;
    //     if (index == 86) return Symbols.ID.M3;
    //     if (index == 87) return Symbols.ID.M4;
    //     if (index == 88) return Symbols.ID.M5;
    //     if (index == 89) return Symbols.ID.M6;
    //     if (index == 90) return Symbols.ID.M7;
    //     if (index == 91) return Symbols.ID.M8;
    //     if (index == 92) return Symbols.ID.M9;
    //     if (index == 93) return Symbols.ID.M10;
    //     if (index == 94) return Symbols.ID.M11;
    //     if (index == 95) return Symbols.ID.M12;
    //     if (index == 96) return Symbols.ID.M13;
    //     if (index == 97) return Symbols.ID.M14;
    //     if (index == 98) return Symbols.ID.M15;
    //     if (index == 99) return Symbols.ID.M16;
    //     if (index == 100) return Symbols.ID.M17;
    //     if (index == 101) return Symbols.ID.M18;
    //     if (index == 102) return Symbols.ID.N1;
    //     if (index == 103) return Symbols.ID.O1;
    //     if (index == 104) return Symbols.ID.O2;
    //     if (index == 105) return Symbols.ID.O3;
    //     if (index == 106) return Symbols.ID.O4;
    //     if (index == 107) return Symbols.ID.O5;
    //     if (index == 108) return Symbols.ID.P1;
    //     if (index == 109) return Symbols.ID.P2;
    //     if (index == 110) return Symbols.ID.P3;
    //     if (index == 111) return Symbols.ID.P4;
    //     if (index == 112) return Symbols.ID.P5;
    //     if (index == 113) return Symbols.ID.P6;
    //     if (index == 114) return Symbols.ID.P7;
    //     if (index == 115) return Symbols.ID.R1;
    //     if (index == 116) return Symbols.ID.R2;
    //     if (index == 117) return Symbols.ID.R3;
    //     if (index == 118) return Symbols.ID.R4;
    //     if (index == 119) return Symbols.ID.R5;
    //     if (index == 120) return Symbols.ID.R6;
    //     if (index == 121) return Symbols.ID.R7;
    //     if (index == 122) return Symbols.ID.S1;
    //     if (index == 123) return Symbols.ID.S2;
    //     if (index == 124) return Symbols.ID.S3;
    //     if (index == 125) return Symbols.ID.S4;
    //     if (index == 126) return Symbols.ID.S5;
    //     if (index == 127) return Symbols.ID.S6;
    //     if (index == 128) return Symbols.ID.S7;
    //     if (index == 129) return Symbols.ID.S8;
    //     if (index == 130) return Symbols.ID.S9;
    //     if (index == 131) return Symbols.ID.S10;
    //     if (index == 132) return Symbols.ID.S11;
    //     if (index == 133) return Symbols.ID.S12;
    //     if (index == 134) return Symbols.ID.T1;
    //     if (index == 135) return Symbols.ID.T2;
    //     if (index == 136) return Symbols.ID.T3;
    //     if (index == 137) return Symbols.ID.T4;
    //     if (index == 138) return Symbols.ID.T5;
    //     if (index == 139) return Symbols.ID.T6;
    //     if (index == 140) return Symbols.ID.T7;
    //     if (index == 141) return Symbols.ID.T8;
    //     if (index == 142) return Symbols.ID.T9;
    //     if (index == 143) return Symbols.ID.U1;
    //     if (index == 144) return Symbols.ID.V1;
    //     if (index == 145) return Symbols.ID.V2;
    //     if (index == 146) return Symbols.ID.V3;
    //     if (index == 147) return Symbols.ID.W1;
    //     if (index == 148) return Symbols.ID.W2;
    //     if (index == 149) return Symbols.ID.W3;
    //     if (index == 150) return Symbols.ID.W4;
    //     if (index == 151) return Symbols.ID.W5;
    //     if (index == 152) return Symbols.ID.W6;

    //     // If index is out of range, return an invalid symbol
    //     revert("Invalid index");
    // }
    
    function at(string memory sort, uint256 index)
        public
        view
        returns (uint256)
    {
        return category[sort].at(index);
    }

    function categoryLength(string memory sort) public view returns (uint256) {
        return category[sort].length();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Symbols {
    enum ID {
        A0,
        A1,
        A2,
        A3,
        B1,
        B2,
        B3,
        B4,
        B5,
        B6,
        B7,
        B8,
        B9,
        B10,
        B11,
        B12,
        B13,
        B14,
        B15,
        B16,
        C1,
        C2,
        C3,
        C4,
        C5,
        C6,
        C7,
        C8,
        C9,
        C10,
        C11,
        C12,
        C13,
        C14,
        C15,
        C16,
        C17,
        C18,
        C19,
        D1,
        D2,
        D3,
        D4,
        D5,
        D6,
        D7,
        D8,
        E1,
        E2,
        E3,
        E4,
        E5,
        F1,
        F2,
        F3,
        F4,
        G1,
        G2,
        G3,
        G4,
        G5,
        G6,
        G7,
        G8,
        H1,
        H2,
        H3,
        H4,
        H5,
        H6,
        H7,
        H8,
        H9,
        H10,
        H11,
        H12,
        I1,
        J1,
        J2,
        K1,
        K2,
        L1,
        L2,
        L3,
        M1,
        M2,
        M3,
        M4,
        M5,
        M6,
        M7,
        M8,
        M9,
        M10,
        M11,
        M12,
        M13,
        M14,
        M15,
        M16,
        M17,
        M18,
        N1,
        O1,
        O2,
        O3,
        O4,
        O5,
        P1,
        P2,
        P3,
        P4,
        P5,
        P6,
        P7,
        R1,
        R2,
        R3,
        R4,
        R5,
        R6,
        R7,
        S1,
        S2,
        S3,
        S4,
        S5,
        S6,
        S7,
        S8,
        S9,
        S10,
        S11,
        S12,
        T1,
        T2,
        T3,
        T4,
        T5,
        T6,
        T7,
        T8,
        T9,
        U1,
        V1,
        V2,
        V3,
        W1,
        W2,
        W3,
        W4,
        W5,
        W6
    }
    function findSymbol(uint256 index) public pure returns (ID) {
        if (index == 1) return ID.A1;
        if (index == 2) return ID.A2;
        if (index == 3) return ID.A3;
        if (index == 4) return ID.B1;
        if (index == 5) return ID.B2;
        if (index == 6) return ID.B3;
        if (index == 7) return ID.B4;
        if (index == 8) return ID.B5;
        if (index == 9) return ID.B6;
        if (index == 10) return ID.B7;
        if (index == 11) return ID.B8;
        if (index == 12) return ID.B9;
        if (index == 13) return ID.B10;
        if (index == 14) return ID.B11;
        if (index == 15) return ID.B12;
        if (index == 16) return ID.B13;
        if (index == 17) return ID.B14;
        if (index == 18) return ID.B15;
        if (index == 19) return ID.B16;
        if (index == 20) return ID.C1;
        if (index == 21) return ID.C2;
        if (index == 22) return ID.C3;
        if (index == 23) return ID.C4;
        if (index == 24) return ID.C5;
        if (index == 25) return ID.C6;
        if (index == 26) return ID.C7;
        if (index == 27) return ID.C8;
        if (index == 28) return ID.C9;
        if (index == 29) return ID.C10;
        if (index == 30) return ID.C11;
        if (index == 31) return ID.C12;
        if (index == 32) return ID.C13;
        if (index == 33) return ID.C14;
        if (index == 34) return ID.C15;
        if (index == 35) return ID.C16;
        if (index == 36) return ID.C17;
        if (index == 37) return ID.C18;
        if (index == 38) return ID.C19;
        if (index == 39) return ID.D1;
        if (index == 40) return ID.D2;
        if (index == 41) return ID.D3;
        if (index == 42) return ID.D4;
        if (index == 43) return ID.D5;
        if (index == 44) return ID.D6;
        if (index == 45) return ID.D7;
        if (index == 46) return ID.D8;
        if (index == 47) return ID.E1;
        if (index == 48) return ID.E2;
        if (index == 49) return ID.E3;
        if (index == 50) return ID.E4;
        if (index == 51) return ID.E5;
        if (index == 52) return ID.F1;
        if (index == 53) return ID.F2;
        if (index == 54) return ID.F3;
        if (index == 55) return ID.F4;
        if (index == 56) return ID.G1;
        if (index == 57) return ID.G2;
        if (index == 58) return ID.G3;
        if (index == 59) return ID.G4;
        if (index == 60) return ID.G5;
        if (index == 61) return ID.G6;
        if (index == 62) return ID.G7;
        if (index == 63) return ID.G8;
        if (index == 64) return ID.H1;
        if (index == 65) return ID.H2;
        if (index == 66) return ID.H3;
        if (index == 67) return ID.H4;
        if (index == 68) return ID.H5;
        if (index == 69) return ID.H6;
        if (index == 70) return ID.H7;
        if (index == 71) return ID.H8;
        if (index == 72) return ID.H9;
        if (index == 73) return ID.H10;
        if (index == 74) return ID.H11;
        if (index == 75) return ID.H12;
        if (index == 76) return ID.I1;
        if (index == 77) return ID.J1;
        if (index == 78) return ID.J2;
        if (index == 79) return ID.K1;
        if (index == 80) return ID.K2;
        if (index == 81) return ID.L1;
        if (index == 82) return ID.L2;
        if (index == 83) return ID.L3;
        if (index == 84) return ID.M1;
        if (index == 85) return ID.M2;
        if (index == 86) return ID.M3;
        if (index == 87) return ID.M4;
        if (index == 88) return ID.M5;
        if (index == 89) return ID.M6;
        if (index == 90) return ID.M7;
        if (index == 91) return ID.M8;
        if (index == 92) return ID.M9;
        if (index == 93) return ID.M10;
        if (index == 94) return ID.M11;
        if (index == 95) return ID.M12;
        if (index == 96) return ID.M13;
        if (index == 97) return ID.M14;
        if (index == 98) return ID.M15;
        if (index == 99) return ID.M16;
        if (index == 100) return ID.M17;
        if (index == 101) return ID.M18;
        if (index == 102) return ID.N1;
        if (index == 103) return ID.O1;
        if (index == 104) return ID.O2;
        if (index == 105) return ID.O3;
        if (index == 106) return ID.O4;
        if (index == 107) return ID.O5;
        if (index == 108) return ID.P1;
        if (index == 109) return ID.P2;
        if (index == 110) return ID.P3;
        if (index == 111) return ID.P4;
        if (index == 112) return ID.P5;
        if (index == 113) return ID.P6;
        if (index == 114) return ID.P7;
        if (index == 115) return ID.R1;
        if (index == 116) return ID.R2;
        if (index == 117) return ID.R3;
        if (index == 118) return ID.R4;
        if (index == 119) return ID.R5;
        if (index == 120) return ID.R6;
        if (index == 121) return ID.R7;
        if (index == 122) return ID.S1;
        if (index == 123) return ID.S2;
        if (index == 124) return ID.S3;
        if (index == 125) return ID.S4;
        if (index == 126) return ID.S5;
        if (index == 127) return ID.S6;
        if (index == 128) return ID.S7;
        if (index == 129) return ID.S8;
        if (index == 130) return ID.S9;
        if (index == 131) return ID.S10;
        if (index == 132) return ID.S11;
        if (index == 133) return ID.S12;
        if (index == 134) return ID.T1;
        if (index == 135) return ID.T2;
        if (index == 136) return ID.T3;
        if (index == 137) return ID.T4;
        if (index == 138) return ID.T5;
        if (index == 139) return ID.T6;
        if (index == 140) return ID.T7;
        if (index == 141) return ID.T8;
        if (index == 142) return ID.T9;
        if (index == 143) return ID.U1;
        if (index == 144) return ID.V1;
        if (index == 145) return ID.V2;
        if (index == 146) return ID.V3;
        if (index == 147) return ID.W1;
        if (index == 148) return ID.W2;
        if (index == 149) return ID.W3;
        if (index == 150) return ID.W4;
        if (index == 151) return ID.W5;
        if (index == 152) return ID.W6;

        // If index is out of range, return an invalid symbol
        revert("Invalid index");
    }
}