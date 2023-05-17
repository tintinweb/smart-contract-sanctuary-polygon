/**
 *Submitted for verification at polygonscan.com on 2023-05-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Airdrop {
    address[] public applicants;
    mapping(address => uint256) public applied;

    event Applied(address applicant, uint256 timestamp);

    function applyForAirdrop() external {
        require(applied[msg.sender] == 0, "Already applied");
        applicants.push(msg.sender);
        applied[msg.sender] = block.timestamp;

        emit Applied(msg.sender, block.timestamp);
    }

    function length() external view returns (uint256) {
        return applicants.length;
    }

    function slice(uint256 start, uint256 end) external view returns (address[] memory list) {
        require(applicants.length > end && end >= start, "Args error");
        list = new address[](end + 1 - start);
        uint256 j = 0;
        for (uint256 i = start; i <= end; i++) {
            list[j++] = applicants[i];
        }
    }
}