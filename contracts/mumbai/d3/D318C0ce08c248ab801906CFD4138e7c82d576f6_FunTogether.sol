// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract FunTogether {

    struct Project {
        address creator;
        uint256 totalSupply;
        uint256 itemPrice;
        uint256 deadline;
        bool settled;
        uint256 contributionCount;
    }

    struct Contributor {
        uint256 amount;
        bool refunded;
    }

    event ProjectCreated(uint256 id, string ipfsCid);
    event ProjectContribution(uint256 id, address contributor);
    event ProjectContributionsClaimed(uint256 id);
    event ProjectRefundClaimed(uint256 id, address contributor);

    uint256 public projectCount = 0;
    mapping(uint256 => Project) public projects;
    mapping(uint256 => mapping(address => Contributor)) contributors;

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
        require(project.contributionCount < project.totalSupply, "Contributions limit reached");

        project.contributionCount += 1;

        Contributor storage contributor = contributors[projectId][msg.sender];
        contributor.amount += msg.value;

        emit ProjectContribution(projectId, msg.sender);
    }

    function claimSuccessful(uint256 projectId) public {
        Project storage project = projects[projectId];

        require(project.creator == msg.sender, "Can be claim only by project creator");
        require(project.contributionCount == project.totalSupply, "Project goal is not reached yet");

        project.settled = true;
        uint raisedAmount = project.totalSupply * project.itemPrice;

        emit ProjectContributionsClaimed(projectId);

        (bool sent,) = payable(msg.sender).call{value : raisedAmount}("");
        require(sent, "Failed to send raised amount to the creator");
    }

    function claimFailed(uint256 projectId) public {
        Project memory project = projects[projectId];

        require(!project.settled, "Project was successfully settled");
        require(project.deadline < block.timestamp, "Project deadline has not passed yet");
        require(project.contributionCount < project.totalSupply, "Project was successfully funded");

        Contributor storage contributor = contributors[projectId][msg.sender];
        require(contributor.amount > 0, "Message sender didn't contribute anything");
        require(!contributor.refunded, "Contributor was already refunded");
        contributor.refunded = true;

        emit ProjectRefundClaimed(projectId, msg.sender);

        (bool sent,) = payable(msg.sender).call{value : contributor.amount}("");
        require(sent, "Failed to send refund amount to the contributor");
    }
}