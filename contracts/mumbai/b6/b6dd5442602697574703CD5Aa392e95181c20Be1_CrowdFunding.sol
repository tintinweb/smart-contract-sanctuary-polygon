// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
// what all does a campaign contains
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
    }
 

    mapping(uint256 => Campaign) public campaigns;
   // declaring global variable
    uint256 public numberOfCampaigns = 0;

    function createCampaign(address _owner, string memory _title,string memory _description,uint256 _target, uint256 _deadline , string memory _image) public returns(uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];

     // is everything okay?
        require(campaign.deadline < block.timestamp,"The deadlne should be a date in the future.");

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.target = _deadline;
        campaign.amountCollected = 0;
        campaign.image =_image;
        // add more fields as per requirement
           
           numberOfCampaigns++;

           return numberOfCampaigns - 1;
    }

    function donateToCampaign(uint256 _id)public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent,) = payable(campaign.owner).call{value: amount}("");

        if(sent){
            campaign.amountCollected = campaign.amountCollected+ amount;
        }
    }

    function getDonators(uint256 _id) view public returns(address[] memory,uint256[] memory ) {
        return(campaigns[_id].donators, campaigns[_id].donations);

    }
   // allCampaigns is a variable which will have all the camoaigns from the empty campaign[] array
    function getCampaigns() public view returns(Campaign[] memory){
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for(uint i=0; i< numberOfCampaigns; i++){
            Campaign storage item = campaigns[i];
            allCampaigns[i] = item;
        }

        return allCampaigns;
    }

}