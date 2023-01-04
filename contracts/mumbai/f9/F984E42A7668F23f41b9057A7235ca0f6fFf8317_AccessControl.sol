// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {AcessControl, Dto} from "../libraries/LibAccessControl.sol";

/// @notice this contract would be handling access control matter for the web3bridge doa ecosystem
contract AccessControl {
    /// @notice this function would be used for initilizing the superuser
    /// @dev this function can only called once
    /// @param _superuser: this is the address of the would be superuser
    function setUp(address _superuser) external {
        AcessControl.setUp(_superuser);
    }

    /// @notice this function would be useed to grant role to an account 
    /// @dev [this is would be guided by this assess control] (and this access control has been implemented in the provider)
    /// @param _role: this is the role this is to be assigned to the address (keccak256("NAME_OF_ROLE"))
    /// @param _assignee: this is the address the role would be assigned to
    function grantRole(Dto.Roles _role, address _assignee) external {
        AcessControl.grantRole(_assignee, _role);
    }

    /// @notice this function would be used by the superuser to revoke role given to and address
    /// @dev during this process, this function would be gated in that only yhe superuser can make this call
    function revokeRole(Dto.Roles _role, address _assignee) external {
        AcessControl.revokeRole(_role, _assignee);
    }

    /// @notice this function is a view that would be used to check if an address has a role
    /// @dev this function would not be guided
    /// @param _role: this is the role this is to be assigned to the address (keccak256("NAME_OF_ROLE"))
    /// @param _assignee: this is the address the role would be assigned to
    function hasRole(Dto.Roles _role, address _assignee) external view returns (bool isAdmin_) {
        isAdmin_ = AcessControl.hasRole(_role, _assignee);
    }

    /// @notice this function would be used to transfer superuser ownership to different account
    /// @dev only superuser can make this change
    /// @param _superuser: this is the address of the would be superuser
    function transferSuper(address _superuser) external {
        AcessControl.transferSuper(_superuser, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library Dto {
  enum Roles {
    DEFAULT, // This is the role that all addresses has by default 
    DAO_GOVERNACE_MANAGER, // This role would be allowed to carryout governing action like creating proposal 
    ADMIN_OPERATOR, // This role would be able to call all the function in the admin ops facet
    CERTIFICATE_MANAGER, // This role owner would be able to deploy new certificate when a cohort graduate
    TOKEN_FACTORY,
    PRE_CERTIFICATE_TOKEN_MANAGER // this role owner would be able to call guarded function in the precertificate token 
  }
  struct AccessControlStorage {
    mapping(address => Roles) role; // address => role
    address superuser; // The superuser can preform all the role and assign role to addresses 
    bool is_initialized;
  }
}

library Positions {
  bytes32 constant ACCESS_CONTROL_STORAGE_POSITION = keccak256("access.control.bridge.dao.storage");
}

library Errors {
  error NOT_SUPERUSER();
  error HAS_BEEN_INITIALIZED();
  error NOT_ROLE_MEMBER();
}




library AcessControl {
    // ================================
    // EVENT
    // ================================
    event RoleGranted(Dto.Roles role, address assignee);
    event RoleRevoked(Dto.Roles role, address assignee);
    event Setuped(address superuser);
    event SuperuserTransfered(address new_superuser);


  function accessControlStorage() internal pure returns (Dto.AccessControlStorage storage ms) {
    bytes32 position = Positions.ACCESS_CONTROL_STORAGE_POSITION;
    assembly {
      ms.slot := position
    }
  }

  function enforceSuperUser(address _addr) internal view {
    Dto.AccessControlStorage storage ms = accessControlStorage();
    if(_addr == ms.superuser) {
        revert Errors.NOT_SUPERUSER();
    }
  }

  function setUp(address _superuser) internal {
    Dto.AccessControlStorage storage ms = accessControlStorage();
    if(ms.is_initialized == true) {
        revert Errors.HAS_BEEN_INITIALIZED();
    }

    ms.superuser = _superuser;
    ms.is_initialized = true;

    emit Setuped(_superuser);
  }


  function grantRole(address _assignee, Dto.Roles _role) internal {
    enforceSuperUser(msg.sender);
    Dto.AccessControlStorage storage ms = accessControlStorage();
    ms.role[_assignee] = _role;

    emit RoleGranted(_role, _assignee);
  }

  function revokeRole(Dto.Roles _role, address _assignee) internal {
    enforceSuperUser(msg.sender);
    Dto.AccessControlStorage storage ms = accessControlStorage();
    ms.role[_assignee] = Dto.Roles.DEFAULT;

    emit RoleRevoked(_role, _assignee);
  }

  function hasRole(Dto.Roles _role, address _assignee) internal view returns(bool has_role) {
    Dto.AccessControlStorage storage ms = accessControlStorage();
    has_role = _assignee == ms.superuser|| _role == ms.role[_assignee];
  }

  
  function hasRoleWithRevert(Dto.Roles _role, address _assignee) internal view returns(bool has_role) {
    if(hasRole(_role, _assignee)) {
        return true;
    } else {
        revert Errors.NOT_ROLE_MEMBER();
    }
  }


  function transferSuper(address _superuser, address _current_caller) internal {
    enforceSuperUser(_current_caller);
    Dto.AccessControlStorage storage ms = accessControlStorage();
    ms.superuser = _superuser;

    emit SuperuserTransfered(_superuser);
  }
}