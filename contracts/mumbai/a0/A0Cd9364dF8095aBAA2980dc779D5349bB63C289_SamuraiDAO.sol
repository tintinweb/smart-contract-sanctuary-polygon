/**
 *Submitted for verification at polygonscan.com on 2023-05-12
*/

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: contracts/dao.sol



pragma solidity ^0.8.0;


interface IERC721 {
    function balanceOf(address _owner) external view returns (uint256);
}

contract SamuraiDAO is ReentrancyGuard {
    struct Proposal {
        string title;
        string proposal;
        address proposalOwner;
        uint32 yesVote;
        uint32 noVote;
        address[] supporter;
        address[] opponent;
        bool status;
    }

    // Variables
    uint32 public proposalCount;
    address public erc721Contract;
    address public owner;

    //mappings
    mapping (uint32 => Proposal) public proposals;
    mapping (uint32 => mapping (address => uint32)) votedPower;
    mapping (uint32 => mapping(address => bool)) hasVoted;

    constructor() {
        owner = msg.sender;
    }

    // Events
    event CreateProposal(uint32 indexed id, address indexed proposalOwner, string title, string proposal);
    event VoteForProposal(uint32 indexed id, address indexed voter, bool vote);

    function setDefaultCollection(address _collection) public onlyOwner {
        erc721Contract = _collection;
    }
    function changeProposalStatus(uint32 _id, bool status) public onlyOwner {
        proposals[_id].status = status;
    } 

    // New Proposal
    function submitProposal(string memory _title, string memory _proposal) public {
        //Require
        require(getNFTBalance(msg.sender) > 0, "You must own at least one NFT to submit a proposal");
         ++proposalCount;
        require(proposals[proposalCount].status == false);

       
        proposals[proposalCount] = Proposal(_title, _proposal, msg.sender, 0, 0, new address[](0), new address[](0), true);
        emit CreateProposal(proposalCount, msg.sender, _title, _proposal);
    }

    function getNFTBalance(address _owner) public view returns (uint256) {
        return IERC721(erc721Contract).balanceOf(_owner);
    }

    // New Vote
    function voteForProposal(uint32 _id, bool _vote) public nonReentrant {
        // Require
        require(proposals[_id].status == true, "Proposal is not active");
        require(hasVoted[_id][msg.sender] == false, "You already voted for this proposal");

        uint256 votingPower = getNFTBalance(msg.sender);
        if (_vote) {
            proposals[_id].yesVote += uint32(votingPower);
            proposals[_id].supporter.push(msg.sender);
        } else {
            proposals[_id].noVote += uint32(votingPower);
            proposals[_id].opponent.push(msg.sender);
        }
        hasVoted[_id][msg.sender] = true;
        votedPower[_id][msg.sender] = uint32(votingPower);
        emit VoteForProposal(_id, msg.sender, _vote);
    }

    // Views
    function getProposalStatus(uint32 _id) public view returns (bool) {
        return proposals[_id].status;
    }

    function getProposalVotes(uint32 _id) public view returns (uint32, uint32) {
        return (proposals[_id].yesVote, proposals[_id].noVote);
    }

    function getSupporters(uint32 _id) public view returns (address[] memory) {
        return proposals[_id].supporter;
    }

    function getOpponents(uint32 _id) public view returns (address[] memory) {
        return proposals[_id].opponent;
    }

    function getVotingPower(uint32 _id, address _voter) public view returns (uint) {
    return votedPower[_id][_voter];
    }

    // Modifier for Admin
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
}