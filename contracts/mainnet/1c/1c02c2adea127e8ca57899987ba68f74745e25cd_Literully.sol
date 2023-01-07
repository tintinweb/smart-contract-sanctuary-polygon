/**
 *Submitted for verification at polygonscan.com on 2023-01-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

interface ValidationContract {
    function validate(address walletAddress) external view returns (bool);
}

contract Literully {
    struct Poll {
        string question;
        string context;
        address owner;
        PollDates dates;
        PollSettings settings;
        PollOption[] options;
    }

    struct PollDates {
        uint256 created_at;
        uint256 end_at;
    }

    struct PollSettings {
        bool optionsRestricted;
        bool paused;
        address validationContractAddress;
    }

    struct PollOption {
        string option;
        string context;
        address owner;
        address[] voters;
    }

    struct Vote {
        bool voted;
        uint256 date;
        uint256 optionIndex;
    }

    address public owner;
    uint256 public pollCreationFee = 0;
    uint256 public totalPolls = 0;

    // pollId => Poll
    mapping(uint256 => Poll) private Polls;

    // pollId => address => optionIndex
    mapping(uint256 => mapping(address => Vote)) public PollVotes;

    // ** Events **
    event PollCreated(
        address indexed initiator,
        uint256 pollId,
        string question
    );
    event PollQuestionUpdated(
        address indexed initiator,
        uint256 pollId,
        string previousQuestion,
        string newQuestion
    );
    event PollPaused(
        address indexed initiator,
        uint256 pollId,
        bool pausedState
    );

    event PollOptionCreated(
        address indexed initiator,
        uint256 pollId,
        uint256 optionIndex
    );

    event PollVoted(
        address indexed initiator,
        uint256 pollId,
        uint256 optionIndex
    );

    receive() external payable {}

    constructor(uint256 _pollCreationFee) {
        pollCreationFee = _pollCreationFee;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyPollOwner(uint256 _pollId) {
        require(msg.sender == Polls[_pollId].owner, "Only poll owner");
        _;
    }

    modifier isPollValid(uint256 _pollId) {
        Poll memory currentPoll = Polls[_pollId];
        require(currentPoll.owner != address(0), "Poll does not exist");
        require(
            currentPoll.settings.paused == false,
            "Poll was paused by owner"
        );
        require(currentPoll.dates.end_at > block.timestamp, "Poll is finished");
        _;
    }

    function changeFeeAmount(uint256 _amount) public onlyOwner {
        pollCreationFee = _amount;
    }

    function withdraw(uint256 _amount, address payable _toAddress)
        public
        onlyOwner
    {
        _toAddress.transfer(_amount);
    }

    /**
		Create a poll

		_question - the original question 
		_end_at - Date when the poll will be closed
		_optionsRestricted - if set to true, only owner can create options
		_validationContractAddress - if set other than zero address, every time user votes it will call the validate function passing as an 
		argument address and will wait until it received boolean true, if no will be reverted
		_optionsArray - predefined options from poll owner
	**/
    function createPoll(
        string memory _question,
        string memory _context,
        uint256 _end_at,
        bool _optionsRestricted,
        address _validationContractAddress,
        string[] memory _optionsArray,
        string[] memory _contextArray
    ) public payable returns (uint256) {
        require(msg.value >= pollCreationFee, "Creating poll requires fee");
        require(_end_at > block.timestamp, "End date is wrong");

        Poll storage currentPoll = Polls[totalPolls];

        currentPoll.question = _question;
        currentPoll.context = _context;
        currentPoll.owner = msg.sender;
        currentPoll.dates = PollDates({
            created_at: block.timestamp,
            end_at: _end_at
        });
        currentPoll.settings = PollSettings({
            optionsRestricted: _optionsRestricted,
            paused: false,
            validationContractAddress: _validationContractAddress
        });

        for (
            uint256 optionIndex = 0;
            optionIndex < _optionsArray.length;
            optionIndex++
        ) {
            PollOption memory predefinedOption;
            predefinedOption.option = _optionsArray[optionIndex];
            predefinedOption.context = _contextArray[optionIndex];
            predefinedOption.owner = msg.sender;
            currentPoll.options.push(predefinedOption);
        }

        emit PollCreated(msg.sender, totalPolls, _question);
        totalPolls += 1;
        return totalPolls - 1;
    }

    /**
		Pause or Resume the poll

		Poll owner can pause or Resume the poll but the event will be thrown

		_pollId - Poll id
		_paused - State => if true - paused, false - live
	**/
    function pauseOrResumePoll(uint256 _pollId, bool _paused)
        public
        onlyPollOwner(_pollId)
    {
        Poll storage currentPoll = Polls[_pollId];

        emit PollPaused(msg.sender, _pollId, _paused);
        currentPoll.settings.paused = _paused;
    }

    /**
		Create poll option

		Poll can be optionsRestrected which will lead only owner to create options,
		othewise anyone can create

		_pollId - Poll id
		__option - Option string
	**/
    function createOption(
        uint256 _pollId,
        string memory _option,
        string memory _context
    ) public isPollValid(_pollId) {
        Poll storage currentPoll = Polls[_pollId];
        require(
            currentPoll.settings.optionsRestricted == false ||
                msg.sender == currentPoll.owner,
            "Only owner can create options"
        );

        PollOption memory newPollOption;
        newPollOption.option = _option;
        newPollOption.context = _context;
        newPollOption.owner = msg.sender;
        emit PollOptionCreated(msg.sender, _pollId, currentPoll.options.length);
        currentPoll.options.push(newPollOption);
    }

    /**
		Vote

		As simple as you can understand, this is the core of the contract

		_pollId - Poll id
		_optionIndex - Option Index
	**/
    function vote(uint256 _pollId, uint256 _optionIndex)
        public
        isPollValid(_pollId)
    {
        Poll storage currentPoll = Polls[_pollId];
        require(
            currentPoll.options[_optionIndex].owner != address(0),
            "Poll option does not exist"
        );

        if (currentPoll.settings.validationContractAddress != address(0)) {
            bool validation = ValidationContract(
                currentPoll.settings.validationContractAddress
            ).validate(msg.sender);
            require(validation == true, "Custom validation failed");
        }

        require(PollVotes[_pollId][msg.sender].voted == false, "Already voted");

        PollVotes[_pollId][msg.sender] = Vote({
            voted: true,
            date: block.timestamp,
            optionIndex: _optionIndex
        });
        emit PollVoted(msg.sender, _pollId, _optionIndex);
        currentPoll.options[_optionIndex].voters.push(msg.sender);
    }

    /**
			Read only functions section started
	**/
    struct PollForRead {
        string question;
        string context;
        address owner;
        uint256 totalVotes;
        uint256 totalOptions;
        bool finished;
        PollDates dates;
        PollSettings settings;
        PollOptionsRead[] options;
    }

    struct PollOptionsRead {
        string option;
        string context;
        address owner;
        uint256 totalVotes;
    }

    function getPoll(uint256 _pollId) public view returns (PollForRead memory) {
        Poll memory currentPoll = Polls[_pollId];
        require(currentPoll.owner != address(0), "Poll not initialized");
        PollForRead memory pollInfo;
        pollInfo.question = currentPoll.question;
        pollInfo.context = currentPoll.context;
        pollInfo.owner = currentPoll.owner;
        pollInfo.totalOptions = currentPoll.options.length;
        pollInfo.totalVotes = 0;
        pollInfo.options = new PollOptionsRead[](currentPoll.options.length);
        pollInfo.finished = currentPoll.dates.end_at < block.timestamp;

        for (
            uint256 optionIndex = 0;
            optionIndex < currentPoll.options.length;
            optionIndex++
        ) {
            if (currentPoll.options[optionIndex].owner == address(0)) {
                break;
            }
            pollInfo.totalVotes += currentPoll
                .options[optionIndex]
                .voters
                .length;
            pollInfo.options[optionIndex] = PollOptionsRead({
                option: currentPoll.options[optionIndex].option,
                context: currentPoll.options[optionIndex].context,
                owner: currentPoll.options[optionIndex].owner,
                totalVotes: currentPoll.options[optionIndex].voters.length
            });
        }

        pollInfo.dates = PollDates({
            created_at: currentPoll.dates.created_at,
            end_at: currentPoll.dates.end_at
        });

        pollInfo.settings = PollSettings({
            optionsRestricted: currentPoll.settings.optionsRestricted,
            paused: currentPoll.settings.paused,
            validationContractAddress: currentPoll
                .settings
                .validationContractAddress
        });

        return pollInfo;
    }

    function getVotersByOptionId(uint256 _pollId, uint256 _optionIndex)
        public
        view
        returns (address[] memory)
    {
        Poll memory currentPoll = Polls[_pollId];
        return currentPoll.options[_optionIndex].voters;
    }

    function getQuestions(uint256 skip, uint256 limit) public view returns (string[] memory) {

        string[] memory questions = new string[](limit);
        uint256 counter = 0;
         for (uint256 pollId = skip; pollId < (skip + limit); pollId++) {
            if (Polls[pollId].owner != address(0)) {
                questions[counter] = Polls[pollId].question;
                counter++;
            } else {
                break;
            }
        }
        return questions;
    }
}