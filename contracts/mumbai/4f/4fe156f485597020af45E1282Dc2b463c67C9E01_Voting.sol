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
pragma solidity ^0.8.9;

interface IVoting {
    struct ElectionInfo{
        string name;
        uint year;
        uint numberOfVoters;
        bool stateElections;
        bool nationalElections;
    }
    struct Candidates {
        uint candidateId;
        string candidateName;
        string party;
        uint votesReceived;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IVoting.sol";

contract Voting is IVoting{
    event Voted(
        address indexed voter,
        bool hasVoted
    );
    event VotersAdded(
        uint numberOfVoters
    );
    event CandidatesAdded(
        uint numberOfCandidates
    );

   uint numberOfVoters;
 
    struct VoterInfo {
        bool hasVoted;
        uint startTime;
        uint endTime;
    }

    bool votersAdded;

    uint public totalCandidates;
    uint public totalVoters;
    uint public totalVotesCasted;

    address[] private voterAddressList;
    Candidates[] public aboutCandidates;

    mapping(address => VoterInfo) public voterInfoMapping;

    ElectionInfo public info;
    address public immutable owner;

    modifier onlyOwner(address user){
       require(user == owner);
       _;
    }

    constructor(ElectionInfo memory _info, address _owner ){
        info = ElectionInfo(_info.name, _info.year, _info.numberOfVoters, _info.stateElections, _info.nationalElections);
        owner = _owner;
    }

// getter

    function candidatesList() public view returns(Candidates[] memory){
        return aboutCandidates;
    }
    function votersList() public view returns(address[] memory) {
        return voterAddressList;
    }

// setter

    function addCandidates(Candidates[] memory _candidates) public onlyOwner(msg.sender) {
        uint i;
        for(i=0; i < _candidates.length; i+=1) {
            require(i == _candidates[i].candidateId && _candidates[i].votesReceived==0, 
            "constructor: Wrong input for candiate");
            
            aboutCandidates.push(_candidates[i]);
        }
        totalCandidates = i+1;
        emit CandidatesAdded(totalCandidates);
    }

    function addVoters(address[] memory _voters, uint[] memory _startTime, uint[] memory _endTime) public onlyOwner(msg.sender){
        require(votersAdded == false, "addVoters: Voter's list already updated");

        for(uint i=0; i < _voters.length; i+=1) {
            voterInfoMapping[_voters[i]] = VoterInfo(false, _startTime[i], _endTime[i]);
            voterAddressList.push(_voters[i]);
        }
         
        votersAdded = true;
        totalVoters = _voters.length;
        emit VotersAdded(_voters.length);
    }

    function castVote(uint _candidateId) public {
        require(voterInfoMapping[msg.sender].hasVoted == false, "castVote: Already Voted");
        require(block.timestamp > voterInfoMapping[msg.sender].startTime, "castVote: Not started");
        require(block.timestamp < voterInfoMapping[msg.sender].endTime, "castVote: expired");

        aboutCandidates[_candidateId].votesReceived +=1;
        voterInfoMapping[msg.sender].hasVoted = true;
        totalVotesCasted +=1;
        emit Voted(msg.sender, voterInfoMapping[msg.sender].hasVoted);
    }
}