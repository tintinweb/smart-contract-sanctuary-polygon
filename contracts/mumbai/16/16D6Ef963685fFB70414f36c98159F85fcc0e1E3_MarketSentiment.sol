//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

contract MarketSentiment {

    address public owner;
    string[] public tickerArray;

    constructor() {
        owner = msg.sender;
    }

    struct ticker {
        bool exists;
        uint256 up;
        uint256 down;
        mapping(address => bool) voters; 
    }
    event tickerUpdated (
        uint256 up,
        uint256 down,
        address voter,
        string ticker 
    );

    mapping(string => ticker) private Tickers;

    function addTicker( string memory _ticker) public {
        require(msg.sender == owner, "only ownerl can call");
        ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;
        tickerArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote) public {
        require(Tickers[_ticker].exists, "Cant vote this coin");
        require(!Tickers[_ticker].voters[msg.sender], "You have alredy voted this coin");

        ticker storage t = Tickers[_ticker];
        t.voters[msg.sender] = true;

        if(_vote){
            t.up++;
        } else {
            t.down++;
        }
        emit tickerUpdated(t.up, t.down, msg.sender, _ticker);
    }

    function getVotes(string memory _ticker) public view returns (uint256 up, uint256 down){
        require(Tickers[_ticker].exists, "No Such ticker defined");
        ticker storage t = Tickers[_ticker];
        return(t.up, t.down);
    }


}