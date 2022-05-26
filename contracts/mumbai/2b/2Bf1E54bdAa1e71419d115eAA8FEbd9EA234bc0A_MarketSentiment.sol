// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract MarketSentiment {

    // defining global variables, address owner of smartcontract
    // defining all the cryptocurrencies set by the owner
    address public owner;
    string[] public tickersArray;

    // whoever deploys this smart contract will become the owner of the smart contract
    constructor() {
        owner = msg.sender;
    }

    // definition (structure) of any crptocurrency which the owner has added
    // does the crypto exist, how many votes up and down, mapping keeps track of 
    // all the voters and makes sure they can't vote more then once
    struct ticker {
        bool exists;
        uint256 up;
        uint256 down;
        mapping(address => bool) Voters;
    }

    // maintains transparency by showing that whenever someone votes
    // this event will be emited with this return values
    event tickerupdated (
        uint256 up,
        uint256 down,
        address voter,
        string ticker
    );

    // takes any string and maps it to a ticker struct
    // if ticker doesn't exist bool will return false (should return error)
    mapping(string => ticker) private Tickers;

    // only owner should be able to call this function
    // function adds tickers but can only be called by owner of smart contract
    function addTicker(string memory _ticker) public {
        require(msg.sender == owner, "only the owner can create tickers");
        ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }

    // function for voting for tickers
    /* require statements to check if the user has already voted for a token and 
    if the token can even be voted for  */
    function vote(string memory _ticker, bool _vote) public {
        require(Tickers[_ticker].exists, "Can't vote on this coin");
        require(!Tickers[_ticker].Voters[msg.sender], "You have already voted for this coin");

        /* anytime the user with this address (msg.sender) trys to call the ticker will be caught by
        require statmment */
        ticker storage t = Tickers[_ticker];
        t.Voters[msg.sender] = true;

        if(_vote) {
            t.up++;
        } else {
            t.down--;
        }

        // call the event after the functions
        /* will update the the current number of votes onto the blockchain 
        and will say where the msg.sender has voted and which they have voted for*/  
        emit tickerupdated(t.up, t.down, msg.sender, _ticker);
        }

        // this function allows anyone to see the number of votes done 
        function getVotes(string memory _ticker) public view returns (
            uint256 up,
            uint256 down
        ) {
           require(Tickers[_ticker].exists, "No such Ticker Defined");
           ticker storage t = Tickers[_ticker];
           return(t.up, t.down); 
        }

}