/**
 *Submitted for verification at polygonscan.com on 2022-12-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

// Enum for the different user types in the PMS
enum UserType {
    HOSPITAL,
    DOCTOR,
    PATIENT
}

// Struct for storing hospital information
struct Hospital {
    bytes32 name;
    bytes32 _address;
    bytes32 contact;
}

// Struct for storing doctor information
struct Doctor {
    bytes32 name;
    uint256 hospitalId;
}

// Struct for storing patient information
struct Patient {
    bytes32 name;
    uint256 doctorId;
}

// Struct for storing medical record information
struct MedicalRecord {
    bytes32 diagnosis;
    bytes32 prescription;
    bytes32 notes;
}

// PMS contract
contract PatientManagementSystem {
    // Mapping of hospital IDs to hospital information
    mapping(uint256 => Hospital) public hospitals;

    // Mapping of doctor IDs to doctor information
    mapping(uint256 => Doctor) public doctors;

    // Mapping of patient IDs to patient information
    mapping(uint256 => Patient) public patients;

    // Mapping of medical record IDs to medical record information
    mapping(uint256 => MedicalRecord) public medicalRecords;

    // Array for storing hospital IDs
    uint256[] public hospitalIds;

    // Array for storing doctor IDs
    uint256[] public doctorIds;

    // Array for storing patient IDs
    uint256[] public patientIds;

    // Array for storing medical record IDs
    uint256[] public medicalRecordIds;

    // Mapping of Ethereum addresses to user types
    mapping(address => UserType) public userTypes;

    // Mapping of Ethereum addresses to hospital IDs (for hospitals and doctors)
    mapping(address => uint256) public hospitalIdsForAddresses;

    // Mapping of Ethereum addresses to doctor IDs (for patients)
    mapping(address => uint256) public doctorIdsForAddresses;

    // Counter for generating unique IDs
    uint256 public idCounter;

    // Event for logging new hospital registration
    event NewHospitalRegistered(uint256 hospitalId, bytes32 hospitalName);

    // Event for logging new doctor registration
    event NewDoctorRegistered(
        uint256 doctorId,
        bytes32 doctorName,
        uint256 hospitalId
    );

    // Event for logging new patient registration
    event NewPatientRegistered(
        uint256 patientId,
        bytes32 patientName,
        uint256 doctorId
    );

    // Event for logging new medical record added
    event NewMedicalRecordAdded(
        uint256 medicalRecordId,
        bytes32 diagnosis,
        bytes32 prescription,
        bytes32 notes
    );

    // Constructor function for initializing the contract
    constructor() {
        // Add the contract owner as the initial hospital
        addHospital("Hospital 1", "Address 1", "Contact 1");

        // Set the contract owner as the initial superuser
        userTypes[msg.sender] = UserType.HOSPITAL;
        hospitalIdsForAddresses[msg.sender] = 0;
    }
    // Function to register a new hospital
    function addHospital(
        bytes32 hospitalName,
        bytes32 hospitalAddress,
        bytes32 hospitalContact
    ) public {
        // Only superusers are allowed to register hospitals
        require(
            userTypes[msg.sender] == UserType.HOSPITAL,
            "Only superusers are allowed to register hospitals."
        );

        // Generate a unique ID for the new hospital
        uint256 hospitalId = idCounter;
        idCounter++;

        // Add the new hospital to the hospitals mapping
        hospitals[hospitalId] = Hospital(
            hospitalName,
            hospitalAddress,
            hospitalContact
        );

        // Add the hospital ID to the hospitalIds array
        hospitalIds.push(hospitalId);

        // Set the Ethereum address of the hospital to the hospital ID in the userTypes and hospitalIdsForAddresses mappings
        userTypes[msg.sender] = UserType.HOSPITAL;
        hospitalIdsForAddresses[msg.sender] = hospitalId;

        // Emit the NewHospitalRegistered event
        emit NewHospitalRegistered(hospitalId, hospitalName);
    }
}