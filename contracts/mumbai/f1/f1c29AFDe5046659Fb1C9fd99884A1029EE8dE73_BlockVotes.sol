//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title A Decentralized Voting Smart Contract
/// @author Mide Sofek
/// @notice You can use this contract to create quick voting ballots
/// @notice BlockVotesNFT airdropped through ThirdWeb ContractKit is required to vote
/// @dev All function calls are currently implemented without side effects
/// @custom:testing stages. This contract is still undergoing tests.
// BlockVoteNFTCA: 0xb52B4b6401BD42fcE41a74566ab41BB8dece8E6e

// Interface for the BlockVotersNFT required to hold for Voting
// Only the two necessary functions are been interefaced here

interface IBlockVotersNFT {
    /// @dev balanceOf returns the number of NFTs owned by the given address
    /// @param owner - address to fetch number of NFTs for
    /// @return Returns the number of NFTs owned
    function balanceOf(address owner) external view returns (uint256);

    /// @dev tokenOfOwnerByIndex returns a tokenID at given index for owner
    /// @param owner - address to fetch the NFT TokenID for
    /// @param index - index of NFT in owned tokens array to fetch
    /// @return Returns the TokenID of the NFT
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}

contract BlockVotes {
    /// @notice A Struct to record candidates
    /// @dev Struct stores each Candidate's Data
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    /// @notice A Struct to enable pre-registration of voters
    /// @dev Struct tracks each voter's Data
    struct voter {
        string voterName;
        bool voted;
    }

    //**************VARIABLE DECLARATION***************//
    uint public candidatesCount;
    uint public timestamp;
    uint public voteDuration;
    bool public votingLive;
    // store accounts which have voted
    mapping(address => bool) public voters;
    // Store, Fetch & Map Candidate data into candidates
    // Store Candidate Count
    mapping(uint => Candidate) public candidates;

    IBlockVotersNFT blockVotersNFT;

    //************  EVENTS  ************//
    event votedEvent(uint indexed _candidateId);
    event voteStarted();

    //only the contract owner should be able to start voting
    address public owner;

    //************  MODIFIERS  ************//
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    // Requires a voter to Have at Least 1 NFT to qualify to vote
    modifier nftHolderOnly() {
        require(
            blockVotersNFT.balanceOf(msg.sender) > 0,
            "NOT_QUALIFIED_TO_VOTE"
        );
        _;
    }

    constructor(address _blockVotersNFT) {
        owner = msg.sender;
        timestamp = block.timestamp;
        votingLive = false;
        blockVotersNFT = IBlockVotersNFT(_blockVotersNFT);
    }

    //**************WRITABLE FUNCTIONS***************//

    /// @notice Starts Vote by Contract Owner
    /// @dev Duration is calculated in minutes
    /// @dev Function still at experimental stages
    /// @param voteMinutes is duration Voting will be available
    function startVote(uint voteMinutes) public onlyOwner {
        voteDuration = voteMinutes * 1 minutes;
        votingLive = true;

        //if(block.timestamp < voteDuration) {votingLive = false;}
        emit voteStarted();
    }

    /// @notice Is trigerred by owner to end voting
    function endVote() public onlyOwner {
        votingLive = false;
    }

    /// @notice Enables owner to add new candidates
    /// @dev Increments totalNumber of Candidates
    /// @dev Registers 'Candidate' then updates 'candidates' mapping
    /// @param _name takes name of each candidate (stored in memory)
    function addCandidate(string memory _name) public onlyOwner {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    /// @notice Enables qualified voters vote registered Candiates
    /// @dev Function checks sets of requirements
    // @param _candidateID represents unique ID of Candidate(voter intends to vote)
    function vote(uint _candidateId) public nftHolderOnly {
        // require that address hasn't voted before
        require(!voters[msg.sender], "Already voted!");
        //require voting is live
        require(votingLive == true, "Vote isn't Live");
        // require vote only for valid candidate
        require(
            _candidateId > 0 && _candidateId <= candidatesCount,
            "Not Found"
        );

        // require time duration for vote has not ended
        require(timestamp >= voteDuration, "Time is up");

        // record that voter has voted
        voters[msg.sender] = true;

        // update candidate vote count
        candidates[_candidateId].voteCount++;

        // trigger vote event
        emit votedEvent(_candidateId);
    }

    // @return total numbers of vote each candidates have
    function checkCandidateVote(uint _candidateId) public view returns (uint) {
        return candidates[_candidateId].voteCount;
    }

    /// @notice Lets user know if their vote has been counted
    function haveYouVoted() public view returns (bool) {
        return voters[msg.sender];
    }

    /// @notice Enable transfer of ownership
    function changeOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}