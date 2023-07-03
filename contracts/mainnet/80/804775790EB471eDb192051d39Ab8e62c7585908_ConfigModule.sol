//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for access related errors.
 */
library AccessError {
    /**
     * @dev Thrown when an address tries to perform an unauthorized action.
     * @param addr The address that attempts the action.
     */
    error Unauthorized(address addr);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../errors/AccessError.sol";

library OwnableStorage {
    bytes32 private constant _SLOT_OWNABLE_STORAGE =
        keccak256(abi.encode("io.synthetix.core-contracts.Ownable"));

    struct Data {
        address owner;
        address nominatedOwner;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = _SLOT_OWNABLE_STORAGE;
        assembly {
            store.slot := s
        }
    }

    function onlyOwner() internal view {
        if (msg.sender != getOwner()) {
            revert AccessError.Unauthorized(msg.sender);
        }
    }

    function getOwner() internal view returns (address) {
        return OwnableStorage.load().owner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Input related errors.
 */
library InputErrors {
    /**
     * @notice Error when an input has unexpected zero uint256.
     *
     * Cases:
     * - `FundsModule.depositunds()`
     * - `FundsModule.withdrawFunds()`
     *
     */
    error ZeroAmount();

    /**
     * @notice Error when an input has unexpected zero address.
     *
     * Cases:
     * - `ProfilesModule.allowProfile()`
     * - `ProfilesModule.disallowProfile()`
     * - `VaultsModule.addVault()`
     *
     */
    error ZeroAddress();

    /**
     * @notice Error when an input has unexpected zero bytes32 ID.
     *
     * Cases:
     * - `FeesModule.initializeFeesModule()`
     * - `FeesModule.setGratefulFeeTreasury()`
     * - `VaultsModule.addVault()`
     *
     */
    error ZeroId();

    /**
     * @notice Error when an input has unexpected zero uint for time.
     *
     * Cases:
     * - `ConfigModule.initializeConfigModule()`
     * - `ConfigModule.setSolvencyTimeRequired()`
     * - `ConfigModule.setLiquidationTimeRequired()`
     *
     */
    error ZeroTime();

    /**
     * @notice Error when trying to initialize a module that has already been.
     *
     * Cases:
     * - `ConfigModule.initializeConfigModule()`
     * - `FeesModule.initializeFeesModule()`
     * - `VaultModule.addVault()`
     *
     */
    error AlreadyInitialized();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Module for managing system configuration.
 */
interface IConfigModule {
    /**************************************************************************
     * Governance functions
     *************************************************************************/

    /**
     * @notice Initialize the grateful system configuration
     * @dev Only owner / Emits `ConfigInitialized` event
     * @param solvencyTimeRequired The time required to remain solvent (allow to start new susbscriptions or withdrawals)
     * @param liquidationTimeRequired The time required to avoid liquidation
     */
    function initializeConfigModule(
        uint256 solvencyTimeRequired,
        uint256 liquidationTimeRequired
    ) external;

    /**
     * @notice Change the time required to remain solvent
     * @dev Only owner / Emits `SolvencyTimeChanged` event
     * @param newSolvencyTime The new time required to remain solvent
     */
    function setSolvencyTimeRequired(uint256 newSolvencyTime) external;

    /**
     * @notice Change the time required to avoid liquidation
     * @dev Only owner / Emits `LiquidationTimeChanged` event
     * @param newLiquidationTime The new time required to avoid liquidation
     */
    function setLiquidationTimeRequired(uint256 newLiquidationTime) external;

    /**************************************************************************
     * View functions
     *************************************************************************/

    /**
     * @notice Return the current solvency time required
     * @return Solvency time
     */
    function getSolvencyTimeRequired() external returns (uint256);

    /**
     * @notice Return the current liquidation time required
     * @return Liquidation time
     */
    function getLiquidationTimeRequired() external returns (uint256);

    /**************************************************************************
     * Events
     *************************************************************************/

    /**
     * @notice Emits the initial configuration
     * @param solvencyTimeRequired The time required to remain solvent
     * @param liquidationTimeRequired The time required to avoid liquidation
     */
    event ConfigInitialized(
        uint256 solvencyTimeRequired,
        uint256 liquidationTimeRequired
    );

    /**
     * @notice Emits the solvency time change
     * @param oldSolvencyTime The old time required to remain solvent
     * @param newSolvencyTime The new time required to remain solvent
     */
    event SolvencyTimeChanged(uint256 oldSolvencyTime, uint256 newSolvencyTime);

    /**
     * @notice Emits the liquidation time change
     * @param oldLiquidationTime The old time required to avoid liquidation
     * @param newLiquidationTime The new time required to avoid liquidation
     */
    event LiquidationTimeChanged(
        uint256 oldLiquidationTime,
        uint256 newLiquidationTime
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Config} from "../storage/Config.sol";
import {IConfigModule} from "../interfaces/IConfigModule.sol";
import {OwnableStorage} from "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";
import {InputErrors} from "../errors/InputErrors.sol";

/**
 * @title Module for managing system configuration.
 * @dev See IConfigModule.
 */
contract ConfigModule is IConfigModule {
    using Config for Config.Data;

    /// @inheritdoc	IConfigModule
    function initializeConfigModule(
        uint256 solvencyTimeRequired,
        uint256 liquidationTimeRequired
    ) external override {
        OwnableStorage.onlyOwner();

        if (solvencyTimeRequired == 0) revert InputErrors.ZeroTime();
        if (liquidationTimeRequired == 0) revert InputErrors.ZeroTime();

        Config.Data storage config = Config.load();

        if (config.isInitialized()) revert InputErrors.AlreadyInitialized();

        config.setSolvencyTimeRequired(solvencyTimeRequired);
        config.setLiquidationTimeRequired(liquidationTimeRequired);

        emit ConfigInitialized(solvencyTimeRequired, liquidationTimeRequired);
    }

    /// @inheritdoc	IConfigModule
    function setSolvencyTimeRequired(
        uint256 newSolvencyTime
    ) external override {
        OwnableStorage.onlyOwner();
        if (newSolvencyTime == 0) revert InputErrors.ZeroTime();

        Config.Data storage config = Config.load();

        uint256 oldSolvencyTime = config.solvencyTimeRequired;
        config.setSolvencyTimeRequired(newSolvencyTime);

        emit SolvencyTimeChanged(oldSolvencyTime, newSolvencyTime);
    }

    /// @inheritdoc	IConfigModule
    function setLiquidationTimeRequired(
        uint256 newLiquidationTime
    ) external override {
        OwnableStorage.onlyOwner();
        if (newLiquidationTime == 0) revert InputErrors.ZeroTime();

        Config.Data storage config = Config.load();

        uint256 oldLiquidationTime = config.liquidationTimeRequired;
        config.setLiquidationTimeRequired(newLiquidationTime);

        emit LiquidationTimeChanged(oldLiquidationTime, newLiquidationTime);
    }

    /// @inheritdoc	IConfigModule
    function getSolvencyTimeRequired()
        external
        view
        override
        returns (uint256)
    {
        return Config.load().solvencyTimeRequired;
    }

    /// @inheritdoc	IConfigModule
    function getLiquidationTimeRequired()
        external
        view
        override
        returns (uint256)
    {
        return Config.load().liquidationTimeRequired;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Stores the system configuration.
 */
library Config {
    bytes32 private constant _CONFIG_STORAGE_SLOT =
        keccak256(abi.encode("Config"));

    struct Data {
        /**
         * @dev Time required to remain solvent.
         *
         * This is used to know if a profile is allow to open new subscriptions or making withdrawals.
         *
         * If the profile balance does not cover this future time, it is insolvent.
         */
        uint256 solvencyTimeRequired;
        /**
         * @dev Time required to allow making liquidations.
         *
         * This is used to know if a profile is in a liquidation period.
         *
         * If the profile balance does not cover this future time, it can be liquidated.
         */
        uint256 liquidationTimeRequired;
    }

    /**
     * @dev Loads the singleton storage info about the system.
     */
    function load() internal pure returns (Data storage store) {
        bytes32 s = _CONFIG_STORAGE_SLOT;
        assembly {
            store.slot := s
        }
    }

    /**
     * @dev Sets the system solvency time.
     */
    function setSolvencyTimeRequired(
        Data storage self,
        uint256 solvencyTime
    ) internal {
        self.solvencyTimeRequired = solvencyTime;
    }

    /**
     * @dev Sets the system liquidation time.
     */
    function setLiquidationTimeRequired(
        Data storage self,
        uint256 liquidationTime
    ) internal {
        self.liquidationTimeRequired = liquidationTime;
    }

    /**
     * @dev Returns if the config storage is initialized.
     */
    function isInitialized(Data storage self) internal view returns (bool) {
        return self.liquidationTimeRequired != 0;
    }
}