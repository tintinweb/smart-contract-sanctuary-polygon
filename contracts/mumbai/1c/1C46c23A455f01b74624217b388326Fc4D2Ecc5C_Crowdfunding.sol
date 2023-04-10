// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Crowdfunding {
    struct Campaign {
        string name;
        string description;
        string image;
        uint256 targetAmount;
        uint256 fundingAmount;
        uint256 deadline;
        address payable owner;
        address[] funders;
        uint256[] donations;
        bool completed;
    }

    mapping(uint256 => Campaign) public campaigns;
    uint256 public campaignCount = 0;

    function createCampaign(
        address _owner,
        string memory _name,
        string memory _description,
        string memory _image,
        uint256 _targetAmount,
        uint256 _deadline
    ) public returns (uint256) {
        Campaign storage campaign = campaigns[campaignCount];

        require(
            campaign.deadline > block.timestamp,
            "Deadline must be in the future"
        );

        campaign.name = _name;
        campaign.description = _description;
        campaign.image = _image;
        campaign.targetAmount = _targetAmount;
        campaign.deadline = _deadline;
        campaign.owner = payable(_owner);
        campaign.completed = false;
        campaign.fundingAmount = 0;

        campaignCount++;

        return campaignCount - 1;
    }

    function donateToCampaign(uint256 _id) public payable {
        Campaign storage campaign = campaigns[_id];

        require(
            campaign.deadline > block.timestamp,
            "Deadline must be in the future"
        );
        require(campaign.completed == false, "Campaign must not be completed");

        campaign.funders.push(msg.sender);
        campaign.donations.push(msg.value);

        (bool sent, ) = payable(campaign.owner).call{value: msg.value}("");
        if (sent) {
            campaign.fundingAmount += msg.value;
        }
    }

    function getDonators(
        uint256 _id
    ) public view returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].funders, campaigns[_id].donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory _campaigns = new Campaign[](campaignCount);

        for (uint256 i = 0; i < campaignCount; i++) {
            _campaigns[i] = campaigns[i];
        }

        return _campaigns;
    }
}