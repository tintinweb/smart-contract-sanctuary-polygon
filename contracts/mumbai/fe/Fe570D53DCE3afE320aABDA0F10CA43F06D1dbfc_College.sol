/**
 *Submitted for verification at polygonscan.com on 2022-08-25
*/

// SPDX-License-Identifier: MIT;

//above line is compusory

// specify the solidity compiler
pragma solidity ^0.8.7;

contract College {

    // we are declaring struct to declare dictionary/object
    struct StudentDetails {
        string name;
        uint class;
        uint feePaid;
    }

    // private variable starts with _
    mapping(uint => StudentDetails) private _students; // used to store key value pair
    // uint will point to the object of StudentDetails
    
    uint public totalStudents; // public because it will be available to outside this contract also;// default value = 0
    
    // parameter name ends with _
    function enroll(string memory name_, uint class_) external { // will add student name to mapping
        _students[totalStudents].name     = name_;
        _students[totalStudents].class    = class_;
        _students[totalStudents].feePaid  = 0;
        totalStudents++;
    }

    function payFees(uint rollNumber_) external payable { // payble = to use msg.value
        _students[rollNumber_].feePaid  += msg.value;
        //msg.value == we will get value which user supplied while calling this function
    }

    // 0.1 matic
    // Wei
    // 1 matic = 10**18 Wei
    // if we have to tranfer 1 matic then we need to send 10**18 Wei
    // 

    function getStudentDetails(uint rollNumber_) external view returns (StudentDetails memory){ // memory is keyword.. 
        return _students[rollNumber_];
    }
}