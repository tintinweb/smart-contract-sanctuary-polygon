// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/structs/EnumerableSet.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./utils/IDefaultAccessControl.sol";
import "./IUnitPricesGovernance.sol";

interface IProtocolGovernance is IDefaultAccessControl, IUnitPricesGovernance {
    /// @notice CommonLibrary protocol params.
    /// @param permissionless If `true` anyone can spawn vaults, o/w only Protocol Governance Admin
    /// @param maxTokensPerVault Max different token addresses that could be managed by the protocol
    /// @param governanceDelay The delay (in secs) that must pass before setting new pending params to commiting them
    /// @param forceAllowMask If a permission bit is set in this mask it forces all addresses to have this permission as true
    /// @param withdrawLimit Withdraw limit (in unit prices, i.e. usd)
    struct Params {
        uint256 maxTokensPerVault;
        uint256 governanceDelay;
        address protocolTreasury;
        uint256 forceAllowMask;
        uint256 withdrawLimit;
    }

    // -------------------  EXTERNAL, VIEW  -------------------

    /// @notice Timestamp after which staged granted permissions for the given address can be committed.
    /// @param target The given address
    /// @return Zero if there are no staged permission grants, timestamp otherwise
    function stagedPermissionGrantsTimestamps(address target) external view returns (uint256);

    /// @notice Staged granted permission bitmask for the given address.
    /// @param target The given address
    /// @return Bitmask
    function stagedPermissionGrantsMasks(address target) external view returns (uint256);

    /// @notice Permission bitmask for the given address.
    /// @param target The given address
    /// @return Bitmask
    function permissionMasks(address target) external view returns (uint256);

    /// @notice Timestamp after which staged pending protocol parameters can be committed
    /// @return Zero if there are no staged parameters, timestamp otherwise.
    function stagedParamsTimestamp() external view returns (uint256);

    /// @notice Staged pending protocol parameters.
    function stagedParams() external view returns (Params memory);

    /// @notice Current protocol parameters.
    function params() external view returns (Params memory);

    /// @notice Addresses for which non-zero permissions are set.
    function permissionAddresses() external view returns (address[] memory);

    /// @notice Permission addresses staged for commit.
    function stagedPermissionGrantsAddresses() external view returns (address[] memory);

    /// @notice Return all addresses where rawPermissionMask bit for permissionId is set to 1.
    /// @param permissionId Id of the permission to check.
    /// @return A list of dirty addresses.
    function addressesByPermission(uint8 permissionId) external view returns (address[] memory);

    /// @notice Checks if address has permission or given permission is force allowed for any address.
    /// @param addr Address to check
    /// @param permissionId Permission to check
    function hasPermission(address addr, uint8 permissionId) external view returns (bool);

    /// @notice Checks if address has all permissions.
    /// @param target Address to check
    /// @param permissionIds A list of permissions to check
    function hasAllPermissions(address target, uint8[] calldata permissionIds) external view returns (bool);

    /// @notice Max different ERC20 token addresses that could be managed by the protocol.
    function maxTokensPerVault() external view returns (uint256);

    /// @notice The delay for committing any governance params.
    function governanceDelay() external view returns (uint256);

    /// @notice The address of the protocol treasury.
    function protocolTreasury() external view returns (address);

    /// @notice Permissions mask which defines if ordinary permission should be reverted.
    /// This bitmask is xored with ordinary mask.
    function forceAllowMask() external view returns (uint256);

    /// @notice Withdraw limit per token per block.
    /// @param token Address of the token
    /// @return Withdraw limit per token per block
    function withdrawLimit(address token) external view returns (uint256);

    /// @notice Addresses that has staged validators.
    function stagedValidatorsAddresses() external view returns (address[] memory);

    /// @notice Timestamp after which staged granted permissions for the given address can be committed.
    /// @param target The given address
    /// @return Zero if there are no staged permission grants, timestamp otherwise
    function stagedValidatorsTimestamps(address target) external view returns (uint256);

    /// @notice Staged validator for the given address.
    /// @param target The given address
    /// @return Validator
    function stagedValidators(address target) external view returns (address);

