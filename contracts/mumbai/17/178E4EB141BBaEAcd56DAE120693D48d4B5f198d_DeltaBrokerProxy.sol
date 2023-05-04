// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Achthar <[email protected]>
*
* Implementation of the 1Delta brokerage proxy.
/******************************************************************************/

import {LibModules} from "./libraries/LibModules.sol";
import {IModuleConfig} from "./interfaces/IModuleConfig.sol";

contract DeltaBrokerProxy {
    constructor(address _contractOwner, address _moduleConfigModule) payable {
        LibModules.setContractOwner(_contractOwner);

        // Add the moduleConfig external function from the moduleConfigModule
        IModuleConfig.ModuleConfig[] memory cut = new IModuleConfig.ModuleConfig[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IModuleConfig.configureModules.selector;
        cut[0] = IModuleConfig.ModuleConfig({
            moduleAddress: _moduleConfigModule,
            action: IModuleConfig.ModuleConfigAction.Add,
            functionSelectors: functionSelectors
        });
        LibModules.configureModules(cut);
    }

    // An efficient multicall implementation for 1Delta Accounts across multiple modules
    // The modules are validated before anything is called.
    function multicallMultiModule(address[] calldata modules, bytes[] calldata data) external payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        LibModules.ModuleStorage storage ds;
        bytes32 position = LibModules.MODULE_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }

        for (uint256 i = 0; i < data.length; i++) {
            // we verify that the module exists
            address moduleAddress = modules[i];
            require(ds.moduleExists[moduleAddress], "Broker: Invalid module");
            (bool success, bytes memory result) = moduleAddress.delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }

    // An efficient multicall implementation for 1Delta Accounts on a single module
    // The module is validated and then the delegatecalls are executed.
    function multicallSingleModule(address module, bytes[] calldata data) external payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        address moduleAddress = module;

        LibModules.ModuleStorage storage ds;
        bytes32 position = LibModules.MODULE_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }

        // important check that the input is in fact an implementation by 1DeltaDAO
        require(ds.moduleExists[moduleAddress], "Broker: Invalid module");
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = moduleAddress.delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }

    // Find module for function that is called and execute the
    // function if a module is found and return any value.
    fallback() external payable {
        LibModules.ModuleStorage storage ds;
        bytes32 position = LibModules.MODULE_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get module from function selector
        address module = ds.selectorToModule[msg.sig];
        require(module != address(0), "Broker: Function does not exist");
        // Execute external function from module using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the module
            let result := delegatecall(gas(), module, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Achthar - 1delta.io
* Modified Diamond module handling library
* external contract.
/******************************************************************************/

import {IModuleConfig} from "../interfaces/IModuleConfig.sol";

// solhint-disable max-line-length

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibModules {
    bytes32 constant MODULE_STORAGE_POSITION = keccak256("diamond.standard.module.storage");

    struct ModuleAddressAndPosition {
        address moduleAddress;
        uint96 functionSelectorPosition; // position in moduleFunctionSelectors.functionSelectors array
    }

    struct ModuleFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 moduleAddressPosition; // position of moduleAddress in moduleAddresses array
    }

    struct ModuleStorage {
        // maps function selector to the module address and
        // the position of the selector in the moduleFunctionSelectors.selectors array
        mapping(bytes4 => ModuleAddressAndPosition) selectorToModuleAndPosition;
        // maps selector to module
        mapping(bytes4 => address) selectorToModule;
        // maps module addresses to function selectors
        mapping(address => ModuleFunctionSelectors) moduleFunctionSelectors;
        // module addresses
        address[] moduleAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // Used to query if a module exits
        mapping(address => bool) moduleExists;
        // owner of the contract
        address contractOwner;
    }

    function moduleStorage() internal pure returns (ModuleStorage storage ds) {
        bytes32 position = MODULE_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        ModuleStorage storage ds = moduleStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = moduleStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == moduleStorage().contractOwner, "LibModuleConfig: Must be contract owner");
    }

    event Upgrade(IModuleConfig.ModuleConfig[] _moduleChange);

    // Internal function version of diamondCut
    function configureModules(IModuleConfig.ModuleConfig[] memory _moduleChange) internal {
        for (uint256 moduleIndex; moduleIndex < _moduleChange.length; moduleIndex++) {
            IModuleConfig.ModuleConfigAction action = _moduleChange[moduleIndex].action;
            if (action == IModuleConfig.ModuleConfigAction.Add) {
                addFunctions(_moduleChange[moduleIndex].moduleAddress, _moduleChange[moduleIndex].functionSelectors);
            } else if (action == IModuleConfig.ModuleConfigAction.Replace) {
                replaceFunctions(_moduleChange[moduleIndex].moduleAddress, _moduleChange[moduleIndex].functionSelectors);
            } else if (action == IModuleConfig.ModuleConfigAction.Remove) {
                removeFunctions(_moduleChange[moduleIndex].moduleAddress, _moduleChange[moduleIndex].functionSelectors);
            } else {
                revert("LibModuleConfig: Incorrect ModuleConfigAction");
            }
        }
        emit Upgrade(_moduleChange);
    }

    function addFunctions(address _moduleAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibModuleConfig: No selectors in module to cut");
        ModuleStorage storage ds = moduleStorage();
        require(_moduleAddress != address(0), "LibModuleConfig: Add module can't be address(0)");
        uint96 selectorPosition = uint96(ds.moduleFunctionSelectors[_moduleAddress].functionSelectors.length);
        // add new module address if it does not exist
        if (selectorPosition == 0) {
            addModule(ds, _moduleAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldModuleAddress = ds.selectorToModuleAndPosition[selector].moduleAddress;
            require(oldModuleAddress == address(0), "LibModuleConfig: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _moduleAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _moduleAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibModuleConfig: No selectors in module to cut");
        ModuleStorage storage ds = moduleStorage();
        require(_moduleAddress != address(0), "LibModuleConfig: Add module can't be address(0)");
        uint96 selectorPosition = uint96(ds.moduleFunctionSelectors[_moduleAddress].functionSelectors.length);
        // add new module address if it does not exist
        if (selectorPosition == 0) {
            addModule(ds, _moduleAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldModuleAddress = ds.selectorToModuleAndPosition[selector].moduleAddress;
            require(oldModuleAddress != _moduleAddress, "LibModuleConfig: Can't replace function with same function");
            removeFunction(ds, oldModuleAddress, selector);
            addFunction(ds, selector, selectorPosition, _moduleAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _moduleAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibModuleConfig: No selectors in module to cut");
        ModuleStorage storage ds = moduleStorage();
        // if function does not exist then do nothing and return
        require(_moduleAddress == address(0), "LibModuleConfig: Remove module address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldModuleAddress = ds.selectorToModuleAndPosition[selector].moduleAddress;
            removeFunction(ds, oldModuleAddress, selector);
        }
    }

    function addModule(ModuleStorage storage ds, address _moduleAddress) internal {
        enforceHasContractCode(_moduleAddress, "LibModuleConfig: New module has no code");
        ds.moduleFunctionSelectors[_moduleAddress].moduleAddressPosition = ds.moduleAddresses.length;
        ds.moduleAddresses.push(_moduleAddress);
        ds.moduleExists[_moduleAddress] = true;
    }

    function addFunction(
        ModuleStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _moduleAddress
    ) internal {
        ds.selectorToModuleAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.moduleFunctionSelectors[_moduleAddress].functionSelectors.push(_selector);
        ds.selectorToModuleAndPosition[_selector].moduleAddress = _moduleAddress;
        ds.selectorToModule[_selector] = _moduleAddress;
    }

    function removeFunction(
        ModuleStorage storage ds,
        address _moduleAddress,
        bytes4 _selector
    ) internal {
        require(_moduleAddress != address(0), "LibModuleConfig: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_moduleAddress != address(this), "LibModuleConfig: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToModuleAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.moduleFunctionSelectors[_moduleAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.moduleFunctionSelectors[_moduleAddress].functionSelectors[lastSelectorPosition];
            ds.moduleFunctionSelectors[_moduleAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToModuleAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.moduleFunctionSelectors[_moduleAddress].functionSelectors.pop();
        delete ds.selectorToModuleAndPosition[_selector];
        delete ds.selectorToModule[_selector];

        // if no more selectors for module address then delete the module address
        if (lastSelectorPosition == 0) {
            // replace module address with last module address and delete last module address
            uint256 lastModuleAddressPosition = ds.moduleAddresses.length - 1;
            uint256 moduleAddressPosition = ds.moduleFunctionSelectors[_moduleAddress].moduleAddressPosition;
            if (moduleAddressPosition != lastModuleAddressPosition) {
                address lastModuleAddress = ds.moduleAddresses[lastModuleAddressPosition];
                ds.moduleAddresses[moduleAddressPosition] = lastModuleAddress;
                ds.moduleFunctionSelectors[lastModuleAddress].moduleAddressPosition = moduleAddressPosition;
            }
            ds.moduleAddresses.pop();
            delete ds.moduleFunctionSelectors[_moduleAddress].moduleAddressPosition;
            ds.moduleExists[_moduleAddress] = false;
        }
    }

    function initializeModuleConfig(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "LibModuleConfig: _init address has no code");
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
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
/**
 * Vendored on December 23, 2021 from:
 * https://github.com/mudgen/diamond-3-hardhat/blob/7feb995/contracts/interfaces/IModuleConfig.sol
 */
pragma solidity ^0.8.0;

interface IModuleConfig {
    enum ModuleConfigAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct ModuleConfig {
        address moduleAddress;
        ModuleConfigAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _moduleConfig Contains the module addresses and function selectors
    function configureModules(ModuleConfig[] calldata _moduleConfig) external;
}