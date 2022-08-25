// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.7.6;
pragma abicoder v2;

import '../interfaces/IRegistry.sol';

/// @title Stores all the governance variables
contract Registry is IRegistry {
    address public override governance;
    address public override positionManagerFactoryAddress;
    int24 public override maxTwapDeviation;
    uint32 public override twapDuration;

    mapping(address => bool) public override whitelistedKeepers;
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
    ///@param moduleId keccak of contract name
    event ContractChanged(address oldContract, address newContract, bytes32 moduleId);

    ///@notice emitted when a module is switched on/off
    ///@param moduleId keccak of module name
    ///@param isActive true if module is switched on, false otherwise
    event ModuleSwitched(bytes32 moduleId, bool isActive);

    constructor(
        address _governance,
        int24 _maxTwapDeviation,
        uint32 _twapDuration
    ) {
        require(_governance != address(0), 'RCG');
        require(_twapDuration != 0, 'RCT');

        governance = _governance;
        maxTwapDeviation = _maxTwapDeviation;
        twapDuration = _twapDuration;
    }

    ///@notice modifier to check if the sender is the governance contract
    modifier onlyGovernance() {
        require(msg.sender == governance, 'ROG');
        _;
    }

    ///@notice sets the Position manager factory address
    ///@param _positionManagerFactory the address of the position manager factory
    function setPositionManagerFactory(address _positionManagerFactory) external onlyGovernance {
        require(_positionManagerFactory != address(0), 'RF0');
        positionManagerFactoryAddress = _positionManagerFactory;
    }

    ///@notice change the address of the governance
    ///@param _governance the address of the new governance
    function changeGovernance(address _governance) external onlyGovernance {
        require(_governance != address(0), 'RG0');
        governance = _governance;
        emit GovernanceChanged(_governance);
    }

    ///@notice Register a contract
    ///@param _id keccak256 of contract name
    ///@param _contractAddress address of the new module
    ///@param _defaultValue default value of the module
    ///@param _activatedByDefault true if the module is activated by default, false otherwise
    function addNewContract(
        bytes32 _id,
        address _contractAddress,
        bytes32 _defaultValue,
        bool _activatedByDefault
    ) external onlyGovernance {
        require(modules[_id].contractAddress == address(0), 'RAE');
        modules[_id] = Entry({
            contractAddress: _contractAddress,
            activated: true,
            defaultData: _defaultValue,
            activatedByDefault: _activatedByDefault
        });
        moduleKeys.push(_id);
        emit ContractCreated(_contractAddress, _id);
    }

    ///@notice Changes a module's address
    ///@param _id keccak256 of module id string
    ///@param _newContractAddress address of the new module
    function changeContract(bytes32 _id, address _newContractAddress) external onlyGovernance {
        require(modules[_id].contractAddress != address(0), 'RCE');
        modules[_id].contractAddress = _newContractAddress;
        emit ContractChanged(modules[_id].contractAddress, _newContractAddress, _id);
    }

    ///@notice Toggle global state of a module
    ///@param _id keccak256 of module id string
    ///@param _activated boolean to activate or deactivate module
    function switchModuleState(bytes32 _id, bool _activated) external onlyGovernance {
        require(modules[_id].contractAddress != address(0), 'RSE');
        modules[_id].activated = _activated;
        emit ModuleSwitched(_id, _activated);
    }

    ///@notice adds a new whitelisted keeper
    ///@param _keeper address of the new keeper
    function addKeeperToWhitelist(address _keeper) external override onlyGovernance {
        require(!whitelistedKeepers[_keeper], 'RKW');
        whitelistedKeepers[_keeper] = true;
    }

    ///@notice remove a whitelisted keeper
    ///@param _keeper address of the keeper to remove
    function removeKeeperFromWhitelist(address _keeper) external override onlyGovernance {
        require(whitelistedKeepers[_keeper], 'RKN');
        whitelistedKeepers[_keeper] = false;
    }

    ///@notice Get the keys for all modules
    ///@return bytes32[] all module keys
    function getModuleKeys() external view override returns (bytes32[] memory) {
        return moduleKeys;
    }

    ///@notice Set default value for a module
    ///@param _id keccak256 of module id string
    ///@param _defaultData default data for the module
    function setDefaultValue(bytes32 _id, bytes32 _defaultData) external onlyGovernance {
        require(modules[_id].contractAddress != address(0), 'RDE');
        require(_defaultData != bytes32(0), 'RD0');

        modules[_id].defaultData = _defaultData;
    }

    ///@notice Set default activation for a module
    ///@param _id keccak256 of module id string
    ///@param _activatedByDefault default activation bool for the module
    function setDefaultActivation(bytes32 _id, bool _activatedByDefault) external onlyGovernance {
        require(modules[_id].contractAddress != address(0), 'RS0');
        modules[_id].activatedByDefault = _activatedByDefault;
    }

    ///@notice set oracle price deviation threshold
    ///@param _maxTwapDeviation the new oracle price deviation threshold
    function setMaxTwapDeviation(int24 _maxTwapDeviation) external onlyGovernance {
        maxTwapDeviation = _maxTwapDeviation;
    }

    ///@notice set twap duration
    ///@param _twapDuration the new twap duration
    function setTwapDuration(uint32 _twapDuration) external onlyGovernance {
        require(_twapDuration != 0, 'RT0');
        twapDuration = _twapDuration;
    }

    ///@notice Get the address of a module for a given key
    ///@param _id keccak256 of module id string
    ///@return address of the module
    ///@return bool true if module is activated, false otherwise
    ///@return bytes memory default data for the module
    ///@return bool true if module is activated by default, false otherwise
    function getModuleInfo(bytes32 _id)
        external
        view
        override
        returns (
            address,
            bool,
            bytes32,
            bool
        )
    {
        return (
            modules[_id].contractAddress,
            modules[_id].activated,
            modules[_id].defaultData,
            modules[_id].activatedByDefault
        );
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.7.6;
pragma abicoder v2;

interface IRegistry {
    struct Entry {
        address contractAddress;
        bool activated;
        bytes32 defaultData;
        bool activatedByDefault;
    }

    ///@notice return the address of PositionManagerFactory
    ///@return address of PositionManagerFactory
    function positionManagerFactoryAddress() external view returns (address);

    ///@notice return the address of Governance
    ///@return address of Governance
    function governance() external view returns (address);

    ///@notice return the max twap deviation
    ///@return int24 max twap deviation
    function maxTwapDeviation() external view returns (int24);

    ///@notice return the twap duration
    ///@return uint32 twap duration
    function twapDuration() external view returns (uint32);

    ///@notice return the address of Governance
    ///@return address of Governance
    function getModuleKeys() external view returns (bytes32[] memory);

    ///@notice adds a new whitelisted keeper
    ///@param _keeper address of the new keeper
    function addKeeperToWhitelist(address _keeper) external;

    ///@notice remove a whitelisted keeper
    ///@param _keeper address of the keeper to remove
    function removeKeeperFromWhitelist(address _keeper) external;

    ///@notice checks if the address is whitelisted as a keeper
    ///@param _keeper address to check
    ///@return bool true if the address is withelisted, false otherwise
    function whitelistedKeepers(address _keeper) external view returns (bool);

    function getModuleInfo(bytes32 _id)
        external
        view
        returns (
            address,
            bool,
            bytes32,
            bool
        );
}