//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


//Deployed to:  0x7C559DC1a23909D297eaf828dd1Ac70feb53F807

contract BuyMeCoffee {
  address private owner; // Contract owner
  uint256 private totalDonation; // Total amount Donated

  // Mapping from Address to Donors to the amount donated
  mapping(address => uint256) private donors;

  // Donation event definition
  event Donation(address indexed sender, uint256 amount, string message);

  constructor() {
    // Set the owner to the contract deployer
    owner = msg.sender;
  }

  // Revert any external transfer
  fallback() external payable {
    revert();
  }

  // Revert any external transfer
  receive() external payable {
    revert();
  }

  // Only Owner Modifier
  modifier _OnlyOwner() {
    require(msg.sender == owner);
    _;
  }

  // Get Balance of a specific User with Address
  function getTotalDonation() public view returns (uint256) {
    // Return the total amount donated so far
    return totalDonation;
  }

  // Donation Function Call
  function donate(string memory _note) public payable {
    // Check for doantion not to be less than 1 MATIC
    require(msg.value >= 1 ether, "Kindly donate at 1 MATIC");

    // Add amount donated to total donation
    totalDonation += msg.value;

    // Transfer donated amount to the contract deployer
    payable(owner).transfer(msg.value);

    // Emit a donation event
    emit Donation(msg.sender, msg.value, _note);
  }
}