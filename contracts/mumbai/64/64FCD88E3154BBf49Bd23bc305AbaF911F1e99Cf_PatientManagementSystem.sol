/**
 *Submitted for verification at polygonscan.com on 2023-02-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// Enum for the different user types in the PMS
enum UserType {
    UNREGISTERED,
    SUPERUSER,
    SUPERUSER2,
    SUPERUSER3,
    HOSPITAL,
    DOCTOR,
    PATIENT
}

// Struct for storing hospital information
struct Hospital {
    bytes32 name;
    bytes32 _address;
    bytes32 contact;
    address wallet;
}

// Struct for storing doctor information
struct Doctor {
    bytes32 name;
    uint256 hospitalId;
    address wallet;
}

// Struct for storing patient information
struct Patient {
    bytes32 name;
    uint256 age;
    bytes32 gender;
    uint256 doctorId;
    address patientWallet;
    uint256[] medicalRecordIds;
}

// Struct for storing medical record information
struct MedicalRecord {
    bytes32 diagnosis;
    bytes32 prescription;
    bytes32 notes;
    uint256 timestamp;
}

// PMS contract
contract PatientManagementSystem {
    // Mapping of hospital IDs to hospital information
    mapping(uint256 => Hospital) public hospitals;

    // Mapping of doctor IDs to doctor information
    mapping(uint256 => Doctor) public doctors;

    // Mapping of patient IDs to patient information
    mapping(uint256 => Patient) patients;

    // Mapping of medicalRecordIds to medicalRecords
    mapping (uint256 => MedicalRecord) medicalRecords;

    // Array for storing hospital IDs
    uint256[] public hospitalIds;

    // Array for storing doctor IDs
    uint256[] public doctorIds;

    // Array for storing patient IDs
    uint256[] public patientIds;

    // Mapping of Ethereum addresses to user types
    mapping(address => UserType) public userTypes;

    // Mapping of Ethereum addresses to hospital IDs (for hospitals and doctors)
    mapping(address => uint256) public hospitalIdsForAddresses;

    // Mapping of Ethereum addresses to doctor IDs
    mapping(address => uint256) public doctorIdsForAddresses;
    
    // Mapping of Ethereum addresses to patient IDs
    mapping(address => uint256) public patientIdsForAddresses;

    // Counter for generating unique IDs
    uint256 public patientIdCounter;
    uint256 public hospitalIdCounter;
    uint256 public doctorIdCounter;
    uint256 public medicalIdCounter;

    // Event for logging new hospital registration
    event NewHospitalRegistered(uint256 hospitalId, bytes32 hospitalName, address hospitalWallet);

    // Event for logging new doctor registration
    event NewDoctorRegistered(
        uint256 doctorId,
        bytes32 doctorName,
        uint256 hospitalId,
        address wallet
    );

    // Event for logging new patient registration
    event NewPatientRegistered(
        uint256 patientId,
        address patientWallet,
        uint256 doctorId
    );

    // Constructor function for initializing the contract
    constructor() {
        // Set the contract owner as the initial superuser
        userTypes[msg.sender] = UserType.SUPERUSER;
        
        // Add the contract owner as the initial hospital
        addHospital("Hospital 1", "Street Unknown", "+123456789", 0xE73359416A1A8De4Cc59763bE4CbCEE288a399CF);
        // hospitalIdsForAddresses[msg.sender] = 0;
    }
    
    // Function to register a new hospital
    function addHospital(
    bytes32 hospitalName,
    bytes32 hospitalAddress,
    bytes32 hospitalContact,
    address hospitalWallet
    ) public {
        // Only superusers are allowed to register hospitals
        require(
            userTypes[msg.sender] == UserType.SUPERUSER || // current superuser
            userTypes[msg.sender] == UserType.SUPERUSER2 || // additional superuser
            userTypes[msg.sender] == UserType.SUPERUSER3,   // additional superuser
            "Only superusers are allowed to register hospitals."
        );

        // Generate a unique ID for the new hospital
        uint256 hospitalId = hospitalIdCounter;
        hospitalIdCounter++;

        // Add the new hospital to the hospitals mapping
        hospitals[hospitalId] = Hospital(
            hospitalName,
            hospitalAddress,
            hospitalContact,
            hospitalWallet
        );

        // Add the hospital ID to the hospitalIds array
        hospitalIds.push(hospitalId);

        // Set the Ethereum address of the hospital to the hospital ID in the userTypes and hospitalIdsForAddresses mappings
        userTypes[hospitalWallet] = UserType.HOSPITAL;
        hospitalIdsForAddresses[hospitalWallet] = hospitalId;

        // Emit the NewHospitalRegistered event
        emit NewHospitalRegistered(hospitalId, hospitalName, hospitalWallet);
    }

    // Function to register a new doctor
    function addDoctor(bytes32 doctorName, uint256 hospitalId, address wallet) public {
        // Only hospitals are allowed to register doctors
        require(
            userTypes[msg.sender] == UserType.HOSPITAL &&
            hospitalIdsForAddresses[msg.sender] == hospitalId,
            "Only hospitals are allowed to register doctors."
        );

        // Generate a unique ID for the new doctor
        uint256 doctorId = doctorIdCounter;
        doctorIdCounter++;

        // Add the new doctor to the doctors mapping
        doctors[doctorId] = Doctor(doctorName, hospitalId, wallet);

        // Add the doctor ID to the doctorIds array
        doctorIds.push(doctorId);

        // Set the Ethereum address of the doctor to the doctor ID and hospital ID in the userTypes and hospitalIdsForAddresses mappings
        userTypes[wallet] = UserType.DOCTOR;
        doctorIdsForAddresses[wallet] = doctorId;

        // Emit the NewDoctorRegistered event
        emit NewDoctorRegistered(doctorId, doctorName, hospitalId, wallet);
    }
    
    // Function to register a new patient
    function addPatient(
        bytes32 _name,
        uint256 _age,
        bytes32 _gender,
        uint256 _doctorId,
        address _patientWallet,
        bytes32 _diagnosis,
        bytes32 _prescription,
        bytes32 _notes
        ) public {
        // Only doctors are allowed to register patients
        require(
            userTypes[msg.sender] == UserType.DOCTOR &&
            msg.sender == doctors[_doctorId].wallet,
            "Only doctors are allowed to register patients."
        );

        // Generate a unique ID for the new patient
        uint256 patientId = patientIdCounter;
        patientIdCounter++;

        // Add the new patient to the patients mapping
        patients[patientId] = Patient({
            name: _name,
            age: _age,
            gender: _gender,
            doctorId: _doctorId,
            patientWallet: _patientWallet,
            medicalRecordIds: new uint256[](0)
        });

        addMedicalRecord(patientId, _diagnosis, _prescription, _notes);

        // Add the patient ID to the patientIds array
        patientIds.push(patientId);

        // Set the Ethereum address of the patient to the doctor ID in the userTypes and doctorIdsForAddresses mappings
        userTypes[_patientWallet] = UserType.PATIENT;
        patientIdsForAddresses[_patientWallet] = patientId;

        // Emit the NewPatientRegistered event
        emit NewPatientRegistered(patientId, _patientWallet, _doctorId);
    }
    
    // Function to add a new medical record
    function addMedicalRecord(
        uint256 patientId,
        bytes32 _diagnosis,
        bytes32 _prescription,
        bytes32 _notes
    ) public {
        // Only hospitals and doctors are allowed to add medical records
        require(
            userTypes[msg.sender] == UserType.HOSPITAL ||
            userTypes[msg.sender] == UserType.DOCTOR ,
            "Only hospitals and doctors are allowed to add medical records."
        );

        // Generate new ID for Medical Record
        uint256 medicalRecordId = medicalIdCounter;
        medicalIdCounter++;

        // Add the new medical record to the medicalRecords array
        medicalRecords[medicalRecordId] = MedicalRecord({
            diagnosis: _diagnosis,
            prescription: _prescription,
            notes: _notes,
            timestamp: block.timestamp
        });

        Patient storage patient = patients[patientId];
        patient.medicalRecordIds.push(medicalRecordId);
    }
    
    // Set the SUPERUSER2 or SUPERUSER3 constants for a particular address
    function setSuperuser(address _address, UserType _userType) public {
        // Only the current superuser is allowed to set other superusers
        require(
            userTypes[msg.sender] == UserType.SUPERUSER,
            "Only the current superuser is allowed to set other superusers."
        );

        // Set the user type for the specified address
        userTypes[_address] = _userType;
    }

    // Function to get the user type for an Ethereum address
    function getUserType(address user) public view returns (UserType) {
        return userTypes[user];
    }

    // Function to get the hospital ID for an Ethereum address
    function getHospitalId(address user) public view returns (uint256) {
        return hospitalIdsForAddresses[user];
    }

    // Function to get the doctor ID for an Ethereum address
    function getDoctorId(address user) public view returns (uint256) {
        return doctorIdsForAddresses[user];
    }

    // Function to get the information for a hospital
    function getHospitalInfo(uint256 hospitalId) public view returns (
        bytes32 hospitalName,
        bytes32 hospitalAddress,
        bytes32 hospitalContact,
        address hospitalWallet
    ) {
        return (
            hospitals[hospitalId].name,
            hospitals[hospitalId]._address,
            hospitals[hospitalId].contact,
            hospitals[hospitalId].wallet
        );
    }

    // Function to get the information for a doctor
    function getDoctorInfo(uint256 doctorId) public view returns (
        bytes32 doctorName,
        uint256 hospitalId,
        address _wallet
    ) {
        return (
            doctors[doctorId].name,
            doctors[doctorId].hospitalId,
            doctors[doctorId].wallet
        );
    }

    // Function to get the information for a patient
    function getPatientInfo(address patientWallet) public view returns (
        bytes32 patientName,
        uint256 age,
        bytes32 gender,
        uint256 doctorId,
        address wallet,
        uint256[] memory _medicalIds
    ) {
        require(
            userTypes[msg.sender] == UserType.HOSPITAL ||
            userTypes[msg.sender] == UserType.DOCTOR ||
            userTypes[msg.sender] == UserType.PATIENT,
            "Only Doctors, Hospitals & Patient themselves can access patients data."
        );
        uint256 patientId = patientIdsForAddresses[patientWallet];
        return (
            patients[patientId].name,
            patients[patientId].age,
            patients[patientId].gender,
            patients[patientId].doctorId,
            patients[patientId].patientWallet,
            patients[patientId].medicalRecordIds
        );
    }

    // Function to get the information for a medical record
    function getMedicalRecordInfo(uint256 medicalRecordId) public view returns (
        bytes32 diagnosis,
        bytes32 prescription,
        bytes32 notes,
        uint256 timestamp
    ) {
        return (
            medicalRecords[medicalRecordId].diagnosis,
            medicalRecords[medicalRecordId].prescription,
            medicalRecords[medicalRecordId].notes,
            medicalRecords[medicalRecordId].timestamp
        );
    }
}