/**
 *Submitted for verification at polygonscan.com on 2022-08-25
*/

pragma solidity ^0.8.7;

contract college{
      struct studentdetails{
        string name;
        uint class;
        uint fesspaid;

      }



     mapping(uint => studentdetails) private _students;
     uint public totalstudents;



     function enroll(string memory name_, uint class_) external{

         _students[totalstudents].name = name_;
         _students[totalstudents].class = class_;
         _students[totalstudents].fesspaid = 0;
         totalstudents += 1;
     }
     

     function getstudentdetails(uint rollnumber_) external view  returns (studentdetails memory){

         return _students[rollnumber_];
     }

    function payfees(uint rollnumber_)
    external payable
    {
      _students[rollnumber_].fesspaid+= msg.value;
      
    }

}