/**
 *Submitted for verification at polygonscan.com on 2022-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Router {
    uint256 public totalMoney;
    address public operator;
    address contributors = 0x80643b6bd40066c0415768a0cFd0767f7db4a1C6;
    address holders = 0x0Fd07B8556c2fa4dA9B4489f47D3abC16fE7a5eC;
    address holdersYield = 0xdA3f37657F2264F512C0dEcff827f16B6Ac581a1;
    address reopen = 0xe583327E8D32184aA21475f98c76c6900aB40a17;
    address ecosystem = 0xd47925e346E3c4c437a97844853237FAA880018C;

    modifier onlyOperator {
        require(msg.sender == operator, "Cannot");
        _;
    }

    constructor() {
        operator = msg.sender;
    }

    function transferFunds(
        uint256 contributorsPercent_,
        uint256 projectPercent_,
        uint Season_,
        address project
    ) public payable {
        totalMoney = address(this).balance / 100;
        if (Season_ == 1) {
            uint256 projectContributors = (totalMoney * 56) / 100;
            payable(reopen).transfer(totalMoney * 10);
            payable(project).transfer(projectContributors * projectPercent_);
            payable(contributors).transfer(
                projectContributors * contributorsPercent_
            );
        } else if (Season_ == 2) {
            uint256 projectContributors = (totalMoney * 36) / 100;
            payable(reopen).transfer(totalMoney * 5);
            payable(project).transfer(projectContributors * projectPercent_);
            payable(contributors).transfer(
                projectContributors * contributorsPercent_
            );
            payable(holders).transfer(totalMoney * 25);
        } else {
            uint256 projectContributors = (totalMoney * 30) / 100;
            payable(reopen).transfer(totalMoney * 5);
            payable(project).transfer(projectContributors * projectPercent_);
            payable(contributors).transfer(
                projectContributors * contributorsPercent_
            );
            payable(holders).transfer(totalMoney * 31);
        }
        payable(holdersYield).transfer(totalMoney * 14);
        payable(ecosystem).transfer(totalMoney * 20);
    }

    function addFunds() public payable returns (string memory) {
        return "Hello";
    }

    receive() external payable {}

    fallback() external payable {}
}