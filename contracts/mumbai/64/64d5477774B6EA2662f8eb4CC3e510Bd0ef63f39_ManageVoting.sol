//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "./Voting.sol";

contract ManageVoting {
    address public owner;
    UV[] public nameVoting;
    uint256[] public userList;

    uint256 counter;

    struct Opt {
        string _name;
        string _img;
    }

    struct UV {
        string _name;
        address owner;
        uint256 id;
    }

    //sets owner,
    //owner added as a stakeholder
    constructor() {
        owner = msg.sender;
    }

    uint256 private votingCount = 0;

    //mapping
    mapping(string => Voting) public votings;
    mapping(uint256 => Voting) public votingList;

    //EVENTS
    event CreateVoting(address sender, string _votingName);
    event AddOption(address sender, string _votingName, string _name);
    event Vote(address sender, string _votingName, uint256 _optionID);

    //Create new instance of the voting contract
    function createVoting(
        string memory _votingName,
        uint256 _time,
        Opt[] memory options
    ) public returns (bool) {
        Voting myVote = new Voting();
        myVote.setInfo(_time);
        counter++;
        votings[_votingName] = myVote;
        votingList[counter] = myVote;
        nameVoting.push(UV(_votingName, msg.sender, counter));

        for (uint256 i = 0; i < options.length; i++) {
            addOption(_votingName, options[i]._name, options[i]._img);
        }

        emit CreateVoting(msg.sender, _votingName);
        return true;
    }

    //add candidate
    function addOption(
        string memory _votingName,
        string memory _name,
        string memory _img
    ) public returns (bool) {
        votings[_votingName].addOption(_name, _img);
        emit AddOption(msg.sender, _votingName, _name);
        return true;
    }

    //stakeholders only vote
    function vote(string memory _votingName, uint256 _optionID)
        public
        returns (bool)
    {
        votings[_votingName].vote(_optionID);
        emit Vote(msg.sender, _votingName, _optionID);
        return true;
    }

    function getAllOptions(string memory _votingName)
        public
        view
        returns (Voting.Option[] memory)
    {
        return votings[_votingName].getAllOptions();
    }

    function secondsRemaining(string memory _votingName)
        public
        view
        returns (uint256)
    {
        return votings[_votingName].secondsRemaining();
    }

    /* Returns all unsold List items */
    function fetchListItems() public view returns (UV[] memory) {
        return nameVoting;
    }

    /* Returns all unsold List items */
    function fetchMyListItems() public view returns (UV[] memory) {
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < counter; i++) {
            if (nameVoting[i].owner == msg.sender) {
                itemCount += 1;
            }
        }

        UV[] memory items = new UV[](itemCount);

        for (uint256 i = 0; i < counter; i++) {
            if (nameVoting[i].owner == msg.sender) {
                uint256 currentId = i;

                UV storage currentItem = nameVoting[currentId];
                items[currentIndex] = currentItem;

                currentIndex += 1;
            }
        }

        return items;
    }
}

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.7;

contract Voting {
    //counter for every options; will form the id in the mapping
    uint256 optionCount = 0;
    uint256 time;
    string title;
    address owner;

    //EVENTS
    //events for voting
    event AddOptions(string name);

    //event for voting, takes in candidate ID
    event Voted(uint256 id);

    //option information
    struct Option {
        uint256 id;
        string name;
        uint256 vote;
        string imgUrl;
    }

    //MAPPING
    //maps all options
    mapping(uint256 => Option) allOptions;

    //maps address of all users that vote
    mapping(address => bool) allUsers;

    //maps for every name
    mapping(string => bool) optionNames;

    //MODIFIERS
    modifier checkTime() {
        require(block.timestamp < (time), "Time Up");
        _;
    }

    function setInfo(uint256 _time) public {
        time = block.timestamp + _time;
        owner = msg.sender;
    }

    //addOption function
    function addOption(string memory _name, string memory _imgUrl) external {
        //create a new struct candidate
        //mapping the candidatecount as ID to the dandidate data
        allOptions[optionCount] = Option(optionCount, _name, 0, _imgUrl);
        //increment the count each time a candidate is added
        optionCount++;

        //sets users added
        optionNames[_name] = true;

        //event
        emit AddOptions(_name);
    }

    //Voting function
    function vote(uint256 _optionID) external checkTime returns (bool) {
        //increment the candidates vote by 1
        allOptions[_optionID].vote = allOptions[_optionID].vote + 1;

        //mark the voter as having voted
        allUsers[msg.sender] = true;

        //emit the event
        emit Voted(_optionID);
        return true;
    }

    //get all candidate
    function getAllOptions() external view returns (Option[] memory) {
        Option[] memory items = new Option[](optionCount);

        //iterate all the candidates
        //assign to the array at an index of their ID
        for (uint256 i = 0; i < optionCount; i++) {
            Option storage currentItem = allOptions[i];
            items[i] = currentItem;
        }
        // return the arrays
        return items;
    }

    function secondsRemaining() public view returns (uint256) {
        if (block.timestamp >= time) {
            return 0; // already there
        } else {
            return time - block.timestamp;
        }
    }
}