// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface INFTMinting {
    function balanceOf(
        address _address,
        uint256 _id
    ) external view returns (uint256);
}

import "@openzeppelin/contracts/access/Ownable.sol";

contract StateDAO is Ownable {
    string public stateName;
    uint256 public stateId;
    INFTMinting nftMinting;
    uint256 public totalNumberOfProposals;
    uint256 public votingPeriod = 60 seconds;
    uint256 public totalChild;

    enum Vote {
        Yes, // Yes = 0
        No // No = 1
    }

    struct Proposal {
        address proposedBy;
        string proposalType;
        string proposalTitle;
        uint256 timestamp;
        uint256 yayVotes;
        uint256 nayVotes;
        uint256 deadline;
        bool executed;
        mapping(address => bool) voters;
    }

    struct Child {
        uint256 childId;
        string chldName;
        address childDAO;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => Child) public children;

    constructor(
        string memory _stateName,
        uint256 _stateId,
        address _nftMinting
    ) {
        stateName = _stateName;
        stateId = _stateId;
        nftMinting = INFTMinting(_nftMinting);
    }

    /* Modifiers */
    modifier isMemberOfState() {
        require(
            nftMinting.balanceOf(msg.sender, stateId) == 1,
            "Not the member of this state."
        );
        _;
    }

    modifier isProposalActive(uint256 proposalId) {
        require(proposals[proposalId].deadline >= block.timestamp);
        _;
    }

    modifier isProposalEnded(uint256 proposalId) {
        require(proposals[proposalId].deadline <= block.timestamp);
        _;
    }

    /* Functions */

    /*
        Function addState:
        This function will allow the owner(representative) of the DAO,
        to add the state.
    */
    function addChild(
        uint256 _childId,
        string memory _childName,
        address _childAddress
    ) public onlyOwner returns (uint256) {
        uint256 childId = totalChild;
        children[childId] = Child(_childId, _childName, _childAddress);
        totalChild += 1;
        return childId;
    }

    /*
        Function removeState:
        This function will allow the owner(representative) of the DAO,
        to remive the state. 
    */
    function removeState(uint256 _childId) public onlyOwner {
        delete children[_childId];
        totalChild -= 1;
    }

    /*
        Function createProposal:
        Allows the member of the state to create a proposal.
        It takes two parametes type of proposal and title of proposal.
    */
    function createProposal(
        string memory typeOfProposal,
        string memory proposalTitle
    ) public isMemberOfState returns (uint256) {
        uint256 proposalId = totalNumberOfProposals;
        Proposal storage proposal = proposals[proposalId];
        proposal.proposedBy = msg.sender;
        proposal.proposalType = typeOfProposal;
        proposal.proposalTitle = proposalTitle;
        proposal.timestamp = block.timestamp;
        proposal.deadline = block.timestamp + votingPeriod;
        totalNumberOfProposals += 1;
        return proposalId;
    }

    /*
        Function voteOnProposal: 
        Allows the member of state to vote on any active proposal.
    */
    function vote(
        uint256 proposalId,
        Vote _vote
    ) public isMemberOfState isProposalActive(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        uint256 numVotes = 0;
        address voter = msg.sender;
        if (proposal.voters[voter] == false) {
            numVotes = 1;
            proposal.voters[voter] = true;
        }
        require(numVotes == 1, "Already Voted");

        if (_vote == Vote.Yes) {
            proposal.yayVotes += 1;
        } else proposal.nayVotes += 1;
    }

    /*
        Function executeProposal:
        Allows the owner of state to execute the proposal.
    */
    function executeProposal(
        uint256 proposalId
    ) public isProposalEnded(proposalId) onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        require(
            !(keccak256(abi.encodePacked(proposal.proposalType)) ==
                keccak256(abi.encodePacked("ELECTION"))),
            "Proposal is for election!"
        );
        if (proposal.yayVotes > proposal.nayVotes) {
            proposal.executed = true;
        }
    }

    /*
        Function executeElectionResult:
        Allows the owner to execute the owner to execute the result of the elections.
    */
    function executeElectionResult(
        address _newOwner,
        uint256 _proposalId
    ) public {
        Proposal storage proposal = proposals[_proposalId];
        require(
            keccak256(abi.encodePacked(proposal.proposalType)) ==
                keccak256(abi.encodePacked("ELECTION")),
            "Proposal is not of election!"
        );
        transferOwnership(_newOwner);
        proposal.executed = true;
    }

    /* 
        Function setStateName: Allows the owner of the user to change the state name.
    */
    function setStateName(string memory _stateName) public onlyOwner {
        stateName = _stateName;
    }

    /*
        Function updateVotingPeriod: Can be used to update the voting period by owner.
        Test in remix
    */
    function updateVotingPeriod(
        uint256 _days,
        uint256 _hours,
        uint256 _minutes
    ) public {
        votingPeriod = _days * 86400 + _hours * 3600 + _minutes * 60;
    }
}