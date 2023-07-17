/**
 *Submitted for verification at polygonscan.com on 2023-07-17
*/

pragma solidity ^0.8.0;

contract MilestonePaymentContract {
    address public client;
    address public projectManager;
    address public contractor;
    uint public totalPayment;
    uint public totalMilestones;
    uint public completedMilestones;

    struct Milestone {
        uint amount;
        bool completed;
    }

    mapping(uint => Milestone) public milestones;

    event MilestoneSet(uint indexed milestoneIndex, uint amount);
    event MilestoneCompleted(uint indexed milestoneIndex);
    event PaymentReleased(uint amount);

    constructor(address _client,address _projectManager, address _contractor) {
        client = _client;
        projectManager = _projectManager;
        contractor = _contractor;
    }

    modifier onlyClient() {
        require(msg.sender == client, "Only client can call this function");
        _;
    }

    modifier onlyProjectManager() {
        require(msg.sender == projectManager, "Only project manager can call this function");
        _;
    }

    modifier onlyContractor() {
        require(msg.sender == contractor, "Only contractor can call this function");
        _;
    }

    function setMilestone(uint _milestoneIndex, uint _amount) public onlyClient {
        require(_milestoneIndex < totalMilestones, "Invalid milestone index");
        require(!milestones[_milestoneIndex].completed, "Milestone has already been completed");
        
        milestones[_milestoneIndex] = Milestone(_amount, false);
        emit MilestoneSet(_milestoneIndex, _amount);
    }

    function completeMilestone(uint _milestoneIndex) public onlyProjectManager {
        require(_milestoneIndex < totalMilestones, "Invalid milestone index");
        require(!milestones[_milestoneIndex].completed, "Milestone has already been completed");
        
        milestones[_milestoneIndex].completed = true;
        completedMilestones++;
        emit MilestoneCompleted(_milestoneIndex);

        if (completedMilestones == totalMilestones) {
            releasePayment();
        }
    }

    function releasePayment() internal {
        require(completedMilestones == totalMilestones, "All milestones have not been completed");

        uint remainingBalance = address(this).balance;
        uint amountToRelease = totalPayment - remainingBalance;
        require(amountToRelease > 0, "No payment to release");

        (bool success, ) = contractor.call{value: amountToRelease}("");
        require(success, "Failed to release payment");

        emit PaymentReleased(amountToRelease);
    }

    function setTotalPayment(uint _totalPayment) public onlyClient {
        require(_totalPayment > 0, "Total payment must be greater than 0");
        require(totalPayment == 0, "Total payment has already been set");

        totalPayment = _totalPayment;
    }

    function setTotalMilestones(uint _totalMilestones) public onlyClient {
        require(_totalMilestones > 0, "Total milestones must be greater than 0");
        require(totalMilestones == 0, "Total milestones have already been set");

        totalMilestones = _totalMilestones;
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    receive() external payable {
        // Receive payment from client
        require(msg.sender == client, "Only client can send payment");
        require(totalPayment > 0, "Total payment has not been set");

        require(
            address(this).balance + msg.value <= totalPayment,
            "Total payment exceeded"
        );
    }
}