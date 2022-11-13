// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

contract Request {

    mapping (uint => RequestDetails) public requestDetails;
    uint256 public numRequestDetails;

    function saveRequestDetails(string memory hospitalName, string memory city, string memory country,
                                string memory emailId, uint256 amount, string memory description)
                                external {
        

        requestDetails[numRequestDetails].hospitalName = hospitalName;
        requestDetails[numRequestDetails].country = country;
        requestDetails[numRequestDetails].city = city;
        requestDetails[numRequestDetails].emailId = emailId;
        requestDetails[numRequestDetails].amount = amount;
        requestDetails[numRequestDetails].description = description;
        requestDetails[numRequestDetails].requester = msg.sender;
        requestDetails[numRequestDetails].isActive = true;
        requestDetails[numRequestDetails].amountReceived = 0;

        numRequestDetails++;
    }   

    struct RequestDetails{
        string hospitalName;
        string country;
        string city;
        string emailId;
        uint256 amount;
        string description;
        address requester;
        bool isActive; 
        uint256 amountReceived;
    }
}