// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Dwitter {
  struct User {
    address wallet;
    string name;
    string username;
    string avatar;
    string bio;
  }

  mapping(address => string) public usernames;

  mapping(string => User) public users;

  function signUp(
    string memory _name,
    string memory _username,
    string memory _bio,
    string memory _avatar
  ) public {
    require(bytes(usernames[msg.sender]).length == 0, 'User Already Exists');
    require(users[_username].wallet == address(0), 'Username is taken, please try another one!');

    users[_username] = User({wallet: msg.sender, name: _name, username: _username, avatar: _avatar, bio: _bio});

    usernames[msg.sender] = _username;
  }

  function getUser(address _wallet) public view returns (User memory) {
    return users[usernames[_wallet]];
  }
}