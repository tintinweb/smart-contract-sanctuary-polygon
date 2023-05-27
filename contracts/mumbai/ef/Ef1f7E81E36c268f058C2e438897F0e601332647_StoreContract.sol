/**
 *Submitted for verification at polygonscan.com on 2023-05-26
*/

// SPDX-License-Identifier: MIT

// File: contracts/StoreDataStructure.sol


pragma solidity ^0.8.13;

library StoreDataStructure {
    struct StoreTag{
        uint256 id;
        string name;
        string imageUrl;
        uint256 totalDrop;
    }
    struct StoreItem {
        uint256 itemIndex;
        string itemType;
        string rarity;
        string name;
        string description;
        string IP;
        SimplifiedDropTag drop;
        string imageUrl;
        Supply supply;
        uint256 price;
        Utils utils;
    }
    struct Utils{
        bool consumable;
        Discount discount;
        EarlyAccess earlyAccess;
        string allowPassIdMint;
        string bundle;
        bool isWhitelisted;
    }
    struct Supply{
        uint256 current;
        uint256 max;
    }
    struct Discount{
        uint256 percentage;
        uint256 date;
        string passId;
    }
    struct DropTag{
        uint256 id;
        uint256 storeId;
        string name;
        uint256 date;
        uint256 totalItems;
        Supply supply;
        string imageUrl;
    }
    struct SimplifiedDropTag{
        uint256 id;
        uint256 storeId;
        uint256 date;
        uint256 totalItems;
    }
    struct EarlyAccess{
        string passId;
        uint256 date;
    }
}
// File: contracts/operator-filter-registry/lib/Constants.sol


pragma solidity ^0.8.13;

address constant CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS = 0x000000000000AAeB6D7670E522A718067333cd4E;
address constant CANONICAL_CORI_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

// File: contracts/operator-filter-registry/IOperatorFilterRegistry.sol


pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(address registrant) external;

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external;

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address addr) external;

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(address registrant, address operator, bool filtered) external;

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     */
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     */
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address registrantToSubscribe) external;

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external;

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(address addr) external returns (address registrant);

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(address registrant) external returns (address[] memory);

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external;

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(address addr) external returns (address[] memory);

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address addr) external returns (bool);

    /**
     * @dev Convenience method to compute the code hash of an arbitrary contract
     */
    function codeHashOf(address addr) external returns (bytes32);
}

// File: contracts/operator-filter-registry/OperatorFilterer.sol


pragma solidity ^0.8.13;


/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 *         Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract OperatorFilterer {
    /// @dev Emitted when an operator is not allowed.
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS);

    /// @dev The constructor that is called when the contract is being deployed.
    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    OPERATOR_FILTER_REGISTRY.register(address(this));
                }
            }
        }
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @dev A helper function to check if an operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting contracts
            // may specify their own OperatorFilterRegistry implementations, which may behave differently
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}

// File: contracts/operator-filter-registry/DefaultOperatorFilterer.sol


pragma solidity ^0.8.13;


/**
 * @title  DefaultOperatorFilterer
 * @notice Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.
 * @dev    Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract DefaultOperatorFilterer is OperatorFilterer {
    /// @dev The constructor that is called when the contract is being deployed.
    constructor() OperatorFilterer(CANONICAL_CORI_SUBSCRIPTION, true) {}
}

// File: @openzeppelin/contracts/utils/Counters.sol


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

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/interfaces/IERC2981.sol


// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


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

// File: @openzeppelin/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;


/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/IAccessControl.sol


// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

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
// File: @openzeppelin/contracts/access/AccessControl.sol


// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;





/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}
// File: @openzeppelin/contracts/access/IAccessControlEnumerable.sol


// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/access/AccessControlEnumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;




/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
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
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// File: contracts/WhitelistContract.sol


pragma solidity ^0.8.13;

//import "./StoreContract.sol";

  /**
   * @title WhitelistContract
   * @dev ContractDescription
   * @custom:dev-run-script contracts/WhitelistContract.sol
   */
