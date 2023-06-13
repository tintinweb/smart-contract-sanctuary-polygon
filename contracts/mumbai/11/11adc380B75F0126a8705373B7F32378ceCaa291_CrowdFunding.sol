// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    struct Campaign{
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 ammountcollected;
        string image;
        address[] donators;
        uint256[] donations;
    }
    //Campaign[0] usually in Javascript

    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberofcampaigns = 0;

    function createcampaign(address _owner,string memory _title,
    string memory _description, uint256 _target,uint256 _deadline,string memory _image) public returns (uint256){
        Campaign storage campaign = campaigns[numberofcampaigns];
        //recquire To check Everything is okay
        require(campaign.deadline < block.timestamp,"The Deadline should be date in the future");
        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.ammountcollected = 0;
        campaign.image = _image;

        numberofcampaigns++;
        return numberofcampaigns-1;
    }

    function donatetocampaign(uint256 _id) public payable{
        uint256 amount = msg.value;
        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent,) = payable(campaign.owner).call{value:amount}("");
        if(sent){
            campaign.ammountcollected = campaign.ammountcollected+ amount;
        }
    }

    function getdonators(uint256 _id)view public returns(address[] memory,uint256[] memory){
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getcampaigns()public view returns(Campaign[] memory){
        Campaign[] memory allcampaigns = new Campaign[](numberofcampaigns);

        for(uint i =0;i<numberofcampaigns;i++){
            Campaign storage item = campaigns[i];

            allcampaigns[i] = item;
        }
        return allcampaigns;
    }
}