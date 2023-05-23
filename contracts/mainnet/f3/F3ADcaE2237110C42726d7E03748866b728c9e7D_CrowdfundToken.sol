/**
 *Submitted for verification at polygonscan.com on 2023-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CrowdfundToken {
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

    mapping(address => uint256) public contributions;

    event Contribution(address indexed contributor, uint256 amount);
    event FundingCompleted(uint256 totalContributions);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action");
        _;
    }

    constructor() {
        name = "Token";
        symbol = "CFT";
        decimals = 18;
        tokenPrice = 500000000000000; // Adjusted tokenPrice value
        targetAmount = 30000000;
        minContribution = 1000000000000000;
        maxContribution = 1000000000000000000000;
        beneficiary = payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4); // Set your wallet address here
        owner = msg.sender;
        totalSupply = 69000000000 * (10**decimals);
    }

    function contribute() public payable {
        require(msg.value >= minContribution, "Contribution amount is below the minimum");
        require(msg.value <= maxContribution, "Contribution amount exceeds the maximum");

        totalContributions += msg.value;
        contributions[msg.sender] += msg.value;
        emit Contribution(msg.sender, msg.value);

        if (totalContributions >= targetAmount) {
            emit FundingCompleted(totalContributions);
            uint256 tokensToMint = totalContributions * (10**decimals) / tokenPrice;
            mintTokens(tokensToMint);
            beneficiary.transfer(address(this).balance); // Send funds to the beneficiary wallet
        }
    }

    function mintTokens(uint256 _amount) internal {
        // Mint tokens to the specified address
        // Add your minting logic here
        
        totalSupply += _amount; // Increase total supply by the minted amount
    }

    function withdrawFunds() public onlyOwner payable {
        require(address(this).balance > 0, "No funds available to withdraw");
        beneficiary.transfer(address(this).balance);
    }
}