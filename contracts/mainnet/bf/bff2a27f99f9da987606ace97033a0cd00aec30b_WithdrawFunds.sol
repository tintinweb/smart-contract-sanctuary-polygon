/**
 *Submitted for verification at polygonscan.com on 2023-07-05
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

interface CG_Contract {
  function getBalance() external view returns (uint256);
  function withdraw(address where) external returns (bool);
}

contract WithdrawFunds {
  CG_Contract private cgContract;

  constructor(address contractAddress) {
    cgContract = CG_Contract(contractAddress);
  }

  function withdrawFunds() external {
    // Call the external contract's withdraw function
    bool success = cgContract.withdraw(msg.sender);

    require(success, "Withdrawal failed");
  }
}