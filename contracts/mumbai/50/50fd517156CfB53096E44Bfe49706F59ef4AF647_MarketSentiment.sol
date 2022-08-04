//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

contract MarketSentiment{

    address owner;



    constructor(){
        owner=msg.sender;
    }




    struct Ticker {
        
        uint up;
        uint down;
        bool exist;
        mapping(address=>bool) voter ;
    }



    mapping (string => Ticker) tickers;


    function add(string memory _ticker) public {
        require(msg.sender==owner,"only owner can  add a ticker");
        Ticker storage newticker= tickers[_ticker];
        newticker.exist=true;
  
    }

    function vote( string memory _ticker , bool _vote ) public {
        require(tickers[_ticker].exist, "Coin not added yet");
        require(!tickers[_ticker].voter[msg.sender] , "You have already voted " );
        
        Ticker storage t = tickers[_ticker];
        t.voter[msg.sender] = true ;

        if (_vote ){
           t.up = t.up+1;
        }

        else {
            t.down = t.down+1;
        }

    }


    function getvotes(string memory _ticker) public view returns( uint up , uint down) {
        require(tickers[_ticker].exist, "Coin does not exist");
         Ticker storage t = tickers[_ticker];
         return (t.up,t.down);
    }

    
}