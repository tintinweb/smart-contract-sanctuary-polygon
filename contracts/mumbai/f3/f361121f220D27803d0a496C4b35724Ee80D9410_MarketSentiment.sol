// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract MarketSentiment{
    address public owner;
    string[] public tickersArray;

    constructor(){
        owner = msg.sender; // who deployed this contract is the owner.
    }

    struct ticker{
        bool exists; // is ticker exists
        uint256 up;
        uint256 down;
        mapping(address => bool) Voters; // ensure single vote per addr
    }

    event tickerupdated ( // for voter and observers transparency
        uint256 up,
        uint256 down,
        address voter,
        string ticker
    ); // dont forget this semi-colon

    mapping(string => ticker) private Tickers; // query ticker name and return ticker struct

    // owner calls
    function addTicker(string memory _ticker) public {
        require(msg.sender == owner, "Only the owner can create tickers");

        // create ticker struct
        ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }

    // voter calls
    function vote(string memory _ticker, bool _vote) public {
        require(Tickers[_ticker].exists, "Ticker does not exists.");
        require(!Tickers[_ticker].Voters[msg.sender], "You have already voted.");

        ticker storage t = Tickers[_ticker];
        t.Voters[msg.sender] = true;

        if(_vote){
            t.up++;
        }
        else{
            t.down++;
        }

        emit tickerupdated(t.up, t.down, msg.sender, _ticker);
    }

    // GUI website calls
    function getVotes(string memory _ticker) public view returns (
        uint256 up,
        uint256 downs
    ){
        require(Tickers[_ticker].exists, "Ticker not defined");

        ticker storage t = Tickers[_ticker];
        return(t.up, t.down);
    }
}

/*
contract Lock {
    uint public unlockTime;
    address payable public owner;

    event Withdrawal(uint amount, uint when);

    constructor(uint _unlockTime) payable {
        require(
            block.timestamp < _unlockTime,
            "Unlock time should be in the future"
        );

        unlockTime = _unlockTime;
        owner = payable(msg.sender);
    }

    function withdraw() public {
        // Uncomment this line, and the import of "hardhat/console.sol", to print a log in your terminal
        // console.log("Unlock time is %o and block timestamp is %o", unlockTime, block.timestamp);

        require(block.timestamp >= unlockTime, "You can't withdraw yet");
        require(msg.sender == owner, "You aren't the owner");

        emit Withdrawal(address(this).balance, block.timestamp);

        owner.transfer(address(this).balance);
    }
}
*/