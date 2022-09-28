// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract FunTogether {

    struct Project {
        address creator;
        uint256 totalSupply;
        uint256 itemPrice;
        uint256 deadline;
        bool settled;
        address[] contributors;
    }

    event ProjectCreated(uint256 id, string ipfsCid);
    event ProjectContribution(uint256 id, address contributor);
    event ProjectContributionsClaimed(uint256 id);

    uint256 public projectCount = 0;
    mapping(uint256 => Project) public projects;

    function createProject(string calldata ipfsCid, uint256 totalSupply, uint256 itemPrice, uint256 deadline) public {
        // todo: creator wallet is whitelisted
        // require(whitelistedCreators[msg.sender], "Creation of the project is not allowed for the address");
        require(deadline > block.timestamp, "Can't create a project with deadline in the past");

        Project memory project;
        project.creator = msg.sender;
        project.totalSupply = totalSupply;
        project.itemPrice = itemPrice;
        project.deadline = deadline;
        projects[projectCount] = project;

        emit ProjectCreated(projectCount, ipfsCid);

        projectCount++;
    }

    function contribute(uint256 projectId) public payable {
        Project storage project = projects[projectId];

        require(project.deadline > block.timestamp, "Can't contribute after deadline");
        require(msg.value == project.itemPrice, "Invalid amount");
        require(project.contributors.length < project.totalSupply, "Contributors limit reached");

        project.contributors.push(msg.sender);

        emit ProjectContribution(projectId, msg.sender);
    }

    function claimSuccessful(uint256 projectId) public {
        Project storage project = projects[projectId];

        require(project.creator == msg.sender, "Can be claim only by project creator");
        require(project.contributors.length == project.totalSupply, "Project goal is not reached yet");

        project.settled = true;
        uint raisedAmount = project.totalSupply * project.itemPrice;

        emit ProjectContributionsClaimed(projectId);

        (bool sent,) = payable(msg.sender).call{value : raisedAmount}("");
        require(sent, "Failed to send raised amount to the creator");
    }
}