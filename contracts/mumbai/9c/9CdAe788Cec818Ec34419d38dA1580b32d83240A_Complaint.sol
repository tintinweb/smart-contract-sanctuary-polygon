// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Complaint {
    address[] public officer;
    address public owner;
    uint256 public nextId;
    uint256[] public pendingApprovals;
    uint256[] public pendingResolutions;
    uint256[] public resolvedCases;

    constructor(address _officer) {
        owner = msg.sender;
        officer.push(_officer);
        nextId = 1;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You are not the owner of this smart contract"
        );
        _;
    }

    modifier onlyOfficer() {
        require(
            exists(msg.sender),
            "You are not registered officer of this smart contract"
        );
        _;
    }

    function exists(address sender) private view returns (bool) {
        for (uint i = 0; i < officer.length; i++) {
            if (officer[i] == sender) {
                return true;
            }
        }
    return false;
    }

    struct complaint {
        uint256 id;
        address complaintRegisteredBy;
        string title;
        string description;
        string date;
        string time;
        string place;
        string approvalRemark;
        string resolutionRemark;
        bool isApproved;
        bool isResolved;
        bool exists;
    }
    mapping(uint256 => complaint) public Complaints;

    event complaintFiled(
        uint256 id,
        address complaintRegisteredBy,
        string title
    );

    event pendingApprovalsEvent(
        complaint complaint
    );

    event pendingResolutionsEvent(
        complaint complaint
    );

    event pendingResolvedEvent(
        complaint complaint
    );

    event getAllComplaintsEvent(
        complaint complaint
    );

    function getAllComplaints() public returns(complaint[] memory) {

        complaint[] memory allComplaints = new complaint[](nextId);

        for (uint256 i = 1; i < nextId; i++) {
            complaint storage c = Complaints[i];
            allComplaints[i-1] = c;
            emit getAllComplaintsEvent(c);
        }
        return allComplaints;
    } 

    function getAllPendingApprovalComplaints() public returns(complaint[] memory) {
        calcPendingApprovalIds();

        complaint[] memory allComplaints = new complaint[](pendingApprovals.length);

        for (uint256 i = 0; i < pendingApprovals.length; i++) {
            complaint storage c = Complaints[pendingApprovals[i]];
            allComplaints[i] = c;
            emit pendingApprovalsEvent(c);
        }
        return allComplaints;
    }

    function getAllResolvedComplaints() public returns(complaint[] memory) {
        calcResolvedIds();

        complaint[] memory allComplaints = new complaint[](resolvedCases.length);

        for (uint256 i = 0; i < resolvedCases.length; i++) {
            complaint storage c = Complaints[resolvedCases[i]];
            allComplaints[i] = c;
            emit pendingResolvedEvent(c);
        }
        return allComplaints;
    }

    function getAllPendingResolutionComplaints() public returns(complaint[] memory) {
        calcPendingResolutionIds();

        complaint[] memory allComplaints = new complaint[](pendingResolutions.length);

        for (uint256 i = 0; i < pendingResolutions.length; i++) {
            complaint storage c = Complaints[pendingResolutions[i]];
            allComplaints[i] = c;
            emit pendingResolutionsEvent(c);
        }
        return allComplaints;
    }

    function fileComplaint(string memory _title, string memory _description, string memory date, string memory time, string memory place)
        public
    {
        complaint storage newComplaint = Complaints[nextId];
        newComplaint.id = nextId;
        newComplaint.complaintRegisteredBy = msg.sender;
        newComplaint.title = _title;
        newComplaint.description = _description;
        newComplaint.date = date;
        newComplaint.time = time;
        newComplaint.place = place;
        newComplaint.approvalRemark = "Pending Approval";
        newComplaint.resolutionRemark = "Pending Resolution";
        newComplaint.isApproved = false;
        newComplaint.isResolved = false;
        newComplaint.exists = true;
        emit complaintFiled(nextId, msg.sender, _title);
        nextId++;
    }

    function approveComplaint(uint256 _id, string memory _approvalRemark)
        public
        onlyOfficer
    {
        require(
            Complaints[_id].exists == true,
            "This complaint id does not exist"
        );
        require(
            Complaints[_id].isApproved == false,
            "Complaint is already approved"
        );
        Complaints[_id].isApproved = true;
        Complaints[_id].approvalRemark = _approvalRemark;
    }

    function discardComplaint(uint256 _id, string memory _approvalRemark)
        public
        onlyOfficer
    {
        require(
            Complaints[_id].exists == true,
            "This complaint id does not exist"
        );
        require(
            Complaints[_id].isApproved == false,
            "Complaint is already approved"
        );
        Complaints[_id].exists = false;
        Complaints[_id].approvalRemark = string.concat(
            "This complaint is rejected. Reason: ",
            _approvalRemark
        );
    }

    function resolveComplaint(uint256 _id, string memory _resolutionRemark, bool isOver)
        public
        onlyOfficer
    {
        require(
            Complaints[_id].exists == true,
            "This complaint id does not exist"
        );
        require(
            Complaints[_id].isApproved == true,
            "Complaint is not yet approved"
        );
        require(
            Complaints[_id].isResolved == false,
            "Complaint is already resolved"
        );
        if (isOver) {
            Complaints[_id].isResolved = true;
        }
        Complaints[_id].resolutionRemark = _resolutionRemark;
    }

    function calcPendingApprovalIds() public {
        delete pendingApprovals;
        for (uint256 i = 1; i < nextId; i++) {
            if (
                Complaints[i].isApproved == false &&
                Complaints[i].exists == true
            ) {
                pendingApprovals.push(Complaints[i].id);
            }
        }
    }

    function calcPendingResolutionIds() public {
        delete pendingResolutions;
        for (uint256 i = 1; i < nextId; i++) {
            if (
                Complaints[i].isResolved == false &&
                Complaints[i].isApproved == true &&
                Complaints[i].exists == true
            ) {
                pendingResolutions.push(Complaints[i].id);
            }
        }
    }

    function calcResolvedIds() public {
        delete resolvedCases;
        for (uint256 i = 1; i < nextId; i++) {
            if (Complaints[i].isResolved == true) {
                resolvedCases.push(Complaints[i].id);
            }
        }
    }

    function setOfficerAddress(address _officer) public onlyOwner {
        officer.push(_officer);
    }
}