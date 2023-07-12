/**
 *Submitted for verification at polygonscan.com on 2023-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Reporting {
    struct Report {
        bytes32 imageHash;
        address radiologist;
        string content;
    }

    mapping(bytes32 => Report) private reports;

    event ReportGenerated(bytes32 indexed imageHash, address indexed radiologist, string content);

    function generateReport(bytes32 _imageHash, string memory _content) public {
        require(reports[_imageHash].imageHash == bytes32(0), "Report already generated");
        
        reports[_imageHash] = Report(_imageHash, msg.sender, _content);
        emit ReportGenerated(_imageHash, msg.sender, _content);
    }

    function getReport(bytes32 _imageHash) public view returns (bytes32, address, string memory) {
        Report memory report = reports[_imageHash];
        require(report.imageHash != bytes32(0), "Report not found");
        
        return (report.imageHash, report.radiologist, report.content);
    }
}