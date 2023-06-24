// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract Funding {

    struct Campaign {
        address owner;
        string title;
        string description;
        uint target;
        uint deadline;
        uint recievedAmount;
        string image;
        address[] donorAddresses;
        uint[] donationAmounts;

    }    

    mapping (uint256 => Campaign) campaigns;

    IERC20 public immutable tokenAddress;

    constructor (IERC20 _tokenAddress){
        tokenAddress =_tokenAddress;
    }

    uint public campaignCount;
    //TODO get all campaing 
    //TODO make this pay using specfing token
    

    function createCampaing(string memory _title,string memory  _descripition,uint _target,string memory image)  external {
        Campaign storage campaign = campaigns[campaignCount];
        
        require(bytes(_title).length > 0, "Title must not be empty");
        require(bytes(_descripition).length > 0, "Description must not be empty");
        require(_target > 0, "Target must be greater than 0");
        require(bytes(image).length > 0, "Image must not be empty");
        require(msg.sender != address(0), "Owner must be a valid address");

        

        campaign.owner = msg.sender;
        campaign.title = _title;
        campaign.description = _descripition;
        campaign.target = _target;
        campaign.deadline = block.timestamp + 30 days;
        campaign.image = image;
        campaignCount++;
    }
        
        function getCampaign(uint campaingId) external view returns(Campaign memory){
            return campaigns[campaingId];
        }


    function donate(uint campaignId, uint amount) external payable{
        require(amount > 0, "Donation amount must be greater than 0");
        require(campaigns[campaignId].deadline >= block.timestamp, "Campaign has been closed");
        require(campaigns[campaignId].recievedAmount + amount <= campaigns[campaignId].target, "Campaign target has been reached");

        // Transfer tokens from the donor to the contract
        tokenAddress.approve(address(this), amount);
        require(tokenAddress.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        Campaign storage campaign = campaigns[campaignId];

        campaign.recievedAmount += amount;
        campaign.donorAddresses.push(msg.sender);
        campaign.donationAmounts.push(amount);
    }

    function withdrawl (uint campaignId) external payable{
        require(campaigns[campaignId].deadline < block.timestamp, "Campaign has not been closed yet");
        require(campaigns[campaignId].owner == msg.sender, "Only the owner can withdraw the funds");
        tokenAddress.allowance(address(this), msg.sender);
        tokenAddress.transfer(msg.sender, campaigns[campaignId].recievedAmount);
    }



}