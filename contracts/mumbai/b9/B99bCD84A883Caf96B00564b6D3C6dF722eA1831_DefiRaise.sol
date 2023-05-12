// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract DefiRaise {

   bytes32 public constant NAME = "DefiRaise";

    struct CampaignCategory{
        uint256 id;
        string name;
    }

    struct Campaign {
        address owner;
        string  data;
        uint256 deadline;
        address[] donators;
        uint256[] donations;
        uint256 amountCollected;
        uint256 category;
    }

    mapping(uint256 => Campaign) private campaigns;

    mapping (uint256 => CampaignCategory) private categories;

    uint256 private numberOfCampaigns = 0;

    uint256 private numberOfCategories = 0;

    event categoryCreated(string _name, uint256 indexed _id); 
    
    event campaignCreated(address indexed _owner, uint256 _deadline, uint256 _categoryId, string _data); 


    function createCampaignCategory(string memory _name) external returns(uint256){
        CampaignCategory storage campaignCateory  =  categories[numberOfCategories];

        campaignCateory.id = numberOfCategories + 1;

        campaignCateory.name = _name;

        numberOfCategories++;

        emit categoryCreated(_name, campaignCateory.id);

        return numberOfCategories - 1;
    }

     function getCampaignCategory(uint256 _categoryId) view public returns (CampaignCategory memory) {
        // verify category Id
        require(_categoryId >= 1, "Invalid category id");
        return (categories[_categoryId - 1]);
    }

    function getCampaignCategories() external view returns (CampaignCategory[] memory) {
        
        CampaignCategory[] memory allCategories = new CampaignCategory[](numberOfCategories);

        for(uint i = 0; i < numberOfCategories; i++) {
            CampaignCategory storage item = categories[i];

            allCategories[i] = item;
        }

        return allCategories;
    }

    function createCampaign(address _owner, uint256 _deadline, uint256 _categoryId, string memory _data) external returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];

        require(_categoryId >= 1, "Invalid category id");
        
        CampaignCategory memory category = categories[_categoryId - 1];

        // Ensure that the campaign category existed already;

        require(category.id == _categoryId, "Ooops...campaign category does not exists");
        

        require(campaign.deadline < block.timestamp, "The deadline should be a date in the future.");

        campaign.owner = _owner;
        campaign.data = _data;
        campaign.deadline = _deadline;
        campaign.category = _categoryId;
        
        numberOfCampaigns++;

        emit campaignCreated(_owner, _deadline, _categoryId, _data);

        return numberOfCampaigns - 1;
    }

    function donateToCampaign(uint256 _id) external payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        (bool sent,) = payable(campaign.owner).call{value: amount}("");

        if(sent) {
            campaign.donators.push(msg.sender);
            campaign.donations.push(amount);
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }

    function getDonators(uint256 _id) view external returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() external view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for(uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }

    function getTotalNosOfCampaigns() external view returns(uint256){
        return numberOfCategories;
    }

     function getCampaign(uint256 _campaignId) view public returns (Campaign memory) {
        // verify category Id
        require(_campaignId >= 0, "Invalid campaign id");
        return (campaigns[_campaignId]);
    }
}