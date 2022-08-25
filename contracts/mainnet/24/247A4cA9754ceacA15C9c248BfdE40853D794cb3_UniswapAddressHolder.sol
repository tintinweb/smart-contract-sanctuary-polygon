// SPDX-License-Identifier: GPL-2.0

pragma solidity 0.7.6;
pragma abicoder v2;

import '../../interfaces/IUniswapAddressHolder.sol';
import '../../interfaces/IRegistry.sol';

contract UniswapAddressHolder is IUniswapAddressHolder {
    address public override nonfungiblePositionManagerAddress;
    address public override uniswapV3FactoryAddress;
    address public override swapRouterAddress;
    IRegistry public registry;

    constructor(
        address _nonfungiblePositionManagerAddress,
        address _uniswapV3FactoryAddress,
        address _swapRouterAddress,
        address _registry
    ) {
        nonfungiblePositionManagerAddress = _nonfungiblePositionManagerAddress;
        uniswapV3FactoryAddress = _uniswapV3FactoryAddress;
        swapRouterAddress = _swapRouterAddress;
        registry = IRegistry(_registry);
    }

    ///@notice Set the address of the non fungible position manager
    ///@param newAddress The address of the non fungible position manager
    function setNonFungibleAddress(address newAddress) external override onlyGovernance {
        nonfungiblePositionManagerAddress = newAddress;
    }

    ///@notice Set the address of the Uniswap V3 factory
    ///@param newAddress The address of the Uniswap V3 factory
    function setFactoryAddress(address newAddress) external override onlyGovernance {
        uniswapV3FactoryAddress = newAddress;
    }

    ///@notice Set the address of the swap router
    ///@param newAddress The address of the swap router
    function setSwapRouterAddress(address newAddress) external override onlyGovernance {
        swapRouterAddress = newAddress;
    }

    ///@notice Set the address of the registry
    ///@param newAddress The address of the registry
    function setRegistry(address newAddress) external override onlyGovernance {
        registry = IRegistry(newAddress);
    }

    ///@notice restrict some function called only by governance
    modifier onlyGovernance() {
        require(msg.sender == registry.governance(), 'UHG');
        _;
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

// SPDX-License-Identifier: GPL-2.0

pragma solidity 0.7.6;
pragma abicoder v2;

interface IUniswapAddressHolder {
    ///@notice default getter for nonfungiblePositionManagerAddress
    ///@return address The address of the non fungible position manager
    function nonfungiblePositionManagerAddress() external view returns (address);

    ///@notice default getter for uniswapV3FactoryAddress
    ///@return address The address of the Uniswap V3 factory
    function uniswapV3FactoryAddress() external view returns (address);

    ///@notice default getter for swapRouterAddress
    ///@return address The address of the swap router
    function swapRouterAddress() external view returns (address);

    ///@notice Set the address of nonfungible position manager
    ///@param newAddress new address of nonfungible position manager
    function setNonFungibleAddress(address newAddress) external;

    ///@notice Set the address of the Uniswap V3 factory
    ///@param newAddress new address of the Uniswap V3 factory
    function setFactoryAddress(address newAddress) external;

    ///@notice Set the address of uniV3 swap router
    ///@param newAddress new address of univ3 swap router
    function setSwapRouterAddress(address newAddress) external;

    ///@notice Set the address of the registry
    ///@param newAddress The address of the registry
    function setRegistry(address newAddress) external;
}