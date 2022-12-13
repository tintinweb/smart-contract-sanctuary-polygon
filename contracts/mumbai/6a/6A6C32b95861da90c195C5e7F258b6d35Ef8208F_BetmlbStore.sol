// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract BetmlbStore {
  uint256 public decimals = 2;

  struct Betstore{
    string betdate;
    string game;
    string teams;
    string marcket;
    string place;
    uint256 stake;
    uint256 odds;
    uint256 profitloss;
    string status;
    string site;
    uint256 createdAt;
  }

  mapping (uint256 => Betstore) public betDic;

  function createBetData(uint256 _betId, string memory _betDate, string memory _game, string memory _teams, string memory _marcket, string memory _place, uint256 _stake, uint256 _odds, uint256 _profitloss, string memory _status, string memory _site) public {
    Betstore memory betdata = Betstore(_betDate, _game, _teams, _marcket, _place, _stake, _odds, _profitloss, _status, _site, block.timestamp);
    betDic[_betId] = betdata;
  }

  function changeBetstatus(uint256 _betId, string memory _status) public {
    betDic[_betId].status = _status;
  }
}