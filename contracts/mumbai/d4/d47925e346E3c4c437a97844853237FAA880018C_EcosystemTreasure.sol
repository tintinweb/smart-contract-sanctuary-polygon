/**
 *Submitted for verification at polygonscan.com on 2022-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract EcosystemTreasure {
    address[] public projects;
    uint16 deleteCount;
    address public operator;

    modifier onlyOperator {
        require(msg.sender == operator, "Cannot");
        _;
    }

    constructor() {
        operator = msg.sender;
    }

    function addProject(address project_Wallet) private onlyOperator {
        bool flag = true;
        for (uint256 i = 0; i < projects.length; i++) {
            if (projects[i] == project_Wallet) {
                flag = false;
            }
        }
        if (flag) {
            projects.push(project_Wallet);
        }
    }

    function removeProject(address project_Wallet) public {
        require(project_Wallet == msg.sender, "Cannot");
        for (uint256 i = 0; i < projects.length; i++) {
            if (projects[i] == project_Wallet) {
                delete projects[i];
                deleteCount++;
            }
        }
    }

    function payProjects() public onlyOperator payable {
        uint256 totalMoney = address(this).balance;
        uint256 perAccount = totalMoney / (projects.length - deleteCount);
        for (uint256 a = 0; a < projects.length; a++) {
            if (projects[a] != address(0)) {
                payable(projects[a]).transfer(perAccount);
            }
        }
    }

    receive() external payable {}

    fallback() external payable {}
}