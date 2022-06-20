// SPDX-License-Identifier: GPL-2.0

pragma solidity 0.7.6;

import '../../interfaces/IAaveAddressHolder.sol';
import '../../interfaces/IRegistry.sol';

contract AaveAddressHolder is IAaveAddressHolder {
    address public override lendingPoolAddress;
    IRegistry public registry;

    constructor(address _lendingPoolAddress, address _registry) {
        lendingPoolAddress = _lendingPoolAddress;
        registry = IRegistry(_registry);
    }

    ///@notice Set the address of the lending pool from aave
    ///@param newAddress The address of the lending pool from aave
    function setLendingPoolAddress(address newAddress) external override onlyGovernance {
        lendingPoolAddress = newAddress;
    }

    ///@notice Set the address of the registry
    ///@param newAddress The address of the registry
    function setRegistry(address newAddress) external override onlyGovernance {
        registry = IRegistry(newAddress);
    }

    ///@notice restrict some function called only by governance
    modifier onlyGovernance() {
        require(
            msg.sender == registry.governance(),
            'AaveAddressHolder::onlyGovernance: Only governance can call this function'
        );
        _;
    }
}

// SPDX-License-Identifier: GPL-2.0

pragma solidity 0.7.6;

interface IAaveAddressHolder {
    ///@notice default getter for lendingPoolAddress
    ///@return address The address of the lending pool from aave
    function lendingPoolAddress() external view returns (address);

    ///@notice Set the address of lending pool
    ///@param newAddress new address of the lending pool from aave
    function setLendingPoolAddress(address newAddress) external;

    ///@notice Set the address of the registry
    ///@param newAddress The address of the registry
    function setRegistry(address newAddress) external;
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
    function isWhitelistedKeeper(address _keeper) external view returns (bool);

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