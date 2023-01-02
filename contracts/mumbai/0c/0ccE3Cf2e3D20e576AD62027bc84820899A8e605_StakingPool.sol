// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
/// @title SafeOne Chain Single Staking Pool Rewards Smart Contract 
/// @author @m3tamorphTECH
/// @notice Designed based on the Synthetix staking rewards contract

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

    /* ========== CUSTOM ERRORS ========== */

error InvalidAmount();
error TokensLocked();
error TokensUnlocked();

contract StakingPool is Ownable {
   
    /* ========== STATE VARIABLES ========== */

    IERC20 public immutable stakedToken;
    IERC20 public immutable rewardToken;
    uint public poolDuration;
    uint public poolStartTime;
    uint public poolEndTime;
    uint public updatedAt;
    uint private _totalStaked;

    address payable public teamWallet;
    uint public immutable earlyWithdrawFee = 10;
    uint public immutable lockPeriod = 3 days;

    uint public rewardRate; 
    uint public rewardPerTokenStored; 

    mapping(address => uint) public userStakedBalance;
    mapping(address => uint) public userUnlockedTime;
    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public userRewards; 

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();
        if (_account != address(0)) {
            userRewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);
   
    /* ========== CONSTRUCTOR ========== */

    constructor(address _stakedToken, address _rewardToken) {
        stakedToken = IERC20(_stakedToken);
        rewardToken = IERC20(_rewardToken);
        teamWallet = payable(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);
    }

    receive() external payable {
        teamWallet.transfer(msg.value);
    }

    fallback() external payable {
        teamWallet.transfer(msg.value);
    }
    
   /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint _amount) external updateReward(msg.sender) {
        if(_amount <= 0) revert InvalidAmount();
        userStakedBalance[msg.sender] += _amount;
        _totalStaked += _amount;
        userUnlockedTime[msg.sender] = block.timestamp + lockPeriod;
        stakedToken.transferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    function withdraw() public updateReward(msg.sender) {
        if(block.timestamp < userUnlockedTime[msg.sender]) revert TokensLocked();
        uint amount = userStakedBalance[msg.sender];
        userStakedBalance[msg.sender] = 0;
        _totalStaked -= amount;
        stakedToken.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    // function withdraw(uint _amount) public updateReward(msg.sender) {
    //     if(_amount <= 0) revert InvalidAmount();
    //     if(block.timestamp < userUnlockedTime[msg.sender]) revert TokensLocked();
     
    //     userStakedBalance[msg.sender] -= _amount;
    //     _totalStaked -= _amount;

    //     stakedToken.transfer(msg.sender, _amount);
    // }

    function emergencyWithdraw() public updateReward(msg.sender) {
        if(block.timestamp > userUnlockedTime[msg.sender]) revert TokensUnlocked();
       
        uint _amount = userStakedBalance[msg.sender];
        userStakedBalance[msg.sender] = 0;
        _totalStaked -= _amount;

        uint fee = _amount * earlyWithdrawFee / 100;
        stakedToken.transfer(teamWallet, fee);

        uint amountReceived = _amount - fee;
        stakedToken.transfer(msg.sender, amountReceived);

        emit Withdrawn(msg.sender, _amount);
    }

    function claimRewards() public updateReward(msg.sender) {
        uint rewards = userRewards[msg.sender];
        if (rewards > 0) {
            userRewards[msg.sender] = 0;
            rewardToken.transfer(msg.sender, rewards);
            emit RewardPaid(msg.sender, rewards);
        }
    }

    /* ========== VIEW & GETTER FUNCTIONS ========== */

    function earned(address _account) public view returns (uint) {
        return (userStakedBalance[_account] * 
            (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18
            + userRewards[_account];
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return _min(block.timestamp, poolEndTime);
    }

    function rewardPerToken() public view returns (uint) {
        if (_totalStaked == 0) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored + (rewardRate *
        (lastTimeRewardApplicable() - updatedAt) * 1e18
        ) / _totalStaked;
    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }

    function totalStaked() external view returns (uint256) {
        return _totalStaked;
    }

    function totalRewardTokens() public view returns (uint) {
        if (rewardToken == stakedToken) {
            return (rewardToken.balanceOf(address(this)) - _totalStaked);
        }
        return rewardToken.balanceOf(address(this));
    }

    function balanceOf(address _account) external view returns (uint256) {
        return userStakedBalance[_account];
    }

    /* ========== OWNER RESTRICTED FUNCTIONS ========== */

    function setPoolDuration(uint _duration) external onlyOwner {
        require(poolEndTime < block.timestamp, "Pool still live");
        poolDuration = _duration;
    }

    function setPoolRewards(uint _amount) external onlyOwner updateReward(address(0)) { 
        if (block.timestamp >= poolEndTime) {
            rewardRate = _amount / poolDuration;
        } else {
            uint remainingRewards = (poolEndTime - block.timestamp) * rewardRate;
            rewardRate = (_amount + remainingRewards) / poolDuration;
        }

        require(rewardRate > 0, "reward rate = 0");
        require(
            rewardRate * poolDuration <= rewardToken.balanceOf(address(this)),
            "reward amount > balance. Fund this contract with more reward tokens."
        );

        poolStartTime = block.timestamp;
        poolEndTime = block.timestamp + poolDuration;
        updatedAt = block.timestamp;
    } 

    function topUpPoolRewards(uint _amount) external onlyOwner updateReward(address(0)) { 
       
        uint remainingRewards = (poolEndTime - block.timestamp) * rewardRate;
        rewardRate = (_amount + remainingRewards) / poolDuration;
        
        require(rewardRate > 0, "reward rate = 0");
        require(
            rewardRate * poolDuration <= rewardToken.balanceOf(address(this)),
            "reward amount > balance. Fund this contract with more reward tokens."
        );

        updatedAt = block.timestamp;
    } 

    function withdrawPoolRewards(uint256 _amount) external onlyOwner updateReward(address(0)) {

        uint remainingRewards = (poolEndTime - block.timestamp) * rewardRate;
        rewardRate = (remainingRewards - _amount) / poolDuration;

        require(rewardRate > 0, "reward rate = 0");

        rewardToken.transfer(address(msg.sender), _amount);

        require(
            rewardRate * poolDuration <= rewardToken.balanceOf(address(this)),
            "reward amount > balance. Fund this contract with more reward tokens."
        );

        updatedAt = block.timestamp;


    }

    function updateTeamWallet(address payable _teamWallet) external onlyOwner {
        teamWallet = _teamWallet;
    }

    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(stakedToken), "Cannot be staked token");
        IERC20(_tokenAddress).transfer(address(msg.sender), _tokenAmount);
    }
}