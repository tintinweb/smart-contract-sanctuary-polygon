// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

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

    // mapping is use as key value pair like javascript object
    // Campaings[0] = 0 => { address:6789009, title: build pc, description: this is test des.., and fill and other fields }
    // Campaings[1] = 1 => { address:6789009, title: build pc, description: this is test des.., and fill and other fields }

    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberOfCampaigns = 0; // declare global variable

    // use memory keyword for string to hold variable value inside function after function terminate memory 
    // that created in blockchain also deleted
    // storage keyword use for hold data permanent in blockchain
    function createCampaign(address _owner, string memory _title, string memory _description, uint256 
    _target, uint256 _deadline, string memory _image) public returns(uint256) {
        // this is how we can get campaign on particular index of mapping key value pair 
        Campaign storage campaign = campaigns[numberOfCampaigns];

        // is everything okay?
        require(campaign.deadline < block.timestamp, "The deadline should be date in future");
        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        numberOfCampaigns++;
        return numberOfCampaigns - 1;

    }

    // payable keyword mean in this function we are gona donate some crypto currency to somwehere else

    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value; //get the ammount of sender from frountend
        
        // this is how we get key value pair and then by using storage we are getting it on blockchain storage
        Campaign storage campaign = campaigns[_id];
        campaign.donators.push(msg.sender); //msg.sender get the address of sender vault
        campaign.donations.push(amount);
        (bool sent, ) = payable(campaign.owner).call{value: amount}(""); // sent amount to campain owner address
        if (sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }
     }

    // view keyword mean it world return some data that would be just viewed on frontend
    function getDonators(uint256 _id) public view returns(address[] memory, uint256[] memory) {
        return ( campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaign() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns); // [{}, {}, {}, {}] this is how we creating number of empty objects for total number of campaigns

        for(uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];
            allCampaigns[i] = item;
        }

        return allCampaigns;
    }



}