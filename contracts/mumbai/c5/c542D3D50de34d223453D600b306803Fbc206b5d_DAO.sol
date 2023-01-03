/**
 *Submitted for verification at polygonscan.com on 2023-01-02
*/

/**
 *Submitted for verification at polygonscan.com on 2022-12-20
*/

pragma solidity ^0.8.16;

// This is the contract for our DAO.
contract DAO {
     // struct to represent a member
    struct Member {
        bool exists; // whether the member exists
        uint256 shares; // number of voting shares
    }

    // We'll use a struct to store information about each proposal.
    struct Proposal {
        // The proposal index.
        uint proposalIndex;
        // The address of the member who created the proposal.
        address proposer;
        // The proposal description.
        string description;
        // The number of "yes" votes.
        uint yesCount;
        // The number of "no" votes.
        uint noCount;
        // A flag to indicate whether the proposal has been approved or rejected.
        bool approved;
        //Submit Time for voting Period
        uint SubmitTime;
        //the flag to indicate whether the proposal has been proccessed or not
        bool processed;
    }

    // We'll use a mapping to store the proposals, with the proposal index as the key.
    mapping(uint => Proposal) public proposals;
    mapping (address => Member)public  members;
    // the minimum number of votes needed for a proposal to pass
    uint256 public minimumQuorum;

    // the minimum percentage of yes votes needed for a proposal to pass
    uint256 public minimumPercentage;

    // the number of seconds a proposal is active for
    uint256 public votingPeriod;

    // // We'll use an array to store the proposal indices, so that we can iterate over all the proposals.
    uint[] public proposalIndices;

    address public Owner;

    // We'll use a mapping to store the votes, with the proposal index as the key and the address of the voter as the value.
    mapping(uint => mapping(address => bool)) public Voted;

     // event emitted when a new proposal is submitted
    event SubmitProposal(uint256 proposalId, address proposer, string description);

    // event emitted when a proposal is voted on
    event SubmitVote(uint256 proposalId, address voter, bool vote);

    // event emitted when a proposal is processed
    event ProcessProposal(uint256 proposalId, bool result);
    
    modifier  onlyOwner(){
        require(msg.sender == Owner,"msg sender needs to be owner");
        _;
    }
     modifier onlyMember(){
        require(isMember(msg.sender),"msg sender needs to be member");
        _;
    }

    // This is the constructor function. It is called when the contract is deployed.
    constructor()  {
        // Add the contract creator as the first member of the DAO.
        members[msg.sender].exists= true;   
        Owner=msg.sender;
    }

     // This function allows any member to propose a new member.
    function proposeMember(address newMember) public onlyOwner {
        // // Only members can propose new members.
        // require(isMember(msg.sender), "Only members can propose new members.");
        require(!members[newMember].exists,"The member already existed");
        // Propose the new member.
        members[newMember].exists= true;
    }

    // This function allows any member to create a new proposal.
    function createProposal(string memory description) public onlyMember {
        // Only members can create proposals.
        // require(isMember(msg.sender), "Only members can create proposals.");

        // Get the next proposal index.
        uint proposalIndex = proposalIndices.length+1;

         // create the new proposal
        Proposal memory proposal = Proposal({
            proposalIndex:proposalIndex,
            proposer: msg.sender,
            description: description,
            yesCount: 0,
            noCount: 0,
            approved: false,
            SubmitTime:block.timestamp,
            processed:false
        });

        // add the proposal to the mapping
        proposals[proposalIndex] = proposal;

        // Add the proposal index to the proposal indices array.
        proposalIndices.push(proposalIndex);
         // emit the SubmitProposal event
        emit SubmitProposal(proposalIndex, msg.sender, description);
    }

    // This function allows any member to vote on a proposal.
    function vote(uint proposalIndex, bool vote) public onlyMember {
        // Only members can vote.
        //require(isMember(msg.sender), "Only members can vote.");

        // Get the proposal.
        Proposal storage proposal = proposals[proposalIndex];
        
        require(proposal.proposer != address(0), "Proposal does not exist");

        // check if the voting period is still active
        require(block.timestamp <= proposal.SubmitTime + votingPeriod, "Voting period has expired");
        
        // check if the msg.sender is already voted
        require(Voted[proposalIndex][msg.sender]==false,"The voter had already voted for the specific proposalId");
        // Increment the appropriate vote count.
        if (vote) {
            proposal.yesCount++;
        } else {
            proposal.noCount++;
        }

        // If the proposal has received more "yes" votes than "no" votes, mark it as approved.
        if (proposal.yesCount > proposal.noCount) {
            proposal.approved = true;
        }
        Voted[proposalIndex][msg.sender]=true;
    }

    // // This function returns the number of "yes" and "no" votes for a given proposal.
    // function getVoteCount(uint proposalIndex) public view returns (uint yes, uint no) {
    //     Proposal storage proposal = proposals[proposalIndex];
    //     yes = proposal.yesCount;
    //     no = proposal.noCount;
    // }

    // This is a helper function that checks if an address is a member of the DAO.
    function isMember(address addr) public view returns (bool) {
        // Iterate over all the members.
            if (members[addr].exists == true) {
                return true;
        }
        // If the given address is not a member, return false.
        return false;
    }
    function processProposal(uint256 proposalId) public onlyOwner {
        // get the proposal details
        Proposal storage proposal = proposals[proposalId];
        // check if the proposal exists
        require(proposal.proposer != address(0), "Proposal does not exist");
       require(proposal.processed == false,"Proposal has been already prossesed");
        require(block.timestamp >= proposal.SubmitTime + votingPeriod, "Voting period has expired");

        if (proposal.yesCount > proposal.noCount)
        {
            proposal.approved = true;
        }
        else{
           proposal.approved = false;
        }
        proposal.processed=true;
        emit  ProcessProposal(proposalId,proposal.approved);

    }

    function ChangeVotingPeriod(uint256 _votingPeriod)public onlyOwner {
        votingPeriod =_votingPeriod;
    }
    function getFinalResult(uint256 proposalId)public view returns(bool)
    {
        require(proposalId<=proposalIndices.length,"The proposalId not exites");
        Proposal storage proposal = proposals[proposalId]; 
        return(proposal.approved);
    }

}