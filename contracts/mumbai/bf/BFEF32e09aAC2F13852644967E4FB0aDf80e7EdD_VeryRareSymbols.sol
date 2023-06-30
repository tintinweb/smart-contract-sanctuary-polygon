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

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface IBaseLogic {
    enum Symbols {
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

    function gameMap() external view returns (address);

    function arrow(
        uint256 id,
        uint256 position,
        string memory direction,
        uint8 sort
    ) external returns (int256 coin);

    function findSymbol(uint256 index) external pure returns (Symbols);

    function contains(string memory sort, uint256) external view returns (bool);

    function at(string memory sort, uint256 index)
        external
        view
        returns (uint256);
function categoryLength(string memory sort) external  view returns(uint256);
    function b1_destroy(uint256 id, uint256 position) external;

    function b12_destroy(uint256 id, uint256 position)
        external
        returns (int256 coin);

    function j1_remove(uint256 id, uint256 position) external;

    function f4_destroy(uint256 id, uint256 position) external;

    function o5_remove(uint256 id, uint256 position) external;

    function t1_destroy(uint256 id, uint256 position)
        external
        returns (int256 coin);

    function l2_destroy(uint256 id, uint256 position)
        external
        returns (int256 coin);

    function o3_destroy(uint256 id, uint256 position) external;

    function p6_destroy(uint256 id, uint256 position)
        external
        returns (int256 coin);

    function u1_destroy(uint256 id, uint256 position) external;

    function m12_destroy(uint256 id, uint256 position) external;

    function m16_destroy(uint256 id, uint256 position) external;

    function b10_destroy(uint256 id, uint256 position) external;

    function b11_destroy(uint256 id, uint256 position) external;

    function c12_destroy(uint256 id, uint256 position) external;

    function g1_destroy(uint256 id, uint256 position)
        external
        returns (int256 coin);

    function m9_destroy(uint256 id, uint256 position)
        external
        returns (int256 coin);

    function p1_destroy(uint256 id, uint256 position) external;

    function p5_destroy(uint256 id, uint256 position) external;

    function p7_remove(uint256 id, uint256 position)
        external
        returns (int256 coin);

    function r4_destroy(uint256 id, uint256 position) external;

    function s1_destroy(uint256 id, uint256 position)
        external
        returns (int256 coin);

    function s2_remove(uint256 id, uint256 position)
        external
        returns (int256 coin);

    function t3_destroy(uint256 id, uint256 position)
        external
        returns (int256 coin);

    function t7_destroy(uint256 id, uint256 position) external;

    function v1_destroy(uint256 id, uint256 position)
        external
        returns (int256 coin);

    function v2_destroy(uint256 id, uint256 position)
        external
        returns (int256 coin);

    function v3_destroy(uint256 id, uint256 position)
        external
        returns (int256 coin);

    function w2_destroy(uint256 id, uint256 position)
        external
        returns (int256 coin);

    function t8_destroy(uint256 id, uint256 position)
        external
        returns (int256 coin);

    function void(uint256 id, uint256 position) external returns (int256 coin);

    function void_destroy(uint256 id, uint256 position)
        external
        returns (int256 coin);

    function getAdjacentPositions(uint256 position)
        external
        returns (uint256[] memory pos);

    function getArrowPointed(uint256 position, string memory direction)
        external
        pure
        returns (uint256[] memory);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface ICOGGame {
    function atPosition(uint256, uint256) external view returns (uint256);

    function removeSymbol(uint256, uint256) external;

    function destroySymbol(uint256, uint256) external;

    function addSymbol(uint256, uint256, uint256) external;

    function addToInventory(uint256, uint256, uint256) external;

    function isPositionEmpty(uint256, uint256) external view returns (bool);

    function getEmptyPosition(uint256) external view returns (uint256[] memory);

    function skipDeposit(uint256) external;

    function countSymbol(uint256, uint256) external view returns (uint256);

    function boostPayout(uint256, uint256, int256) external;

    function updateCountSpin(uint256, uint256, uint256) external;

    function getProp(uint256, uint256) external view returns (uint256);

    function getPayout(uint256, uint256) external view returns (int256);

    function findPosition(uint256, uint256) external returns (uint256[] memory);
    function updateBalance(uint256 id, int256 coin) external returns(bool);
    function getInitialPayout(uint256) external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Symbols {
    enum Symbols {
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
    function findSymbol(uint256 index) public pure returns (Symbols) {
        if (index == 1) return Symbols.A1;
        if (index == 2) return Symbols.A2;
        if (index == 3) return Symbols.A3;
        if (index == 4) return Symbols.B1;
        if (index == 5) return Symbols.B2;
        if (index == 6) return Symbols.B3;
        if (index == 7) return Symbols.B4;
        if (index == 8) return Symbols.B5;
        if (index == 9) return Symbols.B6;
        if (index == 10) return Symbols.B7;
        if (index == 11) return Symbols.B8;
        if (index == 12) return Symbols.B9;
        if (index == 13) return Symbols.B10;
        if (index == 14) return Symbols.B11;
        if (index == 15) return Symbols.B12;
        if (index == 16) return Symbols.B13;
        if (index == 17) return Symbols.B14;
        if (index == 18) return Symbols.B15;
        if (index == 19) return Symbols.B16;
        if (index == 20) return Symbols.C1;
        if (index == 21) return Symbols.C2;
        if (index == 22) return Symbols.C3;
        if (index == 23) return Symbols.C4;
        if (index == 24) return Symbols.C5;
        if (index == 25) return Symbols.C6;
        if (index == 26) return Symbols.C7;
        if (index == 27) return Symbols.C8;
        if (index == 28) return Symbols.C9;
        if (index == 29) return Symbols.C10;
        if (index == 30) return Symbols.C11;
        if (index == 31) return Symbols.C12;
        if (index == 32) return Symbols.C13;
        if (index == 33) return Symbols.C14;
        if (index == 34) return Symbols.C15;
        if (index == 35) return Symbols.C16;
        if (index == 36) return Symbols.C17;
        if (index == 37) return Symbols.C18;
        if (index == 38) return Symbols.C19;
        if (index == 39) return Symbols.D1;
        if (index == 40) return Symbols.D2;
        if (index == 41) return Symbols.D3;
        if (index == 42) return Symbols.D4;
        if (index == 43) return Symbols.D5;
        if (index == 44) return Symbols.D6;
        if (index == 45) return Symbols.D7;
        if (index == 46) return Symbols.D8;
        if (index == 47) return Symbols.E1;
        if (index == 48) return Symbols.E2;
        if (index == 49) return Symbols.E3;
        if (index == 50) return Symbols.E4;
        if (index == 51) return Symbols.E5;
        if (index == 52) return Symbols.F1;
        if (index == 53) return Symbols.F2;
        if (index == 54) return Symbols.F3;
        if (index == 55) return Symbols.F4;
        if (index == 56) return Symbols.G1;
        if (index == 57) return Symbols.G2;
        if (index == 58) return Symbols.G3;
        if (index == 59) return Symbols.G4;
        if (index == 60) return Symbols.G5;
        if (index == 61) return Symbols.G6;
        if (index == 62) return Symbols.G7;
        if (index == 63) return Symbols.G8;
        if (index == 64) return Symbols.H1;
        if (index == 65) return Symbols.H2;
        if (index == 66) return Symbols.H3;
        if (index == 67) return Symbols.H4;
        if (index == 68) return Symbols.H5;
        if (index == 69) return Symbols.H6;
        if (index == 70) return Symbols.H7;
        if (index == 71) return Symbols.H8;
        if (index == 72) return Symbols.H9;
        if (index == 73) return Symbols.H10;
        if (index == 74) return Symbols.H11;
        if (index == 75) return Symbols.H12;
        if (index == 76) return Symbols.I1;
        if (index == 77) return Symbols.J1;
        if (index == 78) return Symbols.J2;
        if (index == 79) return Symbols.K1;
        if (index == 80) return Symbols.K2;
        if (index == 81) return Symbols.L1;
        if (index == 82) return Symbols.L2;
        if (index == 83) return Symbols.L3;
        if (index == 84) return Symbols.M1;
        if (index == 85) return Symbols.M2;
        if (index == 86) return Symbols.M3;
        if (index == 87) return Symbols.M4;
        if (index == 88) return Symbols.M5;
        if (index == 89) return Symbols.M6;
        if (index == 90) return Symbols.M7;
        if (index == 91) return Symbols.M8;
        if (index == 92) return Symbols.M9;
        if (index == 93) return Symbols.M10;
        if (index == 94) return Symbols.M11;
        if (index == 95) return Symbols.M12;
        if (index == 96) return Symbols.M13;
        if (index == 97) return Symbols.M14;
        if (index == 98) return Symbols.M15;
        if (index == 99) return Symbols.M16;
        if (index == 100) return Symbols.M17;
        if (index == 101) return Symbols.M18;
        if (index == 102) return Symbols.N1;
        if (index == 103) return Symbols.O1;
        if (index == 104) return Symbols.O2;
        if (index == 105) return Symbols.O3;
        if (index == 106) return Symbols.O4;
        if (index == 107) return Symbols.O5;
        if (index == 108) return Symbols.P1;
        if (index == 109) return Symbols.P2;
        if (index == 110) return Symbols.P3;
        if (index == 111) return Symbols.P4;
        if (index == 112) return Symbols.P5;
        if (index == 113) return Symbols.P6;
        if (index == 114) return Symbols.P7;
        if (index == 115) return Symbols.R1;
        if (index == 116) return Symbols.R2;
        if (index == 117) return Symbols.R3;
        if (index == 118) return Symbols.R4;
        if (index == 119) return Symbols.R5;
        if (index == 120) return Symbols.R6;
        if (index == 121) return Symbols.R7;
        if (index == 122) return Symbols.S1;
        if (index == 123) return Symbols.S2;
        if (index == 124) return Symbols.S3;
        if (index == 125) return Symbols.S4;
        if (index == 126) return Symbols.S5;
        if (index == 127) return Symbols.S6;
        if (index == 128) return Symbols.S7;
        if (index == 129) return Symbols.S8;
        if (index == 130) return Symbols.S9;
        if (index == 131) return Symbols.S10;
        if (index == 132) return Symbols.S11;
        if (index == 133) return Symbols.S12;
        if (index == 134) return Symbols.T1;
        if (index == 135) return Symbols.T2;
        if (index == 136) return Symbols.T3;
        if (index == 137) return Symbols.T4;
        if (index == 138) return Symbols.T5;
        if (index == 139) return Symbols.T6;
        if (index == 140) return Symbols.T7;
        if (index == 141) return Symbols.T8;
        if (index == 142) return Symbols.T9;
        if (index == 143) return Symbols.U1;
        if (index == 144) return Symbols.V1;
        if (index == 145) return Symbols.V2;
        if (index == 146) return Symbols.V3;
        if (index == 147) return Symbols.W1;
        if (index == 148) return Symbols.W2;
        if (index == 149) return Symbols.W3;
        if (index == 150) return Symbols.W4;
        if (index == 151) return Symbols.W5;
        if (index == 152) return Symbols.W6;

        // If index is out of range, return an invalid symbol
        revert("Invalid index");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

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
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
 * ====
 */
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
    function remove(
        Bytes32ToBytes32Map storage map,
        bytes32 key
    ) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(
        Bytes32ToBytes32Map storage map,
        bytes32 key
    ) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(
        Bytes32ToBytes32Map storage map
    ) internal view returns (uint256) {
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
    function at(
        Bytes32ToBytes32Map storage map,
        uint256 index
    ) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(
        Bytes32ToBytes32Map storage map,
        bytes32 key
    ) internal view returns (bool, bytes32) {
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
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(
            value != 0 || contains(map, key),
            "EnumerableMap: nonexistent key"
        );
        return value;
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
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

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(
        Bytes32ToBytes32Map storage map
    ) internal view returns (bytes32[] memory) {
        return map._keys.values();
    }

    // Bytes32ToIntMap

    struct Bytes32ToIntMap {
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
        Bytes32ToIntMap storage map,
        bytes32 key,
        int256 value
    ) internal returns (bool) {
        return set(map._inner, key, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(
        Bytes32ToIntMap storage map,
        bytes32 key
    ) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(
        Bytes32ToIntMap storage map,
        bytes32 key
    ) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(
        Bytes32ToIntMap storage map
    ) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(
        Bytes32ToIntMap storage map,
        uint256 index
    ) internal view returns (bytes32, int256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, int256(uint256(value)));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(
        Bytes32ToIntMap storage map,
        bytes32 key
    ) internal view returns (bool, int256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, int256(uint256(value)));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(
        Bytes32ToIntMap storage map,
        bytes32 key
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToIntMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (int256) {
        return int256(uint256(get(map._inner, key, errorMessage)));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(
        Bytes32ToIntMap storage map
    ) internal view returns (bytes32[] memory) {
        bytes32[] memory store = keys(map._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintToUintMap

    struct UintToBytes32Map {
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
        UintToBytes32Map storage map,
        uint256 key,
        bytes32 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), value);
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(
        UintToBytes32Map storage map,
        uint256 key
    ) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(
        UintToBytes32Map storage map,
        uint256 key
    ) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(
        UintToBytes32Map storage map
    ) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(
        UintToBytes32Map storage map,
        uint256 index
    ) internal view returns (uint256, bytes32) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), value);
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(
        UintToBytes32Map storage map,
        uint256 key
    ) internal view returns (bool, bytes32) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, value);
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(
        UintToBytes32Map storage map,
        uint256 key
    ) internal view returns (bytes32) {
        return get(map._inner, bytes32(key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToBytes32Map storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        return get(map._inner, bytes32(key), errorMessage);
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(
        UintToBytes32Map storage map
    ) internal view returns (uint256[] memory) {
        bytes32[] memory store = keys(map._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(
        Bytes32ToUintMap storage map,
        bytes32 key
    ) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(
        Bytes32ToUintMap storage map,
        bytes32 key
    ) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(
        Bytes32ToUintMap storage map
    ) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(
        Bytes32ToUintMap storage map,
        uint256 index
    ) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(
        Bytes32ToUintMap storage map,
        bytes32 key
    ) internal view returns (bool, uint256) {
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
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key
    ) internal view returns (uint256) {
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

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(
        Bytes32ToUintMap storage map
    ) internal view returns (bytes32[] memory) {
        bytes32[] memory store = keys(map._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(
        UintToUintMap storage map,
        uint256 key
    ) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(
        UintToUintMap storage map,
        uint256 key
    ) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(
        UintToUintMap storage map,
        uint256 index
    ) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(
        UintToUintMap storage map,
        uint256 key
    ) internal view returns (bool, uint256) {
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
    function get(
        UintToUintMap storage map,
        uint256 key
    ) internal view returns (uint256) {
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

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(
        UintToUintMap storage map
    ) internal view returns (uint256[] memory) {
        bytes32[] memory store = keys(map._inner);
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

library Helper {
    function getAdjacentPositions(uint256 position)
        public
        pure
        returns (uint256[] memory)
    {
        uint256[] memory adjacentPositions = new uint256[](8);
        // Define the dimensions of the array
        uint8 numRows = 4;
        uint8 numCols = 5;
        uint8 count = 0;
        // Calculate the row and column of the known position
        uint256 row = position / numCols;
        uint256 col = position % numCols;
        // Calculate the adjacent positions

        // Up
        if (row > 0) {
            adjacentPositions[count] = position - numCols;
            if (
                adjacentPositions[count] != 0 ||
                adjacentPositions[count] == 0 &&
                (position == 1 || position == 5 || position == 6)
            ) {
                ++count;
            }
        }

        // Down
        if (row < numRows - 1) {
            adjacentPositions[count] = position + numCols;
            ++count;
        }

        // Left
        if (col > 0) {
            adjacentPositions[count] = position - 1;
            if (
                adjacentPositions[count] != 0 ||
                adjacentPositions[count] == 0 &&
                (position == 1 || position == 5 || position == 6)
            ) {
                ++count;
            }
        }

        // Right
        if (col < numCols - 1) {
            adjacentPositions[count] = position + 1;
            ++count;
        }

        // Up-Left
        if (row > 0 && col > 0) {
            adjacentPositions[count] = (position - numCols - 1);
            if (
                adjacentPositions[count] != 0 ||
                adjacentPositions[count] == 0 &&
                (position == 1 || position == 5 || position == 6)
            ) {
                ++count;
            }
        }

        // Up-Right
        if (row > 0 && col < numCols - 1) {
            adjacentPositions[count] = (position - numCols + 1);
            if (
                adjacentPositions[count] != 0 ||
                adjacentPositions[count] == 0 &&
                (position == 1 || position == 5 || position == 6)
            ) {
                ++count;
            }
        }

        // Down-Left
        if (row < numRows - 1 && col > 0) {
            adjacentPositions[count] = (position + numCols - 1);
            ++count;
        }

        // Down-Right
        if (row < numRows - 1 && col < numCols - 1) {
            adjacentPositions[count] = (position + numCols + 1);
            ++count;
        }

        uint256[] memory pos = new uint256[](count);

        for (uint256 i = 0; i < count; ++i) {
            pos[i] = adjacentPositions[i];
        }
        return pos;
    }

    function getArrowPointed(uint256 position, string memory direction)
        public
        pure
        returns (uint256[] memory)
    {
        uint8 numCols = 5;
        uint256[] memory pointedPositions = new uint256[](4);

        // Calculate the row and column of the known position
        uint256 row = position / numCols;
        uint256 col = position % numCols;
        uint256 size = 0;
        // Up
        if (keccak256(bytes(direction)) == keccak256(bytes("up"))) {
            for (uint256 i = row; i > 0; --i) {
                pointedPositions[size] = position - 5 * i;
                size++;
            }
        }
        // Down
        else if (keccak256(bytes(direction)) == keccak256(bytes("down"))) {
            for (uint256 i = 1; i < 4 - row; i++) {
                pointedPositions[size] = position + 5 * i;
                size++;
            }
        }
        // Left
        else if (keccak256(bytes(direction)) == keccak256(bytes("left"))) {
            for (uint256 i = 1; i <= col; i++) {
                pointedPositions[size] = position - 1 * i;
                size++;
            }
        }
        // Right
        else if (keccak256(bytes(direction)) == keccak256(bytes("right"))) {
            for (uint256 i = 1; i <= 4 - col; i++) {
                pointedPositions[size] = position + 1 * i;
                size++;
            }
        }
        // Up-Left
        else if (keccak256(bytes(direction)) == keccak256(bytes("upleft"))) {
            uint256 length = row < col ? row : col;
            for (uint256 i = 1; i <= length; i++) {
                pointedPositions[size] = position - 6 * i;
                size++;
            }
        }
        // Up-Right
        else if (keccak256(bytes(direction)) == keccak256(bytes("upright"))) {
            uint256 length = row < 4 - col ? row : 4 - col;
            for (uint256 i = 1; i <= length; i++) {
                pointedPositions[size] = position - 4 * i;
                size++;
            }
        }
        // Down-Left
        else if (keccak256(bytes(direction)) == keccak256(bytes("downleft"))) {
            uint256 length = col < 3 - row ? col : 3 - row;
            for (uint256 i = 1; i <= length; i++) {
                pointedPositions[size] = position + 4 * i;
                size++;
            }
        }
        // Down-Right
        else if (keccak256(bytes(direction)) == keccak256(bytes("downright"))) {
            uint256 length = 4 - col < 3 - row ? 4 - col : 3 - row;
            for (uint256 i = 1; i <= length; i++) {
                pointedPositions[size] = position + 6 * i;
                size++;
            }
        }

        uint256[] memory result = new uint256[](size);
        for (uint256 i = 0; i < size; i++) {
            result[i] = pointedPositions[i];
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Random {
    function random() public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        block.difficulty,
                        blockhash(block.number - 1)
                    )
                )
            ) % 100;
    }

    function randomRange(
        uint256 range,
        uint256 count
    ) public view returns (uint256[] memory) {
        uint256[] memory randomNumbers = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            randomNumbers[i] =
                uint256(
                    keccak256(
                        abi.encodePacked(
                            msg.sender,
                            block.difficulty,
                            blockhash(block.number - 1),
                            i
                        )
                    )
                ) %
                range;
        }

        return randomNumbers;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./utils/EnumerableMap.sol";
import "./utils/Random.sol";
import "./interfaces/IBaseLogic.sol";
import "./interfaces/IGame.sol";
import "./Symbols.sol";
import "./utils/helper.sol";

contract VeryRareSymbols {
    IBaseLogic public baseLogic;
    ICOGGame public gameMap;
    using Symbols for Symbols.Symbols;

    constructor(IBaseLogic _base) {
        baseLogic = _base;
        gameMap = ICOGGame(_base.gameMap());
    }

    function checkSymbol(
        uint256 id,
        uint256 position,
        uint256 index
    ) external returns (int256 coin) {
        if (index == 40) {
            coin += d2(id, position);
        } else if (index == 48) {
            coin += e2(id, position);
        } else if (index == 59) {
            coin += g4(id, position, "down");
        } else if (index == 93) {
            coin += m10(id, position);
        } else if (index == 111) {
            coin += p4(id, position);
        } else if (index == 147) {
            coin += w1(id, position);
        } else if (index == 149) {
            coin += w3(id, position);
        }
    }

    function d2(uint256 id, uint256 position) internal returns (int256 coin) {
        //TODO count total diamonds in the spin
    }

    function g4(
        uint256 id,
        uint256 position,
        string memory direction
    ) internal returns (int256 coin) {
        return baseLogic.arrow(id, position, direction, 3);
    }

    function e2(uint256 id, uint256 position) internal returns (int256 coin) {
        uint256[] memory adjacentPosition = Helper.getAdjacentPositions(
            position
        );
        for (uint8 i = 0; i < adjacentPosition.length; ++i) {
            uint256 adjPosition = adjacentPosition[i];
            Symbols.Symbols adjSymbol = Symbols.findSymbol(
                gameMap.atPosition(id, adjPosition)
            );
            if (
                adjSymbol == Symbols.Symbols.C19 ||
                adjSymbol == Symbols.Symbols.W5 ||
                adjSymbol == Symbols.Symbols.H2 ||
                adjSymbol == Symbols.Symbols.H3 ||
                adjSymbol == Symbols.Symbols.H4 ||
                adjSymbol == Symbols.Symbols.H5 ||
                adjSymbol == Symbols.Symbols.H6 ||
                adjSymbol == Symbols.Symbols.H7 ||
                adjSymbol == Symbols.Symbols.H8
            ) {
                gameMap.destroySymbol(id, adjPosition);
                coin += 1;
            }
        }
    }

    function m10(uint256 id, uint256 position)
        internal
        view
        returns (int256 coin)
    {
        uint256[] memory adjacentPosition = Helper.getAdjacentPositions(
            position
        );
        for (uint8 i = 0; i < adjacentPosition.length; ++i) {
            uint256 adjPosition = adjacentPosition[i];
            Symbols.Symbols adjSymbol = Symbols.findSymbol(
                gameMap.atPosition(id, adjPosition)
            );
            int256 payout = gameMap.getPayout(id, adjPosition);
            coin += 7 * payout;
            // TODO destroy all adj symbols
        }
    }

    function p4(uint256 id, uint256 position) internal returns (int256 coin) {
        uint256[] memory adjacentPosition = Helper.getAdjacentPositions(
            position
        );
        for (uint8 i = 0; i < adjacentPosition.length; ++i) {
            uint256 adjPosition = adjacentPosition[i];
            Symbols.Symbols adjSymbol = Symbols.findSymbol(
                gameMap.atPosition(id, adjPosition)
            );
            if (
                adjSymbol == Symbols.Symbols.A2 ||
                adjSymbol == Symbols.Symbols.B9 ||
                adjSymbol == Symbols.Symbols.C14 ||
                adjSymbol == Symbols.Symbols.O2
            ) {
                coin += 1;
            } else if (adjSymbol == Symbols.Symbols.L2) {
                coin += 1;
                coin += baseLogic.l2_destroy(id, adjPosition);
            } else if (adjSymbol == Symbols.Symbols.S1) {
                coin += 1;
                coin += baseLogic.s1_destroy(id, adjPosition);
            } else if (adjSymbol == Symbols.Symbols.T8) {
                coin += 1;
                coin += baseLogic.t8_destroy(id, adjPosition);
            } else if (adjSymbol == Symbols.Symbols.M9) {
                coin += baseLogic.m9_destroy(id, adjPosition);
            }
        }
    }

    function w1(uint256 id, uint256 position) internal returns (int256 coin) {
        //TODO count watermelons
    }

    function w3(uint256 id, uint256 position)
        internal
        view
        returns (int256 coin)
    {
        int256 highestPayout;
        uint256[] memory adjacentPosition = Helper.getAdjacentPositions(
            position
        );
        for (uint8 i = 0; i < adjacentPosition.length; ++i) {
            uint256 adjPosition = adjacentPosition[i];
            int256 payout = gameMap.getPayout(id, adjPosition);
            highestPayout = highestPayout > payout ? highestPayout : payout;
        }
        coin += highestPayout;
    }
}