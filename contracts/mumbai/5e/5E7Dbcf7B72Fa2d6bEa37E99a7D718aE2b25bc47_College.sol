// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract College {
    struct StudentData {
        bytes32 name; // student name
        bytes32 lastName; // student lastName
        uint16 age; // student age
        uint256 certificateId;
    }

    // owner address
    address public _owner;

    /// @dev Mapping studentId to StudentData
    mapping(uint256 => StudentData) public _students;

    /// @dev Students count
    uint256 public _studentsCount;

    /// @notice Emitted when a new student created
    /// @param studentId - Student identifier
    /// @param name - Student first name
    /// @param lastName - Student last name
    /// @param age - Student age
    /// @param certificateId - Student certificate
    event LogNewStudentCreated(
        uint256 studentId,
        bytes32 name,
        bytes32 lastName,
        uint16 age,
        uint256 certificateId
    );

    /// @notice Emitted when a student updated
    /// @param studentId - Student identifier
    /// @param name - Student first name
    /// @param lastName - Student last name
    /// @param age - Student age
    /// @param certificateId - Student certificate
    event LogStudentDataUpdated(
        uint256 studentId,
        bytes32 name,
        bytes32 lastName,
        uint16 age,
        uint256 certificateId
    );

    /// @notice Emitted when a student removed
    /// @param studentId - Student identifier
    event LogStudentRemoved(uint256 studentId);

    constructor() {
        _owner = msg.sender;
    }

    /// @notice Check if a student exists
    /// @param studentId - Name of token type in bytes32
    modifier studentExists(uint256 studentId) {
        require(
            _students[studentId].name > 0,
            "C 401 - Student does not exits"
        );
        _;
    }

    /// @notice Check that a sender is a owner of contract
    modifier ownerOnly() {
        require(
            _owner == msg.sender,
            "C 400 - Only owner can create new student"
        );
        _;
    }

    function createNewStudent(
        bytes32 name,
        bytes32 lastName,
        uint16 age,
        uint256 certificateId
    ) external ownerOnly {
        /// @dev Create new student
        StudentData memory studentData = StudentData(
            name,
            lastName,
            age,
            certificateId
        );

        _studentsCount++;
        _students[_studentsCount] = studentData;

        emit LogNewStudentCreated(
            _studentsCount,
            name,
            lastName,
            age,
            certificateId
        );
    }

    function removeStudent(uint256 studentId)
        external
        ownerOnly
        studentExists(studentId)
    {
        _studentsCount--;

        delete _students[studentId];

        emit LogStudentRemoved(studentId);
    }

    function getStudent(uint256 studentId)
        external
        view
        studentExists(studentId)
        returns (StudentData memory)
    {
        return _students[studentId];
    }

    function updateStudentData(
        uint256 studentId,
        bytes32 name,
        bytes32 lastName,
        uint16 age,
        uint256 certificateId
    ) external ownerOnly studentExists(studentId) {
        _students[studentId] = StudentData(name, lastName, age, certificateId);

        emit LogStudentDataUpdated(
            studentId,
            name,
            lastName,
            age,
            certificateId
        );
    }
}