/**
 *Submitted for verification at polygonscan.com on 2023-04-13
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    struct Option {
        string name;
        uint256 totalTokens;
    }

    address public owner;
    mapping(address => uint256) public balances;
    Option[] public options;

    uint256 public minTokensPerVote = 1;
    uint256 public maxTokensPerVote = 50;

    event VoteCast(uint256 indexed optionIndex, uint256 totalTokens);
    event VotingCleared();

    constructor(string[] memory optionNames) {
        owner = msg.sender;
        for (uint256 i = 0; i < optionNames.length; i++) {
            options.push(Option(optionNames[i], 0));
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    function vote(uint256 optionIndex, uint256 tokens) public {
        require(optionIndex < options.length, "Invalid option index");
        require(tokens >= minTokensPerVote && tokens <= maxTokensPerVote, "Invalid number of tokens for voting");
        require(balances[msg.sender] >= tokens, "Insufficient balance");

        options[optionIndex].totalTokens += tokens;
        balances[msg.sender] -= tokens;

        emit VoteCast(optionIndex, options[optionIndex].totalTokens);
    }

    function getOption(uint256 index) public view returns (string memory, uint256) {
        return (options[index].name, options[index].totalTokens);
    }

    function getOptionsCount() public view returns (uint256) {
        return options.length;
    }

    function setBalance(address user, uint256 amount) public onlyOwner {
        balances[user] = amount;
    }

    function clearVote() public onlyOwner {
        for (uint256 i = 0; i < options.length; i++) {
            options[i].totalTokens=0;
        }
        emit VotingCleared();
    }
}