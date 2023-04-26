// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract EaseFunds {
    struct Campaign{
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadln;
        uint256 amtCollected;
        string image;
        address[] donators;
        uint256[] donations;
    }

    mapping(uint256 => Campaign) public campaigns;

    uint256 public noofCampaigns = 0;

    function creacteCamp(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadln,
        uint256 _amtCollected,
        string memory _image
    ) public returns(uint256) {
        Campaign storage campaign = campaigns[noofCampaigns];

        require(campaign.deadln < block.timestamp , "The deadline should be a date in future.");

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadln = _deadln;
        campaign.amtCollected = 0;
        campaign.image = _image;
    }

    function donateToCamp(
        uint256 _id
    ) public payable {
        uint256 amt= msg.value;

        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amt);

        (bool sent,) = payable(campaign.owner).call{value: amt}("");

        if(sent){
            campaign.amtCollected = campaign.amtCollected + amt;
        }
    }

    function getDonators(
        uint256 _id
    ) view public returns(address[] memory , uint256[] memory){
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCamp() public view returns(Campaign[] memory){
        Campaign[] memory allCampaigns = new Campaign[](noofCampaigns);

        for(uint i = 0; i< noofCampaigns; i++){
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }
        return allCampaigns;
    }

}