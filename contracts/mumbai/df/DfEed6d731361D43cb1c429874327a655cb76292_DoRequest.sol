// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract DoRequest {
    address public admin;
    address public owner;
    uint256 public nextId;
    uint256[] public pendingApprovals;
    uint256[] public pendingResolutions;
    uint256[] public resolvedMission;

    constructor(address _admin) {
        owner = msg.sender;
        admin = _admin;
        nextId = 1;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You are not the owner of this smart contract"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            msg.sender == admin,
            "You are not registered admin of this smart contract"
        );
        _;
    }

    struct request {
        uint256 id;
        address requestRegisteredBy;
        string title;
        string description;
        string approvalRemark;
        string resolutionRemark;
        bool isApproved;
        bool isResolved;
        bool exists;
    }
    mapping(uint256 => request) public Requests;

    event requestFiled(uint256 id, address requestRegisteredBy, string title);

    function fileRequest(
        string memory _title,
        string memory _description
    ) public {
        request storage newRequest = Requests[nextId];
        newRequest.id = nextId;
        newRequest.requestRegisteredBy = msg.sender;
        newRequest.title = _title;
        newRequest.description = _description;
        newRequest.approvalRemark = "Pending Approval";
        newRequest.resolutionRemark = "Pending Resolution";
        newRequest.isApproved = false;
        newRequest.isResolved = false;
        newRequest.exists = true;
        emit requestFiled(nextId, msg.sender, _title);
        nextId++;
    }

    function approveRequest(
        uint256 _id,
        string memory _approvalRemark
    ) public onlyAdmin {
        require(Requests[_id].exists == true, "This request id does not exist");
        require(
            Requests[_id].isApproved == false,
            "Request is already approved"
        );
        Requests[_id].isApproved = true;
        Requests[_id].approvalRemark = _approvalRemark;
    }

    function discardRequest(
        uint256 _id,
        string memory _approvalRemark
    ) public onlyAdmin {
        require(Requests[_id].exists == true, "This request id does not exist");
        require(
            Requests[_id].isApproved == false,
            "Request is already approved"
        );
        Requests[_id].exists = false;
        Requests[_id].approvalRemark = _approvalRemark;
    }

    function resolveRequest(
        uint256 _id,
        string memory _resolutionRemark
    ) public onlyAdmin {
        require(Requests[_id].exists == true, "This request id does not exist");
        require(
            Requests[_id].isApproved == true,
            "Request is not yet approved"
        );
        require(
            Requests[_id].isResolved == false,
            "Request is already resolved"
        );
        Requests[_id].isResolved = true;
        Requests[_id].resolutionRemark = _resolutionRemark;
    }

    function calcPendingApprovalIds() public {
        delete pendingApprovals;
        for (uint256 i = 1; i < nextId; i++) {
            if (Requests[i].isApproved == false && Requests[i].exists == true) {
                pendingApprovals.push(Requests[i].id);
            }
        }
    }

    function calcPendingResolutionIds() public {
        delete pendingResolutions;
        for (uint256 i = 1; i < nextId; i++) {
            if (
                Requests[i].isResolved == false &&
                Requests[i].isApproved == true &&
                Requests[i].exists == true
            ) {
                pendingResolutions.push(Requests[i].id);
            }
        }
    }

    function calcResolvedIds() public {
        delete resolvedMission;
        for (uint256 i = 1; i < nextId; i++) {
            if (Requests[i].isResolved == true) {
                resolvedMission.push(Requests[i].id);
            }
        }
    }

    function setadminAddress(address _admin) public onlyOwner {
        admin = _admin;
    }
}