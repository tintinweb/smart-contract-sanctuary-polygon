// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {

    enum CampaignStatus { Proposed, Open, Closed }
    enum CampaignStage { Engage, Public, Review, Funded, Active, Reconcile, Complete }

    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
        CampaignStatus status;
        CampaignStage stage;
    }

    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberOfCampaigns = 0;

    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];

        require(_deadline > block.timestamp, "The deadline should be a date in the future.");

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;
        campaign.status = CampaignStatus.Proposed;
        campaign.stage = CampaignStage.Engage;

        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

    address[] private allowedWallets;

    function setAllowedWallets(address[] memory _wallets) public {
        allowedWallets = _wallets;
    }

    function isAllowedWallet(address _wallet) private view returns (bool) {
        for (uint i = 0; i < allowedWallets.length; i++) {
            if (allowedWallets[i] == _wallet) {
                return true;
            }
        }
        return false;
    }

    function setCampaignStatus(uint256 _id, CampaignStatus _status) public {
        Campaign storage campaign = campaigns[_id];
        require(isAllowedWallet(msg.sender), "Caller is not allowed to perform this action.");
        require(campaign.owner == msg.sender, "Only the owner of the campaign can modify its status.");

        if(block.timestamp > campaign.deadline) {
            campaign.status = CampaignStatus.Closed;
        } else {
            campaign.status = _status;
        }
    }

    function setCampaignStage(uint256 _id, CampaignStage _stage) public {
        Campaign storage campaign = campaigns[_id];
        require(isAllowedWallet(msg.sender), "Caller is not allowed to perform this action.");
        require(campaign.owner == msg.sender, "Only the owner of the campaign can modify its stage.");

        campaign.stage = _stage;
    }

    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        require(campaign.status == CampaignStatus.Open && campaign.stage == CampaignStage.Public, "Donations are not allowed at this time.");

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent,) = payable(campaign.owner).call{value: amount}("");

        if(sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }

    function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for(uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }
}