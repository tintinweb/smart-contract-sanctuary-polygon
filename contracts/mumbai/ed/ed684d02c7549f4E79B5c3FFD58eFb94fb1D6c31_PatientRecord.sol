// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PatientRecord {
    struct Record {
        string[7] vitalSigns;
        string[3] treatmentDetails;
        string[3] vaccine;
        string[3] prescription;
    }

    struct Access {
        address grantedAddress;
        bool hasAccess;
    }

    mapping(address => Record[]) private patientRecords;
    mapping(address => bool) private admins;
    mapping(address => bool) private doctors;
    mapping(address => bool) private patients;
    mapping(address => Access[]) private accessList;

    modifier onlyAuthorizedDoctor(address patientAddress) {
        require(doctors[msg.sender] && hasAccess(msg.sender, patientAddress), "Only authorized doctors can perform this action");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Only admins can perform this action");
        _;
    }

    event PatientRecordAdded(address indexed patientAddress, string name, uint256 indexed recordIndex);
    event PatientRecordUpdated(address indexed patientAddress, string name, uint256 indexed recordIndex);
    event AccessGranted(address indexed patientAddress, address indexed doctorAddress);
    event AccessRevoked(address indexed patientAddress, address indexed doctorAddress);

    constructor() {
        admins[address(0x109D25547BD97E4ED7f8362f27e50F084521D033)] = true;
        doctors[address(0x667E5B64873B08B129eD730260d78B4739263Ead)] = true;
        patients[address(0xefdAd7C2eDeD5CE6877A5942392aD4E3016c71c7)] = true;
    }

    function addPatientRecord(
        address patientAddress,
        string[7] memory vitalSigns,
        string[3] memory treatmentDetails,
        string[3] memory vaccine,
        string[3] memory prescription
    ) public onlyAuthorizedDoctor(patientAddress) {
        patients[patientAddress] = true;
        patientRecords[patientAddress].push(Record(vitalSigns, treatmentDetails, vaccine, prescription));

        emit PatientRecordAdded(patientAddress, "Record added", patientRecords[patientAddress].length - 1);
    }

    function updatePatientRecord(
        address patientAddress,
        uint256 recordIndex,
        string[7] memory updatedVitalSigns,
        string[3] memory updatedTreatmentDetails,
        string[3] memory updatedVaccine,
        string[3] memory updatedPrescription
    ) public onlyAuthorizedDoctor(patientAddress) {
        require(recordIndex < patientRecords[patientAddress].length, "Invalid record index");

        Record storage patientRecord = patientRecords[patientAddress][recordIndex];

        // Update vital signs
        require(updatedVitalSigns.length == 7, "Invalid number of vital signs");
        patientRecord.vitalSigns = updatedVitalSigns;

        // Update treatment details
        require(updatedTreatmentDetails.length == 3, "Invalid number of treatment details");
        patientRecord.treatmentDetails = updatedTreatmentDetails;

        // Update vaccine
        patientRecord.vaccine = updatedVaccine;

        // Update prescription
        patientRecord.prescription = updatedPrescription;

        emit PatientRecordUpdated(patientAddress, "Record updated", recordIndex);
    }

    function getPatientRecord(address patientAddress) public view returns (Record[] memory) {
        require(admins[msg.sender] || doctors[msg.sender] || msg.sender == patientAddress, "Only authorized doctors or the patient can access the record");
        return patientRecords[patientAddress];
    }

    function hasAccess(address doctorAddress, address patientAddress) private view returns (bool) {
        Access[] storage accessArray = accessList[patientAddress];
        for (uint256 i = 0; i < accessArray.length; i++) {
            if (accessArray[i].grantedAddress == doctorAddress && accessArray[i].hasAccess) {
                return true;
            }
        }
        return false;
    }

    function grantAccess(address grantedAddress, address patientAddress) public {
        require(msg.sender == patientAddress, "Only the patient can grant access");

        patients[patientAddress] = true;

        Access memory newAccess = Access(grantedAddress, true);
        accessList[patientAddress].push(newAccess);

        emit AccessGranted(patientAddress, grantedAddress);
    }

    function revokeAccess(address grantedAddress, address patientAddress) public {
        require(msg.sender == patientAddress, "Only the patient can revoke access");

        Access[] storage accessArray = accessList[patientAddress];
        for (uint256 i = 0; i < accessArray.length; i++) {
            if (accessArray[i].grantedAddress == grantedAddress) {
                accessArray[i].hasAccess = false;
                break;
            }
        }

        emit AccessRevoked(patientAddress, grantedAddress);
    }

    function addDoctor(address doctorAddress) public onlyAdmin {
        doctors[doctorAddress] = true;
    }

    function removeDoctor(address doctorAddress) public onlyAdmin {
        doctors[doctorAddress] = false;
    }

    function removePatient(address patientAddress) public onlyAdmin {
        patients[patientAddress] = false;
    }

    function isAdmin(address account) public view returns (bool) {
        return admins[account];
    }

    function isDoctor(address account) public view returns (bool) {
        return doctors[account];
    }

}