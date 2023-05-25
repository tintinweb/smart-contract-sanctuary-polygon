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
        bool ban;
    }

    address public treasury;
    
    address[] public bannedAddresses;

    mapping(uint256 => Campaign) public campaigns;
    

    uint256 public numberOfCampaigns = 0;

    constructor(){
        treasury = 0xF9826c32B837270e485C4Dc17041c643BcBC9BB8;
        
    }

    function changetreasury(address _newTreasuryAddress) public {
        require((msg.sender) == treasury);
        treasury = _newTreasuryAddress;
    }

    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) public returns (uint256) {
    require(block.timestamp < _deadline, "The deadline should be a date in the future.");

    // Check if the address is banned
    for (uint256 i = 0; i < bannedAddresses.length; i++) {
        require(bannedAddresses[i] != _owner, "Campaign creation is not allowed for banned addresses.");
    }

    Campaign storage campaign = campaigns[numberOfCampaigns];
    campaign.owner = _owner;
    campaign.ban = false; // Set the ban variable to false by default
    campaign.title = _title;
    campaign.description = _description;
    campaign.target = _target;
    campaign.deadline = _deadline;
    campaign.amountCollected = 0;
    campaign.image = _image;

    numberOfCampaigns++;

    return numberOfCampaigns - 1;
    }

    function donateToCampaign(uint256 _id) public payable {
    Campaign storage campaign = campaigns[_id];
    require(!campaign.ban, "Campaign is currently banned and not accepting donations.");

    uint256 amount = msg.value;
    uint256 fee = (amount * 5) / 100; // Calculate the 5% fee amount

    campaign.donators.push(msg.sender);
    campaign.donations.push(amount - fee); // Deduct the fee from the donation amount

    (bool sent, ) = payable(campaign.owner).call{value: amount - fee}("");

    if (sent) {
        campaign.amountCollected = campaign.amountCollected + (amount - fee); // Update the amount collected
    }

    payable(treasury).transfer(fee); // Transfer the fee to the treasury address
    }


    function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for(uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];
            allCampaigns[i] = item;
        }

        return allCampaigns;
    }

    function ban(address _banAddress) public {
    require(msg.sender == treasury, "Only the treasury address can call this function");

    bool found = false;
    for (uint256 i = 0; i < numberOfCampaigns; i++) {
        Campaign storage campaign = campaigns[i];
        if (campaign.owner == _banAddress) {
            campaign.ban = true;
            bannedAddresses.push(_banAddress);
            found = true;
            break; // Exit the loop once the campaign is found
        }
    }

    require(found, "Campaign not found");
    }


    function unban(address _unbanAddress) public {
    require(msg.sender == treasury, "Only the treasury address can call this function");

    for (uint256 i = 0; i < numberOfCampaigns; i++) {
        Campaign storage campaign = campaigns[i];
        if (campaign.owner == _unbanAddress) {
            campaign.ban = false;
            break;
        }
    }

    for (uint256 i = 0; i < bannedAddresses.length; i++) {
        if (bannedAddresses[i] == _unbanAddress) {
            delete bannedAddresses[i];
            break;
        }
    }
}


}