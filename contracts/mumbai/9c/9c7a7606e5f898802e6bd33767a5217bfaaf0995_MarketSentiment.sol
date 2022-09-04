/**
 *Submitted for verification at polygonscan.com on 2022-09-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract MarketSentiment {

    //Keeps track of the smart contract owner and keeps an array of all the cryptos that are added to the poll.
    address public owner;
    string[] public tickersArray;

    //Whoever deploys this contract will become the 'owner'.
    constructor() {
        owner = msg.sender;
    }

    //Definition of any ticker that the owner creates.
    struct ticker {
        //Does the ticker exist?
        bool exists;
        //Keeps count of how many up votes.
        uint256 up;
        //Keeps count of how many down votes.
        uint256 down;
        //Bool will swith to true for any wallet that interacts with a specific ticker. 
        mapping(address => bool) Voters;
    }

    //When anyone updates thier vote, this event will start.
    event tickerupdated (
        uint256 up,
        uint256 down,
        address voter,
        string ticker
    );

    //Takes any string and maps it to a ticker struct.
    mapping(string => ticker) private Tickers;

    //Add new ticker (crypto) to the poll.
    function addTicker(string memory _ticker) public {

        require(msg.sender == owner, "Only the owner can create tickers");
        ticker storage newTicker = Tickers[_ticker];
        newTicker.exists == true;
        tickersArray.push(_ticker);

    }
        
    function vote(string memory _ticker, bool _vote) public {
        require(Tickers[_ticker].exists, "Can't vote on this coin");
        require(!Tickers[_ticker].Voters[msg.sender], "You have already voted for this coin");

        //Temporary storage for function call.
        ticker storage t = Tickers[_ticker];
        t.Voters[msg.sender] = true;

        if(_vote){
            t.up++;
        } else {
            t.down++;
        }

        emit tickerupdated(t.up, t.down, msg.sender, _ticker);
    }

    function getVotes(string memory _ticker) public view returns (
        uint256 up,
        uint256 down
        ){
            require(Tickers[_ticker].exists, "No such Ticker Defined");
            ticker storage t = Tickers[_ticker];
            return(t.up, t.down);
        }
    
}