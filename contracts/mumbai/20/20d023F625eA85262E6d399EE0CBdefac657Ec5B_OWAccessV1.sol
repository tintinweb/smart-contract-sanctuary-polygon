// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {Unsafe} from "../utils/Unsafe.sol";
import {Counters} from "../utils/Counters.sol";
import {Roles} from "../utils/Roles.sol";
import {EnumerableSet} from "../utils/EnumerableSet.sol";

import {AccessBase} from "./AccessBase.sol";
import {ContractController} from "../core/controller/ContractController.sol";

contract OWAccessV1 is AccessBase {
    using Unsafe for uint256;
    using Counters for Counters.Counter;
    using Roles for Roles.Role;
    using EnumerableSet for EnumerableSet.AddressSet;

    constructor() {
        /******** contractController setting ********/
        isActive = true;

        _initialSetAdmin();
    }

    function contractActive() public override(ContractController) onlyAdmin {
        super.contractActive();
    }

    function contractUnActive() public override(ContractController) onlyAdmin {
        super.contractUnActive();
    }

    ///////////
    // Admin //
    ///////////

    function _initialSetAdmin() private {
        roleIds.increment();

        roles[ADMIN_ID] = "Admin";
        bytes32 name = keccak256(bytes("Admin"));
        roleByName[name] = ADMIN_ID;
        _addMember(ADMIN_ID, _msgSender());
    }

    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    function _onlyAdmin() private view {
        if (!isAdmin(_msgSender())) {
            revert Unauthorized();
        }
    }

    function isAdmin(address _member) public view returns (bool) {
        return isMember(ADMIN_ID, _member);
    }

    //////////
    // Role //
    //////////

    function addRole(string calldata _role)
        external
        whenContractActive
        onlyAdmin
    {
        if (isExistRoleByName(_role)) {
            revert AlreadyExistRole();
        }
        if (bytes(_role).length < 1) {
            revert InvalidRole();
        }

        roleIds.increment();
        uint256 roleId = roleIds.current();

        roles[roleId] = _role;
        bytes32 name = keccak256(bytes(_role));
        roleByName[name] = roleId;

        emitCreate("Role", roleId);
    }

    //////////////
    // Role Set //
    //////////////

    function setRole(uint256 _roleId, string calldata _role)
        external
        onlyAdmin
    {
        if (!isExistRoleById(_roleId)) {
            revert InvalidRoleId();
        }
        if (isExistRoleByName(_role)) {
            revert AlreadyExistRole();
        }
        if (bytes(_role).length < 1) {
            revert InvalidRole();
        }

        bytes32 name = keccak256(bytes(roles[_roleId]));
        delete roleByName[name];
        roles[_roleId] = _role;
        bytes32 newName = keccak256(bytes(_role));
        roleByName[newName] = _roleId;
    }

    function removeRole(uint256 _roleId) external onlyAdmin {
        if (!isExistRoleById(_roleId)) {
            revert InvalidRoleId();
        }
        if (_roleId == ADMIN_ID) {
            revert CanNotRemoveAdmin();
        }

        bytes32 name = keccak256(bytes(roles[_roleId]));
        delete roleByName[name];
        delete roles[_roleId];
        delete members[_roleId];
        delete accounts[_roleId];
    }

    //////////////
    // Role Get //
    //////////////

    function isExistRoleById(uint256 _roleId) public view returns (bool) {
        return
            _roleId != 0 &&
            _roleId <= roleIds.current() &&
            0 < bytes(roles[_roleId]).length;
    }

    function isExistRoleByName(string memory _role) public view returns (bool) {
        return getRoleIdByName(_role) != 0;
    }

    function getRoleIdByName(string memory _role)
        public
        view
        returns (uint256)
    {
        bytes32 name = keccak256(bytes(_role));

        return roleByName[name];
    }

    function getRoleById(uint256 _roleId)
        external
        view
        returns (string memory)
    {
        if (!isExistRoleById(_roleId)) {
            revert InvalidRoleId();
        }

        return roles[_roleId];
    }

    function getRoles() external view returns (string[] memory) {
        uint256 roleCount;

        for (uint256 i = 0; i <= roleIds.current(); i = i.increment()) {
            if (0 < bytes(roles[i]).length) {
                roleCount = roleCount.increment();
            }
        }

        string[] memory roleList = new string[](roleCount);
        uint256 index;

        for (uint256 i = 0; i <= roleIds.current(); i = i.increment()) {
            if (0 < bytes(roles[i]).length) {
                roleList[index] = roles[i];
                index = index.increment();
            }
        }

        return roleList;
    }

    ////////////
    // Member //
    ////////////

    function addMember(uint256 _roleId, address _member) external {
        if (!isAdmin(_msgSender()) && !isMember(_roleId, _msgSender())) {
            revert Unauthorized();
        }

        _addMember(_roleId, _member);
    }

    function removeMember(uint256 _roleId, address _member) external onlyAdmin {
        if (_roleId == ADMIN_ID) {
            revert CanNotRemoveAdmin();
        }
        _removeMember(_roleId, _member);
    }

    function renounceMember(uint256 _roleId) external {
        if (!isMember(_roleId, _msgSender())) {
            revert Unauthorized();
        }

        _removeMember(_roleId, _msgSender());
    }

    function _addMember(uint256 _roleId, address _member) private {
        if (!isExistRoleById(_roleId)) {
            revert InvalidRoleId();
        }

        members[_roleId].add(_member);
        accounts[_roleId].add(_member);
        emit MemberAdded(_roleId, _member, block.timestamp);
    }

    function _removeMember(uint256 _roleId, address _member) private {
        if (!isExistRoleById(_roleId)) {
            revert InvalidRoleId();
        }

        members[_roleId].remove(_member);
        accounts[_roleId].remove(_member);
        emit MemberRemoved(_roleId, _member, block.timestamp);
    }

    ////////////////
    // Member Get //
    ////////////////

    function isMember(uint256 _roleId, address _member)
        public
        view
        returns (bool)
    {
        if (!isExistRoleById(_roleId)) {
            revert InvalidRoleId();
        }

        return members[_roleId].has(_member);
    }

    function getMember(uint256 _roleId, uint256 _index)
        external
        view
        returns (address)
    {
        if (!isExistRoleById(_roleId)) {
            revert InvalidRoleId();
        }

        return accounts[_roleId].at(_index);
    }

    function getMembers(uint256 _roleId)
        external
        view
        returns (address[] memory)
    {
        if (!isExistRoleById(_roleId)) {
            revert InvalidRoleId();
        }

        return accounts[_roleId].values();
    }

    function getMemberCount(uint256 _roleId) external view returns (uint256) {
        if (!isExistRoleById(_roleId)) {
            revert InvalidRoleId();
        }

        return accounts[_roleId].length();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library Unsafe {
    function increment(uint256 x) internal pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../openzeppelin/contracts/utils/Counters.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {Counters} from "../utils/Counters.sol";
import {Roles} from "../utils/Roles.sol";
import {EnumerableSet} from "../utils/EnumerableSet.sol";

import {OWBase} from "../core/OWBase.sol";
import {ContractController} from "../core/controller/ContractController.sol";
import {AccessError} from "../errors/AccessError.sol";

contract AccessBase is OWBase, ContractController, AccessError {
    Counters.Counter public roleIds;

    uint256 public constant ADMIN_ID = 1;

    mapping(uint256 => string) internal roles;
    mapping(uint256 => Roles.Role) internal members;
    mapping(uint256 => EnumerableSet.AddressSet) internal accounts;

    mapping(bytes32 => uint256) internal roleByName;

    event MemberAdded(
        uint256 indexed roleId,
        address indexed member,
        uint256 timestamp
    );

    event MemberRemoved(
        uint256 indexed roleId,
        address indexed member,
        uint256 timestamp
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {Context} from "../../utils/Context.sol";

import {ContractControllerError} from "../../errors/ContractControllerError.sol";

abstract contract ContractController is ContractControllerError, Context {
    bool public isActive;

    event ContractActive(address account, uint256 timestamp);
    event ContractUnActive(address account, uint256 timestamp);

    /////////////////////
    // Contract Active //
    /////////////////////

    modifier whenContractActive() {
        if (!isActive) {
            revert UnActive();
        }
        _;
    }

    function contractUnActive() public virtual {
        if (!isActive) {
            revert AlreadyUnActive();
        }

        isActive = false;
        emit ContractUnActive(_msgSender(), block.timestamp);
    }

    function contractActive() public virtual {
        if (isActive) {
            revert AlreadyActive();
        }

        isActive = true;
        emit ContractActive(_msgSender(), block.timestamp);
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract OWBase {
    enum AccountType {
        Provider,
        Operator,
        Associator,
        Creator,
        DAO
    }

    event Create(string target, uint256 targetId, uint256 timestamp);

    function emitCreate(string memory _target, uint256 _targetId) internal {
        emit Create(_target, _targetId, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface AccessError {
    ////////////
    // Common //
    ////////////

    error Unauthorized();
    error CanNotRemoveAdmin();

    //////////
    // Role //
    //////////

    error AlreadyExistRole();
    error InvalidRole();
    error InvalidRoleId();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../openzeppelin/contracts/utils/Context.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ContractControllerError {
    error UnActive();
    error AlreadyUnActive();
    error AlreadyActive();
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