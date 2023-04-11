// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/plugin-pattern)

pragma solidity ^0.8.0;

import "../interface/IRouter.sol";

abstract contract Router is IRouter {

    fallback() external payable virtual {
    /// @dev delegate calls the appropriate implementation smart contract for a given function.
        address pluginAddress = getImplementationForFunction(msg.sig);
        _delegate(pluginAddress);
    }

    /// @dev delegateCalls an `implementation` smart contract.
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /// @dev Unimplemented. Returns the implementation contract address for a given function signature.
    function getImplementationForFunction(bytes4 _functionSelector) public view virtual returns (address);
}

// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/plugin-pattern)

pragma solidity ^0.8.0;

import "./IDefaultPluginSet.sol";

interface IBaseRouter is IDefaultPluginSet {
    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Adds a new plugin to the router.
    function addPlugin(Plugin memory plugin) external;

    /// @dev Updates an existing plugin in the router, or overrides a default plugin.
    function updatePlugin(Plugin memory plugin) external;

    /// @dev Removes an existing plugin from the router.
    function removePlugin(string memory pluginName) external;
}

// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/plugin-pattern)

pragma solidity ^0.8.0;

import "./IPlugin.sol";

interface IDefaultPluginSet is IPlugin {
    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns all plugins stored.
    function getAllPlugins() external view returns (Plugin[] memory);

    /// @dev Returns all functions that belong to the given plugin contract.
    function getAllFunctionsOfPlugin(string memory pluginName) external view returns (PluginFunction[] memory);

    /// @dev Returns the plugin metadata for a given function.
    function getPluginForFunction(bytes4 functionSelector) external view returns (PluginMetadata memory);

    /// @dev Returns the plugin's implementation smart contract address.
    function getPluginImplementation(string memory pluginName) external view returns (address);

    /// @dev Returns the plugin metadata and functions for a given plugin.
    function getPlugin(string memory pluginName) external view returns (Plugin memory);
}

// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/plugin-pattern)

pragma solidity ^0.8.0;

interface IPlugin {
    /*///////////////////////////////////////////////////////////////
                                Structs
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice A plugin's metadata.
     *
     *  @param name             The unique name of the plugin.
     *  @param metadataURI      The URI where the metadata for the plugin lives.
     *  @param implementation   The implementation smart contract address of the plugin.
     */
    struct PluginMetadata {
        string name;
        string metadataURI;
        address implementation;
    }

    /**
     *  @notice An interface to describe a plugin's function.
     *
     *  @param functionSelector    The 4 byte selector of the function.
     *  @param functionSignature   Function representation as a string. E.g. "transfer(address,address,uint256)"
     */
    struct PluginFunction {
        bytes4 functionSelector;
        string functionSignature;
    }

    /**
     *  @notice An interface to describe a plug-in.
     *
     *  @param metadata     The plugin's metadata; it's name, metadata URI and implementation contract address.
     *  @param functions    The functions that belong to the plugin.
     */
    struct Plugin {
        PluginMetadata metadata;
        PluginFunction[] functions;
    }

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @dev Emitted when a plugin is added; emitted for each function of the plugin.
    event PluginAdded(address indexed pluginAddress, bytes4 indexed functionSelector, string functionSignature);

    /// @dev Emitted when plugin is updated; emitted for each function of the plugin.
    event PluginUpdated(
        address indexed oldPluginAddress,
        address indexed newPluginAddress,
        bytes4 indexed functionSelector,
        string functionSignature
    );

    /// @dev Emitted when a plugin is removed; emitted for each function of the plugin.
    event PluginRemoved(address indexed pluginAddress, bytes4 indexed functionSelector, string functionSignature);
}

// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/plugin-pattern)

pragma solidity ^0.8.0;

interface IRouter {
    fallback() external payable;

    function getImplementationForFunction(bytes4 _functionSelector) external view returns (address);
}

// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/plugin-pattern)

pragma solidity ^0.8.0;

// Interface
import "../interface/IBaseRouter.sol";

// Core
import "../core/Router.sol";

