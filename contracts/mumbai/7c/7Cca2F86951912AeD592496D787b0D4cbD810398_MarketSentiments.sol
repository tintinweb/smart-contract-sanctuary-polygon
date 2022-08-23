// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// contract address = "0x7Cca2F86951912AeD592496D787b0D4cbD810398

// Import this file to use console.log
// import "hardhat/console.sol";

contract MarketSentiments {
    address public owner;
    string[] public tickersArray;

    constructor() {
        owner = msg.sender;
    }

    struct ticker {
        bool exist;
        uint256 up;
        uint256 down;
        mapping(address => bool) Voters;
    }

    event tickerupdated(uint256 up, uint256 down, address voter, string ticker);

    mapping(string => ticker) private Tickers;

    function addTicker(string memory _ticker) public {
        require(msg.sender == owner, "Only the owner can create");

        ticker storage newTicker =  Tickers[_ticker];

        newTicker.exist = true;
        tickersArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote) public {
        require(Tickers[_ticker].exist, "Can't vote on this coin");

        require(
            !Tickers[_ticker].Voters[msg.sender],
            "You have already voted for this coin"
        );

        ticker storage tickerCreate = Tickers[_ticker];
        tickerCreate.Voters[msg.sender] = true;
        if (_vote) {
            tickerCreate.up++;
        } else {
            tickerCreate.down++;
        }

        emit tickerupdated(tickerCreate.up, tickerCreate.down, msg.sender, _ticker);
    }

    function getVoters(string memory _ticker)
        public
        view
        returns (uint256 up, uint256 down)
    {
        require(Tickers[_ticker].exist, "No such Ticker Defined");

        ticker storage tickerCheck = Tickers[_ticker];

        return (tickerCheck.up, tickerCheck.down);
    }
}