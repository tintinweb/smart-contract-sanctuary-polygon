/**
 *Submitted for verification at polygonscan.com on 2023-04-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
//import "hardhat/console.sol";

contract CrowdFunding {

    address payable public adminFeeAddress;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

enum Status { active, inactive, completed, failed, cancelled }

    struct CreateProject {

        bytes32 projectID;
        string projectDataId;
        //string name;
        //string description;
        //string image_url;
        address creator;
        uint256 amountDonated;
        uint256 goal;
        uint256 deadline;
        Status status;
        uint256 dateCreated;
    }

    event NewProjectCreated(
        bytes32 projectId,
        string projectDataId,
        address creatorAddress,
        uint256 projectGoal,
        uint256 deadline,
        uint256 dateCreated
    );

    event FundReceived(bytes32 projectId, address backer, uint256 amount);

    event FundWithdrawn(bytes32 projectId, uint256 amountDonated);

    event ProjectCancelled(bytes32 projectId);

    mapping(bytes32 => CreateProject) public idToProject;

    function createNewProject(
        string calldata projectDataId,
        uint256 goal,
        uint256 deadline

    ) external {
        bytes32 projectId = keccak256(abi.encodePacked(
            msg.sender,
            address(this),
            goal,
            deadline,
            block.timestamp
        ));

        idToProject[projectId] = CreateProject(
            projectId,
            projectDataId,
            msg.sender,
            0,
            goal,
            deadline,
            Status.active,
            block.timestamp
        );

        emit NewProjectCreated(projectId, projectDataId, msg.sender, goal, deadline, block.timestamp);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can access this function.");
        _;
    }

    modifier onlyCreator(address creator) {
        require(msg.sender == creator, "Only creator can access this function.");
        _;
    }

    modifier isDeadlinePassed(bytes32 projectId) {
        require(
            block.timestamp < idToProject[projectId].deadline,
            "Crowd Funding deadline has passed. Please try again later."
        );
        _;
    }

    function getBalance() public onlyOwner view returns (uint256) {
        return address(this).balance;
    }

    function contribute(bytes32 projectId) public payable isDeadlinePassed (projectId){
        require(
            idToProject[projectId].status == Status.active,
            "You cant contribute to InActive Project."
        );
        require(
            msg.value > 0,
            "You must send some Ether to contribute to the project."
        );

        idToProject[projectId].amountDonated += msg.value;

        if (idToProject[projectId].amountDonated >= idToProject[projectId].goal) {
            idToProject[projectId].status = Status.completed;
        }

        emit FundReceived(projectId, msg.sender, msg.value);
    }

    function withdraw(bytes32 projectId) public onlyCreator(msg.sender) {
        require(
            idToProject[projectId].status == Status.completed,
            "Project is not completed."
        );
        require(
            idToProject[projectId].amountDonated > 0,
            "There is no balance to withdraw."
        );

        idToProject[projectId].status = Status.completed;

        (bool sent, ) = idToProject[projectId].creator.call{value: idToProject[projectId].amountDonated}("");

        if (!sent) {
            idToProject[projectId].status = Status.failed;
        }

        require(sent, "Failed to send Ether");

        emit FundWithdrawn(projectId, idToProject[projectId].amountDonated);
    }

    function cancelProject(bytes32 projectId) public onlyCreator(msg.sender) {
        require(
            idToProject[projectId].status == Status.active,
            "Project is not active."
        );
        require(
            idToProject[projectId].amountDonated > 0,
            "There is no balance to withdraw."
        );

        idToProject[projectId].status = Status.cancelled;

        emit ProjectCancelled(projectId);
    }

    function getProject(bytes32 projectId) public view returns (CreateProject memory) {
        return idToProject[projectId];
    }

    // Admin Functions
    function setAdminFeeAddress(
        address payable _adminFeeAddress
    ) public onlyOwner {
        require(_adminFeeAddress != address(0), "Invalid admin fee address");
        adminFeeAddress = _adminFeeAddress;
    }

    // Special function
    receive() external payable {} // allow the contract to receive tokens

    fallback() external payable {} // allow the contract to receive tokens


}