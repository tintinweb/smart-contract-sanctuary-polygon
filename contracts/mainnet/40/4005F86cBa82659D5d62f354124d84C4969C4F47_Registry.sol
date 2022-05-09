// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import '../interfaces/IRegistry.sol';

/// @title Stores all the modules addresses
contract Registry is IRegistry {
    address public override governance;
    address public override positionManagerFactoryAddress;

    mapping(bytes32 => Entry) public modules;
    bytes32[] public moduleKeys;

    ///@notice emitted when governance address is changed
    ///@param newGovernance the new governance address
    event GovernanceChanged(address newGovernance);

    ///@notice emitted when a contract is added to registry
    ///@param newContract address of the new contract
    ///@param moduleId keccak of module name
    event ContractCreated(address newContract, bytes32 moduleId);

    ///@notice emitted when a contract address is updated
    ///@param oldContract address of the contract before update
    ///@param newContract address of the contract after update
    ///@param moduleId keccak of module name
    event ContractChanged(address oldContract, address newContract, bytes32 moduleId);

    ///@notice emitted when a module is switched on/off
    ///@param moduleId keccak of module name
    ///@param isActive true if module is switched on, false otherwise
    event ModuleSwitched(bytes32 moduleId, bool isActive);

    constructor(address _governance) {
        governance = _governance;
    }

    ///@notice sets the Position manager factory address
    ///@param _positionManagerFactory the address of the position manager factory
    function setPositionManagerFactory(address _positionManagerFactory) external onlyGovernance {
        positionManagerFactoryAddress = _positionManagerFactory;
    }

    ///@notice change the address of the governance
    ///@param _governance the address of the new governance
    function changeGovernance(address _governance) external onlyGovernance {
        governance = _governance;
        emit GovernanceChanged(_governance);
    }

    ///@notice Register a module
    ///@param _id keccak256 of module id string
    ///@param _contractAddress address of the new module
    function addNewContract(bytes32 _id, address _contractAddress) external onlyGovernance {
        require(modules[_id].contractAddress == address(0), 'Registry::addNewContract: Entry already exists.');
        modules[_id] = Entry({contractAddress: _contractAddress, activated: true});
        moduleKeys.push(_id);
        emit ContractCreated(_contractAddress, _id);
    }

    ///@notice Changes a module's address
    ///@param _id keccak256 of module id string
    ///@param _newContractAddress address of the new module
    function changeContract(bytes32 _id, address _newContractAddress) external onlyGovernance {
        require(modules[_id].contractAddress != address(0), 'Registry::changeContract: Entry does not exist.');
        //Begin timelock
        emit ContractChanged(modules[_id].contractAddress, _newContractAddress, _id);
        modules[_id].contractAddress = _newContractAddress;
    }

    ///@notice Toggle global state of a module
    ///@param _id keccak256 of module id string
    ///@param _activated boolean to activate or deactivate module
    function switchModuleState(bytes32 _id, bool _activated) external onlyGovernance {
        require(modules[_id].contractAddress != address(0), 'Registry::switchModuleState: Entry does not exist.');
        modules[_id].activated = _activated;
        emit ModuleSwitched(_id, _activated);
    }

    ///@notice Get the keys for all modules
    ///@return bytes32[] all module keys
    function getModuleKeys() external view override returns (bytes32[] memory) {
        return moduleKeys;
    }

    ///@notice Get the address of a module for a given key
    ///@param _id keccak256 of module id string
    ///@return address of the module
    function moduleAddress(bytes32 _id) external view override returns (address) {
        return modules[_id].contractAddress;
    }

    ///@notice Get the state of a module
    ///@param _id keccak256 of module id string
    ///@return bool activated
    function isActive(bytes32 _id) public view override returns (bool) {
        return modules[_id].activated;
    }

    ///@notice modifier to check if the sender is the governance contract
    modifier onlyGovernance() {
        require(msg.sender == governance, 'Registry::onlyGovernance: Call must come from governance.');
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

interface IRegistry {
    struct Entry {
        address contractAddress;
        bool activated;
    }

    ///@notice return the address of PositionManagerFactory
    ///@return address of PositionManagerFactory
    function positionManagerFactoryAddress() external view returns (address);

    ///@notice return the address of Governance
    ///@return address of Governance
    function governance() external view returns (address);

    ///@notice return the address of Governance
    ///@return address of Governance
    function getModuleKeys() external view returns (bytes32[] memory);

    ///@notice return the address of Governance
    ///@return address of Governance
    function isActive(bytes32 _id) external view returns (bool);

    ///@notice return the address of Governance
    ///@return address of Governance
    function moduleAddress(bytes32 _id) external view returns (address);
}