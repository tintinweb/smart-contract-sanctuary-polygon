//SPDX-License-Identifier: MIT
//lohtp

pragma solidity ^0.8.7;

//To make sure any address actually owns any of these valid tokens that gives
//right to vote in our DAO, we need to make an interface to the smart contract that 
//created these NFT tokens which keep track of the balance of any addresses that hold
//these tokens 

//Interfact function replicates the function that the OpenSea store front has
//It takes 2 parameters, an address and a unsigned integer 256 number and returns a
//uint256 figure which is the balance of this address for this token ID 
interface IdaoContract {
	function balanceOf(address, uint256) external view returns (uint256);
}

//Smart contract function
contract Dao {
	//Define smart contract functionality variables 
	//Store owner of smart conrtact in public viewable address variable
	//Anyone in the community or blockchain space can view the owner of this DAO
	address public owner;

	//Keep track of the next proposal ID so that every proposal that the community 
	//of the DAO puts forth will have a unique identifiable ID
	uint256 nextProposal;

	//Need to have an array that distinguishes which tokens are allowed to vote
	//on this DAO. To use token ID numbers that will allow users of the DAO to 
	//make votes and proposals on this smart contract
	uint256[] public validTokens;

	//Create a reference to the interface IdaoContract
	//Our DAO contract variable will actually run this functionality 
	IdaoContract daoContract;

	//Create a constructor function to identity what is the smart contract address to use
	//for our DAO contract interface
	constructor() {
		//Whoever that deploys the smart contact will become the owner of this DAO
		owner = msg.sender;

		//The first proposal created will have an ID of 1
		nextProposal = 1;

		//Smart contract address obtained from OpenSea. Use the smart contract address for OpenSea 
		//store front. Any time we call this smart contract, we can use this balanceOf function from that
		//smart contract
		//daoContract = IdaoContract(0x2953399124f0cbb46d2cbacd8a89cf0599974963);
		daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);

		//Token ID obtained from OpenSea. This makes sures that when we're creating a proposal or 
		//when we're voting, we make sure that the wallet address that's trying to make the vote or 
		//proposal actually holds this NFT in their wallet from this smart contract
		//This is the valid token ID that is able to access the DAO
		validTokens = [1053645697561675738019260933428680739577310971742119796745355799500079235073];
	}

	//Define structure that stores different variables 
	struct proposal {
		uint256 id;
		bool exists;
		string description;
		uint deadline;
		uint256 votesUp;
		uint256 votesDown;
		address[] canVote;
		uint256 maxVotes;
		mapping(address => bool) voteStatus;
		bool countConducted;
		bool passed; 
	}

	//Because the idea of DAO isthat anyone can view these proposals, they will be made public
	//All proposals stored on the smart contract has to be made public
	//Create a mapping that maps any unsigned 256 eg proposal ID to a proposal struct made public and call
	//this mapping as Proposals
	mapping (uint256 => proposal) public Proposals;

	//Create a few events that we can emit in our functions and then listen to with Moralis. When new proposals are
	//created or new votes are cast, these events are automatically synced to Moralis database and the data can be presented 
	//to the users via the DApp
	event proposalCreated (
		uint256 id,
		string description,
		uint256 maxVotes,
		address proposer
	);

	//Event to calculate the current status of voting for proposal, keep track of who has made the recent vote on
	//which proposal they made the vote on, did they vote for or against the proposal
	event newVote (
		uint256 votesUp,
		uint256 votesDown,
		address voter,
		uint256 proposal,
		bool votedFor
	);

	//The owner of the smart contract by the deadline or after the deadline of this proposal count the votes of 
	//of that proposal and it'll automatically update the proposal to be accepted or rejected. 
	//Event to determine if the proposal has passed and present the information in the DApp
	event proposalCount (
		uint256 id,
		bool passed
	);

	//This private functions will check the proposal eligibility. If someone is trying to create a proposal, this 
	//private function will check whether the user actually owns any of the NFTs that make them part of the DAO and allows
	//them to make proposals 
	//This private function takes in one address and returns true or false. It creates a for() loop that runs through 
	//all the valid tokens using the DAO contract function which is the interface to the OpenSea store front smart contract and
	//check whether the proposal holds any of the valid tokens and if they do, the function returns true 
	//In summary, this function checks the valid token array list against OpenSea store front smart contract whether the wallet 
	//that is trying to make a proposal is part of the DAO
	function checkProposalEligibility (address _proposalist) private view returns (
		bool
	){
		for (uint i=0; i<validTokens.length; i++) {
			if (daoContract.balanceOf (_proposalist, validTokens[i]) >= 1) {
				return true;
			}
		}
		return false;
	}

	//This private function will check whether a voter can vote on a specific proposal and returns true or false	
	function checkVoteEligibility (uint256 _id, address _voter) private view returns (
		bool
	){
		for (uint256 i=0; i<Proposals[_id].canVote.length; i++) {
			if (Proposals[_id].canVote[i] == _voter) {
				return true;
			}
		}
		return false;
	}

	//Create the following public function to generate an actual proposal into the smart contract
	//createProposal is the function name and it takes 2 parameters, description for that proposal and an array of 
	//addresses that can vote on this proposal
	//Need to use Moralis Web3 API to get the current status of NFT holders
	function createProposal (string memory _description, address[] memory _canVote) public {
		//Check the message sender actually holds one of the NFTs that is set in the valid tokens array 
		//If not, the message within the double quotes will be displayed
		require (checkProposalEligibility (msg.sender), "Only NFT holders can put forth Proposals");

		//Create a new proposal in the proposal array, nextProposal index starts from 1
		proposal storage newProposal = Proposals[nextProposal];
		newProposal.id = nextProposal;
		newProposal.exists = true;
		newProposal.description = _description;

		//To set the validity period of this proposal, 1000 is the time for 1000 blocks to be created onto the blockchain
		newProposal.deadline = block.number + 1000;
		newProposal.canVote = _canVote;
		newProposal.maxVotes = _canVote.length;

		//Emit the event on the smart contract in order to read this new proposal being created through Moralis
		emit proposalCreated (nextProposal, _description, _canVote.length, msg.sender);
		nextProposal++;
	}

	//Create the functionality for casting a vote on this proposal
	//Need a few statements to ensure voters do not vote on wrong or malicious proposals
	function voteOnProposal (uint256 _id, bool _vote) public {
		require(Proposals[_id].exists, "This Proposal does not exist");
		require(checkVoteEligibility(_id, msg.sender), "You cannot vote on this Proposal");
		require(!Proposals[_id].voteStatus[msg.sender], "You have already voted on this Proposal");
		require(block.number <= Proposals[_id].deadline, "The deadline has passed for this Proposal");

		proposal storage p = Proposals[_id];

		if(_vote){
			p.votesUp++;
		}else{
			p.votesDown++;
		}

		p.voteStatus[msg.sender] = true;

		//Emit the event on the smart contract in order to read this new vote being created through Moralis
		emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
	}

	//Function to count the votes to check whether the status of this proposal was passed or not
	function countVotes(uint256 _id) public {
		require(msg.sender == owner, "Only Owner Can Count Votes");
		require(Proposals[_id].exists, "This Proposal does not exist");

		//Ensure owner can only count the votes after the deadline
		require(block.number > Proposals[_id].deadline, "Voting has not concluded");
		require(!Proposals[_id].countConducted, "Count already conducted");

		proposal storage p = Proposals[_id];

		if(Proposals[_id].votesDown < Proposals[_id].votesUp){
			p.passed = true;
		}

		p.countConducted = true;

		//Emit the event on the smart contract in order to read this new proposal count being created through Moralis
		emit proposalCount(_id, p.passed);
	}

	//Function to add new valid tokens into smart contract if we want to have new DAO memberss that hold different NFTs
	//in the future
	function addTokenId(uint256 _tokenId) public {
		require(msg.sender == owner, "Only Owner Can Add Tokens");

		validTokens.push(_tokenId);
	}
}