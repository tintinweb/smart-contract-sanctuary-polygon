// SPDX-License-Identifier: MIT
// The above line is a SPDX license identifier that specifies the license for this Solidity code.

pragma solidity ^0.8.0;

contract Vote {
    uint8 public pollCount;

    // This modifier restricts access to the function to the poll creator only.
    modifier onlyPollCreator(uint256 pollId) {
        if (pollDetails[pollId].pollCreator != msg.sender) {
            revert("you are not a poll creator");
        } else {
            _;
        }
    }

    // This modifier checks if a voter is eligible to vote in the given poll.
    modifier eligibleToVote(uint256 pollId) {
        if (voterDetails[msg.sender][pollId].pollId != pollId) {
            revert("you are not eligible to vote in this Poll");
        } else {
            _;
        }
    }

    // This struct contains information about a poll.
    struct PollInfo {
        uint256 pollId;
        string pollName;
        address pollCreator;
        bool pollStatus;
        uint256 pollMemberCount;
        uint256 startTime;
        uint256 endTime;
        uint256 totalVotesMade;
        uint256 voteOptions;
        PollVoteOptions pollVoteOptions;
    }

    // This struct contains the vote options for a poll.
    struct PollVoteOptions {
        uint256 pollId;
        uint256[] optionsWithVoteCount;
    }

    // This struct contains information about a voter.
    struct VoterInfo {
        uint256 pollId;
        bool voted;
        uint256 vote;
    }

    // This struct contains information about a warden.
    struct WardenInfo {
        uint256[] pollId;
        uint256 currentPoll;
        bool haveActivePoll;
    }

    // This mapping stores the details of all the polls created.
    mapping(uint256 => PollInfo) public pollDetails;

    // This mapping stores the details of all the voters for each poll.
    mapping(address => mapping(uint256 => VoterInfo)) public voterDetails;

    // This mapping stores the details of all the wardens.
    mapping(address => WardenInfo) wardenDetails;

    function fetchWarden()
        public
        view
        returns (
            uint256[] memory _pollId,
            uint256 _currentPoll,
            bool _haveActivePoll
        )
    {
        _pollId = wardenDetails[msg.sender].pollId;
        _currentPoll = wardenDetails[msg.sender].currentPoll;
        _haveActivePoll = wardenDetails[msg.sender].haveActivePoll;
    }

    // This function creates a new poll with the given parameters
    function createPoll(
        address[] memory members,
        uint256 timeLimit,
        uint256 voteOptions,
        string memory _pollName
    ) public {
        // Check if the sender already has an active poll
        bool doesWardenHaveActivePoll = wardenDetails[msg.sender]
            .haveActivePoll;

        if (doesWardenHaveActivePoll) {
            // If the sender already has an active poll, check if the poll has ended
            uint256 _poll = wardenDetails[msg.sender].currentPoll;
            require(
                pollDetails[_poll].endTime < block.timestamp,
                "Time is yet to pass, can't make one more poll"
            );
            // Set the haveActivePoll flag to false
            wardenDetails[msg.sender].haveActivePoll = false;
        }

        // Ensure that the sender doesn't already have an active poll
        require(
            !wardenDetails[msg.sender].haveActivePoll,
            "You only can create a single Poll at a time"
        );

        // Increment the poll count and create a new poll ID
        uint256 newPollId = pollCount + 1;

        // Create an array to hold the default votes for each option
        uint256[] memory defaultVotes = new uint256[](voteOptions);

        // Create a new PollInfo struct and add it to the pollDetails mapping
        pollDetails[newPollId] = PollInfo(
            newPollId,
            _pollName,
            msg.sender,
            true,
            members.length + 1,
            block.timestamp,
            timeLimit,
            0,
            voteOptions,
            PollVoteOptions(newPollId, defaultVotes)
        );

        // Create a VoterInfo struct for the poll creator and add it to the voterDetails mapping
        voterDetails[msg.sender][newPollId] = VoterInfo(newPollId, false, 0);

        // Create a VoterInfo struct for each member in the members array and add it to the voterDetails mapping
        for (uint256 i; i < members.length; i++) {
            voterDetails[members[i]][newPollId] = VoterInfo(
                newPollId,
                false,
                0
            );
        }

        // Increment the poll count
        pollCount += 1;

        // Add the new poll ID to the warden's poll ID array and set the current poll ID to the new poll ID
        wardenDetails[msg.sender].pollId.push(newPollId);
        wardenDetails[msg.sender].currentPoll = newPollId;
        wardenDetails[msg.sender].haveActivePoll = true;
    }

    // This function returns the poll details for a given poll ID
    function getPollDetails(uint8 pollId)
        public
        view
        returns (PollInfo memory pollInfo)
    {
        PollInfo storage _pollInfo = pollDetails[pollId];
        pollInfo = _pollInfo;
    }

    // This function allows a user to cast their vote for a given poll ID and vote option
    function makeVote(uint8 pollId, uint256 _vote)
        public
        eligibleToVote(pollId)
    {
        // Get the voter and poll details from storage
        VoterInfo storage voter = voterDetails[msg.sender][pollId];
        PollInfo storage poll = pollDetails[pollId];

        // Make sure the poll is open and not expired
        require(poll.pollStatus, "Poll is closed for now");
        require(poll.endTime > block.timestamp, "Poll has expired");

        // Make sure the user is eligible to vote and hasn't already voted
        require(
            poll.totalVotesMade <= poll.pollMemberCount,
            "Maximum votes have been made"
        );
        require(
            voterDetails[msg.sender][pollId].voted == false,
            "Already voted"
        );

        // Make sure the vote option is valid
        require(
            pollDetails[pollId].voteOptions >= _vote,
            "Invalid voting option"
        );

        // Increment the vote count for the selected option and update the total vote count for the poll
        pollDetails[pollId].pollVoteOptions.optionsWithVoteCount[_vote] += 1;
        poll.totalVotesMade += 1;

        // If all eligible voters have cast their vote, close the poll
        if (poll.totalVotesMade == poll.pollMemberCount) {
            poll.pollStatus = false;
        }

        // Update the voter's voted status and selected vote option
        voter.voted = true;
        voter.vote = _vote;
    }

    // This function adds voters to a poll
    function addVoters(uint256 pollId, address[] memory members)
        public
        onlyPollCreator(pollId)
        returns (uint256 _memberCount)
    {
        // Increase the poll's member count by the number of members being added
        pollDetails[pollId].pollMemberCount += members.length;
        // Loop through each member being added
        for (uint256 i = 0; i < members.length; i++) {
            // Set the voter's information for this poll
            voterDetails[members[i]][pollId] = VoterInfo(pollId, false, 0);
        }
        // Return the updated member count for the poll
        _memberCount = pollDetails[pollId].pollMemberCount;
    }

    // This function ends a poll
    function endPoll(uint256 pollId) public onlyPollCreator(pollId) {
        // Get the poll's information
        PollInfo memory poll = pollDetails[pollId];
        // Set the poll's status to false, indicating that it has ended
        poll.pollStatus = false;
        // Set the active poll flag for the poll creator to false
        wardenDetails[msg.sender].haveActivePoll = false;
    }

    // This function returns the poll results and poll name for a given poll ID
    function pollResult(uint8 pollId)
        public
        view
        returns (PollVoteOptions memory result, string memory _pollName)
    {
        // Check that the poll has ended before displaying the results
        bool _pollStatus = pollDetails[pollId].pollStatus;
        require(
            pollDetails[pollId].endTime < block.timestamp || !_pollStatus,
            "Can't show result now, let Poll end first"
        );
        // If the poll has ended, return the poll's vote options and name
        result = pollDetails[pollId].pollVoteOptions;
        _pollName = pollDetails[pollId].pollName;
    }
}