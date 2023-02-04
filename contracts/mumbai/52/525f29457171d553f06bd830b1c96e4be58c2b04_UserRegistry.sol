/**
 *Submitted for verification at polygonscan.com on 2023-02-03
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract UserRegistry {
  struct User {
    string firstName;
    string lastName;
    string email;
  }

  mapping (address => User) users;

  function registerUser(string memory _firstName, string memory _lastName, string memory _email) public {
    users[msg.sender].firstName = _firstName;
    users[msg.sender].lastName = _lastName;
    users[msg.sender].email = _email;
  }

  function getUser(address _userAddress) public view returns (string memory, string memory, string memory) {
    return (users[_userAddress].firstName, users[_userAddress].lastName, users[_userAddress].email);
  }
}