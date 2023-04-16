/**
 *Submitted for verification at polygonscan.com on 2023-04-15
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract HealthRecord {
    struct MedicalHistory {
        string hospitalName;
        string doctorName;
        string diagnosis;
        string medication;
        uint256 date;
    }

    struct PatientRecord {
        string patientName;
        uint256 age;
        string[] medicalConditions;
        string[] medications;
        string[] allergies;
        MedicalHistory[] medicalHistory;
    }

    mapping (address => PatientRecord) private records;

    function addPatientRecord(string memory _name, uint256 _age, string[] memory _conditions, string[] memory _medications, string[] memory _allergies) public {
        require(records[msg.sender].age == 0, "Record already exists for this patient.");
        PatientRecord storage record = records[msg.sender];
        record.patientName = _name;
        record.age = _age;
        record.medicalConditions = _conditions;
        record.medications = _medications;
        record.allergies = _allergies;
    }

    function addMedicalHistory(string memory _hospital, string memory _doctor, string memory _diagnosis, string memory _medication, uint256 _date) public {
        PatientRecord storage record = records[msg.sender];
        require(record.age != 0, "No record exists for this patient.");
        MedicalHistory memory history = MedicalHistory(_hospital, _doctor, _diagnosis, _medication, _date);
        record.medicalHistory.push(history);
    }

    function getPatientRecord() public view returns (string memory, uint256, string[] memory, string[] memory, string[] memory, MedicalHistory[] memory) {
        PatientRecord storage record = records[msg.sender];
        require(record.age != 0, "No record exists for this patient.");
        return (record.patientName, record.age, record.medicalConditions, record.medications, record.allergies, record.medicalHistory);
    }
}