// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract fir1 {
    address public officer;
    address public owner;
    uint256 public nextId;
    uint256[] public pendingApprovals;
    uint256[] public pendingResolutions;
    uint256[] public resolvedCases;

    constructor(address _officer) {
        owner = msg.sender;
        officer = _officer;
        nextId = 1;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner of this smart contract");
        _;
    }

    modifier onlyOfficer() {
        require(msg.sender == officer, "You are not a registered officer of this smart contract");
        _;
    }

    struct Complaint {
        uint256 id;
        address complaintRegisteredBy;
        string title;
        string description;
        string approvalRemark;
        string resolutionRemark;
        bool isApproved;
        bool isResolved;
        bool exists;
        string adharID;
        string city;
        string pincode;
        string phone;
        string email;
    }

    mapping(uint256 => Complaint) public complaints;

    event ComplaintFiled(uint256 id, address complaintRegisteredBy, string title);

    function fileComplaint(
        string memory _title,
        string memory _description,
        string memory _adharID,
        string memory _city,
        string memory _pincode,
        string memory _phone,
        string memory _email
    ) public {
        Complaint storage newComplaint = complaints[nextId];
        newComplaint.id = nextId;
        newComplaint.complaintRegisteredBy = msg.sender;
        newComplaint.title = _title;
        newComplaint.description = _description;
        newComplaint.approvalRemark = "Pending Approval";
        newComplaint.resolutionRemark = "Pending Resolution";
        newComplaint.isApproved = false;
        newComplaint.isResolved = false;
        newComplaint.exists = true;
        newComplaint.adharID = _adharID;
        newComplaint.city = _city;
        newComplaint.pincode = _pincode;
        newComplaint.phone = _phone;
        newComplaint.email = _email;
        emit ComplaintFiled(nextId, msg.sender, _title);
        nextId++;
    }

    function approveComplaint(uint256 _id, string memory _approvalRemark) public onlyOfficer {
        require(complaints[_id].exists == true, "This complaint id does not exist");
        require(complaints[_id].isApproved == false, "Complaint is already approved");
        complaints[_id].isApproved = true;
        complaints[_id].approvalRemark = _approvalRemark;
    }

    function discardComplaint(uint256 _id, string memory _approvalRemark) public onlyOfficer {
        require(complaints[_id].exists == true, "This complaint id does not exist");
        require(complaints[_id].isApproved == false, "Complaint is already approved");
        complaints[_id].exists = false;
        complaints[_id].approvalRemark = string(abi.encodePacked("This complaint is rejected. Reason: ", _approvalRemark));
    }

    function resolveComplaint(uint256 _id, string memory _resolutionRemark) public onlyOfficer {
        require(complaints[_id].exists == true, "This complaint id does not exist");
        require(complaints[_id].isApproved == true, "Complaint is not yet approved");
        require(complaints[_id].isResolved == false, "Complaint is already resolved");
        complaints[_id].isResolved = true;
        complaints[_id].resolutionRemark = _resolutionRemark;
    }

    function calcPendingApprovalIds() public {
        delete pendingApprovals;
        for (uint256 i = 1; i < nextId; i++) {
            if (complaints[i].isApproved == false && complaints[i].exists == true) {
                pendingApprovals.push(complaints[i].id);
            }
        }
    }

    function calcPendingResolutionIds() public {
        delete pendingResolutions;
        for (uint256 i = 1; i < nextId; i++) {
            if (complaints[i].isResolved == false && complaints[i].isApproved == true && complaints[i].exists == true) {
                pendingResolutions.push(complaints[i].id);
            }
        }
    }

    function calcResolvedIds() public {
        delete resolvedCases;
        for (uint256 i = 1; i < nextId; i++) {
            if (complaints[i].isResolved == true) {
                resolvedCases.push(complaints[i].id);
            }
        }
    }

    function setOfficerAddress(address _officer) public onlyOwner {
        officer = _officer;
    }
}