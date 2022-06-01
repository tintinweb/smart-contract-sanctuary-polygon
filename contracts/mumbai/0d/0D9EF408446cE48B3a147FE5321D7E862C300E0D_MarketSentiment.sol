//SPDX-License-Identifier: MIT
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
        mapping(address => bool) Voters;
    }

    event tickerupdate(string ticker, address voter, uint256 up, uint256 down);

    mapping(string => ticker) private Tickers;

    function addTicker(string memory _ticker) public {
        require(msg.sender == owner, "Only owner can add ticker");
        ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;
        tickerArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote) public {
        require(Tickers[_ticker].exists, "Ticker does not exists");
        require(!Tickers[_ticker].Voters[msg.sender], "You have already voted");

        ticker storage t = Tickers[_ticker];
        if (_vote) {
            t.up++;
        } else {
            t.down++;
        }
        emit tickerupdate(_ticker, msg.sender, t.up, t.down);
        t.Voters[msg.sender] = true;
    }

    function getVote(string memory _ticker)
        public
        view
        returns (uint256, uint256)
    {
        require(Tickers[_ticker].exists, "Ticker does not exists");
        ticker storage t = Tickers[_ticker];
        return (t.up, t.down);
    }

}