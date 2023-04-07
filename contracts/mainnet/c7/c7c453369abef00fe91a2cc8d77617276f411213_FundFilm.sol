/**
 *Submitted for verification at polygonscan.com on 2023-04-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.18;

contract FundFilm {
    address payable public platformOwner;
    uint256 public numberOfCampaigns = 0;
    uint256 public CAMPAIGNS_VALUE_LOCKED;
    uint256 public constant WITHDRAWAL_FEE = 10;
    uint256 public constant SERVICE_FEE = 2;

    constructor() {
        platformOwner = payable(msg.sender);
    }

    struct Campaign {
        address owner;
        uint256 campaignId;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        string video;
        address[] donators;
        uint256[] donations;
        bool hasWithdrawn;
    }

    mapping(uint256 => Campaign) public campaigns;

    event CampaignStarted(
    address owner, uint256 campaignId, 
    string _title, string _description, 
    uint256 _target, uint256 _deadline, 
    string _image, string _video);
    function startCampaign(
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image,
        string memory _video
    ) public returns (uint256) {
        require(_deadline > block.timestamp,"Deadline should be in the future");
        Campaign storage newCampaign = campaigns[numberOfCampaigns];
        newCampaign.owner = msg.sender;
        newCampaign.campaignId = numberOfCampaigns;
        newCampaign.title = _title;
        newCampaign.description = _description;
        newCampaign.target = _target;
        newCampaign.deadline = _deadline;
        if (bytes(_image).length > 0) newCampaign.image = _image ;
        
        if (bytes(_video).length > 0) newCampaign.video = _video;

        numberOfCampaigns++;
        emit CampaignStarted(msg.sender, newCampaign.campaignId, _title, _description, _target, _deadline, _image, _video);
        return newCampaign.campaignId;
    }

    event CampaignEdited(string _title, string _description, uint256 _target, string _image, string _video);
    function editCampaign(
        uint256 _id,
        string memory _title,
        string memory _description,
        uint256 _target,
        string memory _image,
        string memory _video
    ) public {
        Campaign storage campaign = campaigns[_id];
        require(msg.sender == campaign.owner,"Only campaign owners can edit their campaigns!");
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.image = _image;
        campaign.video = _video;
        emit CampaignEdited(_title, _description, _target, _image, _video);
    }
    
    modifier campaignHasNotEnded(uint256 _campaignId) {
        require(
            campaigns[_campaignId].hasWithdrawn == false
            && campaigns[_campaignId].deadline > block.timestamp
            , "Campaign has already finished");
        _;
    }
    event CampaignDeadlineExtended(uint256 _id, uint256 _newDeadline, uint256 feePaid);
    function extendDeadline(uint256 _id, uint256 _newDeadline) campaignHasNotEnded(_id)  public payable {
        // extending a deadline should cost 2% of the target
        Campaign storage campaign = campaigns[_id];
        require(msg.sender == campaign.owner,"Only campaign owners can extend the deadline of their campaigns!");
        require(_newDeadline > campaign.deadline,"New deadline should be later than the current one");
        // transfer 2% of target to contract address
        uint256 fee = (campaign.target * SERVICE_FEE) / 100;
        require(msg.value == fee, "Service fee not provided or insufficient (should equal to 2% of the campaign's target");
        campaign.deadline = _newDeadline;
        emit CampaignDeadlineExtended(_id, _newDeadline, fee);
    }

    event DonatedToCampaign(address donator, uint256 _campaignId, uint256 _amount);
    function donateToCampaign(uint256 _id) public payable {
        Campaign storage campaign = campaigns[_id];
        require(campaign.hasWithdrawn == false,"The owner of this campaign has already withdrawn from it. No further donations allowed.");
        campaign.donators.push(msg.sender);
        campaign.donations.push(msg.value);

        campaign.amountCollected += msg.value;
        CAMPAIGNS_VALUE_LOCKED += msg.value;
        emit DonatedToCampaign(msg.sender, _id, msg.value);
    }
    function getDonators(uint256 _id) view public returns(address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    modifier onlyCampaignOwner(uint256 _campaignId) {
        require(msg.sender == campaigns[_campaignId].owner,"Only campaign owners can call this function!");
        _;
    }
    modifier campaignHasEnded(uint256 _campaignId) {
        // a campaign is considered as 'finished' if one of the conditions is true:
        require(
        campaigns[_campaignId].deadline <= block.timestamp
        || 
        campaigns[_campaignId].amountCollected >= campaigns[_campaignId].target 
        ,"Campaign hasn't ended yet");
        _;
    }
    event WithdrewFromCampaign(uint256 _campaignId, address _owner,uint256 _amountWithdrawn);
    function withdrawFromCampaign(uint256 _campaignId) onlyCampaignOwner(_campaignId) campaignHasEnded(_campaignId) public {
        Campaign storage campaign = campaigns[_campaignId];
        require(campaign.hasWithdrawn == false, "You can only withdraw once!");
        uint256 sumAfterFee = campaign.amountCollected - ((campaign.amountCollected * WITHDRAWAL_FEE) / 100);
        payable(campaign.owner).transfer(sumAfterFee);

        campaign.hasWithdrawn = true;
        CAMPAIGNS_VALUE_LOCKED -= campaign.amountCollected;
        emit WithdrewFromCampaign(_campaignId, campaign.owner, sumAfterFee);
    }

    modifier onlyPlatformOwner() {
        require(msg.sender == platformOwner);
        _;
    }
    function withdrawServiceFees() onlyPlatformOwner public {
        // withdraw all the contract balance excluding the campaigns' locked funds
        uint256 amountToWithdraw = address(this).balance - ((CAMPAIGNS_VALUE_LOCKED * (100 - WITHDRAWAL_FEE)) / 100);
        (bool sent, ) = platformOwner.call{value: amountToWithdraw}("");
        require(sent, "Failed to withdraw");
    }
}