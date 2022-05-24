//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.7;

contract MarketSentiment {
    // initialize smart contract owner
    address public owner;
    constructor() {
        owner = msg.sender;
    }

    // initialize array of tickers
    // tickers are where votable tokens are stored
    string[] public tickersArray;

    // define a struct for tickers
    struct ticker {
        bool exists;
        uint256 up;
        uint256 down;
        mapping(address => bool) Voters;
    }

    // map string format of each created ticker to its equivalent ticker struct
    // Call 'Tickers' to perform mapping
    mapping(string => ticker) private Tickers;

    // define event to be emitted when a ticker is updated
    event tickerUpdated (uint256 up, uint256 down, address voter, string ticker);

    /**
     * Add new ticker/ token that may be voted on
     */
    function addTicker(string memory _ticker) public {
        require(msg.sender == owner, "Only the owner can create tickers");
        ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }

    /**
     * Cast vote on future price direction of a ticker/ token
     */
    function vote(string memory _ticker, bool _vote) public {
        // Map the ticker string format to ticker struct to get the value of 'exists'
        require(Tickers[_ticker].exists, "Can't vote on this coin");
        
        // Map the ticker string format to ticker struct to access Voters, which maps the ticker to a bool
        require(!Tickers[_ticker].Voters[msg.sender], "You have already voted for this coin");

        ticker storage t = Tickers[_ticker];
        t.Voters[msg.sender] = true;
        
        if(_vote) {
            t.up++;
        } else {
            t.down++;
        }

        emit tickerUpdated(t.up, t.down, msg.sender, _ticker);
    }

    /**
     * Get the status of votes for any tickers/ tokens
     */
    function getVotes(string memory _ticker) public view returns (uint256 up, uint256 down) {
        require(Tickers[_ticker].exists, "No such Ticker Defined");

        ticker storage t = Tickers[_ticker];
        return (t.up, t.down);
    }
}