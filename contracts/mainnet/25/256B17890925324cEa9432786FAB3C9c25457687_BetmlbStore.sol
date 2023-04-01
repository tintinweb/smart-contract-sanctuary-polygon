// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract BetmlbStore {

  uint256 public betIndex;

  struct Betstore{
    string betdate;
    string game;
    string teams;
    string market;
    string place;
    string stake;
    string odds;
    string profitloss;
    string status;
    string site;
    uint256 createdAt;
  }

  struct BetRtio{
    uint256 betcount;
    uint256 wincount;
    uint256 losecount;
  }

  mapping (uint256 => Betstore) public betDic;
  BetRtio public betRatio;

  constructor(){
      betIndex = 0;
      betRatio.betcount = 0;
      betRatio.wincount = 0;
      betRatio.losecount = 0;
  }
  
  function createBetData(string memory _betDate, string memory _game, string memory _teams, string memory _market, string memory _place, string memory _stake, string memory _odds, string memory _profitloss, string memory _status, string memory _site) public {
    Betstore memory betdata = Betstore(_betDate, _game, _teams, _market, _place, _stake, _odds, _profitloss, _status, _site, block.timestamp);
    betIndex++;
    betDic[betIndex] = betdata;
    betRatio.betcount++;
  }

  function changeBetstatus(uint256 _betId, string memory _status) public {
    if(keccak256(bytes(_status)) == keccak256(bytes("W")))
    {
      if(keccak256(bytes(betDic[_betId].status)) == keccak256(bytes("L")))
        betRatio.losecount--;
      betRatio.wincount++;
    }
    else if(keccak256(bytes(_status)) == keccak256(bytes("L")))
    {
      if(keccak256(bytes(betDic[_betId].status)) == keccak256(bytes("W")))
        betRatio.wincount--;
      betRatio.losecount++;
    }
    betDic[_betId].status = _status;
  }  
}