// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

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
    }

    event tickerupdated (
        uint256 up,
        uint256 down,
        address voter,
        string ticker
    );

    mapping(string => ticker) private Tickers;

    function addTicker(string memory _ticker) public {
        require(msg.sender == owner, "Only the contract owner can create tickers");
        ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote) public {
        require(Tickers[_ticker].exists, "The ticker doesn't exist");
        require(!Tickers[_ticker].Voters[msg.sender], "Only one vote can be submitted for each ticker");
        ticker storage editTicker = Tickers[_ticker];
        editTicker.Voters[msg.sender] = true;

        if(_vote) {
            editTicker.up++; 
        }
        else {
            editTicker.down++;
        }

        emit tickerupdated(editTicker.up, editTicker.down, msg.sender, _ticker);
    }

    function getVotes(string memory _ticker) public view returns (uint256 up, uint256 down) {
        require(Tickers[_ticker].exists, "The ticker doesn't exist");
        ticker storage t = Tickers[_ticker];
        return(t.up, t.down);
    }
}