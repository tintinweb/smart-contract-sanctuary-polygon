// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    struct Campaign {
        address owner;
        string title;
        string desription;
        uint target;
        uint deadline;
        uint amountCollected;
        string image;
        address[] donators;
        uint[] donations;
    }

    mapping(uint => Campaign) public campaigns;

    uint public numberofCampaigns = 0;

    function createCampaign(
        address _owner,
        string memory _tittle,
        string memory _descriptions,
        uint _target,
        uint _deadline,
        string memory _image
    ) public returns (uint) {
        Campaign storage campaign = campaigns[numberofCampaigns];
        // if everything is ok
        require(
            campaign.deadline < block.timestamp,
            "The deadline should be a day in the future."
        );

        campaign.owner = _owner;
        campaign.title = _tittle;
        campaign.desription = _descriptions;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.image = _image;

        numberofCampaigns++;

        return numberofCampaigns - 1;
    }

    function donateToCampagin(uint _id) public payable {
        uint amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent, ) = payable(campaign.owner).call{value: amount}("");

        if (sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }

    function getDonators(
        uint _id
    ) public view returns (address[] memory, uint[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberofCampaigns);

        for (uint i = 0; i < numberofCampaigns; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }
}