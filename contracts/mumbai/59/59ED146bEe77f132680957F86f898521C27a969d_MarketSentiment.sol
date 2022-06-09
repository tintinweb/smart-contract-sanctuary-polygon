// SPDX-License-Identifier: MIT

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
        mapping(address => bool) userHasVoted;
    }

    mapping(string => Ticker) tickers;

    event TickerUpdated(uint256 up, uint256 down, address voter, string ticker);

    modifier tickerExists(string memory _ticker) {
        require(tickers[_ticker].exists, "The ticker doesn't exist");
        _;
    }

    function addTicker(string memory _ticker) public {
        require(owner == msg.sender, "Only the owner can do this");

        Ticker storage newTicker = tickers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote)
        public
        tickerExists(_ticker)
    {
        require(
            !tickers[_ticker].userHasVoted[msg.sender],
            "User already voted for this ticker"
        );

        Ticker storage ticker = tickers[_ticker];

        ticker.userHasVoted[msg.sender] = true;

        if (_vote) {
            ticker.up++;
        } else {
            ticker.up--;
        }

        emit TickerUpdated(ticker.up, ticker.down, msg.sender, _ticker);
    }

    function getVotes(string memory _ticker)
        public
        view
        tickerExists(_ticker)
        returns (uint256 up, uint256 down)
    {
        Ticker storage ticker = tickers[_ticker];
        return (ticker.up, ticker.down);
    }
}