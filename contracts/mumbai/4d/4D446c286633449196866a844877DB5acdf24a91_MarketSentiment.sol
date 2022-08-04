// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

error MarketSentiment__NotOwner();
error MarketSentiment__EntryNotPresent();
error MarketSentiment__AlreadyVoted();

contract MarketSentiment {
    address public immutable owner;
    string[] public tickersArray;

    struct Ticker {
        bool exists;
        uint256 up;
        uint256 down;
        mapping(address => bool) Voters;
    }

    event tickerUpdated(uint256 up, uint256 down, address voter, string ticker);

    mapping(string => Ticker) private Tickers;

    constructor() {
        owner = msg.sender;
    }

    function addTicker(string memory _ticker) public {
        if (msg.sender != owner) {
            revert MarketSentiment__NotOwner();
        }
        Ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote) public {
        if (!Tickers[_ticker].exists) {
            revert MarketSentiment__EntryNotPresent();
        }
        if (Tickers[_ticker].Voters[msg.sender]) {
            revert MarketSentiment__AlreadyVoted();
        }
        Ticker storage t = Tickers[_ticker];
        t.Voters[msg.sender] = true;
        if (_vote) {
            t.up++;
        } else {
            t.down++;
        }
        emit tickerUpdated(t.up, t.down, msg.sender, _ticker);
    }

    function getVotes(string memory _ticker)
        public
        view
        returns (uint256 up, uint256 down)
    {
        if (!Tickers[_ticker].exists) {
            revert MarketSentiment__EntryNotPresent();
        }
        Ticker storage t = Tickers[_ticker];
        return (t.up, t.down);
    }
}