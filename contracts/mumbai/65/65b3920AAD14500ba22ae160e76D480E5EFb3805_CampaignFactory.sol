// SPDX-License-Identifier: MIT

pragma solidity >0.7.0 <=0.9.0;


//contract to record all crowdfunding projects
contract CampaignFactory {
    address[] public deployedCampaigns;

    // event front-end Se Integrate Karne m kaam ata h
    event campaignCreated(
        string title,
        uint requiredAmount,
        address indexed owner,
        address campaignAddress,
        string imgURI,
        uint indexed timestamp,
        string indexed category
    );

    function totalPublishedProjs() public view returns (uint256) {
        return deployedCampaigns.length;
    }

     function createCampaign(
        string memory campaignTitle, 
        uint requiredCampaignAmount, 
        string memory imgURI, 
        string memory category,
        string memory storyURI) public
        {
            //initializing CrowdfundingProject contract
            Campaign newCampaign = new Campaign(
                //passing arguments from constructor function
               campaignTitle, requiredCampaignAmount, imgURI, storyURI, msg.sender);

               deployedCampaigns.push(address(newCampaign));

               emit campaignCreated(
            campaignTitle, 
            requiredCampaignAmount, 
            msg.sender, 
            address(newCampaign),
            imgURI,
            block.timestamp,
            category
        );

    }
}

contract Campaign{
    //defining state variables
    string public title;
    uint public requiredAmount;
    string public image;
    string public story;
    address payable public owner; //address where amount to be transfered
    uint public receivedAmount;
   
   event donated(address indexed donar, uint indexed amount, uint indexed timestamp);

   constructor(
        string memory campaignTitle, 
        uint requiredCampaignAmount, 
        string memory imgURI,
        string memory storyURI,
        address campaignOwner
    ) {
        //mapping values
        title = campaignTitle;
        requiredAmount = requiredCampaignAmount;
        image = imgURI;
        story = storyURI;
        owner = payable(campaignOwner);
    }

    //donation function
    function donate() public payable {

        //if goal amount is achieved, close the proj
        require(requiredAmount > receivedAmount, "GOAL ACHIEVED");

        owner.transfer(msg.value);

        //calculate total amount raised
        receivedAmount += msg.value;

        emit donated(msg.sender, msg.value, block.timestamp);
    }
}