/**
 *Submitted for verification at polygonscan.com on 2022-08-25
*/

//SPDX-License-Identifier:MIT;
pragma solidity^0.8.7;

contract college{

    struct StudentDetails{
        string name;
        uint class;
        uint feespaid;
    }
    mapping(uint => StudentDetails) private _students;

    uint public totalstudents;


    function enroll(string memory name_,uint class_) external {

        _students[totalstudents].name = name_;
        _students[totalstudents].class = class_;
        _students[totalstudents].feespaid = 0;
        totalstudents +=1;
    }

    function getstudentdetails(uint rollnumber_) external view returns (StudentDetails memory){
        return _students[rollnumber_];
    }
    function payfees(uint rollnumber_)
    external payable{
        _students[rollnumber_].feespaid += msg.value;
    }
}