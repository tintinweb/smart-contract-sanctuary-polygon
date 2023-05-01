// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

struct User {
  address id;
  string name;
  string aadharNumber;
}

contract LandRecord {
  address contractOwner;

  mapping(address => User) public usersMapping;
  address[] public users;

  constructor() {
    contractOwner = msg.sender;
  }

  function isContractOwner(address _addr) public view returns (bool) {
    return (_addr == contractOwner);
  }

  function isUserExist(address _addr) public view returns (bool) {
    return (usersMapping[_addr].id == address(0));
  }

  function getAllUsers() public view returns (User[] memory) {
    User[] memory _users = new User[](users.length);
    for (uint256 i = 0; i < users.length; i++) {
      _users[i] = usersMapping[users[i]];
    }

    return _users;
  }

  function addUser(
    address _addr,
    string memory _name,
    string memory _aadharNumber
  ) public {
    require(isUserExist(_addr), 'User already exist');

    User memory _user = User(_addr, _name, _aadharNumber);
    usersMapping[_addr] = _user;
    users.push(_addr);
  }
}