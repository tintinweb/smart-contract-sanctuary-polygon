//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MarketSentiment{

    address public owner; 

    constructor(){
        owner = msg.sender;
    }

    //basic struct for votes
    struct Ticker{
        uint256 votesUp;
        uint256 votesDown;
        mapping(address => bool) voter;
    }

    //mappings
    mapping(string => Ticker) public tickers;
    mapping(string => uint256) public allTickers;

    //modifier for the vote function "only the owner can add a ticker"
    modifier onlyOwner{
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    //event when an user vote
    event tickerUpdate(string _tickerName, uint voteUp, uint voteDown );

    //function to add a ticker
    function addTicker(string memory _tickerName) public onlyOwner{
        require(allTickers[_tickerName] != 1, "Este ticker ya existe");
        allTickers[_tickerName] = 1;
    }

    //function to vote
    function vote(bool _vote, string memory _tickerName) public{
        require(tickers[_tickerName].voter[msg.sender] == false, "Este usuario ya voto!!");//if the user doesnt vote never, vote.
        //if logic
        if(_vote == true){
            tickers[_tickerName].votesUp +=1;
               emit tickerUpdate(_tickerName, 1, 0);
        }else if(_vote == false){
           emit tickerUpdate(_tickerName, 0, 1);
            tickers[_tickerName].votesDown +=1;
        }else{
            revert("Wrong choose");
        }
        tickers[_tickerName].voter[msg.sender] = true;    
    }   


    //function that returns the votes
    function getVotes(string memory _tickerName) public view returns(uint256 votesUp, uint256 votesDown, uint256 totalVotes){
        require(allTickers[_tickerName] == 1, "This ticker alredy exist!");
        votesUp = tickers[_tickerName].votesUp; //save the data for a up vote
        votesDown = tickers[_tickerName].votesDown; //save the data for a down vote
        totalVotes = votesUp + votesDown;  //save the data for the total votes
        return (votesUp, votesDown, totalVotes); //returns the votes
    }
}