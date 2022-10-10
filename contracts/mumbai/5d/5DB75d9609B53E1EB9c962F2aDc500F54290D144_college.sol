/**
 *Submitted for verification at polygonscan.com on 2022-10-09
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; 
//struct --> self defined data type
contract college {
    struct StudentDetails {
        string name ;
        uint class;
        //string gendre;
        uint feesPaid;
    }
    //string private _CollegeName ="IITB";
    //function foo(uint rollnumber , uint class_name_ ) returns (bool) {
      //  return true;
    //}
    //mapping --> associating details with a number 
    mapping(uint => StudentDetails) private _students;

    uint public totalStudents;
    //memory --> temorarily ; storage --> permanent 
    //view ---> to see

    function enroll(string memory name_, uint class_ ) public {
        _students[totalStudents].name = name_;
        _students[totalStudents].class = class_;
        //_students[totalStudents].gendre = gendre_;
        _students[totalStudents].feesPaid =0;
        totalStudents = totalStudents + 1;

    }
    function getStudentsByIndex(uint index_) public view returns (StudentDetails memory ) {
        return _students[index_];
    }

    function payFees(uint index_) public payable {
        _students[index_].feesPaid + msg.value;
    }


}