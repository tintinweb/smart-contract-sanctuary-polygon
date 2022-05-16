// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.10;

contract Account {  

  // mapping of player wallet => name of player (in bytes32, may show up as hexidecimal in javascript)
  mapping(address => bytes32) public name;

  // error for when the user already has a name
  error NameAlreadyExists();

  // event for tracking addresses to names
  event Registered(address indexed user, bytes32 indexed name);

  /////////////////////////////////////////////////////////////////////////////////
  //                                USER INTERFACE                               //
  /////////////////////////////////////////////////////////////////////////////////


  // assign a bytes32 username to the players wallet. Can only be called once. Names are immutable.
  function register(bytes32 name_) external {
    
    // if the player already has a name, throw an error
    if ( name[msg.sender] != bytes32(0) ) { revert NameAlreadyExists(); }

    // register the player's name in the name map
    name[msg.sender] = name_;

    // name has been registered
    emit Registered(msg.sender, name_);
  }
}