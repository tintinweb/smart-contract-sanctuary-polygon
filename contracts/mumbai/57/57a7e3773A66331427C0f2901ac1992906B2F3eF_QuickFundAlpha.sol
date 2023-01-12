// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract QuickFundAlpha {
    // default address to which fees are sent
    address payable defaultFeesAddress = payable(0xc69848d26622b782363C4C9066c9787a270E9232);

    // address of the contract owner
    address public owner;

    // constructor to set the contract owner to the address that deploys the contract
    constructor() public {
        owner = msg.sender;
     }

    // modifier to allow only the owner to execute a function
    modifier onlyOwner {
      require(msg.sender == owner, "Only owner can call this function.");
     _;
    }
    
    // struct to store information about a campaign
    struct Campaign {
        address owner; // address of the campaign owner
        string title; // title of the campaign
        string description; // description of the campaign
        uint256 target; // target amount to be raised
        uint256 deadline; // deadline for the campaign
        uint256 amountCollected; // amount of native coins collected
        string[] image; // image for the campaign
        string category; // category of the campaign
        string[] video; // video for the campaign
        address[] donators; // array to store addresses of donators
        string [] donatorsNotes; // array to store notes from donators
        uint256[] donations; // array to store donations
        string[] donationsCoins; // array to store other coin donations
        string[] updates; // array to store other campaign updates
        string[] milestones; // array for campaign milestones
    }

    // mapping to store campaign information
    mapping(uint256 => Campaign) public campaigns;

    // variable to keep track of the number of campaigns
    uint256 public numberOfCampaigns = 0;

    // function to create a new campaign
    function createCampaign(address _owner,
     string memory _title, 
     string memory _description, 
     uint256 _target, 
     uint256 _deadline, 
     string memory _category, 
     string [] memory _image, 
     string [] memory _video,
     string [] memory _milestones
     ) public returns (uint256) {

        Campaign storage campaign = campaigns[numberOfCampaigns];

        require(_deadline > block.timestamp, "The deadline should be a date in the future.");

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.category = _category;
        campaign.image = _image;
        campaign.video = _video;
        campaign.milestones = _milestones;
        campaign.updates.push("");

        numberOfCampaigns++;

        return numberOfCampaigns - 1;

    }

    function updateCampaign(
        uint256 pid,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _category,
        string[] memory _image,
        string[] memory _video,
        string[] memory _milestones
    ) public {

        Campaign storage campaign = campaigns[pid];

        // Ensure that only the campaign owner can update the campaign
        require(msg.sender == campaign.owner, "Only the campaign owner can update the campaign.");
        require(_deadline > block.timestamp, "The deadline should be a date in the future.");

        // Update campaign fields
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.category = _category;
        campaign.image = _image;
        campaign.video = _video;
        campaign.milestones = _milestones;
    }


    function pushUpdateCampaign(
        uint256 pid,
        string memory _update
    ) public {
        Campaign storage campaign = campaigns[pid];
        // Ensure that only the campaign owner can update the campaign
        require(msg.sender == campaign.owner, "Only the campaign owner can push updates to the campaign.");
        //Push Updates to Campaign
        campaign.updates.push(_update);
    }

   
    function donateToCampaign(uint256 _id, string memory note, string memory symbol) public payable {
        
        Campaign storage campaign = campaigns[_id];
        require(campaign.deadline > block.timestamp, "The deadline for this campaign has passed.");

        uint256 amount = msg.value;
        require((msg.sender.balance) > amount, "Insufficient balance");

        uint256 fees = amount / 100;

        // check fees were sent to campaign
        (bool feesSent,) = payable(defaultFeesAddress).call{value: fees}("");
        require(feesSent, "Error transferring fees.");

        (bool sentOther,) = payable(campaign.owner).call{value: amount - fees}("");
        require(sentOther, "Error transferring funds to campaign owner.");
        
        campaign.amountCollected = campaign.amountCollected + (amount - fees);
        campaign.donators.push(msg.sender);
        campaign.donatorsNotes.push(note);
        campaign.donations.push(amount - fees);
        campaign.donationsCoins.push(symbol);

    }

    function getDonators(uint256 _id) view public returns(address[] memory, uint256[] memory, string[] memory, string [] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations, campaigns[_id].donatorsNotes, campaigns[_id].donationsCoins);

    }

    function transferOther(uint256 _id, uint256 _amount, string memory symbol, string memory note, address payable coin_addy) public { 
        
        // create function that you want to use to fund your contract or transfer that token
        IERC20 token = IERC20(coin_addy);

        uint256 fees = _amount / 100;

        Campaign storage campaign = campaigns[_id];
        require(campaign.deadline > block.timestamp, "The deadline for this campaign has passed.");

        require(token.balanceOf(msg.sender) >= _amount, "Insufficient balance of token");

        (bool feesSent) = token.transferFrom(msg.sender, defaultFeesAddress, fees);
        require(feesSent, "Error transferring fees.");

        (bool sentOther) = token.transferFrom(msg.sender, campaign.owner, (_amount - fees));
        require(sentOther, "Error transferring payment.");

        campaign.donators.push(msg.sender);
        campaign.donatorsNotes.push(note);
        campaign.donations.push(_amount - fees);
        campaign.donationsCoins.push(symbol);
    }


    function getCampaigns() public view returns(Campaign[] memory){
        // Getting campagigns from memory
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);
        
        // loop and populate, then return all campaigns.
        for (uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];
            allCampaigns[i] = item;
        }

        return allCampaigns;
    }

    function setDefaultFeesAddress(address payable _newAddress) public onlyOwner {
        require(_newAddress != address(0), "The new address cannot be the zero address.");
        defaultFeesAddress = _newAddress;
    }

    function getDefaultFeesAddress() public view returns (address) {
        return defaultFeesAddress;
    }

}