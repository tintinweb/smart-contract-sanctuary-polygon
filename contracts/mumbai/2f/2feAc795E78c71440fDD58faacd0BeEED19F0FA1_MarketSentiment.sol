// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract MarketSentiment {

	address public owner;
	string[] public tickersArray;

	constructor (){
		owner = msg.sender;	
	}
	//hoever deploys this smartcontract will be the owner

	//any cryptocurrency added to the smart contract will follow this structure

	struct ticker{
		bool exists;//if the ticker exists, true any time we add it to the smart contract
		uint256 up;//hoe many votes up are received
		uint256 down;
		mapping(address => bool) Voters;//keep track of the voters, so they can vote only once
	}

	event tickerupdated (
		uint256 up,
		uint256 down,
		address voter,
		string ticker
	);//event that is triggered when a ticker is updated, gives the number of  up and down votes, the voter and the ticker
	//gives us the current status of the moralis vote

mapping(string => ticker) private Tickers;

function addTicker(string memory _ticker) public {
//function to add ticker to smart contart
require(msg.sender == owner, "Only the owner can add tickers");

ticker storage newTicker = Tickers[_ticker];
newTicker.exists = true;
tickersArray.push(_ticker);
}

function vote(string memory _ticker, bool _vote) public {
//function to vote for a ticker
//first make sure that the ticker is present in the mapping
require(Tickers[_ticker].exists, "Cant vote on this coin");
//as long as the boolean is true we can vote
require(!Tickers[_ticker].Voters[msg.sender], "You have already voted for this coin");
//is false if the user hasnt voted yet

ticker storage t = Tickers[_ticker];
t.Voters[msg.sender] = true;

if(_vote){
	t.up++;
}
else{
	t.down++;
}
emit tickerupdated (t.up, t.down, msg.sender, _ticker);
//we get the current status of the vote
}	

function getVotes(string memory _ticker) public view returns(
	uint256 up,
	uint256 down
){
require(Tickers[_ticker].exists, "No such ticker defined");
ticker storage t = Tickers[_ticker];
return(t.up,t.down);
}

}