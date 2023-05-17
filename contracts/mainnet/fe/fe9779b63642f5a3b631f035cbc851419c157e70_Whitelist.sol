/**
 *Submitted for verification at polygonscan.com on 2023-05-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Whitelist {
  string public contractName = "Senatoons whitelist v1.0";
  string public url = "https://www.senatoons.com";

  // person who deploys contract is the owner
  address payable public owner;

  // pauses whe whitelisting process
  bool public isPaused;

  // total whitelisted addresses
  uint public totalUsers;

  // create an array of Users
  mapping(uint => User) public whitelist;
    
  // each user has a username and score
  struct User {
    address user;
    uint256 score;
    string name;
  }

  event EnterWhitelist(address indexed account, uint256 score);
  event PauseWhitelist();
  event ResumeWhitelist();
    
  constructor()  {
    owner = payable(msg.sender);
    isPaused = false;
    totalUsers = 0;
  }

  // allows owner only
  modifier onlyOwner(){
    require(owner == msg.sender, "Sender not authorized");
    _;
  }

  function pauseWhitelist(bool pause) onlyOwner public {
    isPaused = pause;
    if (pause) {
      emit PauseWhitelist();
    } else {
      emit ResumeWhitelist();
    }
  }

  function withdraw() onlyOwner public {
    owner.transfer(address(this).balance);
  }

  function getBalance() public view returns(uint256) {
    return address(this).balance;
  }
  
  function enterWhitelist(string memory name) external payable {
    require(isPaused == false, "Whitelist is currently paused");
    require(msg.value > 0, "Insufficient value provided");
    require(bytes(name).length > 0 && bytes(name).length < 16, "Invalid name size (requires 1-16 bytes long)");

    // Increase user's score based on the amount of ETH sent
    uint256 scoreIncrease = msg.value;

    // check if the user has already enter the whitelist
    bool hasEntered = false;
    if (totalUsers == 0) {
      // Add a new user to the leaderboard
      whitelist[totalUsers] = User(msg.sender, scoreIncrease, name);
      totalUsers++;
    } else {
      for (uint i=0; i<totalUsers; i++) { 
        if (whitelist[i].user == msg.sender) {
          hasEntered = true;
          // update the user's score
          whitelist[i].score += msg.value;
          whitelist[i].name = name;
          break;
        }
      }
      if (!hasEntered) {
        // Add a new user to the leaderboard
        whitelist[totalUsers] = User(msg.sender, scoreIncrease, name);
        totalUsers++;
      }
    }
    
    // Sort the leaderboard
    sortWhitelist();

    emit EnterWhitelist(msg.sender, scoreIncrease);
  }

  function sortWhitelist() internal {
    // Create a temporary array to hold the sorted users
    User[] memory sortedUsers = new User[](totalUsers);
    
    // Copy all users from the mapping to the temporary array
    for (uint i = 0; i < totalUsers; i++) {
      sortedUsers[i] = whitelist[i];
    }
    
    // Sort the temporary array in descending order based on score
    for (uint i = 0; i < totalUsers - 1; i++) {
      for (uint j = 0; j < totalUsers - i - 1; j++) {
        if (sortedUsers[j].score < sortedUsers[j + 1].score) {
          User memory temp = sortedUsers[j];
          sortedUsers[j] = sortedUsers[j + 1];
          sortedUsers[j + 1] = temp;
        }
      }
    }
    
    // Replace the whitelist mapping with the sorted array
    for (uint i = 0; i < totalUsers; i++) {
      whitelist[i] = sortedUsers[i];
    }
  }
  
}