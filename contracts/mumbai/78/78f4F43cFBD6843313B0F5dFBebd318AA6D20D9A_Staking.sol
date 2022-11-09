//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Staking {
  
  address public owner;

  struct Position {
    uint positionId;
    address walletAddress;
    uint createTime;
    uint unlockTime;
    uint percentInterest;
    uint tokenStaked;
    uint tokenInterest;
    bool open;
  }

  Position position;

  uint public currentPositionId;    // This will increment after a new position is created
  mapping(uint => Position) public positions;   // Every newly created positions added in this mapping
  mapping(address => uint[]) public positionIdByAddress;    // This gives user abilities to querry all the position Id by their addresses
  mapping(uint => uint) public tiers;   // This takes the number of days and returns the interest rate
  uint[] public lockPeriods;    // This gives the information how many days the token will lock(30 Day's etc...)

  constructor() payable {
    owner = msg.sender;
    currentPositionId = 0;
    tiers[30] = 700;    // 7% APY
    tiers[90] = 1000;   // 10% APY
    tiers[180] = 1200;    // 12% APY
    lockPeriods.push(30);
    lockPeriods.push(90);
    lockPeriods.push(180);
  }

  function stakeTokens(uint numHours) external payable {
    
    require(tiers[numHours] > 0, "Mapping not found");

    positions[currentPositionId] = Position(
      currentPositionId,    // positionId
      msg.sender,   // walletAddress
      block.timestamp,    // createTime
      block.timestamp + (numHours * 1 days),   // unlockTime
      tiers[numHours],    // percentInterest
      msg.value,    // tokenStake
      calculateInterest(tiers[numHours], msg.value),    // tokenInterest
      true    // Open
    );

    positionIdByAddress[msg.sender].push(currentPositionId);
    currentPositionId++;

  }

  function calculateInterest(uint basisPoints, uint tokenAmount) private pure returns(uint) {
    return basisPoints * (tokenAmount / 10000);
  }

  function modifyLockPeriods(uint numHours, uint basisPoints) external {
    require(owner == msg.sender, "Only owner have an access to modify staking period");
    tiers[numHours] = basisPoints;
    lockPeriods.push(numHours);
  }

  function getLockPeriods() external view returns(uint[] memory) {
    return lockPeriods;
  }

  function getInterestRate(uint numHours) external view returns(uint) {
    return tiers[numHours];
  }

  function getPositionById(uint positionId) external view returns (Position memory) {
    return positions[positionId];
  }

  function getPositionIdsForAddress(address walletAddress) external view returns(uint[] memory) {
    return positionIdByAddress[walletAddress];
  }

  function changeUnlockTime(uint positionId, uint newUnlockTime) external {
    require(owner == msg.sender, "Only owner can modify the unlock time");
    positions[positionId].unlockTime = newUnlockTime;
  }

  function closePosition(uint positionId) external {
    require(positions[positionId].walletAddress == msg.sender, "Only position creator may close the position");
    require(positions[positionId].open == true, "Position is closed");
    positions[positionId].open = false;
    if(block.timestamp > positions[positionId].unlockTime) {
      uint amount = positions[positionId].tokenStaked + positions[positionId].tokenInterest;
      payable(msg.sender).transfer(amount);
    } else {
      payable(msg.sender).transfer(positions[positionId].tokenStaked);
    }
  }
}