    /// @notice Addresses that has validators.
    function validatorsAddresses() external view returns (address[] memory);

    /// @notice Address that has validators.
    /// @param i The number of address
    /// @return Validator address
    function validatorsAddress(uint256 i) external view returns (address);

    /// @notice Validator for the given address.
    /// @param target The given address
    /// @return Validator
    function validators(address target) external view returns (address);

    // -------------------  EXTERNAL, MUTATING, GOVERNANCE, IMMEDIATE  -------------------

    /// @notice Rollback all staged validators.
    function rollbackStagedValidators() external;

    /// @notice Revoke validator instantly from the given address.
    /// @param target The given address
    function revokeValidator(address target) external;

    /// @notice Stages a new validator for the given address
    /// @param target The given address
    /// @param validator The validator for the given address
    function stageValidator(address target, address validator) external;

    /// @notice Commits validator for the given address.
    /// @dev Reverts if governance delay has not passed yet.
    /// @param target The given address.
    function commitValidator(address target) external;

    /// @notice Commites all staged validators for which governance delay passed
    /// @return Addresses for which validators were committed
    function commitAllValidatorsSurpassedDelay() external returns (address[] memory);

    /// @notice Rollback all staged granted permission grant.
    function rollbackStagedPermissionGrants() external;

    /// @notice Commits permission grants for the given address.
    /// @dev Reverts if governance delay has not passed yet.
    /// @param target The given address.
    function commitPermissionGrants(address target) external;

    /// @notice Commites all staged permission grants for which governance delay passed.
    /// @return An array of addresses for which permission grants were committed.
    function commitAllPermissionGrantsSurpassedDelay() external returns (address[] memory);

    /// @notice Revoke permission instantly from the given address.
    /// @param target The given address.
    /// @param permissionIds A list of permission ids to revoke.
    function revokePermissions(address target, uint8[] memory permissionIds) external;

    /// @notice Commits staged protocol params.
    /// Reverts if governance delay has not passed yet.
    function commitParams() external;

    // -------------------  EXTERNAL, MUTATING, GOVERNANCE, DELAY  -------------------

    /// @notice Sets new pending params that could have been committed after governance delay expires.
    /// @param newParams New protocol parameters to set.
    function stageParams(Params memory newParams) external;

    /// @notice Stage granted permissions that could have been committed after governance delay expires.
    /// Resets commit delay and permissions if there are already staged permissions for this address.
    /// @param target Target address
    /// @param permissionIds A list of permission ids to grant
    function stagePermissionGrants(address target, uint8[] memory permissionIds) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./utils/IDefaultAccessControl.sol";

interface IUnitPricesGovernance is IDefaultAccessControl, IERC165 {
    // -------------------  EXTERNAL, VIEW  -------------------

    /// @notice Estimated amount of token worth 1 USD staged for commit.
    /// @param token Address of the token
    /// @return The amount of token
    function stagedUnitPrices(address token) external view returns (uint256);

    /// @notice Timestamp after which staged unit prices for the given token can be committed.
    /// @param token Address of the token
    /// @return Timestamp
    function stagedUnitPricesTimestamps(address token) external view returns (uint256);

    /// @notice Estimated amount of token worth 1 USD staged for commit.
    /// @param token Address of the token
    /// @return The amount of token
    function unitPrices(address token) external view returns (uint256);

    // -------------------  EXTERNAL, MUTATING  -------------------

    /// @notice Stage estimated amount of token worth 1 USD staged for commit.
    /// @param token Address of the token
    /// @param value The amount of token
    function stageUnitPrice(address token, uint256 value) external;

    /// @notice Reset staged value
    /// @param token Address of the token
    function rollbackUnitPrice(address token) external;

    /// @notice Commit staged unit price
    /// @param token Address of the token
    function commitUnitPrice(address token) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IProtocolGovernance.sol";

interface IVaultRegistry is IERC721 {
    /// @notice Get Vault for the giver NFT ID.
    /// @param nftId NFT ID
    /// @return vault Address of the Vault contract
    function vaultForNft(uint256 nftId) external view returns (address vault);

