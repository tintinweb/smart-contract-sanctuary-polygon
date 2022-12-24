// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @title Crowfunding Campaign Creator
/// @author TinchoMon11
contract CrowFunding {

    /// @custom:struct Defins basic structure for a campaign
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

    /// @custom:mapping Contains campaigns created 
    mapping(uint256 => Campaign) public campaigns;

    /// @custom:counter Counter for campaigns Ids
    uint256 public numberOfCampaigns = 0;

    /// @notice Creates a new crowfunding campaign
    /// @dev TinchoMon11
    /// @param _owner of the new campaign created (address)
    /// @param _title of the new campaign (string)
    /// @param _description of the new campaign (string)
    /// @param _target to reach for the crowfunding campaing (uint256)
    /// @param _deadline of the campaing (uint256). Should be bigger than actual date
    /// @param _image URL of the campaing
    /// @return ID given to the new campaign
    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) public returns (uint256) {
        require(_deadline > block.timestamp, "Deadline should be a future date");
        
        Campaign storage campaign = campaigns[numberOfCampaigns];
        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        numberOfCampaigns += 1;

        return numberOfCampaigns-1;
    }

    /// @notice Donates to a campaign
    /// @dev TinchoMon11
    /// @param _id URL of the campaing
    function donateToCampaign(uint256 _id) public payable {
        Campaign storage campaign = campaigns[_id];
        require(campaign.deadline > block.timestamp, "This campaign has finished");

        uint256 amount = msg.value;
        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent, ) = payable(campaign.owner).call{value: amount}("");

        if(sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }

    /// @notice Gets list of donators and amounts donated
    /// @dev TinchoMon11
    /// @param _id URL of the campaing
    /// @return 2 arrays. One whit a list of donators and the other with donations made
    function getDonators(uint256 _id) public view returns (address[] memory, uint256[] memory) {
        return(campaigns[_id].donators, campaigns[_id].donations);
    }

    /// @notice Gets list of donators and amounts donated
    /// @dev TinchoMon11
     /// @return array of Campaigns already created
    function getCampaigns() public view returns(Campaign[] memory) {
        // Creates new variable "allCampaigns" that its an array of Campagin Structs with "numberOfCampaigns" emtpy elements
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns); 
        
        /// @custom:loops into campaigns created and saves them into allCampaigns array
        for(uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];
            allCampaigns[i] = item;
        }
        return allCampaigns;
    }
}