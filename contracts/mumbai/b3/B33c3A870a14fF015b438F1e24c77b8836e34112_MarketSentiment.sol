//SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

contract MarketSentiment {
    address public owner;
    string[] public tickerArrays;

    constructor() {
        owner = msg.sender;
    }

    struct ticker {
        bool exists;
        uint256 Up;
        uint256 Down;
        mapping(address => bool) Voters;
    }
    event tickerUpdated(uint256 Up, uint256 Down, address voter, string ticker);

    mapping(string => ticker) private Tickers;

    function addTickers(string memory _Ticker) public {
        require(msg.sender == owner, "Only Owner can Add Ticker");

        ticker storage newTicker = Tickers[_Ticker];
        newTicker.exists = true;
        tickerArrays.push(_Ticker);
    }

    function vote(string memory _ticker, bool _vote) public {
        require(Tickers[_ticker].exists, "You Cannot Vote in this coin");
        require(!Tickers[_ticker].Voters[msg.sender], "You have already Voted");

        ticker storage t = Tickers[_ticker];
        if (_vote) {
            t.Up++;
        } else {
            t.Down++;
        }
        emit tickerUpdated(t.Up, t.Down, msg.sender, _ticker);
    }

    function getVote(string memory _ticker)
        public
        view
        returns (uint256 Up, uint256 Down)
    {
        require(Tickers[_ticker].exists, "You Cannot Vote in this coin");
        ticker storage t = Tickers[_ticker];

        return (t.Up, t.Down);
    }
}