/**
 *Submitted for verification at polygonscan.com on 2023-02-04
*/

// Version 1.0          
                                                                                 

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Contests {

   struct ContestVote { 
      address artist_address;
      uint voteCount; 
   }

   struct Contest {
      uint256 id;
      string title;       
      uint status;  // 0 = NOT STARTED, 1 = STARTED, 2 = ENDED
      uint256 balance;
      address[] artist_addresses;
      ContestVote[] votes;
   }


   //map(contestId => Contest)
   mapping(uint256 => Contest) contests;

   address owner; 
   uint256 numContests = 0;

   constructor(){
       owner =  payable(msg.sender);
   }

   event OnContestCreated(string title, address[] artists_addresses, uint256  id_contest); 
   
 
   function createContest(string memory title, address[] memory artists_addresses) public returns(uint256 id) {
       require(msg.sender == owner, "Only Mellody can create contests !");
       id = numContests + 1;
       Contest storage c = contests[id];
       c.id = id;
       c.title = title;
       c.status = 0;
       c.balance = 0;
       
       for(uint i=0; i< artists_addresses.length; i++){ 
         c.artist_addresses.push(artists_addresses[i]);   
       }

       contests[c.id] = c;

       numContests = id;

       emit OnContestCreated(title, artists_addresses, c.id);  
       return c.id;
   }


   function readContest(uint256 id) external view returns (Contest memory) {
       Contest storage contest = contests[id];
       return contest;
   }

   function lastContest() external view returns (Contest memory){
       return contests[numContests];
   }
}