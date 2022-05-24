//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract MarketSentiment {
  address public owner;
  string[] public tickersArray;

  constructor() {
    owner = msg.sender;
  }

  struct ticker {
    bool exists;
    uint256 up;
    uint256 down;
    mapping(address => bool) Voters;
  }

  event tickerUpdated (
    uint256 up,
    uint256 down,
    address voter,
    string ticker
  );

  mapping(string => ticker) private Tickers;

  function addTicker(string memory _ticker) public {
       require(msg.sender == owner, "Only the owner can create tickers Bruh");
       ticker storage newTicker = Tickers[_ticker];
       newTicker.exists = true;
       tickersArray.push(_ticker);
}

function vote(string memory _ticker, bool _vote) public {
  require(Tickers[_ticker].exists, "That ticker Dont exist Bruh");
  require(!Tickers[_ticker].Voters[msg.sender], "This address already voted for this coin bruh");
  
  ticker storage t = Tickers[_ticker];
  t.Voters[msg.sender] = true;
  if(_vote){
    t.up++;
  } else {
    t.down++;
  }

  emit tickerUpdated  (t.up,t.down,msg.sender,_ticker);
}

function getVotes(string memory _ticker) public view returns (uint256 up, uint256 down) {
  require(Tickers[_ticker].exists, "That ticker aint on here");
  ticker storage t = Tickers[_ticker];
  return(t.up,t.down);
}


}