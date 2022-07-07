//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


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
        mapping(address => bool) Voters;
    }

    event tickerUpdated(
        uint256 up,
        uint256 down,
        address voter,
        string ticker
    );

    mapping(string => Ticker) private Tickers;

    modifier onlyOwner {
        require(owner == msg.sender, "");
        _;
    }

    function addTicker(string memory _ticker) public onlyOwner {
        Ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote) public {
        require(Tickers[_ticker].exists, "Ticker doesn't exist");
        require(!Tickers[_ticker].Voters[msg.sender], "Already voted.");
        Ticker storage currentTicker = Tickers[_ticker];
        currentTicker.Voters[msg.sender] = true;
        if (_vote) {
            currentTicker.up += 1;
        }
        else {
            currentTicker.down += 1;
        }
        emit tickerUpdated(
            currentTicker.up, 
            currentTicker.down, 
            msg.sender, 
            _ticker
        );
    }

    function getVotes(string memory _ticker) public view returns (uint256, uint256) {
        require(Tickers[_ticker].exists, "Ticker doesn't exist");
        Ticker storage currentTicker = Tickers[_ticker];
        return (currentTicker.up, currentTicker.down);
    }
}