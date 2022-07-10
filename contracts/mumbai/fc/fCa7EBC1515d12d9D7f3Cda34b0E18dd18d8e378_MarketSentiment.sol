/**
 *Submitted for verification at polygonscan.com on 2022-07-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract MarketSentiment {

    address public owner;
    string[] public tickersArray;

    constructor() {
        owner = msg.sender;
    }

    struct ticker {
        bool exists; // if ticker exists
        uint256 up; // up votes
        uint256 down; // down votes
        mapping(address => bool) Voters; // keeping track of voters. each address mapped to a boolean (if voted for this ticker or not)
    }

    // for transparency & moralis to listen to events on this smartcontract
    // the voter who just voted & the ticker that was just voted on, to display
    event tickerupdated (
        uint256 up,
        uint256 down,
        address voter,
        string ticker
    );

    // maps a string to a ticker struct
    mapping(string => ticker) private Tickers;

    // fn to add tickers, callable only by owner of contract
    function addTicker(string memory _ticker) public {
        require(msg.sender == owner, "Only the owner can create tickers");
        ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }

    // fn to handle voting
    function vote(string memory _ticker, bool _vote) public {
        // validate ticker exists
        require(Tickers[_ticker].exists, "Can't vote on this coin");
        // validate sender hasn't already voted for this ticker
        require(!Tickers[_ticker].Voters[msg.sender], "You have already voted for this coin");

        ticker storage t = Tickers[_ticker];
        t.Voters[msg.sender] = true; // set voted to true

        if (_vote) {
            t.up++;
        } else {
            t.down++;
        }

        emit tickerupdated (t.up, t.down, msg.sender, _ticker);
    }

    function getVotes(string memory _ticker) public view returns (
        uint up,
        uint down
    ) {
        require(Tickers[_ticker].exists, "No such Ticker defined");
        ticker storage t = Tickers[_ticker];
        return(t.up, t.down);
    }
}