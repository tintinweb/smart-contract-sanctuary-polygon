// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {
    struct Project {
        string name;
        string description;
        string ipfsHash;
        uint256 goalAmount;
        uint256 currentAmount;
        address payable creator;
    }

    Project[] public projects;
    mapping(address => uint256) public balances;
    mapping(address => bool) public investors;

    event ProjectCreated(uint256 projectId, string name, address creator);
    event ContributionMade(uint256 projectId, address investor, uint256 amount);

    modifier onlyCreator(uint256 _projectId) {
        require(msg.sender == projects[_projectId].creator, "Only the project creator can perform this action");
        _;
    }

    function createProject(string memory _name, string memory _description, string memory _ipfsHash, uint256 _goalAmount) public {
        require(bytes(_name).length > 0, "Project name cannot be empty");
        require(bytes(_description).length > 0, "Project description cannot be empty");
        require(bytes(_ipfsHash).length > 0, "IPFS hash cannot be empty");
        require(_goalAmount > 0, "Goal amount must be greater than zero");

        Project memory newProject = Project({
            name: _name,
            description: _description,
            ipfsHash: _ipfsHash,
            goalAmount: _goalAmount,
            currentAmount: 0,
            creator: payable(msg.sender)
        });

        uint256 projectId = projects.length;
        projects.push(newProject);

        emit ProjectCreated(projectId, _name, msg.sender);
    }

    function contribute(uint256 _projectId) public payable {
        require(_projectId < projects.length, "Invalid project ID");

        Project storage project = projects[_projectId];
        require(msg.value > 0, "Contribution amount must be greater than zero");

        project.currentAmount += msg.value;
        balances[project.creator] += msg.value;
        investors[msg.sender] = true;

        emit ContributionMade(_projectId, msg.sender, msg.value);
    }

    function withdrawFunds() public {
        require(balances[msg.sender] > 0, "No funds available for withdrawal");

        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    function getAllProjects() public view returns (Project[] memory) {
        return projects;
    }
}