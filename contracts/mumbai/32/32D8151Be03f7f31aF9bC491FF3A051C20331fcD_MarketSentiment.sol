// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

contract MarketSentiment {
    address public owner;
    string[] public tickersArray;

    struct ticker {
        bool exists;
        uint256 up;
        uint256 down;
        mapping(address => bool) Voters;
    }

    event TickerUpdated(uint256 up, uint256 down, address voter, string ticker);

    mapping(string => ticker) private Tickers;

    constructor() {
        owner = msg.sender;
    }

    function addTicker(string memory _ticker) public {
        require(msg.sender == owner, "Only owner can create ticker");
        ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote) public {
        require(Tickers[_ticker].exists, "Can't vote on this coin");
        require(
            !Tickers[_ticker].Voters[msg.sender],
            "You have already voted on this coin"
        );

        ticker storage t = Tickers[_ticker];
        t.Voters[msg.sender] = true;

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
        returns (uint256 up, uint256 down)
    {
        require(Tickers[_ticker].exists, "No such Ticker defined");
        ticker storage t = Tickers[_ticker];

        return (t.up, t.down);
    }
}