    /// @notice Get NFT ID for given Vault contract address.
    /// @param vault Address of the Vault contract
    /// @return nftId NFT ID
    function nftForVault(address vault) external view returns (uint256 nftId);

    /// @notice Checks if the nft is locked for all transfers
    /// @param nft NFT to check for lock
    /// @return `true` if locked, false otherwise
    function isLocked(uint256 nft) external view returns (bool);

    /// @notice Register new Vault and mint NFT.
    /// @param vault address of the vault
    /// @param owner owner of the NFT
    /// @return nft Nft minted for the given Vault
    function registerVault(address vault, address owner) external returns (uint256 nft);

    /// @notice Number of Vaults registered.
    function vaultsCount() external view returns (uint256);

    /// @notice All Vaults registered.
    function vaults() external view returns (address[] memory);

    /// @notice Address of the ProtocolGovernance.
    function protocolGovernance() external view returns (IProtocolGovernance);

    /// @notice Address of the staged ProtocolGovernance.
    function stagedProtocolGovernance() external view returns (IProtocolGovernance);

    /// @notice Minimal timestamp when staged ProtocolGovernance can be applied.
    function stagedProtocolGovernanceTimestamp() external view returns (uint256);

    /// @notice Stage new ProtocolGovernance.
    /// @param newProtocolGovernance new ProtocolGovernance
    function stageProtocolGovernance(IProtocolGovernance newProtocolGovernance) external;

    /// @notice Commit new ProtocolGovernance.
    function commitStagedProtocolGovernance() external;

    /// @notice Approve nft to new address
    /// @dev This can be called only by the Protocol Governance. It is used to disable the strategy for a vault
    /// @param newAddress address that will be approved
    /// @param nft for re-approval
    function adminApprove(address newAddress, uint256 nft) external;

    /// @notice Lock NFT for transfers
    /// @dev Use this method when vault structure is set up and should become immutable. Can be called by owner.
    /// @param nft - NFT to lock
    function lockNft(uint256 nft) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.9;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

interface IContractMeta {
    function contractName() external view returns (string memory);
    function contractNameBytes() external view returns (bytes32);

    function contractVersion() external view returns (string memory);
    function contractVersionBytes() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

interface IDefaultAccessControl is IAccessControlEnumerable {
    /// @notice Checks that the address is contract admin.
    /// @param who Address to check
    /// @return `true` if who is admin, `false` otherwise
    function isAdmin(address who) external view returns (bool);

    function isOperator(address who) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../IProtocolGovernance.sol";

interface IBaseValidator {
    struct ValidatorParams {
        IProtocolGovernance protocolGovernance;
    }

    /// @notice Validator params staged to commit.
    function stagedValidatorParams() external view returns (ValidatorParams memory);

    /// @notice Timestamp after which validator params can be committed.
    function stagedValidatorParamsTimestamp() external view returns (uint256);

    /// @notice Current validator params.
    function validatorParams() external view returns (ValidatorParams memory);

    /// @notice Stage new validator params for commit.
    /// @param newParams New params for commit
    function stageValidatorParams(ValidatorParams calldata newParams) external;

    /// @notice Commit new validator params.
    function commitValidatorParams() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IBaseValidator.sol";

interface IValidator is IBaseValidator, IERC165 {
    // @notice Validate if call can be made to external contract.
    // @param sender Sender of the externalCall method
    // @param addr Address of the called contract
    // @param value Ether value for the call
    // @param data Call data
    function validate(
        address sender,
        address addr,
        uint256 value,
        bytes4 selector,
        bytes calldata data
    ) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IVaultGovernance.sol";

interface IVault is IERC165 {
    /// @notice Checks if the vault is initialized

    function initialized() external view returns (bool);

    /// @notice VaultRegistry NFT for this vault
    function nft() external view returns (uint256);

    /// @notice Address of the Vault Governance for this contract.
    function vaultGovernance() external view returns (IVaultGovernance);

