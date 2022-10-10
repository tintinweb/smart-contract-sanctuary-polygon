/**
 *Submitted for verification at polygonscan.com on 2022-10-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract College {
    struct StudentDetails {
        string name;
        uint class;
        uint feesPaid;
    }
    
    // underscore is used just for convention for e.g for declaring a variable private we use underscore at start (_name)

    mapping(uint=>StudentDetails) private _students ;

    uint public totalStudents;

    function enroll(string memory name_, uint class_) public { //memory used for optimization(less gas) so name & class not used across function
        _students[totalStudents].name = name_;
        _students[totalStudents].class = class_;
        _students[totalStudents].feesPaid = 0;
        totalStudents = totalStudents + 1;
    }

    function getStudentsByIndex(uint index_) public view returns(StudentDetails memory){ //view becoz we r not transcating just viewing
       return _students[index_];
    } 

    function payFees(uint index_) public payable{
        _students[index_].feesPaid = _students[index_].feesPaid + msg.value; 
    }
    
}