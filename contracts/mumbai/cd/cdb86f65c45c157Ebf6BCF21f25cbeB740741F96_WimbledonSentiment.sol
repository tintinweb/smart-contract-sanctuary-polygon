// SPX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract WimbledonSentiment {
  address public owner; 
  string[] public tickersArray;

/// deployer becomes owner
constructor() {
  owner = msg.sender;
}

/// only one chance to vote 
struct ticker {
  bool exists;
  uint256 up; 
  uint256 down; 
  mapping(address => bool) Voters; 
}

/// for moralis to listen to the smartcontract
event tickerupdated(
  uint256 up, 
  uint256 down, 
  address voter,
  string ticker
);

/// takes string and maps it to ticker struct
mapping(string => ticker) private Tickers;

/// add tickers only callable by owner of contract
function addTicker(string memory _ticker) public {
  require(msg.sender == owner, "Only owner can create ticker");
  ticker storage newTicker = Tickers[_ticker];
  newTicker.exists = true; 
  tickersArray.push(_ticker);
}

/// check: voting state + set: voting state & vote + call emit tickerupdated
function vote(string memory _ticker, bool _vote) public {
  require(Tickers[_ticker].exists, "Can't vote for this player");
  require(!Tickers[_ticker].Voters[msg.sender], "You've already voted for this plater");
  ticker storage t = Tickers[_ticker];
  t.Voters[msg.sender] = true; 
  if(_vote) {
    t.up++;
  } else {
    t.down++;
  }
  emit tickerupdated(t.up, t.down, msg.sender, _ticker);
}

/// allow public to get votes 
function getVotes(string memory _ticker) public view returns (
  uint256 up, 
  uint256 down
) {
  require(Tickers[_ticker].exists, "This ticker doesn't exist");
  ticker storage t = Tickers[_ticker];
  return(t.up, t.down);
}

}