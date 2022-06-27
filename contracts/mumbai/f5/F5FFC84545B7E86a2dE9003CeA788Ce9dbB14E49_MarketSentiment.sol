// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MarketSentiment {
    address public owner;
    string[] public tickersArray;

    constructor() { // run at the creation of the contract
        owner = msg.sender; // whoever deploys the contract becomes the owner of it
    }

    struct ticker {
        bool exists; // true if ticker exists
        uint256 up; // how many upvotes
        uint256 down; // how many downvotes
        mapping(address => bool) Voters; // keeps track of all voters for the ticker
        // all the wallet addresses will be set to true if already voted, initially false
    }   
    // useful for getting current status of votes to put into moralis, which puts it into the app
    event tickerupdated (
        uint256 up, 
        uint256 down,
        address voter,
        string ticker
    );

    mapping(string => ticker) private Tickers; // takes a string, like btc, and maps it into a ticker struct

    function addTicker(string memory _ticker) public {
        require(msg.sender == owner, "Only the owner can create tickers");
        ticker storage newTicker = Tickers[_ticker]; 
        newTicker.exists = true;
        tickersArray.push(_ticker); // adds the string into the array
    }

    function vote(string memory _ticker, bool _vote) public {
        require(Tickers[_ticker].exists, "Can't vote on this coin");
        require(!Tickers[_ticker].Voters[msg.sender], "You have already voted for this coin");
        
        ticker storage t = Tickers[_ticker]; // 
        t.Voters[msg.sender] = true; // this person has already voted, cannot vote again for same ticker

        if(_vote) { // if the vote is true, or an upvote
            t.up ++;
        } else {
            t.down++;
        }

        emit tickerupdated (t.up, t.down, msg.sender, _ticker); // calls the event
    }

    function getVotes(string memory _ticker) public view returns (uint256 up, uint256 down) {
        require(Tickers[_ticker].exists, "No such Ticker Defined");
        ticker storage t = Tickers[_ticker]; 
        return (t.up, t.down);
    }
    
}