contract WhitelistContract is AccessControlEnumerable {

    bytes32 private constant MANAGER = keccak256("MANAGER");

    StoreContract private storeContractInstance;
    address public storeContractAddress;

    mapping(address => WhitelistInfo) whitelistAccounts;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) public guaranteeAttemptList;

    constructor(address admin){
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }
    struct WhitelistInfo{
        mapping(uint256 => mapping(uint256 => mapping(uint256 => WhitelistedStoreItem))) whitelistedStoreItemList;
    }
    struct WhitelistedStoreItem{
        uint256 maxMint;
        uint256 date;
        bool isAllowlist;
    }
    struct StoreItemId{
        uint256 storeId;
        uint256 dropId;
        uint256 itemIndex;
    }

    /**
    * @notice Updates the store contract address and instance.
    *
    * @dev This function is used to update the store contract address and create an instance of the StoreContract. 
    * This function can only be called by an account with the DEFAULT_ADMIN_ROLE.
    *
    * _storeContractAddress The new store contract address.
    *
    * The function performs the following steps:
    *
    * - Updates the `storeContractAddress` with the new address provided as a parameter.
    * - Instantiates a new `StoreContract` with the updated address and assigns it to `storeContractInstance`.
    */
    /*
    function setStoreContract(address _storeContractAddress) public onlyRole(DEFAULT_ADMIN_ROLE){
        storeContractAddress = _storeContractAddress;
        storeContractInstance = StoreContract(storeContractAddress);
    }
    */

    /**
    * @notice Retrieves the members of a given role.
    *
    * @dev The function takes a role as a parameter and returns an array of addresses representing the members of that role.
    *
    * @param role A bytes32 value representing the role for which members are to be retrieved.
    *
    * @return A dynamic array of type address[], representing the members of the given role.
    *
    * The function performs the following actions:
    *
    * - Initializes a new dynamic array `members` with a size equal to the number of members in the role (retrieved by `getRoleMemberCount(role)`).
    * - Iterates over the length of the `members` array, filling each index with the address of a member of the role (retrieved by `getRoleMember(role, i)`).
    * - Returns the filled `members` array.
    */
    function getRoleMembers(bytes32 role) public view returns (address[] memory) {
        address[] memory members = new address[](getRoleMemberCount(role));
        for (uint i = 0; i < members.length; i++) {
            members[i] = getRoleMember(role, i);
        }
        return members;
    }

    /**
    * @notice Grants the DEFAULT_ADMIN_ROLE to a specified account.
    *
    * @dev This function allows an account with the DEFAULT_ADMIN_ROLE to assign the same role to another account. 
    * The DEFAULT_ADMIN_ROLE is a powerful role that includes permissions such as setting the base URI of the NFT's metadata and
    * setting the address of the contract for storing items. This function can only be called by an account with the DEFAULT_ADMIN_ROLE.
    *
    * @param account The address of the account to which the DEFAULT_ADMIN_ROLE will be granted.
    *
    * The function performs the following steps:
    *
    * - Invokes the `_grantRole` function from the AccessControl contract in the OpenZeppelin contracts library to assign 
    * the DEFAULT_ADMIN_ROLE to the account specified by the `account` parameter.
    *
    */
    function grantAdminRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE){
        _grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
    * @notice Revokes the DEFAULT_ADMIN_ROLE from a specified account.
    *
    * @dev This function allows an account with the DEFAULT_ADMIN_ROLE to revoke the same role from another account. 
    * The DEFAULT_ADMIN_ROLE is a powerful role that includes permissions such as setting the base URI of the NFT's metadata and
    * setting the address of the contract for storing items. This function can only be called by an account with the DEFAULT_ADMIN_ROLE.
    *
    * @param account The address of the account from which the DEFAULT_ADMIN_ROLE will be revoked.
    *
    * The function performs the following steps:
    *
    * - Invokes the `_revokeRole` function from the AccessControl contract in the OpenZeppelin contracts library to revoke
    * the DEFAULT_ADMIN_ROLE from the account specified by the `account` parameter.
    *
    */
    function revokeAdminRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE){
        _revokeRole(DEFAULT_ADMIN_ROLE, account);
    } 
    
    /**
    * @notice Grants the MANAGER role to a specified account.
    *
    * @dev This function allows an account with the DEFAULT_ADMIN_ROLE to grant the MANAGER role to another account.
    * The MANAGER role is a role with permissions for minting tokens, creating, modifying, and deleting items and store entities.
    * This function can only be called by an account with the DEFAULT_ADMIN_ROLE.
    *
    * @param account The address of the account which will be granted the MANAGER role.
    *
    * The function performs the following steps:
    *
    * - Invokes the `_grantRole` function from the AccessControl contract in the OpenZeppelin contracts library to grant
    * the MANAGER role to the account specified by the `account` parameter.
    *
    */
    function grantManagerRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE){
        _grantRole(MANAGER, account);
    }

    /**
    * @notice Revokes the MANAGER role from a specified account.
    *
    * @dev This function allows an account with the DEFAULT_ADMIN_ROLE to revoke the MANAGER role from another account.
    * The MANAGER role is a role with permissions for minting tokens, creating, modifying, and deleting items and store entities.
    * This function can only be called by an account with the DEFAULT_ADMIN_ROLE.
    *
    * @param account The address of the account which will have the MANAGER role revoked.
    *
    * The function performs the following steps:
    *
    * - Invokes the `_revokeRole` function from the AccessControl contract in the OpenZeppelin contracts library to revoke
    * the MANAGER role from the account specified by the `account` parameter.
    *
    */
    function revokeManagerRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE){
        _revokeRole(MANAGER, account);
    }

    /**
    * @notice Add addresses to the whitelist.
    *
    * @dev This function is used to whitelist a set of addresses for specific store items.
    * This function can only be called by an account with the MANAGER role.
    *
    * @param accounts An array of addresses to be added to the whitelist.
    * @param whitelist An array of WhitelistedStoreItem structures containing the details for each account's whitelisting.
    * @param storeItemId An array of StoreItemId structures containing the details of each store item for which the accounts are being whitelisted.
    *
    * The function performs the following steps:
    *
    * - Loops through each account in the 'accounts' parameter.
    * - For each account, it assigns the corresponding WhitelistedStoreItem structure to the account's 'whitelistedStoreItemList' mapping in the 'whitelistAccounts' mapping.
    * - The WhitelistedStoreItem is assigned based on the StoreItemId details.
    */
    function AddWhiteListAddress(address[] memory accounts, WhitelistedStoreItem[] memory whitelist, StoreItemId[] memory storeItemId) public onlyRole(MANAGER){
        for (uint256 i = 0; i < accounts.length; i++){
            whitelistAccounts[accounts[i]].whitelistedStoreItemList[storeItemId[i].storeId][storeItemId[i].dropId][storeItemId[i].itemIndex] = whitelist[i];
        }
    }

    /**
    * @notice Remove store items from the whitelist for specified accounts.
    *
    * @dev This function is used to remove specific store items from the whitelist for a set of addresses.
    * This function can only be called by an account with the MANAGER role.
    *
    * @param accounts An array of addresses to have items removed from the whitelist.
    * @param storeItemId An array of StoreItemId structures containing the details of each store item to be removed from the whitelist.
    *
    * The function performs the following steps:
    *
    * - Loops through each account in the 'accounts' parameter.
    * - For each account, it deletes the corresponding store item from the account's 'whitelistedStoreItemList' mapping in the 'whitelistAccounts' mapping.
    * - The store item to be deleted is based on the StoreItemId details.
    */
    function RemoveWhitelistStoreItem(address[] memory accounts, StoreItemId[] memory storeItemId) public onlyRole(MANAGER){
        for (uint256 i = 0; i < accounts.length; i++){
            delete whitelistAccounts[accounts[i]].whitelistedStoreItemList[storeItemId[i].storeId][storeItemId[i].dropId][storeItemId[i].itemIndex];
        }
    }

    /**
    * @notice Decrease the maximum mint limit for a specific whitelisted store item of a specific account.
    *
    * @dev This function is used to decrease the maximum mint limit of a specific whitelisted store item for a specific account.
    * This function can only be called by an account with the MANAGER role.
    *
    * @param account The account whose whitelisted store item's maximum mint limit is to be decreased.
    * @param storeId The ID of the store where the item is located.
    * @param dropId The ID of the drop where the item is located.
    * @param itemIndex The index of the item in the store and drop.
    *
    * The function performs the following steps:
    *
    * - It accesses the 'whitelistedStoreItemList' mapping of the account in the 'whitelistAccounts' mapping using the storeId, dropId, and itemIndex parameters.
    * - It then decreases the 'maxMint' field of the whitelisted store item by one.
    */
    function DeductMintAttempt(address account, uint256 storeId, uint256 dropId, uint256 itemIndex) external onlyRole(MANAGER){
        whitelistAccounts[account].whitelistedStoreItemList[storeId][dropId][itemIndex].maxMint--;
    }

    /**
    * @notice Returns the details of a specific whitelisted store item for a specific account.
    *
    * @dev This function retrieves the details of a whitelisted store item for a specific account. 
    *
    * @param account The account whose whitelisted store item details are to be retrieved.
    * @param storeId The ID of the store where the item is located.
    * @param dropId The ID of the drop where the item is located.
    * @param itemIndex The index of the item in the store and drop.
    *
    * @return WhitelistedStoreItem A WhitelistedStoreItem struct that contains the details of the whitelisted store item.
    *
    * The function performs the following steps:
    *
    * - It accesses the 'whitelistedStoreItemList' mapping of the account in the 'whitelistAccounts' mapping using the storeId, dropId, and itemIndex parameters.
    * - It then returns the whitelisted store item.
    */
    function GetWhiteListInfo(address account, uint256 storeId, uint256 dropId, uint256 itemIndex) public view returns(WhitelistedStoreItem memory){
        return whitelistAccounts[account].whitelistedStoreItemList[storeId][dropId][itemIndex];
    }

    /**
    * @notice Sets the number of guaranteed attempts for a specific item in a specific store and drop.
    *
    * @dev This function allows the manager to set the number of guaranteed attempts to mint a specific item in a store and drop.
    *
    * @param attempt The number of guaranteed attempts to be set.
    * @param storeId The ID of the store where the item is located.
    * @param dropId The ID of the drop where the item is located.
    * @param itemIndex The index of the item in the store and drop.
    *
    * The function performs the following steps:
    *
    * - It checks if the caller of the function has the manager role using the onlyRole modifier.
    * - It sets the number of guaranteed attempts for the specified item in the 'guaranteeAttemptList' mapping.
    */
    function SetGuaranteeAttempt(uint256 attempt, uint256 storeId, uint256 dropId, uint256 itemIndex) public onlyRole(MANAGER){
        guaranteeAttemptList[storeId][dropId][itemIndex] = attempt;
    }

    /**
    * @notice Decreases the number of guaranteed attempts for a specific item in a specific store and drop by one.
    *
    * @dev This function allows the manager to deduct the number of guaranteed attempts to mint a specific item in a store and drop.
    *
    * @param storeId The ID of the store where the item is located.
    * @param dropId The ID of the drop where the item is located.
    * @param itemIndex The index of the item in the store and drop.
    *
    * The function performs the following steps:
    *
    * - It checks if the caller of the function has the manager role using the onlyRole modifier.
    * - It decreases the number of guaranteed attempts for the specified item in the 'guaranteeAttemptList' mapping by one.
    */
    function DeductGuaranteeAttempt(uint256 storeId, uint256 dropId, uint256 itemIndex) external onlyRole(MANAGER){
        guaranteeAttemptList[storeId][dropId][itemIndex]--;
    }

    /**
    * @notice Checks whether an account can purchase a specific item from a store and drop.
    *
    * @dev This function checks if an account has the privilege to purchase a specific item from a specific store and drop.
    *
    *  @param account The address of the account that wants to purchase the item.
    *  @param storeId The ID of the store where the item is located.
    *  @param dropId The ID of the drop where the item is located.
    *  @param itemIndex The index of the item in the store and drop.
    *
    * @return isPurchasable A boolean value indicating whether the item can be purchased by the account.
    * @return isAllowlist A boolean value indicating whether the account is on the allowlist for purchasing the item.
    *
    * The function performs the following steps:
    *
    * - It retrieves the information of the account's whitelisted status for the specified item.
    * - It checks if the maximum allowed minting attempts for the account is greater than 0 and if the current timestamp is later than the allowed purchase date.
    * - If the account is on the allowlist, it checks if the remaining available supply of the item is greater than the guaranteed attempts. If so, it returns true for both isPurchasable and isAllowlist.
    * - If the account is not on the allowlist but is still able to mint, it returns true for isPurchasable and false for isAllowlist.
    * - If the account cannot mint, it returns false for both isPurchasable and isAllowlist.
    */
    function isPurchasable(address account, uint256 storeId, uint256 dropId, uint256 itemIndex) public view returns (bool, bool){
        WhitelistedStoreItem memory whitelistedStoreItem = whitelistAccounts[account].whitelistedStoreItemList[storeId][dropId][itemIndex];
        uint256 timestamp = block.timestamp;
        if (whitelistedStoreItem.maxMint > 0 && timestamp > whitelistedStoreItem.date){
            if (whitelistedStoreItem.isAllowlist){
                StoreDataStructure.Supply memory storeItemSupply = _getStoreItemSupply(storeId, dropId, itemIndex);
                uint256 guaranteeAttempt = guaranteeAttemptList[storeId][dropId][itemIndex];
                uint256 remainingAvailableItem = storeItemSupply.max - storeItemSupply.current;
                if (remainingAvailableItem > guaranteeAttempt)
                    return (true, true);
                else return (false, true);
            }
            else{
                return (true, false);
            }            
        }
        return (false, false);
    }
        
    /**
    * @notice Internal function that gets the supply details of a specific item in a store.
    *
    * @dev This function is used to retrieve the supply details of a specific item from a specified store and drop.
    *
    *  @param storeId The ID of the store from which to retrieve the item's supply details.
    *  @param dropId The ID of the drop from which to retrieve the item's supply details.
    *  @param itemIndex The index of the item in the store and drop.
    *
    * @return _supply The supply details of the specified item.
    *
    * The function performs the following steps:
    *
    * - It calls the storeItemList function from the storeContractInstance contract with the specified storeId, dropId, and itemIndex.
    * - It ignores all return values from the storeItemList function call except for the _supply value, which contains the supply details of the specified item.
    * - It returns the _supply value.
    */
    function _getStoreItemSupply(uint256 storeId, uint256 dropId, uint256 itemIndex) internal view returns (StoreDataStructure.Supply memory){
        
        (,
        ,
        ,
        ,
        ,
        ,
        ,
        , 
        StoreDataStructure.Supply memory _supply, 
        , 
        ) = storeContractInstance.storeItemList(storeId,dropId,itemIndex);

        return _supply;     
    }
    
}
// File: contracts/AccountContract.sol


