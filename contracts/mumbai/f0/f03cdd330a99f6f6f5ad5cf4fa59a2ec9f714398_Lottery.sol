/**
 *Submitted for verification at polygonscan.com on 2022-12-18
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Lottery {
  address payable public owner;


  uint public price = 20; // TEMP

  uint public playersCount = 0;
  address payable[] public players;
  mapping(address => bool) playerExists;
  mapping(address => uint) balances;
  
  address payable public winner = payable(0);

  constructor(uint _price) {
    owner = payable(msg.sender);
    price = _price;
  }

  function getPrice() public view returns(uint _price) {
    return price;
  }

  function setPrice(uint _price) public {
    price = _price;
  }

  /**
    Players / participate
   */
  function getPlayers() public view returns(address payable[] memory _players) {
    return players;
  }

  function getPlayersCount() public view returns(uint _playersCount) {
    return playersCount;
  }

  function participate() public payable {
    address payable playerAddress = payable(msg.sender);

    // Control that the user address is not already registered to the Lottery
    require(!playerExists[playerAddress], "Player already exists");

    // Pay the ticket
    require(msg.value == 0.1 ether, "Must be 1 Ether");
    balances[playerAddress] = 0.1 ether;

    // Add the address to the player list
    playersCount++;
    players.push(playerAddress);
    playerExists[playerAddress] = true;
  }
  
  function getPlayerBalance() public view returns(uint _balance) {
    return balances[msg.sender];
  }

  /**
    Lottery global
   */

   function getLotteryBalance() public view returns (uint) {
    return address(this).balance;
   }

   function chooseWinner() public {
      // Only the contract owner can choose a winner
      require(msg.sender == owner, "Only the owner can choose a winner");

      // Require that there are at least 2 participants
      require(players.length >= 2, "Not enough participants, 2 minimum");


      require(winner == payable(0), "A winner already exists");

      require(address(this).balance > 0 ether, "No more money to distribute");


      // Choose a random participant as the winner
      uint randomIndex = random();
      address payable _winner = players[randomIndex];
      winner = _winner;

      // Send all the contract balance to the winner
      _winner.transfer(address(this).balance);
   }


   function getWinner() public view returns (address payable){
    return winner;
   }
    
    // Function to get a random number between 0 and the number of participants
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, players))) % players.length;
    }

}


/**

const instance = await Lottery.deployed();
(await instance.getPrice()).toString()



 */