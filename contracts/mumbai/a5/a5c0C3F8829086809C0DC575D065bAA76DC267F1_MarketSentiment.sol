// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract MarketSentiment {
    // write code to let anyone with a crypto wallet address
    // interact with our smart contract and vote on their sentiment on cryptocurrencies
    address public owner;
    string[] public tickersArray;

    constructor() {
        // who ever deploys this contract will be come the owner of this smart contract
        owner = msg.sender;
    }

    // any crypto currency added to the smart contract will follow this structure
    // any time we add a ticker to this smart contract will set this boolean to true
    struct ticker {
        bool exists;
        uint256 up;
        uint256 down;
        mapping(address => bool) Voters;
    }
    
    event tickerupdated(uint256 up, uint256 down, address voter, string ticker);
    // takes any string and maps it to a ticker struct
    // if this ticker isnt created the exist boolean will be false
    // our Tickers mapping will return us this struct for btc
    // letting us know who has voted and the direction theyve voted
    mapping(string => ticker) private Tickers;

    // function to add tickers can be called only by owner of smart contract
    function addTicker(string memory _ticker) public {
        require(msg.sender == owner, "Only the owner can create tickers");
        ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }

    // vote function
    function vote(string memory _ticker, bool _vote) public {
        require(Tickers[_ticker].exists, "Can't vote on this coin");
        require(
            !Tickers[_ticker].Voters[msg.sender],
            "You have already voted for this coin"
        );

        ticker storage t = Tickers[_ticker];
        // any time this user with this address that msg.sender has tries to call the vote function again
        // for the same _ticker theyll be caught in the require[!Tickers[_ticker]...] statement
        // so they can only call this function once
        t.Voters[msg.sender] = true;

        // set vote up or down
        if (_vote) {
            t.up++;
        } else {
            t.down++;
        }

        emit tickerupdated(t.up, t.down, msg.sender, _ticker);
    }

    // get the votes for any ticker
    function getVotes(string memory _ticker)
        public
        view
        returns (uint256 up, uint256 down)
    {
        require(Tickers[_ticker].exists, "No such Ticker Defined");
        ticker storage t = Tickers[_ticker];
        return (t.up, t.down);

    }
}