pragma solidity ^0.8.13;

  /**
   * @title AccountContract
   * @dev ContractDescription
   * @custom:dev-run-script contracts/AccountContract.sol
   */
contract AccountContract is AccessControlEnumerable {

    bytes32 private constant MANAGER = keccak256("MANAGER");

    mapping(address => User) private UserList;

    constructor(address admin){
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    struct User{
        mapping(string => string) info;
    }
    
    /**
    * @notice Fetches the members of a given role.
    *
    * @dev This function retrieves all the members of a specific role by looping over the count of members in that role. 
    * The result is returned as an array of addresses.
    * This function can be called by any account to get the list of addresses that hold a specific role.
    *
    * @param role The role identifier to get the members of.
    *
    * @return members An array of addresses that are assigned to the role specified by the `role` parameter.
    *
    * The function performs the following steps:
    *
    * - Initializes a new dynamic array of addresses with a size equal to the count of the members in the role specified by the `role` parameter.
    * - Loops over each index in the members array and assigns the address of the member at that index in the role to the corresponding index in the `members` array.
    * - Returns the `members` array.
    *
    */
    function getRoleMembers(bytes32 role) public view returns (address[] memory) {
        address[] memory members = new address[](getRoleMemberCount(role));
        for (uint i = 0; i < members.length; i++) {
            members[i] = getRoleMember(role, i);
        }
        return members;
    }

    /**
    * @notice Grants the DEFAULT_ADMIN_ROLE to a specified account.
    *
    * @dev This function allows an account with the DEFAULT_ADMIN_ROLE to assign the same role to another account. 
    * The DEFAULT_ADMIN_ROLE is a powerful role that includes permissions such as setting the base URI of the NFT's metadata and
    * setting the address of the contract for storing items. This function can only be called by an account with the DEFAULT_ADMIN_ROLE.
    *
    * @param account The address of the account to which the DEFAULT_ADMIN_ROLE will be granted.
    *
    * The function performs the following steps:
    *
    * - Invokes the `_grantRole` function from the AccessControl contract in the OpenZeppelin contracts library to assign 
    * the DEFAULT_ADMIN_ROLE to the account specified by the `account` parameter.
    *
    */
    function grantAdminRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE){
        _grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
    * @notice Revokes the DEFAULT_ADMIN_ROLE from a specified account.
    *
    * @dev This function allows an account with the DEFAULT_ADMIN_ROLE to revoke the same role from another account. 
    * The DEFAULT_ADMIN_ROLE is a powerful role that includes permissions such as setting the base URI of the NFT's metadata and
    * setting the address of the contract for storing items. This function can only be called by an account with the DEFAULT_ADMIN_ROLE.
    *
    * @param account The address of the account from which the DEFAULT_ADMIN_ROLE will be revoked.
    *
    * The function performs the following steps:
    *
    * - Invokes the `_revokeRole` function from the AccessControl contract in the OpenZeppelin contracts library to revoke
    * the DEFAULT_ADMIN_ROLE from the account specified by the `account` parameter.
    *
    */
    function revokeAdminRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE){
        _revokeRole(DEFAULT_ADMIN_ROLE, account);
    } 

    /**
    * @notice Grants the MANAGER role to a specified account.
    *
    * @dev This function allows an account with the DEFAULT_ADMIN_ROLE to grant the MANAGER role to another account.
    * The MANAGER role is a role with permissions for minting tokens, creating, modifying, and deleting items and store entities.
    * This function can only be called by an account with the DEFAULT_ADMIN_ROLE.
    *
    * @param account The address of the account which will be granted the MANAGER role.
    *
    * The function performs the following steps:
    *
    * - Invokes the `_grantRole` function from the AccessControl contract in the OpenZeppelin contracts library to grant
    * the MANAGER role to the account specified by the `account` parameter.
    *
    */
    function grantManagerRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE){
        _grantRole(MANAGER, account);
    }

    /**
    * @notice Revokes the MANAGER role from a specified account.
    *
    * @dev This function allows an account with the DEFAULT_ADMIN_ROLE to revoke the MANAGER role from another account.
    * The MANAGER role is a role with permissions for minting tokens, creating, modifying, and deleting items and store entities.
    * This function can only be called by an account with the DEFAULT_ADMIN_ROLE.
    *
    * @param account The address of the account which will have the MANAGER role revoked.
    *
    * The function performs the following steps:
    *
    * - Invokes the `_revokeRole` function from the AccessControl contract in the OpenZeppelin contracts library to revoke
    * the MANAGER role from the account specified by the `account` parameter.
    *
    */
    function revokeManagerRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE){
        _revokeRole(MANAGER, account);
    } 

    /**
    * @notice Updates the specified field in the user's info with a new value.
    *
    * @dev This function is only callable by an account with the `MANAGER` role. It allows updating the user information in the contract.
    * 
    * @param walletAddress The address of the user whose information is to be updated.
    * @param fieldName The name of the field to be updated.
    * @param value The new value to be set for the field.
    *
    * The function performs the following steps:
    *
    * - Checks that the calling account has the `MANAGER` role.
    * - Finds the user associated with `walletAddress` in the `UserList`.
    * - Updates the field specified by `fieldName` in the user's info with the new `value`.
    */
    function setUserInfo(address walletAddress, string memory fieldName, string memory value) public onlyRole(MANAGER){
        UserList[walletAddress].info[fieldName] = value;
    }

    /**
    * @notice Retrieves the value of the specified field in a user's info.
    *
    * @dev This function is only callable by an account with the `MANAGER` role. It allows fetching the user information from the contract.
    * 
    * @param walletAddress The address of the user whose information is to be fetched.
    * @param fieldName The name of the field to be fetched.
    *
    * @return Returns the value of the specified field for the user associated with `walletAddress`.
    *
    * The function performs the following steps:
    *
    * - Checks that the calling account has the `MANAGER` role.
    * - Finds the user associated with `walletAddress` in the `UserList`.
    * - Fetches and returns the value of the field specified by `fieldName` in the user's info.
    */
    function getUserInfo(address walletAddress, string memory fieldName) public view onlyRole(MANAGER) returns (string memory){
        return UserList[walletAddress].info[fieldName];
    }

    /**
    * @notice Retrieves the IRL Wallet address of a user.
    *
    * @dev This function is used to get the IRL wallet address of a user. If no IRL wallet is set, it returns the sender's address as a default.
    *
    * @param sender The address of the user whose IRL Wallet is to be fetched.
    *
    * @return Returns the address of the IRL Wallet associated with `sender`.
    *
    * The function performs the following steps:
    *
    * - Fetches the IRLWallet field from the user's information.
    * - Checks if this field is not empty.
    * - If it is not empty, it converts the IRLWallet info string to an address and assigns it to the IRLWallet variable.
    * - If it is empty, it assigns the sender's address to the IRLWallet variable.
    * - Returns the IRLWallet address.
    */
    function getUserIRLWallet(address sender) public view returns (address){
        string memory IRLWalletInfo = UserList[sender].info["IRLWallet"];
        address IRLWallet = sender;
        if (!compareStrings(IRLWalletInfo, "")){
            IRLWallet = address(bytes20(bytes(IRLWalletInfo)));
        }
        return IRLWallet;
    }

    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        if (bytes(a).length != bytes(b).length) {
            return false;
        } else {
            for (uint i = 0; i < bytes(a).length; i++) {
                if (bytes(a)[i] != bytes(b)[i]) {
                    return false;
                }
            }
            return true;
        }
    }
}
// File: contracts/IERC721A.sol


// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}
// File: contracts/ERC721A.sol


// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;


/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) _revert(BalanceQueryForZeroAddress.selector);
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) _revert(URIQueryForNonexistentToken.selector);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Returns whether the ownership slot at `index` is initialized.
     * An uninitialized slot does not necessarily mean that the slot has no owner.
     */
    function _ownershipIsInitialized(uint256 index) internal view virtual returns (bool) {
        return _packedOwnerships[index] != 0;
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256 packed) {
        if (_startTokenId() <= tokenId) {
            packed = _packedOwnerships[tokenId];
            // If the data at the starting slot does not exist, start the scan.
            if (packed == 0) {
                if (tokenId >= _currentIndex) _revert(OwnerQueryForNonexistentToken.selector);
                // Invariant:
                // There will always be an initialized ownership slot
                // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                // before an unintialized ownership slot
                // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                // Hence, `tokenId` will not underflow.
                //
                // We can directly compare the packed value.
                // If the address is zero, packed will be zero.
                for (;;) {
                    unchecked {
                        packed = _packedOwnerships[--tokenId];
                    }
                    if (packed == 0) continue;
                    if (packed & _BITMASK_BURNED == 0) return packed;
                    // Otherwise, the token is burned, and we must revert.
                    // This handles the case of batch burned tokens, where only the burned bit
                    // of the starting slot is set, and remaining slots are left uninitialized.
                    _revert(OwnerQueryForNonexistentToken.selector);
                }
            }
            // Otherwise, the data exists and we can skip the scan.
            // This is possible because we have already achieved the target condition.
            // This saves 2143 gas on transfers of initialized tokens.
            // If the token is not burned, return `packed`. Otherwise, revert.
            if (packed & _BITMASK_BURNED == 0) return packed;
        }
        _revert(OwnerQueryForNonexistentToken.selector);
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account. See {ERC721A-_approve}.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     */
    function approve(address to, uint256 tokenId) public payable virtual override {
        _approve(to, tokenId, true);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) _revert(ApprovalQueryForNonexistentToken.selector);

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool result) {
        if (_startTokenId() <= tokenId) {
            if (tokenId < _currentIndex) {
                uint256 packed;
                while ((packed = _packedOwnerships[tokenId]) == 0) --tokenId;
                result = packed & _BITMASK_BURNED == 0;
            }
        }
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId].value`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        // Mask `from` to the lower 160 bits, in case the upper bits somehow aren't clean.
        from = address(uint160(uint256(uint160(from)) & _BITMASK_ADDRESS));

        if (address(uint160(prevOwnershipPacked)) != from) _revert(TransferFromIncorrectOwner.selector);

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) _revert(TransferCallerNotOwnerNorApproved.selector);

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
        uint256 toMasked = uint256(uint160(to)) & _BITMASK_ADDRESS;
        assembly {
            // Emit the `Transfer` event.
            log4(
                0, // Start of data (0, since no data).
                0, // End of data (0, since no data).
                _TRANSFER_EVENT_SIGNATURE, // Signature.
                from, // `from`.
                toMasked, // `to`.
                tokenId // `tokenId`.
            )
        }
        if (toMasked == 0) _revert(TransferToZeroAddress.selector);

        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                _revert(TransferToNonERC721ReceiverImplementer.selector);
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                _revert(TransferToNonERC721ReceiverImplementer.selector);
            }
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) _revert(MintZeroQuantity.selector);

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
            uint256 toMasked = uint256(uint160(to)) & _BITMASK_ADDRESS;

            if (toMasked == 0) _revert(MintToZeroAddress.selector);

            uint256 end = startTokenId + quantity;
            uint256 tokenId = startTokenId;

            do {
                assembly {
                    // Emit the `Transfer` event.
                    log4(
                        0, // Start of data (0, since no data).
                        0, // End of data (0, since no data).
                        _TRANSFER_EVENT_SIGNATURE, // Signature.
                        0, // `address(0)`.
                        toMasked, // `to`.
                        tokenId // `tokenId`.
                    )
                }
                // The `!=` check ensures that large values of `quantity`
                // that overflows uint256 will make the loop run out of gas.
            } while (++tokenId != end);

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) _revert(MintToZeroAddress.selector);
        if (quantity == 0) _revert(MintZeroQuantity.selector);
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) _revert(MintERC2309QuantityExceedsLimit.selector);

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        _revert(TransferToNonERC721ReceiverImplementer.selector);
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) _revert(bytes4(0));
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                       APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_approve(to, tokenId, false)`.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _approve(to, tokenId, false);
    }

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        bool approvalCheck
    ) internal virtual {
        address owner = ownerOf(tokenId);

        if (approvalCheck && _msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                _revert(ApprovalCallerNotOwnerNorApproved.selector);
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
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
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) _revert(TransferCallerNotOwnerNorApproved.selector);
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) _revert(OwnershipNotInitializedForExtraData.selector);
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }

    /**
     * @dev For more efficient reverts.
     */
    function _revert(bytes4 errorSelector) internal pure {
        assembly {
            mstore(0x00, errorSelector)
            revert(0x00, 0x04)
        }
    }
}
// File: contracts/MintContract.sol


pragma solidity ^0.8.13;




//import "./StoreContract.sol";



  /**
   * @title ContractName
   * @dev ContractDescription
   * @custom:dev-run-script contracts/MintContract.sol
   */

// File: contracts/StoreContract.sol


pragma solidity ^0.8.9;



