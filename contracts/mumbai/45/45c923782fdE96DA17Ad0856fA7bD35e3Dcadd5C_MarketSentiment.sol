//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract MarketSentiment {
    address public owner;
    string[] public tickersArray;

    constructor() {
        owner = msg.sender;
    }

    struct ticker {
        bool exists;
        uint256 up;
        uint256 down;
        mapping(address => bool) Voters;
        //all of the addresses are set to false in the begining of this mapping
    }

    event tickerupdated(uint256 up, uint256 down, address voter, string ticker);

    mapping(string => ticker) private Tickers;

    function addticker(string memory _ticker) public {
        require(owner == msg.sender, "You are not owner");
        ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote) public {
        require(Tickers[_ticker].exists, "Can not Vote on this coin");
        require(!Tickers[_ticker].Voters[msg.sender], "You have already voted");

        ticker storage t = Tickers[_ticker];
        t.Voters[msg.sender] = true;

        if (_vote) {
            t.up++;
        } else {
            t.down++;
        }
        emit tickerupdated(t.up, t.down, msg.sender, _ticker);
    }

    function getVotes(string memory _ticker)
        public
        view
        returns (uint256 up, uint256 down)
    {
        require(Tickers[_ticker].exists, "No such a ticker Defined");
        ticker storage t = Tickers[_ticker];
        return (t.up, t.down);
    }
}