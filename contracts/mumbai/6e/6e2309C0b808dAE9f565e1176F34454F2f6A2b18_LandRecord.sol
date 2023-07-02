// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./interface/IOwnable.sol";

/**
 *  @title   Ownable
 *  @notice  Thirdweb's `Ownable` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *           who the 'owner' of the inheriting smart contract is, and lets the inheriting contract perform conditional logic that uses
 *           information about who the contract's owner is.
 */

abstract contract Ownable is IOwnable {
    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address private _owner;

    /// @dev Reverts if caller is not the owner.
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert("Not authorized");
        }
        _;
    }

    /**
     *  @notice Returns the owner of the contract.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     *  @notice Lets an authorized wallet set a new owner for the contract.
     *  @param _newOwner The address to set as the new owner of the contract.
     */
    function setOwner(address _newOwner) external override {
        if (!_canSetOwner()) {
            revert("Not authorized");
        }
        _setupOwner(_newOwner);
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function _setupOwner(address _newOwner) internal {
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 *  Thirdweb's `Ownable` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *  who the 'owner' of the inheriting smart contract is, and lets the inheriting contract perform conditional logic that uses
 *  information about who the contract's owner is.
 */

interface IOwnable {
    /// @dev Returns the owner of the contract.
    function owner() external view returns (address);

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external;

    /// @dev Emitted when a new Owner is set.
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@thirdweb-dev/contracts/extension/Ownable.sol';

struct User {
  address id;
  string name;
  string aadharNumber;
  bool isVerified;
}

struct Inspector {
  address id;
  string name;
}

struct Land {
  uint id;
  uint area;
  string landAddress;
  string latLng;
  uint propertyId;
  address payable ownerAddr;
  bool isVerified;
}

struct LandTransferRequest {
  uint id;
  uint propertyId;
  address payable from;
  address payable to;
  bool accepted;
}

struct LandTransferRequestWithLand {
  Land land;
}

contract LandRecord is Ownable {
  event InspectorAdded(address indexed id, string name);
  event InspectorUpdated(address indexed id, string name);

  mapping(address => Inspector) inspectorsMapping;
  address[] inspectors;

  mapping(address => User) usersMapping;
  address[] users;

  mapping(uint => Land) landsMapping;
  uint[] lands;
  mapping(address => uint[]) usersLandMapping;

  mapping(uint => LandTransferRequest) landTransferRequestsMapping;
  uint[] landTransferRequests;
  mapping(address => uint[]) userTransferRequestsMapping;
  mapping(address => uint[]) userReceivedRequestMapping;

  modifier onlyInspector() {
    if (!isInspectorExist(msg.sender)) {
      revert('User is not inspector');
    }

    _;
  }

  constructor() {
    _setupOwner(msg.sender);
  }

  function isContractOwner(address _addr) public view returns (bool) {
    return _addr == owner();
  }

  function isInspectorExist(address _addr) public view returns (bool) {
    return (inspectorsMapping[_addr].id != address(0));
  }

  function getInspectorCount() public view returns (uint) {
    return inspectors.length;
  }

  function getInspector(address _addr) public view returns (Inspector memory) {
    require(isInspectorExist(_addr), 'Inspector does not exist');

    return inspectorsMapping[_addr];
  }

  function getAllInspectors() public view returns (Inspector[] memory) {
    Inspector[] memory _inspectors = new Inspector[](inspectors.length);
    for (uint256 i = 0; i < inspectors.length; i++) {
      _inspectors[i] = inspectorsMapping[inspectors[i]];
    }

    return _inspectors;
  }

  function addInspector(address _id, string memory _name) external onlyOwner {
    require(!isInspectorExist(_id), 'Inspector already exist');

    inspectorsMapping[_id] = Inspector(_id, _name);
    inspectors.push(_id);

    emit InspectorAdded(_id, _name);
  }

  function updateInspector(string memory _name) external {
    address _addr = msg.sender;

    require(isInspectorExist(_addr), 'Inspector does not exist');

    inspectorsMapping[_addr].name = _name;

    emit InspectorUpdated(_addr, _name);
  }

  function getUserCount() public view returns (uint) {
    return users.length;
  }

  function getAllUsers() public view returns (User[] memory) {
    User[] memory _users = new User[](users.length);
    for (uint256 i = 0; i < users.length; i++) {
      _users[i] = usersMapping[users[i]];
    }

    return _users;
  }

  function getUser(address _addr) public view returns (User memory) {
    require(isUserExist(_addr), 'User does not exist');

    return usersMapping[_addr];
  }

  function isUserExist(address _addr) public view returns (bool) {
    return (usersMapping[_addr].id != address(0));
  }

  function addUser(string memory _name, string memory _aadharNumber) external {
    address _addr = msg.sender;

    require(!isUserExist(_addr), 'User already exist');

    usersMapping[_addr] = User(_addr, _name, _aadharNumber, false);
    users.push(_addr);
  }

  function updateUser(
    string memory _name,
    string memory _aadharNumber
  ) external {
    address _addr = msg.sender;

    require(isUserExist(_addr), 'User does not exist');

    usersMapping[_addr].name = _name;
    usersMapping[_addr].aadharNumber = _aadharNumber;
  }

  function verifyUser(address _addr) external onlyInspector {
    usersMapping[_addr].isVerified = true;
  }

  function isLandExist(uint _propertyId) public view returns (bool) {
    return (landsMapping[_propertyId].id != 0);
  }

  function getLandCount() public view returns (uint) {
    return lands.length;
  }

  function getAllLands() public view returns (Land[] memory) {
    Land[] memory _lands = new Land[](lands.length);
    for (uint256 i = 0; i < lands.length; i++) {
      _lands[i] = landsMapping[lands[i]];
    }

    return _lands;
  }

  function getAllLands(address _addr) public view returns (Land[] memory) {
    require(isUserExist(_addr), 'User not Exist');

    uint[] memory _landsId = usersLandMapping[_addr];
    Land[] memory _lands = new Land[](_landsId.length);

    for (uint256 i = 0; i < _landsId.length; i++) {
      _lands[i] = landsMapping[_landsId[i]];
    }

    return _lands;
  }

  function getLand(uint _id) public view returns (Land memory) {
    require(isLandExist(_id), 'Land does not exist');

    return landsMapping[_id];
  }

  function addLand(
    uint _area,
    string memory _landAddress,
    string memory _latLng,
    uint _propertyId
  ) external {
    require(!isLandExist(_propertyId), 'Land already exist');

    uint _id = lands.length + 1;

    landsMapping[_propertyId] = Land(
      _id,
      _area,
      _landAddress,
      _latLng,
      _propertyId,
      payable(msg.sender),
      false
    );
    lands.push(_propertyId);
    usersLandMapping[msg.sender].push(_propertyId);
  }

  function updateLand(
    uint _propertyId,
    uint _area,
    string memory _landAddress,
    string memory _latLng
  ) external {
    require(isLandExist(_propertyId), 'Land does not exist');
    require(
      landsMapping[_propertyId].ownerAddr == msg.sender,
      'Only land owner can update'
    );

    landsMapping[_propertyId].area = _area;
    landsMapping[_propertyId].landAddress = _landAddress;
    landsMapping[_propertyId].latLng = _latLng;
  }

  function verifyLand(uint _propertyId) external onlyInspector {
    require(isLandExist(_propertyId), 'Land does not exist');

    landsMapping[_propertyId].isVerified = true;
  }

  function transferLand(
    uint _propertyId,
    address payable _newOwnerAddr
  ) internal onlyInspector {
    require(isLandExist(_propertyId), 'Land does not exist');
    address prevOwnerAddr = landsMapping[_propertyId].ownerAddr;

    landsMapping[_propertyId].ownerAddr = _newOwnerAddr;
    usersLandMapping[_newOwnerAddr].push(_propertyId);

    uint[] memory usersLands = usersLandMapping[prevOwnerAddr];
    for (uint i = 0; i < usersLands.length; i++) {
      if (usersLands[i] == _propertyId) {
        delete usersLandMapping[prevOwnerAddr][i];

        usersLandMapping[prevOwnerAddr][i] = usersLands[i];
        usersLandMapping[prevOwnerAddr].pop();
        break;
      }
    }
  }

  function sendTansferRequest(uint _propertyId, address to) external {
    require(isLandExist(_propertyId), 'Land does not exist');
    require(
      landsMapping[_propertyId].ownerAddr == msg.sender,
      'Only land owner can start transfer'
    );
    require(landsMapping[_propertyId].isVerified, 'Land is not yet verified');

    uint _id = landTransferRequests.length;
    LandTransferRequest memory req = LandTransferRequest(
      _id,
      _propertyId,
      payable(msg.sender),
      payable(to),
      false
    );

    landTransferRequestsMapping[_id] = req;
    landTransferRequests.push(_id);
    userTransferRequestsMapping[msg.sender].push(_id);
    userReceivedRequestMapping[to].push(_id);
  }

  function isTransferRequestExist(uint _transferId) public view returns (bool) {
    return landTransferRequestsMapping[_transferId].id == _transferId;
  }

  function acceptRequest(uint _transferId) external {
    require(isTransferRequestExist(_transferId), 'Invalid transfer id');
    require(
      landTransferRequestsMapping[_transferId].to == msg.sender,
      'Not the receiver of the transfer'
    );

    landTransferRequestsMapping[_transferId].accepted = true;
  }

  function approveTransferRequest(uint _transferId) external onlyInspector {
    require(isTransferRequestExist(_transferId), 'Invalid transfer id');

    LandTransferRequest memory req = landTransferRequestsMapping[_transferId];

    transferLand(req.propertyId, req.to);
    delete landTransferRequestsMapping[_transferId];

    for (uint i = 0; i < landTransferRequests.length; i++) {
      if (landTransferRequests[i] == _transferId) {
        delete landTransferRequests[i];
        landTransferRequests[i] = landTransferRequests[
          landTransferRequests.length - 1
        ];
        landTransferRequests.pop();
        break;
      }
    }

    for (uint i = 0; i < userTransferRequestsMapping[req.from].length; i++) {
      if (userTransferRequestsMapping[req.from][i] == _transferId) {
        delete userTransferRequestsMapping[req.from][i];
        userTransferRequestsMapping[req.from][i] = userTransferRequestsMapping[
          req.from
        ][userTransferRequestsMapping[req.from].length - 1];
        userTransferRequestsMapping[req.from].pop();
        break;
      }
    }

    for (uint i = 0; i < userReceivedRequestMapping[req.to].length; i++) {
      if (userReceivedRequestMapping[req.to][i] == _transferId) {
        delete userReceivedRequestMapping[req.to][i];
        userReceivedRequestMapping[req.to][i] = userReceivedRequestMapping[
          req.to
        ][userReceivedRequestMapping[req.to].length - 1];
        userReceivedRequestMapping[req.to].pop();
        break;
      }
    }
  }

  function usersSentTransferRequests(
    address _id
  ) public view returns (Land[] memory) {
    uint reqLen = userTransferRequestsMapping[_id].length;
    Land[] memory _lands = new Land[](reqLen);

    for (uint i = 0; i < reqLen; i++) {
      _lands[i] = landsMapping[
        landTransferRequestsMapping[userTransferRequestsMapping[_id][i]]
          .propertyId
      ];
    }

    return _lands;
  }

  function usersReceivedTransferRequests(
    address _id
  ) public view returns (Land[] memory) {
    uint reqLen = userReceivedRequestMapping[_id].length;
    Land[] memory _lands = new Land[](reqLen);

    for (uint i = 0; i < reqLen; i++) {
      _lands[i] = landsMapping[
        landTransferRequestsMapping[userReceivedRequestMapping[_id][i]]
          .propertyId
      ];
    }

    return _lands;
  }

  function _canSetOwner() internal view virtual override returns (bool) {
    return msg.sender == owner();
  }
}