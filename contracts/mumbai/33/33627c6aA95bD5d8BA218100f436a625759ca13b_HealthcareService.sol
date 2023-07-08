// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HealthcareService {
    struct Hospital {
        string name;
        string location;
        string contactNumber;
        string contactEmail;
        uint256 totalBeds;
    }

    struct Patient {
        string name;
        uint256 age;
        string place;
        string gender;
    }

    struct MedicalData {
        uint256 hospitalId;
        string department;
        string prescription;
        uint256 totalExpense;
        string disease;
    }

    mapping(uint256 => Hospital) private hospitals;
    mapping(uint256 => Patient) private patients;
    mapping(uint256 => MedicalData) private medicalData;
    mapping(uint256 => uint256[]) private medicalDataIdsByAdhaar;

    uint256 private hospitalCount;
    uint256 private medicalDataCount;

    function addHospital(
        string memory name,
        string memory location,
        string memory contactNumber,
        string memory contactEmail,
        uint256 totalBeds
    ) public {
        Hospital memory hospital = Hospital(
            name,
            location,
            contactNumber,
            contactEmail,
            totalBeds
        );
        hospitals[hospitalCount] = hospital;
        hospitalCount++;
    }

    function getHospital(
        uint256 hospitalId
    ) public view returns (Hospital memory) {
        return hospitals[hospitalId];
    }

    function addPatient(
        uint256 adhaarNumber,
        string memory name,
        uint256 age,
        string memory place,
        string memory gender
    ) public {
        Patient memory patient = Patient(name, age, place, gender);
        patients[adhaarNumber] = patient;
    }

    function getPatient(
        uint256 adhaarNumber
    ) public view returns (Patient memory) {
        return patients[adhaarNumber];
    }

    function addMedicalData(
        uint256 adhaarNumber,
        uint256 hospitalId,
        string memory department,
        string memory prescription,
        uint256 totalExpense,
        string memory disease
    ) public {
        MedicalData memory data = MedicalData(
            hospitalId,
            department,
            prescription,
            totalExpense,
            disease
        );
        uint256 medicalDataId = medicalDataCount;
        medicalData[medicalDataId] = data;
        medicalDataCount++;
        medicalDataIdsByAdhaar[adhaarNumber].push(medicalDataId);
    }

    function getMedicalData(
        uint256 medicalDataId
    ) public view returns (MedicalData memory) {
        return medicalData[medicalDataId];
    }

    function getMedicalDataIds(
        uint256 adhaarNumber
    ) public view returns (uint256[] memory) {
        return medicalDataIdsByAdhaar[adhaarNumber];
    }
}