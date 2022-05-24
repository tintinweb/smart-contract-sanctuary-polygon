//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;


contract MarketSentiment {
    address public owner;
    string[] public tickersArray;

    constructor() {
        owner=msg.sender;
    }

    struct ticker{
         bool exists;
         uint up;
         uint down;
         mapping(address=>bool) voters;
    }

    event tickerEvent(string ticker,uint up,uint down, address voter);

    mapping(string => ticker) private Tickers;

    function addTokens(string memory _ticker) public {
        require(msg.sender==owner,"you do not have the authority to create the token");
        require(Tickers[_ticker].exists==false,"Token already exists");
        ticker storage newTicker=Tickers[_ticker]; 
        newTicker.exists=true;
        tickersArray.push(_ticker);
    }

    function vote(string memory _ticker,bool _vote) public {
        require(Tickers[_ticker].exists,"Token does not exists");
        require(Tickers[_ticker].voters[msg.sender]==false,"you have already vote for the token.");


        ticker storage t=Tickers[_ticker];
        t.voters[msg.sender]=true;

        if(_vote){
            t.up++;
        }else{
            t.down++;
        }

        emit tickerEvent(_ticker,t.up,t.down,msg.sender);
    }

    function getVotes(string memory _ticker) public view returns(uint up,uint down){
        require(Tickers[_ticker].exists,"Token does not exists");
        ticker storage t=Tickers[_ticker];
        return(t.up,t.down);
    }
}