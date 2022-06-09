// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./Governable.sol";
import "./../interfaces/utils/IRegistry.sol";

/**
 * @title IRegistry
 * @author leather.tv.fi
 * @notice Tracks the contracts of the Solaverse.
 * The governance can set the contract addresses and anyone can look them up.
 * A key is a unique identifier for each contract. Use [`get(key)`](#get) or [`tryGet(key)`](#tryget) to get the address of the contract. Enumerate the keys with [`length()`](#length) and [`getKey(index)`](#getkey).
*/
contract Registry is IRegistry, Governable {

    /***************************************
    TYPE DEFINITIONS
    ***************************************/

    struct RegistryEntry {
        uint256 index;
        address value;
    }

    /***************************************
    STATE VARIABLES
    ***************************************/

    /// @notice contract name => contract address
    mapping(string => RegistryEntry) private _addresses;

    /// @notice index => key
    mapping(uint256 => string) private _keys;

    /// @notice The number of unique keys.
    uint256 public override length;

    /**
     * @notice Constructs the registry contract.
     * @param _governance The address of the governance.
     */
    // solhint-disable-next-line no-empty-blocks
    constructor(address _governance) Governable(_governance) { }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Gets the `value` of a given `key`.
     * Reverts if the key is not in the mapping.
     * @param _key The key to query.
     * @return value The value of the key.
    */
    function get(string calldata _key) external view override returns (address value) {
        RegistryEntry memory entry = _addresses[_key];
        require(entry.index != 0, "key not in mapping");
        return entry.value;
    }

    /**
     * @notice Gets the `value` of a given `key`.
     * Fails gracefully if the key is not in the mapping.
     * @param _key The key to query.
     * @return success True if the key was found, false otherwise.
     * @return value The value of the key or zero if it was not found.
    */
    function tryGet(string calldata _key) external view override returns (bool success, address value) {
        RegistryEntry memory entry = _addresses[_key];
        return (entry.index == 0) ? (false, address(0x0)) : (true, entry.value);
    }

    /**
     * @notice Gets the `key` of a given `index`.
     * @dev Iterable [1,length].
     * @param _index The index to query.
     * @return key The key at that index.
     */
    function getKey(uint256 _index) external view override returns (string memory key) {
        require(_index != 0 && _index <= length, "index out of range");
        return _keys[_index];
    }

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets keys and values.
     * Can only be called by the current governance.
     * @param keys The keys to set.
     * @param values The values to set.
    */
    function set(string[] calldata keys, address[] calldata values) external override onlyGovernance {
        uint256 len = keys.length;
        require(len == values.length, "length mismatch");
        
        for (uint256 i = 0; i < len; i++) {
            require(values[i] != address(0), "cannot set zero address");
            string memory key = keys[i];
            address value = values[i];
            RegistryEntry memory entry = _addresses[key];
           
            // add new record
            if (entry.index == 0) {
                entry.index = ++length; // autoincrement from 1
                _keys[entry.index] = key;
            }

            // store record
            entry.value = value;
            _addresses[key] = entry;
            emit RecordSet(key, value);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "../interfaces/utils/IGovernable.sol";

/**
 * @title Governable
 * @author leather.tv
 * @notice Enforces access control for important functions.
 */
contract Governable is IGovernable {

    /***************************************
    STATE VARIABLES
    ***************************************/

    /// @notice  The governor.
    address private _governance;

    /// @notice governance to take over.
    address private _pendingGovernance;

    /// @notice true if governance is locked, otherwise false.
    bool private _locked;

    /**
     * @notice Constructs the `Governable` contract.
     * @param _governor The address of the governor.
    */
    constructor(address _governor) {
        require(_governor != address(0x0), "zero address governance");
        _governance = _governor;
        _pendingGovernance = address(0x0);
        _locked = false;
    }

    /***************************************
    MODIFIERS
    ***************************************/

    /**
      * @notice onlyGovernance modifier.
      * - can only be called by governor
      * - can only be called while unlocked
    */ 
    modifier onlyGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _governance, "!governance");
        _;
    }

    /**
     * @notice onlyPendingGovernance modifier.
     * - can only be called by pending governor
     * - can only be called while unlocked
    */
    modifier onlyPendingGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _pendingGovernance, "!pending governance");
        _;
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Returns address of the current governor.
     * @return governance The governor address.
    */
    function governance() public view override returns (address) {
        return _governance;
    }

    /**
     * @notice Returns address of the pending governor.
     * @return pendingGovernance The pending governor address.
    */
    function pendingGovernance() external view override returns (address) {
        return _pendingGovernance;
    }

    /**
     * @notice Returns true if governance is locked.
     * @return locked True, if governance is locked.
    */
    function governanceIsLocked() external view override returns (bool) {
        return _locked;
    }

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current governor.
     * @param _pendingGovernor The new governor.
    */
    function setPendingGovernance(address _pendingGovernor) external override onlyGovernance {
        _pendingGovernance = _pendingGovernor;
        emit GovernancePending(_pendingGovernor);
    }

    /**
     * @notice Accepts the governance role.
     * Can only be called by the pending governor.
    */
    function acceptGovernance() external override onlyPendingGovernance {
        require(_pendingGovernance != address(0x0), "zero governance");
        address oldGovernance = _governance;
        _governance = _pendingGovernance;
        _pendingGovernance = address(0x0);
        emit GovernanceTransferred(oldGovernance, _governance);
    }

    /**
     * @notice Permanently locks this contract's governance role and any of its functions that require the role.
     * This action cannot be reversed.
     * Before you call it, ask yourself:
     *   - Is the contract self-sustaining?
     *   - Is there a chance you will need governance privileges in the future?
     * Can only be called by the current governance.
     */
    function lockGovernance() external override onlyGovernance {
        _locked = true;
        // intentionally not using address(0x0), see re-initialization exploit
        _governance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        _pendingGovernance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        emit GovernanceTransferred(msg.sender, address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF));
        emit GovernanceLocked();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;


/**
 * @title IRegistry
 * @author leather.tv.fi
 * @notice Tracks the contracts of the Solaverse.
 * The governance can set the contract addresses and anyone can look them up.
 * A key is a unique identifier for each contract. Use [`get(key)`](#get) or [`tryGet(key)`](#tryget) to get the address of the contract. Enumerate the keys with [`length()`](#length) and [`getKey(index)`](#getkey).
*/
interface IRegistry {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a record is set.
    event RecordSet(string indexed key, address indexed value);

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice The number of unique keys.
    function length() external view returns (uint256);

    /**
     * @notice Gets the `value` of a given `key`.
     * Reverts if the key is not in the mapping.
     * @param _key The key to query.
     * @return value The value of the key.
     */
    function get(string calldata _key) external view returns (address value);

    /**
     * @notice Gets the `value` of a given `key`.
     * Fails gracefully if the key is not in the mapping.
     * @param _key The key to query.
     * @return success True if the key was found, false otherwise.
     * @return value The value of the key or zero if it was not found.
     */
    function tryGet(string calldata _key) external view returns (bool success, address value);

    /**
     * @notice Gets the `key` of a given `index`.
     * @dev Iterable [1,length].
     * @param _index The index to query.
     * @return key The key at that index.
     */
    function getKey(uint256 _index) external view returns (string memory key);

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets keys and values.
     * Can only be called by the current governance.
     * @param _keys The keys to set.
     * @param _values The values to set.
     */
    function set(string[] calldata _keys, address[] calldata _values) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title Governable
 * @author leather.tv
 * @notice Enforces access control for important functions.
 */
interface IGovernable {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when pending governance is set.
    event GovernancePending(address pendingGovernance);

    /// @notice Emitted when governance is set.
    event GovernanceTransferred(address oldGovernance, address newGovernance);

    /// @notice Emitted when governance is locked.
    event GovernanceLocked();

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Returns address of the current governor.
     * @return governance The governor address.
    */
    function governance() external view returns (address);

    /**
     * @notice Returns address of the pending governor.
     * @return pendingGovernance The pending governor address.
    */
    function pendingGovernance() external view returns (address);

    /**
     * @notice Returns true if governance is locked.
     * @return locked True, if governance is locked.
    */
    function governanceIsLocked() external view returns (bool);

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current governor.
     * @param _pendingGovernor The new governor.
    */
    function setPendingGovernance(address _pendingGovernor) external;

    /**
     * @notice Accepts the governance role.
     * Can only be called by the pending governor.
    */
    function acceptGovernance() external;

    /**
     * @notice Permanently locks this contract's governance role and any of its functions that require the role.
     * This action cannot be reversed.
     * Before you call it, ask yourself:
     *   - Is the contract self-sustaining?
     *   - Is there a chance you will need governance privileges in the future?
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function lockGovernance() external;
}