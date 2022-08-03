/**
 *Submitted for verification at polygonscan.com on 2022-08-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract ImGrowsReports {
    mapping(bytes32 => string) reports;

    event transaction(address user, string assessmentId);

    function addReport(string memory _assessmentId, string memory _data) public returns (bool) {
        emit transaction(msg.sender,_assessmentId);
        bytes32 hash = keccak256(abi.encodePacked(_assessmentId));
        reports[hash] = _data;
        return true;
    }

    
    function getReport(string memory _assessmentId) public view returns (string memory) {
        bytes32 hash = keccak256(abi.encodePacked(_assessmentId));
        return reports[hash];
    }
}