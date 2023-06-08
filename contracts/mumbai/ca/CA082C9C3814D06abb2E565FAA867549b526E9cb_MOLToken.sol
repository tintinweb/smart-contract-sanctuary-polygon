/**
 *Submitted for verification at polygonscan.com on 2023-06-07
*/

pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

contract MOLToken {
    string public name;
    string public symbol;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public stakeTimestamp;
    mapping(address => bool) public daoMembers;

    address public dao;
    uint256 public daoProposalCount;
    uint256 public daoVoteDuration;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 amount);
    event DAOProposal(address indexed proposer, uint256 proposalId, bytes proposalData);
    event DAOVote(address indexed voter, uint256 proposalId, bool vote, uint256 voteCount);

    modifier onlyDAO() {
        require(msg.sender == dao, "Only DAO can perform this action");
        _;
    }

    constructor(string memory _name, string memory _symbol, uint256 _initialSupply, uint256 _daoVoteDuration) {
        name = _name;
        symbol = _symbol;
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply;
        dao = msg.sender;
        daoMembers[msg.sender] = true;
        daoProposalCount = 0;
        daoVoteDuration = _daoVoteDuration;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function stake(uint256 amount) public {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        stakedBalance[msg.sender] += amount;
        stakeTimestamp[msg.sender] = block.timestamp;
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) public {
        require(stakedBalance[msg.sender] >= amount, "Insufficient staked balance");
        require(block.timestamp >= stakeTimestamp[msg.sender] + (30 days), "Stake is still locked");
        stakedBalance[msg.sender] -= amount;
        balanceOf[msg.sender] += amount;
        emit Unstaked(msg.sender, amount);
    }

    function addDAOMember(address member) public onlyDAO {
        daoMembers[member] = true;
    }

    function removeDAOMember(address member) public onlyDAO {
        daoMembers[member] = false;
    }

    function createDAOProposal(bytes memory proposalData) public returns (uint256) {
        require(daoMembers[msg.sender], "Only DAO members can create proposals");
        daoProposalCount++;
        emit DAOProposal(msg.sender, daoProposalCount, proposalData);
        return daoProposalCount;
    }

    function voteOnDAOProposal(uint256 proposalId, bool vote) public {
        require(daoMembers[msg.sender], "Only DAO members can vote");
        emit DAOVote(msg.sender, proposalId, vote, daoProposalCount);
    }
}