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
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./BimDaoProposal.sol";


/// @title DAO BIM
/// @author BIM
/// @notice managing BIM DAO
contract BimDao is Ownable {

    mapping (string => uint256) public proposalbook;

    BimDaoProposal[] private proposals;

    constructor() {}

    event newProposal(BimDaoProposal proposal);

    event proposalResult(BimDaoProposal proposal, string proposalName, bool result);

    /// @notice Create a proposal
    /// @param _proposalName The name associated to the proposal*
    /// @param _duration The duration of the proposal
    function createProposal(string memory _proposalName, uint256 _duration) external onlyOwner {
        require(proposalbook[_proposalName] == 0, "Proposal already exists");
        BimDaoProposal proposal = new BimDaoProposal(_proposalName, _duration);
        proposalbook[_proposalName] = proposals.length;
        proposals.push(proposal);
        emit newProposal(proposal);
    }

    /// @notice Get the number of proposals
    /// @return The number of proposals
    function getNbProposals() external view returns (uint256) {
        return proposals.length;
    }

    /// @notice Get nbProposals addresses starting from startId
    /// @param startId The index of the first proposal to get
    /// @param nbProposals The number of proposals to get
    /// @return The proposals
    function getProposals(uint256 startId, uint256 nbProposals) external view returns (BimDaoProposal[] memory) {
        require(startId + nbProposals <= proposals.length, "Not enough proposals");
        BimDaoProposal[] memory votesRes = new BimDaoProposal[](nbProposals);
        for (uint256 i = 0; i < nbProposals; i++) {
            votesRes[i] = proposals[startId + i];
        }
        return votesRes;
    }

    /// @notice Get the address of a proposal
    /// @param _proposalId The id associated to the proposal
    /// @return The proposal
    function getProposalFromId(uint256 _proposalId) external view returns (BimDaoProposal) {
        require(_proposalId < proposals.length, "Proposal does not exist");
        return proposals[_proposalId];
    }

    /// @notice Get the address of a proposal
    /// @param _proposalName The name associated to the proposal
    /// @return The proposal
    function getProposalFromName(string memory _proposalName) external view returns (BimDaoProposal) {
        require(proposals.length > 0, "Proposal does not exist");
        return proposals[proposalbook[_proposalName]];
    }

    /// @notice Set the result of a proposal
    /// @param _proposalId The id of the proposal
    /// @param _result The result of the proposal
    function setProposalResultFromId(uint256 _proposalId, bool _result) external onlyOwner {
        require(_proposalId < proposals.length, "Proposal does not exist");
        BimDaoProposal proposal = proposals[_proposalId];
        proposal.setResult(_result);
        emit proposalResult(proposal, proposal.name(), _result);
    }

    /// @notice Set the result of a proposal
    /// @param _proposalName The name associated to the proposal
    /// @param _result The result of the proposal
    function setProposalResultFromName(string memory _proposalName, bool _result) external onlyOwner {
        require(proposals.length > 0, "Proposal does not exist");
        BimDaoProposal proposal = proposals[proposalbook[_proposalName]];
        proposal.setResult(_result);
        emit proposalResult(proposal, proposal.name(), _result);
    }

    /// @notice Get the results of a list of proposals
    /// @param startId The index of the first proposal to get
    /// @param nbProposals The number of proposals to get
    /// @return The results of the proposals
    function getProposalsResult(uint256 startId, uint256 nbProposals) external view returns (bool[] memory) {
        require(startId + nbProposals <= proposals.length, "Not enough proposals");
        bool[] memory results = new bool[](nbProposals);
        for (uint256 i = 0; i < nbProposals; i++) {
            results[i] = proposals[startId + i].getResult();
        }
        return results;
    }

    /// @notice Get the result of a proposal
    /// @param _proposalId The id of the proposal
    function getProposalResultFromId(uint256 _proposalId) external view returns (bool) {
        require(_proposalId < proposals.length, "Proposal does not exist");
        return proposals[_proposalId].getResult();
    }


    /// @notice Get the result of a proposal
    /// @param _proposalName The name associated to the proposal
    function getProposalResultFromName(string memory _proposalName) external view returns (bool) {
        require(proposals.length > 0, "Proposal does not exist");
        return proposals[proposalbook[_proposalName]].getResult();
    }

    /// @notice Get the number of voters of a list of proposals
    /// @param startId The index of the first proposal to get
    /// @param nbProposals The number of proposals to get
    /// @return A list of number of voters
    function getProposalsNbVoters(uint256 startId, uint256 nbProposals) external view returns (uint256[] memory) {
        require(startId + nbProposals <= proposals.length, "Not enough proposals");
        uint256[] memory nbVoters = new uint256[](nbProposals);
        for (uint256 i = 0; i < nbProposals; i++) {
            nbVoters[i] = proposals[startId + i].getNbVoters();
        }
        return nbVoters;
    }

    /// @notice Get the number of voters of a proposal
    /// @param _proposalId The id of the proposal
    /// @return nbVoters The number of voters
    function getProposalNbVotersFromId(uint256 _proposalId) external view returns (uint256) {
        require(_proposalId < proposals.length, "Proposal does not exist");
        return proposals[_proposalId].getNbVoters();
    }

    /// @notice Get the number of voters of a proposal
    /// @param _proposalName The name associated to the proposal
    /// @return The number of voters
    function getProposalNbVotersFromName(string memory _proposalName) external view returns (uint256) {
        require(proposals.length > 0, "Proposal does not exist");
        return proposals[proposalbook[_proposalName]].getNbVoters();
    }

    /// @notice Get the voters of a proposal
    /// @param _proposalId The id of the proposal
    /// @return The addresses of the voters
    function getProposalVotersFromId(uint256 _proposalId) external view returns (address[] memory) {
        require(_proposalId < proposals.length, "Proposal does not exist");
        return proposals[_proposalId].getAllVoters();
    }

    /// @notice Get the voters of a proposal
    /// @param _proposalName The name associated to the proposal
    /// @return The addresses of the voters
    function getProposalVotersFromName(string memory _proposalName) external view returns (address[] memory) {
        require(proposals.length > 0, "Proposal does not exist");
        return proposals[proposalbook[_proposalName]].getAllVoters();
    }

    /// @notice Get the block height of multiples of proposals
    /// @param startId index of the first proposal to get
    /// @param nbProposals number of proposals to get
    function getProposalsBlockHeight(uint256 startId, uint256 nbProposals) external view returns (uint256[] memory) {
        require(startId + nbProposals <= proposals.length, "Not enough proposals");
        uint256[] memory blockHeights = new uint256[](nbProposals);
        for (uint256 i = 0; i < nbProposals; i++) {
            blockHeights[i] = proposals[startId + i].blockHeight();
        }
        return blockHeights;
    }

    /// @notice Get the BlockHeight of a proposal
    /// @param _proposalId The id associated to the proposal
    function getProposalBlockHeightFromId(uint256 _proposalId) external view returns (uint256) {
        require(_proposalId < proposals.length, "Proposal does not exist");
        return proposals[_proposalId].blockHeight();
    }

    /// @notice Get the BlockHeight of a proposal
    /// @param _proposalName The name associated to the proposal
    function getProposalBlockHeightFromName(string memory _proposalName) external view returns (uint256) {
        require(proposals.length > 0, "Proposal does not exist");
        return proposals[proposalbook[_proposalName]].blockHeight();
    }

    /// @notice Get the timestampStart of multiples proposals
    /// @param startId index of the first proposal to get
    /// @param nbProposals number of proposals to get
    function getProposalsTimestampStart(uint256 startId, uint256 nbProposals) external view returns (uint256[] memory) {
        require(startId + nbProposals <= proposals.length, "Not enough proposals");
        uint256[] memory timestampStarts = new uint256[](nbProposals);
        for (uint256 i = 0; i < nbProposals; i++) {
            timestampStarts[i] = proposals[startId + i].timestampStart();
        }
        return timestampStarts;
    }

    /// @notice Get the timestampStart of a proposal
    /// @param _proposalId The id associated to the proposal
    function getProposalTimestampStartFromId(uint256 _proposalId) external view returns (uint256) {
        require(_proposalId < proposals.length, "Proposal does not exist");
        return proposals[_proposalId].timestampStart();
    }

    /// @notice Get the timestampStart of a proposal
    /// @param _proposalName The name associated to the proposal
    function getProposalTimestampStartFromName(string memory _proposalName) external view returns (uint256) {
        require(proposals.length > 0, "Proposal does not exist");
        return proposals[proposalbook[_proposalName]].timestampStart();
    }

    /// @notice Get the timestampEnd of multiples proposals
    /// @param startId index of the first proposal to get
    /// @param nbProposals number of proposals to get
    function getProposalsTimestampEnd(uint256 startId, uint256 nbProposals) external view returns (uint256[] memory) {
        require(startId + nbProposals <= proposals.length, "Not enough proposals");
        uint256[] memory timestampEnds = new uint256[](nbProposals);
        for (uint256 i = 0; i < nbProposals; i++) {
            timestampEnds[i] = proposals[startId + i].timestampEnd();
        }
        return timestampEnds;
    }

    /// @notice Get the timestampEnd of a proposal
    /// @param _proposalId The id associated to the proposal
    function getProposalTimestampEndFromId(uint256 _proposalId) external view returns (uint256) {
        require(_proposalId < proposals.length, "Proposal does not exist");
        return proposals[_proposalId].timestampEnd();
    }

    /// @notice Get the timestampEnd of a proposal
    /// @param _proposalName The name associated to the proposal
    function getProposalTimestampEndFromName(string memory _proposalName) external view returns (uint256) {
        require(proposals.length > 0, "Proposal does not exist");
        return proposals[proposalbook[_proposalName]].timestampEnd();
    }

    /// @notice Get the vote time of multiples proposals
    /// @param startId index of the first proposal to get
    /// @param nbProposals number of proposals to get
    function getProposalsVoteTime(uint256 startId, uint256 nbProposals) external view returns (uint256[] memory) {
        require(startId + nbProposals <= proposals.length, "Not enough proposals");
        uint256[] memory voteTimes = new uint256[](nbProposals);
        for (uint256 i = 0; i < nbProposals; i++) {
            voteTimes[i] = proposals[startId + i].timestampEnd() - proposals[startId + i].timestampStart();
        }
        return voteTimes;
    }

    /// @notice Get the vote time of a proposal
    /// @param _proposalId The id associated to the proposal
    function getProposalVoteTimeFromId(uint256 _proposalId) external view returns (uint256) {
        require(_proposalId < proposals.length, "Proposal does not exist");
        return proposals[_proposalId].timestampEnd() - proposals[_proposalId].timestampStart();
    }

    /// @notice Get the vote time of a proposal
    /// @param _proposalName The name associated to the proposal
    function getProposalVoteTimeFromName(string memory _proposalName) external view returns (uint256) {
        require(proposals.length > 0, "Proposal does not exist");
        return proposals[proposalbook[_proposalName]].timestampEnd() - proposals[proposalbook[_proposalName]].timestampStart();
    }

    /// @notice Get the status of multiples proposals
    /// @param startId index of the first proposal to get
    /// @param nbProposals number of proposals to get
    function getProposalsStatus(uint256 startId, uint256 nbProposals) external view returns (uint256[] memory) {
        require(startId + nbProposals <= proposals.length, "Not enough proposals");
        uint256[] memory statuses = new uint256[](nbProposals);
        for (uint256 i = 0; i < nbProposals; i++) {
            statuses[i] = proposals[startId + i].getStatus();
        }
        return statuses;
    }

    /// @notice Get the status of a proposal
    /// @param _proposalId The id associated to the proposal
    function getProposalStatusFromId(uint256 _proposalId) external view returns (uint256) {
        require(_proposalId < proposals.length, "Proposal does not exist");
        return proposals[_proposalId].getStatus();
    }

    /// @notice Get the status of a proposal
    /// @param _proposalName The name associated to the proposal
    function getProposalStatusFromName(string memory _proposalName) external view returns (uint256) {
        require(proposals.length > 0, "Proposal does not exist");
        return proposals[proposalbook[_proposalName]].getStatus();
    }

    /// @notice Get the name of multiples proposals
    /// @param startId index of the first proposal to get
    /// @param nbProposals number of proposals to get
    function getProposalsName(uint256 startId, uint256 nbProposals) external view returns (string[] memory) {
        require(startId + nbProposals <= proposals.length, "Not enough proposals");
        string[] memory names = new string[](nbProposals);
        for (uint256 i = 0; i < nbProposals; i++) {
            names[i] = proposals[startId + i].name();
        }
        return names;
    }

    /// @notice Get the name of a proposal
    /// @param _proposalId The id associated to the proposal
    function getProposalNameFromId(uint256 _proposalId) external view returns (string memory) {
        require(_proposalId < proposals.length, "Proposal does not exist");
        return proposals[_proposalId].name();
    }

    /// @notice Get if an address has voted for multiples proposals
    /// @param startId index of the first proposal to get
    /// @param nbProposals number of proposals to get
    /// @param _voter The address of the voter
    function getProposalsHasVoted(uint256 startId, uint256 nbProposals, address _voter) external view returns (bool[] memory) {
        require(startId + nbProposals <= proposals.length, "Not enough proposals");
        bool[] memory voters = new bool[](nbProposals);
        for (uint256 i = 0; i < nbProposals; i++) {
            voters[i] = proposals[startId + i].hasVoted(_voter);
        }
        return voters;
    }

    /// @notice Get if an address has voted for a proposal
    /// @param _proposalId The id associated to the proposal
    /// @param _voter The address of the voter
    function getProposalHasVotedFromId(uint256 _proposalId, address _voter) external view returns (bool) {
        require(_proposalId < proposals.length, "Proposal does not exist");
        return proposals[_proposalId].hasVoted(_voter);
    }

    /// @notice Get if an address has voted for a proposal
    /// @param _proposalName The name associated to the proposal
    /// @param _voter The address of the voter
    function getProposalHasVotedFromName(string memory _proposalName, address _voter) external view returns (bool) {
        require(proposals.length > 0, "Proposal does not exist");
        return proposals[proposalbook[_proposalName]].hasVoted(_voter);
    }

    /// @notice Get the vote decision of multiples addresses
    /// @param startId index of the first proposal to get
    /// @param nbProposals number of proposals to get
    /// @param _voter The address of the voter
    function getProposalsVoterDecision(uint256 startId, uint256 nbProposals, address _voter) external view returns (bool[] memory) {
        require(startId + nbProposals <= proposals.length, "Not enough proposals");
        bool[] memory votes = new bool[](nbProposals);
        for (uint256 i = 0; i < nbProposals; i++) {
            votes[i] = proposals[startId + i].decision(_voter);
        }
        return votes;
    }

    /// @notice Get the vote decision of an address
    /// @param _proposalId The id associated to the proposal
    /// @param _voter The address of the voter
    function getProposalVoterDecisionFromId(uint256 _proposalId, address _voter) external view returns (bool) {
        require(_proposalId < proposals.length, "Proposal does not exist");
        return proposals[_proposalId].decision(_voter);
    }

    /// @notice Get the vote decision of an address
    /// @param _proposalName The name associated to the proposal
    /// @param _voter The address of the voter
    function getProposalVoterDecisionFromName(string memory _proposalName, address _voter) external view returns (bool) {
        require(proposals.length > 0, "Proposal does not exist");
        return proposals[proposalbook[_proposalName]].decision(_voter);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Proposal of BIM DAO
/// @author BIM
/// @notice Proposal of BIM DAO
contract BimDaoProposal is Ownable{

    mapping (address => bool) public hasVoted;

    mapping (address => bool) public decision;

    address[] public votersAddress;

    uint256 public timestampStart;

    uint256 public timestampEnd;

    uint256 public blockHeight;

    string public name;

    uint256 private result;

    constructor(string memory _name, uint256 _duration) {
        name = _name;
        timestampStart = block.timestamp;
        timestampEnd = timestampStart + _duration;
        blockHeight = block.number;
    }

    /// @notice Proposal for the proposal
    /// @param _vote true for yes and false for no
    function voteProposal(bool _vote) external {
        require(block.timestamp < timestampEnd, "Proposal is over");
        require(!hasVoted[msg.sender], "You have already voted");
        hasVoted[msg.sender] = true;
        if(_vote)
            decision[msg.sender] = _vote;
        votersAddress.push(msg.sender);
    }

    /// @notice Set the result of the proposal
    /// @param _result true for yes and false for no
    function setResult(bool _result) external onlyOwner {
        require(block.timestamp > timestampEnd, "Proposal is not over yet");
        result = (_result ? 1 : 2);
    }

    /// @notice Get the number of voters
    /// @return The number of voters
    function getNbVoters() external view returns (uint256) {
        return votersAddress.length;
    }

    /// @notice Get nbVoters addresses starting from startId
    /// @param startId The index of the first voter to get
    /// @param nbVoters The number of voters to get
    /// @return The list of addresses of the voters
    function getVoters(uint256 startId, uint256 nbVoters) external view returns (address[] memory) {
        require(startId + nbVoters <= votersAddress.length, "Not enough voters");
        address[] memory voters = new address[](nbVoters);
        for (uint256 i = 0; i < nbVoters; i++) {
            voters[i] = votersAddress[startId + i];
        }
        return voters;
    }

    /// @notice Get the addresses of a list of voters
    /// @return The list of addresses of the voters
    function getAllVoters() external view returns (address[] memory) {
        return votersAddress;
    }

    /// @notice Get the result of the proposal true for yes and false for no
    /// @return The result of the proposal, true for yes and false for no
    function getResult() external view returns (bool) {
        require(result > 0, "Result is not determined yet");
        return result == 1;
    }

    /// @notice Get status of the proposal
    /// @return The status of the proposal, 0 for ongoing, 1 for yes, 2 for no, 3 for finished without result yet
    function getStatus() external view returns (uint256) {
        if(result > 0)
            return result;
        if(block.timestamp > timestampEnd)
            return 3;
        return 0;
    }

  
}