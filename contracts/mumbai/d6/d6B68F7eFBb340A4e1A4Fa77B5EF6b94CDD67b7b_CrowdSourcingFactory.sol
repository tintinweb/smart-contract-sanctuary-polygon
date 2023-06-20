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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ICrowdFundingCampaign.sol";

contract CrowdFundingCampaign is ICrowdFundingCampaign {
    struct Campaign {
        string name;
        address creator;
        IERC20 token;
        uint256 goalAmount;
        bool claimed;
        bool cancelled;
        bool claimable;
        address[2] participantsWallets;
        uint256[2] participantsSplit;      // must equal 10000
    }

    Campaign public campaign;
    
    mapping(address => uint256) public pledges;

        // string public name;
        // address public creator;
        // IERC20 public immutable token;
        // uint256 public goalAmount;
        // bool public claimed;
        // bool public cancelled;
        // bool public claimable;
        // address[2] public participantsWallets;
        // uint[2] public participantsSplit;      // must equal 10000


    constructor(
        string memory _name,
        address _tokenAddress,
        uint256 _goalAmount
    ) {
        campaign = Campaign({
            name: _name,
            creator: msg.sender,
            token: IERC20(_tokenAddress),
            goalAmount: _goalAmount,
            claimed: false,
            cancelled: false,
            claimable: false,
            participantsWallets: [address(0), address(0)],
            participantsSplit: [uint256(0), uint256(0)]
        });
        // name = _name;
        // creator = msg.sender;
        // token = IERC20(_tokenAddress);
        // goalAmount = _goalAmount;
        // claimed = false;
        // cancelled = false;
        // claimable = false;
    }

    function cancel() external {
        require(msg.sender == campaign.creator, "Only the creator can cancel");
        require(campaign.claimed == false, "Cannot cancel a campaign that has been claimed");
        campaign.cancelled = true;
    }

    function pledge(uint _amount) external {
        require(campaign.cancelled == false, "Cannot pledge to a cancelled campaign");
        require(campaign.claimed == false, "Cannot pledge to a claimed campaign");
        require(_amount > 0, "Cannot pledge 0 tokens");
        pledges[msg.sender] += _amount;
        campaign.token.transferFrom(msg.sender, address(this), _amount);
    }

    function refund() external {
        require(campaign.claimable == false, "Cannot refund from a completed campaign");
        require(campaign.claimed == false, "Cannot refund from a claimed campaign");
        require(pledges[msg.sender] > 0, "Must have already pledged tokens to request a refund");
        pledges[msg.sender] = 0;
        campaign.token.transferFrom(address(this), msg.sender, pledges[msg.sender]);
    }

    function setParticipants(
        address _participant1Wallet,
        address _participant2Wallet,
        uint256 _participant1Split,
        uint256 _participant2Split
    ) external {
        require(msg.sender == campaign.creator, "Only the creator can set participants");
        require(campaign.cancelled == false, "Cannot pledge to a cancelled campaign");
        require(campaign.claimed == false, "Cannot pledge to a claimed campaign");
        
        campaign.participantsWallets[0] = _participant1Wallet;
        campaign.participantsWallets[1] = _participant2Wallet;
        campaign.participantsSplit[0] = _participant1Split;
        campaign.participantsSplit[1] = _participant2Split;
    }

    function setClaimable() external {
        require(msg.sender == campaign.creator, "Only the creator can complete a campaign");
        require(campaign.cancelled == false, "Cannot pledge to a cancelled campaign");
        require(campaign.claimed == false, "Cannot pledge to a claimed campaign");
        require(campaign.participantsWallets[0] != address(0) && campaign.participantsWallets[1] != address(0), "Both participants must be set");
        require(campaign.participantsSplit[0] + campaign.participantsSplit[1] == 10000, "Participants split must total to 10000");
        require(campaign.token.balanceOf(address(this)) >= campaign.goalAmount, "Goal amount must be reached");
        require(campaign.claimable == false, "Cannot complete a campaign that is already completed");

        campaign.claimable = true;
    }

    function claim() external {
        require(campaign.participantsWallets[0] != address(0) && campaign.participantsWallets[1] != address(0), "Both participants must be set");
        require(campaign.participantsSplit[0] + campaign.participantsSplit[1] == 10000, "Participants split must total to 10000");
        require(campaign.claimed == false, "Cannot claim a campaign that has already been claimed");
        require(campaign.cancelled == false, "Cannot claim a campaign that has been cancelled");
        require(campaign.token.balanceOf(address(this)) >= campaign.goalAmount, "Goal amount must be reached");
        require(campaign.claimable == true, "Cannot claim a campaign that hasn't been completed");

        uint256 participant1Amount = (campaign.token.balanceOf(address(this)) * campaign.participantsSplit[0]) / 10000;
        uint256 participant2Amount = (campaign.token.balanceOf(address(this)) * campaign.participantsSplit[1]) / 10000;

        campaign.token.transfer(campaign.participantsWallets[0], participant1Amount);
        campaign.token.transfer(campaign.participantsWallets[1], participant2Amount);

        campaign.claimed = true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ICrowdFundingCampaign.sol";
import "./CrowdFundingCampaign.sol";

contract CrowdSourcingFactory {
    uint public campaignCount = 0;
    mapping(uint => address) public campaigns;

    function createCrowdFundingCampaign(string memory _name, address _tokenAddress, uint256 _goalAmount) external returns(address) {
        ICrowdFundingCampaign newCampaign = new CrowdFundingCampaign(_name, _tokenAddress, _goalAmount);

        campaignCount++;
        campaigns[campaignCount] = address(newCampaign);
        return address(newCampaign);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ICrowdFundingCampaign {
    
}