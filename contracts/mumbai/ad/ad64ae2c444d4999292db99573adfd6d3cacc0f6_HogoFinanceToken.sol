/**
 *Submitted for verification at polygonscan.com on 2023-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }
}

contract HogoFinanceToken is Ownable {
    mapping(address => uint) public balances;
    uint public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public feeGasPerClaim;
    uint public claimedAirdrop;

    constructor() {
        totalSupply = 100000000 * 10**18; // Total supply set to 100 million tokens with 18 decimals
        balances[msg.sender] = totalSupply;
        name = "Hogo Finance";
        symbol = "HOGO";
        decimals = 18;
        feeGasPerClaim = 0.01 ether; // Fee gas per claim set to 0.01 ether
        claimedAirdrop = 0;
    }

    function transfer(address to, uint amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    function burn(uint amount) external onlyOwner {
        require(amount <= balances[msg.sender], "Insufficient balance");
        balances[msg.sender] -= amount;
        totalSupply -= amount;
    }

    function renounceOwnership() external onlyOwner {
        owner = address(0);
    }

    function claimAirdrop() external payable {
        uint claimAmount = 10000 * 10**18; // 10,000 tokens per claim with 18 decimals
        require(balances[msg.sender] == 0, "You have an existing balance");
        require(claimAmount <= totalSupply, "Insufficient airdrop supply");
        require(msg.value >= feeGasPerClaim, "Insufficient fee gas");
        require(claimedAirdrop + claimAmount <= 1000000 * 10**18, "Airdrop claim limit reached");
        
        balances[msg.sender] = claimAmount;
        totalSupply -= claimAmount;
        claimedAirdrop += claimAmount;
    }
}