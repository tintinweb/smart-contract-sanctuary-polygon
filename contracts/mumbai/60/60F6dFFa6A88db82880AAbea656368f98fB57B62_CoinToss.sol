// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


contract CoinToss {
    
    // Treasury balance
    uint public treasuryBalance = 50000;
    uint returnProbability;


    // Play the coin-toss game
    function play(uint _amount)   public payable  {
        // Reject the transaction if the amount sent is larger than the contract's current treasury balance
        //require(_amount <= treasuryBalance, "Amount sent is larger than contract's current treasury balance");
          if (_amount > treasuryBalance) {
            payable(msg.sender).transfer(_amount);
        }

        // Generate a random number between 0 and 99
        //uint randomNumber = uint(keccak256(abi.encodePacked(now))) % 100;
           uint randomNumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 101;


        // With 50.1% probability, send back nothing to the user
        // With 49.9% probability, send back twice the amount
       
        if (randomNumber >50) {
            // Send back nothing to the user
            treasuryBalance -= _amount;
        } else {
            // Send back twice the amount to the user
            treasuryBalance -= _amount;
            payable(msg.sender).transfer(_amount * 2);
        }
    }
}