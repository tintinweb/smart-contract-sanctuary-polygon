// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Achthar - 1delta.io
* A Management contract for a dimaond of which the modules are provided by an
* external contract.
/******************************************************************************/

import {IModuleProvider} from "./interfaces/IModuleProvider.sol";

// solhint-disable max-line-length

contract OneDeltaModuleManager is IModuleProvider {
    event Upgrade(IModuleProvider.ModuleConfig[] _moduleConfig);
    // maps function selector to the module address and
    // the position of the selector in the _moduleFunctionSelectors.selectors array
    mapping(bytes4 => ModuleAddressAndPosition) private _selectorToModuleAndPosition;
    // maps selector to module
    mapping(bytes4 => address) public selectorToModule;
    // maps module addresses to function selectors
    mapping(address => ModuleFunctionSelectors) private _moduleFunctionSelectors;
    // module addresses
    address[] private _moduleAddresses;
    // Used to query if a contract implements an interface.
    // Used to implement ERC-165.
    mapping(bytes4 => bool) public supportedInterfaces;
    // Used to query if a module exits
    mapping(address => bool) private _moduleExists;
    // owner of the contract
    address public contractOwner;

    function moduleExists(address moduleAddress) external view returns (bool) {
        return _moduleExists[moduleAddress];
    }

    function checkIfInvalidModules(address[] memory modules) external view returns (bool isInvalid) {
        for (uint256 i; i < modules.length; ) {
            if (!_moduleExists[modules[i]]) return true;
            unchecked {
                i++;
            }
        }
    }

    function selectorToModuleAndPosition(bytes4 selector) external view returns (ModuleAddressAndPosition memory) {
        return _selectorToModuleAndPosition[selector];
    }

    function selectorsToModules(bytes4[] memory selectors) external view returns (address[] memory moduleAddressList) {
        for (uint256 i = 0; i < selectors.length; i++) {
            moduleAddressList[i] = selectorToModule[selectors[i]];
        }
    }

    function moduleFunctionSelectors(address functionAddress) external view returns (ModuleFunctionSelectors memory) {
        return _moduleFunctionSelectors[functionAddress];
    }

    function moduleAddresses() external view returns (address[] memory addresses) {
        addresses = _moduleAddresses;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        contractOwner = msg.sender;
    }

    modifier enforceIsContractOwner() {
        require(msg.sender == contractOwner, "ModuleManager: Must be contract owner");
        _;
    }

    function setContractOwner(address _newOwner) external enforceIsContractOwner {
        address previousOwner = contractOwner;
        contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    // External function version of configureModules
    // It has no initializer as the proxy is not supposed to require storage that has to be initialized
    function configureModules(IModuleProvider.ModuleConfig[] memory _moduleConfig) external enforceIsContractOwner {
        for (uint256 moduleIndex; moduleIndex < _moduleConfig.length; moduleIndex++) {
            IModuleProvider.ModuleManagement action = _moduleConfig[moduleIndex].action;
            if (action == IModuleProvider.ModuleManagement.Add) {
                addFunctions(_moduleConfig[moduleIndex].moduleAddress, _moduleConfig[moduleIndex].functionSelectors);
            } else if (action == IModuleProvider.ModuleManagement.Replace) {
                replaceFunctions(_moduleConfig[moduleIndex].moduleAddress, _moduleConfig[moduleIndex].functionSelectors);
            } else if (action == IModuleProvider.ModuleManagement.Remove) {
                removeFunctions(_moduleConfig[moduleIndex].moduleAddress, _moduleConfig[moduleIndex].functionSelectors);
            } else {
                revert("ModuleConfig: Incorrect ModuleManagement");
            }
        }
        emit Upgrade(_moduleConfig);
    }

    function addFunctions(address _moduleAddress, bytes4[] memory _functionSelectors) private {
        require(_functionSelectors.length > 0, "ModuleConfig: No selectors in module to cut");
        require(_moduleAddress != address(0), "ModuleConfig: Add module can't be address(0)");
        uint96 selectorPosition = uint96(_moduleFunctionSelectors[_moduleAddress].functionSelectors.length);
        // add new module address if it does not exist
        if (selectorPosition == 0) {
            addModule(_moduleAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldModuleAddress = _selectorToModuleAndPosition[selector].moduleAddress;
            require(oldModuleAddress == address(0), "ModuleConfig: Can't add function that already exists");
            addFunction(selector, selectorPosition, _moduleAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _moduleAddress, bytes4[] memory _functionSelectors) private {
        require(_functionSelectors.length > 0, "ModuleConfig: No selectors in module to cut");
        require(_moduleAddress != address(0), "ModuleConfig: Add module can't be address(0)");
        uint96 selectorPosition = uint96(_moduleFunctionSelectors[_moduleAddress].functionSelectors.length);
        // add new module address if it does not exist
        if (selectorPosition == 0) {
            addModule(_moduleAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldModuleAddress = _selectorToModuleAndPosition[selector].moduleAddress;
            require(oldModuleAddress != _moduleAddress, "ModuleConfig: Can't replace function with same function");
            removeFunction(oldModuleAddress, selector);
            addFunction(selector, selectorPosition, _moduleAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _moduleAddress, bytes4[] memory _functionSelectors) private {
        require(_functionSelectors.length > 0, "ModuleConfig: No selectors in module to cut");
        // if function does not exist then do nothing and return
        require(_moduleAddress == address(0), "ModuleConfig: Remove module address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldModuleAddress = _selectorToModuleAndPosition[selector].moduleAddress;
            removeFunction(oldModuleAddress, selector);
        }
    }

    function addModule(address _moduleAddress) internal {
        enforceHasContractCode(_moduleAddress, "ModuleConfig: New module has no code");
        _moduleFunctionSelectors[_moduleAddress].moduleAddressPosition = _moduleAddresses.length;
        _moduleAddresses.push(_moduleAddress);
        _moduleExists[_moduleAddress] = true;
    }

    function addFunction(
        bytes4 _selector,
        uint96 _selectorPosition,
        address _moduleAddress
    ) internal {
        _selectorToModuleAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        _moduleFunctionSelectors[_moduleAddress].functionSelectors.push(_selector);
        _selectorToModuleAndPosition[_selector].moduleAddress = _moduleAddress;
        selectorToModule[_selector] = _moduleAddress;
    }

    function removeFunction(address _moduleAddress, bytes4 _selector) internal {
        require(_moduleAddress != address(0), "ModuleConfig: Can't remove function that doesn't exist");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = _selectorToModuleAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = _moduleFunctionSelectors[_moduleAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = _moduleFunctionSelectors[_moduleAddress].functionSelectors[lastSelectorPosition];
            _moduleFunctionSelectors[_moduleAddress].functionSelectors[selectorPosition] = lastSelector;
            _selectorToModuleAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        _moduleFunctionSelectors[_moduleAddress].functionSelectors.pop();
        delete _selectorToModuleAndPosition[_selector];
        delete selectorToModule[_selector];

        // if no more selectors for module address then delete the module address
        if (lastSelectorPosition == 0) {
            // replace module address with last module address and delete last module address
            uint256 lastModuleAddressPosition = _moduleAddresses.length - 1;
            uint256 moduleAddressPosition = _moduleFunctionSelectors[_moduleAddress].moduleAddressPosition;
            if (moduleAddressPosition != lastModuleAddressPosition) {
                address lastModuleAddress = _moduleAddresses[lastModuleAddressPosition];
                _moduleAddresses[moduleAddressPosition] = lastModuleAddress;
                _moduleFunctionSelectors[lastModuleAddress].moduleAddressPosition = moduleAddressPosition;
            }
            _moduleAddresses.pop();
            delete _moduleFunctionSelectors[_moduleAddress].moduleAddressPosition;
            _moduleExists[_moduleAddress] = false;
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IModuleProvider {
    enum ModuleManagement {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct ModuleConfig {
        address moduleAddress;
        ModuleManagement action;
        bytes4[] functionSelectors;
    }

    struct ModuleAddressAndPosition {
        address moduleAddress;
        uint96 functionSelectorPosition; // position in moduleFunctionSelectors.functionSelectors array
    }

    struct ModuleFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 moduleAddressPosition; // position of moduleAddress in moduleAddresses array
    }

    function selectorToModuleAndPosition(bytes4 selector) external view returns (ModuleAddressAndPosition memory);

    function moduleFunctionSelectors(address functionAddress) external view returns (ModuleFunctionSelectors memory);

    function moduleAddresses() external view returns (address[] memory);

    function supportedInterfaces(bytes4 _interface) external view returns (bool);

    function selectorToModule(bytes4 selector) external view returns (address);

    function selectorsToModules(bytes4[] memory selectors) external view returns (address[] memory moduleAddressList);

    function moduleExists(address moduleAddress) external view returns (bool);

    function checkIfInvalidModules(address[] memory modules) external view returns (bool);
}