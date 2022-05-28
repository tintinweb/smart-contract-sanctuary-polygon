//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract MarketSentiment {
    address public owner;
    string[] public tickersArray;

    constructor(){
        owner = msg.sender;
        
    }

    struct Ticker{
        bool exists;
        uint256 up;
        uint256 down;
        mapping(address => bool) Voters;
    }

    event tickerUpdated (uint up, uint down, address voter, string ticker);
    mapping(string => Ticker) private Tickers;


    function addTicker(string memory tickerName) external returns(bool){
        require(msg.sender == owner, "You're not the owner");
        require (!Tickers[tickerName].exists,"Ticker exists");
        tickersArray.push(tickerName);
        Ticker storage newTicker = Tickers[tickerName];
        newTicker.exists = true;
        newTicker.up = 0;
        newTicker.down = 0;
        return true;
    }

    function addVote(string memory tickerName, bool vote) external {
        Ticker storage newTicker = Tickers[tickerName];
        
        require (Tickers[tickerName].exists,"Ticker does not exist");
        require (!newTicker.Voters[msg.sender],"You have already Voted");
        
        if(vote) {   newTicker.up++;  }
        else {   newTicker.down++;  }
        newTicker.Voters[msg.sender] = true;

        emit tickerUpdated(newTicker.up, newTicker.down, msg.sender, tickerName);
    }

    function getVotes(string memory tickerName) external view returns(uint256 up, uint256 down){
        require (Tickers[tickerName].exists,"Ticker does not exist");

        Ticker storage newTicker = Tickers[tickerName];
        return(newTicker.up, newTicker.down);
    }
    
}