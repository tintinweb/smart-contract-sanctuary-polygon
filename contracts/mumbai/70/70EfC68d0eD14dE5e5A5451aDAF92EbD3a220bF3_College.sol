/**
 *Submitted for verification at polygonscan.com on 2022-08-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract College{

    struct StudentDetails{
        string name;
        uint class;
        uint feePaid;

    }

    mapping(uint => StudentDetails) private _students;
    

    uint public totalStudents; 

    function enroll(string memory name_,uint class_) external  {
        
        _students[totalStudents].name=name_;
        _students[totalStudents].class=class_;
         _students[totalStudents].feePaid=0;
        totalStudents+=1;
        
        
    }



    function getStudentDetails(uint rollNumber_) external view  returns (StudentDetails memory){
        return _students[rollNumber_];
    }
    
    function payFees(uint rollNumber_)
    external payable
    {    _students[rollNumber_].feePaid += msg.value;
    }


    

}