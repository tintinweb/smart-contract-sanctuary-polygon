// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract MedicalHealthContract {
    struct Doctor {
        string name;
        string category;
        address wallet;
        uint256 fees;
        string comment;
        uint256 uniqueId;
        string registrationNo;
        uint256 registrationYear;
        string degreeName;
        string medicalCouncilName;
    }

    struct Category {
        string name;
    }

    struct Patient {
        string name;
        address wallet;
        uint256 startTime;
        uint256 endTime;
        uint256 uniqueId;
        string status;
        string ipfsHash;
        uint256 doctorUniqueId; // Added field to store doctor's unique ID
        string medicalReportHash; // Added field to store the medical report hash
        string insurancePolicyId; // Added field to store the insurance policy ID
    }

    mapping(uint => Category) private listCategory;
    mapping(uint => Doctor) private listDoctors;
    mapping(string => Category) private categories;
    mapping(string => Doctor) private doctors;
    mapping(uint256 => Patient) private patients;

    uint private index;
    address private owner;

    event CategoryAdded(string name);
    event DoctorAdded(string name, uint256 uniqueId);
    event DoctorRemoved(uint256 uniqueId);
    event PatientDetails(string name, address wallet, uint256 startTime, uint256 endTime, uint256 uniqueId, string status);
    event DoctorPatientBooked(string doctorName, uint256 doctorUniqueId, string patientName, uint256 patientUniqueId);
    event PatientStatusChanged(uint256 patientId, string status);
    event MedicalReportSent(uint256 patientId, string medicalReportHash);
    event DoctorReview(uint256 patientId, uint256 rating, string comments);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function getOwnerAddress() public view returns (address) {
        return owner;
    }

    function addCategory(string memory categoryName) external onlyOwner {
        uint256 categoryId = ++index;
        Category storage newCategory = listCategory[categoryId];
        newCategory.name = categoryName;
        categories[categoryName] = newCategory;

        emit CategoryAdded(categoryName);
    }

    function addDoctor(
        string memory doctorName,
        string memory category,
        address doctorWallet,
        uint256 doctorFees,
        string memory registrationNo,
        uint256 registrationYear,
        string memory degreeName,
        string memory medicalCouncilName
    ) external onlyOwner {
        require(doctorFees > 0, "Fee should be greater than 0.");
        require(bytes(doctorName).length > 0, "Doctor name should not be empty.");

        Category storage selectedCategory = categories[category];
        require(bytes(selectedCategory.name).length > 0, "Category not found.");

        uint256 doctorId = ++index;
        Doctor storage newDoctor = listDoctors[doctorId];
        newDoctor.name = doctorName;
        newDoctor.category = category;
        newDoctor.wallet = doctorWallet;
        newDoctor.fees = doctorFees;
        newDoctor.uniqueId = doctorId;
        newDoctor.registrationNo = registrationNo;
        newDoctor.registrationYear = registrationYear;
        newDoctor.degreeName = degreeName;
        newDoctor.medicalCouncilName = medicalCouncilName;

        doctors[doctorName] = newDoctor;

        emit DoctorAdded(doctorName, doctorId);
    }

    function removeDoctor(uint256 doctorId) external onlyOwner {
        Doctor storage selectedDoctor = listDoctors[doctorId];
        require(bytes(selectedDoctor.name).length > 0, "Doctor not found.");
        delete doctors[selectedDoctor.name];
        delete listDoctors[doctorId];

        emit DoctorRemoved(doctorId);
    }

    function getAllCategories() external view returns (Category[] memory) {
        Category[] memory allCategories = new Category[](index);

        for (uint256 i = 1; i <= index; i++) {
            allCategories[i - 1] = listCategory[i];
        }

        return allCategories;
    }

    function getAllDoctors() external view returns (Doctor[] memory) {
        Doctor[] memory allDoctors = new Doctor[](index);

        for (uint256 i = 1; i <= index; i++) {
            allDoctors[i - 1] = listDoctors[i];
        }

        return allDoctors;
    }

    function getAllDoctorsInCategory(string memory category) external view returns (Doctor[] memory) {
        Category storage selectedCategory = categories[category];
        require(bytes(selectedCategory.name).length > 0, "Category not found.");

        uint256 count = 0;
        Doctor[] memory doctorList = new Doctor[](index);

        for (uint256 i = 1; i <= index; i++) {
            Doctor storage currentDoctor = listDoctors[i];
            if (keccak256(bytes(currentDoctor.category)) == keccak256(bytes(category))) {
                doctorList[count] = currentDoctor;
                count++;
            }
        }

        Doctor[] memory filteredDoctorList = new Doctor[](count);
        for (uint256 i = 0; i < count; i++) {
            filteredDoctorList[i] = doctorList[i];
        }

        return filteredDoctorList;
    }

    function getDoctorDetails(uint256 doctorId) external view returns (
        string memory,
        string memory,
        address,
        uint256,
        string memory,
        string memory,
        uint256,
        string memory,
        string memory
    ) {
        Doctor storage selectedDoctor = listDoctors[doctorId];
        require(bytes(selectedDoctor.name).length > 0, "Doctor not found.");

        return (
            selectedDoctor.name,
            selectedDoctor.category,
            selectedDoctor.wallet,
            selectedDoctor.fees,
            selectedDoctor.comment,
            selectedDoctor.registrationNo,
            selectedDoctor.registrationYear,
            selectedDoctor.degreeName,
            selectedDoctor.medicalCouncilName
        );
    }

    function bookDoctor(
        uint256 doctorId,
        string memory patientName,
        address patientWallet,
        string memory ipfsHash
    ) external payable {
        Doctor storage selectedDoctor = listDoctors[doctorId];
        require(bytes(selectedDoctor.name).length > 0, "Doctor not found.");

        require(msg.value == selectedDoctor.fees, "Insufficient payment.");

        uint256 patientId = ++index;

        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + 7 days;

        // Set the patient details
        Patient storage newPatient = patients[patientId];
        newPatient.name = patientName;
        newPatient.wallet = patientWallet;
        newPatient.startTime = startTime;
        newPatient.endTime = endTime;
        newPatient.uniqueId = patientId;
        newPatient.status = "Appointment booked";
        newPatient.ipfsHash = ipfsHash;
        newPatient.doctorUniqueId = doctorId; // Store the doctor's unique ID for the patient

        // Transfer the fees to the doctor's wallet
        payable(selectedDoctor.wallet).transfer(msg.value);

        emit PatientDetails(patientName, patientWallet, startTime, endTime, patientId, "Appointment booked");

        // Additional event for doctor-patient relationship
        emit DoctorPatientBooked(selectedDoctor.name, doctorId, patientName, patientId);
    }

    function changeStatus(uint256 patientId, string memory status) external {
        require(bytes(status).length > 0, "Status should not be empty.");
        require(bytes(patients[patientId].name).length > 0, "Patient not found.");

        Patient storage selectedPatient = patients[patientId];
        require(selectedPatient.wallet == msg.sender, "Only patient can change the status.");

        if (keccak256(bytes(status)) == keccak256("treatment going on")) {
            // Only the doctor who booked the patient can set the status to "treatment going on"
            require(
                selectedPatient.doctorUniqueId == listDoctors[selectedPatient.doctorUniqueId].uniqueId,
                "Only the doctor who booked the patient can change the status to 'treatment going on'."
            );
            selectedPatient.endTime = 0; // Set the end time to 0 since treatment is ongoing
        } else if (keccak256(bytes(status)) == keccak256("Treated")) {
            // Only the doctor who booked the patient can set the status to "treated"
            require(
                selectedPatient.doctorUniqueId == listDoctors[selectedPatient.doctorUniqueId].uniqueId,
                "Only the doctor who booked the patient can change the status to 'treated'."
            );
            selectedPatient.endTime = block.timestamp; // Set the end time to the current block timestamp
        }

        selectedPatient.status = status;
        emit PatientStatusChanged(patientId, status);
    }

    function sendMedicalReport(uint256 patientId, string memory medicalReportHash) external {
        require(bytes(medicalReportHash).length > 0, "Medical report hash should not be empty.");
        require(bytes(patients[patientId].name).length > 0, "Patient not found.");

        Patient storage selectedPatient = patients[patientId];
        Doctor storage selectedDoctor = listDoctors[selectedPatient.doctorUniqueId];

        require(selectedDoctor.wallet == msg.sender, "Only the doctor who booked the patient can send the medical report.");

        selectedPatient.medicalReportHash = medicalReportHash;

        emit MedicalReportSent(patientId, medicalReportHash);
    }

    function giveDoctorReview(uint256 doctorId, uint256 patientId, uint256 rating, string memory comments) external {
        Doctor storage selectedDoctor = listDoctors[doctorId];
        require(bytes(selectedDoctor.name).length > 0, "Doctor not found.");

        Patient storage selectedPatient = patients[patientId];
        require(bytes(selectedPatient.name).length > 0, "Patient not found.");
        require(keccak256(abi.encodePacked(selectedPatient.status)) == keccak256(abi.encodePacked("Treated")), "Patient not treated yet.");

        selectedDoctor.comment = comments;

        emit DoctorReview(patientId, rating, comments);
    }

    function getDoctorReview(string memory doctorName) external view returns (string memory) {
        Doctor storage selectedDoctor = doctors[doctorName];
        require(bytes(selectedDoctor.name).length > 0, "Doctor not found.");

        return selectedDoctor.comment;
    }

    function getPatientInfo(uint256 patientId, address patientWallet)
        external
        view
        returns (
            string memory name,
            uint256 startTime,
            uint256 endTime,
            uint256 uniqueId,
            string memory status,
            string memory ipfsHash,
            uint256 doctorUniqueId,
            string memory doctorName,
            string memory doctorCategory,
            address doctorWallet,
            string memory doctorRegistrationNo
        )
    {
        require(bytes(patients[patientId].name).length > 0, "Patient not found.");
        require(patients[patientId].wallet == patientWallet, "Invalid patient wallet address.");

        Patient storage selectedPatient = patients[patientId];
        Doctor storage selectedDoctor = listDoctors[selectedPatient.doctorUniqueId];

        require(bytes(selectedDoctor.name).length > 0, "Doctor not found.");

        doctorName = selectedDoctor.name;
        doctorCategory = selectedDoctor.category;
        doctorWallet = selectedDoctor.wallet;
        doctorRegistrationNo = selectedDoctor.registrationNo;

        return (
            selectedPatient.name,
            selectedPatient.startTime,
            selectedPatient.endTime,
            selectedPatient.uniqueId,
            selectedPatient.status,
            selectedPatient.ipfsHash,
            selectedDoctor.uniqueId,
            doctorName,
            doctorCategory,
            doctorWallet,
            doctorRegistrationNo
        );
    }
}