//SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.0;

contract MEClassroom {
    struct Student {
        uint id;
        string name;
        string course;
        Deliverable[] deliverables;
    }
    struct Deliverable {
        uint id;
        address author;
        string url;
    }

    mapping(uint => Student) private students;
    uint private studentCount;

    function addStudent(
        uint _id,
        string memory _name,
        string memory _course
    ) public {
        require(students[_id].id == 0, "Student ID already exists");
        require(_id > 0, "ID must be greater than 0");
        Student storage newStudent = students[_id];
        newStudent.id = _id;
        newStudent.name = _name;
        newStudent.course = _course;
        studentCount++;
    }

    function submitDeliverable(
        uint _studentId,
        uint _id,
        string memory _deliverableUrl
    ) public returns (string memory) {
        require(students[_studentId].id != 0, "Student ID does not exist");
        checkDuplicateDeliverableId(_studentId, _id);
        Student storage student = students[_studentId];
        student.deliverables.push(
            Deliverable(_id, msg.sender, _deliverableUrl)
        );
        // (bool success, ) = msg.sender.call{value: 2000000000000000000}("");
        // require(success, "Incentive Transfer failed.");
        return "Deliverable added succesfully!";
    }

    function checkDuplicateDeliverableId(
        uint _studentId,
        uint _id
    ) internal view {
        Student storage student = students[_studentId];

        for (uint i = 0; i < student.deliverables.length; i++) {
            require(
                student.deliverables[i].id != _id,
                "Duplicate deliverable ID"
            );
        }
    }

    function getStudentById(
        uint _id
    ) public view returns (uint, string memory, string memory) {
        require(students[_id].id != 0, "Student ID does not exist");

        Student storage student = students[_id];
        return (student.id, student.name, student.course);
    }

    function getDeliverablebyId(
        uint _studentId
    ) public view returns (Deliverable[] memory) {
        require(students[_studentId].id != 0, "Student ID does not exist");
        return students[_studentId].deliverables;
    }

    function getCourseDetails() public pure returns (string memory) {
        string
            memory courseDetails = "Course Name: Introduction to Solidity\nInstructor: Aman Zishan\nSchedule: Weekly once saturday or sunday, 6PM to 7PM";
        return courseDetails;
    }

    function getStudentCount() public view returns (uint) {
        return studentCount;
    }
}