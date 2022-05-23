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

    event tickerUpdated(
        string ticker,
        uint256 up,
        uint256 down,
        address voter
    );

    mapping(string => Ticker) public tickers;

    function addTicker(string memory _ticker) public{
        require(msg.sender == owner, "Only owner can add tickers");
        require(!tickers[_ticker].exists, "Ticker already exists");
        Ticker storage newTicker = tickers[_ticker];
        newTicker.exists = true;
        newTicker.up = 0;
        newTicker.down = 0;
        tickersArray.push(_ticker);
    }

    function voteTicker(string memory _ticker, bool _vote) public{
        require(tickers[_ticker].exists, "Ticker does not exist");
        require(!tickers[_ticker].Voters[msg.sender], "You have already voted");
        Ticker storage t = tickers[_ticker];
        t.Voters[msg.sender] = true;
        if(_vote){
            t.up++;
        }else{
            t.down++;
        }
        emit tickerUpdated(_ticker, t.up, t.down, msg.sender);
    }

    function getVotesByTicker(string memory _ticker) public view returns(uint256 up,uint256 down){
        require(tickers[_ticker].exists, "Ticker does not exist");
        Ticker storage t = tickers[_ticker];
        return (t.up, t.down);
    }

}