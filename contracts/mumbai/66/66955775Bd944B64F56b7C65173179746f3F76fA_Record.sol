// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Record {
    address public officer;
    address public owner;
    uint256 public nextId;
    uint256[] public pendingApprovals;
    uint256[] public pendingResolutions;
    uint256[] public resolvedRecords;

    constructor(address _officer) {
        owner = msg.sender;
        officer = _officer;
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
            msg.sender == officer,
            "You are not registered officer of this smart contract"
        );
        _;
    }

    struct record {
        uint256 id;
        address recordRegisteredBy;
        string nic;
        string details;
        string approvalRemark;
        string resolutionRemark;
        bool isApproved;
        bool isResolved;
        bool exists;
    }
    mapping(uint256 => record) public Records;

    event recordFiled(
        uint256 id,
        address recordRegisteredBy,
        string nic
    );

    function fileRecord(string memory _nic, string memory _details)
        public
    {
        record storage newRecord = Records[nextId];
        newRecord.id = nextId;
        newRecord.recordRegisteredBy = msg.sender;
        newRecord.nic = _nic;
        newRecord.details = _details;
        newRecord.approvalRemark = "Pending Approval";
        newRecord.resolutionRemark = "Pending Resolution";
        newRecord.isApproved = false;
        newRecord.isResolved = false;
        newRecord.exists = true;
        emit recordFiled(nextId, msg.sender, _nic);
        nextId++;
    }

    function approveRecord(uint256 _id, string memory _approvalRemark)
        public
        onlyOfficer
    {
        require(
            Records[_id].exists == true,
            "This record id does not exist"
        );
        require(
            Records[_id].isApproved == false,
            "Records is already approved"
        );
        Records[_id].isApproved = true;
        Records[_id].approvalRemark = _approvalRemark;
    }

    function discardRecord(uint256 _id, string memory _approvalRemark)
        public
        onlyOfficer
    {
        require(
            Records[_id].exists == true,
            "This record id does not exist"
        );
        require(
            Records[_id].isApproved == false,
            "Record is already approved"
        );
        Records[_id].exists = false;
        Records[_id].approvalRemark = string.concat(
            "This record is rejected. Reason: ",
            _approvalRemark
        );
    }

    function resolveRecord(uint256 _id, string memory _resolutionRemark)
        public
        onlyOfficer
    {
        require(
            Records[_id].exists == true,
            "This record id does not exist"
        );
        require(
            Records[_id].isApproved == true,
            "Record is not yet approved"
        );
        require(
            Records[_id].isResolved == false,
            "Record is already resolved"
        );
        Records[_id].isResolved = true;
        Records[_id].resolutionRemark = _resolutionRemark;
    }

    function calcPendingApprovalIds() public {
        delete pendingApprovals;
        for (uint256 i = 1; i < nextId; i++) {
            if (
                Records[i].isApproved == false &&
                Records[i].exists == true
            ) {
                pendingApprovals.push(Records[i].id);
            }
        }
    }

    function calcPendingResolutionIds() public {
        delete pendingResolutions;
        for (uint256 i = 1; i < nextId; i++) {
            if (
                Records[i].isResolved == false &&
                Records[i].isApproved == true &&
                Records[i].exists == true
            ) {
                pendingResolutions.push(Records[i].id);
            }
        }
    }

    function calcResolvedIds() public {
        delete resolvedRecords;
        for (uint256 i = 1; i < nextId; i++) {
            if (Records[i].isResolved == true) {
                resolvedRecords.push(Records[i].id);
            }
        }
    }

    function setOfficerAddress(address _officer) public onlyOwner {
        officer = _officer;
    }
}