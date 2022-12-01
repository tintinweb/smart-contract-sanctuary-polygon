// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {AcessControl} from "../libraries/LibAccessControl.sol";



/// @notice this contract would be handling access control matter for the web3bridge doa ecosystem
contract AccessControl {
/// @notice this function would be used for initilizing the superuser 
    /// @dev this function can only called once 
    /// @param _superuser: this is the address of the would be superuser 
    function setUp(address _superuser) external {
        AcessControl.setUp(_superuser);
    }

    /// @notice 
    /// @dev [this is would be guided by this assess control]
    /// @param _role: this is the role this is to be assigned to the address (keccak256("NAME_OF_ROLE"))
    /// @param _assignee: this is the address the role would be assigned to 
    function grantRole(bytes32 _role, address _assignee) external {
        AcessControl.grantRole(_role, _assignee, msg.sender);
    }

    /// @notice this function would be used by the superuser to revoke role given to and address 
    /// @dev during this process, this function would be gated in that only yhe superuser can make this call
    function revokeRole(bytes32 _role, address _assignee) external {
        AcessControl.revokeRole(_role, _assignee, msg.sender);
    }

    /// @notice this function is a view that would be used to check if an address has a role 
    /// @dev this function would not be guided 
    /// @param _role: this is the role this is to be assigned to the address (keccak256("NAME_OF_ROLE"))
    /// @param _assignee: this is the address the role would be assigned to 
    function hasRole(bytes32 _role, address _assignee) external view returns(bool isAdmin_) {
        isAdmin_ = AcessControl.hasRole(_role, _assignee);
    }

    /// @notice this function would be used to transfer superuser ownership to different account 
    /// @dev only superuser can make this change 
    /// @param _superuser: this is the address of the would be superuser 
    function transferSuper(address _superuser) external {
        AcessControl.transferSuper(_superuser, msg.sender);
    }
}


// role: bytes32(abi.encodePacked(keccak256("PRE_CERTIFICATE_TOKEN_MANAGER")))

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library Dto {
  struct GovernorStorage {
    mapping(bytes32 => mapping(address => bool)) role; // role => address => status
    address superuser;
    bool is_initialized;
  }
}

library Positions {
  bytes32 constant GOVERNOR_STORAGE_POSITION = keccak256("access.control.bridge.dao.storage");
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
    event RoleGranted(bytes32 role, address assignee);
    event RoleRevoked(bytes32 role, address assignee);
    event Setuped(address superuser);
    event SuperuserTransfered(address new_superuser);


  function governorStorage() internal pure returns (Dto.GovernorStorage storage ms) {
    bytes32 position = Positions.GOVERNOR_STORAGE_POSITION;
    assembly {
      ms.slot := position
    }
  }

  function enforceSuperUser(address _addr) internal view {
    Dto.GovernorStorage storage ms = governorStorage();
    if(_addr == ms.superuser) {
        revert Errors.NOT_SUPERUSER();
    }
  }

  function setUp(address _superuser) internal {
    Dto.GovernorStorage storage ms = governorStorage();
    if(ms.is_initialized == true) {
        revert Errors.HAS_BEEN_INITIALIZED();
    }

    ms.superuser = _superuser;
    ms.is_initialized = true;

    emit Setuped(_superuser);
  }


  function grantRole(bytes32 _role, address _assignee, address _current_caller) internal {
    enforceSuperUser(_current_caller);
    Dto.GovernorStorage storage ms = governorStorage();
    ms.role[_role][_assignee] = true;

    emit RoleGranted(_role, _assignee);
  }

  function revokeRole(bytes32 _role, address _assignee, address _current_caller) internal {
    enforceSuperUser(_current_caller);
    Dto.GovernorStorage storage ms = governorStorage();
    ms.role[_role][_assignee] = false;

    emit RoleRevoked(_role, _assignee);
  }

  function hasRole(bytes32 _role, address _assignee) internal view returns(bool has_role) {
    Dto.GovernorStorage storage ms = governorStorage();
    if(_assignee == ms.superuser) {
        return true;
    } else {
        return ms.role[_role][_assignee];
    }
  }

  
  function hasRoleWithRevert(bytes32 _role, address _assignee) internal view returns(bool has_role) {
    Dto.GovernorStorage storage ms = governorStorage();
    if(_assignee == ms.superuser || ms.role[_role][_assignee]) {
        return true;
    } else {
        revert Errors.NOT_ROLE_MEMBER();
    }
  }


  function transferSuper(address _superuser, address _current_caller) internal {
    enforceSuperUser(_current_caller);
    Dto.GovernorStorage storage ms = governorStorage();
    ms.superuser = _superuser;

    emit SuperuserTransfered(_superuser);
  }
}