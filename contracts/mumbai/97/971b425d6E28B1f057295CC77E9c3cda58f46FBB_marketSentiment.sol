/**
 *Submitted for verification at polygonscan.com on 2022-07-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract marketSentiment {
    address public owner;
    string[] public tickersArray;
    mapping(string => ticker) private Tickers;

    struct ticker {
        bool exists;
        uint256 up;
        uint256 down;
        mapping(address => bool) Voters;
    }

    event tickerUpdated (
        uint256 up,
        uint256 down,
        address voter,
        string ticker
    );

    constructor () {
        owner = msg.sender;
    }

    function addTicker(string memory _ticker) public {
        require(msg.sender == owner, "only the owner can create a ticker");
        ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote) public {
        //_vote: true vote up false vote down
        require(Tickers[_ticker].exists, "Cannot vote on this coin");
        require(!Tickers[_ticker].Voters[msg.sender], "You already voted on this coin");
        
        ticker storage t = Tickers[_ticker];
        t.Voters[msg.sender] = true;

        if(_vote == true) {
            t.up ++;
        } else {
            t.down ++;
        }
        emit tickerUpdated(t.up, t.down, msg.sender, _ticker);

    }

    function getVotes(string memory _ticker) public view returns(uint up, uint down) {
        require(Tickers[_ticker].exists, "No such ticker exist");
        ticker storage t = Tickers[_ticker];
        return(t.up, t.down);
    }
}