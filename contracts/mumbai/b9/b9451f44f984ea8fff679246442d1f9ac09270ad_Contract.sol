// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Roles.sol";
import "./AddressArrayUtils.sol";
import "./AddToBoolMapping.sol";

error Contract__NotAdmin();
error Contract__NotDoctor();
error Contract__NotPatient();
error Contract__PendingDoctorApproval();
error Contract__DoctorPublicKeyMissing();

contract Contract {
    // using methods of Roles for Role struct in Roles
    using Roles for Roles.Role;
    using AddToBoolMapping for AddToBoolMapping.Map;
    using AddressArrayUtils for address[];

    struct MedicalRecord {
        address editor;
        address[] viewers;
        string key_data_hash;
    }

    struct Admin {
        address user;
        string public_key;
        AddToBoolMapping.Map pending_doctors;
    }

    struct Patients {
        Roles.Role users;
        mapping(address => MedicalRecord) records;
    }

    struct Doctors {
        Roles.Role users;
        mapping(address => string) public_keys;
        mapping(address => AddToBoolMapping.Map) docToPatAccess;
    }

    // defining roles - contains hashes
    Admin private admin;
    Doctors private doctors;
    Patients private patients;

    // Initializing admin
    constructor() {
        admin.user = msg.sender;
    }

    // Admin methods
    function isAdmin(address _address) public view returns (bool) {
        if (admin.user == _address) return true;
        return false;
    }

    function getAdmin() public view returns (address) {
        return admin.user;
    }

    function setAdminPubKey(string memory _public_key) public onlyAdmin {
        admin.public_key = _public_key;
    }

    function getAdminPubKey() public view returns (string memory) {
        return admin.public_key;
    }

    // Doctor methods
    function isDrRegistered(address _address) public view returns (bool) {
        return doctors.users.has(_address);
    }

    function isDrPending(address _address) public view returns (bool) {
        return admin.pending_doctors.get(_address);
    }

    function isDoctor(address _address) public view returns (bool) {
        if (!doctors.users.has(_address)) return false;
        if (admin.pending_doctors.get(_address)) return false;
        if (bytes(doctors.public_keys[_address]).length == 0) return false;
        return true;
    }

    function registerDr(string memory _hash) public {
        if (isPatient(msg.sender)) revert("Contract: Address already registered as patient");
        if (bytes(_hash).length == 0) revert("Contract: Empty hash is not allowed");
        doctors.users.add(msg.sender, _hash);
        admin.pending_doctors.set(msg.sender);
    }

    function approveDr(address _address) public onlyAdmin {
        if (isDoctor(_address)) return;
        if (!doctors.users.has(_address)) return;
        admin.pending_doctors.unset(_address);
    }

    function disapproveDr(address _address) public onlyAdmin {
        if (!isDrPending(_address)) revert("Contract: Doctor not registered");
        doctors.users.remove(_address);
        admin.pending_doctors.unset(_address);
    }

    function registerDrConfirm(string memory _public_key) public {
        if (bytes(_public_key).length == 0) revert("Contract: Empty public key is not allowed!");
        if (!doctors.users.has(msg.sender)) revert Contract__NotDoctor();
        if (admin.pending_doctors.get(msg.sender)) revert Contract__PendingDoctorApproval();
        doctors.public_keys[msg.sender] = _public_key;
    }

    function setDrHash(string memory _hash) public onlyDoctor {
        if (bytes(_hash).length == 0) revert("Contract: Empty hash is not allowed!");
        doctors.users.setHash(msg.sender, _hash);
    }

    function getDrHash(address _address) public view returns (string memory) {
        if (!isDrRegistered(_address)) revert Contract__NotDoctor();
        return doctors.users.getHash(_address);
    }

    function getDrPubKey(address _address) public view returns (string memory) {
        return doctors.public_keys[_address];
    }

    function getAllDrs() public view returns (address[] memory) {
        return doctors.users.getMembers();
    }

    function getPendingDrs() public view returns (address[] memory) {
        return admin.pending_doctors.keys;
    }

    function getPtsOfDr() public view onlyDoctor returns (address[] memory) {
        return doctors.docToPatAccess[msg.sender].keys;
    }

    // Patient methods
    function isPatient(address _address) public view returns (bool) {
        return patients.users.has(_address);
    }

    function registerPt(string memory _hash, string memory _key_data_hash) public {
        if (isDrRegistered(msg.sender) || isDoctor(msg.sender))
            revert("Contract: Address already registered as doctor");
        if (bytes(_hash).length == 0) revert("Contract: Empty hash is not allowed");
        patients.users.add(msg.sender, _hash);
        patients.records[msg.sender].editor = msg.sender;
        patients.records[msg.sender].key_data_hash = _key_data_hash;
    }

    function setPtGeneralHash(string memory _hash) public onlyPatient {
        patients.users.setHash(msg.sender, _hash);
    }

    function getPtGeneralHash(address _address) public view returns (string memory) {
        if (!isPatient(_address)) revert Contract__NotPatient();

        if (
            msg.sender == _address ||
            patients.records[_address].editor == msg.sender ||
            patients.records[_address].viewers.indexOf(msg.sender) != -1
        ) return patients.users.getHash(_address);

        revert("Not Allowed");
    }

    function setPtRecordHash(address _address, string memory _hash) public {
        if (!isPatient(_address)) revert Contract__NotPatient();
        if (!(patients.records[_address].editor == msg.sender)) revert("Not Allowed");
        patients.records[_address].key_data_hash = _hash;
    }

    function getPtRecordHash(address _address) public view returns (string memory) {
        if (!isPatient(_address)) revert Contract__NotPatient();

        if (
            msg.sender == _address ||
            patients.records[_address].editor == msg.sender ||
            patients.records[_address].viewers.indexOf(msg.sender) != -1
        ) return patients.records[_address].key_data_hash;

        revert("Not Allowed");
    }

    function getAllPts() public view returns (address[] memory) {
        return patients.users.getMembers();
    }

    function changeEditorAccess(
        address _address,
        string memory _general_hash,
        string memory _key_hash
    ) public onlyPatient {
        // pending update - when user changes access, symmetric key S must be changed
        if (!isDoctor(_address)) revert Contract__NotDoctor();

        // remove old editor access
        removeEditorAccess(_general_hash, _key_hash);

        // add new editor access
        patients.records[msg.sender].editor = _address;
        doctors.docToPatAccess[_address].set(msg.sender);
    }

    function removeEditorAccess(
        string memory _general_hash,
        string memory _key_hash
    ) public onlyPatient {
        address old_editor = patients.records[msg.sender].editor;
        patients.records[msg.sender].editor = msg.sender;
        doctors.docToPatAccess[old_editor].unset(msg.sender);

        patients.users.setHash(msg.sender, _general_hash);
        patients.records[msg.sender].key_data_hash = _key_hash;
    }

    function getDrOfPt() public view onlyPatient returns (address) {
        return patients.records[msg.sender].editor;
    }

    function grantViewerAccess(address _address) public onlyPatient {
        if (!isDoctor(_address)) revert Contract__NotDoctor();

        if (!patients.records[msg.sender].viewers.contains(_address)) {
            patients.records[msg.sender].viewers.push(_address);
        }
    }

    function revokeViewerAccess(address _address) public onlyPatient {
        // pending update - when user revokes access, symmetric key S must be changed
        if (!isDoctor(_address)) revert Contract__NotDoctor();

        patients.records[msg.sender].viewers.remove(_address);
    }

    function getPatViewers() public view onlyPatient returns (address[] memory) {
        return patients.records[msg.sender].viewers;
    }

    // modifiers
    modifier onlyAdmin() {
        if (!isAdmin(msg.sender)) revert Contract__NotAdmin();
        _;
    }

    modifier onlyDoctor() {
        if (!doctors.users.has(msg.sender)) revert Contract__NotDoctor();
        if (admin.pending_doctors.get(msg.sender)) revert Contract__PendingDoctorApproval();
        if (bytes(doctors.public_keys[msg.sender]).length == 0)
            revert Contract__DoctorPublicKeyMissing();
        _;
    }

    modifier onlyPatient() {
        if (!isPatient(msg.sender)) revert Contract__NotPatient();
        _;
    }
}