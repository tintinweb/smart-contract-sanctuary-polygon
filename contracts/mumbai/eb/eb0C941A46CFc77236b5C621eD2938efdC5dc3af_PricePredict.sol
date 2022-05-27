//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract PricePredict {

    address public owner ;
    string[] public tickersArray;

    constructor() {
        owner = msg.sender;
    }

    struct ticker {
        bool exists;
        uint256 up;
        uint256 down;
        mapping(address => bool) Voters;
    }

    event tickerUpdate (
        uint256 up,
        uint256 down,
        address voter,
        string ticker
    );

    mapping(string => ticker) private Tickers;

    function addTikcer(string memory _ticker) public {
        require(msg.sender == owner , "only the owner can create the tickers ");

        ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }

    function vote(string memory _ticker , bool _vote) public {
        require(Tickers[_ticker].exists, "Can't vote on this coin");
        require(!Tickers[_ticker].Voters[msg.sender], "You have already voted for this coin");

        ticker storage t = Tickers[_ticker];
        t.Voters[msg.sender] = true;

        if(_vote){
           t.up++;
        }else {
            t.down++;
        }

        emit tickerUpdate(t.up,t.down,msg.sender,_ticker);
    }

    function getVote(string memory _ticker) public view returns(uint256 up, uint256 down){
        require(Tickers[_ticker].exists ,"No such Coin defined" );
        // ticker storage t = Tickers[_ticker];
        return (Tickers[_ticker].up,Tickers[_ticker].down);
    }
}