/**
 *Submitted for verification at polygonscan.com on 2022-05-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @notice Interface for the modular system
 */
interface IModuleManager {
    function getModule(uint8 function_) external returns (address);
}

/**
 * @notice Permission system trying to avoid centralized power
 */
contract Roles {
    /**
     * @notice Add or remove every role
     */
    address private superAdminRole;

    /**
     * @notice The address of the votation system
     */
    address private votationContract;

    /**
     * @notice FALSE flag
     * @dev Just for saving gas
     */
    uint128 public constant FALSE = 0;

    /**
     * @notice TRUE flag
     * @dev Just for saving gas
     */
    uint128 public constant TRUE = 1;
    
    /**
     * @notice Amount of admins
     */
    uint256 private amountOfAdmins;
    
    /**
     * @notice Is an address an admin?
     */
    mapping(address => uint128) private adminRole;

    /**
     * @notice Is an address a moderator?
     */
    mapping(address => uint128) private moderatorRole;

    /**
     * @notice Is an address a verified seller?
     */
    mapping(address => uint128) private verifiedSellerRole;

    /**
     * @notice Is an address a seller?
     */
    mapping(address => uint128) private sellerRole;
    
    /**
     * @notice If this contract changes superadminship
     */
    event SuperOwnershipTransferred(address previousOwner, address newOwner);
    
    /**
     * @notice When an admin is added
     * @param authority The authority that added a new admin
     * @param newAdmin The new admin
     */
    event AddedAdmin(address authority, address newAdmin);

    /**
     * @notice When a moderator is added
     * @param authority The authority that added a new moderator
     * @param newModerator The new moderator
     */
    event AddedModerator(address authority, address newModerator);

    /**
     * @notice When a verified seller is added
     * @param authority The authority that added a new verified seller
     * @param newVerifiedSeller The new verified seller
     */
    event AddedVerifiedSeller(address authority, address newVerifiedSeller);

    /**
     * @notice When a seller is added
     * @param authority The authority that added a new seller
     * @param newSeller The new seller
     */
    event AddedSeller(address authority, address newSeller);
    
    /**
     * @notice When an admin is removed
     * @param authority The authority that removed an admin
     * @param oldAdmin The old admin
     */
    event RemovedAdmin(address authority, address oldAdmin);

    /**
     * @notice When a moderador is removed
     * @param authority The authority that removed an moderator
     * @param oldModerator The old moderator
     */
    event RemovedModerator(address authority, address oldModerator);

    /**
     * @notice When a verified seller is removed
     * @param authority The authority that removed a verified seller
     * @param oldVerifiedSeller The old verified seller
     */
    event RemovedVerifiedSeller(address authority, address oldVerifiedSeller);

    /**
     * @notice When a seller is removed
     * @param authority The authority that removed a seller
     * @param oldSeller The old seller
     */
    event RemovedSeller(address authority, address oldSeller);

    /**
     * @notice The constructor that makes the msg.sender the super admin
     */
    constructor(address module_) {
        _transferSuperAdminship(msg.sender);
        votationContract = IModuleManager(module_).getModule(3);
    }

    /**
     * @notice Error from roles
     * @param reason Role needed
     */
    error PermissionRequired(string reason);

    /**
     * @notice Action restricted to superadmins
     */
    modifier onlySuperAdmin() {
        if (msg.sender != superAdmin())
            revert PermissionRequired('Not superadmin');
        _;
    }

    /**
     * @notice Action restricted to admins
     */
    modifier onlyAdmins() {
        if ((adminRole[msg.sender] != TRUE) && (msg.sender != superAdmin()))
            revert PermissionRequired('Not admin');
        _;
    }

    /**
     * @notice Action restricted to moderators or admins (or super admins)
     */
    modifier onlyModerators() {
        if ((moderatorRole[msg.sender] != TRUE) &&
                (adminRole[msg.sender] != TRUE) &&
                (superAdmin() != msg.sender))
            revert PermissionRequired('Not moderator');
        _;
    }

    /**
     * @notice Action restricted to verified sellers
     */
    modifier onlyVerifiedSellers() {
        if (verifiedSellerRole[msg.sender] != TRUE)
            revert PermissionRequired('Not verified');
        _;
    }

    /**
     * @notice Action restricted to sellers
     */
    modifier onlySellers() {
        if ((sellerRole[msg.sender] != TRUE) &&
            (verifiedSellerRole[msg.sender] != TRUE))
            revert PermissionRequired('Not seller');
        _;
    }

    modifier onlyVotation() {
        if (msg.sender != votationContract)
            revert PermissionRequired('Not votation');
        _;
    }

    /**
     * @notice Renounce super adminship
     */
    function renounceSuperAdminship() public virtual onlySuperAdmin {
        _transferSuperAdminship(address(0));
    }

    /**
     * @notice Transfer super adminship
     * @param newSuperAdmin The new super admin
     */
    function transferSuperAdminship(address newSuperAdmin) public virtual onlySuperAdmin {
        require(newSuperAdmin != address(0));
        _transferSuperAdminship(newSuperAdmin);
    }

    /**
     * @notice Really transfer super adminship
     * @param newSuperAdmin The new super admin
     * @dev internal
     */
    function _transferSuperAdminship(address newSuperAdmin) internal virtual {
        address oldSuperAdmin = superAdminRole;
        superAdminRole = newSuperAdmin;
        emit SuperOwnershipTransferred(oldSuperAdmin, newSuperAdmin);
    }

    /**
     * @notice Add a new admin
     * @param newAdmin The new admin 
     */
    function addAdmin(address newAdmin) public virtual onlyAdmins {
        adminRole[newAdmin] = TRUE;
        amountOfAdmins++;
        emit AddedAdmin(msg.sender, newAdmin);
    }

    /**
     * @notice Remove an old admin
     * @param oldAdmin The old admin
     * @dev This function is only called by this contract 
     */
    function removeAdmin(address oldAdmin) public virtual onlyVotation {
        adminRole[oldAdmin] = FALSE;
        amountOfAdmins--;
        emit RemovedAdmin(msg.sender, oldAdmin);
    }

    /**
     * @notice Add a moderator
     * @param newModerator The new moderator
     * @dev Only admins can execute this function
     */
    function addModerator(address newModerator) public virtual onlyAdmins {
        moderatorRole[newModerator] = TRUE;
        emit AddedModerator(msg.sender, newModerator);
    }

    /**
     * @notice Remove a moderator
     * @param oldModerator The old moderator
     * @dev Only admins can execute this function
     */
    function removeModerator(address oldModerator) public virtual onlyAdmins {
        moderatorRole[oldModerator] = FALSE;
        emit RemovedModerator(msg.sender, oldModerator);
    }

    /**
     * @notice Add a seller
     * @param newSeller The new seller
     * @dev Only moderators can execute this function
     */
    function addSeller(address newSeller) public virtual onlyModerators {
        sellerRole[newSeller] = TRUE;
        emit AddedSeller(msg.sender, newSeller);
    }

    /**
     * @notice Remove a seller
     * @param oldSeller The old seller
     * @dev Only moderators can execute this function
     */
    function removeSeller(address oldSeller) public virtual onlyModerators {
        sellerRole[oldSeller] = FALSE;
        emit RemovedSeller(msg.sender, oldSeller);
    }

    /**
     * @notice Add a verified seller
     * @param newVerifiedSeller The new moderator
     * @dev Only moderators and admins can execute this function
     */
    function addVerifiedSeller(address newVerifiedSeller) public virtual onlyModerators {
        if (isSeller(newVerifiedSeller)) sellerRole[newVerifiedSeller] = FALSE;
        verifiedSellerRole[newVerifiedSeller] = TRUE;
        emit AddedVerifiedSeller(msg.sender, newVerifiedSeller);
    }

    /**
     * @notice Remove verified seller
     * @param oldVerifiedSeller The old verified seller
     * @dev Only moderators and admins can execute this function
     */
    function removeVerifiedSeller(address oldVerifiedSeller) public virtual onlyModerators {
        verifiedSellerRole[oldVerifiedSeller] = FALSE;
        emit RemovedVerifiedSeller(msg.sender, oldVerifiedSeller);
    }

    /**
     * @notice Changes the votation contract, this affects the modifier
     * @param votation_ The new address
     */
    function setVotingSC(address votation_) public onlySuperAdmin {
        votationContract = votation_;
    }

    /**
     * @notice Returns if the 'admin' given is admin
     * @param user_ The admin
     * @return true if is verified, false otherwise
     */
    function isAdmin(address user_) public view virtual returns (bool) {
        return adminRole[user_] == TRUE ? true : false;
    }

    /**
     * @notice Returns if the 'moderator' given is moderator
     * @param user_ The moderator
     * @return true if is verified, false otherwise
     */
    function isModerator(address user_) public view virtual returns (bool) {
        return moderatorRole[user_] == TRUE ? true : false;
    }

    /**
     * @notice Returns if the seller given is verified
     * @param user_ The seller
     * @return true if is verified, false otherwise
     */
    function isVerifiedSeller(address user_) public view virtual returns (bool) {
        return verifiedSellerRole[user_] == TRUE ? true : false;
    }

    /**
     * @notice Returns if the seller has seller role
     * @param user_ The seller
     * @return true if is verified, false otherwise
     */
    function isSeller(address user_) public view virtual returns (bool) {
        return sellerRole[user_] == TRUE ? true : false;
    }

    /**
     * @notice Gets the amount of admins
     * @return The amount of admins
     */
    function getAdminCount() public view returns (uint256) {
        return amountOfAdmins;
    }

    /**
     * @notice Returns the address of the superAdmin if there is one
     * @return the address of the super admin
     */
    function superAdmin() public view virtual returns (address) {
        return superAdminRole;
    }
}