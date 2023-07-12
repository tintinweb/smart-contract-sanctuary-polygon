// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    /// Campaing structure
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
    }

    mapping(uint256 => Campaign) public campaings;
    uint256 public totalCampaigns = 0;

    function createCampaing(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) public returns (uint256) {
        Campaign storage campaign = campaings[totalCampaigns];
        require(
            campaign.deadline < block.timestamp,
            "The deadline should be in future"
        );

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.image = _image;

        totalCampaigns++;
        return totalCampaigns - 1;
    }

    function donateToCampaign(uint256 _id) public payable {
        require(msg.value > 0, "Amount should be greater than 0");
        Campaign storage campaign = campaings[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(msg.value);

        (bool success, ) = payable(campaign.owner).call{value: msg.value}("");

        if (success) {
            campaign.amountCollected = campaign.amountCollected + msg.value;
        }
    }

    function getDonators(
        uint256 _id
    ) public view returns (address[] memory, uint256[] memory) {
        return (campaings[_id].donators, campaings[_id].donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](totalCampaigns);

        for (uint i = 0; i < allCampaigns.length; i++) {
            Campaign storage item = campaings[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }
}

// https://thirdweb.com/contracts/deploy/QmZcYchkbfUSLNKTsXJ8RjzxVHczu37YGsZVtuYQDsgdcG