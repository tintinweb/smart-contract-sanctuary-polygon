// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract MarketSentiment {

    address public owner;
    string[] public tickersArray;

    constructor() {
        owner = msg.sender;
    }

    struct ticker {
        bool isTrue;
        uint256 upButton;
        uint256 downButton;
        mapping(address => bool) Voters;
    }

    event tickerupButtondated (
        uint256 upButton,
        uint256 downButton,
        address voter,
        string ticker
    );

    mapping(string => ticker) private Tickers;

    function addTicker(string memory _ticker) public {
        require(msg.sender == owner, "Only the owner can create tickers");
        ticker storage newTicker = Tickers[_ticker];
        newTicker.isTrue = true;
        tickersArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote) public {
        require(Tickers[_ticker].isTrue, "Can't vote on this crypto");
        require(!Tickers[_ticker].Voters[msg.sender], "You have already voted for this crypto");
        

        ticker storage t = Tickers[_ticker];
        t.Voters[msg.sender] = true;

        if(_vote){
            t.upButton++;
        } else {
            t.downButton++;
        }

        emit tickerupButtondated (t.upButton,t.downButton,msg.sender,_ticker);
    }

    function getVotes(string memory _ticker) public view returns (
        uint256 upButton,
        uint256 downButton
    ){
        require(Tickers[_ticker].isTrue, "No such Ticker Defined");
        ticker storage t = Tickers[_ticker];
        return(t.upButton,t.downButton);        
    }
}