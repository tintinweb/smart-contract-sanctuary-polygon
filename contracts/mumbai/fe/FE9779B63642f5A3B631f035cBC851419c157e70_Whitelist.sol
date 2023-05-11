/**
 *Submitted for verification at polygonscan.com on 2023-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


contract Whitelist {

  // person who deploys contract is the owner
  address owner;

  // lists top 10 users
  uint whitelistLength = 1000;

  // create an array of Users
  mapping (uint => User) public whitelist;
    
  // each user has a username and score
  struct User {
    address user;
    uint256 score;
  }
    
  constructor()  {
    owner = msg.sender;
  }

  // allows owner only
  modifier onlyOwner(){
    require(owner == msg.sender, "Sender not authorized");
    _;
  }

  function enterWhitelist() public payable returns (bool success) {

    // check if the user already has a whitelist entry
    uint256 oldScore = 0;
    for (uint i=0; i<whitelistLength; i++) {
        if (whitelist[i].user == msg.sender) {
            oldScore = whitelist[i].score;
            break;
        }
    }
    
    uint256 newScore = msg.value + oldScore;
    
    // if the score is too low, don't update
    if (whitelist[whitelistLength-1].score >= newScore) return false;

    // loop through the whitelist
    for (uint i=0; i<whitelistLength; i++) {
      // find where to insert the new score
      if (whitelist[i].score < newScore) {

        // shift whitelist
        User memory currentUser = whitelist[i];
        for (uint j=i+1; j<whitelistLength+1; j++) {
          User memory nextUser = whitelist[j];
          whitelist[j] = currentUser;
          currentUser = nextUser;
        }

        // insert
        whitelist[i] = User({
          user: msg.sender,
          score: newScore
        });

        // delete last from list
        delete whitelist[whitelistLength];

        return true;
      }
    }
  }
}