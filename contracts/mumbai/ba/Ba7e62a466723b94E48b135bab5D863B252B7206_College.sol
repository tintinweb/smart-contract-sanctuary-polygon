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
    // string private _collegeName = "IITB";
    // function foo (uint rollnumber_, string class_) returns (bool) {
    //     return true;
    // }

    mapping(uint=>StudentDetails) private _students; // in solidity mapping is faster than using array

    uint public totalStudents = 0;

    function enroll(string memory name_, uint class_) public { // if we are storing it in memory it will be removed as
    // soon as function call is over, for permenantly storing we have to use keyword-storage, fetching the data is slow
        _students[totalStudents].name = name_;
        _students[totalStudents].class = class_;
        _students[totalStudents].feesPaid = 0;
        totalStudents += 1;
    }

    function getStudentsByIndex(uint index_) public view returns(StudentDetails memory) {
        return _students[index_];
    }

    function payFees(uint index_) public payable {
        _students[index_].feesPaid += msg.value; // msg is the data passed while calling the function, msg.sender is wallet
        // address
    }
}