// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract MarketSentiment {

    address public owner;
    string[] public tickersArray;  //list of crypto currency(ticker)

    constructor() {
    // address of owner who deploys the contract.
        owner = msg.sender;
    }

    // details about the ticker(crtpto).
    struct ticker {
        bool exists;
        uint256 up;
        uint256 down;
        mapping(address => bool) Voters;
    }

    // event to update about changes in ticker.
    event tickerupdated (
        uint256 up,
        uint256 down,
        address voter,
        string ticker
    );

    //map to ticker struct, to get the details of tickers by name
    mapping(string => ticker) private Tickers;

    // func to create ticker
    function addTicker(string memory _ticker) public {
        // condition: one who calls func must be owner who deployed contract.
        require(msg.sender == owner, "Only the owner can create tickers!");

        // struct type ticker storage to add new ticker.
        ticker storage newTicker = Tickers[_ticker];

        // from ticker struct and make exists true
        newTicker.exists = true;
        
        //push new ticker to array
        tickersArray.push(_ticker);

    }

    function vote(string memory _ticker, bool _vote) public {
        //condition to check if ticker exists or not
        require(Tickers[_ticker].exists, "Can't vote on this coin!");
        // check if the user has already voted or not
        require(!Tickers[_ticker].Voters[msg.sender],"You have already voted for this coin!");

        // ticker struct to store the ticker
        ticker storage t = Tickers[_ticker];
        // make as voted
        t.Voters[msg.sender] = true;

        // vote is true then Upvote if false Down vote
        if(_vote) {
            t.up++;
        } else{
            t.down++;
        }

        // emit the event for ticker update
        emit tickerupdated(t.up, t.down, msg.sender, _ticker);

    }

    // func to get the number of votes for particular ticker
    function getVotes(string memory _ticker) public view returns(
        uint256 up, uint256 down
    ) {
        //check if coin exists
        require(Tickers[_ticker].exists, "No such ticker exists!");
        
        ticker storage t = Tickers[_ticker];

        return(t.up, t.down);
        
    }

}