// Utils
import "./utils/StringSet.sol";
import "./utils/DefaultPluginSet.sol";
import "./utils/PluginState.sol";

abstract contract BaseRouter is IBaseRouter, Router, PluginState {
    using StringSet for StringSet.Set;

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @notice The DefaultPluginSet that stores default plugins of the router.
    address public immutable defaultPluginSet;

    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(Plugin[] memory _plugins) {

        DefaultPluginSet map = new DefaultPluginSet();
        defaultPluginSet = address(map);

        uint256 len = _plugins.length;

        for (uint256 i = 0; i < len; i += 1) {
            map.setPlugin(_plugins[i]);
        }
    }

    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Adds a new plugin to the router.
    function addPlugin(Plugin memory _plugin) external {
        require(_canSetPlugin(), "BaseRouter: caller not authorized.");

        _addPlugin(_plugin);
    }

    /// @dev Updates an existing plugin in the router, or overrides a default plugin.
    function updatePlugin(Plugin memory _plugin) external {
        require(_canSetPlugin(), "BaseRouter: caller not authorized.");

        _updatePlugin(_plugin);
    }

    /// @dev Removes an existing plugin from the router.
    function removePlugin(string memory _pluginName) external {
        require(_canSetPlugin(), "BaseRouter: caller not authorized.");

        _removePlugin(_pluginName);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Returns all plugins stored. Override default lugins stored in router are
     *          given precedence over default plugins in DefaultPluginSet.
     */
    function getAllPlugins() external view returns (Plugin[] memory allPlugins) {
        Plugin[] memory defaultPlugins = IDefaultPluginSet(defaultPluginSet).getAllPlugins();
        uint256 defaultPluginsLen = defaultPlugins.length;

        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();
        string[] memory names = data.pluginNames.values();
        uint256 namesLen = names.length;

        uint256 overrides = 0;
        for (uint256 i = 0; i < defaultPluginsLen; i += 1) {
            if (data.pluginNames.contains(defaultPlugins[i].metadata.name)) {
                overrides += 1;
            }
        }

        uint256 total = (namesLen + defaultPluginsLen) - overrides;

        allPlugins = new Plugin[](total);
        uint256 idx = 0;

        for (uint256 i = 0; i < defaultPluginsLen; i += 1) {
            string memory name = defaultPlugins[i].metadata.name;
            if (!data.pluginNames.contains(name)) {
                allPlugins[idx] = defaultPlugins[i];
                idx += 1;
            }
        }

        for (uint256 i = 0; i < namesLen; i += 1) {
            allPlugins[idx] = data.plugins[names[i]];
            idx += 1;
        }
    }

    /// @dev Returns the plugin metadata and functions for a given plugin.
    function getPlugin(string memory _pluginName) public view returns (Plugin memory) {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();
        bool isLocalPlugin = data.pluginNames.contains(_pluginName);

        return isLocalPlugin ? data.plugins[_pluginName] : IDefaultPluginSet(defaultPluginSet).getPlugin(_pluginName);
    }

    /// @dev Returns the plugin's implementation smart contract address.
    function getPluginImplementation(string memory _pluginName) external view returns (address) {
        return getPlugin(_pluginName).metadata.implementation;
    }

    /// @dev Returns all functions that belong to the given plugin contract.
    function getAllFunctionsOfPlugin(string memory _pluginName) external view returns (PluginFunction[] memory) {
        return getPlugin(_pluginName).functions;
    }

    /// @dev Returns the plugin metadata for a given function.
    function getPluginForFunction(bytes4 _functionSelector) public view returns (PluginMetadata memory) {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();
        PluginMetadata memory metadata = data.pluginMetadata[_functionSelector];

        bool isLocalPlugin = metadata.implementation != address(0);

        return isLocalPlugin ? metadata : IDefaultPluginSet(defaultPluginSet).getPluginForFunction(_functionSelector);
    }

    /// @dev Returns the plugin implementation address stored in router, for the given function.
    function getImplementationForFunction(bytes4 _functionSelector)
        public
        view
        override
        returns (address pluginAddress)
    {
        return getPluginForFunction(_functionSelector).implementation;
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether a plugin can be set in the given execution context.
    function _canSetPlugin() internal view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/plugin-pattern)

pragma solidity ^0.8.0;

// Interface
import "../../interface/IDefaultPluginSet.sol";

// Extensions
import "./PluginState.sol";

contract DefaultPluginSet is IDefaultPluginSet, PluginState {
    using StringSet for StringSet.Set;

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @notice The deployer of DefaultPluginSet.
    address private deployer;

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor() {
        deployer = msg.sender;
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Stores a plugin in the DefaultPluginSet.
    function setPlugin(Plugin memory _plugin) external {
        require(msg.sender == deployer, "DefaultPluginSet: unauthorized caller.");
        _addPlugin(_plugin);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns all plugins stored.
    function getAllPlugins() external view returns (Plugin[] memory allPlugins) {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();

        string[] memory names = data.pluginNames.values();
        uint256 len = names.length;

        allPlugins = new Plugin[](len);

        for (uint256 i = 0; i < len; i += 1) {
            allPlugins[i] = data.plugins[names[i]];
        }
    }

    /// @notice Returns the plugin metadata and functions for a given plugin.
    function getPlugin(string memory _pluginName) public view returns (Plugin memory) {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();
        require(data.pluginNames.contains(_pluginName), "DefaultPluginSet: plugin does not exist.");
        return data.plugins[_pluginName];
    }

    /// @notice Returns the plugin's implementation smart contract address.
    function getPluginImplementation(string memory _pluginName) external view returns (address) {
        return getPlugin(_pluginName).metadata.implementation;
    }

    /// @notice Returns all functions that belong to the given plugin contract.
    function getAllFunctionsOfPlugin(string memory _pluginName) external view returns (PluginFunction[] memory) {
        return getPlugin(_pluginName).functions;
    }

    /// @notice Returns the plugin metadata for a given function.
    function getPluginForFunction(bytes4 _functionSelector) external view returns (PluginMetadata memory) {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();
        PluginMetadata memory metadata = data.pluginMetadata[_functionSelector];
        require(metadata.implementation != address(0), "DefaultPluginSet: no plugin for function.");
        return metadata;
    }
}

// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/plugin-pattern)

pragma solidity ^0.8.0;

// Interface
import "../../interface/IPlugin.sol";

// Extensions
import "./StringSet.sol";

library PluginStateStorage {
    bytes32 public constant PLUGIN_STATE_STORAGE_POSITION = keccak256("plugin.state.storage");

    struct Data {
        /// @dev Set of names of all plugins stored.
        StringSet.Set pluginNames;
        /// @dev Mapping from plugin name => `Plugin` i.e. plugin metadata and functions.
        mapping(string => IPlugin.Plugin) plugins;
        /// @dev Mapping from function selector => plugin metadata of the plugin the function belongs to.
        mapping(bytes4 => IPlugin.PluginMetadata) pluginMetadata;
    }

    function pluginStateStorage() internal pure returns (Data storage pluginStateData) {
        bytes32 position = PLUGIN_STATE_STORAGE_POSITION;
        assembly {
            pluginStateData.slot := position
        }
    }
}

contract PluginState is IPlugin {
    using StringSet for StringSet.Set;

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Stores a new plugin in the contract.
    function _addPlugin(Plugin memory _plugin) internal {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();

        string memory name = _plugin.metadata.name;

        require(data.pluginNames.add(name), "PluginState: plugin already exists.");
        data.plugins[name].metadata = _plugin.metadata;

        require(_plugin.metadata.implementation != address(0), "PluginState: adding plugin without implementation.");

        uint256 len = _plugin.functions.length;
        for (uint256 i = 0; i < len; i += 1) {
            require(
                _plugin.functions[i].functionSelector ==
                    bytes4(keccak256(abi.encodePacked(_plugin.functions[i].functionSignature))),
                "PluginState: fn selector and signature mismatch."
            );
            require(
                data.pluginMetadata[_plugin.functions[i].functionSelector].implementation == address(0),
                "PluginState: plugin already exists for function."
            );

            data.pluginMetadata[_plugin.functions[i].functionSelector] = _plugin.metadata;
            data.plugins[name].functions.push(_plugin.functions[i]);

            emit PluginAdded(
                _plugin.metadata.implementation,
                _plugin.functions[i].functionSelector,
                _plugin.functions[i].functionSignature
            );
        }
    }

    /// @dev Updates / overrides an existing plugin in the contract.
    function _updatePlugin(Plugin memory _plugin) internal {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();

        string memory name = _plugin.metadata.name;
        require(data.pluginNames.contains(name), "PluginState: plugin does not exist.");

        address oldImplementation = data.plugins[name].metadata.implementation;
        require(_plugin.metadata.implementation != oldImplementation, "PluginState: re-adding same plugin.");

        data.plugins[name].metadata = _plugin.metadata;

        PluginFunction[] memory oldFunctions = data.plugins[name].functions;
        uint256 oldFunctionsLen = oldFunctions.length;

        delete data.plugins[name].functions;

        for (uint256 i = 0; i < oldFunctionsLen; i += 1) {
            delete data.pluginMetadata[oldFunctions[i].functionSelector];
        }

        uint256 len = _plugin.functions.length;
        for (uint256 i = 0; i < len; i += 1) {
            require(
                _plugin.functions[i].functionSelector ==
                    bytes4(keccak256(abi.encodePacked(_plugin.functions[i].functionSignature))),
                "PluginState: fn selector and signature mismatch."
            );

            data.pluginMetadata[_plugin.functions[i].functionSelector] = _plugin.metadata;
            data.plugins[name].functions.push(_plugin.functions[i]);

            emit PluginUpdated(
                oldImplementation,
                _plugin.metadata.implementation,
                _plugin.functions[i].functionSelector,
                _plugin.functions[i].functionSignature
            );
        }
    }

    /// @dev Removes an existing plugin from the contract.
    function _removePlugin(string memory _pluginName) internal {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();

        require(data.pluginNames.remove(_pluginName), "PluginState: plugin does not exist.");

        address implementation = data.plugins[_pluginName].metadata.implementation;
        PluginFunction[] memory pluginFunctions = data.plugins[_pluginName].functions;
        delete data.plugins[_pluginName];

        uint256 len = pluginFunctions.length;
        for (uint256 i = 0; i < len; i += 1) {
            emit PluginRemoved(
                implementation,
                pluginFunctions[i].functionSelector,
                pluginFunctions[i].functionSignature
            );
            delete data.pluginMetadata[pluginFunctions[i].functionSelector];
        }
    }
}

// SPDX-License-Identifier: Apache 2.0
// @author: thirdweb (https://github.com/thirdweb-dev/plugin-pattern)

pragma solidity ^0.8.0;

library StringSet {
    struct Set {
        // Storage of set values
        string[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(string => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, string memory value) private returns (bool) {
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
    function _remove(Set storage set, string memory value) private returns (bool) {
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
                string memory lastValue = set._values[lastIndex];

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
    function _contains(Set storage set, string memory value) private view returns (bool) {
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
    function _at(Set storage set, uint256 index) private view returns (string memory) {
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
    function _values(Set storage set) private view returns (string[] memory) {
        return set._values;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Set storage set, string memory value) internal returns (bool) {
        return _add(set, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Set storage set, string memory value) internal returns (bool) {
        return _remove(set, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Set storage set, string memory value) internal view returns (bool) {
        return _contains(set, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Set storage set) internal view returns (uint256) {
        return _length(set);
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
    function at(Set storage set, uint256 index) internal view returns (string memory) {
        return _at(set, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Set storage set) internal view returns (string[] memory) {
        return _values(set);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "lib/plugin-pattern/src/presets/BaseRouter.sol";

contract SimpleRouter is BaseRouter {
    
    address public deployer;

    constructor(Plugin[] memory _plugins) BaseRouter(_plugins) {
        deployer = msg.sender;
    }

    /// @dev Returns whether plug-in can be set in the given execution context.
    function _canSetPlugin() internal view virtual override returns (bool) {
        return msg.sender == deployer;
    }
}