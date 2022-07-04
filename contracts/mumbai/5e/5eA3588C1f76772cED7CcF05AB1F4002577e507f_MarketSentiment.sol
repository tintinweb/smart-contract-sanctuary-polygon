//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

contract MarketSentiment {

    address public owner;
    string[] public tickersArray;

// whoever deploys the sc, becomes the owner of the sc
    constructor() {
        owner = msg.sender;
    }
//a def of any ticker that the onwer creats. any crypto thats added to the sc will follow this struct
    struct ticker{
        bool exists; // bool that is set to true if the ticker exists
        uint256 up; // declaring votes of up
        uint256 down; // declaring votes of down
        mapping(address => bool) Voters; //keeping track of the voters, every address are mapped to a boolean. 
//so anytime anyone votes will set that wallet address to true, so they can't revote on the same ticker again.

    }
// for the sake of transparency, an moralis to listen to any events on this sc. so when anyone updates, will emit this event.
    event tickerupdated (
        uint256 up,
        uint256 down,
        address voter,
        string ticker


    );
    
    mapping(string => ticker) private Tickers;

    function addTicker(string memory _ticker) public {
        require(msg.sender == owner, "Suck My Dick, Only owner can create tickers");
        ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true; 
        tickersArray.push(_ticker);
    }
    //voting function
    function vote(string memory _ticker, bool _vote) public {
        require(Tickers[_ticker].exists,"Can't vote on this coin");// check for the ticker
        require(!Tickers[_ticker].Voters[msg.sender],"You have already voted for this coin huttoo");
        //make sure the address making the call, has not voted already. 

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
        require(Tickers[_ticker].exists, "Pissuda Hutto Mewa Mehe nah");
        ticker storage t = Tickers[_ticker];
        return(t.up,t.down);
    }
        
    

}