// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { IERC173 } from "../ERC/interfaces/IERC173.sol";

enum AdminLevel {
    NIL, // No clearance. Reject this user. The default 0 value.
    One, // Can only modify parts of the contract that do not risk user funds.
    Two, // Can initiate changes to the contract. Can also veto pending changes to the contract.
    Three // Highest security clearance. Can call everything except reassign owner. Can assign admins.
}

struct AdminRegistry {
    // Full security clearance. Can register admins and reassign itself.
    address owner;

    mapping(address => AdminLevel) admins;
}


/// Utility functions for checking, registering, and deregisterying administrative credentials.
library AdminLib {
    bytes32 constant ADMIN_STORAGE_POSITION = keccak256("v4.admin.diamond.storage");

    error InsufficientCredentials();
    error CannotReinitializeOwner(address existingOwner);

    function adminStore() internal pure returns (AdminRegistry storage adReg) {
        bytes32 position = ADMIN_STORAGE_POSITION;
        assembly {
            adReg.slot := position
        }
    }

    /* Getters */

    function getOwner() external view returns (address) {
        return adminStore().owner;
    }

    // @return lvl Will be cast to uint8 on return to external contracts.
    function getAdminLevel(address addr) external view returns (AdminLevel lvl) {
        return adminStore().admins[addr];
    }

    /* Validating Helpers */

    function validateOwner() internal view {
        if (msg.sender != adminStore().owner) {
            revert InsufficientCredentials();
        }
    }

    /// Revert if the msg.sender is a lower lvl than the lvl parameter.
    function validateLevel(AdminLevel lvl) internal view {
        AdminRegistry storage adReg = adminStore();
        if (adReg.owner == msg.sender)
            return;

        AdminLevel senderLvl = adReg.admins[msg.sender];
        if (senderLvl < lvl)
            revert InsufficientCredentials();
    }

    /// Convenience function so users don't have to import AdminLevel when validating.
    function validateLevel(uint8 lvl) internal view {
        validateLevel(AdminLevel(lvl));
    }

    /* Registry functions */

    /// Called when there is no owner so one can be set for the first time.
    function initOwner(address owner) public {
        AdminRegistry storage adReg = adminStore();
        if (adReg.owner != address(0))
            revert CannotReinitializeOwner(adReg.owner);
        adReg.owner = owner;
    }

    /// Remember to initialize the owner to a contract that can reassign on construction.
    function reassignOwner(address newOwner) public {
        validateOwner();
        adminStore().owner = newOwner;
    }

    function register(address newAdmin, uint8 level) public {
        validateLevel(AdminLevel.Three);
        adminStore().admins[newAdmin] = AdminLevel(level);
    }

    function deregister(address oldAdmin) public {
        validateLevel(AdminLevel.Three);
        adminStore().admins[oldAdmin] = AdminLevel.NIL;
    }
}

/// The exposed facet for external interactions with the AdminLib
contract AdminFacet is IERC173 {
    function transferOwnership(address _newOwner) external override {
        AdminLib.reassignOwner(_newOwner);
    }

    function owner() external override view returns (address owner_) {
        owner_ = AdminLib.getOwner();
    }

    /// Fetch the admin level for an address.
    function adminLevel(address addr) external view returns (uint8 lvl) {
        return uint8(AdminLib.getAdminLevel(addr));
    }

    /// Add an admin to this contract. Only level 3 clearance can call this.
    /// This will overwrite any existing clearance level.
    function addAdmin(address addr, uint8 lvl) external {
        AdminLib.register(addr, lvl);
    }

    /// Remove an admin from this contract. Effectively the same
    /// as an addAdmin call with level 0.
    function removeAdmin(address addr) external {
        AdminLib.deregister(addr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}