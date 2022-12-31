/**
 *Submitted for verification at polygonscan.com on 2022-12-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// TODO work out how to ensure recipients, vendors and verifiers cannot be in eachothers list - some require function...  tbc. require(user =! recipientList[]);
// TODO create the TOKEN and ensure this contract only uses this specific token - quite tired so not sure if this is essential or completely missing the point.

contract AlteriToken {
  // Mapping from user addresses to their balances
  mapping(address => uint256) public balances;

  // Mapping from user addresses to their roles
  mapping(address => bool) public verifierList;
  mapping(address => bool) public recipientList;
  mapping(address => bool) public vendorList;

  // Address of the contract owner
  address public owner;

  // Address to which vendors can send tokens
  address public treasurerAddress;

  // Constructor to set the contract owner
  constructor() {
    owner = msg.sender;
  }

  // Function to add a user to the verifierList
  function addVerifier(address user) public {
    // Only the contract owner can add users to the verifierList
    require(msg.sender == owner, "Only the owner can add verifiers");

    // Add the user to the verifierList
    verifierList[user] = true;
  }

  // Function to remove a user from the verifierList
  function removeVerifier(address user) public {
    // Only the contract owner can remove users from the verifierList
    require(msg.sender == owner, "Only the owner can remove verifiers");

    // Remove the user from the verifierList
    verifierList[user] = false;
  }

  // Function to add a user to the recipientList
  function addRecipient(address user) public {
    // Only users in the verifierList can add users to the recipientList
    require(verifierList[msg.sender], "Only verifiers can add recipients");

    // Add the user to the recipientList
    recipientList[user] = true;
  }

  // Function to remove a user from the recipientList
  function removeRecipient(address user) public {
    // Only users in the verifierList can remove users from the recipientList
    require(verifierList[msg.sender], "Only verifiers can remove recipients");

    // Remove the user from the recipientList
    recipientList[user] = false;
  }

  // Function to transfer tokens to a user in the vendorList
  function transfer(address recipient, uint256 amount) public {
    // Only users in the recipientList can transfer tokens to users in the vendorList
    require(recipientList[msg.sender], "Only recipients can transfer tokens");

    // Ensure the recipient is in the vendorList
    require(vendorList[recipient], "Recipient must be in the vendorList");

    // Ensure the sender has sufficient funds
    require(
      balances[msg.sender] >= amount,
      "Sender does not have sufficient funds"
    );

    // Transfer the tokens
    balances[msg.sender] -= amount;
    balances[recipient] += amount;
  }
}

// Function to allow a user in the vendorList to send