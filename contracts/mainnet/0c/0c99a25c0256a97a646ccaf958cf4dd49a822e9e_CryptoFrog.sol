/**
 *Submitted for verification at polygonscan.com on 2023-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CryptoFrog {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public tokenPrice;
    uint256 public targetAmount;
    uint256 public minContribution;
    uint256 public maxContribution;
    address payable public beneficiary; // Update beneficiary address
    address public owner;
    uint256 public totalContributions;
    uint256 public totalSupply;
    bool public isActive; // Flag to control funding status

    mapping(address => uint256) public contributions;
    mapping(address => uint256) public balances;

    event Contribution(address indexed contributor, uint256 amount);
    event FundingCompleted(uint256 totalContributions);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action");
        _;
    }

    constructor() {
        name = "CryptoFrog";
        symbol = "CFROG";
        decimals = 18;
        tokenPrice = 500000000000000; // Adjusted tokenPrice value
        targetAmount = 30000000;
        minContribution = 10000000000000000000;
        maxContribution = 1000000000000000000000;
        beneficiary = payable(0xFE68eAb60035364706dB0cfb0Dd3b4E85a051C70); // Set your wallet address here
        owner = msg.sender;
        totalSupply = 69000000000 * (10**decimals);
        balances[beneficiary] = totalSupply; // Assign all tokens to the beneficiary wallet
        isActive = true; // Funding is active initially
    }

    function contribute() public payable {
        require(isActive, "Funding is currently not active");
        require(msg.value >= minContribution, "Contribution amount is below the minimum");
        require(msg.value <= maxContribution, "Contribution amount exceeds the maximum");

        totalContributions += msg.value;
        contributions[msg.sender] += msg.value;
        emit Contribution(msg.sender, msg.value);

        if (totalContributions >= targetAmount) {
            emit FundingCompleted(totalContributions);
            uint256 tokensToTransfer = totalContributions * (10**decimals) / tokenPrice;
            require(balances[beneficiary] >= tokensToTransfer, "Insufficient tokens in the contract");
            balances[beneficiary] -= tokensToTransfer;
            balances[msg.sender] += tokensToTransfer;
            beneficiary.transfer(address(this).balance); // Send funds to the beneficiary wallet
            isActive = false; // Deactivate funding after reaching the target
        }
    }

    function balanceOf(address _account) public view returns (uint256) {
        return balances[_account];
    }

    function transfer(address _to, uint256 _amount) public returns (bool) {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        return true;
    }

    function withdrawFunds() public onlyOwner payable {
        require(address(this).balance > 0, "No funds available to withdraw");
        beneficiary.transfer(address(this).balance);
    }

    function end() public onlyOwner {
        isActive = false; // Deactivate funding
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0); // Remove the contract owner
    }
}