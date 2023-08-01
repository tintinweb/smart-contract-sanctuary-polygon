// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "../../vendor/aave/IACLManager.sol";
import "../../vendor/aave/IAaveV3ConfigEngine.sol";

contract MockAaveV3ConfigEngine is IAaveV3ConfigEngine {
    IACLManager public aclManager;

    CapsUpdate public lastUpdate;

    event CapsUpdated(address asset, uint256 supplyCap, uint256 borrowCap);

    constructor(IACLManager aclManager_) {
        aclManager = aclManager_;
    }

    function updateCaps(CapsUpdate[] memory _updates) external override {
        require(aclManager.isRiskAdmin(msg.sender), "Only risk admin can call");

        require(_updates.length == 1, "Only one update allowed");

        lastUpdate = _updates[0];

        emit CapsUpdated(_updates[0].asset, _updates[0].supplyCap, _updates[0].borrowCap);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAaveV3ConfigEngine {
    /**
     * @dev Example (mock):
     * CapsUpdate({
     *   asset: AaveV3EthereumAssets.AAVE_UNDERLYING,
     *   supplyCap: 1_000_000,
     *   borrowCap: EngineFlags.KEEP_CURRENT
     * }
     */
    struct CapsUpdate {
        address asset;
        uint256 supplyCap; // Pass any value, of EngineFlags.KEEP_CURRENT to keep it as it is
        uint256 borrowCap; // Pass any value, of EngineFlags.KEEP_CURRENT to keep it as it is
    }

    /**
     * @notice Performs an update of the caps (supply, borrow) of the assets, in the Aave pool configured in this engine instance
     * @param updates `CapsUpdate[]` list of declarative updates containing the new caps
     *   More information on the documentation of the struct.
     */
    function updateCaps(CapsUpdate[] memory updates) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IACLManager
 * @author Aave
 * @notice Defines the basic interface for the ACL Manager
 */
interface IACLManager {
    /**
     * @notice Returns the contract address of the PoolAddressesProvider
     * @return The address of the PoolAddressesProvider
     */
    function ADDRESSES_PROVIDER() external view returns (address);

    /**
     * @notice Returns the identifier of the PoolAdmin role
     * @return The id of the PoolAdmin role
     */
    function POOL_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the EmergencyAdmin role
     * @return The id of the EmergencyAdmin role
     */
    function EMERGENCY_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the RiskAdmin role
     * @return The id of the RiskAdmin role
     */
    function RISK_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the FlashBorrower role
     * @return The id of the FlashBorrower role
     */
    function FLASH_BORROWER_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the Bridge role
     * @return The id of the Bridge role
     */
    function BRIDGE_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the AssetListingAdmin role
     * @return The id of the AssetListingAdmin role
     */
    function ASSET_LISTING_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Set the role as admin of a specific role.
     * @dev By default the admin role for all roles is `DEFAULT_ADMIN_ROLE`.
     * @param role The role to be managed by the admin role
     * @param adminRole The admin role
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    /**
     * @notice Adds a new admin as PoolAdmin
     * @param admin The address of the new admin
     */
    function addPoolAdmin(address admin) external;

    /**
     * @notice Removes an admin as PoolAdmin
     * @param admin The address of the admin to remove
     */
    function removePoolAdmin(address admin) external;

    /**
     * @notice Returns true if the address is PoolAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is PoolAdmin, false otherwise
     */
    function isPoolAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new admin as EmergencyAdmin
     * @param admin The address of the new admin
     */
    function addEmergencyAdmin(address admin) external;

    /**
     * @notice Removes an admin as EmergencyAdmin
     * @param admin The address of the admin to remove
     */
    function removeEmergencyAdmin(address admin) external;

    /**
     * @notice Returns true if the address is EmergencyAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is EmergencyAdmin, false otherwise
     */
    function isEmergencyAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new admin as RiskAdmin
     * @param admin The address of the new admin
     */
    function addRiskAdmin(address admin) external;

    /**
     * @notice Removes an admin as RiskAdmin
     * @param admin The address of the admin to remove
     */
    function removeRiskAdmin(address admin) external;

    /**
     * @notice Returns true if the address is RiskAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is RiskAdmin, false otherwise
     */
    function isRiskAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new address as FlashBorrower
     * @param borrower The address of the new FlashBorrower
     */
    function addFlashBorrower(address borrower) external;

    /**
     * @notice Removes an address as FlashBorrower
     * @param borrower The address of the FlashBorrower to remove
     */
    function removeFlashBorrower(address borrower) external;

    /**
     * @notice Returns true if the address is FlashBorrower, false otherwise
     * @param borrower The address to check
     * @return True if the given address is FlashBorrower, false otherwise
     */
    function isFlashBorrower(address borrower) external view returns (bool);

    /**
     * @notice Adds a new address as Bridge
     * @param bridge The address of the new Bridge
     */
    function addBridge(address bridge) external;

    /**
     * @notice Removes an address as Bridge
     * @param bridge The address of the bridge to remove
     */
    function removeBridge(address bridge) external;

    /**
     * @notice Returns true if the address is Bridge, false otherwise
     * @param bridge The address to check
     * @return True if the given address is Bridge, false otherwise
     */
    function isBridge(address bridge) external view returns (bool);

    /**
     * @notice Adds a new admin as AssetListingAdmin
     * @param admin The address of the new admin
     */
    function addAssetListingAdmin(address admin) external;

    /**
     * @notice Removes an admin as AssetListingAdmin
     * @param admin The address of the admin to remove
     */
    function removeAssetListingAdmin(address admin) external;

    /**
     * @notice Returns true if the address is AssetListingAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is AssetListingAdmin, false otherwise
     */
    function isAssetListingAdmin(address admin) external view returns (bool);
}