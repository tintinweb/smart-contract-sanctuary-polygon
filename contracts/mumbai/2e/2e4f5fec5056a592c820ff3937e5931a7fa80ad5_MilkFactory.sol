// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/utils/Context.sol";

import "./Milk.sol";

contract MilkFactory is Context {
    mapping(bytes32 => Milk) private _registry;

    error AlreadyExists();
    error NotFound();
    error Unauthorized();

    event MilkCreated(
        bytes32 indexed id,
        address indexed sender
    );

    event MilkDeleted(
        bytes32 indexed id,
        address indexed sender
    );

    function createMilk(bytes32 id) public {
        if (address(_registry[id]) != address(0))
            revert AlreadyExists();
        _registry[id] = new Milk(_msgSender());
        emit MilkCreated(id, _msgSender());
    }

    function getMilk(bytes32 id) public view returns (Milk) {
        if (address(_registry[id]) == address(0))
            revert NotFound();
        return _registry[id];
    }

    function deleteMilk(bytes32 id, address payable to) public {
        Milk milk = getMilk(id);
        if (!milk.hasCapability(CLAIM_FUNDS, _msgSender()))
            revert Unauthorized();
        milk.destroy(to);
        delete _registry[id];
        emit MilkDeleted(id, _msgSender());
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/utils/Context.sol";

import "./RequestableAccessManagement.sol";

contract Milk is Context, RequestableAccessManagement {
    address private _factory;

    constructor(address owner) {
        _factory = _msgSender();
        _addCapability(OWNER, ADD_CAPABILITIES);
        _grantRole(OWNER, owner, 1);
    }

    function addDefaultOwnerCapabilities()
        public
        senderCan(ADD_CAPABILITIES)
    {
        _addCapability(OWNER, REMOVE_CAPABILITIES);
        _addCapability(OWNER, GRANT_ROLES);
        _addCapability(OWNER, REVOKE_ROLES);
        _addCapability(OWNER, ADD_RATES);
        _addCapability(OWNER, REMOVE_RATES);
        _addCapability(OWNER, CLAIM_FUNDS);
    }

    function destroy(address payable to) public {
        require(_msgSender() == _factory);
        destroy(to);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import "openzeppelin-contracts/contracts/utils/Context.sol";

import "./AccessManagement.sol";
import "./IRequestableAccessManagement.sol";

bytes32 constant ADD_RATES = keccak256("ADD_RATES");
bytes32 constant REMOVE_RATES = keccak256("REMOVE_RATES");
bytes32 constant CLAIM_FUNDS = keccak256("CLAIM_FUNDS");

abstract contract RequestableAccessManagement is ERC165, Context, AccessManagement, IRequestableAccessManagement {
    error RateNotFound();

    struct Rate {
        uint256 price;
        uint256 secs;
    }

    mapping(bytes32 => Rate) private _rates;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, AccessManagement)
        returns (bool)
    {
        return interfaceId == type(IRequestableAccessManagement).interfaceId
            || super.supportsInterface(interfaceId);
    }


    function addRate(
        bytes32 role,
        uint256 price,
        uint256 secs
    )
        public
        virtual
        senderCan(ADD_RATES)
    {
        _addRate(role, price, secs);
    }

    function _addRate(
        bytes32 role,
        uint256 price,
        uint256 secs
    )
        internal
        virtual
    {
        _rates[role] = Rate(price, secs);
        emit RateAdded(role, price, secs, _msgSender());
    }

    function removeRate(bytes32 role)
        public
        virtual
        senderCan(REMOVE_RATES)
    {
        _removeRate(role);
    }

    function _removeRate(bytes32 role) internal virtual {
        delete _rates[role];
        emit RateRemoved(role, _msgSender());
    }

    function getRate(bytes32 role)
        public
        view
        returns (uint256, uint256)
    {
        Rate storage rate = _rates[role];
        return (rate.price, rate.secs);
    }

    function requestRole(bytes32 role)
        public
        payable
        virtual
    {
        (uint256 price, uint256 secs) = getRate(role);
        if (secs == 0) {
            revert RateNotFound();
        }
        if (price == 0) {
            _grantRole(role, _msgSender(), 1);
        } else {
            _grantRole(role, _msgSender(), block.timestamp + (msg.value / price * secs));
        }
    }

    function claimFunds(address payable to)
        public
        virtual
        senderCan(CLAIM_FUNDS)
    {
        to.transfer(address(this).balance);
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import "openzeppelin-contracts/contracts/utils/Context.sol";

import "./IAccessManagement.sol";

bytes32 constant OWNER = keccak256("OWNER");
bytes32 constant ADD_CAPABILITIES = keccak256("ADD_CAPABILITIES");
bytes32 constant REMOVE_CAPABILITIES = keccak256("REMOVE_CAPABILITIES");
bytes32 constant GRANT_ROLES = keccak256("GRANT_ROLES");
bytes32 constant REVOKE_ROLES = keccak256("REVOKE_ROLES");

abstract contract AccessManagement is IAccessManagement, ERC165, Context {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    error Unauthorized();

    mapping(bytes32 => mapping(address => uint256)) private _roles;

    mapping(bytes32 => EnumerableSet.Bytes32Set) private _capabilities;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IAccessManagement).interfaceId
            || super.supportsInterface(interfaceId);
    }

    modifier senderCan(bytes32 capability) {
        _checkCapability(capability, _msgSender());
        _;
    }

    function _checkCapability(bytes32 capability, address account)
        internal
        view
        virtual
    {
        if (!hasCapability(capability, account)) {
            revert Unauthorized();
        }
    }

    function hasCapability(bytes32 capability, address account)
        public
        view
        virtual
        returns (bool)
    {
        return _hasCapability(capability, account);
    }

    function _hasCapability(bytes32 capability, address account)
        internal
        view
        virtual
        returns (bool)
    {
        uint256 len = _capabilities[capability].length();
        for (uint256 i = 0; i < len; i++) {
            if (hasRole(_capabilities[capability].at(i), account)) {
                return true;
            }
        }
        return false;
    }

    function hasRole(bytes32 role, address account)
        public
        view
        virtual
        returns (bool)
    {
        return _hasRole(role, account);
    }

    function _hasRole(bytes32 role, address account)
        internal
        view
        virtual
        returns (bool)
    {
        uint256 roleExpiration = _roles[role][account];
        return roleExpiration == 1 || roleExpiration > block.timestamp;
    }

    function addCapability(bytes32 role, bytes32 capability)
        public
        virtual
        senderCan(ADD_CAPABILITIES)
    {
        _addCapability(role, capability);
    }

    function _addCapability(bytes32 role, bytes32 capability)
        internal
        virtual
    {
        _capabilities[capability].add(role);
        emit CapabilityAdded(role, capability, _msgSender());
    }

    function removeCapability(bytes32 role, bytes32 capability)
        public
        virtual
        senderCan(REMOVE_CAPABILITIES)
    {
        _removeCapability(role, capability);
    }

    function _removeCapability(bytes32 role, bytes32 capability)
        internal
        virtual
    {
        _capabilities[capability].remove(role);
        emit CapabilityRemoved(role, capability, _msgSender());
    }

    function grantRole(bytes32 role, address account, uint256 until)
        public
        virtual
        senderCan(GRANT_ROLES)
    {
        _grantRole(role, account, until);
    }

    function _grantRole(bytes32 role, address account, uint256 until)
        internal
        virtual
    {
        _roles[role][account] = until;
        emit RoleGranted(role, account, until, _msgSender());
    }

    function revokeRole(bytes32 role, address account)
        public
        virtual
        senderCan(REVOKE_ROLES)
    {
        _removeRole(role, account);
    }

    function renounceRole(bytes32 role) public virtual {
        _removeRole(role, _msgSender());
    }

    function _removeRole(bytes32 role, address account) internal virtual {
        _roles[role][account] = 0;
        emit RoleRevoked(role, account, _msgSender());
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

interface IRequestableAccessManagement {
    event RateAdded(
        bytes32 indexed role,
        uint256 price,
        uint256 secs,
        address indexed sender
    );
    event RateRemoved(
        bytes32 indexed role,
        address indexed sender
    );

    function addRate(
        bytes32 role,
        uint256 price,
        uint256 secs
    )
        external;
    function removeRate(bytes32 role) external;
    function getRate(bytes32 role)
        external
        returns (uint256, uint256);

    function requestRole(bytes32 role) external payable;

    function claimFunds(address payable to) external;
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

interface IAccessManagement {
    event CapabilityAdded(
        bytes32 indexed role,
        bytes32 indexed capability,
        address indexed sender
    );
    event CapabilityRemoved(
        bytes32 indexed role,
        bytes32 indexed capability,
        address indexed sender
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        uint256 until,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    function hasCapability(bytes32 capability, address account)
        external
        view
        returns (bool);
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);
    function addCapability(bytes32 role, bytes32 capability) external;
    function removeCapability(bytes32 role, bytes32 capability) external;
    function grantRole(bytes32 role, address account, uint256 until)
        external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role) external;
}