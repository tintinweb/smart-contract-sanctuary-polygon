/**
 *Submitted for verification at polygonscan.com on 2022-11-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract SimpleVote {
    address public i_owner;

    struct People {
        uint256 votos;
        string name;
    }

    People[] public people;
    People[] public emptyArray;

    uint256 public constant VOTE_LIMIT_PER_WALLET = 1;

    //contagem de votos
    mapping(string => uint256) public votosDasPessoas;
    mapping(address => uint256) private voteCountMap;
    mapping(address => uint256) private allowedVoteCountMap;

    bool public voteIsActive = false;

    uint256 public numPeople;

    constructor() {
        i_owner = msg.sender;
        numPeople = 0;
    }

    function allowedVoteCount(address voter) public view returns (uint256) {
        return VOTE_LIMIT_PER_WALLET - voteCountMap[voter];
    }

    function updateVoteCount(address voter) private {
        voteCountMap[voter] += 1;
    }

    modifier onlyOwner() {
        // require(msg.sender == owner);
        if (msg.sender != i_owner) revert("Not Owner!");
        _;
    }

    function setVoteIsActive(bool voteIsActive_) external onlyOwner {
        voteIsActive = voteIsActive_;
    }

    function vote(string memory _name) public virtual {
        if (!voteIsActive) {
            revert("Voting not active!");
        }

        if (allowedVoteCount(msg.sender) >= 1) {
            updateVoteCount(msg.sender);
        } else {
            revert("Already voted!");
        }

        votosDasPessoas[_name] = votosDasPessoas[_name] + 1;
    }

    function reset() public onlyOwner {
        if (voteIsActive) {
            revert("Voting active!");
        }
        people = emptyArray;
    }

    function addPerson(string memory _name) public onlyOwner {
        if (voteIsActive) {
            revert("Voting active!");
        }
        people.push(People(0, _name));
        numPeople = people.length;
    }
}