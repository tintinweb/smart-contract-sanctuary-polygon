// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    This contract is only required for intermediate, library-like contracts.

    SPDX-License-Identifier: Apache
*/

pragma solidity ^0.8.9;
pragma experimental "ABIEncoderV2";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IController } from "../interfaces/IController.sol";

/**
 * @title IntegrationRegistry
 * @author Set Protocol
 *
 * The IntegrationRegistry holds state relating to the Modules and the integrations they are connected with.
 * The state is combined into a single Registry to allow governance updates to be aggregated to one contract.
 */
contract IntegrationRegistry is Ownable {

    /* ============ Events ============ */

    event IntegrationAdded(address indexed _module, address indexed _adapter, string _integrationName);
    event IntegrationRemoved(address indexed _module, address indexed _adapter, string _integrationName);
    event IntegrationEdited(
        address indexed _module,
        address _newAdapter,
        string _integrationName
    );

    /* ============ State Variables ============ */

    // Address of the Controller contract
    IController public controller;

    // Mapping of module => integration identifier => adapter address
    mapping(address => mapping(bytes32 => address)) private integrations;

    /* ============ Constructor ============ */

    /**
     * Initializes the controller
     *
     * @param _controller          Instance of the controller
     */
    constructor(IController _controller) {
        controller = _controller;
    }

    /* ============ External Functions ============ */

    /**
     * GOVERNANCE FUNCTION: Add a new integration to the registry
     *
     * @param  _module       The address of the module associated with the integration
     * @param  _name         Human readable string identifying the integration
     * @param  _adapter      Address of the adapter contract to add
     */
    function addIntegration(
        address _module,
        string memory _name,
        address _adapter
    )
        public
        onlyOwner
    {
        bytes32 hashedName = _nameHash(_name);
        require(controller.isModule(_module), "Must be valid module.");
        require(integrations[_module][hashedName] == address(0), "Integration exists already.");
        require(_adapter != address(0), "Adapter address must exist.");

        integrations[_module][hashedName] = _adapter;

        emit IntegrationAdded(_module, _adapter, _name);
    }

    /**
     * GOVERNANCE FUNCTION: Batch add new adapters. Reverts if exists on any module and name
     *
     * @param  _modules      Array of addresses of the modules associated with integration
     * @param  _names        Array of human readable strings identifying the integration
     * @param  _adapters     Array of addresses of the adapter contracts to add
     */
    function batchAddIntegration(
        address[] memory _modules,
        string[] memory _names,
        address[] memory _adapters
    )
        external
        onlyOwner
    {
        // Storing modules count to local variable to save on invocation
        uint256 modulesCount = _modules.length;

        require(modulesCount > 0, "Modules must not be empty");
        require(modulesCount == _names.length, "Module and name lengths mismatch");
        require(modulesCount == _adapters.length, "Module and adapter lengths mismatch");

        for (uint256 i = 0; i < modulesCount; i++) {
            // Add integrations to the specified module. Will revert if module and name combination exists
            addIntegration(
                _modules[i],
                _names[i],
                _adapters[i]
            );
        }
    }

    /**
     * GOVERNANCE FUNCTION: Edit an existing integration on the registry
     *
     * @param  _module       The address of the module associated with the integration
     * @param  _name         Human readable string identifying the integration
     * @param  _adapter      Address of the adapter contract to edit
     */
    function editIntegration(
        address _module,
        string memory _name,
        address _adapter
    )
        public
        onlyOwner
    {
        bytes32 hashedName = _nameHash(_name);

        require(controller.isModule(_module), "Must be valid module.");
        require(integrations[_module][hashedName] != address(0), "Integration does not exist.");
        require(_adapter != address(0), "Adapter address must exist.");

        integrations[_module][hashedName] = _adapter;

        emit IntegrationEdited(_module, _adapter, _name);
    }

    /**
     * GOVERNANCE FUNCTION: Batch edit adapters for modules. Reverts if module and
     * adapter name don't map to an adapter address
     *
     * @param  _modules      Array of addresses of the modules associated with integration
     * @param  _names        Array of human readable strings identifying the integration
     * @param  _adapters     Array of addresses of the adapter contracts to add
     */
    function batchEditIntegration(
        address[] memory _modules,
        string[] memory _names,
        address[] memory _adapters
    )
        external
        onlyOwner
    {
        // Storing name count to local variable to save on invocation
        uint256 modulesCount = _modules.length;

        require(modulesCount > 0, "Modules must not be empty");
        require(modulesCount == _names.length, "Module and name lengths mismatch");
        require(modulesCount == _adapters.length, "Module and adapter lengths mismatch");

        for (uint256 i = 0; i < modulesCount; i++) {
            // Edits integrations to the specified module. Will revert if module and name combination does not exist
            editIntegration(
                _modules[i],
                _names[i],
                _adapters[i]
            );
        }
    }

    /**
     * GOVERNANCE FUNCTION: Remove an existing integration on the registry
     *
     * @param  _module       The address of the module associated with the integration
     * @param  _name         Human readable string identifying the integration
     */
    function removeIntegration(address _module, string memory _name) external onlyOwner {
        bytes32 hashedName = _nameHash(_name);
        require(integrations[_module][hashedName] != address(0), "Integration does not exist.");

        address oldAdapter = integrations[_module][hashedName];
        delete integrations[_module][hashedName];

        emit IntegrationRemoved(_module, oldAdapter, _name);
    }

    /* ============ External Getter Functions ============ */

    /**
     * Get integration adapter address associated with the key
     *
     * @param  _module       The address of the module associated with the integration
     * @param  _name         Human readable string identifying the integration
     *
     * @return               Address of adapter
     */
    function getIntegrationAdapter(address _module, string memory _name) external view returns (address) {
        return integrations[_module][_nameHash(_name)];
    }

    /**
     * Check if adapter name is valid
     *
     * @param  _module       The address of the module associated with the integration
     * @param  _name         Human readable string identifying the integration
     *
     * @return               Boolean indicating if valid
     */
    function isValidIntegration(address _module, string memory _name) external view returns (bool) {
        return integrations[_module][_nameHash(_name)] != address(0);
    }

    /* ============ Internal Functions ============ */

    /**
     * Hashes the string and returns a bytes32 value
     */
    function _nameHash(string memory _name) internal pure returns(bytes32) {
        return keccak256(bytes(_name));
    }
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache
*/
pragma solidity ^0.8.9;

import { IIntegrationRegistry } from "./IIntegrationRegistry.sol";

interface IController {
    function addSet(address _setToken) external;
    function feeRecipient() external view returns(address);
    function getModuleFee(address _module, uint256 _feeType) external view returns(uint256);
    function isModule(address _module) external view returns(bool);
    function isSet(address _setToken) external view returns(bool);
    function isSystemContract(address _contractAddress) external view returns (bool);
    function resourceId(uint256 _id) external view returns(address);
    function getIntegrationRegistry() external view returns (IIntegrationRegistry);
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache
*/

pragma solidity ^0.8.9;

interface IIntegrationRegistry {
    function addIntegration(address _module, string memory _id, address _wrapper) external;
    function getIntegrationAdapter(address _module, string memory _id) external view returns(address);
    function getIntegrationAdapterWithHash(address _module, bytes32 _id) external view returns(address);
    function isValidIntegration(address _module, string memory _id) external view returns(bool);
}