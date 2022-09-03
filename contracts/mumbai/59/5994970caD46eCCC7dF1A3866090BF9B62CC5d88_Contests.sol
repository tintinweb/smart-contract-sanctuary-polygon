// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;


contract Contests {

   struct Contest { 
      string title;
      uint id;
   }
   Contest public contest;

   constructor() {
      contest = Contest("Festival MLDY Yatch Club !",  1);
   }

   function setContestTitle(string memory _title) public {
      contest.title = _title;
   }

   function getContestTitle(uint _id) public view returns (string memory) {
      return contest.title;
   }
}