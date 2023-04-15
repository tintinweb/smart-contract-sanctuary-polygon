//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Complaint{
  address public officer;
  address public owner;
  uint256 public nextId;
  uint256[] public pendingApprovals;
  uint256[] public pendingResolutions;
  uint256[] public resolvedCases;

  constructor (address _officer){
    owner = msg.sender;
    officer = _officer;
    nextId = 1;
  }

  modifier onlyOwner (){
    require(msg.sender == owner , "You are not the owner of smart contract");
    _;
  }

  modifier onlyOfficer (){
    require(msg.sender == officer , "You are not an officer");
    _;
  }

  struct complaint{
    uint256 id;
    address victim;
    string victimName;
    string title;
    string description;
    string approvalRemark;
    string resolutionRemark;
    bool isApproved;
    bool isResolved;
    bool valid;
  }

  mapping(uint256 => complaint) public Complaints;

  event complaintFiled(uint256 id, address victim, string title);

  //--------------FILING A COMPLAINT---------------
  function fileComplaint(string memory name, string memory _title, string memory _description) public {
    complaint storage newComplaint = Complaints[nextId];
    
    newComplaint.id = nextId;
    newComplaint.victim = msg.sender;
    newComplaint.victimName = name;
    newComplaint.title = _title;
    newComplaint.description = _description;
    newComplaint.approvalRemark = "Pending Approval";
    newComplaint.resolutionRemark = "Pending Resolution";
    newComplaint.isApproved = false;
    newComplaint.isResolved = false;
    newComplaint.valid = true;

    emit complaintFiled(nextId, msg.sender, _title);
    nextId++;
  }

  //--------------APPROVING A COMPLAINT---------------
  function approveComplaint(uint256 _id, string memory _approvalRemark) public onlyOfficer{
    require(Complaints[_id].valid == true , "This complaint id does not exist");
    require(Complaints[_id].isApproved == false , "Complaint is already approved");

    Complaints[_id].isApproved = true;
    Complaints[_id].approvalRemark = _approvalRemark;
  }

  //--------------DECLINING A COMPLAINT---------------
  function declineComplaint(uint256 _id, string memory _approvalRemark) public onlyOfficer{
    require(Complaints[_id].valid == true , "This complaint id does not exist");
    require(Complaints[_id].isApproved == false , "Cannot decline an already approved complaint");

    Complaints[_id].valid = false;
    Complaints[_id].approvalRemark = string.concat("This complaint is Rejected. REASON : " , _approvalRemark);
  }

  //--------------RESOLVING A COMPLAINT---------------
  function resolveComplaint(uint256 _id, string memory _resolutionRemark) public onlyOfficer{
    require(Complaints[_id].valid == true , "This complaint id does not exist");
    require(Complaints[_id].isApproved == true , "First approve the complaint to resolve it");
    require(Complaints[_id].isResolved == false , "This complaint is already resolved");

    Complaints[_id].isResolved = true;
    Complaints[_id].resolutionRemark = _resolutionRemark;
  }

  //--------------NUMBER OF PENDING APPROVALS---------------
  function calculatePendingApprovals() public{
    delete pendingApprovals;
    for (uint256 i=1 ; i<nextId ;i++){
      if (Complaints[i].valid == true && Complaints[i].isApproved == false){
        pendingApprovals.push(Complaints[i].id);
      }
    }
  }

  //--------------NUMBER OF PENDING RESOLUTIONS---------------
  function calculatePendingResolutions() public{
    delete pendingResolutions;
    for (uint256 i=1 ; i<nextId ;i++){
      if (Complaints[i].valid == true && Complaints[i].isApproved == true && Complaints[i].isResolved == false){
        pendingResolutions.push(Complaints[i].id);
      }
    }
  }

  //--------------NUMBER OF RESOLUTIONS---------------
  function calculateResolutions() public{
    delete resolvedCases;
    for (uint256 i=1 ; i<nextId ;i++){
      if (Complaints[i].isResolved == true){
        resolvedCases.push(Complaints[i].id);
      }
    }
  }

  //--------------ADDING NEW OFFICER---------------
  function setOfficerAddress(address _officer) public onlyOwner{
    owner = _officer;
  }

}