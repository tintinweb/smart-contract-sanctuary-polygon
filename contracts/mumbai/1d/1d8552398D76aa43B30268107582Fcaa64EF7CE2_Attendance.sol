/**
 *Submitted for verification at polygonscan.com on 2023-04-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Attendance {
    struct AttendanceData {
        address instructor;
        uint64[] data;
    }
    mapping(string => AttendanceData) private attendance;

    function setAttendance(string memory courseCode, uint8[] memory attendanceData) public {
        require(attendance[courseCode].instructor == msg.sender, "Only the instructor can edit attendance data.");
        require(attendanceData.length == attendance[courseCode].data.length, "Attendance data size mismatch.");

        for (uint i = 0; i < attendanceData.length; i++) {
            if (attendanceData[i] == 1) {
                attendance[courseCode].data[i] |= uint64(1) << i;
            } else {
                attendance[courseCode].data[i] &= ~(uint64(1) << i);
            }
        }
    }

    function getAttendanceData(string memory courseCode, uint256 rollNo) public view returns (uint64) {
        return attendance[courseCode].data[rollNo];
    }

    function setInstructor(string memory courseCode) public {
        require(attendance[courseCode].instructor == address(0), "Instructor has already been set.");
        attendance[courseCode].instructor = msg.sender;
    }

    function getInstructor(string memory courseCode) public view returns (address) {
        return attendance[courseCode].instructor;
    }
}