// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// The OpenSea.io store-front contract which created the NFT tokens
// keeps track of the balances of any addresses that hold the tokens
// used to validate that the user is a holder of the DAOs token
// address = user's wallet address
// uint256 = token id
// returns the balance of tokens
interface IdaoContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

//-------------------------------------------------------------------------------------------

contract Dao {
    address public owner; // this allows users to know who the owner of contract is

    // Every proposal put forth will have a unique id
    // This 'state' variable tracks the NEXT proposal's is.
    uint256 nextProposal;

    // array that distiquished which tokens are alowed to vote.
    uint256[] public validTokens;

    // reference to the interface
    // creates a variable of the interface's type
    // giving this contract access to the functionality of the OpenSea.io contract
    IdaoContract daoContract;

    // run only at deploy time
    constructor() {
        owner = msg.sender; // set the owner of the contract
        nextProposal = 1; // first proposal will be 1

        // address of the OpenSea store-front contract
        daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);

        // the DAOs token id (from OpenSea)
        // only users who hold this NFT-token in their wallet are allowed to vote.
        validTokens = [
            34885103611559094078416375598166902696017567311370712658413208238551126245396
        ];
    }

    struct proposal {
        uint256 id; // next proposal id
        bool exists; // T/F declares if this proposal actually exist
        string description; // description of the proposal
        uint deadline; // block number of the deadline to cast a vote
        uint256 votesUp; // total number of votes UP (Yes)
        uint256 votesDown; // total number of votes DOWN (No)
        address[] canVote; // array of address holding the required NFT token
        uint256 maxVotes; // the length of the canVote array, how many entries
        // dictionary: address and vote status, used to prevent on user from voting more than once.
        mapping(address => bool) voteStatus;
        // T/F have the votes been counted
        bool countConducted;
        // T/F has the proposal passed.
        bool passed;
    }

    // makes the 'proposal' struct accessable to the public
    // maps the proposal id, to a proposal in the 'proposal' struct
    mapping(uint256 => proposal) public Proposals;

    //--------------------------------------------------------------------------------------
    // EVENTS

    // events to emit
    // these event will be listened to by Moralis
    // then that data can be presented to the users throught the Dapp

    // emitted when a new proposal is created
    // maxVotes is the number of users (wallet address) qualified to vote for this proposal
    // proposer is the address of the user who proposed the proposal
    event proposalCreated(
        uint256 id,
        string description,
        uint256 maxVotes,
        address proposer
    );

    // will help determin the current status of voting on any proposal
    // votesUp is the total number of UP votes
    // votesDown is the total number of down votes
    // voter is the address of the user who made the latest vote.
    // proposal is the proposals id
    // votedFor is a boolean (T/F) did the user vote for or against the proposal
    event newVote(
        uint256 votesUp,
        uint256 votesDown,
        address voter,
        uint256 proposal,
        bool votedFor
    );

    // emits the vote results when the owner counts the votes for a proposal (after voting is closed)
    event proposalCount(uint256 id, bool passed);

    //---------------------------------------------------------------------------------------------
    // (Private) functions, only available internally by this contract

    // when someone attempts to create a proposal, this private function is used as
    // 'require' statements for the 'createProposal' function, to check wether the caller
    // actually ownes any of the NFTs that make them members of this DAO
    function checkProposalEligibility(address _proposalist)
        private
        view
        returns (bool)
    {
        // iterate through the list of valid tokens for DAO membership
        for (uint i = 0; i < validTokens.length; i++) {
            // use the interface to the OpenSea store front, validate that caller holds a membership token.
            if (daoContract.balanceOf(_proposalist, validTokens[i]) >= 1) {
                return true;
            }
        }
        return false;
    }

    // validate that the caller can vote on the proposal
    // return bool, so this function can be used as a require statement
    function checkVoteEligibility(uint256 _id, address _voter)
        private
        view
        returns (bool)
    {
        // taregeting the proposal from the list of proposals, by the passed-in id
        // iterates through the proposal's array of addresses that hold the required NFT token
        // if the caller's address is found in the array, return TRUE
        for (uint256 i = 0; i < Proposals[_id].canVote.length; i++) {
            if (Proposals[_id].canVote[i] == _voter) {
                return true;
            }
        }
        return false;
    }

    // function that actually creates the proposal
    // the passed-in list of address that can vote on this proposalis is used by
    // the moralisWeb3 API to get the current (vote) status of holders of the NFT
    function createProposal(
        string memory _description, // description for the new proposal
        address[] memory _canVote // list of address that can vote on the proposal
    ) public {
        // public, anyone can call this function as long as they pass-in the parameters
        require(
            checkProposalEligibility(msg.sender), // returns TRUE if caller holds one of the required NFT
            "Only NFT holders can put forth Proposals"
        );

        // create a new proposal in the proposal array

        // create a new, temporary proposal in the proposal array
        // Note: the nextProposal number is used as both the array items's index and the proposal's id
        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100; // current block number + 100 blocks gives the voting deadline
        newProposal.canVote = _canVote; // array of addresses that can votes, passed-in
        newProposal.maxVotes = _canVote.length; // number of entries in the canVote array of valid voting addresses

        emit proposalCreated( // event - emitted when a new proposal in created
            nextProposal, // new proposal's id
            _description, // new proposal's description
            _canVote.length, // number of addresses tht can vote on this proposal
            msg.sender // the address of the person who proposed the proposal
        );
        nextProposal++; // increment by 1 the 'state' variable to store the number for the NEXT proposal.
    }

    //--------------------------------------------------------------------------------

    // functionality for casting a vote

    // passed-in:
    //      the id of proposal caller want to vote on
    //      the caller vote: True (for the proposal), or False (against the proposal)
    function voteOnProposal(uint256 _id, bool _vote) public {
        // check in the proposal array that the exists element (boolean) is set to TRUE
        require(Proposals[_id].exists, "This Proposal does not exist");
        // check that the caller's address is in the proposal's canVote eligibility array
        require(
            checkVoteEligibility(_id, msg.sender),
            "You can not vote on this Proposal"
        );
        // check that caller has not voted on this proposal already
        require(
            !Proposals[_id].voteStatus[msg.sender],
            "You have already voted on this Proposal"
        );
        // check that the current block number of the BC is not higher than the set deadline for voting
        require(
            block.number <= Proposals[_id].deadline,
            "The deadline has passed for this Proposal"
        );

        // create an instance of the 'proposals' mapping, of the proposal caller is voting on
        // needed to store the caller's voteStatus
        proposal storage p = Proposals[_id];

        if (_vote) {
            // if caller is voting TRUE, implement the VotesUp counter by 1
            p.votesUp++;
        } else {
            // if caller is voting FALSE, increment the votesDown counter by 1
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true; // set the callers voteStatus too caller can vote more than once.

        // event emittance
        // current status of the proposals up and down vote count
        // caller's address
        // id of the proposal caller voted on
        // how the caller voted, TRUE or FALSE
        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
    }

    //---------------------------------------------------------------------------------------------------

    // owner ONLY functions

    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only Owner Can Count Votes");
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(
            block.number > Proposals[_id].deadline, // has the voting deadline expired
            "Voting has not concluded"
        );
        require(!Proposals[_id].countConducted, "Count already conducted");

        // create an instance of the mapping for the proposal whos votes are being counted
        proposal storage p = Proposals[_id];

        if (Proposals[_id].votesDown < Proposals[_id].votesUp) {
            // if more UP that DOWN votes, proposal passed
            p.passed = true;
        }

        p.countConducted = true; // set the boolean to TRUE, so votes can't be counted again

        // event emittance: the proposal's id and wether it passed or not
        emit proposalCount(_id, p.passed);
    }

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only Owner Can Add Tokens");
        // add an OpenSea token id to the validTokens array
        validTokens.push(_tokenId);
    }
}