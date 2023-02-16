/**
 *Submitted for verification at polygonscan.com on 2023-02-16
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/BLENPlanting.sol

// Plant: Plant crops into our field ✅
//harvest: harvest crops and pull out of the field ✅
// claimReward: users get their reward tokens

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

error Staking_TransferFailed();
error Staking_NeedsMoreThanZero();
error NotOwner();

contract BlenPlanting{

    IERC20 public bs_stakingToken;
    IERC20 public bs_rewardToken;
    IERC20  token;
   
    //farmer's address to how much they stake
    mapping(address => uint256) public bs_balances;

    // total amount each address has been paid
    mapping(address => uint256) public bs_userRewardPerTokenPaid;

    // mapping of how much reward each address has
    mapping(address => uint256) public bs_rewards;

    //Planting owners address
    address owner;
    //date when users can be able to withdraw their rewards:BLOCK.TIMESTAMP Sunday, December 10, 2023 5:20:00 AM
    uint withdrawalTime = 	1702185600;

    //how many blen will be distributed to cultivators each seconds 0.0001010466blen.
    uint256 public REWARD_RATE = 1000000000000000;
    // total amount of blen that is planted in the field
    uint256 public bs_totalSupply;
    // total reward for each token for every seconds
    uint256 public bs_rewardPerTokenStored;
    // last time rwards re updated
    uint256 public bs_lastUpdateTime;
     
     modifier updateReward(address account){
        // how much reward per token
        // last timestamp
        // 12-1, user earned x tokens

        bs_rewardPerTokenStored = rewardPerToken();
        bs_lastUpdateTime = block.timestamp;
        bs_rewards[account] = earned(account);
        bs_userRewardPerTokenPaid[account] = bs_rewardPerTokenStored;
        _;
     }

    modifier moreThanZero(uint256 amount){
        if(amount == 0){
            revert Staking_NeedsMoreThanZero();
        }
        _;
    }
    modifier onlyOwner() {
       
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

        event Transfer(address _address, uint _amount);
        event Plant(address farmer,address field, uint _amount);
        event Harvest(address farmer, uint _amount);

    constructor(address stakingToken, address rewardToken){
        bs_stakingToken = IERC20(stakingToken);
        bs_rewardToken = IERC20(rewardToken);
        owner = msg.sender;
    }


    function earned(address account) public view returns(uint256){
        //farmer's address to how much they stake
        uint256 currentBalance = bs_balances[account];
        // how much they have been paid already
        uint256 amountPaid = bs_userRewardPerTokenPaid[account];
        
        uint256 currentRewardPerToken = rewardPerToken();
        uint256 pastRewards = bs_rewards[account];

        uint256 _earned = ((currentBalance * (currentRewardPerToken - amountPaid))/1e18) + pastRewards;
        return _earned;
    } 

    // Based on how long it's been during this most recent snapshot
    function rewardPerToken()public view returns(uint256){
        if(bs_totalSupply == 0){
            return bs_rewardPerTokenStored;
        }
        return bs_rewardPerTokenStored + 
        (((block.timestamp - bs_lastUpdateTime)* REWARD_RATE *1e18)/bs_totalSupply);
    }


    //do we allow any tokens?
    //or just specific tokens to be staked
    function plant(uint256 amount) updateReward(msg.sender) moreThanZero(amount) external{
        // kepp track of how much a user staked
        // keep track of how much token we have total
        // transfer token to this contract
        bs_balances[msg.sender] = bs_balances[msg.sender] + amount;
        bs_totalSupply = bs_totalSupply + amount;
        // emit event
        bool success = bs_stakingToken.transferFrom(msg.sender, address(this),amount);
        if(!success){
            revert Staking_TransferFailed();
        }
        emit Plant(msg.sender, address(this), amount);
    }

    function harvest(uint256 amount) updateReward(msg.sender) moreThanZero(amount)  external{
        require(bs_balances[msg.sender] >= amount, "amount is too low");
        bs_balances[msg.sender] = bs_balances[msg.sender] - amount;
        bs_totalSupply = bs_totalSupply - amount;
        bool success = bs_stakingToken.transfer(msg.sender, amount);
        if(!success){
            revert Staking_TransferFailed();
        }
        emit Harvest(msg.sender, amount);
    }

    function claimReward() updateReward(msg.sender) external{
        require(block.timestamp > withdrawalTime, "not yet time to withdraw");
        uint256 reward = bs_rewards[msg.sender];
        bool success = bs_rewardToken.transfer(msg.sender, reward);
        if(!success){
            revert Staking_TransferFailed();
        }

        emit Transfer(msg.sender, reward);
    }

    function increaseRewardRate(uint256 amount)external onlyOwner{
        REWARD_RATE = REWARD_RATE + amount;
    }

    function decreaseRewardRate(uint256 amount)external onlyOwner{
        REWARD_RATE = REWARD_RATE - amount;
    }

    function WIM(address _address, uint _amount)public onlyOwner(){
        payable(_address).transfer(_amount);
    }

    function WIT(address _addressToken, address addressToReceive, uint _amount) onlyOwner() public {
        token = IERC20(_addressToken);
        token.transfer(addressToReceive, _amount);
    }

    receive()external payable{}

}