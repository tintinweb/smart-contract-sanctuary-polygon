// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Gigble {
    // Enum for project state
    enum State {
        Inactive,
        Active,
        Completed
    }

    // Structure to hold project details
    struct Project {
        string email;
        address payable client;
        address payable freelancer;
        uint256 budget;
        string description;
        uint256 deadline;
        bool completed;
        bool paid;
        State state;
    }

    error InvalidState();

    modifier inState(State state_) {
        if (state != state_) revert InvalidState();
        _;
    }

    // Events to be emitted for various actions
    event ProjectCreated(
        uint256 indexed projectId,
        string email,
        string description,
        uint256 budget,
        uint256 deadline,
        address payable client
    );
    event ProjectAccepted(uint256 indexed projectId);
    event PaymentReleased(uint256 indexed projectId);
    event PaymentRefunded(uint256 indexed projectId);

    // List of all projects
    Project[] public projects;

    address payable public platformAddress;
    uint256 public platformFee;
    uint256 public projectIdCounter;

    State public state;

    // Constructor function to set the platform address and fee
    constructor(address payable _platformAddress, uint256 _platformFee) {
        platformAddress = _platformAddress;
        platformFee = _platformFee;
        state = State.Inactive;
        projectIdCounter = 0;
    }

    // Function to create a new project and lock budget on platform address
    function createProject(
        string calldata _email,
        string calldata _description,
        uint256 _deadline
    ) external payable inState(State.Inactive) {
        require(
            msg.value > 0,
            "Please provide a non-zero project budget as the value of the transaction."
        );

        Project memory project = Project({
            email: _email,
            description: _description,
            budget: msg.value,
            deadline: _deadline,
            client: payable(msg.sender),
            freelancer: payable(address(0)),
            completed: false,
            paid: false,
            state: State.Active
        });

        projects.push(project);
        projectIdCounter++;

        emit ProjectCreated(
            projectIdCounter,
            project.email,
            project.description,
            project.budget,
            project.deadline,
            project.client
        );
    }

    // Function for freelancers to accept a project and release escrowed budget
    function acceptProject(uint256 _projectId) external {
        Project storage project = projects[_projectId];
        require(project.freelancer == address(0), "Project already accepted");
        require(
            msg.sender == project.client,
            "Only Client can accept the project"
        );
        project.freelancer = payable(msg.sender);
        uint256 fee = (project.budget * platformFee) / 100;
        platformAddress.transfer(fee);
        uint256 amount = project.budget - fee;
        project.completed = true;
        project.paid = true;
        project.freelancer.transfer(amount);
        emit ProjectAccepted(_projectId);
        emit PaymentReleased(_projectId);
    }

    // Function for platform address to refund payment to client
    function refundPayment(uint256 _projectId) external {
        Project storage project = projects[_projectId];
        require(
            msg.sender == platformAddress,
            "Only platform can refund payment"
        );
        require(!project.completed, "Project already completed");
        require(block.timestamp > project.deadline, "Deadline not yet passed");
        project.completed = true;
        project.state = State.Completed;
        project.client.transfer(project.budget);

        emit PaymentRefunded(_projectId);
    }
}