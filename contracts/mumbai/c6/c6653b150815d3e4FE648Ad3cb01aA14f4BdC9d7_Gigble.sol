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
        string title;
        address payable client;
        address payable freelancer;
        uint256 budget;
        string description;
        string keyword;
        uint256 deadline;
        bool completed;
        bool paid;
        State state;
    }

    // List of all projects mapping over all projects
    Project[] public projects;

    error InvalidState();

    modifier inState(State state_) {
        if (state != state_) revert InvalidState();
        _;
    }

    // Events to be emitted for various actions

    
    event ProjectCreated(
        uint256 indexed projectId,
        string email,
        string title,
        string description,
        uint256 budget,
        uint256 deadline,
        string keyword,
        address payable client
    );
    event ProjectAccepted(uint256 indexed projectId);
    event PaymentReleased(uint256 indexed projectId);
    event PaymentRefunded(uint256 indexed projectId);

    

    address payable public platformAddress;
    uint256 public platformFee;
    uint256 public numberOfProjects;

    State public state;

    // Constructor function to set the platform address and fee
    constructor(address payable _platformAddress, uint256 _platformFee) {
        platformAddress = _platformAddress;
        platformFee = _platformFee;
        state = State.Active;
        numberOfProjects = 0;
    }

    // Function to create a new project and lock budget on platform address
    function createProject(
        string memory _email,
        string memory _title,
        string memory _description,
        uint256 _budget,
        uint256 _deadline,
        string memory _keyword
    ) public payable inState(State.Active) returns (uint256)  {
        Project storage project = projects[numberOfProjects];
    
   

        
        require(project.deadline < block.timestamp, "The deadline should be a date in the future.");
            project.email= _email;
            project.title = _title;
            project.description= _description;
            project.budget= _budget;
            project.deadline= _deadline;
            project.keyword= _keyword;
            project.client= payable(msg.sender);
            project.freelancer= payable(address(0));
            project.completed= false;
            project.paid= false;
            state= State.Active;

            
        

        numberOfProjects++;


        emit ProjectCreated(
            numberOfProjects,
            project.email,
            project.title,
            project.description,
            project.budget,
            project.deadline,
            project.keyword,
            project.client
        );

             

        return numberOfProjects -1;
       
    }

    // Function for freelancers to accept a project
    function acceptProject(uint256 _projectId) public {
        Project storage project = projects[_projectId];
        require(project.freelancer == address(0), "Project already accepted");
        require(
            msg.sender != project.client,
            "Only Freelances can accept the project"
        );
        project.freelancer = payable(msg.sender);
        emit ProjectAccepted(_projectId);

    }

    // Function to release escrowed budget to the freelancer
    function releasePayment(uint256 _projectId, uint256 _amount) public payable {
        Project storage project = projects[_projectId];
        require(
            project.client == msg.sender,
            "Only the Client can release payment"
        );
        require(!project.completed, "Project already completed");
        
        uint256 fee = (_amount * platformFee) / 100;
        platformAddress.transfer(fee);
        uint256 amountForFreelance = project.budget - fee;
        project.completed = true;
        project.paid = true;
        project.freelancer.transfer(amountForFreelance);
        
            
        
        emit PaymentReleased(_projectId);
    }



    function getProjects() public view returns (Project[] memory) {
        Project[] memory allProjects = new Project[](numberOfProjects);

        for(uint i = 0; i < numberOfProjects; i++) {
            Project storage item = projects[i];

            allProjects[i] = item;
        }

        return allProjects;
    }
}