/**
 *Submitted for verification at polygonscan.com on 2022-08-25
*/

// SPDX-License-Identifier: MIT;
pragma solidity 0.8.7;


contract college {

struct stduentdetails{
   string name;
   uint class;
   uint feespaid;

}

uint public i;
mapping (uint => stduentdetails ) private _students;
function enroll(string memory name_,uint class_) external {
    
   _students[i].name=name_;
   _students[i].class=class_;
   _students[i].feespaid=0;
    i=i+1;
}




function getstudentdetails(uint rollnum) external view returns
  (stduentdetails memory){
  return _students[rollnum];

}



function payfees(uint rollnum_) external payable
{
_students[rollnum_].feespaid+=msg.value;
}


}