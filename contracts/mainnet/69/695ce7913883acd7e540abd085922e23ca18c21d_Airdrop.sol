/**
 *Submitted for verification at polygonscan.com on 2023-05-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Airdrop {
    address[] public applicants;
    mapping(address => uint256) public applied;
    mapping(address => string) public available;

    address public admin;

    event Applied(address applicant, uint256 timestamp);
    event AdminUpdated(address _admin);

    constructor() {
        admin = msg.sender;
    }

    function setAdmin(address _admin) public {
        require(msg.sender == admin, "Not Granted");
        require(_admin != admin && _admin != address(0), "Args error");

        admin = _admin;
        emit AdminUpdated(_admin);
    }

    function applyForAirdrop() external {
        require(applied[msg.sender] == 0, "Already applied");
        applicants.push(msg.sender);
        applied[msg.sender] = block.timestamp;

        emit Applied(msg.sender, block.timestamp);
    }

    function length() external view returns (uint256) {
        return applicants.length;
    }

    function slice(uint256 start, uint256 end) external view returns (address[] memory addrs, string[] memory names) {
        require(applicants.length > end && end >= start, "Args error");
        addrs = new address[](end + 1 - start);
        names = new string[](end + 1 - start);
        uint256 j = 0;
        for (uint256 i = start; i <= end; i++) {
            address ai = applicants[i];
            addrs[j] = ai;
            names[j++] = available[ai];
        }
    }

    function airdrop(uint256 start, string[] calldata names) external {
        require(msg.sender == admin, "Not granted");
        uint256 _length = names.length;
        for (uint256 i = 0; i < _length; i++) {
            available[applicants[start + i]] = names[i];
        }
    }
}