// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    struct Campaign {
        address payable owner;
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

    uint256 public numberofCampaigns;


    // this funtion will return the id of the campaign
    function createCampaign(address _owner, string calldata _title, string calldata _description, uint256 _target, uint256 _deadline, string calldata _image) public returns(uint256) {

        numberofCampaigns++;

        Campaign storage campaign = campaigns[numberofCampaigns];
        
        require(campaign.deadline <block.timestamp, "the deadline should be a date in the future");

        campaign.owner= payable(_owner);
        campaign.title = _title;
        campaign.description = _description;
        campaign.target=_target;
        campaign.deadline=_deadline;
        campaign.amountCollected=0;
        campaign.image=_image;

        return numberofCampaigns;
    }

    function donateToCampaign(uint256 _id) public payable{
        uint256 amount = msg.value;

        Campaign storage receivingCampaign = campaigns[_id];

        receivingCampaign.donators.push(msg.sender);
        receivingCampaign.donations.push(msg.value);

        (bool sent,) = payable(receivingCampaign.owner).call{value: amount}("");

        if(sent){
            receivingCampaign.amountCollected = receivingCampaign.amountCollected + amount;
        }
    }

    function getDonators(uint256 _id) view public returns(address[] memory _donators, uint256[] memory _donations){
        _donators = campaigns[_id].donators;
        _donations = campaigns[_id].donations;
    }

    function getCampaigns() public view returns(Campaign[]memory ) {
        Campaign[] memory allCampaigns = new Campaign[](numberofCampaigns);

        for(uint i=0; i< numberofCampaigns; i++){
            allCampaigns[i] = campaigns[i];
        }

        return allCampaigns;
    }
}