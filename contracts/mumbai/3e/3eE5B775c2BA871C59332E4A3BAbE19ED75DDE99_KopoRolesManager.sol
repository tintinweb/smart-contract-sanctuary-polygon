// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.17;

/** @title KopoRolesManager
 * @author Nicolas Milliard - Matthieu Bonetti
 * @notice Manage all user roles used by Kopo
 * @dev KopoRolesManager allows admin to update user status: role, verification and blacklist
 */

contract KopoRolesManager {
  mapping(address => User) users;

  enum rolesList {
    BENEFICIAIRE,
    RGE,
    OBLIGE,
    NONOBLIGE,
    ADMIN
  }

  struct User {
    address userAddress;
    rolesList rolesList;
    bool isVerified;
    bool isBlacklisted;
  }

  event AdminAdded(address adminAddress);
  event UserRoleUpdated(address userAddress, rolesList previousRole, rolesList newRole);
  event UserVerified(address userAddress);
  event UserBlacklisted(address userAddress);

  /// @notice Owner of the contract is an ADMIN by default
  constructor() {
    users[msg.sender].rolesList = rolesList.ADMIN;
  }

  /// @notice Check if the provided _address is not address(0)
  modifier isNotZeroAddress(address _address) {
    require(_address != address(0), "Address 0 can't be updated");
    _;
  }

  /// @notice Check if the sender is an active ADMIN
  modifier isActiveAdmin() {
    require(
      users[msg.sender].rolesList == rolesList.ADMIN && users[msg.sender].isBlacklisted == false,
      "You're not an active admin"
    );
    _;
  }

  /// @notice Add the role ADMIN to an address
  /// @param _address can't be address(0) and can't already be an ADMIN address
  function setRoleAdmin(address _address) external isActiveAdmin isNotZeroAddress(_address) {
    require(users[_address].rolesList != rolesList.ADMIN, 'This address is already an admin');

    users[_address].rolesList = rolesList.ADMIN;

    emit AdminAdded(_address);
  }

  /// @notice Update the role of a user (except to ADMIN role)
  /// @dev This function is called when a user wants to update his profile (must be called by an active admin)
  /// @param _address is the address of the user we want to update the role
  /// @param _role is the updated role the user wants
  function updateUserRole(address _address, uint256 _role) external isActiveAdmin {
    require(users[_address].rolesList != rolesList(_role), 'This address has already this role');
    require(_role < 4, "You can't update to this role");

    rolesList previousRole = users[_address].rolesList;
    users[_address].rolesList = rolesList(_role);

    emit UserRoleUpdated(_address, previousRole, users[_address].rolesList);
  }

  /// @notice Verify a user when KYC/KYB is successfully sent to Kopo
  /// @param _address is the address of a non verified user
  function verifyUser(address _address) external isActiveAdmin isNotZeroAddress(_address) {
    require(users[_address].isVerified == false, 'This address is already verified');

    users[_address].isVerified = true;

    emit UserVerified(_address);
  }

  /// @notice Blacklist an address (admin or user)
  /// @param _address is the address of a user or an admin not blacklisted
  function blacklistUser(address _address) external isActiveAdmin isNotZeroAddress(_address) {
    require(users[_address].isBlacklisted == false, 'This address is already blacklisted');

    users[_address].isBlacklisted = true;

    emit UserBlacklisted(_address);
  }

  /// @notice Check if the sender is verified
  function isVerified(address _addr) external view returns (bool) {
    if (users[_addr].isVerified == true) {
      return true;
    }
    return false;
  }

  /// @notice Check if the sender is an Beneficiare
  function isBeneficiaire(address _address) external view returns (bool) {
    if (users[_address].rolesList == rolesList.BENEFICIAIRE) {
      return true;
    }
    return false;
  }

  /// @notice Check if the sender is an RGE
  function isRGE(address _address) external view returns (bool) {
    if (users[_address].rolesList == rolesList.RGE) {
      return true;
    }
    return false;
  }

  /// @notice Check if the sender is an Oblige
  function isNonOblige(address _address) external view returns (bool) {
    if (users[_address].rolesList == rolesList.NONOBLIGE) {
      return true;
    }
    return false;
  }

  /// @notice Check if the sender is an Oblige
  function isOblige(address _address) external view returns (bool) {
    if (users[_address].rolesList == rolesList.OBLIGE) {
      return true;
    }
    return false;
  }

  /// @notice Get the role of a specific address
  function getUserRole(address _address) external view returns (rolesList) {
    return users[_address].rolesList;
  }

  /// @notice Get the isVerified value of a specific address
  function getUserVerifiedStatus(address _address) external view returns (bool) {
    return users[_address].isVerified;
  }

  /// @notice Get the isBlacklisted value of a specific address
  function getUserBlacklistedStatus(address _address) external view returns (bool) {
    return users[_address].isBlacklisted;
  }
}