contract MintContract is DefaultOperatorFilterer, ERC721A, AccessControlEnumerable, IERC2981 {
    
    bytes32 private constant MANAGER = keccak256("MANAGER");

    uint256 public royaltyFeePercentage = 5;
    address public royaltyRecipient;

    StoreContract private storeContractInstance;
    address public storeContractAddress;

    using Counters for Counters.Counter;

    string private customBaseURI;
    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => uint256) public consumableList;

    event NFTMinted(address indexed to, uint256 indexed tokenId, uint256 indexed storeId, uint256 dropIndex, uint256 itemIndex, string modelId);
    event NFTConsumed(string accountId, address indexed from, uint256 indexed tokenId);
    event NFTTransferred(address indexed from, address indexed to, uint256 indexed tokenId);
    constructor(address admin) ERC721A("IRL Smart Collectibles", "IRL") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);

        customBaseURI = "https://s3.us-east-2.amazonaws.com/irl.nft.metadata/metadata/";
    }

    /**
    * @notice Retrieves the members of a given role.
    *
    * @dev The function takes a role as a parameter and returns an array of addresses representing the members of that role.
    *
    * @param role A bytes32 value representing the role for which members are to be retrieved.
    *
    * @return A dynamic array of type address[], representing the members of the given role.
    *
    * The function performs the following actions:
    *
    * - Initializes a new dynamic array `members` with a size equal to the number of members in the role (retrieved by `getRoleMemberCount(role)`).
    * - Iterates over the length of the `members` array, filling each index with the address of a member of the role (retrieved by `getRoleMember(role, i)`).
    * - Returns the filled `members` array.
    */
    function getRoleMembers(bytes32 role) public view returns (address[] memory) {
        address[] memory members = new address[](getRoleMemberCount(role));
        for (uint i = 0; i < members.length; i++) {
            members[i] = getRoleMember(role, i);
        }
        return members;
    }

    /**
    * @notice Sets the store contract address and initializes the store contract instance.
    *
    * @dev This function takes an Ethereum address as a parameter and sets the store contract address. It also initializes
    * the store contract instance to interact with the store contract at the specified address. This function can only be
    * called by an account with the DEFAULT_ADMIN_ROLE.
    *
    *  @param _storeContractAddress The Ethereum address of the store contract.
    *
    * The function performs the following steps:
    *
    * - Sets the `storeContractAddress` state variable to the `_storeContractAddress` parameter.
    * - Sets the `storeContractInstance` state variable to a new instance of the `StoreContract` at the `storeContractAddress`.
    *
    */
    function setStoreContract(address _storeContractAddress) public onlyRole(DEFAULT_ADMIN_ROLE){
        storeContractAddress = _storeContractAddress;
        storeContractInstance = StoreContract(storeContractAddress);
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    function setBaseURI(string memory uri) public onlyRole(DEFAULT_ADMIN_ROLE){
        customBaseURI = uri;
    }

    /**
    * @notice Grants the DEFAULT_ADMIN_ROLE to a specified account.
    *
    * @dev This function allows an account with the DEFAULT_ADMIN_ROLE to assign the same role to another account. 
    * The DEFAULT_ADMIN_ROLE is a powerful role that includes permissions such as setting the base URI of the NFT's metadata and
    * setting the address of the contract for storing items. This function can only be called by an account with the DEFAULT_ADMIN_ROLE.
    *
    * @param account The address of the account to which the DEFAULT_ADMIN_ROLE will be granted.
    *
    * The function performs the following steps:
    *
    * - Invokes the `_grantRole` function from the AccessControl contract in the OpenZeppelin contracts library to assign 
    * the DEFAULT_ADMIN_ROLE to the account specified by the `account` parameter.
    *
    */
    function grantAdminRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE){
        _grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
    * @notice Revokes the DEFAULT_ADMIN_ROLE from a specified account.
    *
    * @dev This function allows an account with the DEFAULT_ADMIN_ROLE to revoke the same role from another account. 
    * The DEFAULT_ADMIN_ROLE is a powerful role that includes permissions such as setting the base URI of the NFT's metadata and
    * setting the address of the contract for storing items. This function can only be called by an account with the DEFAULT_ADMIN_ROLE.
    *
    * @param account The address of the account from which the DEFAULT_ADMIN_ROLE will be revoked.
    *
    * The function performs the following steps:
    *
    * - Invokes the `_revokeRole` function from the AccessControl contract in the OpenZeppelin contracts library to revoke
    * the DEFAULT_ADMIN_ROLE from the account specified by the `account` parameter.
    *
    */
    function revokeAdminRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE){
        _revokeRole(DEFAULT_ADMIN_ROLE, account);
    } 

    /**
    * @notice Grants the MANAGER role to a specified account.
    *
    * @dev This function allows an account with the DEFAULT_ADMIN_ROLE to grant the MANAGER role to another account.
    * The MANAGER role is a role with permissions for minting tokens, creating, modifying, and deleting items and store entities.
    * This function can only be called by an account with the DEFAULT_ADMIN_ROLE.
    *
    * @param account The address of the account which will be granted the MANAGER role.
    *
    * The function performs the following steps:
    *
    * - Invokes the `_grantRole` function from the AccessControl contract in the OpenZeppelin contracts library to grant
    * the MANAGER role to the account specified by the `account` parameter.
    *
    */
    function grantManagerRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE){
        _grantRole(MANAGER, account);
    }

    /**
    * @notice Revokes the MANAGER role from a specified account.
    *
    * @dev This function allows an account with the DEFAULT_ADMIN_ROLE to revoke the MANAGER role from another account.
    * The MANAGER role is a role with permissions for minting tokens, creating, modifying, and deleting items and store entities.
    * This function can only be called by an account with the DEFAULT_ADMIN_ROLE.
    *
    * @param account The address of the account which will have the MANAGER role revoked.
    *
    * The function performs the following steps:
    *
    * - Invokes the `_revokeRole` function from the AccessControl contract in the OpenZeppelin contracts library to revoke
    * the MANAGER role from the account specified by the `account` parameter.
    *
    */
    function revokeManagerRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE){
        _revokeRole(MANAGER, account);
    } 

    /**
    * @notice Mints a new Non-Fungible Token (NFT) and assigns it to a specific address.
    *
    * @dev This function is only callable by an address with the MANAGER role. It uses the `_tokenIdCounter` to generate a unique token ID for each new NFT.
    * It also updates the `consumableList` if the NFT is to be consumable.
    *
    * @param storeId The ID of the store from which the NFT is being minted.
    * @param dropIndex The index of the drop associated with the NFT.
    * @param itemIndex The index of the item within the drop that corresponds to the NFT.
    * @param to The address that will receive the minted NFT.
    * @param consumable A boolean that indicates if the NFT is consumable.
    * @param modelId The ID that represents the model of the NFT.
    *
    * The function performs the following actions:
    * 
    * - Retrieves the current tokenId from the `_tokenIdCounter`.
    * - Increments the `_tokenIdCounter`.
    * - If the `consumable` parameter is true, adds the tokenId to the `consumableList`.
    * - Mints the NFT by calling the `_safeMint` function.
    * - Emits an `NFTMinted` event to notify listeners that a new NFT has been minted.
    * - Calls the `writeTokenStoreItem` function of the `storeContractInstance` to update the store item associated with the tokenId.
    */
    function mint(uint256 storeId, uint256 dropIndex, uint256 itemIndex, address to, bool consumable, string memory modelId) public onlyRole(MANAGER) {
 
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        //Add to consumable list
        if (consumable == true)
            consumableList[tokenId] = 1;

        // Mint the NFT and transfer the Ether to the company's wallet
        _safeMint(to, tokenId);

        // Emit an event to indicate that a new NFT has been minted
        emit NFTMinted(to, tokenId, storeId, dropIndex, itemIndex, modelId);

        //storeContractInstance.writeTokenStoreItem(tokenId, storeId, dropIndex, itemIndex);
    }

    /**
    * @notice Checks if a NFT is consumable.
    *
    * @dev This function checks the `consumableList` mapping using the provided tokenId as the key.
    *
    * @param tokenId The unique identifier of the NFT to be checked for consumability.
    *
    * The function performs the following actions:
    * 
    * - Looks up the `consumableList` mapping using the `tokenId`.
    * - Returns true if the value of the `consumableList` entry is 1, and false otherwise.
    *
    * @return bool True if the NFT is consumable (i.e., if the `consumableList` entry for the NFT's tokenId is 1), and false otherwise.
    */
    function isConsumable(uint256 tokenId) public view returns (bool){
        return (consumableList[tokenId] == 1);
    }

