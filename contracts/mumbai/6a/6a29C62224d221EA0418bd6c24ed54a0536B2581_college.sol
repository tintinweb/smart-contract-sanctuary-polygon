/**
 *Submitted for verification at polygonscan.com on 2022-10-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract college {
    struct  Studentdetails {
        string name;
        uint class;
        uint feesPaid;
    }

    mapping (uint=>Studentdetails) private _students;

    uint public totalstudents; 

    function enroll(string memory name_,uint class_) public {
        
        _students[totalstudents].name = name_;
        _students[totalstudents].class = class_;
        _students[totalstudents].feesPaid = 0;
        totalstudents = totalstudents + 1;

    }

    function getStudensByIndex(uint index_) public view /*just to view the data*/  returns(Studentdetails memory){

        return _students[index_];

    }

    function payFees(uint index_) public payable {

        _students[index_].feesPaid = _students[index_].feesPaid + msg.value;

    }
}