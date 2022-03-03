/**
 *Submitted for verification at polygonscan.com on 2022-03-02
*/

// SPDX-License-Identifier: MIT
// File: contracts/OpenZeppelin/IERC20.sol
pragma solidity >=0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// File: contracts/OpenZeppelin/SafeMath.sol
// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}

// File: contracts/Staking/StakingNew.sol
contract StakingNew{
    using SafeMath for uint256;
    IERC20 public ERC20Interface;
    mapping (address => uint256) private _stakes;
    address  public tokenAddress;
    uint public stakingStarts;
    uint public stakingEnds;
    uint public earlyWithdrawTimeStarts;
    uint public afterMaturityTimeStarts;
    uint public stakingCap;
    uint public poolPeriod; //5 minutes
    address public rewardSetter;
    
    struct StakeState {
        uint256 stakedTotal;
        uint256 stakingCap;
        uint256 stakedBalance;
    }

    struct StakeRewardState {
        uint256 rewardBalance;
        uint256 rewardsTotal;
        uint256 earlyWithdrawRewardAPY;
        uint256 afterMaturityWithdrawRewardAPY;
    }

    struct UserRewards {
        uint256 earlyWithdrawReward;
        uint256 afterMaturityReward;
    }

    StakeRewardState public rewardState;
    StakeState public stakeState;
    mapping (address => UserRewards) public userRewards;

    event Staked(address indexed token, address indexed staker_, uint256 requestedAmount_);
    event PaidOut(address indexed token, address indexed staker_, uint256 amount_, uint256 reward_);

    constructor (address _tokenAddress, uint256 _stakingCap) _realAddress(_tokenAddress) _positive(_stakingCap){
        tokenAddress = _tokenAddress;
        stakingStarts = block.timestamp;
        stakingEnds = stakingStarts.add(777600); //9 days 
        earlyWithdrawTimeStarts = stakingStarts.add(30); //0.5 minutes 
        afterMaturityTimeStarts = stakingStarts.add(864000); //10 days
        poolPeriod = 10; //10 days
        stakingCap = _stakingCap;
        stakeState.stakingCap = _stakingCap;
        ERC20Interface = IERC20(_tokenAddress);

        rewardState.rewardBalance = 1000000000;
        rewardState.rewardsTotal = 1000000000;
        rewardState.earlyWithdrawRewardAPY = 30;        
        rewardState.afterMaturityWithdrawRewardAPY = 40;
        rewardSetter = msg.sender;
    }

    /*
    * @notice stake is a function to stake tokens of address tokenAddress by any account which owns tokens with balance>0
    * @params amount(uint256) - amount of tokens to be staked
    * @output - bool - true if tokens are staked
    */
    function stake(uint256 amount) public returns(bool){
        address from = msg.sender;
        return _stake(from, from, amount);
    }

    /*
    * @notice _stake is a private function to stake tokens and update the stakeState struct
    * @params payer(address) - address of the accout making the function call
    * staker(address) - address of thea account who will have the stakes
    * amount(uint256) - amount of tokens to be staked
    * @output bool - true if tokens are staked
    */
    function _stake(address payer, address staker, uint256 amount) private _after(stakingStarts) _before(stakingEnds) _positive(amount) returns(bool) {
        uint256 stakedBal = stakeState.stakedBalance;
        require(amount <= stakingCap.sub(stakedBal), "Staking cap is filled");
        _payTo(payer, address(this), amount);
        emit Staked(tokenAddress, staker, amount);
        stakeState.stakedBalance = stakeState.stakedBalance.add(amount);
        stakeState.stakedTotal = stakeState.stakedTotal.add(amount);
        _stakes[staker] = _stakes[staker].add(amount);
        return true;
    }

    /*
    * @notice _payTo is a function to transfer tokens from allower to receiver
    * @params allower - address of account from which amount of tokens will be deducted from the balance
    * receiver - address of account to which amount of tokens will be transferred to 
    * amount(uint256) - amount of tokens to be staked
    * @output uint256 - amount of tokens transferred
    */
    function _payTo(address allower, address receiver, uint256 amount) private returns(uint256){
        uint256 preBalance = IERC20(tokenAddress).balanceOf(receiver);
        ERC20Interface.transferFrom(allower, receiver, amount);
        uint256 postBalance = IERC20(tokenAddress).balanceOf(receiver);
        return postBalance.sub(preBalance);
    }

    /*
    * @notice _payDirect is a function to transfer tokens from msg.sender to receiver
    * @params to - address of account to which amount of tokens will be transferred to 
    * amount(uint256) - amount of tokens to be staked
    * @output bool - true if tokens are staked
    */
    function _payDirect(address to, uint256 amount) private returns(bool){
        ERC20Interface.transfer(to, amount);
        return true;
    }

    /*
    * @notice withdraw is a function to withdraw staked tokens and update stake balance of account
    * @params amount(uint256) - amount of stakes to be withdrawn
    * @output bool - true if staked tokens are withdrawn
    */
    function withdraw(uint256 amount) public returns (bool) {
        address from = msg.sender;
        uint256 wdAmount = tryWithdraw(from, amount);
        stakeState.stakedBalance = stakeState.stakedBalance.sub(wdAmount);
        _stakes[from] = _stakes[from].sub(wdAmount);
        return true;
    }

    /*
    * @notice tryWithdraw is a private function to withdraw staked tokens based on whether withdraw time has ended 
    * @params from - address of account that wants to withdraw tokens
    * amount(uint256) - amount of staked tokens to be withdrawn
    * @output uint256 - amount of staked tokens withdrawn
    */
    function tryWithdraw(address from, uint256 amount) private _positive(amount) _realAddress(msg.sender) _after(earlyWithdrawTimeStarts) returns (uint256) {
        require(amount <= _stakes[from], "Not enough balance");
        if (block.timestamp < afterMaturityTimeStarts) {
            return _withdrawEarly(from, amount);
        } else {
            return _withdrawAfterClose(from, amount);
        }
    }
   
    /*
    * @notice getNumberOfDays is a function to get number of days from the unix timestamp 
    * @params timestamp - unix timestamp
    * @output uint256 - no of days
    */
    function getNumberOfDays(uint256 timestamp) internal pure returns(uint256){
        uint diff = (timestamp).div(86400);
        return diff+1;
    }

    function setAfterMaturityTimeToNow() public {
        afterMaturityTimeStarts = block.timestamp;
    }

    function setAfterMaturityTimeToLater() public {
        afterMaturityTimeStarts = (block.timestamp).add(86400); //10 days
    }

    /*
    * @notice calculateWithdrawAfterMaturityRewards is a function to fetch rewards after maturity 
    * @params amount - uint - Amount of staked tokens for which the rewards is to be fetched
    * @output uint256 - Withdraw after maturity Reward tokens
    */
    function calculateWithdrawAfterMaturityRewards(uint256 amount) public view returns(uint256){
        return ((amount).mul(rewardState.afterMaturityWithdrawRewardAPY)).div(100);
    }

    /*
    * @notice calculateWithdrawEarlyRewards is a function to get number of days from the unix timestamp 
    * @params amount - uint - Amount of staked tokens for which the rewards is to be fetched
    * @output uint256 - Withdraw early Reward tokens
    */
    function calculateWithdrawEarlyRewards(uint256 amount) public view returns(uint256){
        uint256 denom = poolPeriod;//getNumberOfDays((afterMaturityTimeStarts).sub(stakingStarts));
        denom = (denom).mul(100);
        uint256 noOfDays = getNumberOfDays((block.timestamp).sub(stakingStarts));
        uint256 reward = ((rewardState.earlyWithdrawRewardAPY).mul((amount).mul(noOfDays))).div(denom);
        return reward;
    }

    /*
    * @notice _withdrawEarly is a private function to withdraw staked tokens before withdraw time has ended
    * @params from - address of account that wants to withdraw tokens
    * amount(uint256) - amount of staked tokens to be withdrawn
    * @output uint256 - amount of staked tokens withdrawn
    */
    function _withdrawEarly(address from, uint256 amount) private _realAddress(from) returns (uint256) {
        uint256 reward = calculateWithdrawEarlyRewards(amount);
        rewardState.rewardBalance = rewardState.rewardBalance.sub(reward);
        userRewards[from].earlyWithdrawReward = userRewards[from].earlyWithdrawReward.add(reward);
        bool totalAmountPaid = _payDirect(from, amount);
        require(totalAmountPaid, "Payment Failed");
        emit PaidOut(tokenAddress, from, amount, amount.add(reward));
        return amount;
    }

    /*
    * @notice _withdrawAfterClose is a function to withdraw staked tokens after withdraw time has ended
    * @params from - address of account that wants to withdraw tokens
    * amount(uint256) - amount of staked tokens to be withdrawn
    * @output uint256 - amount of staked tokens withdrawn
    */
    function _withdrawAfterClose(address from, uint256 amount) private _realAddress(from) returns (uint256) {
        uint256 rewBal = rewardState.rewardBalance;
        uint256 reward = calculateWithdrawAfterMaturityRewards(amount);
        rewardState.rewardBalance = rewBal.sub(reward);
        userRewards[from].afterMaturityReward = (userRewards[from].afterMaturityReward).add(reward);
        bool totalAmountPaid = _payDirect(from, amount.add(reward));
        require(totalAmountPaid, "Payment Failed");
        emit PaidOut(tokenAddress, from, amount, reward);
        return amount;
    }

    /*
    * @notice checkClaimedEarlyWithdrawReward is a function to fetch how many early withdraw rewards a user claimed
    * @output uint256 - amount of rewards
    */
    function checkClaimedEarlyWithdrawReward(address staker) _realAddress(staker) public view returns (uint256) {
        return userRewards[staker].earlyWithdrawReward;
    }
    
    /*
    * @notice checkClaimedAfterMaturityReward is a function to fetch how many after maturity rewards a user claimed
    * @output uint256 - amount of rewards
    */
    function checkClaimedAfterMaturityReward(address staker) _realAddress(staker) public view returns (uint256) {
        return userRewards[staker].afterMaturityReward;
    }

    /*
    * @notice checkClaimedTotalReward is a function to fetch how many total rewards a user claimed
    * @output uint256 - amount of rewards
    */
    function checkClaimedTotalReward(address staker) _realAddress(staker) public view returns (uint256) {
        return (userRewards[staker].afterMaturityReward).add(userRewards[staker].earlyWithdrawReward);
    }

    /*
    * @notice rewardsTotal is a function to fetch total reward tokens
    * @output uint256 - true if tokens are staked
    */
    function rewardsTotal() public view returns (uint256) {
        return rewardState.rewardsTotal;
    }

    /*
    * @notice earlyWithdrawRewardAPY is a function to check earlyWithdrawReward APY
    * @output uint256 - percentage of earlyWithdrawReward
    */
    function earlyWithdrawRewardAPY() public view returns (uint256) {
        return rewardState.earlyWithdrawRewardAPY;
    }

    /*
    * @notice afterMaturityRewardAPY is a function to check afterMaturityReward APY
    * @output uint256 - percentage of afterMaturityRewardAPY
    */
    function afterMaturityRewardAPY() public view returns(uint256){
        return rewardState.afterMaturityWithdrawRewardAPY;
    }

    /*
    * @notice rewardBalance is a function to check reward tokens left
    * @output uint256 - total reward tokens left
    */
    function rewardBalance() public view returns (uint256) {
        return rewardState.rewardBalance;
    }
    
    /*
    * @notice stakedTotal is a function to check total staked tokens 
    * @output uint256 - total number of tokens staked
    */
    function stakedTotal() public view returns(uint256){
        return stakeState.stakedTotal;
    }

    /*
    * @notice stakedBalance is a function to check the total staked balance
    * @output uint256 - total number of stakes left
    */
    function stakedBalance() public view returns(uint256){
        return stakeState.stakedBalance;
    }

    /*
    * @notice stakeOf is a function to check total stakes of an account
    * @params account - address of account whose stakes are to be checked
    * @output uint256 - stake of the account
    */
    function stakeOf(address account) external view returns(uint256){
        return _stakes[account];
    }

    modifier _realAddress(address addr){
        require(addr != address(0), "Zero Address");
        _;
    }

    modifier _positive(uint256 amount){
        require(amount != 0, "Negative Amount");
        _;
    }

    modifier _after(uint eventTime){
        require(block.timestamp >= eventTime, "bad timing for the request- after");
        _;
    }

    modifier _before(uint eventTime){
        require(block.timestamp < eventTime, "bad timing for the request- before");
        _;
    }
}