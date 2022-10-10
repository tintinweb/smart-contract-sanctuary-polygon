/**
 *Submitted for verification at polygonscan.com on 2022-10-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract CollegeContract{
    struct Studentdetails{
        string name;
        uint class;
        uint feePaid;
    }
    mapping(uint=>Studentdetails) private _students;
    
    uint totalStudents;

    function enroll(string memory name,uint class) public{
        _students[totalStudents].name = name;
        _students[totalStudents].class = class;
        _students[totalStudents].feePaid = 0;
        totalStudents = totalStudents + 1;
    }   

    function getStudentByIndex(uint index_) public view returns(Studentdetails memory) {
        return _students[index_];
    }

    function payFees(uint index_) public payable{
        _students[index_].feePaid = _students[index_].feePaid + msg.value;
    }
    
}