/**
 *Submitted for verification at polygonscan.com on 2022-08-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract College {
    
    struct StudentDetails {
        string name;
        uint class;
        uint feesPaid;
    }

    mapping(uint => StudentDetails) private _students;

    uint public totalStudents;

    function enroll(string memory name_,uint class_) external {
        _students[totalStudents].name = name_;
        _students[totalStudents].class = class_;
        _students[totalStudents].feesPaid=0;
        totalStudents+=1;
    }

    function getStudentDetails(uint RollNumber_) external view returns (StudentDetails memory){
        return _students[RollNumber_];
    }

    function payFees(uint RollNumber_)
    external payable
    {
        _students[RollNumber_].feesPaid+=msg.value;
    }

//0.1 Matic
//Wei
//1 Matic=10**18 Wei
//1 Matic->10**18 Wei
//0.1 Matic=10**17 Wei

}