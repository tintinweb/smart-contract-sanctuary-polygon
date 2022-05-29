//SPDX-License-Identifier: Unlicense
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
        // check an address voted for that ticker
        mapping(address => bool) Voters;
    }

    event tickerupdated (
        uint256 up,
        uint256 down,
        address voter,
        string ticker
    );

    // take any string and map to any ticker (BTC=>ticker struct)
    mapping(string => ticker) private Tickers;

    // add a new ticker like "BTC", "ETH" only if you are the owner of the smart contract
    function addTicker(string memory _ticker) public {
        require(msg.sender == owner, "Only the owner can create tickers");
        ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote) public {
        // check the ticker exist
        require(Tickers[_ticker].exists, "Can't vote on this coin");
        // check you didn't vote yet for this ticker
        require(!Tickers[_ticker].Voters[msg.sender], "You have already voted for this coin");

        // set the voted action to true for this ticker
        ticker storage t = Tickers[_ticker];
        t.Voters[msg.sender] = true;

        // update the vote up or down
        if(_vote){
            t.up++;
        } else {
            t.down++;
        }

        // call the event to update the ticker
        emit tickerupdated(t.up, t.down, msg.sender, _ticker);
    }

    // get the vote for any ticker at any time
    function getVotes(string memory _ticker) public view returns (
        uint256 up,
        uint256 down
    ) {
        // check the ticker exist
        require(Tickers[_ticker].exists, "No such Ticker Defined");
        ticker storage t = Tickers[_ticker];
        return(t.up, t.down);
    }
}