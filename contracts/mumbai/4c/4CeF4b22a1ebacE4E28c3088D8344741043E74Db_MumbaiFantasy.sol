//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

contract MumbaiFantasy {

  mapping(address => string) public teamOwners;
  string[] public playersThatHaveBought;
  string public topPlayer;
  uint public validatedWinnerCount = 0;
  address public owner;

  constructor() {
      // https://docs.chain.link/docs/multi-variable-responses/#response-types
      // https://docs.polygon.technology/docs/develop/oracles/chainlink/
      // https://docs.chain.link/docs/api-array-response/
      owner = msg.sender;
    }


  function buyIn(string memory _teamName) external payable {
    require(msg.value == 0.1 ether, "Buy in is 50 MATIC");
    playersThatHaveBought.push(_teamName);
    teamOwners[msg.sender] = _teamName;
  }


  function returnBoughtInPlayers() public view returns(string[] memory) {
    // return array of players (string format) that have bought in
    return playersThatHaveBought;
  }

  function verifyWinner() public {
    // Must be a person who's bought in
    // If they are, requires 3 people to validate the winner is correct
    require(bytes(teamOwners[msg.sender]).length > 0);
    validatedWinnerCount += 1;
  }

  function retrieveWinnings() public {
    require(keccak256(abi.encodePacked(teamOwners[msg.sender])) == keccak256(abi.encodePacked(topPlayer)));
    require(validatedWinnerCount >= 1);
    (bool sent, ) = (msg.sender).call{value: address(this).balance}("");
    require(sent, "Failed to send MATIC");
  }

  function addTopPlayer(string memory _topPlayer) external {
    topPlayer = _topPlayer;
  }

}