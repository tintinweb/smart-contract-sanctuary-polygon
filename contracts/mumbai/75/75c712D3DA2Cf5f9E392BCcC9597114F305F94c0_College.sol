/**
 *Submitted for verification at polygonscan.com on 2022-10-09
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract College {
    struct studentDetails {
        string name;
        uint class;
        uint feesPaid;
    }

    mapping(uint=>studentDetails) private _students;

    uint public totalStudents;

    function enroll(string memory name_, uint class_) public {
        _students[totalStudents].name =name_;
        _students[totalStudents].class =class_;
        _students[totalStudents].feesPaid =0;
        totalStudents = totalStudents + 1;
    }

    function getStudentsByIndex(uint index_) public view returns(studentDetails memory) {
        return _students[index_];
    }

    function payFees(uint index_) public payable {
        _students[index_].feesPaid + msg.value;
    }
}