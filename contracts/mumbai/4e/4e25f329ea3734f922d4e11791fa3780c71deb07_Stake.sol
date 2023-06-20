/**
 *Submitted for verification at polygonscan.com on 2023-06-20
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the BIP.
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
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Stake is Ownable {

    IERC20 private token;  

    bool private initialized = false;

    uint256 private rewardPer = 10;

    uint256 private stakingId = 0;

    bool private isRewardOff  = false;

    uint256 public rewardOffOnTime = 0;

    uint256 private totalInvestment = 0;

    uint256 private totalInvestors = 0;

    struct UserStruct {
        uint256[] stakingIds;
        uint256 totalStakeAmount;
        uint256 totalHarvestAmount;
        uint256 lastClaim;
    }

    struct StakeStruct {
        address owner;
        uint256 amount;
        uint256 stakeTime;
        uint256 unStakeTime;
        uint256 harvested;
    }
     
    uint256 private lockperiod = 180 days; 
    
    mapping (uint256 => StakeStruct) public stakeDetails;
    mapping (address => UserStruct)  public userDetails;


    event Staked(uint256 stakingId, address _staker, uint256 _amount, uint256 _time);
    event UnStaked(uint256 stakingId, address _staker, uint256 _amount, uint256 _time);
    event Harvested(address _staker, uint256 _amount, uint256 _time);

    function initialize(address _token) onlyOwner public returns (bool) {
        require(!initialized, "Already Initialized");
        initialized = true;
        token = IERC20(_token);
        return true;
    }

    function stake (uint256 _amount) public returns (bool) {
        require (token.allowance(msg.sender, address(this)) >= _amount, "Token not approved");
        token.transferFrom(msg.sender, address(this), _amount);
        StakeStruct memory stakerinfo;    
        stakerinfo = StakeStruct({
            owner : msg.sender,
            amount: _amount,
            stakeTime: block.timestamp,
            unStakeTime : block.timestamp + lockperiod,
            harvested: 0
        });
        if(userDetails[msg.sender].totalStakeAmount == 0 && userDetails[msg.sender].totalHarvestAmount == 0){
            totalInvestors++;
        }
        stakeDetails[stakingId] = stakerinfo;
        totalInvestment += _amount;
        userDetails[msg.sender].totalStakeAmount += _amount;
        userDetails[msg.sender].totalHarvestAmount += 0;
        userDetails[msg.sender].stakingIds.push(stakingId);
        
        emit Staked(stakingId, msg.sender, _amount, block.timestamp);
        stakingId++;  
        return true;
    }

    function unstake (uint256 _stakingId) public returns (bool) {
        require(stakeDetails[_stakingId].owner == msg.sender, "You are not a staker");
        require(stakeDetails[_stakingId].stakeTime != 0, "Token not exist");
        require (block.timestamp > stakeDetails[_stakingId].unStakeTime, "Amount is in lock period");          
        token.transfer(msg.sender, stakeDetails[_stakingId].amount);
        userDetails[msg.sender].totalStakeAmount -= stakeDetails[_stakingId].amount;
        emit UnStaked(_stakingId, msg.sender, stakeDetails[_stakingId].amount, block.timestamp);
        for(uint256 i = 0; i < userDetails[msg.sender].stakingIds.length; i++){
            if(userDetails[msg.sender].stakingIds[i] == _stakingId){
                userDetails[msg.sender].stakingIds[i] = userDetails[msg.sender].stakingIds[userDetails[msg.sender].stakingIds.length-1];
                delete userDetails[msg.sender].stakingIds[userDetails[msg.sender].stakingIds.length-1];
                userDetails[msg.sender].stakingIds.pop();
                break;
            }
        }
        delete stakeDetails[_stakingId];
        return true;
    }

    function harvest() public returns (bool) {
        require(block.timestamp > userDetails[msg.sender].lastClaim , "You can claim after 24 hours");
        _harvest(msg.sender);
        return true;
    }

    function _harvest(address _user) internal {
        require(getClaimReward(_user) > 0, "Nothing to harvest");
        uint256 harvestAmount = getClaimReward(_user);
        userDetails[_user].totalHarvestAmount += harvestAmount;
        token.transfer(_user, harvestAmount);
        userDetails[msg.sender].lastClaim = block.timestamp + 24 hours;
        emit Harvested(_user, harvestAmount, block.timestamp);
    }

    function getClaimReward(address _user) public view returns (uint256){
        uint256 reward = 0;
        for(uint256 i = 0; i < userDetails[_user].stakingIds.length; i++){
            reward += getCurrentReward(userDetails[_user].stakingIds[i]);
        }
        return reward;
    }

    function getTotalReward(uint256 _stakingId) public view returns (uint256) {
        if(isRewardOff && rewardOffOnTime > stakeDetails[_stakingId].stakeTime){
            uint256 stakingDuration = rewardOffOnTime - stakeDetails[_stakingId].stakeTime;
            uint256 totalReward = (stakingDuration * stakeDetails[_stakingId].amount * rewardPer / 100) / (7 days * 26); // Assuming 6 months as 26 weeks
            return totalReward;
        }else if(!isRewardOff){
            uint256 stakingDuration = block.timestamp - stakeDetails[_stakingId].stakeTime;
            uint256 totalReward = (stakingDuration * stakeDetails[_stakingId].amount * rewardPer / 100) / (7 days * 26); // Assuming 6 months as 26 weeks
            return totalReward;
        }else{
            return 0;
        }
    }

    function getCurrentReward(uint256 _stakingId) public view returns (uint256) {
        if(stakeDetails[_stakingId].amount != 0){
            return (getTotalReward(_stakingId)) - (stakeDetails[_stakingId].harvested);
        }else{
            return 0;
        }
    }

    function getTotalInvestment() public view returns (uint256) {
        return totalInvestment;
    }

    function getTotalInvestors() public view returns (uint256) {
        return totalInvestors;
    }

    function getToken() public view returns (IERC20) {
        return token;
    } 

    function changeRewardPer(uint256 _per) public onlyOwner returns (bool) {
        rewardPer = _per;
        return true;
    }

    function isRewardONOFF() public onlyOwner returns (bool){
        isRewardOff = !isRewardOff;
        rewardOffOnTime = block.timestamp;
        return true;
    }

    function transferTokens(uint256 _amount) public onlyOwner returns (bool){
        require(token.balanceOf(address(this)) > _amount , "Not Enough Tokens");
        token.transfer(owner(), _amount);
        return true;
    } 
     
}