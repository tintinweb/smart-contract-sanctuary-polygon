//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract MarketSentiment {
    address public owner;
    string[] public tickersArray;

    struct Ticker {
        bool exists;
        uint256 up;
        uint256 down;
        mapping(address => bool) Voters;
    }

    mapping(string => Ticker) private _tickers;

    event TickerUpdated(uint256 up, uint256 down, address voter, string ticker);

    constructor() {
        owner = msg.sender;
    }

    function addTicker(string memory _ticker) public {
        require(msg.sender == owner, "Only the owner can create tickers");
        Ticker storage newTicker = _tickers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote) public {
        require(_tickers[_ticker].exists, "Can't vote on this coin");
        require(
            !_tickers[_ticker].Voters[msg.sender],
            "You have already voted for this coin"
        );

        Ticker storage t = _tickers[_ticker];

        if (_vote) {
            t.up++;
        } else {
            t.down++;
        }

        t.Voters[msg.sender] = true;

        emit TickerUpdated(t.up, t.down, msg.sender, _ticker);
    }

    function getVotes(string memory _ticker)
        public
        view
        returns (uint256 up, uint256 down)
    {
        require(_tickers[_ticker].exists, "Can't get votes on this coin");
        Ticker storage t = _tickers[_ticker];
        return (t.up, t.down);
    }
}