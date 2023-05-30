/**
 *Submitted for verification at polygonscan.com on 2023-05-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Charity {
    event CampaignStarted(bytes32 campaignId, address initiator);
    event WithdrawFunds(bytes32 campaignId, address initiator, uint256 amount);
    event FundsDonated(bytes32 campaignId, address donor, uint256 amount);
    event CampaignEnded(bytes32 campaignId, address initiator);
    event Refunded(bytes32 campaignId, address donor, uint256 amount);

    bool public paused;
    address public immutable owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can perform this action");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    function pause() external whenNotPaused onlyOwner{
        paused = true;
    }

    function unpause() external whenPaused onlyOwner{
        paused = false;
    }

    modifier onlyInitiator(bytes32 campaignId) {
        require(_campaigns[campaignId].initiator == msg.sender, "Not campaign initiator");
        _;
    }

    struct Campaign {
        string title;
        string imgUrl;
        string description;
        bool isLive; 
        address initiator;
        uint256 deadline;
        address donor;
        uint256 donatedAmount;
        bool hasWithdrawn;
    }

    mapping(bytes32 => Campaign) public _campaigns;
    mapping(address => mapping(bytes32 => uint256)) public userCampaignDonations;

    function generateCampaignId(string calldata title,string calldata description) public pure returns (bytes32) {
        require(bytes(title).length !=0 && bytes(description).length !=0, "Title and description are required");
        bytes32 campaignId = keccak256(abi.encodePacked(title, description));
        return campaignId;
    }
    
    function startCampaign(string calldata title, string calldata imgUrl, string calldata description, uint256 deadline) public whenNotPaused{
        require(bytes(title).length !=0 && bytes(description).length !=0, "Title and description are required");
        require(deadline > block.timestamp, "Deadline must be in the future");  
        bytes32 campaignId = generateCampaignId(title, description);
        require(block.timestamp < deadline, "Campaign ended");

        Campaign storage campaign = _campaigns[campaignId];
        require(keccak256(abi.encodePacked(campaign.title)) != keccak256(abi.encodePacked(title)), "Title must be unique");
        require(!campaign.isLive, "Campaign exists");

        campaign.title = title;
        campaign.imgUrl = imgUrl;
        campaign.description = description;
        campaign.isLive = true;
        campaign.initiator = msg.sender;
        campaign.deadline = deadline;

        emit CampaignStarted(campaignId, msg.sender);
    }

    function endCampaign(bytes32 campaignId) public whenNotPaused onlyInitiator(campaignId){
        require(campaignId != bytes32(0), "Invalid campaignId");

        Campaign storage campaign = _campaigns[campaignId];

        // require the campaign is alive
        require(campaign.isLive, "campaign is not active");

        campaign.isLive = false;
        campaign.deadline = block.timestamp;

        emit CampaignEnded(campaignId, msg.sender);
    }

      // allows users to donate to a charity campaign of their choice
    function donateToCampaign(bytes32 campaignId) public whenNotPaused payable {
        require(campaignId != bytes32(0), "Invalid campaignId");

        // get campaign details with the given campaign
        Campaign storage campaign = _campaigns[campaignId];

        // require the campaign has not ended
        require(block.timestamp < campaign.deadline, "Campaign has ended");

        // require that the donor is not the campaign initiator
        require(msg.sender != campaign.initiator, "Campaign initiator cannot donate to their own campaign");

        uint256 amountToDonate = msg.value;
        require(msg.value !=0 , "Wrong ETH value");

        // end the campaign automatically, if the deadline is exceeded
        if (block.timestamp > campaign.deadline) {
            campaign.isLive = false;
        }

        // increase the campaign balance by the amount donated;
        campaign.donatedAmount += amountToDonate;
        campaign.donor = msg.sender;

        // keep track of users donation history
        userCampaignDonations[msg.sender][campaignId] +=  amountToDonate;

        // emit FundsDonated event
        emit FundsDonated(campaignId, msg.sender, amountToDonate);
    }

    function refundDonation (bytes32 campaignId) public whenNotPaused {
        require(campaignId != bytes32(0), "Invalid campaignId");

        // Campaign storage campaign = _campaigns[campaignId];
        Campaign storage campaign = _campaigns[campaignId];
        
        // require that only the specific donor can call this function
        require(msg.sender == campaign.donor, "Only the donor can refund their donation");

        // require that the campaign is live
        require(campaign.isLive, "Campaign is not active");
        // require that the donor has donated to the campaign
        require(campaign.donatedAmount !=0 , "Donor has not donated to campaign");
        // check if the campaign is still live
        require(block.timestamp <= campaign.deadline, "Campaign is already closed");

        // get the amount to refund
        uint256 amountToRefund = userCampaignDonations[campaign.donor][campaignId];

        // subtract the amount from the campaign's balance
        campaign.donatedAmount -= amountToRefund;
        
        // subtract the amount from the donor's donation history
        userCampaignDonations[campaign.donor][campaignId] -= amountToRefund;

        // transfer the amount back to the donor
        (bool success, ) = payable(msg.sender).call{value: amountToRefund}("");
        require(success, "Refund failed");

        emit Refunded(campaignId, campaign.donor, amountToRefund);

    }

    function withdrawCampaignFunds(bytes32 campaignId) public whenNotPaused onlyInitiator(campaignId) payable{
        require(campaignId != bytes32(0), "Invalid campaignId");
        Campaign storage campaign = _campaigns[campaignId];
        require(!campaign.isLive, "Campaign is still active");
        require(block.timestamp > campaign.deadline,"Campaign is still active");
        require(!campaign.hasWithdrawn, "Funds have already been withdrawn");
        require(campaign.donatedAmount !=0 , "No funds to withdraw");

        (bool success, ) = payable(campaign.initiator).call{value: campaign.donatedAmount}("");
        require(success, "Send failed");

        campaign.hasWithdrawn = true;
        campaign.donatedAmount = 0;

        emit WithdrawFunds(campaignId, campaign.initiator, campaign.donatedAmount);
    }
    
    // returns the details of a campaign given the campaignId
    function getCampaigns(bytes32 campaignId) public whenNotPaused view returns (Campaign memory){
        return _campaigns[campaignId];
    }
    
    fallback() external payable {
        revert("Transaction rejected. Function does not exist.");   
    }

    receive() external payable {
        // handle incoming ether transfers
    }

}