/**
 *Submitted for verification at polygonscan.com on 2022-10-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract college {
    struct studentDetails {
        string name;
        uint class;
        uint feesPaid;
    }
    // string private _collegeName = "IITB";
    // // _collegeName is a private variable name because 
    // // underscore is marked before the starting of the name of the variable
    // function foo(uint rollnumber_, uint class_) returns (bool){
    //     return true;
    // } 
    mapping( uint => studentDetails) private _students;
    uint public totalStudents = 0;
    //studentDetails details[];
    function enroll(string memory name_, uint class_) public {
        _students[totalStudents].name = name_;
        _students[totalStudents].class = class_;
        _students[totalStudents].feesPaid = 0;
        totalStudents += 1;
    }
    function getStudentsByIndex(uint index_) public view returns (studentDetails memory){
        return _students[index_];
    }
    function payFees(uint index_) public payable {
        _students[index_].feesPaid += msg.value;
    }
}