/*
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
*/

    /**
    * @notice Consumes a Non-Fungible Token (NFT) by transferring it to this contract and then burning it.
    *
    * @dev The function requires the NFT to be consumable and the caller to be the owner of the NFT.
    *
    * @param accountId The unique identifier of the account associated with the NFT to be consumed.
    * @param _tokenId The unique identifier of the NFT to be consumed.
    *
    * The function performs the following actions:
    * 
    * - Checks whether the NFT is consumable. If not, the function call is reverted with a "Token is not consumable" error message.
    * - Checks whether the caller is the owner of the NFT. If not, the function call is reverted with a "Sender is not the owner of the NFT" error message.
    * - Approves the transfer of the NFT to this contract.
    * - Transfers the NFT from the owner to this contract.
    * - Burns (destroys) the NFT, removing it from existence.
    * - Emits an NFTConsumed event, logging the accountId, the former owner's address, and the tokenId of the consumed NFT.
    */
    function consumeNFT(string memory accountId, uint256 _tokenId) public {

        // Verify consumable
        require(consumableList[_tokenId] == 1, "Token is not consumable");
        
        // Verify that the sender is the owner of the NFT
        require(ownerOf(_tokenId) == msg.sender, "Sender is not the owner of the NFT");

        // Approve transfer of the NFT to this contract
        super.approve(address(this), _tokenId);

        // Burn the NFT
        super.safeTransferFrom(msg.sender, address(this), _tokenId);

        _burn(_tokenId);

        emit NFTConsumed(accountId, msg.sender, _tokenId);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public returns (bytes4) {
    // Perform any additional checks or logic here
        
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
        emit NFTTransferred(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
        emit NFTTransferred(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public payable
        override(ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function royaltyInfo(uint256 tokenId, uint256 value) public view override returns (address, uint256) {
        return (royaltyRecipient, royaltyFeePercentage);
    }
    function setRoyaltyRecipient(address walletAddress) public onlyRole(DEFAULT_ADMIN_ROLE){
        royaltyRecipient = walletAddress;
    }
    function setRoyaltyPercentage(uint256 percentage) public onlyRole(DEFAULT_ADMIN_ROLE){
        royaltyFeePercentage = percentage;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, AccessControlEnumerable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}



/**
 * @dev The StoreContract is a part of a larger system that manages NFT 
 * minting and management within a marketplace environment. 
 * It's responsible for the management and operation of store-related 
 * functions, such as creating and updating stores, items, and drops.
 */

contract StoreContract is AccessControlEnumerable {

    bytes32 private constant MANAGER = keccak256("MANAGER");

    /**
     * @dev Instances of other contracts this contract interacts with.
     */
    MintContract private mintContractInstance;
    AccountContract private accountContractInstance;
    WhitelistContract private whitelistContractInstance;

    /**
     * @dev The addresses of the aforementioned contracts.
     */
    address public mintContractAddress;
    address public accountContractAddress;
    address public whitelistContractAddress;

    /**
     * @dev The current price of MATIC token.
     */
    uint256 public maticPrice;

    /**
     * @dev The number of stores present in the system.
     */
    uint256 public numStore;
    
    /**
     * @dev Mappings to keep track of the stores, their drops, and items.
     */
    mapping(uint256 => StoreDataStructure.StoreTag) public StoreList;
    mapping(uint256 => mapping(uint256 => StoreDataStructure.DropTag)) public dropList;
    mapping(uint256 => mapping(uint256 => mapping (uint256 => StoreDataStructure.StoreItem))) public storeItemList;
    
    mapping(uint256 => string) public tokenStoreItemList;

    /**
     * @dev The wallet address where funds received from minting NFTs will be sent.
     */
    address payable public companyWallet;

    /**
     * @dev Emitted when a store is updated or created.
     */
    event StoreUpdate(uint256 indexed storeId, StoreDataStructure.StoreTag storeTag);
    /**
     * @dev Emitted when a drop is updated or created.
     */
    event DropUpdate(uint256 indexed storeId, uint256 dropId, StoreDataStructure.DropTag dropTag);
    /**
     * @dev Emitted when a store item is updated or created.
     */
    event StoreItemUpdate(uint256 indexed storeId, uint256 indexed dropId, uint256 indexed itemIndex, StoreDataStructure.StoreItem storeItem);

    constructor(address admin){
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /**
    * @notice Fetches the members of a given role.
    *
    * @dev This function retrieves all the members of a specific role by looping over the count of members in that role. 
    * The result is returned as an array of addresses.
    * This function can be called by any account to get the list of addresses that hold a specific role.
    *
    * @param role The role identifier to get the members of.
    *
    * @return members An array of addresses that are assigned to the role specified by the `role` parameter.
    *
    * The function performs the following steps:
    *
    * - Initializes a new dynamic array of addresses with a size equal to the count of the members in the role specified by the `role` parameter.
    * - Loops over each index in the members array and assigns the address of the member at that index in the role to the corresponding index in the `members` array.
    * - Returns the `members` array.
    *
    */
    function getRoleMembers(bytes32 role) public view returns (address[] memory) {
        address[] memory members = new address[](getRoleMemberCount(role));
        for (uint i = 0; i < members.length; i++) {
            members[i] = getRoleMember(role, i);
        }
        return members;
    }

    /**
    * @notice Grants the DEFAULT_ADMIN_ROLE to a specified account.
    *
    * @dev This function allows an account with the DEFAULT_ADMIN_ROLE to assign the same role to another account. 
    * The DEFAULT_ADMIN_ROLE is a powerful role that includes permissions such as setting the base URI of the NFT's metadata and
    * setting the address of the contract for storing items. This function can only be called by an account with the DEFAULT_ADMIN_ROLE.
    *
    * @param account The address of the account to which the DEFAULT_ADMIN_ROLE will be granted.
    *
    * The function performs the following steps:
    *
    * - Invokes the `_grantRole` function from the AccessControl contract in the OpenZeppelin contracts library to assign 
    * the DEFAULT_ADMIN_ROLE to the account specified by the `account` parameter.
    *
    */
    function grantAdminRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE){
        _grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
    * @notice Revokes the DEFAULT_ADMIN_ROLE from a specified account.
    *
    * @dev This function allows an account with the DEFAULT_ADMIN_ROLE to revoke the same role from another account. 
    * The DEFAULT_ADMIN_ROLE is a powerful role that includes permissions such as setting the base URI of the NFT's metadata and
    * setting the address of the contract for storing items. This function can only be called by an account with the DEFAULT_ADMIN_ROLE.
    *
    * @param account The address of the account from which the DEFAULT_ADMIN_ROLE will be revoked.
    *
    * The function performs the following steps:
    *
    * - Invokes the `_revokeRole` function from the AccessControl contract in the OpenZeppelin contracts library to revoke
    * the DEFAULT_ADMIN_ROLE from the account specified by the `account` parameter.
    *
    */
    function revokeAdminRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE){
        _revokeRole(DEFAULT_ADMIN_ROLE, account);
    } 

    /**
    * @notice Grants the MANAGER role to a specified account.
    *
    * @dev This function allows an account with the DEFAULT_ADMIN_ROLE to grant the MANAGER role to another account.
    * The MANAGER role is a role with permissions for minting tokens, creating, modifying, and deleting items and store entities.
    * This function can only be called by an account with the DEFAULT_ADMIN_ROLE.
    *
    * @param account The address of the account which will be granted the MANAGER role.
    *
    * The function performs the following steps:
    *
    * - Invokes the `_grantRole` function from the AccessControl contract in the OpenZeppelin contracts library to grant
    * the MANAGER role to the account specified by the `account` parameter.
    *
    */
    function grantManagerRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE){
        _grantRole(MANAGER, account);
    }

    /**
    * @notice Revokes the MANAGER role from a specified account.
    *
    * @dev This function allows an account with the DEFAULT_ADMIN_ROLE to revoke the MANAGER role from another account.
    * The MANAGER role is a role with permissions for minting tokens, creating, modifying, and deleting items and store entities.
    * This function can only be called by an account with the DEFAULT_ADMIN_ROLE.
    *
    * @param account The address of the account which will have the MANAGER role revoked.
    *
    * The function performs the following steps:
    *
    * - Invokes the `_revokeRole` function from the AccessControl contract in the OpenZeppelin contracts library to revoke
    * the MANAGER role from the account specified by the `account` parameter.
    *
    */
    function revokeManagerRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE){
        _revokeRole(MANAGER, account);
    } 

    /**
     * @dev Set the addresses of the account, mint, and whitelist contracts.
     */
    function setAccountContract(address _accountContractAddress) public onlyRole(MANAGER){
        accountContractAddress = _accountContractAddress;
        accountContractInstance = AccountContract(accountContractAddress);
    }
    function setMintContract(address _mintContractAddress) public onlyRole(MANAGER){
        mintContractAddress = _mintContractAddress;
        mintContractInstance = MintContract(mintContractAddress);
    }
    function setWhitelistContract(address _whitelistContractAddress) public onlyRole(MANAGER){
        whitelistContractAddress = _whitelistContractAddress;
        whitelistContractInstance = WhitelistContract(whitelistContractAddress);
    }    
    
    /**
    * @notice Public function to mint an NFT from a store.
    *
    * @dev This function allows a user to mint an NFT from a specified store, drop, and item. It takes an array of tokens and a model ID as input, and it has to be called with a payment in Ether.
    * 
    * @param storeId The unique identifier of the store.
    * @param dropIndex The index of the drop within the store.
    * @param itemIndex The index of the item within the drop.
    * @param token An array of int256 tokens. Each token in the array represents a different functionality (early access, allowPassId, and discount).
    * @param modelId The model identifier of the NFT to be minted.
    *
    * The function performs several checks and actions:
    *
    * - Fetches the StoreItem from the specified indices.
    * - Gets the IRLWallet address of the sender.
    * - Checks if the item is already released, and if not, if the sender is eligible for early access or if they're whitelisted.
    * - If the item allows minting by a certain PassId, it checks if the sender owns that PassId.
    * - It calculates the discount (if applicable) and checks if the sender has sent enough Ether.
    * - It checks if the max supply for this NFT has been reached, and if not, it increments the current supply.
    * - It then calls the mint function on a specified mint contract, providing the necessary parameters.
    * - Finally, it transfers the received Ether to the company's wallet.
    */
    function publicMintNFTFromStore(uint256 storeId, uint256 dropIndex, uint256 itemIndex, int256[] memory token, string memory modelId) public payable{
        
        uint256 timestamp = block.timestamp;

        StoreDataStructure.StoreItem storage storeItem = storeItemList[storeId][dropIndex][itemIndex]; //StoreList[storeId].DropList[dropIndex].ItemList[itemIndex];

        address IRLWallet = accountContractInstance.getUserIRLWallet(msg.sender);

        //Check for drop date        
        if (storeItem.drop.date > timestamp){
            bool isEarlyAccess = false;
            bool isWhitelisted = false;
            if (token[0] != -1 && (IERC721A(mintContractAddress).ownerOf(uint256(token[0])) == msg.sender ||
                                   IERC721A(mintContractAddress).ownerOf(uint256(token[0])) ==  IRLWallet)){
                                        if (compareStrings(storeItem.utils.earlyAccess.passId, tokenStoreItemList[uint256(token[0])]) && storeItem.utils.earlyAccess.date < timestamp){
                                            isEarlyAccess = true;            
                                        }
                                   }
            if (storeItem.utils.isWhitelisted){
                bool isAllowlist;                
                (isWhitelisted, isAllowlist) = whitelistContractInstance.isPurchasable(msg.sender, storeId, dropIndex, itemIndex);
                if (isWhitelisted){
                    whitelistContractInstance.DeductMintAttempt(msg.sender, storeId, dropIndex, itemIndex);
                    if (!isAllowlist)
                        whitelistContractInstance.DeductGuaranteeAttempt(storeId, dropIndex, itemIndex);
                }                
            }            
            if (!isEarlyAccess && !isWhitelisted)
                revert("Not eligible for mint date");
        }

        //Check allow PassId Mint
        if (bytes(storeItem.utils.allowPassIdMint).length != 0){
            require(token[1] != -1 && (IERC721A(mintContractAddress).ownerOf(uint256(token[1])) == msg.sender ||
                                   IERC721A(mintContractAddress).ownerOf(uint256(token[1])) ==  IRLWallet) && compareStrings(tokenStoreItemList[uint256(token[1])], storeItem.utils.allowPassIdMint), "User does not own allowPassId");        
        }

        //Check discount
        uint256 discountPercent = 0;
        uint256 discountDate = storeItem.utils.discount.date;
        string memory discountPassId = storeItem.utils.discount.passId;
        if (token[2] != -1 && (IERC721A(mintContractAddress).ownerOf(uint256(token[2])) == msg.sender ||
                                   IERC721A(mintContractAddress).ownerOf(uint256(token[2])) ==  IRLWallet) 
                                   && compareStrings(tokenStoreItemList[uint256(token[2])], discountPassId) 
                                   && discountDate > timestamp){
            discountPercent = storeItem.utils.discount.percentage;
        }        


        // Check if the maximum supply for this NFT type has been reached
        require(storeItem.supply.current < storeItem.supply.max, "Maximum supply reached for this NFT type");
        
        // Check if the user has sent enough Ether
        require(msg.value >= (storeItem.price*10**18/maticPrice) * (100 - discountPercent)/100, "Insufficient Ether sent");

        // Increment the total and NFT type supply
        storeItem.supply.current++;
        dropList[storeId][dropIndex].supply.current++;
        
        mintContractInstance.mint(storeId, dropIndex, itemIndex, msg.sender, storeItem.utils.consumable, modelId);
        companyWallet.transfer(msg.value);
    }

    /**
    * @notice Mints a new NFT from the store to the specified recipient address.
    *
    * @dev This function is only callable by an account with the MANAGER role. It increments the current supply of the NFT type and the total supply, and then mints the new NFT using a separate minting contract.
    *
    * @param storeId The unique identifier of the store.
    * @param dropIndex The index of the drop within the store.
    * @param itemIndex The index of the item within the drop.
    * @param to The address to receive the minted NFT.
    * @param consumable A boolean indicating if the NFT is consumable or not.
    * @param modelId The model identifier of the NFT to be minted.
    *
    * The function performs two main actions:
    *
    * - Increments the current supply of the NFT type and the total supply.
    * - Calls the mint function on a specified mint contract, providing the necessary parameters.
    */
    function mintNFTFromStore(uint256 storeId, uint256 dropIndex, uint256 itemIndex, address to, bool consumable, string memory modelId) public onlyRole(MANAGER){

        // Increment the total and NFT type supply
        storeItemList[storeId][dropIndex][itemIndex].supply.current++;
        dropList[storeId][dropIndex].supply.current++;
        
        mintContractInstance.mint(storeId, dropIndex, itemIndex, to, consumable, modelId);
    }

    /**
     * @dev Update the current price of MATIC token.
     */
    function updateMaticPrice(uint256 price) public onlyRole(MANAGER){
        maticPrice = price;
    }

    /**
    * @notice Creates a new store using the provided store tag data.
    *
    * @dev This function is only callable by an account with the MANAGER role. It uses the `modifyStore` function internally to update the store data.
    *
    * @param storeTag A structure containing the tag data for the new store.
    *
    * This function performs the following main actions:
    *
    * - Calls the `modifyStore` function with the current `numStore` value as the `storeId` and the provided `storeTag` as the new store data.
    * - Increments the `numStore` counter to prepare for the next store creation.
    */
    function createStore(StoreDataStructure.StoreTag memory storeTag) public onlyRole(MANAGER){
        modifyStore(numStore, storeTag);
        numStore++;
    }

    /**
    * @notice Modifies an existing store by updating it with new tag data.
    *
    * @dev This function is only callable by an account with the MANAGER role. It updates an existing store's information with a new store tag.
    *
    * @param storeId The unique identifier of the store to be modified.
    * @param storeTag A structure containing the new tag data for the store.
    *
    * This function performs the following main actions:
    *
    * - Assigns the provided `storeId` to the `id` field of the `storeTag`.
    * - Updates the `totalDrop` field of the `storeTag` with the existing store's `totalDrop` count.
    * - Replaces the existing store's data with the new `storeTag`.
    * - Emits a `StoreUpdate` event to log the changes.
    */
    function modifyStore(uint256 storeId, StoreDataStructure.StoreTag memory storeTag) public onlyRole(MANAGER){
        storeTag.id = storeId;
        storeTag.totalDrop = StoreList[storeId].totalDrop;
        StoreList[storeId] = storeTag;
        emit StoreUpdate(storeId, storeTag);
    }

    /**
    * @notice Creates a new drop in a specified store.
    *
    * @dev This function can only be called by an account with the MANAGER role. It uses the provided drop tag data to create a new drop.
    *
    * @param storeId The unique identifier of the store where the new drop will be created.
    * @param dropTag A structure containing the tag data for the new drop.
    *
    * This function performs the following main actions:
    *
    * - Retrieves the total number of drops in the specified store.
    * - Calls the `modifyDrop` function to create a new drop with the provided `dropTag` at the position of the total drop count.
    * - Increments the total drop count of the specified store.
    */
    function createDrop(uint256 storeId, StoreDataStructure.DropTag memory dropTag) public onlyRole(MANAGER){
        uint256 totalDrop = StoreList[storeId].totalDrop;
        modifyDrop(storeId, totalDrop, dropTag);
        StoreList[storeId].totalDrop++;
    }

    /**
    * @notice Modifies the metadata of a specific drop in a specific store.
    *
    * @dev This function can only be called by an account with the MANAGER role. It modifies the existing drop data with the new drop tag data provided.
    *
    * @param storeId The unique identifier of the store where the drop is located.
    * @param dropId The unique identifier of the drop to be modified within the store.
    * @param dropTag A structure containing the new tag data for the drop.
    *
    * This function performs the following main actions:
    *
    * - Retrieves the current drop tag associated with the provided `storeId` and `dropId`.
    * - Updates the `totalItems`, `id`, and `supply` attributes of the `dropTag` with the respective values from the current drop tag.
    * - Replaces the current drop tag in the drop list of the specified store with the updated `dropTag`.
    * - Emits a `DropUpdate` event notifying about the drop modification.
    */
    function modifyDrop(uint256 storeId, uint256 dropId, StoreDataStructure.DropTag memory dropTag) public onlyRole(MANAGER){
        StoreDataStructure.DropTag memory currentDropTag = dropList[storeId][dropId];

        dropTag.totalItems = dropList[storeId][dropId].totalItems;
        dropTag.id = dropId;
        dropTag.supply = currentDropTag.supply;
        dropList[storeId][dropId] = dropTag;

        emit DropUpdate(storeId, dropId, dropTag);
    }

    /**
    * @notice Creates a new item in a specified store and drop.
    *
    * @dev This function can only be called by an account with the MANAGER role. It creates a new store item with the provided data.
    *
    * @param storeId The unique identifier of the store where the item will be created.
    * @param dropIndex The index of the drop in which the item will be created.
    * @param storeItem A structure containing the data for the new store item.
    *
    * The function performs the following main actions:
    *
    * - Retrieves the current total number of items in the specified drop.
    * - Assigns this total as the item index of the new store item.
    * - Calls the modifyStoreItem function to add the new store item to the specified store and drop.
    * - Increments the total number of items in the specified drop.
    */
    function createStoreItem(uint256 storeId, uint256 dropIndex, StoreDataStructure.StoreItem memory storeItem) public onlyRole (MANAGER){
        uint256 totalItems =  dropList[storeId][dropIndex].totalItems;
        storeItem.itemIndex = totalItems;
        modifyStoreItem(storeId, dropIndex, totalItems, storeItem);
        dropList[storeId][dropIndex].totalItems++;
    }

    /**
    * @notice Updates an existing item in a specified store and drop.
    *
    * @dev This function can only be called by an account with the MANAGER role. It updates an existing store item with the provided new data.
    *
    * @param storeId The unique identifier of the store where the item exists.
    * @param dropIndex The index of the drop in which the item exists.
    * @param itemIndex The index of the item to be updated.
    * @param storeItem A structure containing the new data for the store item.
    *
    * This function performs the following main actions:
    *
    * - Retrieves the current data for the specified store item.
    * - Adjusts the maximum supply of the item and the corresponding drop based on the difference between the new and current max supplies.
    * - Updates the specified store item with the new data.
    * - Emits an event to log the update.
    */
    function modifyStoreItem(uint256 storeId, uint256 dropIndex, uint256 itemIndex, StoreDataStructure.StoreItem memory storeItem) public onlyRole(MANAGER)
    {
        StoreDataStructure.StoreItem memory currentStoreItem = storeItemList[storeId][dropIndex][itemIndex];
        require(storeItem.supply.max >= currentStoreItem.supply.current, "Max supply less than current supply");
        storeItem.supply.current = currentStoreItem.supply.current;
        int256 delta = int256(storeItem.supply.max) - int256(currentStoreItem.supply.max);
        int256 dropMaxSupply = int256(dropList[storeId][dropIndex].supply.max);
        dropMaxSupply += delta;
        require(dropMaxSupply >= 0, "Supply is less than 0");
        dropList[storeId][dropIndex].supply.max = uint256(dropMaxSupply);
        //StoreList[storeId].DropList[dropIndex].tag.supply.max += storeItem.supply.max - currentStoreItem.supply.max;
        storeItemList[storeId][dropIndex][itemIndex] = storeItem;

        emit StoreItemUpdate(storeId, dropIndex, itemIndex, storeItem);
    }

    /**
     * @dev Set the company's wallet address.
     */
    function setCompanyWallet(address payable _companyWallet) public onlyRole(MANAGER){
        companyWallet = _companyWallet;
    }

    /**
    * @notice Gets the price of a specified store item in Wei, considering any possible discount.
    *
    * @dev This function checks for a potential discount and adjusts the price of the item accordingly.
    *
    * @param storeId The unique identifier of the store where the item is located.
    * @param dropIndex The index of the drop in which the item is located.
    * @param itemIndex The index of the item for which the price is being retrieved.
    * @param discountToken A token potentially providing a discount for the item price.
    * @param sender The address of the sender.
    *
    * The function performs the following main actions:
    *
    * - Retrieves the sender's IRLWallet address and the specified store item data.
    * - Checks for a discount by verifying if the sender owns the discount token and if the token corresponds to a valid discount for the item at the current time.
    * - If a discount is available, it calculates the discounted price of the item. Otherwise, it returns the original price.
    *
    * @return uint256 The price of the specified store item in Wei.
    */
    function getStoreItemPriceInWei(uint256 storeId, uint256 dropIndex, uint256 itemIndex, int256 discountToken, address sender) public view returns (uint256){

        address IRLWallet = accountContractInstance.getUserIRLWallet(sender);

        StoreDataStructure.StoreItem memory storeItem = storeItemList[storeId][dropIndex][itemIndex];
        uint256 timestamp = block.timestamp;

        //Check discount
        uint256 discountPercent = 0;
        uint256 discountDate = storeItem.utils.discount.date;
        string memory discountPassId = storeItem.utils.discount.passId;
        if (discountToken != -1 && (IERC721A(mintContractAddress).ownerOf(uint256(discountToken)) == IRLWallet || 
            IERC721A(mintContractAddress).ownerOf(uint256(discountToken)) == sender) 
            && compareStrings(tokenStoreItemList[uint256(discountToken)], discountPassId) 
            && discountDate > timestamp){
            discountPercent = storeItem.utils.discount.percentage;
        }   
        uint256 price = storeItem.price*10**18/maticPrice * (100 - discountPercent)/100;
        return price;
    }
    
    /**
     * @dev Writes the name of a store item to a token.
     */
    function writeTokenStoreItem(uint256 tokenId, uint256 storeId, uint256 dropIndex, uint256 itemIndex) external onlyRole(MANAGER){
        tokenStoreItemList[tokenId] = storeItemList[storeId][dropIndex][itemIndex].name;
    }

    /**
     * @dev Compares two strings for equality.
     */
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        if (bytes(a).length != bytes(b).length) {
            return false;
        } else {
            for (uint i = 0; i < bytes(a).length; i++) {
                if (bytes(a)[i] != bytes(b)[i]) {
                    return false;
                }
            }
            return true;
        }
    }    
}