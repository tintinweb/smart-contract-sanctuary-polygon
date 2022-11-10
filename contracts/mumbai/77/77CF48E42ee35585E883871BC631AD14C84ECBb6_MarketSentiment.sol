pragma solidity ^0.8.7;

contract MarketSentiment{

    address public owner; 

    constructor(){
        owner = msg.sender;
    }

    struct Ticker{
        uint256 votesUp;
        uint256 votesDown;
        mapping(address => bool) voter;
    }

    mapping(string => Ticker) public tickers;
    mapping(string => uint256) public allTickers;


    modifier onlyOwner{
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    event tickerUpdate(string _tickerName, uint voteUp, uint voteDown );

    function addTicker(string memory _tickerName) public onlyOwner{
        require(allTickers[_tickerName] != 1, "Este ticker ya existe");
        tickers[_tickerName].votesUp = 0;
        tickers[_tickerName].votesDown = 0;
        allTickers[_tickerName] = 1;
    }


    function vote(bool _voteUp, bool _voteDown, string memory _tickerName) public{
        require(tickers[_tickerName].voter[msg.sender] == false, "Este usuario ya voto!!");
        if(_voteUp == true){
            tickers[_tickerName].votesUp += 1;
           emit tickerUpdate(_tickerName, 1, 0);
        }else if(_voteDown == true){
            tickers[_tickerName].votesDown += 1;
            emit tickerUpdate(_tickerName, 0, 1);
        }else{
            revert("Wrong choose");
        }
        tickers[_tickerName].voter[msg.sender] = true;    
    }   

    function getVotes(string memory _tickerName) public view returns(uint256 votesUp, uint256 votesDown, uint256 totalVotes){
        require(allTickers[_tickerName] == 1, "Este ticker no existe!");
        votesUp = tickers[_tickerName].votesUp;
        votesDown = tickers[_tickerName].votesDown;
        totalVotes = votesUp + votesDown;
        return (votesUp, votesDown, totalVotes);
    }
}