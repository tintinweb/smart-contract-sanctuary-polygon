// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

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

    event TickerUpdated(uint256 up, uint256 down, address voter, string ticker);

    mapping(string => Ticker) private Tickers;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier existTicker(string memory _ticker) {
        require(
            Tickers[_ticker].exists,
            "Existable: this ticker does not exist"
        );
        _;
    }

    modifier duplicateVote(string memory _ticker) {
        require(
            !Tickers[_ticker].Voters[msg.sender],
            "Duplicable: unable to vote twice"
        );
        _;
    }

    function addTicker(string memory _ticker) public onlyOwner {
        Ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote)
        public
        existTicker(_ticker)
        duplicateVote(_ticker)
    {
        Ticker storage ticker = Tickers[_ticker];
        ticker.Voters[msg.sender] = true;

        if (_vote) {
            ticker.up++;
        } else {
            ticker.down++;
        }

        emit TickerUpdated(ticker.up, ticker.down, msg.sender, _ticker);
    }

    function getVotes(string memory _ticker)
        public
        view
        existTicker(_ticker)
        returns (uint256 up, uint256 down)
    {
        Ticker storage ticker = Tickers[_ticker];
        return (ticker.up, ticker.down);
    }

    function getTickersArray() public view onlyOwner returns (string[] memory) {
        return tickersArray;
    }
}