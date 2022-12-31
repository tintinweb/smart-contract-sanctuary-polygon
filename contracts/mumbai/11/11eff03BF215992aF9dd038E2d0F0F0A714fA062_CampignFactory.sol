//SPDX-License-Identifier: Unlicensed
pragma solidity >0.7.0 <= 0.9.0;

contract CampignFactory{
    address[] public deployedCampaigns;
    event campaignCreated(string title,
    uint requireCampignAmount,
    address indexed owner,
    address capaignAddress,
    string imgURI,
    uint indexed timestamp,
    string indexed category);

    function createCampaign(
    string memory campignTitle, 
    uint requireCampignAmount,
    string memory imgURI,
    string memory category,
    string memory storyURI)public{

        Campaign newCampaign = new Campaign(
            campignTitle,requireCampignAmount,imgURI,storyURI);

        deployedCampaigns.push(address(newCampaign));

        emit campaignCreated(campignTitle,
        requireCampignAmount,
        msg.sender,
        address(newCampaign),
        imgURI,
        block.timestamp,
        category);

    }
}

contract Campaign{
    string public title;
    uint public requiredAmount;
    string public image;
    string public story;
    address payable public owner;   
    uint public receivedAmount;
    event donated(address indexed donar, uint indexed amount, uint indexed timestamp);

    constructor(
     string memory campignTitle,
     uint requireCampignAmount,
     string memory imgURI,
     string memory storyURI
     
     ){
        title = campignTitle;
        requiredAmount = requireCampignAmount;
        image = imgURI;
        story = storyURI;
        owner = payable(msg.sender);
    }

    function donat() public payable{
        require(receivedAmount<=requiredAmount,"required amount fullfilled");
        owner.transfer(msg.value);
        receivedAmount += msg.value;

        emit donated(msg.sender, msg.value,block.timestamp);
    }
}