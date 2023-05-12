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