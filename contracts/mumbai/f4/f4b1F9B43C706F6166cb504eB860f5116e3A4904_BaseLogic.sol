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
import "./utils/Random.sol";
import "./interfaces/ICOGGame.sol";
import "./interfaces/ICoGSymbols.sol";
import "./Symbols.sol";
import "./utils/helper.sol";

contract BaseLogic {
    using EnumerableSet for EnumerableSet.UintSet;
    using Symbols for Symbols.ID;

    ICOGGame public gameMap;
    ICoGSymbols public gameSymbol;

    EnumerableSet.UintSet private adjacentPositions;

    function config(ICOGGame _game, ICoGSymbols _symbol) public {
        gameMap = _game;
        gameSymbol = _symbol;
    }

    function arrow(
        uint256 id,
        uint256 position,
        string memory direction,
        uint8 sort
    ) public returns (int256 coin) {
        uint256[] memory listPositionPointedTo = Helper.getArrowPointed(
            position,
            direction
        );
        for (uint8 i = 0; i < listPositionPointedTo.length; ++i) {
            uint256 positionPointedTo = listPositionPointedTo[i];
            Symbols.ID symbolPointed = Symbols.findSymbol(
                gameMap.atPosition(id, positionPointedTo)
            );
            if (symbolPointed == Symbols.ID.T1) {
                t1_destroy(id, positionPointedTo);
            } else {
                int256 payout = gameMap.getPayout(id, positionPointedTo);
                if (sort == 1) {
                    coin += 2 * payout;
                } else if (sort == 2) {
                    coin += 3 * payout;
                } else if (sort == 3) {
                    coin += 4 * payout;
                }
            }
            if (
                symbolPointed == Symbols.ID.A1 || symbolPointed == Symbols.ID.P2
            ) {
                gameMap.boostPayout(id, positionPointedTo, 1);
            }
        }
    }

    function b1_destroy(uint256 id, uint256 position) public {
        gameMap.addToInventory(id, uint256(Symbols.ID.B2), 1); // add banana peel
        gameMap.destroySymbol(id, position);
    }

    function b12_destroy(
        uint256 id,
        uint256 position
    ) public returns (int256 coin) {
        gameMap.destroySymbol(id, position);
        coin += 39;
    }

    function j1_remove(uint256 id) public {
        //TODO gadd remove token
    }

    function f4_destroy(uint256 id, uint256 position) public {
        gameMap.destroySymbol(id, position);
        gameMap.addToInventory(id, uint256(Symbols.ID.E2), 1);
    }

    function o5_remove(uint256 id, uint256 position) public {
        gameMap.removeSymbol(id, position);
        gameMap.addToInventory(id, uint256(Symbols.ID.P3), 1);
    }

    function t1_destroy(
        uint256 id,
        uint256 position
    ) public returns (int256 coin) {
        gameMap.destroySymbol(id, position);
        coin += 10;
    }

    function l2_destroy(
        uint256 id,
        uint256 position
    ) public returns (int256 coin) {
        coin += 15;
        gameMap.destroySymbol(id, position);
    }

    function o3_destroy(uint256 id, uint256 position) public {
        gameMap.destroySymbol(id, position);

        uint256[] memory randSymbol = Random.randomRange(
            gameSymbol.categoryLength("minerals"),
            1
        );
        gameMap.addToInventory(id, gameSymbol.at("minerals", randSymbol[0]), 2);
    }

    function p6_destroy(
        uint256 id,
        uint256 position
    ) public returns (int256 coin) {
        gameMap.destroySymbol(id, position);
        coin += 10;
    }

    function u1_destroy(uint256 id, uint256 position) public {
        gameMap.destroySymbol(id, position);
        gameMap.addToInventory(id, uint256(Symbols.ID.S10), 1);
    }

    function m12_destroy(uint256 id, uint256 position) public {
        gameMap.removeSymbol(id, position);
        // TODO add mining pick item
    }

    function m16_destroy(uint256 id, uint256 position) public {
        gameMap.removeSymbol(id, position);
        gameMap.addToInventory(id, uint256(Symbols.ID.C4), 3);
    }

    function b10_destroy(uint256 id, uint256 position) public {
        gameMap.destroySymbol(id, position);
        uint256[] memory randSymbol = Random.randomRange(
            gameSymbol.categoryLength("minerals"),
            1
        );
        gameMap.addToInventory(id, gameSymbol.at("minerals", randSymbol[0]), 3);
    }

    function b11_destroy(uint256 id, uint256 position) public {
        gameMap.addToInventory(id, uint256(Symbols.ID.S10), 2);
        gameMap.destroySymbol(id, position);
    }

    function c12_destroy(uint256 id, uint256 position) public {
        gameMap.destroySymbol(id, position);
        gameMap.addToInventory(id, uint256(Symbols.ID.C13), 2);
    }

    function g1_destroy(
        uint256 id,
        uint256 position
    ) public returns (int256 coin) {
        uint256 countSpin = gameMap.getProp(id, position);
        coin += int256(countSpin) * 2;
        gameMap.destroySymbol(id, position);
    }

    function m9_destroy(
        uint256 id,
        uint256 position
    ) public returns (int256 coin) {
        coin += 100;
        gameMap.destroySymbol(id, position);
    }

    function p1_destroy(uint256 id, uint256 position) public {
        gameMap.destroySymbol(id, position);
        gameMap.addToInventory(id, uint256(Symbols.ID.S4), 1);
    }

    function p5_destroy(uint256 id, uint256 position) public {
        gameMap.destroySymbol(id, position);
        gameMap.addToInventory(id, uint256(Symbols.ID.C1), 7);
    }

    function p7_remove(
        uint256 id,
        uint256 position
    ) public returns (int256 coin) {
        // TODO Add reroll token
    }

    function r4_destroy(uint256 id, uint256 position) public {
        gameMap.destroySymbol(id, position);
        //TODO add removal token
    }

    function s1_destroy(
        uint256 id,
        uint256 position
    ) public returns (int256 coin) {
        gameMap.destroySymbol(id, position);
        coin += 30;
    }

    function s2_remove(
        uint256 id,
        uint256 position
    ) public returns (int256 coin) {
        coin += 10;
        gameMap.removeSymbol(id, position);
    }

    function t3_destroy(
        uint256 id,
        uint256 position
    ) public returns (int256 coin) {
        uint256 countSpin = gameMap.getProp(id, position);
        gameMap.destroySymbol(id, position);
        coin += int256(4 * countSpin);
    }

    function t7_destroy(uint256 id, uint256 position) public {
        gameMap.destroySymbol(id, position);
        gameMap.addToInventory(id, uint256(Symbols.ID.S10), 4);
    }

    function w2_destroy(
        uint256 id,
        uint256 position
    ) public returns (int256 coin) {
        gameMap.destroySymbol(id, position);
        coin += 10;
    }

    function t8_destroy(
        uint256 id,
        uint256 position
    ) public returns (int256 coin) {
        gameMap.destroySymbol(id, position);
        coin += 50;
    }

    function void_destroy(
        uint256 id,
        uint256 position
    ) public returns (int256 coin) {
        gameMap.destroySymbol(id, position);
        coin += 8;
    }

    //  TODO destroy all adj
    function destroyAllAdj(
        uint256 id,
        uint256[] memory adjPosition
    ) public returns (int256 coin) {
        for (uint256 i = 0; i < adjPosition.length; ++i) {
            int256 payout = gameMap.getPayout(id, adjPosition[i]);
            coin += 7 * payout; 
            Symbols.ID adjSymbol = Symbols.findSymbol(
                gameMap.atPosition(id, adjPosition[i])
            );
            if (adjSymbol == Symbols.ID.B1) {
                b1_destroy(id, adjPosition[i]);
            } else if (adjSymbol == Symbols.ID.B12) {
                coin += b12_destroy(id, adjPosition[i]);
            } else if (adjSymbol == Symbols.ID.F4) {
                f4_destroy(id, adjPosition[i]);
            } else if (adjSymbol == Symbols.ID.T1) {
                coin += t1_destroy(id, adjPosition[i]);
            } else if (adjSymbol == Symbols.ID.L2) {
                coin += l2_destroy(id, adjPosition[i]);
            } else if (adjSymbol == Symbols.ID.O3) {
                o3_destroy(id, adjPosition[i]);
            } else if (adjSymbol == Symbols.ID.P6) {
                coin += p6_destroy(id, adjPosition[i]);
            } else if (adjSymbol == Symbols.ID.U1) {
                u1_destroy(id, adjPosition[i]);
            } else if (adjSymbol == Symbols.ID.M12) {
                m12_destroy(id, adjPosition[i]);
            } else if (adjSymbol == Symbols.ID.M16) {
                m16_destroy(id, adjPosition[i]);
            } else if (adjSymbol == Symbols.ID.B10) {
                b10_destroy(id, adjPosition[i]);
            } else if (adjSymbol == Symbols.ID.B11) {
                b11_destroy(id, adjPosition[i]);
            } else if (adjSymbol == Symbols.ID.C12) {
                c12_destroy(id, adjPosition[i]);
            } else if (adjSymbol == Symbols.ID.G1) {
                coin += g1_destroy(id, adjPosition[i]);
            } else if (adjSymbol == Symbols.ID.M9) {
                coin += m9_destroy(id, adjPosition[i]);
            } else if (adjSymbol == Symbols.ID.P1) {
                p1_destroy(id, adjPosition[i]);
            } else if (adjSymbol == Symbols.ID.P5) {
                p5_destroy(id, adjPosition[i]);
            } else if (adjSymbol == Symbols.ID.R4) {
                r4_destroy(id, adjPosition[i]);
            } else if (adjSymbol == Symbols.ID.S1) {
                coin += s1_destroy(id, adjPosition[i]);
            } else if (adjSymbol == Symbols.ID.T3) {
                coin += t3_destroy(id, adjPosition[i]);
            } else if (adjSymbol == Symbols.ID.T7) {
                t7_destroy(id, adjPosition[i]);
            } else if (
                adjSymbol == Symbols.ID.V1 ||
                adjSymbol == Symbols.ID.V2 ||
                adjSymbol == Symbols.ID.V3
            ) {
                coin += void_destroy(id, adjPosition[i]);
            } else if (adjSymbol == Symbols.ID.W2) {
                coin += w2_destroy(id, adjPosition[i]);
            } else if (adjSymbol == Symbols.ID.T8) {
                coin += t8_destroy(id, adjPosition[i]);
            }
        }
    }
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

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface ICoGSymbols {
    function symbolsToString(uint8) external view returns (string memory);

    function symbolsInitPayout(uint8) external view returns (int256);

    function contains(string memory sort, uint256 symbol)
        external
        view
        returns (bool);

    function at(string memory sort, uint256 index)
        external
        view
        returns (uint256);

    function categoryLength(string memory sort) external view returns (uint256);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Helper {
    function getAdjacentPositions(
        uint256 position
    ) public pure returns (uint256[] memory result) {
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
                (adjacentPositions[count] == 0 &&
                    (position == 1 || position == 5 || position == 6))
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
                (adjacentPositions[count] == 0 &&
                    (position == 1 || position == 5 || position == 6))
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
                (adjacentPositions[count] == 0 &&
                    (position == 1 || position == 5 || position == 6))
            ) {
                ++count;
            }
        }

        // Up-Right
        if (row > 0 && col < numCols - 1) {
            adjacentPositions[count] = (position - numCols + 1);
            if (
                adjacentPositions[count] != 0 ||
                (adjacentPositions[count] == 0 &&
                    (position == 1 || position == 5 || position == 6))
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

    function getArrowPointed(
        uint256 position,
        string memory direction
    ) public pure returns (uint256[] memory) {
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