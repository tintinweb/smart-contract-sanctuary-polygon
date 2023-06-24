// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract VotingPlatform {
    //////////////////
    //// structs /////
    /////////////////

    struct Voter {
        bool isRegistered;
        uint256 votedOptionId;
        bool hasVoted;
    }

    // Users should be able to create the voting options for the topic they’ve created. E.g. options like “yes”, “no”, “maybe” etc.
    struct VotingOption {
        string name;
        uint256 voteCount;
    }

    struct Topic {
        uint256 id;
        string name;
        uint256 expiryTime;
        address topicOwner;
        mapping(uint256 => VotingOption) options;
        mapping(address => Voter) voters;
        uint256 optionCount;
    }

    /////////////////////////////////
    //// variables and mappings /////
    ////////////////////////////////
    uint256 public topicCount;
    mapping(uint256 => Topic) public topics;

    //////////////////
    //// events /////
    /////////////////

    event TopicCreated(
        uint256 indexed id,
        string name,
        uint256 expiryTime,
        address topicOwner
    );
    event VoterRegistered(uint256 indexed topicId, address voter);
    event VoterUnregistered(uint256 indexed topicId, address voter);
    event VoteCasted(uint256 indexed topicId, address voter, uint256 optionId);
    event VotingExpired(uint256 indexed topicId);

    ////////////////////
    //// modifiers /////
    ///////////////////

    modifier onlyTopicOwner(uint256 _topicId) {
        require(
            topics[_topicId].topicOwner == msg.sender,
            "Only topic owner can reject the applicant"
        );
        _;
    }

    modifier isNotVoted(uint256 _topicId) {
        require(
            !topics[_topicId].voters[msg.sender].hasVoted,
            "You have voted before"
        );
        _;
    }

    modifier onlyAllowedVoter(uint256 _topicId) {
        require(
            topics[_topicId].voters[msg.sender].isRegistered,
            "You are not registered as a voter"
        );
        _;
    }

    ////////////////////
    //// functions /////
    ///////////////////

    // Users should be able to create a topic to vote on. (Permissionlessly)
    function createTopic(
        string memory _topicName,
        uint256 _expiryTime
    ) external {
        require(
            _expiryTime > block.timestamp,
            "Expiry time must be in the future"
        );

        topics[topicCount].id = topicCount;
        topics[topicCount].name = _topicName;
        topics[topicCount].expiryTime = _expiryTime;
        topics[topicCount].topicOwner = msg.sender;

        topicCount++;

        emit TopicCreated(topicCount, _topicName, _expiryTime, msg.sender);
    }

    function createVotingOption(
        uint256 _topicId,
        string memory _optionName
    ) external onlyTopicOwner(_topicId) {
        Topic storage topic = topics[_topicId];
        require(topic.expiryTime > block.timestamp, "Voting has expired");

        topic.options[topic.optionCount].name = _optionName;
        topic.optionCount = topic.optionCount + 1;
    }

    // In order to vote, the users have to register themselves as a voter
    function registerAsVoter(uint256 _topicId) external {
        Topic storage topic = topics[_topicId];
        require(topic.expiryTime > block.timestamp, "Voting has expired");

        topic.voters[msg.sender].isRegistered = true;

        emit VoterRegistered(_topicId, msg.sender);
    }

    // topic creater should have the option to either allow or reject the applicant.
    function rejectVoter(
        uint256 _topicId,
        address _voter
    ) external onlyTopicOwner(_topicId) {
        Topic storage topic = topics[_topicId];
        topic.voters[_voter].isRegistered = true;
        emit VoterUnregistered(_topicId, _voter);
    }

    // Other users should be able to vote on a particular option on a topic and voters should be able to choose only one option for a topic.
    function vote(
        uint256 _topicId,
        uint256 _optionId
    ) external onlyAllowedVoter(_topicId) isNotVoted(_topicId) {
        Topic storage topic = topics[_topicId];
        require(topic.expiryTime > block.timestamp, "Voting has expired");
        require(
            _optionId < topic.optionCount && _optionId >= 0,
            "Invalid option ID"
        );

        topic.options[_optionId].voteCount++;
        topic.voters[msg.sender].votedOptionId = _optionId;
        topic.voters[msg.sender].hasVoted = true;

        emit VoteCasted(_topicId, msg.sender, _optionId);
    }

    //////////////////
    //// getters /////
    /////////////////

    function getVoteCount(
        uint256 _topicId,
        uint256 _optionId
    ) external view returns (uint256) {
        Topic storage topic = topics[_topicId];
        require(topic.expiryTime <= block.timestamp, "Voting is still ongoing");

        return topic.options[_optionId].voteCount;
    }
}