// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Fundraising {
    struct Campaign{
        address owner;
        string title;
        string description;
        uint256 target; //target amount to achieve
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donors; // same as account number
        uint256[] donations; // amount from each account
    }

    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberOfCampaigns = 0;
    
    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, uint256 _amountCollected, string memory _image) public returns(uint256){
        Campaign storage campaign = campaigns[numberOfCampaigns];

        // is everything okay?
        require(campaign.deadline < block.timestamp, "Note: The Deadline should be a date in future");

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = _amountCollected;
        campaign.image = _image;

        numberOfCampaigns++;
        return numberOfCampaigns - 1;
    }

    function donateToCampaign(uint256 _id) public payable{
        uint256 amount = msg.value; //we are going to sent from our frontend

        Campaign storage campaign = campaigns[_id];

        campaign.donors.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent, ) = payable(campaign.owner).call{ value : amount}("");

        if(sent){
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    
    }

    // To get the list of all donors of the campaign
    function getDonors(uint256 _id) view public returns (address[] memory, uint256[] memory) {
        return(campaigns[_id].donors, campaigns[_id].donations);
    }

    function getCampaigns() view public returns(Campaign[] memory){
        // Creating Empty array of Campaign of size as many campaigns present (number of campaigns)
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for(uint i=0; i<numberOfCampaigns; i++){
            Campaign storage item = campaigns[i];
            
            allCampaigns[i] = item;
        }

        return allCampaigns;
    }

}