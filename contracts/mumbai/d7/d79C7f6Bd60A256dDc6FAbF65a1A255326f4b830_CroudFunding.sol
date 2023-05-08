// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CroudFunding {
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

    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberOfCampaigns = 0;

    function createCampaign( address _owner, string memory _title, string memory _description, uint256 _target, uint _deadline, string memory _image) public returns (uint256){
        Campaign storage campaign = campaigns[numberOfCampaigns];
        campaign.owner= _owner;
        campaign.title = _title;
        campaign.description= _description;
        campaign.target= _target;
        campaign.deadline= _deadline;
        campaign.amountCollected= 0;
        campaign.image= _image;

        numberOfCampaigns++;
        return numberOfCampaigns-1;
    }

    function donateToCampaign(uint256 _id) public payable
    {
         uint256 ammount = msg.value;
         Campaign storage campaign= campaigns[_id];
         campaign.donators.push(msg.sender);
         campaign.donations.push(ammount);
         (bool sent,)= payable(campaign.owner).call{value:ammount}("");

         if(sent)
         {
            campaign.amountCollected=campaign.amountCollected+ammount;
         }
    }

    function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory)
    {
        return (campaigns[_id].donators,campaigns[_id].donations);
    }

    function getCampaigns() public view returns(Campaign[] memory)
    {
        Campaign[] memory allCampaigns= new Campaign[](numberOfCampaigns);

        for(uint i=0;i<numberOfCampaigns;i++)
        {
            Campaign storage item = campaigns[i];
            allCampaigns[i]= item;
        }

        return allCampaigns;
    }
}