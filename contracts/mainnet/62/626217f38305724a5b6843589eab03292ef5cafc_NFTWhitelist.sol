// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IAccessController} from "../interfaces/IAccessController.sol";
import {IImplementationManager} from "../interfaces/IImplementationManager.sol";
import {INFTWhitelist} from "../interfaces/INFTWhitelist.sol";

import {ImplementationInterfaceNames} from "../libraries/ImplementationInterfaceNames.sol";
import {Errors} from "../libraries/Errors.sol";

/// @title NFTWhitelist
/// @author Cloover
/// @notice Contract managing the list of NFT collections that are allowed to be used in the protocol
contract NFTWhitelist is INFTWhitelist {
    using EnumerableSet for EnumerableSet.AddressSet;

    //----------------------------------------
    // Storage
    //----------------------------------------

    EnumerableSet.AddressSet private _nftCollections;

    address private _implementationManager;

    mapping(address => address) private _royaltiesRecipent;

    //----------------------------------------
    // Events
    //----------------------------------------

    event AddedToWhitelist(address indexed addedNftCollection, address indexed creator);
    event RemovedFromWhitelist(address indexed removedNftCollection);

    //----------------------------------------
    // Modifiers
    //----------------------------------------
    modifier onlyMaintainer() {
        IAccessController accessController = IAccessController(
            IImplementationManager(_implementationManager).getImplementationAddress(
                ImplementationInterfaceNames.AccessController
            )
        );
        if (!accessController.hasRole(accessController.MAINTAINER_ROLE(), msg.sender)) revert Errors.NOT_MAINTAINER();
        _;
    }

    //----------------------------------------
    // Initialization function
    //----------------------------------------
    constructor(address implementationManager_) {
        _implementationManager = implementationManager_;
    }

    //----------------------------------------
    // External function
    //----------------------------------------

    /// @inheritdoc INFTWhitelist
    function addToWhitelist(address newNftCollection, address creator) external override onlyMaintainer {
        if (!_nftCollections.add(newNftCollection)) revert Errors.ALREADY_WHITELISTED();
        _royaltiesRecipent[newNftCollection] = creator;
        emit AddedToWhitelist(newNftCollection, creator);
    }

    /// @inheritdoc INFTWhitelist
    function removeFromWhitelist(address nftCollectionToRemove) external override onlyMaintainer {
        if (!_nftCollections.remove(nftCollectionToRemove)) revert Errors.NOT_WHITELISTED();
        delete _royaltiesRecipent[nftCollectionToRemove];
        emit RemovedFromWhitelist(nftCollectionToRemove);
    }

    /// @inheritdoc INFTWhitelist
    function isWhitelisted(address nftCollectionToCheck) external view override returns (bool) {
        return _nftCollections.contains(nftCollectionToCheck);
    }

    /// @inheritdoc INFTWhitelist
    function getWhitelist() external view override returns (address[] memory) {
        uint256 numberOfElements = _nftCollections.length();
        address[] memory activeNftCollections = new address[](numberOfElements);
        for (uint256 i = 0; i < numberOfElements; ++i) {
            activeNftCollections[i] = _nftCollections.at(i);
        }
        return activeNftCollections;
    }

    /// @inheritdoc INFTWhitelist
    function getCollectionRoyaltiesRecipient(address nftCollection) external view override returns (address creator) {
        return _royaltiesRecipent[nftCollection];
    }

    /// @inheritdoc INFTWhitelist
    function implementationManager() external view override returns (address) {
        return _implementationManager;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

interface IAccessController is IAccessControl {
    function MAINTAINER_ROLE() external view returns (bytes32);
    function MANAGER_ROLE() external view returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IImplementationManager {
    /// @notice Updates the address of the contract that implements `interfaceName`
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress) external;

    /// @notice Return the address of the contract that implements the given `interfaceName`
    function getImplementationAddress(bytes32 interfaceName) external view returns (address implementationAddress);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface INFTWhitelist {
    /// @notice Whitelist a nft collection with the creator address of it
    function addToWhitelist(address newNftCollection, address creator) external;

    /// @notice Removes a collection from the whitelist
    function removeFromWhitelist(address nftCollectionToRemove) external;

    /// @notice Return True if the address is whitelisted
    function isWhitelisted(address nftCollectionToCheck) external view returns (bool);

    /// @notice Return all addresses that are currently included in the whitelist.
    function getWhitelist() external view returns (address[] memory);

    /// @notice Return creator address for a specific nft collection
    function getCollectionRoyaltiesRecipient(address nftCollection) external view returns (address creator);

    /// @notice Return the implementationManager contract address
    function implementationManager() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @title ImplementationInterfaceNames
/// @author Cloover
/// @notice Library exposing interfaces names used in Cloover
library ImplementationInterfaceNames {
    bytes32 public constant AccessController = "AccessController";
    bytes32 public constant RandomProvider = "RandomProvider";
    bytes32 public constant NFTWhitelist = "NFTWhitelist";
    bytes32 public constant TokenWhitelist = "TokenWhitelist";
    bytes32 public constant ClooverRaffleFactory = "ClooverRaffleFactory";
    bytes32 public constant Treasury = "Treasury";
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @title Errors library
/// @author Cloover
/// @notice Library exposing errors used in Cloover's contracts
library Errors {
    error CANT_BE_ZERO(); // 'Value can't must be higher than 0'
    error NOT_MAINTAINER(); // 'Caller is not the maintainer'
    error IMPLEMENTATION_NOT_FOUND(); // 'Implementation interfaces is not registered'
    error ALREADY_WHITELISTED(); //'address already whitelisted'
    error NOT_WHITELISTED(); //'address not whitelisted'
    error EXCEED_MAX_PERCENTAGE(); //'Percentage value must be lower than max allowed'
    error EXCEED_MAX_VALUE_ALLOWED(); //'Value must be lower than max allowed'
    error BELOW_MIN_VALUE_ALLOWED(); //'Value must be higher than min allowed'
    error WRONG_DURATION_LIMITS(); //'The min duration must be lower than the max one'
    error OUT_OF_RANGE(); //'The value is not in the allowed range'
    error SALES_ALREADY_STARTED(); // 'At least one ticket has already been sold'
    error RAFFLE_CLOSE(); // 'Current timestamps greater or equal than the close time'
    error RAFFLE_STILL_OPEN(); // 'Current timestamps lesser or equal than the close time'
    error DRAW_NOT_POSSIBLE(); // 'Raffle is status forwards than DRAWING'
    error TICKET_SUPPLY_OVERFLOW(); // 'Maximum amount of ticket sold for the raffle has been reached'
    error WRONG_MSG_VALUE(); // 'msg.value not valid'
    error WRONG_AMOUNT(); // 'msg.value not valid'
    error MSG_SENDER_NOT_WINNER(); // 'msg.sender is not winner address'
    error NOT_CREATOR(); // 'msg.sender is not the creator of the raffle'
    error TICKET_NOT_DRAWN(); // 'ticket must be drawn'
    error TICKET_ALREADY_DRAWN(); // 'ticket has already be drawn'
    error NOT_REGISTERED_RAFFLE(); // 'Caller is not a raffle contract registered'
    error NOT_RANDOM_PROVIDER_CONTRACT(); // 'Caller is not the random provider contract'
    error COLLECTION_NOT_WHITELISTED(); //'NFT collection not whitelisted'
    error ROYALTIES_NOT_POSSIBLE(); //'NFT collection creator '
    error TOKEN_NOT_WHITELISTED(); //'Token not whitelisted'
    error IS_ETH_RAFFLE(); //'Ticket can only be purchase with native token (ETH)'
    error NOT_ETH_RAFFLE(); //'Ticket can only be purchase with ERC20 token'
    error NO_INSURANCE_TAKEN(); //'ClooverRaffle's creator didn't took insurance to claim prize refund'
    error INSURANCE_AMOUNT(); //'insurance cost paid'
    error SALES_EXCEED_MIN_THRESHOLD_LIMIT(); //'Ticket sales exceed min ticket sales covered by the insurance paid'
    error ALREADY_CLAIMED(); //'User already claimed his part'
    error NOTHING_TO_CLAIM(); //'User has nothing to claim'
    error EXCEED_MAX_TICKET_ALLOWED_TO_PURCHASE(); //'User exceed allowed ticket to purchase limit'
}

// SPDX-License-Identifier: MIT
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