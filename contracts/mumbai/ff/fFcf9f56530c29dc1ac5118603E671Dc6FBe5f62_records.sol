// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract records {
    address public admin;
    address public student;
    string[] pendingRecords;
    string[] approvedRecords;

    struct certificate { 
        string name;
        string aadhar;
        string degree;
        bool isApproved;
        string approvalRemark;
        bool exists;
    }

    mapping (string => certificate) certificates;
    string[] public aadharList;

    constructor() {
        admin = msg.sender;
        student = address(0);
    }

    modifier adminOnly {
        require(admin == msg.sender, "only admin can perform this action");
        _;
    }

    modifier studentOnly {
        require(student == msg.sender, "Your not the student of this college");
        _;
    }

    event recordAdded(
        string aadhar,
        string name
    );
    
    function addCertificate(string memory _name, string memory _aadhar, string memory _degree) public studentOnly
    {
        certificate storage newCertificate = certificates[_aadhar];
        newCertificate.name = _name;
        newCertificate.aadhar = _aadhar;
        newCertificate.degree = _degree;
        newCertificate.isApproved = false;
        newCertificate.exists = true;
        emit recordAdded(_aadhar, _name);
        aadharList.push(_aadhar);
    }

    function approveCertificate(string memory _aadhar, string memory _approvalRemark) public adminOnly
    {
        require(certificates[_aadhar].exists == true, "This Request does not exist");
        require(certificates[_aadhar].isApproved == false, "Request is already approved");
        certificates[_aadhar].isApproved = true;
        certificates[_aadhar].approvalRemark = _approvalRemark;
    }

    function discardCertificate(string memory _aadhar, string memory _approvalRemark) public adminOnly 
    {
        require(certificates[_aadhar].exists == true, "This Request does not exist");
        require(certificates[_aadhar].isApproved == false, "Request is already approved");
        certificates[_aadhar].exists = false;
        certificates[_aadhar].approvalRemark = string(
            abi.encodePacked("This Request is rejected. Reason: ", _approvalRemark));
    }

    function calcPendingRecords() public adminOnly {
        delete pendingRecords;
        for (uint256 i = 0; i < aadharList.length; i++) {
            string memory currentAadhar = aadharList[i];
            if (
                certificates[currentAadhar].isApproved == false &&
                certificates[currentAadhar].exists == true
            ) {
                pendingRecords.push(certificates[currentAadhar].aadhar);
            }
        }
    }

    function viewPendingRecords() public view adminOnly returns(string memory) {
        string memory result = "";
        for (uint256 i = 0; i < aadharList.length; i++) {
            string memory currentAadhar = aadharList[i];
            if (
                certificates[currentAadhar].isApproved == false &&
                certificates[currentAadhar].exists == true
            ){
                 result = string(abi.encodePacked(result, certificates[currentAadhar].name, " "));
            }
        }
        return result;
    }
        

    function setStudent(address _student) public adminOnly {
        student = _student;
    }

    function getCertificate(string memory _aadhar) public view adminOnly returns (string memory, string memory, string memory, bool, string memory) {
        require(certificates[_aadhar].exists == true, "This request does not exist.");
        certificate memory cert = certificates[_aadhar];
        return (cert.name, cert.aadhar, cert.degree, cert.isApproved, cert.approvalRemark);
    }
    
}