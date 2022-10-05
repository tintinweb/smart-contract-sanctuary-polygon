//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Forum {

  struct Question {
    uint questionId;
    string message;
    address creatorAddress;
    uint timestamp;
  }

  struct Answer {
    uint answerId;
    uint questionId;
    address creatorAddress;
    string message;
    uint timestamp;
    uint upvotes;
  }

  Question[] public questions;
  Answer[] public answers;
  mapping (uint => uint[]) public answersPerQuestion;

  // Keeps track of which users have upvoted an answer
  // We use this to prevent a user from upvoting more than once
  mapping (uint => mapping(address => bool)) public upvoters;
  // Keeps track of how many upvotes the user has given
  // This could be used to reward "SUPER TIPPERS" 
  mapping (address => uint) public usersUpvoteCount;

  event QuestionAdded(Question question);
  event AnswerAdded(Answer answer);
  event AnswerUpvoted(Answer answer);

  IERC20 public immutable Forumcash;
  uint constant decimals = 18;
  
  uint amountToPay = 1 * 10**decimals;
  uint amountToParticipate = 10 * 10**decimals;

  constructor(address _tokenAddress) {
    Forumcash = IERC20(_tokenAddress);
  }

  // We created a modifier to avoid duplicating code.
  // We can add it to function declarations to check conditions
  // before continuing with the function, indicated by the _;
  modifier answerExists(uint _answerId) {
    require(answers.length >= _answerId, 'Answer does not exist!');
    _;
  }

  function postQuestion(string calldata _message) external {
    uint questionCounter = questions.length;
    Question memory question = Question({
      questionId: questionCounter,
      message: _message,
      creatorAddress: msg.sender,
      timestamp: block.timestamp
    });
    questions.push(question);
    emit QuestionAdded(question);
  }

  function postAnswer(uint _questionId, string calldata _message) external {
    uint answerCounter = answers.length;
    Answer memory answer = Answer({
      answerId: answerCounter,
      questionId: _questionId,
      creatorAddress: msg.sender,
      message: _message,
      timestamp: block.timestamp,
      upvotes: 0
    });
	// we use an answer array and an answersPerQuestion mapping to store answerIds for each question.
	// This makes it easier for us to fetch the answers based on a questionId
    answers.push(answer); 
    answersPerQuestion[_questionId].push(answerCounter);
    emit AnswerAdded(answer);
  }

  function upvoteAnswer(uint _answerId) external answerExists(_answerId) {
    Answer storage currentAnswer = answers[_answerId]; 

    require(upvoters[_answerId][msg.sender] != true, 'User already upvoted this answer!');
    require(answers[_answerId].creatorAddress != msg.sender, 'Cannot upvote own answer!');
    require(Forumcash.balanceOf(msg.sender) >= amountToPay, 'User has insufficient balance!');
    require(Forumcash.allowance(msg.sender, address(this)) >= amountToPay, 'Account did not approve token succesfully!');
    
    bool sent;
    if (Forumcash.balanceOf(currentAnswer.creatorAddress) >= amountToParticipate) {
      sent = Forumcash.transferFrom(msg.sender, currentAnswer.creatorAddress, amountToPay); 
    } else {
      sent = Forumcash.transferFrom(msg.sender, address(this), amountToPay); 
    }

    require(sent, "Token transfer failed!");
    currentAnswer.upvotes++;
    usersUpvoteCount[msg.sender]++;
    upvoters[_answerId][msg.sender] = true;
    emit AnswerUpvoted(currentAnswer);
  }

  function getQuestions() external view returns (Question[] memory) {
    return questions;
  }

  function getAnswersPerQuestion(uint _questionId) public view returns (uint[] memory) {
    return answersPerQuestion[_questionId];
  }

  function getUpvotes(uint _answerId) public view answerExists(_answerId) returns (uint) {
    return answers[_answerId].upvotes;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}