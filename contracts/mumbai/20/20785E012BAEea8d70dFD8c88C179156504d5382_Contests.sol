// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Contests {

   struct Contest { 
      string title;
      uint contest_id;
   }
   Contest contest;

   function setContest() public {
      contest = Contest('Festival MLDY Yatch Club !',  1);
   }
   function getContestId() public view returns (uint) {
      return contest.contest_id;
   } 
   function getContestTitle(uint) public view returns (string memory) {
      return contest.title;
   }
}