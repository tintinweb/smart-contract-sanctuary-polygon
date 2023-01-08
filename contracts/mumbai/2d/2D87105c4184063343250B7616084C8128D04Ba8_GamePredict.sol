/**
 *Submitted for verification at polygonscan.com on 2023-01-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

contract GamePredict {
  mapping (address => uint) private balances;

  address public owner;

  event LogDepositMade(address accountAddress, uint amount);

  constructor() public {
    // msg provides details about the message that's sent to the contract
    // msg.sender is contract caller (address of contract creator)
    owner = msg.sender;
  }

  function deposit() public payable returns (uint) {
    // Use 'require' to test user inputs, 'assert' for internal invariants
    // Here we are making sure that there isn't an overflow issue
    require((balances[msg.sender] + msg.value) >= balances[msg.sender]);

    balances[msg.sender] += msg.value;
    // no "this." or "self." required with state variable
    // all values set to data type's initial value by default

    emit LogDepositMade(msg.sender, msg.value); // fire event

    return balances[msg.sender];
  }

  function withdraw(uint withdrawAmount) public returns (uint remainingBal) {
    require(withdrawAmount <= balances[msg.sender]);

    // Note the way we deduct the balance right away, before sending
    // Every .transfer/.send from this contract can call an external function
    // This may allow the caller to request an amount greater
    // than their balance using a recursive call
    // Aim to commit state before calling external functions, including .transfer/.send
    balances[msg.sender] -= withdrawAmount;

    payable(msg.sender).transfer(withdrawAmount);

    return balances[msg.sender];
}

/// @notice Get balance
/// @return The balance of the user
// 'view' (ex: constant) prevents function from editing state variables;
// allows function to run locally/off blockchain
function balance() view public returns (uint) {
    return balances[msg.sender];
}

}