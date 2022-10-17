// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract moodDiary {
  string mood;
  string thought;

  // create a function that writes a mood to the smart contract
  function setMood(string memory _mood) public {
    mood = _mood;
  }

  //create a function the reads the mood from the smart contract
  function getMood() public view returns (string memory) {
    return mood;
  }

  // create a function that writes a thought to the smart contract
  function setThought(string memory _thought) public {
    thought = _thought;
  }

  //create a function the reads the thought from the smart contract
  function getThought() public view returns (string memory) {
    return thought;
  }
}