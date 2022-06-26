/**
 *Submitted for verification at polygonscan.com on 2022-06-26
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Voting {
    // structs
    struct VoteOption{
        string name;
        uint count;
    }
    struct Poll {
        address owner;
        string name;
        string description;
        uint start_time;
        uint end_time;
        uint fee;
        uint option_count; // Number of options
        mapping(uint => VoteOption ) options; // mapping of index+1 to options (should start from 1)
        string[] option_names; // array of option names;
        mapping(address => uint ) votes; // mapping of address to option_id (should start from 1)
    }
    // get polls return values as a struct
    struct GetVotesReturn {
       address[] poll_owners;
       string[] poll_names;
       string[] poll_descriptions;
       uint[] poll_start_times;
       uint[] poll_end_times;
       uint[] poll_fees;
       uint[] poll_ids;
       string[][] poll_options;
       uint[][] poll_options_votes;
       uint[] poll_voted_idxs;
    }

    // Variables
    uint polls_created;
    // Mapping of addresses to usernames
    mapping(address => string ) address_to_username;
    mapping(string => address ) username_to_address;

    mapping(uint => Poll) polls;


    // variables    
    address public owner;
    
    // events
    event createPollEvt(uint pollId, address owner, string name, string description, uint start_time, uint end_time, uint fee, string[] options);

    constructor() {
        owner = msg.sender;
    }

    // Private Functions
    function validStr(string memory str) private pure returns(bool isValid) {
        return bytes(str).length >= 1;
    }

    // Public Functions 
    function createPoll(string memory name, string memory description, uint start_time, uint end_time, uint fee, string[] memory options) public {
        // Check string length
        require(validStr(name) && validStr(description));
        // Check end time after start time
        require(end_time >= start_time);
        // Check more than one option
        require(options.length >= 2);
        // Check that options have valid names
        for (uint i=0; i<options.length; i++) {
            require(validStr(options[i]));
        }

        // Adding the poll
        Poll storage newPoll = polls[polls_created];
        newPoll.owner = msg.sender;
        newPoll.name = name;
        newPoll.description = description;
        newPoll.start_time = start_time;
        newPoll.end_time = end_time;
        newPoll.fee = fee;
        newPoll.option_count = options.length;
        newPoll.option_names = options;

        // Adding the poll options
        for (uint i=0; i<options.length; i++) {
            VoteOption storage option = newPoll.options[newPoll.option_count+1];
            option.name = options[i];   
        }


        emit createPollEvt(polls_created, msg.sender, name, description, start_time, end_time, fee, options);

        // Increment poll id
        polls_created++;
    }

    function getUser() public view returns(string memory username) {
        return address_to_username[msg.sender];
    }

    function createUser(string memory username) public{
        // Make checks to ensure user name is not empty && not taken && address not registered
        require(validStr(username));
        address_to_username[msg.sender] = username;
        username_to_address[username] = msg.sender;
    }

    function getPolls() public view returns (GetVotesReturn memory poll_data) {
       address[] memory owners = new address[](polls_created);
       string[] memory names = new string[](polls_created);
       string[] memory descriptions = new string[](polls_created);
       uint[] memory start_times = new uint[](polls_created);
       uint[] memory end_times = new uint[](polls_created);
       uint[] memory fees = new uint[](polls_created);
       uint[] memory poll_ids = new uint[](polls_created);
       uint[] memory voted_idxs = new uint[](polls_created);

        // array of arrays for options
       string[][] memory option_list = new string[][](polls_created);
        // array of arrays for options votes
        uint[][] memory option_vote_list = new uint[][](polls_created);
        for (uint i=0; i<polls_created; i++) {
            owners[i] = polls[i].owner;
            names[i] = polls[i].name;
            descriptions[i] = polls[i].description;
            start_times[i] = polls[i].start_time;
            end_times[i] = polls[i].end_time;
            fees[i] = polls[i].fee;
            poll_ids[i] = i;
            voted_idxs[i] = polls[i].votes[msg.sender];
            
            // get option_count from poll
            uint option_count = polls[i].option_count;
            uint[] memory option_votes = new uint[](option_count);
            for (uint j=0; j<option_count; j++) {
                VoteOption memory option = polls[i].options[j+1];
                option_votes[j] = option.count;
            }

            // add options to option_list
            option_list[i] = polls[i].option_names;
            // add options_votes to option_vote_list
            option_vote_list[i] = option_votes;
            
        }
        return GetVotesReturn(owners, names, descriptions, start_times, end_times, fees, poll_ids, option_list, option_vote_list, voted_idxs);
    }

    function vote(uint poll_id, uint option_id) payable public {
        // Check that poll exists
        require(poll_id < polls_created, "Poll does not exist");
        // Check that option exists
        require(option_id < polls[poll_id].option_count, "Option does not exist");
        // Check that user has not already voted
        require(polls[poll_id].votes[msg.sender] == 0, "User has already voted");
        // Check that user has not voted in the future
        require(polls[poll_id].start_time <= block.timestamp, "User has tried voting in the future");
        // Check that user has not voted in the past
        require(polls[poll_id].end_time >= block.timestamp, "User has tried voting for the past");
        // Check that user has enough balance
        require(msg.value >= polls[poll_id].fee, "User does not have enough balance");
        // set poll.votes of user to option_id
        polls[poll_id].votes[msg.sender] = option_id+1;
        polls[poll_id].options[option_id+1].count++;
        // transfer the balance to the poll owner
        payable(polls[poll_id].owner).transfer(polls[poll_id].fee);
    }
}