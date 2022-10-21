/**
 *Submitted for verification at polygonscan.com on 2022-10-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract MarketSentiment {

    address public owner;
    string[] public tickersArray;

constructor() {
    owner = msg.sender;
}

     struct Ticker {
        bool exists;
        uint256 up;
        uint256 down;
        mapping(address => bool) Voters;
     }
          
          event TickerUpdated (
            uint256 up,
            uint256 down,
            address voter,
            string ticker
          );

 mapping(string => Ticker) private Tickers;

 function addTicker(string memory _ticker) public {
    require(msg.sender == owner, "only owner can create tickers");
    Ticker storage newTicker = Tickers[_ticker];
    newTicker.exists = true;
    tickersArray.push(_ticker);

 }
     function vote(string memory _ticker, bool _vote) public {
        require(Tickers[_ticker].exists, "You can't vote on this Coin");
        require(!Tickers[_ticker].Voters[msg.sender], "already voted for this coin");
     

       Ticker storage t = Tickers[_ticker];
       t.Voters[msg.sender] = true;

       if(_vote){
         t.up++;
       } else {
         t.down++;
       }
         emit TickerUpdated (t.up,t.down,msg.sender,_ticker);

}

function getVotes(string memory _ticker) public view returns (
   uint256 up,
   uint256 down
){
   require(Tickers[_ticker].exists, "No such ticker defined");
   Ticker storage t = Tickers[_ticker];
   return(t.up,t.down);
}

}