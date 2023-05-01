// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

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

contract LandRecord {
  address contractOwner;

  mapping(address => User) usersMapping;
  address[] users;

  mapping(address => Inspector) inspectorsMapping;
  address[] inspectors;

  mapping(uint => Land) landsMapping;
  uint[] lands;
  mapping(address => uint[]) usersLand;

  constructor() {
    contractOwner = msg.sender;
  }

  function getSender() external view returns (address) {
    return msg.sender;
  }

  function getOwner() public view returns (address) {
    return contractOwner;
  }

  function isContractOwner(address _addr) public view returns (bool) {
    return (_addr == contractOwner);
  }

  function isUserExist(address _addr) public view returns (bool) {
    return (usersMapping[_addr].id != address(0));
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

  function getUser() public view returns (User memory) {
    require(!isUserExist(msg.sender), 'User does not exist');

    return usersMapping[msg.sender];
  }

  function addUser(string memory _name, string memory _aadharNumber) public {
    address _addr = msg.sender;

    require(isUserExist(_addr), 'User already exist');

    usersMapping[_addr] = User(_addr, _name, _aadharNumber, false);
    users.push(_addr);
  }

  function updateUser(string memory _name, string memory _aadharNumber) public {
    address _addr = msg.sender;

    require(!isUserExist(_addr), 'User does not exist');

    usersMapping[_addr].name = _name;
    usersMapping[_addr].aadharNumber = _aadharNumber;
  }

  function verifyUser(address _addr) public {
    require(!isInspectorExist(msg.sender), 'User is not inspector');

    usersMapping[_addr].isVerified = true;
  }

  function isInspectorExist(address _addr) public view returns (bool) {
    return (inspectorsMapping[_addr].id != address(0));
  }

  function getInspectorCount() public view returns (uint) {
    return inspectors.length;
  }

  function getAllInspectors() public view returns (Inspector[] memory) {
    Inspector[] memory _inspectors = new Inspector[](inspectors.length);
    for (uint256 i = 0; i < inspectors.length; i++) {
      _inspectors[i] = inspectorsMapping[inspectors[i]];
    }

    return _inspectors;
  }

  function getInspector(address _addr) public view returns (Inspector memory) {
    require(!isInspectorExist(_addr), 'Inspector does not exist');

    return inspectorsMapping[_addr];
  }

  function addInspector(address _addr, string memory _name) public {
    require(!isContractOwner(msg.sender), 'Only owner can add inspector');
    require(isInspectorExist(_addr), 'Inspector already exist');

    inspectorsMapping[_addr] = Inspector(_addr, _name);
    inspectors.push(_addr);
  }

  function updateInspector(string memory _name) public {
    address _addr = msg.sender;

    require(!isInspectorExist(_addr), 'Inspector does not exist');

    inspectorsMapping[_addr].name = _name;
  }

  function addLand(
    uint _area,
    string memory _landAddress,
    string memory _latLng,
    uint _propertyId
  ) public {
    address _addr = msg.sender;

    require(!isUserExist(_addr), 'User does not exist');

    uint _id = lands.length + 1;
    landsMapping[_id] = Land(
      _id,
      _area,
      _landAddress,
      _latLng,
      _propertyId,
      payable(_addr),
      false
    );
    lands.push(_id);
    usersLand[_addr].push(_id);
  }

  function verifyLand(uint _id) public {
    require(!isInspectorExist(msg.sender), 'User is not inspector');

    landsMapping[_id].isVerified = true;
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

  function getUserLands() public view returns (Land[] memory) {
    address _addr = msg.sender;

    require(!isUserExist(_addr), 'User does not exist');

    uint[] memory _lands = usersLand[_addr];
    Land[] memory _userLands = new Land[](_lands.length);
    for (uint256 i = 0; i < _lands.length; i++) {
      _userLands[i] = landsMapping[_lands[i]];
    }

    return _userLands;
  }
}