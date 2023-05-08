/**
 *Submitted for verification at polygonscan.com on 2023-05-08
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

contract Poll {
   
    uint public latestCreatedPoll;
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
        latestCreatedPoll++;
        Option[] memory options = new Option[](_optionNames.length);

        PollData storage pollData = Polls[latestCreatedPoll];
        pollData.owner = msg.sender;
        pollData.title = _title;
        pollData.description = _description;

        for (uint256 i = 0; i < _optionNames.length; i++) {
            options[i] = Option(i + 1, _optionNames[i], 0);
            pollData.options.push(options[i]);
        }

        emit PollCreated(
            latestCreatedPoll,
            _title,
            _description,
            _optionNames
        );
    }
}