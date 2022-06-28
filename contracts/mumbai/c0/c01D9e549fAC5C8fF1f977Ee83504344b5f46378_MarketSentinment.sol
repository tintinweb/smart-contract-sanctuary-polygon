// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract MarketSentinment {
    address public owner;
    string[] public tickersArray;

    constructor() {
        owner = msg.sender;
    }

    struct Ticker {
        bool exists;
        uint256 up;
        uint256 down;
        mapping(address => bool) voters;
    }

    event TicketUpdated(uint256 up, uint256 down, address voter, string ticker);

    mapping(string => Ticker) private tickers;

    function addTicker(string memory _ticker) public {
        require(msg.sender == owner, "Only the owner can create tickers");
        Ticker storage newTicker = tickers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote) public {
        require(tickers[_ticker].exists, "Can't vote on this coin");
        require(
            !tickers[_ticker].voters[msg.sender],
            "You have already voted for this coin"
        );

        Ticker storage t = tickers[_ticker];
        t.voters[msg.sender] = true;

        if (_vote) {
            t.up++;
        } else {
            t.down--;
        }

        emit TicketUpdated(t.up, t.down, msg.sender, _ticker);
    }

    function getVoter(string memory _ticker)
        public
        view
        returns (uint256 up, uint256 down)
    {
        require(tickers[_ticker].exists, "No such Ticker Defined");
        Ticker storage t = tickers[_ticker];
        return (t.up, t.down);
    }
}