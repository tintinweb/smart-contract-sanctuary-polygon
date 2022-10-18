// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '../interfaces/IAccessController.sol';
import '@openzeppelin/contracts/access/Ownable.sol'; 

/**
 * @title Access Controller contract
 * @notice Implements basic access control 
 * Copied from Aave V2
 **/
 
contract AccessController is IAccessController, Ownable {
    struct UserData {
        uint256 permissions;
        address permissionAdmin;
    }

  mapping(address => UserData) _users;
  mapping(address => uint256) _permissionsAdmins;

  uint256 public constant MAX_NUM_OF_ROLES = 256;

  modifier onlyPermissionAdmins(address user) {
    require(_permissionsAdmins[user] > 0, 'CALLER_NOT_PERMISSIONS_ADMIN');
    _;
  }

  ///@inheritdoc IAccessController
  function addPermissionAdmins(address[] calldata admins) external onlyOwner {
    for (uint256 i = 0; i < admins.length; i++) {
      _permissionsAdmins[admins[i]] = 1;

      emit PermissionsAdminSet(admins[i], true);
    }
  }

  ///@inheritdoc IAccessController
  function removePermissionAdmins(address[] calldata admins) external onlyOwner {
    for (uint256 i = 0; i < admins.length; i++) {
      _permissionsAdmins[admins[i]] = 0;

      emit PermissionsAdminSet(admins[i], false);
    }
  }

  ///@inheritdoc IAccessController
  function addPermissions(uint256[] calldata roles, address[] calldata users)
    external
    onlyPermissionAdmins(msg.sender)
  {
    require(roles.length == users.length, 'INCONSISTENT_ARRAYS_LENGTH');

    for (uint256 i = 0; i < users.length; i++) {
      uint256 role = roles[i];
      address user = users[i];

      require(role < MAX_NUM_OF_ROLES, 'INVALID_ROLE');

      uint256 permissions = _users[user].permissions;
      address permissionAdmin = _users[user].permissionAdmin;

      require(
        (permissions != 0 && permissionAdmin == msg.sender) ||
          _users[user].permissionAdmin == address(0),
        'INVALID_PERMISSIONADMIN'
      );

      if (permissions == 0) {
        _users[user].permissionAdmin = msg.sender;
      }

      _users[user].permissions = permissions | (1 << role);

      emit RoleSet(user, role, msg.sender, true);
    }
  }

  ///@inheritdoc IAccessController
  function removePermissions(uint256[] calldata roles, address[] calldata users)
    external
    onlyPermissionAdmins(msg.sender)
  {
    require(roles.length == users.length, 'INCONSISTENT_ARRAYS_LENGTH');

    for (uint256 i = 0; i < users.length; i++) {
      uint256 role = roles[i];
      address user = users[i];

      require(role < MAX_NUM_OF_ROLES, 'INVALID_ROLE');

      uint256 permissions = _users[user].permissions;
      address permissionAdmin = _users[user].permissionAdmin;

      require(
        (permissions != 0 && permissionAdmin == msg.sender) ||
          _users[user].permissionAdmin == address(0),
        'INVALID_PERMISSIONADMIN'
      );

      _users[user].permissions = permissions & ~(1 << role);

      if (_users[user].permissions == 0) {
        //all permission have been removed
        _users[user].permissionAdmin = address(0);
      }

      emit RoleSet(user, role, msg.sender, false);
    }
  }

  ///@inheritdoc IAccessController
  function getUserPermissions(address user)
    external
    view
    returns (uint256[] memory, uint256)
  {
    uint256[] memory roles = new uint256[](256);
    uint256 rolesCount = 0;
    uint256 userPermissions = _users[user].permissions;

    for (uint256 i = 0; i < 256; i++) {
      if ((userPermissions >> i) & 1 > 0) {
        roles[rolesCount] = i;
        rolesCount++;
      }
    }

    return (roles, rolesCount);
  }

  ///@inheritdoc IAccessController
  function isInRole(address user, uint256 role) public view returns (bool) {
    return (_users[user].permissions >> role) & 1 > 0;
  }

  function isEnableToMint(address user) external view returns (bool) {
    return (isInRole(user, 0) || isPermissionsAdmin(user));
  }

  ///@inheritdoc IAccessController
  function isInAllRoles(address user, uint256[] calldata roles)
    external
    view
    returns (bool)
  {
    for (uint256 i = 0; i < roles.length; i++) {
      if ((_users[user].permissions >> roles[i]) & 1 == 0) {
        return false;
      }
    }
    return true;
  }

  ///@inheritdoc IAccessController
  function isInAnyRole(address user, uint256[] calldata roles)
    external
    view
    returns (bool)
  {
    for (uint256 i = 0; i < roles.length; i++) {
      if ((_users[user].permissions >> roles[i]) & 1 > 0) {
        return true;
      }
    }
    return false;
  }

  ///@inheritdoc IAccessController
  function isPermissionsAdmin(address admin) public view returns (bool) {
    return _permissionsAdmins[admin] > 0;
  }

  ///@inheritdoc IAccessController
  function getUserPermissionAdmin(address user) external view returns (address) {
    return _users[user].permissionAdmin;
  }

  ///@inheritdoc IAccessController
  function isUserPermissionAdminValid(address user) external view returns (bool) {
    return _permissionsAdmins[_users[user].permissionAdmin] > 0;
  }
    
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IAccessController {
  event RoleSet(address indexed user, uint256 indexed role, address indexed whiteLister, bool set);
  event PermissionsAdminSet(address indexed user, bool set);

  /**
   * @dev Allows owner to add new permission admins
   * @param admins The addresses to promote to permission admin
   **/
  function addPermissionAdmins(address[] calldata admins) external;

  /**
   * @dev Allows owner to remove permission admins
   * @param admins The addresses to demote as permission admin
   **/
  function removePermissionAdmins(address[] calldata admins) external;

  /**
   * @dev Allows owner to whitelist a set of addresses for multiple roles
   * @param roles The list of roles to assign
   * @param users The list of users to add to the corresponding role
   **/
  function addPermissions(uint256[] calldata roles, address[] calldata users) external;

  /**
   * @dev Allows owner to remove permissions on a set of addresses
   * @param roles The list of roles to remove
   * @param users The list of users to remove from the corresponding role
   **/
  function removePermissions(uint256[] calldata roles, address[] calldata users) external;

  /**
   * @dev Returns the permissions configuration for a specific user
   * @param user The address of the user
   * @return the set of permissions states for the user
   **/
  function getUserPermissions(address user) external view returns (uint256[] memory, uint256);

  /**
   * @dev Returns if a user is enable to mint a new NFT
   * @param user The address of the user
   * @return boolean to confirm is the user is enable
   **/
  function isEnableToMint(address user) external view returns (bool);

  /**
   * @dev Used to query if a certain user has a certain role
   * @param user The address of the user
   * @return True if the user is in the specific role
   **/
  function isInRole(address user, uint256 role) external view returns (bool);

  /**
   * @dev Used to query if a certain user has the permissions admin role
   * @param user The address of the user
   * @return True if the user is a permissions admin, false otherwise
   **/
  function isPermissionsAdmin(address user) external view returns (bool);

  /**
   * @dev Used to query if a certain user satisfies certain roles
   * @param user The address of the user
   * @param roles The roles to check
   * @return True if the user has all the roles, false otherwise
   **/
  function isInAllRoles(address user, uint256[] calldata roles) external view returns (bool);

  /**
   * @dev Used to query if a certain user is in at least one of the roles specified
   * @param user The address of the user
   * @return True if the user has all the roles, false otherwise
   **/
  function isInAnyRole(address user, uint256[] calldata roles) external view returns (bool);

  /**
   * @dev Used to query if a certain user is in at least one of the roles specified
   * @param user The address of the user
   * @return the address of the permissionAdmin of the user
   **/
  function getUserPermissionAdmin(address user) external view returns (address);

  /**
   * @dev Used to query if the permission admin of a certain user is valid
   * @param user The address of the user
   * @return true if the permission admin of user is valid, false otherwise
   **/
  function isUserPermissionAdminValid(address user) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}