/**
 *Submitted for verification at polygonscan.com on 2023-05-06
*/

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: contracts/newpoll.sol


pragma solidity ^0.8.0;


contract Poll {
    using Counters for Counters.Counter;
    Counters.Counter public latestCreatedPoll;
    struct Option {
        uint256 id;
        string name;
        uint256 voteCount;
    }

    struct PollData {
        address owner;
        string title;
        string description;
        Option[] options;
        mapping(address => bool) hasVoted;
        bool hasDisabled;
    }

    mapping(uint256 => PollData) public Polls;
    mapping(address => uint256[]) public ownerToPollsID;

    modifier validPollId(uint256 _pollId) {
        require(
            _pollId > 0 && _pollId <= latestCreatedPoll.current(),
            "Invalid Poll ID"
        );
        _;
    }

    modifier onlyOwner(uint256 _pollId) {
        require(Polls[_pollId].owner == msg.sender, "Only owner can modify");
        _;
    }

    event PollCreated(
        uint256 indexed pollId,
        string title,
        string description,
        string[] optionNames
    );

    event VoteCast(
        uint256 indexed pollId,
        address indexed voter,
        uint256 indexed optionId
    );

    event PollDeleted(uint indexed pollId, address owner);

    event PollModified(uint256 indexed pollId);
    
    function getPollsWithOptions(uint pollId) external view returns(string memory,string memory, string[] memory) {
   
        PollData storage poll = Polls[pollId];
        string[] memory _options = new string[](poll.options.length);

        for(uint i = 0; i <poll.options.length;i++) {
            _options[i] = poll.options[i].name;
        }

        return (poll.title,poll.description,_options);

    }

    function createPoll(
        string memory _title,
        string memory _description,
        string[] memory _optionNames
    ) external {
        require(bytes(_title).length > 0, "Poll: Title should not be empty");
        require(
            bytes(_description).length > 0,
            "Poll: Desciption should not be empty"
        );
        require(_optionNames.length > 1, "Poll: options should be atleast 2");
        latestCreatedPoll.increment();
        Option[] memory options = new Option[](_optionNames.length);

        PollData storage pollData = Polls[latestCreatedPoll.current()];
        pollData.owner = msg.sender;
        pollData.title = _title;
        pollData.description = _description;

        for (uint256 i = 0; i < _optionNames.length; i++) {
            options[i] = Option(i + 1, _optionNames[i], 0);
            pollData.options.push(options[i]);
        }

        emit PollCreated(
            latestCreatedPoll.current(),
            _title,
            _description,
            _optionNames
        );
    }

    function modifyPoll(
        uint256 _pollId,
        string memory _title,
        string memory _description,
        string[] memory _optionNames
    ) external validPollId(_pollId) onlyOwner(_pollId) {
        require(!Polls[_pollId].hasDisabled, "The poll is already ended");
        PollData storage poll = Polls[_pollId];

        poll.title = _title;
        poll.description = _description;
        // Update options
        for (uint256 i = 0; i < _optionNames.length; i++) {
            if (i < poll.options.length) {
                // If an existing option is being updated, update its name
                poll.options[i].name = _optionNames[i];
            } else {
                // If a new option is being added, push it to the options array with vote count set to 0
                poll.options.push(
                    Option({
                        id: poll.options.length + 1,
                        name: _optionNames[i],
                        voteCount: 0
                    })
                );
            }
        }

        // Remove extra options
        for (uint256 i = _optionNames.length; i < poll.options.length; i++) {
            // If there are more options in the existing poll than in the updated list, remove the extra options
            poll.options.pop();
        }

        // Emit PollModified event to indicate that the poll has been modified
        emit PollModified(_pollId);
    }

    function deletePoll(
        uint256 _pollId
    ) external validPollId(_pollId) onlyOwner(_pollId) {
        require(!Polls[_pollId].hasDisabled, "The Poll is already disabled");
        PollData storage poll = Polls[_pollId];
        poll.hasDisabled = true;

        emit PollDeleted(_pollId, msg.sender);
    }

    function castVote(
        uint256 _pollId,
        uint256 _optionId
    ) external validPollId(_pollId) {
        require(!Polls[_pollId].hasDisabled, "The poll is closed");
        require(
            !Polls[_pollId].hasVoted[msg.sender],
            "The user has already voted"
        );
        require(
            _optionId > 0 && _optionId <= Polls[_pollId].options.length,
            "Option ID invalid"
        );

        Polls[_pollId].options[_optionId - 1].voteCount++;
        Polls[_pollId].hasVoted[msg.sender] = true;

        emit VoteCast(_pollId, msg.sender, _optionId);
    }

    function getPollResult(
        uint256 _pollId
    ) external view validPollId(_pollId) returns (string[] memory winners) {
        PollData storage poll = Polls[_pollId];
        uint256 maxVoteCount = 0;
        uint256 numWinners = 0;
        string[] memory winningOptions = new string[](poll.options.length);

        for (uint256 i = 0; i < poll.options.length; i++) {
            if (poll.options[i].voteCount > maxVoteCount) {
                maxVoteCount = poll.options[i].voteCount;
                winningOptions[0] = poll.options[i].name;
                numWinners = 1;
            } else if (poll.options[i].voteCount == maxVoteCount) {
                winningOptions[numWinners] = poll.options[i].name;
                numWinners++;
            }
        }

        winners = new string[](numWinners);
        for (uint256 i = 0; i < numWinners; i++) {
            winners[i] = winningOptions[i];
        }

        return winners;
    }

    function getTotalNumberOfVotes(
        uint256 _pollId
    )
        external
        view
        validPollId(_pollId)
        returns (uint256 totalVotes, uint256[] memory allVotes)
    {
        PollData storage poll = Polls[_pollId];
        uint256 pollLength = poll.options.length;
        uint256[] memory _allVotes = new uint256[](pollLength);
        uint256 sum;
        for (uint256 i = 0; i < pollLength; i++) {
            sum += poll.options[i].voteCount;
            _allVotes[i] = poll.options[i].voteCount;
        }

        totalVotes = sum;
        allVotes = _allVotes;
    }
}