    /// @notice ERC20 tokens under Vault management.
    function vaultTokens() external view returns (address[] memory);

    /// @notice Checks if a token is vault token
    /// @param token Address of the token to check
    /// @return `true` if this token is managed by Vault
    function isVaultToken(address token) external view returns (bool);

    /// @notice Total value locked for this contract.
    /// @dev Generally it is the underlying token value of this contract in some
    /// other DeFi protocol. For example, for USDC Yearn Vault this would be total USDC balance that could be withdrawn for Yearn to this contract.
    /// The tvl itself is estimated in some range. Sometimes the range is exact, sometimes it's not
    /// @return minTokenAmounts Lower bound for total available balances estimation (nth tokenAmount corresponds to nth token in vaultTokens)
    /// @return maxTokenAmounts Upper bound for total available balances estimation (nth tokenAmount corresponds to nth token in vaultTokens)
    function tvl() external view returns (uint256[] memory minTokenAmounts, uint256[] memory maxTokenAmounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../IProtocolGovernance.sol";
import "../IVaultRegistry.sol";
import "./IVault.sol";

interface IVaultGovernance {
    /// @notice Internal references of the contract.
    /// @param protocolGovernance Reference to Protocol Governance
    /// @param registry Reference to Vault Registry
    struct InternalParams {
        IProtocolGovernance protocolGovernance;
        IVaultRegistry registry;
        IVault singleton;
    }

    // -------------------  EXTERNAL, VIEW  -------------------

    /// @notice Timestamp in unix time seconds after which staged Delayed Strategy Params could be committed.
    /// @param nft Nft of the vault
    function delayedStrategyParamsTimestamp(uint256 nft) external view returns (uint256);

    /// @notice Timestamp in unix time seconds after which staged Delayed Protocol Params could be committed.
    function delayedProtocolParamsTimestamp() external view returns (uint256);

    /// @notice Timestamp in unix time seconds after which staged Delayed Protocol Params Per Vault could be committed.
    /// @param nft Nft of the vault
    function delayedProtocolPerVaultParamsTimestamp(uint256 nft) external view returns (uint256);

    /// @notice Timestamp in unix time seconds after which staged Internal Params could be committed.
    function internalParamsTimestamp() external view returns (uint256);

    /// @notice Internal Params of the contract.
    function internalParams() external view returns (InternalParams memory);

    /// @notice Staged new Internal Params.
    /// @dev The Internal Params could be committed after internalParamsTimestamp
    function stagedInternalParams() external view returns (InternalParams memory);

    // -------------------  EXTERNAL, MUTATING  -------------------

    /// @notice Stage new Internal Params.
    /// @param newParams New Internal Params
    function stageInternalParams(InternalParams memory newParams) external;

    /// @notice Commit staged Internal Params.
    function commitInternalParams() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./external/FullMath.sol";
import "./ExceptionsLibrary.sol";

/// @notice CommonLibrary shared utilities
library CommonLibrary {
    uint256 constant DENOMINATOR = 10**9;
    uint256 constant D18 = 10**18;
    uint256 constant YEAR = 365 * 24 * 3600;
    uint256 constant Q128 = 2**128;
    uint256 constant Q96 = 2**96;
    uint256 constant Q48 = 2**48;
    uint256 constant Q160 = 2**160;
    uint256 constant UNI_FEE_DENOMINATOR = 10**6;

    function deviationFactor(uint256 a, uint256 b) internal pure returns (uint256 deviationX96) {
        if (a > b) {
            (a, b) = (b, a);
        }
        if (a == 0) {
            return type(uint256).max;
        }
        if (b / a >= Q160) {
            // overflow for X96 format
            return type(uint256).max;
        }

        deviationX96 = FullMath.mulDiv(b, Q96, a);
    }

    /// @notice Sort addresses using bubble sort. The sorting is done in-place.
    /// @param arr Array of addresses
    function bubbleSort(address[] memory arr) internal pure {
        uint256 l = arr.length;
        for (uint256 i = 0; i < l; ++i) {
            for (uint256 j = i + 1; j < l; ++j) {
                if (arr[i] > arr[j]) {
                    address temp = arr[i];
                    arr[i] = arr[j];
                    arr[j] = temp;
                }
            }
        }
    }

    /// @notice Sort uint256 using bubble sort. The sorting is done in-place.
    /// @param arr Array of uint256
    function bubbleSortUint(uint256[] memory arr) internal pure {
        uint256 l = arr.length;
        for (uint256 i = 0; i < l; ++i) {
            for (uint256 j = i + 1; j < l; ++j) {
                if (arr[i] > arr[j]) {
                    uint256 temp = arr[i];
                    arr[i] = arr[j];
                    arr[j] = temp;
                }
            }
        }
    }

    /// @notice Checks if array of addresses is sorted and all adresses are unique
    /// @param tokens A set of addresses to check
    /// @return `true` if all addresses are sorted and unique, `false` otherwise
    function isSortedAndUnique(address[] memory tokens) internal pure returns (bool) {
        if (tokens.length < 2) {
            return true;
        }
        for (uint256 i = 0; i < tokens.length - 1; ++i) {
            if (tokens[i] >= tokens[i + 1]) {
                return false;
            }
        }
        return true;
    }

    /// @dev
    /// Requires both sets of tokens to be sorted. When tokens are not sorted, it's undefined behavior.
    /// If there is a token in tokensToProject that is not part of tokens and corresponding tokenAmountsToProject > 0, reverts.
    /// Zero token amount is eqiuvalent to missing token
    function projectTokenAmounts(
        address[] memory tokens,
        address[] memory tokensToProject,
        uint256[] memory tokenAmountsToProject
    ) internal pure returns (uint256[] memory) {
        uint256[] memory res = new uint256[](tokens.length);
        uint256 t = 0;
        uint256 tp = 0;
        while ((t < tokens.length) && (tp < tokensToProject.length)) {
            if (tokens[t] < tokensToProject[tp]) {
                res[t] = 0;
                t++;
            } else if (tokens[t] > tokensToProject[tp]) {
                if (tokenAmountsToProject[tp] == 0) {
                    tp++;
                } else {
                    revert("TPS");
                }
            } else {
                res[t] = tokenAmountsToProject[tp];
                t++;
                tp++;
            }
        }
        while (t < tokens.length) {
            res[t] = 0;
            t++;
        }
        return res;
    }

    /// @notice Splits each amount of n tokens from `amounts` into k vaults according to `weights`.
    /// @dev Requires tokens and tokenAmounts to be vector of size n and delegatedTokenAmounts to be k x n matrix
    /// so that delegatedTokenAmounts[i] is a vector of size n
    /// norm is a vector 1 x k
    /// the error is up to k tokens due to rounding
    /// @param amounts Amounts to split, vector n x 1
    /// @param weights Weights of the split, matrix n x k, weights[i] is vector n x 1.
    /// Weights do not need to sum to 1 in each column, but they will be normalized on split.
    function splitAmounts(uint256[] memory amounts, uint256[][] memory weights)
        internal
        pure
        returns (uint256[][] memory)
    {
        uint256 k = weights.length;
        require(k > 0, ExceptionsLibrary.EMPTY_LIST);
        uint256 n = amounts.length;
        require(n > 0, ExceptionsLibrary.EMPTY_LIST);
        uint256[] memory weightsNorm = new uint256[](n);
        for (uint256 i = 0; i < k; ++i) {
            require(weights[i].length == n, ExceptionsLibrary.INVALID_VALUE);
        }
        for (uint256 j = 0; j < n; ++j) {
            weightsNorm[j] = 0;
            for (uint256 i = 0; i < k; ++i) {
                weightsNorm[j] += weights[i][j];
            }
        }
        uint256[][] memory res = new uint256[][](k);
        for (uint256 i = 0; i < k; ++i) {
            res[i] = new uint256[](n);
            for (uint256 j = 0; j < n; ++j) {
                if (weightsNorm[j] == 0) {
                    res[i][j] = amounts[j] / k;
                } else {
                    res[i][j] = (amounts[j] * weights[i][j]) / weightsNorm[j];
                }
            }
        }
        return res;
    }

    function sqrtX96(uint256 xX96) internal pure returns (uint256) {
        uint256 sqX96 = sqrt(xX96);
        return sqX96 << 48;
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, ExceptionsLibrary.INVALID_LENGTH);

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @notice Exceptions stores project`s smart-contracts exceptions
library ExceptionsLibrary {
    string constant ADDRESS_ZERO = "AZ";
    string constant VALUE_ZERO = "VZ";
    string constant EMPTY_LIST = "EMPL";
    string constant NOT_FOUND = "NF";
    string constant INIT = "INIT";
    string constant DUPLICATE = "DUP";
    string constant NULL = "NULL";
    string constant TIMESTAMP = "TS";
    string constant FORBIDDEN = "FRB";
    string constant ALLOWLIST = "ALL";
    string constant LIMIT_OVERFLOW = "LIMO";
    string constant LIMIT_UNDERFLOW = "LIMU";
    string constant INVALID_VALUE = "INV";
    string constant INVARIANT = "INVA";
    string constant INVALID_TARGET = "INVTR";
    string constant INVALID_TOKEN = "INVTO";
    string constant INVALID_INTERFACE = "INVI";
    string constant INVALID_SELECTOR = "INVS";
    string constant INVALID_STATE = "INVST";
    string constant INVALID_LENGTH = "INVL";
    string constant LOCK = "LCKD";
    string constant DISABLED = "DIS";
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @notice Stores permission ids for addresses
library PermissionIdsLibrary {
    // The msg.sender is allowed to register vault
    uint8 constant REGISTER_VAULT = 0;
    // The msg.sender is allowed to create vaults
    uint8 constant CREATE_VAULT = 1;
    // The token is allowed to be transfered by vault
    uint8 constant ERC20_TRANSFER = 2;
    // The token is allowed to be added to vault
    uint8 constant ERC20_VAULT_TOKEN = 3;
    // Trusted protocols that are allowed to be approved of vault ERC20 tokens by any strategy
    uint8 constant ERC20_APPROVE = 4;
    // Trusted protocols that are allowed to be approved of vault ERC20 tokens by trusted strategy
    uint8 constant ERC20_APPROVE_RESTRICTED = 5;
    // Strategy allowed using restricted API
    uint8 constant TRUSTED_STRATEGY = 6;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // diff: original lib works under 0.7.6 with overflows enabled
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            // diff: original uint256 twos = -denominator & denominator;
            uint256 twos = uint256(-int256(denominator)) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // diff: original lib works under 0.7.6 with overflows enabled
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../interfaces/utils/IContractMeta.sol";

abstract contract ContractMeta is IContractMeta {
    // -------------------  EXTERNAL, VIEW  -------------------

    function contractName() external pure returns (string memory) {
        return _bytes32ToString(_contractName());
    }

    function contractNameBytes() external pure returns (bytes32) {
        return _contractName();
    }

    function contractVersion() external pure returns (string memory) {
        return _bytes32ToString(_contractVersion());
    }

    function contractVersionBytes() external pure returns (bytes32) {
        return _contractVersion();
    }

    // -------------------  INTERNAL, VIEW  -------------------

    function _contractName() internal pure virtual returns (bytes32);

    function _contractVersion() internal pure virtual returns (bytes32);

    function _bytes32ToString(bytes32 b) internal pure returns (string memory s) {
        s = new string(32);
        uint256 len = 32;
        for (uint256 i = 0; i < 32; ++i) {
            if (uint8(b[i]) == 0) {
                len = i;
                break;
            }
        }
        assembly {
            mstore(s, len)
            mstore(add(s, 0x20), b)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../interfaces/validators/IBaseValidator.sol";
import "../interfaces/IProtocolGovernance.sol";
import "../libraries/ExceptionsLibrary.sol";

contract BaseValidator is IBaseValidator {
    IBaseValidator.ValidatorParams internal _validatorParams;
    IBaseValidator.ValidatorParams internal _stagedValidatorParams;
    uint256 internal _stagedValidatorParamsTimestamp;

    constructor(IProtocolGovernance protocolGovernance) {
        _validatorParams = IBaseValidator.ValidatorParams({protocolGovernance: protocolGovernance});
    }

    // -------------------  EXTERNAL, VIEW  -------------------

    /// @inheritdoc IBaseValidator
    function stagedValidatorParams() external view returns (ValidatorParams memory) {
        return _stagedValidatorParams;
    }

    /// @inheritdoc IBaseValidator
    function stagedValidatorParamsTimestamp() external view returns (uint256) {
        return _stagedValidatorParamsTimestamp;
    }

    /// @inheritdoc IBaseValidator
    function validatorParams() external view returns (ValidatorParams memory) {
        return _validatorParams;
    }

    // -------------------  EXTERNAL, MUTATING  -------------------

    function stageValidatorParams(IBaseValidator.ValidatorParams calldata newParams) external {
        IProtocolGovernance governance = _validatorParams.protocolGovernance;
        require(governance.isAdmin(msg.sender), ExceptionsLibrary.FORBIDDEN);
        _stagedValidatorParams = newParams;
        _stagedValidatorParamsTimestamp = block.timestamp + governance.governanceDelay();
        emit StagedValidatorParams(tx.origin, msg.sender, newParams, _stagedValidatorParamsTimestamp);
    }

    function commitValidatorParams() external {
        IProtocolGovernance governance = _validatorParams.protocolGovernance;
        require(governance.isAdmin(msg.sender), ExceptionsLibrary.FORBIDDEN);
        _validatorParams = _stagedValidatorParams;
        delete _stagedValidatorParams;
        delete _stagedValidatorParamsTimestamp;
        emit CommittedValidatorParams(tx.origin, msg.sender, _validatorParams);
    }

    /// @notice Emitted when new params are staged for commit
    /// @param origin Origin of the transaction (tx.origin)
    /// @param sender Sender of the call (msg.sender)
    /// @param newParams New params that were staged for commit
    /// @param when When the params could be committed
    event StagedValidatorParams(
        address indexed origin,
        address indexed sender,
        IBaseValidator.ValidatorParams newParams,
        uint256 when
    );

    /// @notice Emitted when new params are staged for commit
    /// @param origin Origin of the transaction (tx.origin)
    /// @param sender Sender of the call (msg.sender)
    /// @param params New params that were staged for commit
    event CommittedValidatorParams(
        address indexed origin,
        address indexed sender,
        IBaseValidator.ValidatorParams params
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/external/univ3/ISwapRouter.sol";
import "../interfaces/external/univ3/IUniswapV3Factory.sol";
import "../interfaces/validators/IValidator.sol";
import "../interfaces/vaults/IVault.sol";
import "../interfaces/IProtocolGovernance.sol";
import "../libraries/CommonLibrary.sol";
import "../libraries/PermissionIdsLibrary.sol";
import "../libraries/ExceptionsLibrary.sol";
import "../utils/ContractMeta.sol";
import "./Validator.sol";

contract UniV3Validator is ContractMeta, Validator {
    using EnumerableSet for EnumerableSet.AddressSet;
    bytes4 public constant EXACT_INPUT_SINGLE_SELECTOR = ISwapRouter.exactInputSingle.selector;
    bytes4 public constant EXACT_INPUT_SELECTOR = ISwapRouter.exactInput.selector;
    bytes4 public constant EXACT_OUTPUT_SINGLE_SELECTOR = ISwapRouter.exactOutputSingle.selector;
    bytes4 public constant EXACT_OUTPUT_SELECTOR = ISwapRouter.exactOutput.selector;
    address public immutable swapRouter;
    IUniswapV3Factory public immutable factory;

    constructor(
        IProtocolGovernance protocolGovernance_,
        address swapRouter_,
        IUniswapV3Factory factory_
    ) BaseValidator(protocolGovernance_) {
        swapRouter = swapRouter_;
        factory = factory_;
    }

    // -------------------  EXTERNAL, VIEW  -------------------

    // @inhericdoc IValidator
    function validate(
        address,
        address addr,
        uint256 value,
        bytes4 selector,
        bytes calldata data
    ) external view {
        require(address(swapRouter) == addr, ExceptionsLibrary.INVALID_TARGET);
        require(value == 0, ExceptionsLibrary.INVALID_VALUE);
        IVault vault = IVault(msg.sender);
        if (selector == EXACT_INPUT_SINGLE_SELECTOR) {
            ISwapRouter.ExactInputSingleParams memory params = abi.decode(data, (ISwapRouter.ExactInputSingleParams));
            _verifySingleCall(vault, params.recipient, params.tokenIn, params.tokenOut, params.fee);
        } else if (selector == EXACT_OUTPUT_SINGLE_SELECTOR) {
            ISwapRouter.ExactOutputSingleParams memory params = abi.decode(data, (ISwapRouter.ExactOutputSingleParams));
            _verifySingleCall(vault, params.recipient, params.tokenIn, params.tokenOut, params.fee);
        } else if (selector == EXACT_INPUT_SELECTOR) {
            ISwapRouter.ExactInputParams memory params = abi.decode(data, (ISwapRouter.ExactInputParams));
            _verifyMultiCall(vault, params.recipient, params.path);
        } else if (selector == EXACT_OUTPUT_SELECTOR) {
            ISwapRouter.ExactOutputParams memory params = abi.decode(data, (ISwapRouter.ExactOutputParams));
            _verifyMultiCall(vault, params.recipient, params.path);
        } else {
            revert(ExceptionsLibrary.INVALID_SELECTOR);
        }
    }

    // -------------------  INTERNAL, VIEW  -------------------

    function _contractName() internal pure override returns (bytes32) {
        return bytes32("UniV3Validator");
    }

    function _contractVersion() internal pure override returns (bytes32) {
        return bytes32("1.0.0");
    }

    function _verifyMultiCall(
        IVault vault,
        address recipient,
        bytes memory path
    ) private view {
        uint256 i;
        address token0;
        address token1;
        uint24 fee;
        uint256 feeMask = (1 << 24) - 1;
        while (path.length - i > 20) {
            // the sample UniV3 path structure is (DAI address,DAI-USDC fee, USDC, USDC-WETH fee, WETH)
            // addresses are 20 bytes, fees are 3 bytes
            assembly {
                let o := add(add(path, 0x20), i)
                let d := mload(o)
                d := shr(72, d)
                fee := and(d, feeMask)
                token0 := shr(24, d)
                d := mload(add(o, 23))
                token1 := shr(96, d)
            }
            _verifyPathItem(token0, token1, fee);
            i += 23;
        }
        require(recipient == address(vault), ExceptionsLibrary.INVALID_TARGET);
        require(vault.isVaultToken(token1), ExceptionsLibrary.INVALID_TOKEN);
    }

    function _verifySingleCall(
        IVault vault,
        address recipient,
        address tokenIn,
        address tokenOut,
        uint24 fee
    ) private view {
        require(recipient == address(vault), ExceptionsLibrary.INVALID_TARGET);
        require(vault.isVaultToken(tokenOut), ExceptionsLibrary.INVALID_TOKEN);
        _verifyPathItem(tokenIn, tokenOut, fee);
    }

    function _verifyPathItem(
        address tokenIn,
        address tokenOut,
        uint24 fee
    ) private view {
        require(tokenIn != tokenOut, ExceptionsLibrary.INVALID_TOKEN);
        IProtocolGovernance protocolGovernance = _validatorParams.protocolGovernance;
        address pool = factory.getPool(tokenIn, tokenOut, fee);
        require(
            protocolGovernance.hasPermission(pool, PermissionIdsLibrary.ERC20_APPROVE),
            ExceptionsLibrary.FORBIDDEN
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../interfaces/validators/IValidator.sol";
import "./BaseValidator.sol";

abstract contract Validator is IValidator, ERC165, BaseValidator {
    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return (interfaceId == type(IValidator).interfaceId) || super.supportsInterface(interfaceId);
    }
}