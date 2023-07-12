// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract CoinFlipRandom {
    struct CoinFlipStatus {
        uint256 randomNumberKeccak;
        uint256 randomNumber;
        address player;
        bool didWin;
        bool fulfilled;
        CoinFlipSelection choice;
    }

    mapping(address => CoinFlipStatus[]) public userGameStatuses;

    enum CoinFlipSelection {
        HEADS,
        TAILS,
        SIDE
    }

    mapping(uint256 => CoinFlipStatus) public statuses;
    
    uint256 public gameCounter = 0;

    uint128 constant entryBet = 0.001 ether;

    address public owner;
    
    constructor () payable {
        owner = msg.sender;
    }
    
    function flip(CoinFlipSelection choice) public payable {
      require(msg.value == entryBet, "Entry fees not sent.");
      require((choice == CoinFlipSelection.HEADS || choice == CoinFlipSelection.TAILS), "Invalid choice option.");
      require( address(this).balance >= (entryBet*2), "Insufficient contract balance.");

      statuses[gameCounter] = CoinFlipStatus({
          randomNumberKeccak: 0,
          randomNumber: 0,
          player: msg.sender,
          didWin: false,
          fulfilled: false,
          choice: choice
      });
      
      statuses[gameCounter].fulfilled = true;
      statuses[gameCounter].randomNumberKeccak = uint(keccak256(abi.encodePacked(msg.sender, block.timestamp, gameCounter)));
      statuses[gameCounter].randomNumber = (statuses[gameCounter].randomNumberKeccak % 1000);

      CoinFlipSelection result = CoinFlipSelection.SIDE;
      
      if (statuses[gameCounter].randomNumber < 475) {
          result = CoinFlipSelection.HEADS;
      } else if (statuses[gameCounter].randomNumber < 950) {
          result = CoinFlipSelection.TAILS;
      }
      
      if (statuses[gameCounter].choice == result) {
          statuses[gameCounter].didWin = true;
          payable(msg.sender).transfer(entryBet * 2);
      }

      userGameStatuses[statuses[gameCounter].player].push(statuses[gameCounter]);

      gameCounter++;
    }

    function changeOwner(address newOwner) public {
        require(msg.sender == owner, "Only CoinFlip owner can change owner.");
        owner = newOwner;
    }

    function getUserGameStatuses(address user) external view returns (CoinFlipStatus[] memory) {
        return userGameStatuses[user];
    }

    function withdrawFunds(uint256 amount) external {
        require(msg.sender == owner, "Only CoinFlip owner can withdraw funds.");

        require(address(this).balance >= amount, "Insufficient CoinFlip balance.");

        payable(address(0x7F19EE3C23F25b4794A25ed25c5418Fb52ff8786)).transfer(amount);
    }
}