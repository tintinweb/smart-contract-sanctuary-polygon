// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../utils/EnumDeclarations.sol";
import "../utils/StructDeclarations.sol"; 

contract GemboxDAO {

  //-------- GLOBAL VARIABLES ----------------------------------------------------------

  string public appName;  // Name of App

  address private owner;  // Owner wallet address
  LotteryPoolStruct[] private activePoolList; // List of all the active lottery list 


  //--------- MAPPINGS ------------------------------------------------------------------

  mapping (uint => WinnerStruct) public winners;  // Winners List corresponding to the lotteryId
  

  //--------- MODIFIERS ------------------------------------------------------------------

  modifier onlyOwner() {    // Modifier for restricting access only owner allowed functions
    require(msg.sender == owner, "Unauthorised");
    _;
  }


  //--------- CONSTRUCTOR ------------------------------------------------------------------

  constructor(string memory _app_name){
    owner =  msg.sender;
    appName = _app_name;
  }

  //--------- PRIVATE FUNCTIONS ------------------------------------------------------------------


  
  //--------- PUBLIC FUNCTIONS ------------------------------------------------------------------

  // Create Lottery Pool
  function createPool() public onlyOwner {
  }

  //To get the array of active pools 
  function getActivePoolList() public view  {
  }
  
  // Join Lottery Pool
  function joinPool() view public {
    
  }

  // Claim Winning Prize
  function claimPrize() public {

  }

  // Choose Winner
  function chooseWinner() public {
    
  }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

enum LotteryStatus {
  Completed,
  Active
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./EnumDeclarations.sol";

struct LotteryTicketStruct{
  uint ticketNumber;
  uint poolId;
  address ticketHolder;
}

struct LotteryPoolStruct{       // Lotter info object structure
  uint poolId;
  uint price;
  uint timeDuration;
  uint poolLimit;
  LotteryTicketStruct[] lotteryList;
  LotteryStatus status;
}


struct WinnerStruct {      // Winner info object structure
  address winner;
  uint lotNumber;
  uint lotteryId;
  uint prize;
}