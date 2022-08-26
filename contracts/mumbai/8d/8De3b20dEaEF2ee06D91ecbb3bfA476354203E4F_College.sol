/**
 *Submitted for verification at polygonscan.com on 2022-08-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract College{

    struct StudentDetails{
        string name;
        uint class;
        uint feesPaid;
    }


    mapping(uint=>StudentDetails) private _students;

    uint public totalStudents; 

    function enroll(string memory name_, uint class_) external {
        _students[totalStudents].name = name_;
        _students[totalStudents].class = class_;
        _students[totalStudents].feesPaid = 0;
        totalStudents+=1;
    }

    function payFees(uint rollNumber_) external payable
    {
        _students[rollNumber_].feesPaid += msg.value;
    }


    function getStudentDetails(uint rollNumber_) external view returns(StudentDetails memory){
        return _students[rollNumber_];
    }

}