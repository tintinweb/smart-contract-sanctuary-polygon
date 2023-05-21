// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    struct Donation {
        address donator;
        uint256 amount;
    }

    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        Donation[] donations;
    }

    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberOfCampaigns = 0;

    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) public returns (uint256) {
        require(_deadline > block.timestamp, "The deadline should be a date in the future.");

        Campaign storage campaign = campaigns[numberOfCampaigns];

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

    function donateToCampaign(uint256 _id) public payable {
        require(_id < numberOfCampaigns, "Invalid campaign ID.");

        Campaign storage campaign = campaigns[_id];

        require(campaign.deadline > block.timestamp, "The campaign has ended.");

        uint256 amount = msg.value;

        campaign.donations.push(Donation(msg.sender, amount));

        campaign.amountCollected += amount;

        payable(campaign.owner).transfer(amount);
    }

    function getDonators(uint256 _id) public view returns (address[] memory, uint256[] memory) {
        require(_id < numberOfCampaigns, "Invalid campaign ID.");

        Campaign storage campaign = campaigns[_id];

        address[] memory donators = new address[](campaign.donations.length);
        uint256[] memory donationAmounts = new uint256[](campaign.donations.length);

        for (uint256 i = 0; i < campaign.donations.length; i++) {
            donators[i] = campaign.donations[i].donator;
            donationAmounts[i] = campaign.donations[i].amount;
        }

        return (donators, donationAmounts);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            allCampaigns[i] = campaigns[i];
        }

        return allCampaigns;
    }
}