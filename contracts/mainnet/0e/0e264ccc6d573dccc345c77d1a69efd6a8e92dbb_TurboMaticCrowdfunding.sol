/**
 *Submitted for verification at polygonscan.com on 2023-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TurboMaticCrowdfunding {
    address public owner;
    uint256 public fundingGoal;
    uint256 public deadline;
    uint256 public raisedAmount;
    uint256 public minContribution;
    uint256 public maxContribution;
    struct Contributor {
        uint256 amount;
        bool claimedRefund;
    }
    mapping(address => Contributor) public contributors; // Mapping to store contributors' addresses and contribution amounts
    address[] public contributorAddresses; // Array to store contributors' addresses
    bool public ended;
    bool public goalAchieved;

    event ContributionReceived(address indexed contributor, uint256 amount);
    event RefundClaimed(address indexed contributor, uint256 amount);
    event FundingEnded(bool goalReached);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier beforeDeadline() {
        require(block.timestamp < deadline, "Funding period has ended");
        _;
    }

    constructor(
        uint256 _fundingGoal,
        uint256 _durationInDays,
        uint256 _minContribution,
        uint256 _maxContribution
    ) {
        require(_fundingGoal > 0, "Funding goal must be greater than 0");
        require(_minContribution > 0, "Minimum contribution must be greater than 0");
        require(_maxContribution > 0 && _maxContribution >= _minContribution, "Invalid maximum contribution amount");
        owner = msg.sender;
        fundingGoal = _fundingGoal;
        deadline = block.timestamp + (_durationInDays * 1 days);
        minContribution = _minContribution;
        maxContribution = _maxContribution;
    }

    function contribute() external payable beforeDeadline {
        require(msg.value >= minContribution, "Contribution amount is below the minimum");
        require(msg.value <= maxContribution, "Contribution amount exceeds the maximum");

        if (contributors[msg.sender].amount == 0) {
            contributorAddresses.push(msg.sender);
        }

        contributors[msg.sender].amount += msg.value;
        raisedAmount += msg.value;

        emit ContributionReceived(msg.sender, msg.value);
    }

    function claimRefund() external {
        require(ended, "Funding period has not ended yet");
        require(!goalAchieved, "Funding goal has been achieved");

        uint256 refundAmount = contributors[msg.sender].amount;
        require(refundAmount > 0, "No refund available");
        require(!contributors[msg.sender].claimedRefund, "Refund has already been claimed");

        contributors[msg.sender].claimedRefund = true;
        payable(msg.sender).transfer(refundAmount);

        emit RefundClaimed(msg.sender, refundAmount);
    }

    function endFundingPeriod() external onlyOwner {
        require(!ended, "Funding period has already ended");

        ended = true;
        goalAchieved = (raisedAmount >= fundingGoal);

        emit FundingEnded(goalAchieved);
    }

    function withdraw() external onlyOwner {
        require(ended, "Funding period has not ended yet");
        require(goalAchieved, "Funding goal has not been achieved");

        payable(owner).transfer(address(this).balance);
    }

    function getContributorCount() external view returns (uint256) {
        return contributorAddresses.length;
    }
}