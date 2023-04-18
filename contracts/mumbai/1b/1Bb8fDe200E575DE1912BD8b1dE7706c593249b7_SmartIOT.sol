/**
 *Submitted for verification at polygonscan.com on 2023-04-17
*/

// SPDX-License-Identifier: FREE
pragma solidity ^0.8.0;

contract SmartIOT {

    struct Repairment {
        string name;
        uint256 time;
        uint256 price;
        bool paid;
    }

    address public owner;
    uint public repairCounter;

    mapping(uint => Repairment) public repairsInfo;

    constructor() {
        owner = msg.sender;
    }

     modifier onlyOwner() {
     require(msg.sender == owner);
      _;
    }


   function calculate(Repairment[] memory repairOffers) public onlyOwner {
    require(repairOffers.length > 0, "No repair offers provided");

    repairCounter += 1; 

    uint256 totalTime = 0;
    uint256 totalCost = 0;
    uint256 bestOfferIndex = 0;
    uint256 bestTimePriceRatio = 0;

    for (uint i = 0; i < repairOffers.length; i++) {
        Repairment memory repairOffer = repairOffers[i];
        totalTime += repairOffer.time;
        totalCost += repairOffer.price;
        repairOffer.paid = false;

        // Calculate the time/price ratio of the offer
        uint256 timePriceRatio = repairOffer.time / repairOffer.price;

        // Check if this is the best offer so far based on time/price ratio
        if (timePriceRatio > bestTimePriceRatio) {
            bestTimePriceRatio = timePriceRatio;
            bestOfferIndex = i;
        }
    }
    // Select the best offer based on time/price ratio
    Repairment memory bestOffer = repairOffers[bestOfferIndex];
    repairsInfo[repairCounter] = bestOffer;
  }

  function pay(uint256 counter) public onlyOwner {
       repairsInfo[counter].paid = true;
  }

    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner; 
    }

  }