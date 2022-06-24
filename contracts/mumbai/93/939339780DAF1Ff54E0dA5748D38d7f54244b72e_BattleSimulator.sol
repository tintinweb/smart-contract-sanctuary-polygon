// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BattleSimulator
{
    uint256 public constant MAX_TURN_COUNT = 10;
    bool public isBattleSimulator = true;
   function getBattleResult(uint256 randomN, uint8 bodyGene1, uint8 bodyGene2, uint256[5] memory monsterStats1,uint256[5] memory monsterStats2, uint8 counterGene) external pure returns(uint8)
    {
        uint256 accuracyNumber = randomN;
      uint8 result = 0;//0:draw, 1: user win, 2: target win
      for(uint8 i=0;i<MAX_TURN_COUNT;i++)
      {
        (int monsterHP,int targetHP, uint256 newRandomN) = calculateDamage(bodyGene1, bodyGene2, monsterStats1, monsterStats2, accuracyNumber, counterGene);
        accuracyNumber = newRandomN;
        if(monsterStats2[3] > monsterStats1[3])//check speed
        {
            
            if(monsterHP <= 0)
            {
                monsterStats1[1] = 0;
                result = 2;
                break;
            }
            else
            {
                monsterStats1[1] = uint256(monsterHP);
            }
            
            if(targetHP <= 0)
            {
                monsterStats2[1] = 0;
                result = 1;
                break;
            }
            else
            {
                monsterStats2[1] = uint256(targetHP);
            }
            
        }
        else
        {
            
            if(targetHP <= 0)
            {
                monsterStats2[1] = 0;
                result = 1;
                break;
            }
            else
            {
                monsterStats2[1] = uint256(targetHP);
            }

            if(monsterHP <= 0)
            {
                monsterStats2[1] = 0;
                result = 2;
                break;
            }
            else
            {
                monsterStats2[1] = uint256(targetHP);
            }
        }
      
      }
      return result;
    }

    
  function calculateDamage(uint8 bodyGene1, uint8 bodyGene2, uint256[5] memory stats1, uint256[5] memory stats2, uint256 n, uint8 counterGene) private pure returns(int hp1, int hp2, uint256 newRandomN)
  {
    uint256 rand = n%100;
    if(rand <= stats1[4])
      hp2 =  int(stats2[1]) - (int(stats1[0]) - int(stats2[2]));
    if(counterGene == bodyGene1)
      hp2 -= int(stats2[2])/2;

    n = (n - rand)/100;
    rand = n%100;
    if(rand <= stats2[4])
      hp1 =  int(stats1[1]) - (int(stats2[0]) - int(stats1[2]));
    if(counterGene == bodyGene2)
      hp1 -= int(stats1[2])/2;

    newRandomN = (n - rand)/100;
  }
}