/**
 *Submitted for verification at polygonscan.com on 2022-08-25
*/

// SPDX-License-Identifier: MIT

// as solidity dont support decimals so new unit is *wei* 
// 1 matic = 10^18 wei = when we want to send less than 1 matic 

pragma solidity ^0.8.7;

contract College{

    struct StudentDetails{
        string name;      // by default it will be empty string 
        uint class;       // by default it will be 0 
        uint feesPaid;
    }

    mapping(uint => StudentDetails) private _students;

    uint public totalstudents;

    function enroll(string memory name_ , uint class_) external {
        _students[totalstudents].name = name_;
        _students[totalstudents].class = class_;
        _students[totalstudents].feesPaid = 0;
        totalstudents += 1;
    }

    function PayFees(uint rollNumber_) external payable {
        _students[rollNumber_].feesPaid += msg.value;
    }

    function getDetailsByRollNo(uint rollNumber_) external view returns(StudentDetails memory){
        return _students[rollNumber_];
    } 

}