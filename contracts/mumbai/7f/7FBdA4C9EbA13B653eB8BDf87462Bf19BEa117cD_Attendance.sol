/**
 *Submitted for verification at polygonscan.com on 2023-04-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Attendance {
    struct AttendanceData {
        address instructor;
        mapping(uint64 => uint64) classData;
    }
    mapping(string => AttendanceData) private attendance;

    function setAttendance(string memory courseCode, uint64 classIndex, uint64 attendanceData) public {
    require(
        attendance[courseCode].instructor == msg.sender,
        "Only the instructor can edit attendance data."
    );

    attendance[courseCode].classData[classIndex] = attendanceData;
}


    function getAttendanceData(
        string memory courseCode,
        uint64 classIndex,
        uint64 rollNo
    ) public view returns (bool) {
        uint64 mask = uint64(1) << (rollNo - 1);
        return (attendance[courseCode].classData[classIndex] & mask) != 0;
    }

    function editAttendance(
        string memory courseCode,
        uint64 classIndex,
        uint64 rollNo,
        bool bitValue
    ) public {
        require(
            attendance[courseCode].instructor == msg.sender,
            "Only the instructor can edit attendance data."
        );

        uint64 mask = uint64(1) << (rollNo - 1);
        if (bitValue) {
            attendance[courseCode].classData[classIndex] |= mask;
        } else {
            attendance[courseCode].classData[classIndex] &= ~mask;
        }
    }

    function setInstructor(string memory courseCode) public {
        require(
            attendance[courseCode].instructor == address(0),
            "Instructor has already been set."
        );
        attendance[courseCode].instructor = msg.sender;
    }

    function getInstructor(string memory courseCode)
        public
        view
        returns (address)
    {
        return attendance[courseCode].instructor;
    }
}