// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IPermissionsFacet.sol";

contract PermissionsFacet is IPermissionsFacet {
    error Forbidden();

    bytes32 internal constant STORAGE_POSITION = keccak256("mellow.contracts.permissions.storage");

    function contractStorage() internal pure returns (IPermissionsFacet.Storage storage ds) {
        bytes32 position = STORAGE_POSITION;

        assembly {
            ds.slot := position
        }
    }

    function initializePermissionsFacet(RolesRegistry _rolesRegistry) external override {
        IPermissionsFacet.Storage storage ds = contractStorage();
        if (
            address(ds.rolesRegistry) == address(0) ||
            ds.rolesRegistry.hasPermission(msg.sender, address(this), msg.sig)
        ) {
            ds.rolesRegistry = _rolesRegistry;
        } else {
            revert Forbidden();
        }
    }

    function hasPermission(
        address user,
        address contractAddress,
        bytes4 signature
    ) external view override returns (bool) {
        IPermissionsFacet.Storage memory ds = contractStorage();
        return ds.rolesRegistry.hasPermission(user, contractAddress, signature);
    }

    function requirePermission(address user, address contractAddress, bytes4 signature) external view override {
        IPermissionsFacet.Storage memory ds = contractStorage();
        ds.rolesRegistry.requirePermission(user, contractAddress, signature);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../utils/RolesRegistry.sol";

interface IPermissionsFacet {
    struct Storage {
        RolesRegistry rolesRegistry;
    }

    function initializePermissionsFacet(RolesRegistry _rolesRegistry) external;

    function hasPermission(address user, address contractAddress, bytes4 signature) external view returns (bool);

    function requirePermission(address user, address contractAddress, bytes4 signature) external view;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

contract RolesRegistry {
    error Forbidden();

    uint8 public constant ADMIN_ROLE_MASK = 1 << 1;
    mapping(address => mapping(address => uint256)) public userContractRoles;
    mapping(bytes4 => uint256) public signatureRoles;
    mapping(address => mapping(bytes4 => bool)) public isEveryoneAllowedToCall;

    constructor(address admin) {
        userContractRoles[admin][address(this)] = ADMIN_ROLE_MASK;
    }

    function hasPermission(address user, address contractAddress, bytes4 signature) public view returns (bool) {
        if ((ADMIN_ROLE_MASK & userContractRoles[user][address(this)]) > 0) {
            return true;
        }

        if (isEveryoneAllowedToCall[contractAddress][signature]) {
            return true;
        }

        return (userContractRoles[user][contractAddress] & signatureRoles[signature]) != 0;
    }

    function requirePermission(address user, address contractAddress, bytes4 signature) external view {
        if (!hasPermission(user, contractAddress, signature)) {
            revert Forbidden();
        }
    }

    modifier onlyAdmin() {
        if ((userContractRoles[msg.sender][address(this)] & ADMIN_ROLE_MASK) == 0) {
            revert Forbidden();
        }
        _;
    }

    function setGeneralRule(address contractAddress, bytes4 signature, bool value) external onlyAdmin {
        isEveryoneAllowedToCall[contractAddress][signature] = value;
    }

    function grantUserContractRole(uint8 role, address user, address contractAddress) external onlyAdmin {
        userContractRoles[user][contractAddress] |= 1 << role;
    }

    function revokeUserContractRole(uint8 role, address user, address contractAddress) external onlyAdmin {
        userContractRoles[user][contractAddress] &= ~(1 << role);
    }

    function grantSignatureRole(uint8 role, bytes4 signature) external onlyAdmin {
        signatureRoles[signature] |= 1 << role;
    }

    function revokeSignatureRole(uint8 role, bytes4 signature) external onlyAdmin {
        signatureRoles[signature] &= ~(1 << role);
    }
}