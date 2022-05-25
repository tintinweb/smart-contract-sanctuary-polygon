//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

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

    event tickerUpdated(uint256 up, uint256 down, address voter,string ticker);

    mapping(string => ticker) private Tickers;

    function addTicker(string memory _ticker) public {
        require(msg.sender == owner, "Only the owner of the contract can create tickers");
        ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote) public {
        require(Tickers[_ticker].exists, "Cant on this coin");
        require(!Tickers[_ticker].Voters[msg.sender], "You have already voted for this coin");

        ticker storage tick = Tickers[_ticker];
        tick.Voters[msg.sender] = true;

        if(_vote) {
            tick.up ++;
        } else {
            tick.down ++;
        }

        emit tickerUpdated(tick.up, tick.down, msg.sender, _ticker);
    }

    function getVotes(string memory _ticker) public view returns(uint up, uint down) {
        require(Tickers[_ticker].exists, "No such ticker defined");
        ticker storage tick = Tickers[_ticker];
        return(tick.up, tick.down);
    }
        
}