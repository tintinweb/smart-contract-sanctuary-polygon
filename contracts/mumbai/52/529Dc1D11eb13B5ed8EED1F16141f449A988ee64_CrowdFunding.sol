// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
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
        string[] names;
        string category;
        string email;
    }

    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberOfCampaigns = 0;

    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image,string memory _category,string memory _email) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];

        require(_deadline > block.timestamp, "The deadline should be a date in the future.");

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;
        campaign.category = _category;
        campaign.email = _email;


        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

function donateToCampaign(uint256 _id,string memory name) public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);
        campaign.names.push(name);
        
        // sort the donations array in descending order
        for (uint256 i = 0; i < campaign.donations.length; i++) {
            for (uint256 j = i+1; j < campaign.donations.length; j++) {
                if (campaign.donations[i] < campaign.donations[j]) {
                    uint256 tempValue = campaign.donations[i];
                    campaign.donations[i] = campaign.donations[j];
                    campaign.donations[j] = tempValue;
                    address tempAddr = campaign.donators[i];
                    campaign.donators[i] = campaign.donators[j];
                    campaign.donators[j] = tempAddr;
                    string memory tempName = campaign.names[i];
                    campaign.names[i] = campaign.names[j];
                    campaign.names[j] = tempName;
                }
            }
        }

        (bool sent,) = payable(campaign.owner).call{value: amount}("");

        if(sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }

        if (campaign.amountCollected >= campaign.target) {
            deleteCampaign(_id);
        }
}


    function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory, string[] memory) {
    return (campaigns[_id].donators, campaigns[_id].donations, campaigns[_id].names);
    }


    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for(uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }

    function deleteCampaign(uint256 _id) internal {
        require(_id < numberOfCampaigns, "Campaign does not exist");


        for (uint256 i = _id; i < numberOfCampaigns - 1; i++) {
            campaigns[i] = campaigns[i+1];
        }

        delete campaigns[numberOfCampaigns - 1];

        numberOfCampaigns--;
    }
    function checkAndDeleteExpiredCampaigns() public {
    for (uint256 i = 0; i < numberOfCampaigns; i++) {
        Campaign storage campaign = campaigns[i];

        if (campaign.deadline <= block.timestamp) {
            deleteCampaign(i);
        }
    }
}

}