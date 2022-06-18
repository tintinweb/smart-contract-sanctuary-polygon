//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error MarketSentiment_NotOwner();
error MarketSentiment_TickerNotCreated();

contract MarketSentiment {
    // immutable means once it has been initialze it is never going to change
    address public immutable owner;
    string[] public tickerArray;

    constructor() {
        owner = msg.sender;
    }

    struct ticker {
        bool exists;
        uint256 up;
        uint256 down;
        mapping(address => bool) Voters;
    }

    event tickerUpdated(uint256 up, uint256 down, address voter, string ticker);

    mapping(string => ticker) private Ticker;

    function addTicker(string memory _ticker) public onlyOwner {
        ticker storage newTicker = Ticker[_ticker];
        newTicker.exists = true;
        tickerArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote) public canVote(_ticker) {
        ticker storage t = Ticker[_ticker];
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
        require(Ticker[_ticker].exists, "No such Tickers Defined");
        ticker storage t = Ticker[_ticker];
        return (t.up, t.down);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert MarketSentiment_NotOwner();
        }
        _;
    }
    modifier canVote(string memory _ticker) {
        if (!Ticker[_ticker].exists && !Ticker[_ticker].Voters[msg.sender]) {
            revert MarketSentiment_TickerNotCreated();
        }
        _;
    }
}