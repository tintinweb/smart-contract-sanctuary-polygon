/**
 *Submitted for verification at polygonscan.com on 2023-02-11
*/

pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED"
contract UserRegistry {
  struct User {
    string username;
    string email;
    string nomeClub;
    string userType;
  }

  mapping (address => User) public users;

  function registerUser(
    string memory _username,
    string memory _email,
    string memory _nomeClub,
    string memory _userType
  ) public {
    User storage user = users[msg.sender];

    user.username = _username;
    user.email = _email;
    user.nomeClub = _nomeClub;
    user.userType = _userType;
  }
}