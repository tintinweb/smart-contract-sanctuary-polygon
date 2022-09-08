// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract MarketSentiment {

    address public owner;
    string [] public tickersArray;

    constructor(){

        owner = msg.sender;
    }

    struct ticker {

        bool exists;
        uint256 up;
        uint256 down;
        mapping(address => bool) Voters;
    }

    event tickerupdated(
        uint256 up,
        uint256 down,
        address voter,
        string ticker

    );


    mapping(string => ticker) private Tickers;

    function addTicker(string memory _ticker) public{

        require(msg.sender == owner, "Only the owner can create tickers");
        ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);

    }
    function vote(string memory _ticker, bool _vote) public {

        require(Tickers[_ticker].exists, "Can't vote on this coin yet");
        require(!Tickers[_ticker].Voters[msg.sender], "You have already voted");
        if (_vote) {

            Tickers[_ticker].Voters[msg.sender] = true;
            Tickers[_ticker].up++;
        }
        else{
             
        }
    }

    function getVotes(string memory _ticker) public view returns(
        uint256 up,
        uint256 down

    ){

                require(Tickers[_ticker].exists, "Can't vote on this coin yet");
                
                return(Tickers[_ticker].up, Tickers[_ticker].down);


    }


}