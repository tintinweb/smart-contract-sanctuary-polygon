/**
 *Submitted for verification at polygonscan.com on 2022-02-25
*/

pragma solidity ^0.8.7;
contract School {
   address public teacher; 

   constructor()  {
      teacher = msg.sender;
   }


   modifier onlyTeacher {
	
      require(msg.sender == teacher);
      _;
   }
}

contract Notice is School {
   string public notice;
   constructor(string memory intialnotice) { notice = intialnotice; } 


   function changeNotice(string memory _notice) public onlyTeacher {
      notice = _notice;
   }
}