// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract EosiFinance {
    struct Campaign {
        address owner;
        string traderName;
        string minProfit;
        uint256 minCapital;
        uint256 commission;
        uint256 amountCollected;
        string image;
        address[] investors;
        uint256[] investments;
    }

    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberOfCampaigns = 0;

    function createCampaign(address _owner, string memory _traderName, string memory _minProfit, uint256 _minCapital, uint256 _commission, string memory _image) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];

        // require(campaign.commission < block.timestamp, "The commission should be a date in the future.");

        campaign.owner = _owner;
        campaign.traderName = _traderName;
        campaign.minProfit = _minProfit;
        campaign.minCapital = _minCapital;
        campaign.commission = _commission;
        campaign.amountCollected = 0;
        campaign.image = _image;

        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        campaign.investors.push(msg.sender);
        campaign.investments.push(amount);

        (bool sent,) = payable(campaign.owner).call{value: amount}("");

        if(sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }

    function getInvestors(uint256 _id) view public returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].investors, campaigns[_id].investments);
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