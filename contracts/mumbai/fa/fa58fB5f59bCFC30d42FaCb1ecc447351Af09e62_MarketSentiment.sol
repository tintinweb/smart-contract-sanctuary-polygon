// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract MarketSentiment {
    address public owner;
    string[] public tickersArray;
    mapping(string => ticker) private Tickers;

    constructor() {
        owner = msg.sender;
    }

    struct ticker {
        bool exists;
        uint256 up;
        uint256 down;
        mapping(address => bool) voters;
    }

    event tickerUpdated(uint256 up, uint256 down, address voter, string ticker);

    function addTicker(string memory _ticker) public {
        require(msg.sender == owner, "only the owner can create tickers");
        ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote) public {
        ticker storage thisTicker = Tickers[_ticker];
        require(thisTicker.exists, "ticker does not exist");
        require(thisTicker.voters[msg.sender] == false, "you have alr voted");
        if (_vote) {
            thisTicker.up++;
        } else {
            thisTicker.down++;
        }
        thisTicker.voters[msg.sender] = true;
        emit tickerUpdated(thisTicker.up, thisTicker.down, msg.sender, _ticker);
    }

    function getVotes(
        string memory _ticker
    ) public view returns (uint256 up, uint256 down) {
        ticker storage thisTicker = Tickers[_ticker];
        require(thisTicker.exists, "ticker does not exist");
        return (thisTicker.up, thisTicker.down);
    }
}