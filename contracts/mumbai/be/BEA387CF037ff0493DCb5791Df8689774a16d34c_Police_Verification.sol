// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Police_Verification{
    address public officer;
    address public owner;
    uint256 public nextId;
    uint256[] private pending_verifications;
    uint256[] private successful_verifications;
    uint256 public total_pending_verifications;
    uint256 public total_successful_verifications;

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

    struct application{
        uint256 id;
        address application_by;
        string aadhar_number;
        string name;
        string mob_no;
        bool exists;
    }

    struct status{
        uint256 id;
        string verification_remark;
        bool isVerified;
    }

    mapping(uint256 => application) public Applications;
    mapping(uint256 => status) public ViewStatus;

    event Application_Filed(
        uint256 id,
        address application_by,
        string aadhar_number,
        string name,
        string mob_no,
        bool exists
    );

    event view_status(
        uint256 id,
        string verification_remark,
        bool isVerified
    );

    function apply_for_verification(string memory _aadhar_no, string memory _name, string memory _mob_no)
        public
    {
        application storage newApplication = Applications[nextId];
        status storage View_Status = ViewStatus[nextId];
        newApplication.id = nextId;
        View_Status.id = nextId;
        newApplication.application_by = msg.sender;
        newApplication.aadhar_number = _aadhar_no;
        newApplication.name = _name;
        newApplication.mob_no = _mob_no;
        //Viewing status
        View_Status.verification_remark = "Pending Verification";
        View_Status.isVerified = false;
        newApplication.exists = true;

        emit Application_Filed(nextId,msg.sender,newApplication.name,
                                newApplication.aadhar_number,newApplication.mob_no,newApplication.exists);
        emit view_status(nextId, View_Status.verification_remark,View_Status.isVerified);
        nextId++;
    }

    //Police Contract

    function Verify(uint256 _id, string memory _verfication_remark)
        public
        onlyOfficer
    {
        require(
            Applications[_id].exists == true,
            "This Application id does not exist"
        );
        require(
            ViewStatus[_id].isVerified == false,
            "Application is already verified"
        );

        ViewStatus[_id].isVerified = true;
        ViewStatus[_id].verification_remark =_verfication_remark;

    }

    function Deny_Verification(uint256 _id, string memory _rejection_remark)
        public
        onlyOfficer
    {
        require(
            Applications[_id].exists == true,
            "This complaint id does not exist"
        );

        Applications[_id].exists = false;
        ViewStatus[_id].isVerified = false;
        ViewStatus[_id].verification_remark = string.concat(
            "This Application is rejected. Reason: ",
            _rejection_remark
        );
    }
    function Calc_Pending_Verifications() public {
        delete pending_verifications;
        for (uint256 i = 1; i < nextId; i++) {
            if (
                ViewStatus[i].isVerified == false &&
                Applications[i].exists == true
            ){
                pending_verifications.push(Applications[i].id);
            }
        }
        total_pending_verifications = pending_verifications.length;
        
    }

    function Calc_Verified_Applications() public {
        delete successful_verifications;
        for (uint256 i = 1; i < nextId; i++) {
            if (ViewStatus[i].isVerified == true) {
                successful_verifications.push(Applications[i].id);
            }
        }
        total_successful_verifications = successful_verifications.length;
    }

    function setOfficerAddress(address _officer) public onlyOfficer {
        officer = _officer;
    }

}