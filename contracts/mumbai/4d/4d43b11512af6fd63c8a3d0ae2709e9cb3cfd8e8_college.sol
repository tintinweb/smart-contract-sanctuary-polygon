/**
 *Submitted for verification at polygonscan.com on 2022-10-09
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

contract college{
    struct StudentDetails {
        string name;
        uint class;
        uint feesPaid;

    }
    //string collegeName="IITB"//naming convention for public variables
   // string private _collegeName="IITB" //naming convetnion for pvt variables
    mapping(uint=>StudentDetails) private _students;
    /*defines what type maps to the other type here rollno (uint) maps to datatype of student details */
    
    uint public totalStudents=0;

    function enroll(string memory name_,uint class_) public{//stores in memory in stead of storage makes a memory variable saves gas(money) 
        _students[totalStudents].class=class_;
        _students[totalStudents].name=name_;
        _students[totalStudents].feesPaid=0;
        totalStudents=totalStudents+1;

    }


    function getStudentByIndex(uint index_) public view returns(StudentDetails memory){
        return _students[index_];
    }
    function payfees(uint index_) public payable {
        _students[index_].feesPaid + msg.value;
    }
}