/**
 *Submitted for verification at polygonscan.com on 2022-08-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract college {

    struct StudentDetails{
        string name;
        uint class;
        uint feesPaid;
    }

    //mapping(uint => string) private _students;
    mapping(uint => StudentDetails) private _students;
    uint public totalStudents;

    function enroll(string memory name_,uint class_) external{    //string will last only till execution of this function and not stored  in blockchain
            _students[totalStudents].name=name_;
            _students[totalStudents].class=class_;
             _students[totalStudents].feesPaid=0;
            totalStudents += 1;
    }


    function getStudentDetails(uint rollNumber_) external view returns(StudentDetails memory){
            return _students[rollNumber_];
    }

    function payFees(uint rollNumber_) external payable{
        _students[rollNumber_].feesPaid +=  msg.value;
    }

//Sol does not allow to transfer decimal
//0.1 Matic
//1 Matic=10**18 Wei
}