/**
 *Submitted for verification at polygonscan.com on 2022-10-09
*/

// SPDX-License-Identifier: MIT
pragma solidity^0.8.7;

contract College{                      //details regarding students and relations between them
  struct StudentDetails{               // defining student details
      string name;
      uint class;
      uint feesPaid;
  }

  // mapping can considered as a key value map: i.e roll number has some details thus mapped to some details
  mapping(uint=>StudentDetails) private _students; // roll no.assigned with private
  
  uint public totalStudents; //giving variable value or not giving it would be considered as equal to zero when defined
  function enroll(string memory name_, uint class_) public{    //keeping variable in memeory variable will allow to declare it once and use it multiple times
      _students[totalStudents].name = name_;
      _students[totalStudents].class = class_;
      _students[totalStudents].feesPaid = 0;
      totalStudents = totalStudents + 1;
  }
  
  function getStudentsByIndex(uint index_) public view returns(StudentDetails memory) // in return first specific: variable name and then type
   {
       return _students[index_];
   }

   function payFees(uint index_) public payable{
       _students[index_].feesPaid = _students[index_].feesPaid + msg.value; // msg.sender whcih address the function was being called. and stores a value you will be sending
       
   }

}