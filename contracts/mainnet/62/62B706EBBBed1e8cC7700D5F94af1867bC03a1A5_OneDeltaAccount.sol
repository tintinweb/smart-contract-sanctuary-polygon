// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Achthar - 1delta.io
* Title:  1Delta Margin Trading Account
* Implementation of a diamond that fetches its modules from another contract.
/******************************************************************************/

import {GeneralStorage, LibGeneral} from "./libraries/LibGeneral.sol";
import {IModuleProvider} from "./interfaces/IModuleProvider.sol";

contract OneDeltaAccount {
    // provider is immutable and therefore stored in the bytecode
    IModuleProvider private immutable _moduleProvider;

    function moduleProvider() external view returns (IModuleProvider) {
        return _moduleProvider;
    }

    // the constructor only initializes the module provider
    // the modules are provided by views in this module provider contract
    // the  cut module is not existing in this contract, it is implemented in the provider
    constructor(address provider) {
        GeneralStorage storage ds = LibGeneral.generalStorage();
        // we put the provider in the  storage, too
        ds.moduleProvider = provider;
        ds.factory = msg.sender;

        // assign immutable
        _moduleProvider = IModuleProvider(provider);
    }

    // An efficient multicall implementation for 1Delta Accounts across multiple modules
    // The modules are validated before anything is called.
    function multicallMultiModule(address[] calldata modules, bytes[] calldata data) external payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        // we check that all modules exist in a single call
        require(!_moduleProvider.checkIfInvalidModules(modules));
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = modules[i].delegatecall(data[i]);

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
        // important check that the input is in fact an implementation by 1DeltaDAO
        require(_moduleProvider.moduleExists(moduleAddress));
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
        // get module from function selector
        address module = _moduleProvider.selectorToModule(msg.sig);
        require(module != address(0), "OneDeltaAccount: Function does not exist");
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

struct GeneralStorage {
    address factory;
    address moduleProvider;
}

library LibGeneral {
    bytes32 constant GENERAL_STORAGE = keccak256("1DeltaAccount.storage.general");

    function generalStorage() internal pure returns (GeneralStorage storage gs) {
        bytes32 position = GENERAL_STORAGE;
        assembly {
            gs.slot := position
        }
    }
}

abstract contract WithGeneralStorage {
    function gs() internal pure returns (GeneralStorage storage) {
        return LibGeneral.generalStorage();
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