//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

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
        mapping(address => bool) voters;
    }

    event TickerUpdated(uint256 up, uint256 down, address voter, string ticker);

    mapping(string => Ticker) private tickers;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier tickerExists(string memory _ticker) {
        require(tickers[_ticker].exists, "Ticker does not exist");
        _;
    }

    function addTicker(string memory _ticker) public onlyOwner {
        Ticker storage newTicker = tickers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote)
        public
        tickerExists(_ticker)
    {
        require(
            !(tickers[_ticker].voters[msg.sender]),
            "Already voted for this coin"
        );

        Ticker storage t = tickers[_ticker];

        t.voters[msg.sender] = true;
        if (_vote) {
            t.up++;
        } else {
            t.down++;
        }

        emit TickerUpdated(t.up, t.down, msg.sender, _ticker);
    }

    function getVotes(string memory _ticker)
        public
        view
        tickerExists(_ticker)
        returns (uint256 up, uint256 down)
    {
        Ticker storage t = tickers[_ticker];
        return (t.up, t.down);
    }
}