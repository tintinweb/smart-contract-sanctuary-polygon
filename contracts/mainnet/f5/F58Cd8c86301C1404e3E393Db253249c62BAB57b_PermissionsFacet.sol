// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibDelegatePermissions} from "LibDelegatePermissions.sol";
import {IPermissionProvider} from "IPermissionProvider.sol";
import {LibDelegate} from "LibDelegate.sol";

contract PermissionsFacet {

    function resetDelegatePermissions() external {
        LibDelegatePermissions.resetDelegatePermissions(msg.sender);
    }

    function getIndexForDelegatePermission(IPermissionProvider.Permission permission) external pure returns (uint256) {
        return LibDelegatePermissions.getIndexForDelegatePermission(permission);
    }

    function getRawDelegatePermissions(address owner) external view returns (uint256) {
        return LibDelegatePermissions.getRawDelegatePermissions(owner);
    }

    function setDelegatePermissionsRaw(uint256 permissionsRaw) external {
        LibDelegatePermissions.setDelegatePermissionsRaw(permissionsRaw);
    }

    function checkDelegatePermission(address owner, IPermissionProvider.Permission permission) external view returns (bool) {
        return LibDelegatePermissions.checkDelegatePermission(owner, permission);
    }

    function checkDelegatePermissions(address owner, IPermissionProvider.Permission[] calldata permissions) external view returns (bool) {
        return LibDelegatePermissions.checkDelegatePermissions(owner, permissions);
    }

    function requireDelegatePermission(address owner, IPermissionProvider.Permission permission) external view {
        require(LibDelegatePermissions.checkDelegatePermission(owner, permission), "PermissionsFacet: delegate does not have requested permission.");
    }

    function requireDelegatePermissions(address owner, IPermissionProvider.Permission[] calldata permissions) external view {
        require(LibDelegatePermissions.checkDelegatePermissions(owner, permissions), "PermissionsFacet: delegate does not have all the requested permissions.");
    }

    function setDelegatePermission(IPermissionProvider.Permission permission, bool state) external {
        LibDelegatePermissions.setDelegatePermission(permission, state);
    }

    function setDelegatePermissions(IPermissionProvider.Permission[] calldata permissions, bool[] calldata states) external {
        require(permissions.length == states.length, "PermissionsFacet: array lengths must match.");
        LibDelegatePermissions.setDelegatePermissions(permissions, states);
    }

    //  Equivalent to calling setDelegate() and setDelegatePermissions()
    function setDelegateAndPermissions(address delegate, IPermissionProvider.Permission[] calldata permissions, bool[] calldata states) external {
        require(permissions.length == states.length, "PermissionsFacet: array lengths must match.");
        LibDelegate.setDelegate(delegate);
        LibDelegatePermissions.setDelegatePermissions(permissions, states);
    }

    //  Equivalent to calling setDelegate() and setDelegatePermissionsRaw()
    function setDelegateAndPermissionsRaw(address delegate, uint256 permissionsRaw) external {
        LibDelegate.setDelegate(delegate);
        LibDelegatePermissions.setDelegatePermissionsRaw(permissionsRaw);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IPermissionProvider} from "IPermissionProvider.sol";
import {LibEvents} from "LibEvents.sol";
import {LibDelegate} from "LibDelegate.sol";
import {LibBin} from "LibBin.sol";

library LibDelegatePermissions {
   bytes32 constant PERMISSIONS_STORAGE_POSITION = keccak256("CryptoUnicorns.Delegate.Permissions.storage");

    struct DelegatePermissionsStorage {
        mapping(address => uint256) delegatorToPermissionsOnDelegates;
    }

    function delegatePermissionsStorage() internal pure returns (DelegatePermissionsStorage storage ps) {
        bytes32 position = PERMISSIONS_STORAGE_POSITION;
        assembly {
            ps.slot := position
        }
    }

    function getRawDelegatePermissions(address delegator) internal view returns (uint256) {
        return delegatePermissionsStorage().delegatorToPermissionsOnDelegates[delegator];
    }

    function setDelegatePermission(IPermissionProvider.Permission permission, bool state) internal {
        uint256 currentDelegatePermissions = delegatePermissionsStorage().delegatorToPermissionsOnDelegates[msg.sender];
        uint256 delegatePermissionToChange = getIndexForDelegatePermission(permission);
        uint256 result = LibBin.setBit(currentDelegatePermissions, delegatePermissionToChange, state);

        setDelegatePermissionsRaw(result);
    }

    function setDelegatePermissions(IPermissionProvider.Permission[] calldata permissions, bool[] calldata states) internal {
        uint256 originalDelegatePermissions = delegatePermissionsStorage().delegatorToPermissionsOnDelegates[msg.sender];
        uint256 result = originalDelegatePermissions;
        for(uint256 i=0; i < permissions.length; i++) {
            uint256 permissionToChange = getIndexForDelegatePermission(permissions[i]);
            result = LibBin.setBit(result, permissionToChange, states[i]);
        }
        setDelegatePermissionsRaw(result);
    }

    function getIndexForDelegatePermission(IPermissionProvider.Permission permission) internal pure returns (uint256) {
        return uint8(permission);
    }

    function setDelegatePermissionsRaw(uint256 delegatePermissionsRaw) internal {
        uint256 currentDelegatePermissions = delegatePermissionsStorage().delegatorToPermissionsOnDelegates[msg.sender];
        delegatePermissionsStorage().delegatorToPermissionsOnDelegates[msg.sender] = delegatePermissionsRaw;
        address delegate = LibDelegate.getDelegate(msg.sender);
        emit LibEvents.PermissionsChanged(msg.sender, delegate, currentDelegatePermissions, delegatePermissionsRaw);
    }

    function checkDelegatePermission(address delegator, IPermissionProvider.Permission permission) internal view returns (bool) {
        uint256 currentDelegatePermissions = delegatePermissionsStorage().delegatorToPermissionsOnDelegates[delegator];
        return LibBin.getBit(currentDelegatePermissions, getIndexForDelegatePermission(permission));
    }

    function checkDelegatePermissions(address delegator, IPermissionProvider.Permission[] calldata permissions) internal view returns (bool) {
        uint256 currentDelegatePermissions = delegatePermissionsStorage().delegatorToPermissionsOnDelegates[delegator];
        for(uint256 i = 0; i < permissions.length; i++) {
            if(!LibBin.getBit(currentDelegatePermissions, getIndexForDelegatePermission(permissions[i]))) {
                return false;
            }
        }
        return true;
    }

    function resetDelegatePermissions(address delegator) internal {
        uint256 currentDelegatePermissions = delegatePermissionsStorage().delegatorToPermissionsOnDelegates[delegator];
        delegatePermissionsStorage().delegatorToPermissionsOnDelegates[delegator] = 0;
        address delegate = LibDelegate.getDelegate(delegator);
        emit LibEvents.PermissionsChanged(delegator, delegate, currentDelegatePermissions, 0);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPermissionProvider {

    enum Permission {               // WARNING: This list must NEVER be re-ordered
        FARM_ALLOWED,                                                   //0
        JOUST_ALLOWED,              //  Not in use yet                  //1
        RACE_ALLOWED,               //  Not in use yet                  //2
        PVP_ALLOWED,                //  Not in use yet                  //3
        UNIGATCHI_ALLOWED,          //  Not in use yet                  //4
        RAINBOW_RUMBLE_ALLOWED,     //  Not in use yet                  //5
        UNICORN_PARTY_ALLOWED,      //  Not in use yet                  //6

        UNICORN_BREEDING_ALLOWED,                                       //7
        UNICORN_HATCHING_ALLOWED,                                       //8
        UNICORN_EVOLVING_ALLOWED,                                       //9
        UNICORN_AIRLOCK_IN_ALLOWED,                                     //10
        UNICORN_AIRLOCK_OUT_ALLOWED,                                    //11

        LAND_AIRLOCK_IN_ALLOWED,                                        //12
        LAND_AIRLOCK_OUT_ALLOWED,                                       //13

        BANK_STASH_RBW_IN_ALLOWED,                                      //14
        BANK_STASH_RBW_OUT_ALLOWED,                                     //15
        BANK_STASH_UNIM_IN_ALLOWED,                                     //16
        BANK_STASH_UNIM_OUT_ALLOWED,                                    //17
        BANK_STASH_LOOTBOX_IN_ALLOWED,                                  //18                                
        BANK_STASH_KEYSTONE_OUT_ALLOWED,                                //19

        FARM_RMP_BUY,                                                   //20
        FARM_RMP_SELL                                                   //21
    }
    
    event PermissionsChanged(
        address indexed owner,
        address indexed delegate,
        uint256 oldPermissions,
        uint256 newPermissions
    );

    
    
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library LibEvents {

   event DelegateChanged(
        address indexed owner,
        address indexed oldDelegate,
        address indexed newDelegate,
        uint256 permissions
    );
    
    event PermissionsChanged(
        address indexed owner,
        address indexed delegate,
        uint256 oldPermissions,
        uint256 newPermissions
    );

   event DebugActivity(
       string method, 
       address indexed caller
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibEvents} from "LibEvents.sol";
import {LibDelegatePermissions} from "LibDelegatePermissions.sol";

library LibDelegate {
    bytes32 constant DELEGATE_STORAGE_POSITION = keccak256("CryptoUnicorns.Delegate.storage");

    struct DelegateStorage {
        mapping(address => address) delegatorToDelegate;                //  [delegator => delegate]
        mapping(address => address) delegateToDelegator;                //  [delegate => delegator]
    }

    function delegateStorage() internal pure returns (DelegateStorage storage ds) {
        bytes32 position = DELEGATE_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setDelegate(address delegate) internal {
        DelegateStorage storage ds = delegateStorage();

        if(ds.delegateToDelegator[delegate] != address(0)) {
            require(ds.delegateToDelegator[delegate] == msg.sender, "LibDelegate: Delegate already assigned to someone else.");
        }
        address previousDelegate = ds.delegatorToDelegate[msg.sender];
        ds.delegatorToDelegate[msg.sender] = delegate;
        ds.delegateToDelegator[delegate] = msg.sender;
        emitDelegateChangedEvent(msg.sender, previousDelegate, delegate);
    }

    function revokeDelegate() internal {
        DelegateStorage storage ds = delegateStorage();
        address deletedDelegate = ds.delegatorToDelegate[msg.sender];
        require(deletedDelegate != address(0), "LibDelegate: cannot revoke without a delegate.");
        LibDelegatePermissions.resetDelegatePermissions(msg.sender);
        delete ds.delegatorToDelegate[msg.sender];
        delete ds.delegateToDelegator[deletedDelegate];
        emitDelegateChangedEvent(msg.sender, deletedDelegate, address(0));
    }

    function abandonDelegation() internal {
        DelegateStorage storage ds = delegateStorage();
        address delegator = ds.delegateToDelegator[msg.sender];
        require(delegator != address(0), "LibDelegate: address is not a delegate.");
        LibDelegatePermissions.resetDelegatePermissions(delegator);
        delete ds.delegateToDelegator[msg.sender];
        delete ds.delegatorToDelegate[delegator];
        emitDelegateChangedEvent(delegator, msg.sender, address(0));
    }

    function getDelegate(address delegator) internal view returns (address) {
        return delegateStorage().delegatorToDelegate[delegator];
    }

    function getDelegator(address delegate) internal view returns (address) {
        return delegateStorage().delegateToDelegator[delegate];
    }

    function emitDelegateChangedEvent(address delegator, address oldDelegate, address newDelegate) private {
        uint256 permissions = LibDelegatePermissions.getRawDelegatePermissions(msg.sender);
        emit LibEvents.DelegateChanged(delegator, oldDelegate, newDelegate, permissions);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library LibBin {

    function shiftLeft(uint256 bitMap, uint256 bitToChange) private pure returns (uint256) {
        return bitMap << bitToChange;
    }

    // // Set bit value at position to state
    function setBit(uint256 bitMap, uint256 bitToChange, bool state) internal pure returns (uint256) {
        uint256 shiftLeftResult = shiftLeft(1, bitToChange);
        return state ? setBitToTrue(bitMap, shiftLeftResult): setBitToFalse(bitMap, shiftLeftResult);
    }

    function setBitToTrue(uint256 bitMap, uint256 shiftLeftResult) private pure returns (uint256) {
        return bitMap | shiftLeftResult;
    }

    function setBitToFalse(uint256 bitMap, uint256 shiftLeftResult) private pure returns (uint256) {
        return bitMap & negate(shiftLeftResult);
    }

    function negate(uint256 bitMap) private pure returns (uint256) {
        return bitMap ^ type(uint256).max;
    }

    // Get bit value at position
    function getBit(uint256 bitMap, uint256 bitToChange) internal pure returns (bool) {
        return bitMap & shiftLeft(1, bitToChange) != 0;
    }
    
}