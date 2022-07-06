/**
 *Submitted for verification at polygonscan.com on 2022-07-05
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Marketplace {
    event newProject(string cid, address owner, uint256 price);
    event newAccess(string cid, address buyer);

    struct Project {
        string cid;
        address owner;
        uint256 price;
        address[] accessList;
    }

    mapping(string => Project) public idToProject;

    // when a user uploads a new set of files
    function createProject(string calldata cid, uint256 price) external {
        require(idToProject[cid].owner == address(0), "CID ALREADY EXISTS");
        address[] memory accessList;
        idToProject[cid] = Project(cid, msg.sender, price, accessList);
        emit newProject(cid, msg.sender, price);
    }

    // when a user buys access to a private project
    function buyAccess(string calldata cid) external payable {
        Project storage thisProject = idToProject[cid];
        require(msg.value == thisProject.price, "VALUE MUST MATCH PRICE");
        thisProject.accessList.push(msg.sender);
        emit newAccess(cid, msg.sender);
    }

    // checks if a user address has access to a project
    function hasAccess(string calldata cid, address user)
        external
        view
        returns (bool access)
    {
        Project storage thisProject = idToProject[cid];
        if (thisProject.price > 0) {
            for (uint8 i = 0; i < thisProject.accessList.length; i++) {
                if (thisProject.accessList[i] == user) {
                    return true;
                }
            }
            return false;
        } else {
            return true;
        }
    }
}