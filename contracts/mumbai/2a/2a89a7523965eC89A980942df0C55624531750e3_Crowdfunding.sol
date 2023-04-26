// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Crowdfunding {
    struct Campaign {
        address payable owner;
        string title;
        string description;
        uint targetAmount;
        uint deadline;
        uint amountCollected;
        address[] donators;
        mapping(address => uint) donations;
    }

    Campaign[] public campaigns;

    event CampaignCreated(uint indexed campaignId, address indexed creator);
    event DonationReceived(uint indexed campaignId, address indexed donator, uint amount);

    function createCampaign(
        string memory _title,
        string memory _description,
        uint _targetAmount,
        uint _durationInDays
    ) public {
        uint campaignId = campaigns.length;
        campaigns.push();
        Campaign storage newCampaign = campaigns[campaignId];

        newCampaign.owner = payable(msg.sender);
        newCampaign.title = _title;
        newCampaign.description = _description;
        newCampaign.targetAmount = _targetAmount;
        newCampaign.deadline = block.timestamp + (_durationInDays * 1 days);

        emit CampaignCreated(campaignId, msg.sender);
    }

    function donate(uint _campaignId) public payable {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp < campaign.deadline, "The crowdfunding campaign has ended.");
        require(msg.value > 0, "Donation amount should be greater than 0.");

        campaign.amountCollected += msg.value;
        campaign.donations[msg.sender] += msg.value;

        if (campaign.donations[msg.sender] == msg.value) {
            campaign.donators.push(msg.sender);
        }

        emit DonationReceived(_campaignId, msg.sender, msg.value);
    }

    function getDonators(uint _campaignId) public view returns (address[] memory) {
        return campaigns[_campaignId].donators;
    }

    function getDonation(uint _campaignId, address _donator) public view returns (uint) {
        return campaigns[_campaignId].donations[_donator];
    }
}