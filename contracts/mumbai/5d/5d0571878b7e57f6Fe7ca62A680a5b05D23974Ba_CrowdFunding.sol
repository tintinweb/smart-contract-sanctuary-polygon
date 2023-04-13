// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// name of the smart contract is crowdfunding
contract CrowdFunding {
    // the structure of each camapain on the website. 
    // (what each campaign would contain)
    struct Campaign{
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

    // campaigns will have serveral Campaign inside it 
    // which can be accessed like an array 
    // as we have have mapped it with an integer(key value pair)
    mapping(uint256=>Campaign) public campaigns;

    //variable storing total number of campaigns on the website
    uint256 public numberOfCampaigns=0;

    // _ is used while passing the parameters to indicate that those variables 
    // belong to that specefic function only
    // we need to add memory before every variable with datatype string

    //returns a number(campaign id) 
    //and is a public function so can be executed from the frontend as well
    function createCampaign(address _owner,
    string memory _title,
    string memory _description,
    uint256 _target,
    uint256 _deadline,
    string memory _image)
    public returns (uint256)
    {
        // a new campaign of type struct Campaign
        // also storing it in the array campaigns
        // number of campaigns is initially 0 and would be incremented acting as curr index
        Campaign storage campaign = campaigns[numberOfCampaigns];

        //require is used to check and validate things
        // print this is deadline in a past/previous date
        require(campaign.deadline < block.timestamp,"The deadline must a be a future value");

        // initializing the values
        campaign.owner= _owner;
        campaign.title=_title;
        campaign.description=_description;
        campaign.target=_target;
        campaign.deadline=_deadline;
        campaign.amountCollected=0;
        campaign.image=_image;

        numberOfCampaigns++;
        
        //index of the recently made campaign
        return numberOfCampaigns-1;
    }

    // payable is used whenever there is transaction involved(cypto would be exchanged)
    function donateToCampaign(uint256 _id) public payable {
        // this would be taken from the front-end
        uint256 amount = msg.value;

        // getting hold of the campaign for which donation has come
        Campaign storage campaign = campaigns[_id];

        //adding the donator id in the donators list
        campaign.donators.push(msg.sender);

        //adding amount of separate donations into the donations array
        campaign.donations.push(amount);

        // payable returns 2 values hence we have added , after sent
        // sent variable tells wheather the transaction has been sent or not
        (bool sent,) = payable(campaign.owner).call{value: amount}("");

        // if transaction succesfull add the amount to the total amount collected of the campaign
        if(sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }

    // view function is a function that only return data
    // it will return an array of addresses of donators and array of integers donations
    function getDonators(uint256 _id) view public 
    returns (address[] memory, uint256[] memory) {

        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    //whenever we get something from memory we add memory keyword
    function getCampaigns() public view returns (Campaign[] memory) {

        //creatomg a variable allCampagains which is an array of struct Campaigns
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for(uint i = 0; i < numberOfCampaigns; i++) {
            //fetching indivisual campaign from the storage
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }
}