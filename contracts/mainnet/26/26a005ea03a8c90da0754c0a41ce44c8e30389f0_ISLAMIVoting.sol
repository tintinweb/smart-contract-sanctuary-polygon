/**
 *Submitted for verification at polygonscan.com on 2023-01-31
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: Contracts/ISLAMIvote.sol



//ISLAMI voting contract based on user balace in wallet


pragma solidity ^0.8.17;




contract ISLAMIVoting {

    address public owner;
    IERC20 public ISLAMI;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    uint256 private answerCount;

    uint256 public votingEventID;
    bool public votingEventLive = false;

/*
@dev: Voting System
*/
    struct VoteOptions{
        string voteOption;
        uint256 voteCount;
    }
    struct VoteEvent{
        uint256 eventID;
        string question;
        mapping(uint256 => VoteOptions) answers;
        uint256 status;
        string winner;
    }
    struct forVote{
        bool voted;
        uint256 votedForEvent;
    }

    event ChangeOwner(address NewOwner);
    event Voted(uint256 VotingEvent, uint256 Answer, address Voter, uint256 Power);
    event VoteResults(uint256 VotingEvent, string projectName, string Result);


    mapping(uint256 => VoteEvent) public Event;
    mapping(address => forVote) public user; 

    /* @dev: Check if contract owner */
    modifier onlyOwner (){
        require(msg.sender == owner, "Only ISLAMI owner can set vote options");
        _;
    }
/*
    @dev: prevent reentrancy when function is executed
*/
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    constructor(IERC20 _islami) {
        owner = msg.sender;
        votingEventID = 0;
        ISLAMI = _islami;
        _status = _NOT_ENTERED;
    }

/*
    @dev: Change the contract owner
*/
    function transferOwnership(address _newOwner)external onlyOwner{
        require(_newOwner != address(0x0),"Zero Address");
        emit ChangeOwner(_newOwner);
        owner = _newOwner;
    }

/*
    @dev: used by set c=voting events
*/
    function addToVote(uint256 _eventID, string memory _option) internal{
        answerCount++;
        require(votingEventLive == true,"No Live Event!");
        Event[_eventID].answers[answerCount].voteOption = _option;
    } 

/*
    @dev: Add voting project and start the voting event
*/
    function setVotingEvent(string memory _question, string memory o1, string memory o2, string memory o3) external onlyOwner{
        votingEventID++;
        votingEventLive = true;
        Event[votingEventID].eventID = votingEventID;
        Event[votingEventID].question = _question;
        Event[votingEventID].status = 1; //Voting event is Active
        addToVote(votingEventID, o1);
        addToVote(votingEventID, o2);
        addToVote(votingEventID, o3);
    }
    /*
    @dev: add vote value submitted by user
*/
    function newVote(uint256 _eventID,uint256 _answer, uint256 _power) internal{
        Event[_eventID].answers[_answer].voteCount += _power;
    }
/*
     @dev: Check voting results.
*/
    function checkVoteResult(uint256 _eventID) internal{
        if(Event[_eventID].answers[1].voteCount > 
           Event[_eventID].answers[2].voteCount &&
           Event[_eventID].answers[1].voteCount >
           Event[_eventID].answers[3].voteCount){
               Event[_eventID].winner = Event[_eventID].answers[1].voteOption;
               return();
        }
        else if(Event[_eventID].answers[2].voteCount > 
                Event[_eventID].answers[1].voteCount &&
                Event[_eventID].answers[2].voteCount >
                Event[_eventID].answers[3].voteCount){
                    Event[_eventID].winner = Event[_eventID].answers[2].voteOption;
                    return();
        }
        else if(Event[_eventID].answers[3].voteCount > 
                Event[_eventID].answers[1].voteCount &&
                Event[_eventID].answers[3].voteCount >
                Event[_eventID].answers[2].voteCount){
                    Event[_eventID].winner = Event[_eventID].answers[3].voteOption;
                    return();
        }
        else{
            Event[_eventID].winner = "N/A";
        }
    }
    function eventResults() public view returns(uint256, string memory, string memory,uint,string memory,uint,string memory,uint){
        uint256 _eventID = votingEventID;
        string memory _question = Event[_eventID].question;
        return(_eventID, _question,
        Event[_eventID].answers[1].voteOption,
        Event[_eventID].answers[1].voteCount,
        Event[_eventID].answers[2].voteOption,
        Event[_eventID].answers[2].voteCount,
        Event[_eventID].answers[3].voteOption,
        Event[_eventID].answers[3].voteCount);
    }    
    function endVotingEvent() external onlyOwner{
        require(Event[votingEventID].status != 0,"Already ended");
        answerCount = 0;
        //Zero means voting event has ended
        Event[votingEventID].status = 0;
        checkVoteResult(votingEventID);
        votingEventLive = false;
        emit VoteResults(votingEventID, Event[votingEventID].question, Event[votingEventID].winner);
    }

/*
    @dev: Voting for projects
    user can vote only once in an event
    user power is calculated with respect to wallet token balance
*/
    function voteFor(uint256 _answer) public nonReentrant{
        uint256 _balance = ISLAMI.balanceOf(msg.sender);
        uint256 _req = 100000*10**5;
        require(_balance >= _req*10**2," you need to have at least 100000 ISLAMI");
        uint256 _eventID = votingEventID;
        uint256 _votedEvent = user[msg.sender].votedForEvent;
        uint256 _votingPower = (_balance/_req);
        if(_eventID > _votedEvent){
            user[msg.sender].voted == false;
        }
        else{
            revert("Already Voted!");
        }
        require(votingEventLive == true,"No voting event");
        user[msg.sender].voted = true;
        user[msg.sender].votedForEvent = _eventID;
        newVote(_eventID, _answer, _votingPower);
        emit Voted(_eventID, _answer, msg.sender, _votingPower);
    }
    
}


               /*********************************************************
                  Proudly Developed by MetaIdentity ltd. Copyright 2023
               **********************************************************/