// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

contract ProjectTracker {
    // Mapping from project ID to project data
    mapping(string => Project) public projects;

    // Array to track admin addresses
    address[] public admins;

    // Modifier to check if the caller is an admin
    modifier onlyAdmin() {
        bool isAdmin = false;
        for (uint256 i = 0; i < admins.length; i++) {
            if (admins[i] == msg.sender) {
                isAdmin = true;
                break;
            }
        }
        require(isAdmin, "Only admins can call this function");
        _;
    }

    // Structure for storing project data
    struct Project {
        string id;
        string name;
        uint256 funding;
        uint256 balance;
        uint256 impactGoal;
        uint256 rating;
        bool isCommissioned;
        address[] teamMembers;
    }

    // Constructor to set the deployer as the first admin
    constructor() {
        admins.push(msg.sender);
    }

    function addAdmin(address account) external onlyAdmin returns (bool) {
        admins.push(account);
        return true;
    }

    // Function to add a new project
    function addProject(
        string memory id,
        string memory name,
        uint256 funding,
        uint256 impactGoal,
        uint256 rating,
        bool isCommissioned,
        address[] memory teamMembers
    ) public {
        // Create a new project object
        Project memory newProject = Project(
            id,
            name,
            funding,
            0,
            impactGoal,
            rating,
            isCommissioned,
            teamMembers
        );

        // Add the new project to the mapping
        projects[newProject.id] = newProject;
    }

    // Function to transfer MATIC to a project's balance
    function fundProject(string memory projectId, uint256 amount) public payable {
        // Get the project data
        Project memory project = projects[projectId];

        // Check if the sender has enough funds
        require(msg.value >= amount, "Insufficient funds");

        // Update the project's balance
        project.balance += msg.value;

        // Update the project's funding
        project.funding += amount;

        // Emit an event to notify listeners of the transfer
        emit FuncProject(projectId, amount);
    }

    // Function to update the rating of a project by ID
    function updateRating(string memory projectId, uint256 newRating) public {
        // Get the project data
        Project storage project = projects[projectId];

        // Update the project's rating
        project.rating = newRating;
    }

    // Function to allow a team member to withdraw funds from a project's balance
    function withdrawFunds(string memory projectId, uint256 amount) public {
        // Get the project data
        Project storage project = projects[projectId];

        // Check if the sender is a team member
        require(isTeamMember(projectId, msg.sender), "Not a team member");

        // Check if the project has sufficient balance
        require(project.balance >= amount, "Insufficient project balance");

        // Update the project's balance
        project.balance -= amount;

        // Transfer the funds to the sender
        payable(msg.sender).transfer(amount);

        // Emit an event to notify listeners of the withdrawal
        emit WithdrawFunds(projectId, msg.sender, amount);
    }

    // Function to update the commission status of a project
    function updateCommissionStatus(string memory projectId, bool isCommissioned) public onlyAdmin {
        // Get the project data
        Project storage project = projects[projectId];

        // Update the commission status of the project
        project.isCommissioned = isCommissioned;
    }

    // Function to check if an address is a team member of a project
    function isTeamMember(string memory projectId, address teamMember) internal view returns (bool) {
        // Get the project data
        Project storage project = projects[projectId];

        // Check if the team member's address is in the project's team members list
        for (uint256 i = 0; i < project.teamMembers.length; i++) {
            if (project.teamMembers[i] == teamMember) {
                return true;
            }
        }

        return false;
    }

    // Event to notify listeners of a MATIC transfer
    event FuncProject(string projectId, uint256 amount);

    // Event to notify listeners of a funds withdrawal
    event WithdrawFunds(string projectId, address teamMember, uint256 amount);
}