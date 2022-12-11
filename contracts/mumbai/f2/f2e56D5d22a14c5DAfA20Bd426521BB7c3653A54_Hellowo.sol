// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Hellowo {
  uint256 users;

  function setUser(uint256 _users) public {
    users = _users;
  }

  function getUser() public view returns (uint256) {
    return users;
  }
}