// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    struct Campaign {
        address owner; //address of the owner of the campaign
        string title; //title of the campaign
        string description; //description of the campaign
        uint256 target; //target amount of the campaign
        uint256 deadline; //deadline of the campaign
        uint256 amountCollected; //amount collected so far
        string image; //URL of the image
        address[] donators; //array of addresses of donators
        uint256[] donations; //array of donations
    }

    mapping (uint256 => Campaign) public campaigns; //mapping of campaign id to campaign

    uint256 public numberOfCampaigns = 0; //number of campaigns
    
    // function to create a campaign
    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns]; // create a new campaign

        require(campaign.deadline < block.timestamp, "The deadline should be a date in the future"); // check if the deadline is in the future

        campaign.owner = _owner; // set the owner of the campaign
        campaign.title = _title; // set the title of the campaign
        campaign.description = _description; // set the description of the campaign
        campaign.target = _target; // set the target of the campaign
        campaign.deadline = _deadline; // set the deadline of the campaign
        campaign.amountCollected = 0; // set the amount collected to 0
        campaign.image = _image; // set the image of the campaign

        numberOfCampaigns++; // increment the number of campaigns

        return numberOfCampaigns - 1; // return the id of the campaign
    }

    // function to donate to a campaign
    function donateToCampaign(uint256 _id) public payable  {
        uint256 amount = msg.value; // get the amount of the donation

        Campaign storage campaign = campaigns[_id]; // get the campaign

        campaign.donators.push(msg.sender); // add the donator to the array of donators
        campaign.donations.push(amount); // add the donation to the array of donations

        // (bool sent, ) sent returns true if the transaction was successful, false otherwise
        (bool sent, ) = payable(campaign.owner).call{value: amount}(""); // send the donation to the owner of the campaign
        
        if(sent) {
            campaign.amountCollected += amount; // if sent is true, increment the amount collected, otherwise, refund the donator
        }
    }

    // function to get the donators and the donations of a campaign
    function getDonators(uint256 _id) public view returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations); // return the array of donators and the array of donations
    }

    // function to get all the campaigns
    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns); // create a new array of campaigns

        for(uint256 i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i]; // get the campaign

            allCampaigns[i] = item; // add the campaign to the array of campaigns
        }

        return allCampaigns; // return the array of campaigns
    }
}