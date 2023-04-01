/**
 *Submitted for verification at polygonscan.com on 2023-03-31
*/

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

// import "@openzeppelin/contracts/access/Ownable.sol"; 
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract YourContract {

  event SetContractPurpose(address sender, string purpose);
  event SetUserPurpose(address sender, string purpose);

  string public contractPurpose = "Building Unstoppable Apps!!!";
  mapping (address=>string) public userPurpose; 

  constructor() payable {
      emit SetContractPurpose(msg.sender, contractPurpose);
  }
  
function setMyPurpose(string memory newUserPurpose) public {
    userPurpose[msg.sender] = newUserPurpose;
    emit SetUserPurpose(msg.sender, newUserPurpose);
}

  function setPurpose(string memory newPurpose) public payable {
      contractPurpose = newPurpose;
      emit SetContractPurpose(msg.sender, newPurpose);
  }

  // to support receiving ETH by default
  receive() external payable {}
  fallback() external payable {}
}