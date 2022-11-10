// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract MarketSentiment {
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    // Struct Type of a ticker
    struct tickerStruct {
        uint256 _votesOK;
        uint256 _votesNOK;
        mapping(address => bool) _voters;
    } 

    // Event to emit when a vote is executed
    event _tickerUpdated(string _tickerName, uint256 _votesOK, uint256 _votesNOK, address voter);
    
    //Mapping for tickers (strings) already created
    mapping(string => uint) public _existingTickers;
    
    //Mapping for Tickers (TickerStruct inside)
    mapping(string => tickerStruct) public _tickersList;

    // Function to add a ticker (only owner can do it)
    function addTicker(string memory _tickerName)  public {
        require(msg.sender == owner, "Only the owner can excute this function");
        require(_existingTickers[_tickerName] != 1, "This ticker already exists");
        
        tickerStruct storage _newTicker = _tickersList[_tickerName];
        _newTicker._votesNOK = 0;
        _newTicker._votesOK = 0;

        //Update the tickers list. Used to avoid duplicating them
        _existingTickers[_tickerName] = 1;
      
    }

    // Function to vote a ticker
    function voteTicker(string memory _tickerName, bool _vote) public {

        require(_tickersList[_tickerName]._voters[msg.sender] == false, "You have already voted this token");

        if (_vote == true) {
            _tickersList[_tickerName]._votesOK = _tickersList[_tickerName]._votesOK + 1;
            } else {
            _tickersList[_tickerName]._votesNOK = _tickersList[_tickerName]._votesNOK + 1;
            }
        _tickersList[_tickerName]._voters[msg.sender] = true;
        emit _tickerUpdated(_tickerName, _tickersList[_tickerName]._votesOK,_tickersList[_tickerName]._votesNOK, msg.sender);

    }

    function countVotes(string memory _tickerName) public view returns(uint256 _votesFor, uint256 _votesAgainst, uint256 _totalVotes) {
        require(_existingTickers[_tickerName] == 1, "The ticker doesnt exist" );
        _votesFor = _tickersList[_tickerName]._votesOK;
        _votesAgainst = _tickersList[_tickerName]._votesNOK;
        _totalVotes = _votesFor + _votesAgainst;
        return(_votesFor,_votesAgainst, _totalVotes);
    }
}