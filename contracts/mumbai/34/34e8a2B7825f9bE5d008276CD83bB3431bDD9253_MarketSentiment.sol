/**
 *Submitted for verification at polygonscan.com on 2022-08-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deployMarketSentiment.js
 */

contract MarketSentiment {

    address public owner;
    string[] public tickersArray;

    constructor() {
        owner = msg.sender;
    }

    struct ticker {
        bool exists;
        uint256 a;
        uint256 b;
        mapping(address => bool) Voters;
    }

    event tickerupdated (
        uint256 a,
        uint256 b,
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
        require(Tickers[_ticker].exists, "Can't vote on this coin");
        require(!Tickers[_ticker].Voters[msg.sender], "You have already voted for this coin");
        

        ticker storage t = Tickers[_ticker];
        t.Voters[msg.sender] = true;

        if(_vote){
            t.a++;
        } else {
            t.b++;
        }

        emit tickerupdated (t.a,t.b,msg.sender,_ticker);
    }

    function getVotes(string memory _ticker) public view returns (
        uint256 a,
        uint256 b
    ){
        require(Tickers[_ticker].exists, "No such Ticker Defined");
        ticker storage t = Tickers[_ticker];
        return(t.a,t.b);
    }
}