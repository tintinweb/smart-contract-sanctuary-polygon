// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    // (10:10) - set up Campaign struct. (like a JS object). Specify the types this struct can have.
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

    // (12:00) - mapping allows us to reference campaigns[0]
    mapping(uint256 => Campaign) public campaigns;

    // (12:23) - global public variable:
    uint256 public numberOfCampaigns = 0;

    // (13:45) - specify parameters
    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline, //stores date as number
        string memory _image
    ) public returns (uint256) {
        //return the id of that specific campaign

        // (15:25) - create new campaign
        Campaign storage campaign = campaigns[numberOfCampaigns]; //populate first item in our Campaigns array (campaigns[0])

        // (16:07) block.timestamp is the current time
        require(
            campaign.deadline < block.timestamp,
            "The deadline should be a date in the future."
        );

        // (16:47)
        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0; //zero at the start
        campaign.image = _image;

        numberOfCampaigns++;

        return numberOfCampaigns - 1; //index of the most newly created campaign (-17:44)
    } //end of createCampaign

    // (18:50) - transfer crypto to Campaign by id
    function donateToCampaign(uint256 _id) public payable {
        //amount we are trying to send from our frontend
        uint256 amount = msg.value;

        //get campaign we want to donate to. like JS we identify it with campaigns[_id] which is avilable b/c of our mapping above
        // set to variable called `campaign`
        Campaign storage campaign = campaigns[_id];

        //add deployer address to array. `donators` is a type specified on our Campaign struct ("address[] donators;") (-19:53)
        campaign.donators.push(msg.sender);

        // same thing for the donations amount type specified in our Campaign struct ("uint256[] donations;")
        campaign.donations.push(amount);

        // (19:57) - make the transaction. This boolean variable `sent` will let us know if the tx has been sent.
        // (21:13) - (bool sent) triggered solidity error "Different number of components on the left hand side (1) than on the right hand side (2)"
        // fix error by adding comma (that we might pass something in later, but get components on left hand side up to 2)
        (bool sent, ) = payable(campaign.owner).call{value: amount}("");

        //if sent is true, add it to the total amt collected (-20:58)
        if (sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }

    //(22:01) get list of all the people (addresses) who donated (our array of donator addresses and donation amounts)
    function getDonators(
        uint256 _id
    ) public view returns (address[] memory, uint256[] memory) {
        //return something from our campaigns mapping
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    // (23:05) - no parameters b/c we want to return all campaigns
    function getCampaigns() public view returns (Campaign[] memory) {
        //return all campaigns from memory and assign to variable `allCampaigns`
        //(23:57) - variable allCampaigns is of type array of multiple campaign structures.
        // empty array with as many empty elements as there are number of campaigns, initially set to zero and incremented
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        // (24:38)
        for (uint i = 0; i < numberOfCampaigns; i++) {
            //fetch specfic campaign from storage:
            Campaign storage item = campaigns[i];
            //populate it straight into our allCampaigns array (-25:15)
            allCampaigns[i] = item;
        }

        return allCampaigns;
    }
} //end of CrowdFunding Contract