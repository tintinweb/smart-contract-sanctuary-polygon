// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract  MarketSentiment{
    address public owner;
    string[] public tickersArray;

    constructor(){
        owner = msg.sender;
    }

    struct ticker{
        bool exist;
        uint256 up;
        uint256 down;
        mapping(address => bool) voters;
    }
    event tickerupdate(
        uint256 up,
        uint256 down,
        address voter,
        string ticker

    );
    mapping(string => ticker) public Tickers;

    function addTicker(string memory _ticker) public {
        require(msg.sender == owner, "You are not the owner");
        ticker storage newTicker = Tickers[_ticker];
        newTicker.exist = true;
        tickersArray.push(_ticker);
    }

    function vote(string memory _ticker,bool _vote) public {
        require(Tickers[_ticker].exist, "Ticker does not exist");
        require(!Tickers[_ticker].voters[msg.sender], "You have already voted");

        ticker storage t = Tickers[_ticker];
        t.voters[msg.sender] = true;

        if(_vote){
            t.up++;
        }else{
            t.down++;
        }

        emit tickerupdate(t.up,t.down,msg.sender,_ticker);
    }

    function getVotes( string memory _ticker) public view returns(uint256 up,uint256 down){
        require(Tickers[_ticker].exist, "Ticker does not exist");
        ticker storage t = Tickers[_ticker];
        return (t.up,t.down);
    }
}