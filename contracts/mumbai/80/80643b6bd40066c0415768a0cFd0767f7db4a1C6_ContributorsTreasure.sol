/**
 *Submitted for verification at polygonscan.com on 2022-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ContributorsTreasure {
    address[] public contributors;
    uint16 deleteCount;
    address public operator;

    modifier onlyOperator {
        require(msg.sender == operator, "Cannot");
        _;
    }

    constructor() {
        operator = msg.sender;
    }

    function addContributor(address contributor) public onlyOperator {
        bool flag = true;
        for (uint256 i = 0; i < contributors.length; i++) {
            if (contributors[i] == contributor) {
                flag = false;
            }
        }
        if (flag) {
            contributors.push(contributor);
        }
    }

    function removeContributor(address contributor) public {
        require(contributor == msg.sender, "Cannot");
        for (uint256 i = 0; i < contributors.length; i++) {
            if (contributors[i] == contributor) {
                delete contributors[i];
                deleteCount++;
            }
        }
    }

    function payContributors() public onlyOperator payable{
        uint256 totalMoney = address(this).balance;
        uint256 perAccount = totalMoney / (contributors.length - deleteCount);
        for (uint256 a = 0; a < contributors.length; a++) {
            if (contributors[a] != address(0)) {
                payable(contributors[a]).transfer(perAccount);
            }
        }
    }

    receive() external payable {}

    fallback() external payable {}
}