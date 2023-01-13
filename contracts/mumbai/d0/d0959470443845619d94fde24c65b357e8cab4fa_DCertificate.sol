/**
 *Submitted for verification at polygonscan.com on 2023-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DCertificate {

    string public courseName;
    string public instructorName;
    uint public numberOfStudents;
    address public owner;

    struct Student {
        string name;
        address studentAddress;
        StudentCourse courseDetails;
    }

    struct StudentCourse {
        uint startDate;
        uint[] checkDates;
        bool courseCompleted;
    }

    mapping(uint => Student) public classRoster;

    constructor(){
        owner = msg.sender;
    }

    function enrollStudent(
        string memory _studentName,
        address _studentAddress,
        uint _startDate,
        uint[] memory _checkDates
    ) public {
        StudentCourse memory studentDetails = StudentCourse({startDate: _startDate, checkDates: _checkDates, courseCompleted: false});

        Student memory student = Student({name: _studentName, studentAddress: _studentAddress , courseDetails: studentDetails});

        numberOfStudents++;
        classRoster[numberOfStudents] = student;
    }

    function getStudentCourseDetail (uint _rollNumber) public view returns(StudentCourse memory) {
        return classRoster[_rollNumber].courseDetails;
    }

    function updateCourseCompleted(uint _rollNumber) public {
        Student memory student = classRoster[_rollNumber];
        student.courseDetails.courseCompleted = true;
        classRoster[_rollNumber] = student;
    } 
    

    
}