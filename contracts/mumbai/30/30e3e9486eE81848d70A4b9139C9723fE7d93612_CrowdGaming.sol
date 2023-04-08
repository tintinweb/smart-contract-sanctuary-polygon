// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract CrowdGaming {

  // Events
      event Launch(uint id, address indexed owner, string title, uint goal, string description, uint256 startAt, uint256 endAt);
      event Cancel(uint id);
      event Pledge(uint indexed id, address indexed pledger, uint amount);
      event Withdraw(uint id);
      event Refund(uint indexed id, address indexed pledger, uint amount);
      event Highlight(uint id);

  // Struct for Campaign
    struct Campaign {
      uint id;
      address owner;
      string title;
      string description;
      uint pledged;
      uint goal;
      uint256 startAt;
      uint256 endAt;
      bool claimed;
      bool cancelled;
      bool highlighted;
    }

  // State variables
    uint public totalCampaigns;
    mapping (uint => Campaign) public campaigns; // track all campaign ids
    mapping (uint => mapping(address => uint)) public pledgedAmount; // track address amount pledged to a campaign
    mapping(address => uint[]) public ownerCampaigns; // track campaigns owned by address
    mapping(address => uint[]) public donorCampaigns; // track campaigns donated to by an address
    address public contractOwner; // SB Labs LLC
    mapping(uint => uint) public donationFunds; // track funds received through donate function
    mapping (uint => bool) public highlightedCampaigns; // track campaign ids that are highlighted


    constructor(address _contractOwner) {
      contractOwner = _contractOwner; // set the deployer as the contract owner
    }


  // Function to launch a campaign - public return the campaign ID
    function launchCampaign(string calldata _title, string calldata _description, uint _goal, uint256 _startAt, uint256 _endAt) external {
    // Require campaign length to be a future date
    require(_startAt >= block.timestamp, "Invalid start date");
    require(_endAt >= _startAt, "Invalid end date");
    require(_endAt <= block.timestamp + 30 days, "Cannot go past 30 days");
    require(_goal > 0, "Goal must be greater than 0");
    // Add to totalCampaign variable
    totalCampaigns++;
    // Set new variables for campaign
    campaigns[totalCampaigns] = Campaign({
      id: totalCampaigns, // id for easy track
      owner: msg.sender,
      title: _title,
      goal: _goal,
      pledged: 0,
      description: _description,
      startAt: _startAt,
      endAt: _endAt,
      claimed: false,
      cancelled: false,
      highlighted: false
    });
    // Add campaign to the ownerCampaigns array
    ownerCampaigns[msg.sender].push(totalCampaigns);
    // Emit Launch
    emit Launch(totalCampaigns, msg.sender, _title, _goal, _description, _startAt, _endAt);
    
    }
  // Function to cancel a campaign
    function cancelCampaign(uint _id) external {
      Campaign memory campaign = campaigns[_id];
      require(msg.sender == campaign.owner, "Not owner");
      require(block.timestamp < campaign.startAt, "Has started");
      // Delete campaign
      delete campaigns[_id];
      campaigns[_id].cancelled = true;
      // Emit Cancel
      emit Cancel(_id);
    }


  // Function to pledge to a campaign 
    function pledgeTo(uint _id) external payable {
    Campaign storage campaign = campaigns[_id];
    require(block.timestamp >= campaign.startAt, "Hasn't started");
    require(block.timestamp <= campaign.endAt, "Has ended");
    // Prevent reentry
    campaign.pledged += msg.value;
    pledgedAmount[_id][msg.sender] += msg.value;
    // Add campaign ID to donorCampaigns mapping for this address
    donorCampaigns[msg.sender].push(_id);
    // Emit Pledge
    emit Pledge(_id, msg.sender, msg.value);
    }


  // Function to widthraw funds from a campaign 
    function withdrawFrom(uint _id) external payable {
      Campaign storage campaign = campaigns[_id];
      require(msg.sender == campaign.owner, "Not owner");
      require(block.timestamp > campaign.endAt, "Hasn't ended");
      require(campaign.pledged >= campaign.goal, "Didn't meet goal");
      require(!campaign.claimed, "Already claimed");
      campaign.claimed = true;
      // Prevent reentry
      uint amount = campaign.pledged;
      campaign.pledged = 0;
      // Send funds to owner and check for success
      (bool success, ) = campaign.owner.call{value: amount}("");
      require(success, "Failed to send Ether");
      // Emit Withdraw
      emit Withdraw(_id);
    }


  // Function to refund funds if the campaign isn't met 
    function refund(uint _id) external payable {
      address donor = msg.sender;
      Campaign storage campaign = campaigns[_id];
      require(block.timestamp > campaign.endAt, "Hasn't ended");
      require(campaign.pledged < campaign.goal, "Total less than goal");
      require(campaign.owner != address(0), "Campaign does not exist");
      // Prevet reentry
      uint balance = pledgedAmount[_id][msg.sender];
      pledgedAmount[_id][msg.sender] = 0;
      // Send ether back to donor and check for success
      (bool success, ) = donor.call{value: balance}("");
      require(success, "Failed to send ether");
      // Emit Refund
      emit Refund(_id, msg.sender, balance);
    }

    // Get campaigns for a specific owner
    function getOwnerCampaigns(address _owner) external view returns (uint[] memory) {
      return ownerCampaigns[_owner];
    }
    // Get donations for a specific address
    function getDonorDonoations (address _owner) external view returns (uint[] memory) {
      return donorCampaigns[_owner];
    }

    // Function to withdraw the funds received through donate function ONLY
    // This does not allow SB Labs access to all funds from all campaigns
    function withdrawDonationFunds(uint _id) external {
      require(msg.sender == contractOwner, "Only SB Labs LLC allowed");
      uint balance = donationFunds[_id];
      require(balance > 0, "No funds available to withdraw");
      donationFunds[_id] = 0; // reset the balance
      (bool success, ) = msg.sender.call{value: balance}("");
      require(success, "Failed to withdraw funds");
    }

  // Function to accept donations and highlight campaign
    function donate(uint _id) external payable {
      Campaign storage campaign = campaigns[_id];
      require(!campaign.cancelled, "Campaign has been cancelled");
      require(block.timestamp >= campaign.startAt, "Campaign hasn't started yet");
      require(block.timestamp <= campaign.endAt, "Campaign has already ended");
      require(msg.value == 10 ether, "10 MATIC required.");
      // Set highlighted to true
      campaign.highlighted = true;
      highlightedCampaigns[_id] = true;
      emit Highlight(_id);
      donationFunds[_id] += msg.value; // track the funds received through donate function
    }
 }