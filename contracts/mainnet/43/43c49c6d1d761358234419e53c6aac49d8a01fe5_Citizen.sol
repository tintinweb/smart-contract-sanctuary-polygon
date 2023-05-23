// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

import "./libs/fota/Auth.sol";
import "./libs/fota/StringUtil.sol";

contract Citizen is Auth {
  using StringUtil for string;
  struct Resident {
    uint id;
    string userName;
    address inviter;
  }
  mapping (address => Resident) public residents;
  mapping (address => bool) public whiteList;
  mapping (bytes24 => address) private userNameAddresses;
  uint totalResident;
  address public defaultInviter;

  event Registered(address indexed userAddress, string userName, address indexed inviter, uint timestamp);
  event InviterUpdated(address[] users, address inviter);
  event DefaultInviterUpdated(address indexed inviter);
  event SetWhiteListed(address indexed userAddress, bool status);

  function initialize(address _mainAdmin) override public initializer {
    super.initialize(_mainAdmin);
    defaultInviter = _mainAdmin;
  }

  function register(string calldata _userName, address _inviter) external returns (uint) {
    if (_inviter == address(0)) {
      _inviter = defaultInviter;
    }
    require(isCitizen(_inviter) && msg.sender != _inviter, "Citizen: inviter is invalid");
    require(_userName.validateUserName(), "Citizen: invalid userName");
    Resident storage resident = residents[msg.sender];
    require(!isCitizen(msg.sender), "Citizen: already an citizen");
    bytes24 _userNameAsKey = _userName.toBytes24();
    require(userNameAddresses[_userNameAsKey] == address(0), "Citizen: userName already exist");
    userNameAddresses[_userNameAsKey] = msg.sender;

    totalResident += 1;
    resident.id = totalResident;
    resident.userName = _userName;
    resident.inviter = _inviter;
    emit Registered(msg.sender, _userName, _inviter, block.timestamp);
    return resident.id;
  }

  function isCitizen(address _address) view public returns (bool) {
    if (whiteList[_address]) {
      return true;
    }
    Resident storage resident = residents[_address];
    return resident.id > 0;
  }

  function getInviter(address _address) view public returns (address) {
    Resident storage resident = residents[_address];
    return resident.inviter;
  }

  function setWhiteList(address _address, bool _status) external onlyMainAdmin {
    require(_address != address(0), "Citizen: invalid address");
    whiteList[_address] = _status;
    emit SetWhiteListed(_address, _status);
  }

  function updateInviter(address[] calldata _addresses, address _inviter) external onlyMainAdmin {
    for(uint i = 0; i < _addresses.length; i++) {
      residents[_addresses[i]].inviter = _inviter;
    }
    emit InviterUpdated(_addresses, _inviter);
  }

  function updateDefaultInviter(address _inviter) external onlyMainAdmin {
    require(isCitizen(_inviter), "Citizen: please register first");
    defaultInviter = _inviter;
    emit DefaultInviterUpdated(_inviter);
  }

  function syncResidents(address[] calldata _residents, uint[] calldata _ids, string[] calldata _userNames, address[] calldata _inviters) external onlyContractAdmin {
    require(_residents.length == _ids.length && _ids.length == _userNames.length && _inviters.length == _inviters.length, "Citizen: data length invalid");
    totalResident += _residents.length;
    Resident storage resident;
    for(uint i = 0; i < _residents.length; i++) {
      resident = residents[_residents[i]];
      resident.id = _ids[i];
      resident.userName = _userNames[i];
      resident.inviter = _inviters[i];
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

library StringUtil {
  struct slice {
    uint _length;
    uint _pointer;
  }

  function validateUserName(string calldata _username)
  internal
  pure
  returns (bool)
  {
    uint8 len = uint8(bytes(_username).length);
    if ((len < 4) || (len > 21)) return false;

    // only contain A-Z 0-9
    for (uint8 i = 0; i < len; i++) {
      if (
        (uint8(bytes(_username)[i]) < 48) ||
        (uint8(bytes(_username)[i]) > 57 && uint8(bytes(_username)[i]) < 65) ||
        (uint8(bytes(_username)[i]) > 90)
      ) return false;
    }
    // First char != '0'
    return uint8(bytes(_username)[0]) != 48;
  }

  function toBytes24(string memory source)
  internal
  pure
  returns (bytes24 result)
  {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
      return 0x0;
    }

    assembly {
      result := mload(add(source, 24))
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Auth is Initializable {

  address public mainAdmin;
  address public contractAdmin;

  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
  event ContractAdminUpdated(address indexed _newOwner);

  function initialize(address _mainAdmin) virtual public initializer {
    mainAdmin = _mainAdmin;
    contractAdmin = _mainAdmin;
  }

  modifier onlyMainAdmin() {
    require(_isMainAdmin(), "onlyMainAdmin");
    _;
  }

  modifier onlyContractAdmin() {
    require(_isContractAdmin() || _isMainAdmin(), "onlyContractAdmin");
    _;
  }

  function transferOwnership(address _newOwner) onlyMainAdmin external {
    require(_newOwner != address(0x0));
    mainAdmin = _newOwner;
    emit OwnershipTransferred(msg.sender, _newOwner);
  }

  function updateContractAdmin(address _newAdmin) onlyMainAdmin external {
    require(_newAdmin != address(0x0));
    contractAdmin = _newAdmin;
    emit ContractAdminUpdated(_newAdmin);
  }

  function _isMainAdmin() public view returns (bool) {
    return msg.sender == mainAdmin;
  }

  function _isContractAdmin() public view returns (bool) {
    return msg.sender == contractAdmin;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}