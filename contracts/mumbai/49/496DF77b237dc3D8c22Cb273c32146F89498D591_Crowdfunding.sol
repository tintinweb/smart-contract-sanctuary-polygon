// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Crowdfunding
 * @author Ghadi Mhawej
 */

contract Crowdfunding {
    /// @notice general structure of crowdfunding projects

    struct Project {
        uint256 projectID;
        string projectTitle;
        string projectDescription;
        address projectOwner;
        address payable author;
        uint256 projectParticipationAmount;
        uint256 projectTotalFundingAmount;
    }

    uint256 autoIncrementProjectID = 0;

    /// @notice amount contributed by an address to a project

    mapping(uint256 => mapping(address => uint256[])) contributions;

    /// @notice array of all crowdfunding projects

    Project[] projects;

    /**
     * @notice modifier
     * @param indexProject doesn't allow project owner to fund the project
     **/

    modifier contributors(uint256 indexProject) {
        require(
            msg.sender != projects[indexProject].projectOwner,
            "Owner cannot send funds to the project"
        );
        _;
    }

    /**
     * @notice creating a project
     * @param _projectTitle setting the project title
     * @param _projectDescription setting the project desciption
     * @param _projectParticipationAmount minimum amount required to participate
     **/
    function createProject(
        string memory _projectTitle,
        string memory _projectDescription,
        uint256 _projectParticipationAmount
    ) public {
        Project memory project = Project(
            autoIncrementProjectID,
            _projectTitle,
            _projectDescription,
            msg.sender,
            payable(msg.sender),
            _projectParticipationAmount,
            0
        );
        autoIncrementProjectID++;
        projects.push(project);
    }

    /**
     * @notice participating to a project by donating funds to it
     * @param _projectID id of project to donate to
     **/

    function participateToProject(uint256 _projectID)
        public
        payable
        contributors(_projectID)
    {
        require(
            msg.value >= projects[_projectID].projectParticipationAmount,
            "Contribution is less than minimal project participation amount"
        );
        projects[_projectID].author.transfer(msg.value);
        projects[_projectID].projectTotalFundingAmount += msg.value;
        contributions[projects[_projectID].projectID][msg.sender].push(
            msg.value
        );
    }

    /**
     * @notice retrieve all the details of a crowdfunding project
     * @param _projectID id of project to fetch its data
     **/

    function searchForProject(uint256 _projectID)
        public
        view
        returns (
            uint256,
            string memory,
            string memory,
            address,
            uint256,
            uint256
        )
    {
        return (
            projects[_projectID].projectID,
            projects[_projectID].projectTitle,
            projects[_projectID].projectDescription,
            projects[_projectID].projectOwner,
            projects[_projectID].projectParticipationAmount,
            projects[_projectID].projectTotalFundingAmount
        );
    }

    /**
     * @notice retrieve all contributions made by a specific address
     * @param _projectID id of project
     * @param _contributor address of contributor
     **/

    function getContributions(uint256 _projectID, address _contributor)
        public
        view
        returns (address, uint256[] memory)
    {
        return (
            _contributor,
            contributions[projects[_projectID].projectID][_contributor]
        );
    }
}