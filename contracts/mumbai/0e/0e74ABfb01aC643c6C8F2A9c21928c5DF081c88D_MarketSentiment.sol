// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract MarketSentiment {

 address public owner;
 string[] public tickersArray;

constructor() {
    owner = msg.sender;

}

struct ticker {
bool exist;
uint up;
uint down;
mapping(address => bool) Voters;
}

event ticketrupdated (
    uint up,
    uint down,
    address voter,
    string ticker
);

mapping(string => ticker) private Tickers;

//We create a function sending a string associated with the struct

function addTicker(string memory _ticker) public {
    require(msg.sender == owner, "Only the owner can create Tickers"); 
    ticker storage newTicker = Tickers[_ticker];
    newTicker.exist = true;
    tickersArray.push(_ticker);
}

//We create a function which allow us to vote, with requires for voters can't vote more than a time the same coin.

function vote(string memory _ticker, bool _vote) public {
    require(Tickers[_ticker].exist, "Voting on this coin is not available");
    require(!Tickers[_ticker].Voters[msg.sender], "You have already voted for this coin");
    
    ticker storage t = Tickers[_ticker];
    t.Voters[msg.sender] = true;

    if(_vote){
        t.up++;
    } else {
        t.down++;
    }

//Declaring new event once an address vote.
    emit ticketrupdated (t.up,t.down,msg.sender,_ticker);
}

//Function that give to us the results of the votes on a ticker

function getVotes(string memory _ticker) public view returns (uint up, uint down) {

require(Tickers[_ticker].exist, "That ticker doesn't exist");
ticker storage t = Tickers[_ticker];
return(t.up,t.down);
}


}