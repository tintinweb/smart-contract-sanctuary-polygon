/**
 *Submitted for verification at polygonscan.com on 2023-07-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract MembersDATA {
  struct MemberProfile {
    uint256 index;
    uint256 timeEnrolled;
    address walletAddress;
    string name;
    string uid;
    string officialEmail;
    string phoneNumber;
    string whatsappNumber;
  }

  uint256 public counter;
  MemberProfile[] public allMembers;
  mapping(address => bool) private isEnrolled;
  mapping(address => bool) private isAdmin;

  constructor() {
    counter = 0;
    isAdmin[msg.sender] = true;
  }

  function makeAdmin(address newAdmin) public {
    require(isAdmin[msg.sender] == true, "Only Admins can invoke");
    isAdmin[newAdmin] = true;
  }

  modifier hasEnrolled(address _add) {
    require(!isEnrolled[_add], "This wallet has already been added");
    _;
  }

  function enrollMember(
    string calldata _name,
    string calldata _uid,
    string calldata _officialEmail,
    string calldata _phoneNumber,
    string calldata _whatsappNumber
  ) public hasEnrolled(msg.sender) {
    isEnrolled[msg.sender] = true;
    allMembers.push(
      MemberProfile(
        counter,
        block.timestamp,
        msg.sender,
        _name,
        _uid,
        _officialEmail,
        _phoneNumber,
        _whatsappNumber
      )
    );
    counter++;
  }

  function migrationMethod(
    uint256 index,
    uint256 timestamp,
    address walletAddress,
    string memory _name,
    string memory _uid,
    string memory _officialEmail,
    string memory _phoneNumber,
    string memory _whatsappNumber
  ) public {
    require(isAdmin[msg.sender] == true, "Only admins can access this method");
    isEnrolled[walletAddress] = true;
    allMembers.push(
      MemberProfile(
        index,
        timestamp,
        walletAddress,
        _name,
        _uid,
        _officialEmail,
        _phoneNumber,
        _whatsappNumber
      )
    );
    counter++;
  }

  function delegateEnrollMember(
    address _address,
    string calldata _name,
    string calldata _uid,
    string calldata _officialEmail,
    string calldata _phoneNumber,
    string calldata _whatsappNumber
  ) public hasEnrolled(_address) {
    require(isAdmin[msg.sender], "Only admins can invoke");
    isEnrolled[_address] = true;
    allMembers.push(
      MemberProfile(
        counter,
        block.timestamp,
        _address,
        _name,
        _uid,
        _officialEmail,
        _phoneNumber,
        _whatsappNumber
      )
    );
    counter++;
  }

  function getAllMembers() public view returns (MemberProfile[] memory) {
    return allMembers;
  }

  function deleteMember(uint256 _id) public {
    require(isAdmin[msg.sender], "Only admins can invoke");
    remove(_id);
  }

  function remove(uint _index) internal {
    require(_index < allMembers.length, "index out of bound");
    require(isAdmin[msg.sender], "Only admins can invoke");

    for (uint i = _index; i < allMembers.length - 1; i++) {
      allMembers[i] = allMembers[i + 1];
    }
    allMembers.pop();
  }
}