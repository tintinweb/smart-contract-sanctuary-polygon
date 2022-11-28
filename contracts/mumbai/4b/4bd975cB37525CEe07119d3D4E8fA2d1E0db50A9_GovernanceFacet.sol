// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibAppStorage.sol";
import "../interfaces/IDAOToken.sol";

/// @dev this contract handles everything about Governance which entails
/// creating proposals by the admin, voting for proposals by the DAO members
contract GovernanceFacet {
    States internal states;

    /// Custom errors
    error notAdmin(string);
    error invalidTime(string);
    error proposalAlreadyCancelled();
    error alreadyVoted();
    error insufficientToken();
    error proposalIsCancelled();
    error noZeroAddressAllowed();
    error invalidProposal();
    error votingAlreadyStarted(string);
    error proposalEnded();
    error zeroValueNotAllowed();
    error maxVoteWeightNotSet();
    error voteWeightRangeExceeded();

    /// Events
    event ProposalCreated(address indexed user, string indexed name, uint256 indexed endTime);
    event ProposalCancelled(uint256 indexed _proposalID, uint256 indexed cancellationTime);
    event proposalVoted(address indexed voter, uint256 indexed proposalID, uint256 indexed voteType, uint256 voteWeight);
    event adminChanged(address newAdmin);
    event proposalEndTimeExtended(uint proposalID, uint newTime);
    event maxVoteWeightChanged(uint8 maxVoteWeight);

    /// @dev this function creates a proposal
    /// only an admin of the contract can create proposals
    function createProposal(string memory _name, uint256 _endTime) external {
        if (msg.sender != states.admin) {
            revert notAdmin("only admin required");
        }
        if (_endTime < block.timestamp) {
            revert invalidTime("invalid end time");
        }

        states.ID = states.ID + 1;
        Proposal storage newProposal = states.proposals[states.ID];

        newProposal.id = states.ID;
        newProposal.name = _name;
        newProposal.endTime = _endTime;
        states.proposalCount += 1;

        emit ProposalCreated(msg.sender, _name, _endTime);
    }

    /// @dev this function is used to cancel a proposal, given a proposalID
    /// only an admin of the contract can cancel proposals
    /// proposal can only be cancelled if voting hasn't started on that proposal
    function cancelProposal(uint256 _proposalID) external {
        if (msg.sender != states.admin) {
            revert notAdmin("only admin required");
        }
        if (states.proposals[_proposalID].cancelled == true) {
            revert proposalAlreadyCancelled();
        }
        if (states.proposals[_proposalID].voteCount > 0) {
            revert votingAlreadyStarted("Can't cancel an active proposal");
        }

        states.proposals[_proposalID].cancelled = true;
        uint256 cancellationTime = block.timestamp;

        emit ProposalCancelled(_proposalID, cancellationTime);
    }

    /// @dev this function is used to extend the endTime of a proposal provided the previous endTime
    /// is not reach. Once the previous endTime is reach, it is said that the proposal has already ended
    function extendProposalEndTime(uint256 _proposalID, uint256 _newEndTime) external {
        if (msg.sender != states.admin) {
            revert notAdmin("only admin required");
        }
        if (block.timestamp > states.proposals[_proposalID].endTime) {
            revert proposalEnded();
        }
        if (_newEndTime < block.timestamp) {
            revert invalidTime("invalid end time");
        }

        states.proposals[_proposalID].endTime = _newEndTime;

        emit proposalEndTimeExtended(_proposalID, _newEndTime);
    }

    function setMaxVoteWeight(uint8 _maxVoteWeight) external {
        if (msg.sender != states.admin) {
            revert notAdmin("only admin required");
        }
        if (_maxVoteWeight <= 0) {
            revert zeroValueNotAllowed();
        }
        states.maxVoteWeight = _maxVoteWeight;
        emit maxVoteWeightChanged(_maxVoteWeight);
    }

    /// @dev this function returns the maxVoteWeight
    function getMaxVoteWeight() external view returns (uint8 maxVoteWeight__) {
        maxVoteWeight__ = states.maxVoteWeight;
    }

    /// @dev this function returns all created proposals
    function getProposals() public view returns (Proposal[] memory) {
        uint256 currentProposalIndex = 0;
        Proposal[] memory allProposals = new Proposal[](states.proposalCount);

        for (uint256 i = 0; i < states.proposalCount; i++) {
            uint256 currentID = i + 1;
            Proposal storage currentProposal = states.proposals[currentID];
            allProposals[currentProposalIndex] = currentProposal;
            currentProposalIndex += 1;
        }

        return allProposals;
    }

    /// @dev this function returns the count(number) of total proposals created
    function proposalCount() external view returns (uint256) {
        return states.proposalCount;
    }

    /// @dev this function is used to vote for a proposal, given the proposalID
    /// it takes in a _voteType which can be 1 or 0 (one or zero):
    /// 1 is for a support vote, 0 is for an against vote
    /// it takes in a voteWeight which is equivalent to the number of votes a user is given
    /// users can only vote with a DAO token, and this token is burnt when user votes.
    /// the number of token burrnt is equivalent to the voteWeight a user used for voting.
    /// User can only vote once
    function voteProposal(uint256 _proposalID, uint256 _voteType, uint256 _voteWeight) external {
        // check if proposal is cancelled
        if (states.proposals[_proposalID].cancelled == true) {
            revert proposalIsCancelled();
        }
        // check if proposal has ended (using the endTime and current time)
        if (block.timestamp > states.proposals[_proposalID].endTime) {
            revert proposalEnded();
        }
        // check if this user has already voted for same proposal
        if (states.voted[msg.sender][_proposalID] == true) {
            revert alreadyVoted();
        }
        // check if maxVoteWeight is set
        if (states.maxVoteWeight <= 0) {
            revert maxVoteWeightNotSet();
        }
        if (_voteWeight <= 0) {
            revert zeroValueNotAllowed();
        }
        if (_voteWeight > states.maxVoteWeight) {
            revert voteWeightRangeExceeded();
        }
        if (IDAOToken(states.daoToken).balanceOf(msg.sender) < _voteWeight) {
            revert insufficientToken();
        }

        states.voteID = states.voteID + 1;

        uint256 burnAmount = _voteWeight * 1e18;
        IDAOToken(states.daoToken).burn(msg.sender, burnAmount);

        if (_voteType == 1) {
            states.proposals[_proposalID].support += _voteWeight;
        }

        if (_voteType == 0) {
            states.proposals[_proposalID].against += _voteWeight;
        }

        states.proposals[_proposalID].voteCount += _voteWeight;
        states.proposals[_proposalID].votersCount += 1;
        states.voted[msg.sender][_proposalID] = true;

        Vote storage newVote = states.votes[states.voteID];
        newVote.proposalID = _proposalID;
        newVote.voter = msg.sender;
        newVote.weight = _voteWeight;
        states.totalVoteCount += 1;

        emit proposalVoted(msg.sender, _proposalID, _voteType, _voteWeight);
    }

    /// @dev this function returns all the voter for a particular proposal given the proposalID
    function getVoters(uint256 _proposalID) public view returns (Vote[] memory) {
        uint256 currentVoterIndex = 0;
        uint256 votesCount = states.totalVoteCount;
        uint256 proposalVotersCount = 0;

        for (uint256 i = 0; i < votesCount; i++) {
            if (states.votes[i + 1].proposalID == _proposalID) {
                proposalVotersCount += 1;
            }
        }

        Vote[] memory allVoters = new Vote[](proposalVotersCount);

        for (uint256 i = 0; i < votesCount; i++) {
            if (states.votes[i + 1].proposalID == _proposalID) {
                uint256 currentID = i + 1;

                Vote storage currentVoter = states.votes[currentID];

                allVoters[currentVoterIndex] = currentVoter;
                currentVoterIndex += 1;
            }
        }

        return allVoters;
    }

    /// @dev this function returns total count votes done on this contract
    function totalVoteCount() external view returns (uint256) {
        return states.totalVoteCount;
    }

    /// @dev this function is used to change admin rights to another address
    /// only the current admin can call this function
    function changeAdmin(address _newAdmin) external {
        if (msg.sender != states.admin) {
            revert notAdmin("only admin required");
        }

        if (_newAdmin == address(0)) {
            revert noZeroAddressAllowed();
        }

        states.admin = _newAdmin;

        emit adminChanged(_newAdmin);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IDAOToken {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function burn(address _voter, uint256 _voting_power) external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

struct Proposal {
    uint256 id;
    string name;
    uint256 endTime;
    uint256 votersCount;
    uint256 voteCount;
    uint256 support;
    uint256 against;
    bool cancelled;
}

struct Vote {
    uint256 proposalID;
    address voter;
    uint256 weight;
}

struct States {
    mapping(uint256 => Proposal) proposals;
    mapping(address => mapping(uint256 => bool)) voted;
    mapping(uint256 => Vote) votes;
    uint256 ID;
    uint256 voteID;
    uint256 proposalCount;
    uint256 totalVoteCount;
    address admin;
    address daoToken;
    uint8 maxVoteWeight;
}