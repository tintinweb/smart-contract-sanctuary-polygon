/**
 *Submitted for verification at polygonscan.com on 2023-07-05
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

interface CG_Contract {
  function getBalance() external view returns (uint256);
  function withdraw() external;
}

contract WithdrawFunds {
  CG_Contract private cgContract;

  constructor(address contractAddress) {
    cgContract = CG_Contract(contractAddress);
  }

  function withdrawFunds() external {
    cgContract.withdraw();
  }

  // Fallback function to receive MATIC sent from the CG_Contract contract
  receive() external payable {}
}