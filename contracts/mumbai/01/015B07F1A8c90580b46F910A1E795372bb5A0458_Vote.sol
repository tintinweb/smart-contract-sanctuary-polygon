//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

contract Vote  {
    
    // l'address de celui qui a crée le smart contract
    address public owner;
    string[] public tickerArray;

    // on crée un constructer pour dit celui qui dploie le contracr est le propriétaire 
    constructor(){
        owner = msg.sender;
    }
    // on crée une structure pour pourvoire enregistré les votes et s'avoir qui a vote et  s'il 
    // la personne a voté le haut ou le bas 
    struct ticker{
        bool exists;
        uint256 up ; 
        uint256 down;
        mapping(address=> bool) Voters;
    }

    // on crée un evernement pour qui va nous permetre de s'avoir le niveau du vote actuellement
    event tickerupdated(
        uint256 up,
        uint256 down,
        address Voter,
        string ticker

    );
    mapping(string=> ticker) private Tickers;
    // creation d'un element a voté 
    function addTicker(string memory _ticker) public{
        require(msg.sender ==owner ,"Only the owner can create tickets");
        ticker storage newTicker =Tickers[_ticker];
        newTicker.exists =true;
        tickerArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote) public{
        require(Tickers[_ticker].exists,"Can't vote on this coin");
        require(!Tickers[_ticker].Voters[msg.sender],"You are already Voted for this coin");
        ticker storage t= Tickers[_ticker];
        t.Voters[msg.sender] = true;
        
        if(_vote){
            t.up++;
        }else{
            t.down++;
        }
        emit tickerupdated(t.up,t.down,msg.sender,_ticker);
    }

    function getVotes(string memory _ticker)public view returns(
        uint256 up,
        uint256 down
    ){
        require(Tickers[_ticker].exists,"No such Ticker Defined");
        ticker storage t = Tickers[_ticker];
        return(t.up, t.down);
    }
}