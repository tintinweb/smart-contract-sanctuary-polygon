// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "./SafeMath.sol";

interface whataContract {
  function balanceOf(address, uint256) external view returns (uint256);
  function maxSupply(uint256) external view returns (uint256);
}


contract Dao {

  using SafeMath for uint;
  using SafeMath for uint256;

  address public owner;
  uint256 nextProposal;
  uint256[] public validTokens;
  whataContract daoContract;

  constructor(){
    owner = msg.sender;
    nextProposal = 1;
    daoContract = whataContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
    validTokens = [58097402891580513947560728452193072169778608589196942986704705987598270595087];
  }

  struct Proposal {
    uint256 id;
    bool exists;
    string description;
    uint deadline;
    uint256 votesUp;
    uint256 votesDown;
    uint256 maxVotes;
    mapping(address => bool) voteStatus;
    mapping(address => uint256) individualVotes;
    mapping(address => mapping(bool => uint256)) individualChoices;
    bool countConducted;
    bool passed;
    address proposedBy;
  }

  mapping(uint256 => Proposal) public proposalToId;

  Proposal[] public proposals;

  event proposalCreated(
    uint256 id,
    string description,
    uint256 maxVotes,
    address proposer
  );

  event newVotes(
    uint256 votesUp,
    uint256 votesDown,
    address voter,
    uint256 proposal,
    bool votedFor
  );

  event proposalCount(
    uint256 id,
    bool passed
  );

    function _getElegibility(address _proposer) private view returns (uint256 _balance){
        uint256 balance = 0;
        for (uint i = 0; i < validTokens.length; i++){
            balance = balance.add(daoContract.balanceOf(_proposer, validTokens[i]));
        }
        _balance = balance;
    }


    function viewVotingPower(address _member) public view returns (uint256 _votes){
      uint256 balance = 0;
        for (uint i = 0; i < validTokens.length; i++){
            balance = balance.add(daoContract.balanceOf(_member, validTokens[i]));
        }
        _votes = balance;
    }
    
    function createProposal(string memory _description, uint256  _deadline) public {
        uint256 balance = _getElegibility(msg.sender);
        require(balance > 0);
        require((_deadline > (block.timestamp.add(259200))) && (_deadline < block.timestamp.add(2419200)));

        uint256 _maxVotes = votePool();

        Proposal storage newProp = proposalToId[nextProposal];
        newProp = proposals[nextProposal];

        newProp.id = nextProposal;
        newProp.exists = true;
        newProp.description = _description;
        newProp.deadline = _deadline;
        newProp.votesUp = 0;
        newProp.votesDown = 0;
        newProp.maxVotes= _maxVotes;
        newProp.countConducted = false;
        newProp.passed = false;
        newProp.proposedBy = msg.sender;

        
        
        emit proposalCreated(nextProposal, _description, _maxVotes, msg.sender);
        nextProposal = nextProposal.add(1);
    }

    function votePool() public view returns (uint256 votes){
      uint256 _maxVotes = 0;
        for (uint i = 0; i < validTokens.length; i++){
          _maxVotes = _maxVotes.add(daoContract.maxSupply(validTokens[i]));
        }
        votes = _maxVotes;
    }

    
    function voteOnProposal(uint256 _id, uint256 _votesUp, uint256 _votesDown) public {

        Proposal storage p = proposalToId[_id];
        
        if (!(p.individualChoices[msg.sender][true] > 0)){
          p.individualChoices[msg.sender][true] = 0;
        }
        if (!(p.individualChoices[msg.sender][false] > 0)){
          p.individualChoices[msg.sender][false] = 0;
        }

        (uint256 votesRemaining, uint256 totalAvailableVotes) = checkVoteAvailability(_id, msg.sender);

        require((_votesUp + _votesDown) <= votesRemaining, 'You have cast too many votes than you are allotted');
        
        p.individualVotes[msg.sender] = p.individualVotes[msg.sender].add((_votesUp+_votesDown));    
        p.votesUp = p.votesUp.add(_votesUp);
        p.votesDown = p.votesDown.add(_votesDown);
        p.individualChoices[msg.sender][true] = p.individualChoices[msg.sender][true].add(_votesUp);
        p.individualChoices[msg.sender][false] = p.individualChoices[msg.sender][false].add(_votesDown);

        require((p.individualVotes[msg.sender] <= totalAvailableVotes), 'Something went wrong');

        if(p.individualVotes[msg.sender] == totalAvailableVotes){
            p.voteStatus[msg.sender] == true;
        }
        
        bool votedFor = (_votesUp > _votesDown);
        emit newVotes(_votesUp, _votesDown, msg.sender, _id, votedFor);
        
        if ((p.votesUp + p.votesDown) == p.maxVotes){
            _countVotes(_id);
        }
        
    }

    function checkVoteAvailability(uint256 _id, address _checkVoter) public view returns (uint256 _votesRemaining, uint256 _totalAvailableVotes){
        Proposal storage p = proposalToId[_id];
        require(p.exists, "This proposal does not exist");
        require(block.timestamp <= p.deadline, "The deadline has passed for this Proposal");
        uint256 voteCount = 0;
        for (uint i = 0; i < validTokens.length; i++){
            voteCount = voteCount.add(daoContract.balanceOf(_checkVoter, validTokens[i]));
        }
        

        _totalAvailableVotes = voteCount;
        _votesRemaining = (voteCount.sub((p.individualChoices[_checkVoter][true].add(p.individualChoices[_checkVoter][false]))));
    }


    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only owner can count votes");
        require(proposalToId[_id].exists, "This proposal does not exist");
        require(block.number > proposalToId[_id].deadline, "Voting has not concluded");
        require(!proposalToId[_id].countConducted, 'Count already conducted');

        _countVotes(_id);
    }

    function _countVotes(uint256 _id) internal {
        if(proposalToId[_id].votesUp > proposalToId[_id].votesDown){
            proposalToId[_id].passed = true;
            proposalToId[_id].countConducted = true;
        } else {
            proposalToId[_id].passed = false;
            proposalToId[_id].countConducted = true;
        }
        emit proposalCount(_id, proposalToId[_id].passed);
    }

    function addTokenId(uint256 _tokenId) public {
      require(msg.sender == owner, 'Only Owner Can Add Tokens');

      validTokens.push(_tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.7;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}