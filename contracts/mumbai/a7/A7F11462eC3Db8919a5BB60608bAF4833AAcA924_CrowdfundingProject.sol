// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.17;

// contract to record all crowndfunding projects
contract CrowdFactory {
  address[] public publishedProjs;

  event ProjectCreated(
    string projTitle,
    uint256 goalAmount,
    address indexed ownerWallet,
    address projAddress,
    uint256 indexed timestamp
  );

  function totalPublishedProjs() public view returns (uint256) {
    return publishedProjs.length;
  }

  function createProject(
    string memory projectTitle,
    uint256 projgoalAmount,
    string memory projDescript,
    address ownerWallet
  ) public {
    // initialising CrowdFundingProject contract
    CrowdfundingProject newProj = new CrowdfundingProject(
      // passing arguments from constructor function
      projectTitle,
      projgoalAmount,
      projDescript,
      ownerWallet
    );

    // pushing project address
    publishedProjs.push(address(newProj));

    // calling ProjectCreated (event above)
    emit ProjectCreated(
      projectTitle, 
      projgoalAmount, 
      msg.sender, 
      address(newProj), 
      block.timestamp
    );
  }
}

contract CrowdfundingProject {
  // defining state variables
  string public projTitle;
  string public projDescription;
  uint256 public goalAmount;
  uint256 public raisedAmount;
  address ownerWallet; // address where amount is to be transferred

  event Funded(
    address indexed donar,
    uint256 indexed amount,
    uint256 indexed timestamp
  );

  constructor(
    string memory projectTitle,
    uint256 projgoalAmount,
    string memory projDescript,
    address ownerWallet_
  ) {
    // mapping values
    projTitle = projectTitle;
    goalAmount = projgoalAmount;
    projDescription = projDescript;
    ownerWallet = ownerWallet_;
  }

  // donation function
  function makeDonation() public payable {
    // if goal amount is acheived, close the proj
    require(goalAmount > raisedAmount, "GOAL ACHIEVED");

    // record walletaddress of donor
    (bool success, ) = payable(ownerWallet).call{value: msg.value}("");
    require(success, "VALUE NOT TRANFERRED");

    // calculate total amount raised
    raisedAmount += msg.value;

    emit Funded(msg.sender, msg.value, block.timestamp);
  }
}