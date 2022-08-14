/**
 *Submitted for verification at polygonscan.com on 2022-08-13
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

contract Records {

    // the deployer of the contract
    address public deployer;

    // a struct to keep of patients basic information
    struct Patient {
        address owner;
        string name;
        uint age;
        string gender;
        uint256 height;
        uint256 weight;
        string patient_address;
        uint256 phone;
        string email;
        uint256 dateCreated;
        string recordhash; // the folder hash of the IPFS folder where records will be kept
    }

    mapping (address => patientHealthRecord[]) HRecord;
    mapping (address => patientInsuranceRecord[]) IRecord;

    // a struct for patient health record
    struct patientHealthRecord {
        string diagnosis;
        string prescription;
        string treatmentForm;
        string Doctor;
        string admissionDate;
        string dischargeDate;
        string summary;
    }

    struct patientInsuranceRecord {
        string policyName;
        uint policyId;
        string policyType;
        uint policyLimit;
        string policyAgent;
        string startDate;
        string endDate;
        string summary;
    }


    // mapping a patients record to an address
    mapping (address => Patient) internal patientList;
    // mapping to track if a patient has regitered or not
    mapping (address => bool) internal registered;

    // struct for a hospital instance
    struct Hospital {
        address owner;
        string name;
        string hospitalAddress;
        string email;
        string website;
    }

    // mapping to keep hold of hospitals list
    mapping (address => bool) hospitalList;
    // mapping to keep hold of hospitals records
    mapping (address => Hospital) hospitalRecord;

    // struct for an insurance instance
    struct Insurance {
        address owner;
        string name;
        string insuranceAddress;
        string email;
        string website;
    }

    // mapping to keep hold of insurance list
    mapping (address => bool) insuranceList;
    // mapping to keep hold of insurance records
    mapping (address => Insurance) insuranceRecord;

    // mapping to keep track of patients access list
    mapping (address => mapping(address => bool)) accessList;

    constructor() {
        deployer = msg.sender;
    } 

    // function to retrive patient information
    function retrievePatient(address patient) public view returns(
        string memory,
        uint,
        string memory,
        uint256,
        uint256,
        string memory,
        uint256,
        string memory,
        uint256,
        string memory) {
        require(accessList[patient][msg.sender] == true);
        require(insuranceList[msg.sender] == true || hospitalList[msg.sender] == true);

        Patient memory p;
        p = patientList[patient];

        return (p.name, p.age, p.gender, p.height, p.weight, p.patient_address, p.phone, p.email, p.dateCreated, p.recordhash);
    }

    // function to retrive patient information by the patient himself
    function getPatient(address patient) public view returns(
        string memory,
        uint,
        string memory,
        uint256,
        uint256,
        string memory,
        uint256,
        string memory,
        uint256,
        string memory) {
        Patient memory p;
        p = patientList[patient];

        require(p.owner == msg.sender, " you do not have access to this information");

        return (p.name, p.age, p.gender, p.height, p.weight, p.patient_address, p.phone, p.email, p.dateCreated, p.recordhash);
    }

    // function to retrive hospital information
    function retrieveHospital(address hospital) public view returns(
        string memory,
        string memory,
        string memory,
        string memory) {

        Hospital memory h;
        h = hospitalRecord[hospital];

        return (h.name, h.hospitalAddress, h.email, h.website);
    }

    // function to retrive insurance information
    function retrieveInsurance(address insurance) public view returns(
        string memory,
        string memory,
        string memory,
        string memory) {

        Insurance memory i;
        i = insuranceRecord[insurance];

        return (i.name, i.insuranceAddress, i.email, i.website);
    }

    // function to grant access
    function grantAccess(address reciever) public returns(bool b) {
        accessList[msg.sender][reciever] = true;
        b = true;
        return b;
    }

    // function to revoke access
    function revokeAccess(address reciever) public returns(bool b) {
        accessList[msg.sender][reciever] = false;
        b = true;
        return b;
    }

    // function to setup patient record
    function setRecordPatient(
        string memory _name,
        uint256 _age,
        string memory _gender,
        uint256 _height,
        uint256 _weight,
        string memory _patient_address,
        uint256 _phone,
        string memory _email) public returns(bool b) {
        require(registered[msg.sender] != true, "You can not register twice");
        Patient memory p;

        p.owner = msg.sender;
        p.name = _name;
        p.age = _age;
        p.gender = _gender;
        p.height = _height;
        p.weight = _weight;
        p.patient_address = _patient_address;
        p.phone = _phone;
        p.email = _email;
        p.dateCreated = block.timestamp;

        patientList[msg.sender] = p;
        registered[msg.sender] = true;

        b = true;

        return b;

    }

    // function to setup hospital record
    // NB: will work on using an API for verification or pass through a verification to ensure security
    function setRecordHospital(
        string memory _name,
        string memory _hospitalAddress,
        string memory _email,
        string memory _website) public returns(bool b) {
        Hospital memory h;

        h.owner = msg.sender;
        h.name = _name;
        h.email = _email;
        h.hospitalAddress = _hospitalAddress;
        h.website = _website;

        hospitalRecord[msg.sender] = h;

        hospitalList[msg.sender] = true;

        b = true;
        return b;
    }

    // function to setup insurance record
    // NB: will work on using an API for verification or pass through a verification to ensure security
    function setRecordInsurance(
        string memory _name,
        string memory _insuranceAddress,
        string memory _email,
        string memory _website) public returns(bool b) {
        Insurance memory i;

        i.owner = msg.sender;
        i.name = _name;
        i.email = _email;
        i.insuranceAddress = _insuranceAddress;
        i.website = _website;

        insuranceRecord[msg.sender] = i;

        insuranceList[msg.sender] = true;

        b = true;
        return b;
    }

    // function to add patient record
    function addPatientRecord(address patient, string memory ipfsHash) public view returns(bool b) {
        require(accessList[patient][msg.sender] == true);
        require(insuranceList[msg.sender] == true || hospitalList[msg.sender] == true);

        Patient memory p;
        p = patientList[patient];
        p.recordhash = ipfsHash;

        return true;
    }

    // TODO

    //create function to add and retrieve health and insurance records

    function addHealthRecord(
        address patient,
        string memory _diagnosis,
        string memory _prescription,
        string memory _treatmentForm,
        string memory _Doctor,
        string memory _admissionDate,
        string memory _dischargeDate,
        string memory _summary) public returns (bool) {

        require(accessList[patient][msg.sender] == true);
        require(hospitalList[msg.sender] == true);

        patientHealthRecord memory p;

        p.diagnosis = _diagnosis;
        p.prescription = _prescription;
        p.treatmentForm = _treatmentForm;
        p.Doctor = _Doctor;
        p.admissionDate = _admissionDate;
        p.dischargeDate = _dischargeDate;
        p.summary = _summary;

        HRecord[patient].push(p);

        bool b = true;

        return b;
    }

    function addInsuranceRecord(
        address patient,
        string memory _policyName,
        uint _policyId,
        string memory _policyType,
        uint _policyLimit,
        string memory _policyAgent,
        string memory _startDate,
        string memory _endDate,
        string memory _summary) public returns (bool) {

        require(accessList[patient][msg.sender] == true);
        require(insuranceList[msg.sender] == true);

        patientInsuranceRecord memory p;

        p.policyName = _policyName;
        p.policyId = _policyId;
        p.policyType = _policyType;
        p.policyLimit = _policyLimit;
        p.policyAgent = _policyAgent;
        p.startDate = _startDate;
        p.endDate = _endDate;
        p.summary = _summary;

        IRecord[patient].push(p);

        bool b = true;

        return b;
    }

    function retrievePatientHealthRecord(address patient) public view returns (patientHealthRecord[] memory p) {
        require(accessList[patient][msg.sender] == true);
        require(insuranceList[msg.sender] == true || hospitalList[msg.sender] == true);

        p = HRecord[patient];

        return p;
    }

    function retrievePatientInsuranceRecord(address patient) public view returns (patientInsuranceRecord[] memory p) {
        require(accessList[patient][msg.sender] == true);
        require(insuranceList[msg.sender] == true || hospitalList[msg.sender] == true);

        p = IRecord[patient];

        return p;
    }

}