/**
 *Submitted for verification at polygonscan.com on 2022-09-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

// information we want to store on the chain
contract InterplanetaryFonts {

    event NewProjectCreated(
    bytes32 projectID,
    address creatorAddress,
    uint256 projectTimestamp,
    uint256 deposit,
    string projectDataCID
    );

    event NewCreator(bytes32 projectID, address creatorAddress);

    event NewCollaborator(bytes32 projectID, address collaboratorAddress);

    event NewFunder(bytes32 projectID, address funderAddress);

    event DepositsPaidOut(bytes32 projectID);

    struct CreateProject {
        bytes32 projectID;
        string projectDataCID; // reference to an IPFS hash
        address projectCreator; // address of who created the project
        uint256 projectTimestamp; // when the project will start ?
        uint256 deposit; // deposit to request the project to start
        address[] projectCollaborators; // list of addresses of Creators that will collaborate in the project
        address[] projectFunders; // list of addresses of Funders        
        bool paidOut;
}

// store and look up events by some identifier
mapping(bytes32 => CreateProject) public idToProject;



function createNewProject(
    uint256 projectTimestamp,
    uint256 deposit,
    string calldata projectDataCID
) external {
    
    // generate a projectID based on other things passed in to generate a hash
    bytes32 projectID = keccak256(
        abi.encodePacked(
            msg.sender,
            address(this),
            projectTimestamp,
            deposit        
            )
    );

    address[] memory projectCollaborators; 
    address[] memory projectFunders;


    // this creates a new CreateProject struct and adds it to the idToProject mapping
    idToProject[projectID] = CreateProject(
        projectID,
        projectDataCID,
        msg.sender,
        projectTimestamp,
        deposit,
        projectCollaborators,
        projectFunders,
        false
    );

    emit NewProjectCreated(
    projectID,
    msg.sender,
    projectTimestamp,
    deposit,
    projectDataCID
    );

}


function addNewCollaborator(bytes32 projectID) external payable {
    // look up event from our mapping
    CreateProject storage myProject = idToProject[projectID];

    // require that msg.sender isn't already in myProject.projectCollaborators yet
    for (uint8 i = 0; i < myProject.projectCollaborators.length; i++) {
        require(myProject.projectCollaborators[i] != msg.sender, "ALREADY COLLABORATING");
    }

    myProject.projectCollaborators.push(payable(msg.sender));

    emit NewCollaborator(projectID, msg.sender);

}

}