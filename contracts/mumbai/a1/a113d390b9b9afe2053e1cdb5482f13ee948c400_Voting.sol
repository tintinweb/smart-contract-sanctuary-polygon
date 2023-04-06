/**
 *Submitted for verification at polygonscan.com on 2023-04-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Voting {
    string[] public options;
    address public owner;
    mapping(string => uint256) public voteCount;
    mapping(address => bool) public hasVoted;
    mapping(address => string) private choice;
    bool voteOpen;

    constructor(string[] memory _options) {
        owner = msg.sender;
        options = _options;
    }
    struct Choice {
        string choice;
        uint count;
    }
    
    function startVote() public {
        require(msg.sender == owner, "You are not authorized");
        voteOpen = true;
    }

    function endVote() public {
        require(msg.sender == owner, "You are not authorized");
        voteOpen = false;
    }
    function seeWinner() public view returns(Choice memory) {
        require(msg.sender == owner, "You are not authorized");
        uint winningCount = 0;
        string memory winningOption = "None";
        for (uint i = 0; i < options.length; i++) {
            if (voteCount[options[i]] > winningCount) {
                winningCount = voteCount[options[i]];
                winningOption = options[i];
            }
        }
        return Choice(winningOption, winningCount);
    }
    function isOpen() public view returns(bool) {
        return voteOpen;
    }

    function vote(string memory option) public {
        require(voteOpen, "Voting hasn't started");
        bool optionExists = false;

        for (uint i = 0; i < options.length; i++) {
            if (keccak256(bytes(options[i])) ==  keccak256(bytes(option))) {
                optionExists = true;
                break;
            }
        }
        require(optionExists, "Invalid Option");
        require(!hasVoted[msg.sender], "You have voted before");

        voteCount[option]++;
        hasVoted[msg.sender] = true;
        choice[msg.sender] = option;
    }
    function seeChoice(address addy) public view returns(string memory) {
        require(msg.sender == owner, "You are not allowed!");
        return choice[addy];
    }
}