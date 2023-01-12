// SPDX-License-Identifier: MIT

// 1. Error Handling
error Ballot__NotOwner();
error Ballot__UserVoted();
error Ballot__NoRightToVote();
error Ballot__SelDelegationDisallowed();

// 2. Pragma
pragma solidity ^0.8.9;
/**@title A sample Voting Contract
 * @author Ibrahim Shittu
 * @notice This contract is to create a voting contract where the chairman can 
 *         assign voting right to eligible s_voters
 */

contract Ballot {
    // This declares a new data type which will
    // be used for variables later.
    // It will represent a single voter.
    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        address delegate; // person delegated to
        uint vote;   // index of the voted proposal
    }

    // This is a type for a single proposal.
    struct Proposal {
        bytes32 name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    address private immutable i_owner;

    // This declares a state variable that
    // stores a `Voter` struct for each possible address.
    mapping(address => Voter) public s_voters;

    // A dynamically-sized array of `Proposal` structs.
    Proposal[] public s_proposals;

    ///////////////
    // MODIFIER //
    //////////////

    // An onlyOwner modifier that allows only the owner(i_owner) to call certain functions
    modifier onlyOwner() {
        // require(msg.sender == i_owner);
        if (msg.sender != i_owner) revert Ballot__NotOwner();
        _;
    }

    // Functions Order:
    //// constructor
    //// receive
    //// fallback
    //// external
    //// public
    //// internal
    //// private
    //// view / pure

    /// Create a new ballot to choose one of `proposalNames`.
    constructor(bytes32[] memory proposalNames) {
        i_owner = msg.sender;
        s_voters[i_owner].weight = 1;

        // For each of the provided proposal names,
        // create a new proposal object and add it
        // to the end of the array.
        for (uint i = 0; i < proposalNames.length; i++) {
            // `Proposal({...})` creates a temporary
            // Proposal object and `s_proposals.push(...)`
            // appends it to the end of `s_proposals`.
            s_proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    // The following two functions allow the contract to accept ETH deposits
    // directly from a wallet without calling a function
    receive() external payable {}

    fallback() external payable {}

    /**
     *  @notice Gives voter the right to vote and can only be called by the owner of the contract
     * @param voter the address of the voter
     */
    function giveRightToVote(address voter) external onlyOwner {
        // We set an onlyOwber modifier so only the i_owner can call this contract
        // Then check if the voter has voted if so, revert with a custom error
        // Also ensure the voter weight is zero 
        if(s_voters[voter].voted) revert Ballot__UserVoted();
        require(s_voters[voter].weight == 0);
        s_voters[voter].weight = 1;
    }

    /**
     * @notice This allows eligible voters delegate their vote to someone else
     * @param to the address of the delegated voter
     */
    function delegate(address to) external {
        // assigns reference
        Voter storage sender = s_voters[msg.sender];
        if(sender.weight ==0) revert Ballot__NoRightToVote();
        if(sender.voted) revert Ballot__UserVoted();
        if(to == msg.sender) revert Ballot__SelDelegationDisallowed();

        // Forward the delegation as long as
        // `to` also delegated.
        // In general, such loops are very dangerous,
        // because if they run too long, they might
        // need more gas than is available in a block.
        // In this case, the delegation will not be executed,
        // but in other situations, such loops might
        // cause a contract to get "stuck" completely.
        while (s_voters[to].delegate != address(0)) {
            to = s_voters[to].delegate;

            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, "Found loop in delegation.");
        }

        Voter storage delegate_ = s_voters[to];

        // s_voters cannot delegate to accounts that cannot vote.
        require(delegate_.weight >= 1);

        // Since `sender` is a reference, this
        // modifies `s_voters[msg.sender]`.
        sender.voted = true;
        sender.delegate = to;

        if (delegate_.voted) {
            // If the delegate already voted,
            // directly add to the number of votes
            s_proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += sender.weight;
        }
    }

     /**
     * @notice This allows eligible voters and votes delegated to them to vote for their preferred proposal
     * @param proposal the index of their preferred proposal chosen
     */
    function vote(uint proposal) external {
        Voter storage sender = s_voters[msg.sender];
        if(sender.weight ==0) revert Ballot__NoRightToVote();
        if(sender.voted) revert Ballot__UserVoted();
        // require(sender.weight != 0, "Has no right to vote");
        // require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;

        // If `proposal` is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        s_proposals[proposal].voteCount += sender.weight;
    }

    /**
     * @notice This calculates the votes and selects the winning proposal
     * @dev Computes the winning proposal taking all previous votes into account
     */
    function winningProposal() public view
            returns (uint winningProposal_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < s_proposals.length; p++) {
            if (s_proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = s_proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

     /**
     * @notice After all computation, this prints the winner name
     * @return winnerName_ the winner's name in bytes which can later be converted to string
     */
    function winnerName() external view
            returns (bytes32 winnerName_)
    {
        winnerName_ = s_proposals[winningProposal()].name;
    }

    /**
     * @notice this gets the adress of the owner of the contract
     */
    function getOwner() public view returns(address){
        return i_owner;
    }
}