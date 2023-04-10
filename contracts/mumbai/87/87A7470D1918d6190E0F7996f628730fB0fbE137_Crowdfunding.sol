// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Crowdfunding {
    address immutable owner;

    constructor(){
        owner = msg.sender;
    }

    struct CrowdCampaign {
        address payable receiver;
        uint goal;
        uint number;
        uint totalAmount;
    }

    struct Participating {
        address  account;
        uint amount;
    }

    uint public numOfCampaign;
    mapping(uint => CrowdCampaign)  campaigns;
    mapping(uint => Participating[])  users;

    mapping(uint => mapping(address => bool)) public haveParticipated;
    event bids(uint campaignId,address account,uint amount);
    modifier IshaveParticipated(uint campaignId){
        require(haveParticipated[campaignId][msg.sender] == false);
        _;
    }

    modifier onlyOwner{
        require(msg.sender == owner, "only ower");
        _;
    }

    function initiateCampaign(address payable receiver, uint goal) external onlyOwner() returns (uint campaignId){
        campaignId = numOfCampaign++;
        CrowdCampaign storage campaign = campaigns[campaignId];
        campaign.receiver = receiver;
        campaign.goal = goal;
    }

    function participateCampaign(uint campaignId) external payable IshaveParticipated(campaignId) {
        CrowdCampaign storage campaign = campaigns[campaignId];
        campaign.totalAmount += msg.value;
        campaign.number += 1;

        users[campaignId].push(Participating(
        {
        account : msg.sender,
        amount : msg.value
        }
        ));
        haveParticipated[campaignId][msg.sender] = true;
        emit bids(campaignId,msg.sender,msg.value);
    }

    function withdraw(uint campaignId) external returns (bool finished){
        CrowdCampaign storage campaign = campaigns[campaignId];
        if (campaign.totalAmount >= campaign.goal) {
        return false;
         }
        uint amount = campaign.totalAmount;
        campaign.totalAmount = 0;
        campaign.receiver.transfer(amount);
        return true;
  }


}