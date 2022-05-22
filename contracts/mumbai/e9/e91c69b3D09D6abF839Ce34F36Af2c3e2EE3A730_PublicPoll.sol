// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract PublicPoll {

    address public owner;
    string[] public tickersArray;

    constructor() {
        owner = msg.sender;
    }

    struct ticker {
        bool exists;
        uint256 agree;
        uint256 disagree;
        mapping(address => bool) Voters;
    }

    event tickerupdated (
        uint256 agree,
        uint256 disagree,
        address voter,
        string ticker
    );

    mapping(string => ticker) private Tickers;

    function addTicker(string memory _ticker) public {
        require(msg.sender == owner, "Only the owner can create tickers");
        ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote) public {
        require(Tickers[_ticker].exists, "Can't vote on this statement");
        require(!Tickers[_ticker].Voters[msg.sender], "You have already voted on this");
        

        ticker storage t = Tickers[_ticker];
        t.Voters[msg.sender] = true;

        if(_vote){
            t.agree++;
        } else {
            t.disagree++;
        }

        emit tickerupdated (t.agree,t.disagree,msg.sender,_ticker);
    }

    function getVotes(string memory _ticker) public view returns (
        uint256 agree,
        uint256 disagree
    ){
        require(Tickers[_ticker].exists, "No such Ticker Defined");
        ticker storage t = Tickers[_ticker];
        return(t.agree,t.disagree);
        
    }
}