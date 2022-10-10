/**
 *Submitted for verification at polygonscan.com on 2022-10-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract college{
    struct studentDetails{
        string name;
        uint class;
        uint fesspaid;
    }
    mapping(uint=>studentDetails) private _students;
    uint totalstudent;
    function enroll(string memory name_, uint class_)public{
        _students[totalstudent].name = name_ ;
        _students[totalstudent].class = class_;
        _students[totalstudent].fesspaid = 0;
        totalstudent = totalstudent +1;
    }
    function getstudentsByIndesx(uint index_) public view returns(studentDetails memory){
        return _students[index_];
    }
    function payFess(uint index_)public payable{
        _students[index_].fesspaid += msg.value;
    }
}