/**
 *Submitted for verification at polygonscan.com on 2022-10-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract College {
    struct Student {
        string name;
        uint feesPaid;
        uint class;
    }
    mapping(uint => Student) private _students;
     uint public totalStudents;
     function enroll(string memory name_,uint class_) external{
         _students[totalStudents].name = name_;
         _students[totalStudents].class = class_;
         _students[totalStudents].feesPaid = 0;
         totalStudents = totalStudents +1;
     }
     function getStudentDetails(uint rollNumber_) 
    external view returns
     (Student memory){
        return _students[rollNumber_];
    }

    function payFees(uint rollNumber_) 
    external payable
     {
         _students[rollNumber_].feesPaid += 
         msg.value;
    }
}