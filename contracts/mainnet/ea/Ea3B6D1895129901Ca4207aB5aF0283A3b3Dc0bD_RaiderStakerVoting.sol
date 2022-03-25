//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface RaiderStakingLocking { 
  function addressStakedBalance(address _address) external view returns (uint);
  function showLockTimeRemaining(address _address) external view returns (uint);
}

contract RaiderStakerVoting is Ownable, Pausable {
  mapping(uint256 => mapping(uint8 => uint256)) public totalVotes; // ident to choice to amount voted
  mapping(address => mapping(uint256 => uint8)) public stakerVotes; // voter to ident to choice voted
  mapping(address => uint256) public votesPerAddress; //voter to staked balance voted with
  mapping(uint256 => uint8[]) public questionsToAnswers; //ident to available choices

  mapping(uint8 => uint8) public winners; //ident to choice

  uint8 public constant QUESTION_1_IDENT = 1;
  uint8 public constant QUESTION_2_IDENT = 2;
  uint256 public voteCloseTime;

  RaiderStakingLocking immutable internal stakingContract;

  // EVENTS

  event Voted(address indexed _from, uint amt, uint8 indexed questionOneAnswer, uint8 indexed questionTwoAnswer);
  event VoteBalanceExtended(address indexed _from, uint amt);
  event WinnerDeclared(uint8 questionIdent, uint8 questionAnswer);

  // Constructor

  constructor(address stakingAddress, uint256 _voteCloseTime, uint8[] memory questionOneAnswers, uint8[] memory questionTwoAnswers) {
    require(_voteCloseTime >= block.timestamp,"Time must be in future");
    require(stakingAddress != address(0),"Valid address required");
    require(questionOneAnswers.length != 0,"Valid answers for Q1 required");
    //require(questionTwoAnswers.length != 0,"Valid answers for Q2 required");

    stakingContract = RaiderStakingLocking(stakingAddress);
    voteCloseTime = _voteCloseTime;
    questionsToAnswers[1] = questionOneAnswers;
    questionsToAnswers[2] = questionTwoAnswers;
  }

   modifier isOpen {
      require(block.timestamp < voteCloseTime,"Voting closed");
      _;
   }

   modifier validIdent(uint8 ident) {
     require(questionsToAnswers[ident].length != 0, "Invalid Question Ident");
     _;
   }

  function vote(uint8 questionOneAnswer, uint8 questionTwoAnswer) external isOpen whenNotPaused {
    uint thisBalance = stakingContract.addressStakedBalance(msg.sender);
    require(questionOneAnswer != 0,"Valid Answer required");
    require(votesPerAddress[msg.sender] == 0, "You have already voted");
    require(thisBalance > 0,"Not a staker");
    require(stakingContract.showLockTimeRemaining(msg.sender) > timeUntilClose(), "Your lockup ends before voting closes");
    stakerVotes[msg.sender][QUESTION_1_IDENT] = questionOneAnswer;
    stakerVotes[msg.sender][QUESTION_2_IDENT] = questionTwoAnswer;

    votesPerAddress[msg.sender] = thisBalance;


    totalVotes[QUESTION_1_IDENT][questionOneAnswer] += thisBalance;
    totalVotes[QUESTION_2_IDENT][questionTwoAnswer] += thisBalance;

    emit Voted(msg.sender, thisBalance, questionOneAnswer, questionTwoAnswer);
  }

  function timeUntilClose() public view isOpen returns(uint) {
    return voteCloseTime - block.timestamp;
  }

  function checkForTies(uint8 questionIdent) public view validIdent(questionIdent) returns (bool){
    uint256 lastNumber = 0;
    for(uint i = 0; i < questionsToAnswers[questionIdent].length; i++){
      uint8 thisChoice = questionsToAnswers[questionIdent][i];
      uint256 thisVal = totalVotes[questionIdent][thisChoice];
      if (thisVal != 0 && thisVal == lastNumber) {
        return true;
      }
      lastNumber = thisVal;
    }

    return false;
  }

  function extendStake() external isOpen whenNotPaused {
    require(votesPerAddress[msg.sender] > 0,"You must have voted already");
    uint thisBalance = stakingContract.addressStakedBalance(msg.sender);
    require(thisBalance > votesPerAddress[msg.sender],"Your balance must have grown");


    uint256 diff = thisBalance - votesPerAddress[msg.sender];

    votesPerAddress[msg.sender] += diff;

    totalVotes[QUESTION_1_IDENT][stakerVotes[msg.sender][QUESTION_1_IDENT]] += diff;
    totalVotes[QUESTION_2_IDENT][stakerVotes[msg.sender][QUESTION_2_IDENT]] += diff;
    emit VoteBalanceExtended(msg.sender, diff);
  }

  function updateClosingTime(uint256 newTime) external onlyOwner {
    voteCloseTime = newTime;
  }

  function getHighestVoteCount(uint8 questionIdent) public view validIdent(questionIdent) returns(uint8) {
    require(!checkForTies(questionIdent),"Tied!");
    uint256 biggestAmount = 0;
    uint8 biggestIdent = 0;

    for(uint256 i = 0; i < questionsToAnswers[questionIdent].length; i++){
      uint8 thisChoice = questionsToAnswers[questionIdent][i];
      uint256 thisVal = totalVotes[questionIdent][thisChoice];
      //No tie check needed again.
      
      if (thisVal > biggestAmount) {
        biggestIdent = thisChoice;
        biggestAmount = thisVal;
      }
    }

    return biggestIdent;
  }


  function declareWinner(uint8 questionIdent) external onlyOwner validIdent(questionIdent) returns(uint8) {
    require(block.timestamp > voteCloseTime,"Voting must be closed");
    uint8 result = getHighestVoteCount(questionIdent);
    require(result != 0,"No Winner yet");
    winners[questionIdent] = result;
    emit WinnerDeclared(questionIdent, result);
    return winners[questionIdent];
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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