/**
 *Submitted for verification at polygonscan.com on 2022-10-09
*/

// SPDx-License-Identifier: MIT

pragma solidity ^0.8.7;

contract College {
    struct StudentDetails {
        string name; // name of the student
        uint class; // year of study
        uint feesPaid; // payable variable
    }

    // private members have a _ in their name
    mapping (uint=>StudentDetails) private _students;

    uint public totalStudents = 0;

    // _ used after variable to signify parameter
    // memory keyword added to not store on storage (deleted just after contract runs)
    function enroll(string memory name_,uint  class_) public {
        _students[totalStudents].name = name_;
        _students[totalStudents].class = class_;
        _students[totalStudents].feesPaid = 0;
        totalStudents++;
    }

    function getStudentsByIndex(uint rollnum_) view public returns(StudentDetails memory) {
        return _students[rollnum_];
    }

    function payFees(uint index_) public payable {
        _students[index_].feesPaid += msg.value; 
    }
}