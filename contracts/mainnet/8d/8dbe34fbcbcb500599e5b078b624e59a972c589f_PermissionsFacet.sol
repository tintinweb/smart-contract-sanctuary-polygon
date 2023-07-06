// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IPermissionsFacet.sol";

contract PermissionsFacet is IPermissionsFacet {
    error Forbidden();
    error InvalidState();
    error Initialized();

    uint256 public constant ADMIN_ROLE_MASK = 1 << 255;
    bytes32 public constant STORAGE_POSITION = keccak256("mellow.contracts.permissions.storage");

    function _contractStorage() internal pure returns (IPermissionsFacet.Storage storage ds) {
        bytes32 position = STORAGE_POSITION;

        assembly {
            ds.slot := position
        }
    }

    function initializePermissionsFacet(address admin) external override {
        if (permissionsInitialized()) revert Initialized();
        IPermissionsFacet.Storage storage ds = _contractStorage();
        ds.initialized = true;
        ds.userRoles[admin] = ADMIN_ROLE_MASK;
    }

    modifier authorized() {
        requirePermission(msg.sender, address(this), msg.sig);
        _;
    }

    function hasPermission(
        address user,
        address contractAddress,
        bytes4 signature
    ) public view override returns (bool) {
        IPermissionsFacet.Storage storage ds = _contractStorage();
        uint256 roleSet = ds.userRoles[user] | ds.publicRoles;
        if ((roleSet & ADMIN_ROLE_MASK) > 0) return true;
        if ((roleSet & ds.allowAllSignaturesRoles[contractAddress]) > 0) return true;
        if ((roleSet & ds.allowSignatureRoles[contractAddress][signature]) > 0) return true;
        return false;
    }

    function requirePermission(address user, address contractAddress, bytes4 signature) public view override {
        if (!hasPermission(user, contractAddress, signature)) {
            revert Forbidden();
        }
    }

    function grantPublicRole(uint8 role) external override authorized {
        IPermissionsFacet.Storage storage ds = _contractStorage();
        ds.publicRoles |= 1 << role;
    }

    function revokePublicRole(uint8 role) external override authorized {
        IPermissionsFacet.Storage storage ds = _contractStorage();
        ds.publicRoles &= ~(1 << role);
    }

    function grantRole(address user, uint8 role) external override authorized {
        IPermissionsFacet.Storage storage ds = _contractStorage();
        ds.userRoles[user] |= 1 << role;
    }

    function revokeRole(address user, uint8 role) external override authorized {
        IPermissionsFacet.Storage storage ds = _contractStorage();
        ds.userRoles[user] &= ~(1 << role);
    }

    function grantContractRole(address contractAddress, uint8 role) external override authorized {
        IPermissionsFacet.Storage storage ds = _contractStorage();
        ds.allowAllSignaturesRoles[contractAddress] |= 1 << role;
    }

    function revokeContractRole(address contractAddress, uint8 role) external override authorized {
        IPermissionsFacet.Storage storage ds = _contractStorage();
        ds.allowAllSignaturesRoles[contractAddress] &= ~(1 << role);
    }

    function grantContractSignatureRole(
        address contractAddress,
        bytes4 signature,
        uint8 role
    ) external override authorized {
        IPermissionsFacet.Storage storage ds = _contractStorage();
        ds.allowSignatureRoles[contractAddress][signature] |= 1 << role;
    }

    function revokeContractSignatureRole(
        address contractAddress,
        bytes4 signature,
        uint8 role
    ) external override authorized {
        IPermissionsFacet.Storage storage ds = _contractStorage();
        ds.allowSignatureRoles[contractAddress][signature] &= ~(1 << role);
    }

    function userRoles(address user) external view override returns (uint256) {
        return _contractStorage().userRoles[user];
    }

    function publicRoles() external view override returns (uint256) {
        return _contractStorage().publicRoles;
    }

    function allowAllSignaturesRoles(address contractAddress) external view override returns (uint256) {
        return _contractStorage().allowAllSignaturesRoles[contractAddress];
    }

    function allowSignatureRoles(address contractAddress, bytes4 selector) external view override returns (uint256) {
        return _contractStorage().allowSignatureRoles[contractAddress][selector];
    }

    function permissionsInitialized() public view override returns (bool) {
        return _contractStorage().initialized;
    }

    function permissionsSelectors() external pure override returns (bytes4[] memory selectors_) {
        selectors_ = new bytes4[](17);
        selectors_[0] = IPermissionsFacet.permissionsInitialized.selector;
        selectors_[1] = IPermissionsFacet.permissionsSelectors.selector;
        selectors_[2] = IPermissionsFacet.initializePermissionsFacet.selector;
        selectors_[3] = IPermissionsFacet.hasPermission.selector;
        selectors_[4] = IPermissionsFacet.grantPublicRole.selector;
        selectors_[5] = IPermissionsFacet.revokePublicRole.selector;
        selectors_[6] = IPermissionsFacet.grantContractSignatureRole.selector;
        selectors_[7] = IPermissionsFacet.revokeContractSignatureRole.selector;
        selectors_[8] = IPermissionsFacet.grantRole.selector;
        selectors_[9] = IPermissionsFacet.revokeRole.selector;
        selectors_[10] = IPermissionsFacet.userRoles.selector;
        selectors_[11] = IPermissionsFacet.publicRoles.selector;
        selectors_[12] = IPermissionsFacet.allowAllSignaturesRoles.selector;
        selectors_[13] = IPermissionsFacet.allowSignatureRoles.selector;
        selectors_[14] = IPermissionsFacet.requirePermission.selector;
        selectors_[15] = IPermissionsFacet.grantContractRole.selector;
        selectors_[16] = IPermissionsFacet.revokeContractRole.selector;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPermissionsFacet {
    struct Storage {
        bool initialized;
        mapping(address => uint256) userRoles;
        uint256 publicRoles;
        mapping(address => uint256) allowAllSignaturesRoles;
        mapping(address => mapping(bytes4 => uint256)) allowSignatureRoles;
    }

    function initializePermissionsFacet(address admin) external;

    function hasPermission(address user, address contractAddress, bytes4 signature) external view returns (bool);

    function requirePermission(address user, address contractAddress, bytes4 signature) external;

    function grantPublicRole(uint8 role) external;

    function revokePublicRole(uint8 role) external;

    function grantContractRole(address contractAddress, uint8 role) external;

    function revokeContractRole(address contractAddress, uint8 role) external;

    function grantContractSignatureRole(address contractAddress, bytes4 signature, uint8 role) external;

    function revokeContractSignatureRole(address contractAddress, bytes4 signature, uint8 role) external;

    function grantRole(address user, uint8 role) external;

    function revokeRole(address user, uint8 role) external;

    function userRoles(address user) external view returns (uint256);

    function publicRoles() external view returns (uint256);

    function allowAllSignaturesRoles(address contractAddress) external view returns (uint256);

    function allowSignatureRoles(address contractAddress, bytes4 selector) external view returns (uint256);

    function permissionsInitialized() external view returns (bool);

    function permissionsSelectors() external view returns (bytes4[] memory selectors_);
}