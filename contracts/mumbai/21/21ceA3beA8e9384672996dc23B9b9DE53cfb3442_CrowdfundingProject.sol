/**
 *Submitted for verification at polygonscan.com on 2022-11-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract CrowdfundingProject {
    // Data structures
    enum State {
        Fundraising,
        Expired,
        Successful,
        UnSuccessful
    }

    enum Pledge {
        Starter,
        Silver,
        Gold
    }

    // State variables
    address payable public creator;
    uint public amountGoal; // required to reach at least this much, else everyone gets refund
    uint public completeAt;
    uint256 public currentBalance;
    uint public raiseBy;
    string public title;
    string public description;
    State public state = State.Fundraising; // initialize on create
    mapping (address => uint) public contributions;
    mapping (address => uint) public contributionWithPledge;
    address[] public contributorAddresses;
    uint totalRaised;

    // Event that will be emitted whenever funding will be received
    event FundingReceived(
        address contributor, 
        uint amount, 
        uint currentTotal
    );
    // Event that will be emitted whenever the project starter has received the funds
    event CreatorPaid(address recipient);
    // Event that will be emitted when fundrasing failed and all contributers get a refund
    event RefundContributors(
        uint contributorsCount, 
        uint refundedCount,
        bool successful
    );

    // Modifier to check current state
    modifier inState(State _state) {
        require(state == _state, "Wrong state detected");
        _;
    }

    // Modifier to check if the function caller is the project creator
    modifier isCreator() {
        require(msg.sender == creator, "Restricted access");
        _;
    }

    /**
      * @param projectTitle Title of the project to be created
      * @param projectDescription Brief description about the project
      * @param durationInDays Project deadline in days
      * @param goalAmount Project goal in wei
      */
    constructor
    (
        string memory projectTitle,
        string memory projectDescription,
        uint durationInDays,
        uint goalAmount
    ) {
        uint _now = block.timestamp;
        raiseBy = _now + (durationInDays * 1 days);
        creator = payable(msg.sender);
        title = projectTitle;
        description = projectDescription;
        amountGoal = goalAmount;
        currentBalance = 0;
    }

    /** @dev Function to fund a certain project.
      */
    function contribute() external inState(State.Fundraising) payable {
        require(msg.sender != creator);

        contributions[msg.sender] = contributions[msg.sender] + msg.value;
        currentBalance = currentBalance + msg.value;
        contributorAddresses.push(msg.sender);
        emit FundingReceived(msg.sender, msg.value, currentBalance);
        
        if (msg.value >= 10000000000000000000) {
            addPledge();
        }

        checkIfFundingCompleteOrExpired();
    }

    function addPledge() internal inState(State.Fundraising) {
        if (msg.value <= 50000000000000000000) {
            contributionWithPledge[msg.sender] = uint(Pledge.Starter);
        } else if (msg.value <= 150000000000000000000) {
            contributionWithPledge[msg.sender] = uint(Pledge.Silver);
        } else if (msg.value <= 450000000000000000000) {
            contributionWithPledge[msg.sender] = uint(Pledge.Gold);
        }
    }

    function getPledge(address _contributor) external view returns(uint pledge) {
        return contributionWithPledge[_contributor];
    }

    /** @dev Function to change the project state depending on conditions.
      */
    function checkIfFundingCompleteOrExpired() public inState(State.Fundraising) {
        if (currentBalance >= amountGoal) {
            state = State.Successful;
            payOut();
        } else if (block.timestamp > raiseBy)  {
            state = State.Expired;
            refundAll();
        }
        completeAt = block.timestamp;
    }

    /** @dev Function to give the received funds to project starter.
      */
    function payOut() internal inState(State.Successful) {
        totalRaised = currentBalance;
        currentBalance = 0;

        if (creator.send(totalRaised)) {
            emit CreatorPaid(creator);
            state = State.Successful;
        } else {
            currentBalance = totalRaised;
        }
    }

    /** @dev Function to retrieve donated amount when a project expires.
      */
    function refundAll() internal inState(State.Expired) {
        require(contributorAddresses.length > 0, "No contributions found");

        uint contributorsCount = contributorAddresses.length;
        uint refundedCount = 0;
        for (uint i = 0; i < contributorsCount; i++) {
            address contributorAddress = contributorAddresses[i];
            uint amountToRefund = contributions[contributorAddress];
            require(amountToRefund > 0, "No amount to refund");

            if (payable(contributorAddress).send(amountToRefund)) {
                contributions[contributorAddress] = 0;
                currentBalance = currentBalance - amountToRefund;
            }

            refundedCount = i;
        }

        if (contributorsCount == refundedCount) {
            state = State.UnSuccessful;
        }
        
        emit RefundContributors(
            contributorsCount,
            refundedCount,
            contributorsCount == refundedCount
        );
    }

    /** @dev Function to retrieve donated amount when a project expires.
      */
    function getRefund() public inState(State.Expired) returns (bool) {
        require(contributions[msg.sender] > 0);

        uint amountToRefund = contributions[msg.sender];
        contributions[msg.sender] = 0;

        if (!payable(msg.sender).send(amountToRefund)) {
            contributions[msg.sender] = amountToRefund;
            return false;
        } else {
            currentBalance = currentBalance - amountToRefund;
        }

        return true;
    }

    /** @dev Function to get specific information about the project.
      */
    function getDetails() public view returns 
    (
        address payable projectStarter,
        string memory projectTitle,
        string memory projectDesc,
        uint256 deadline,
        State currentState,
        uint256 currentAmount,
        uint256 goalAmount
    ) {
        projectStarter = creator;
        projectTitle = title;
        projectDesc = description;
        deadline = raiseBy;
        currentState = state;
        currentAmount = currentBalance;
        goalAmount = amountGoal;
    }
}