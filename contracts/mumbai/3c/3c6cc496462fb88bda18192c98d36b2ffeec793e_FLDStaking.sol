// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.15;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FLDStaking is Ownable{

    IERC20  public FLD;
    IERC20  public rewardToken;
    uint256 public rewardRate;
    uint256 public rewardTokenRewardRate;
    uint256 public totalStaked;
    uint256 public totalRewardsPaid;
    uint256 public totalRewardsTokenPaid;

    struct Stake {
        uint256 amount;
        uint256 startTimestamp;
    }

    mapping(address => Stake[]) public stakes;

    event Staked(address indexed account, uint256 amount, uint256 timestamp);

    event Unstaked(address indexed account, 
                   uint256 amount, 
                   address receiver, 
                   uint256 reward, 
                   uint256 rewardTokenAmount, 
                   uint256 timestamp);

    event RewardRateSet(uint256 rewardRate, uint256 timestamp);

    event RewardTokenRewardRateSet(uint256 rewardRate, uint256 timestamp);

    event RewardsDistributed(address account,
                             uint256 rewardAmount, 
                             uint256 rewardTokenAmount, 
                             uint256 timestamp);

    event RewardTokensClaimed(address indexed account, 
                              address receiver, 
                              uint256 rewardAmount, 
                              uint256 rewardTokenAmount, 
                              uint256 timestamp);

    event RewardTokenUpdated(address indexed rewardToken,
                             uint256 timestamp);

    constructor(address FLDAddress, 
                address rewardTokenAddress, 
                uint256 _rewardRate,
                uint256 _rewardTokenRewardRate) Ownable() {

        FLD = IERC20(FLDAddress);
        rewardToken = IERC20(rewardTokenAddress);
        rewardRate = _rewardRate;
        rewardTokenRewardRate = _rewardTokenRewardRate;
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        uint256 allowance = FLD.allowance(msg.sender, address(this));
        require(allowance >= amount, "Insufficient allowance");

        uint256 currentTimestamp = block.timestamp;

        FLD.transferFrom(msg.sender, address(this), amount);
        stakes[msg.sender].push(Stake(amount, currentTimestamp));
        totalStaked += amount;

        emit Staked(msg.sender, amount, currentTimestamp);
    }

    function unstake(uint256 stakeIndex, address receiver) external {
        require(stakes[msg.sender].length > stakeIndex, "Stake does not exist");

        Stake memory stake = stakes[msg.sender][stakeIndex];

        uint256 amount = stake.amount;
        uint256 reward = calculateReward(amount, stake.startTimestamp);
        uint256 rewardTokenAmount = calculateRewardToken(amount, stake.startTimestamp);

        FLD.transfer(receiver, amount + reward);
        rewardToken.transfer(receiver, rewardTokenAmount);

        totalRewardsPaid += reward;
        totalRewardsTokenPaid += rewardTokenAmount;
        totalStaked -= amount;

        delete stakes[msg.sender][stakeIndex];

        emit Unstaked(msg.sender, amount, receiver, reward, rewardTokenAmount, block.timestamp);
    }

    function claimStakingRewards(uint256 stakeIndex, address receiver) external {

        require(stakes[msg.sender].length > stakeIndex, "Stake does not exist");

        Stake memory stake = stakes[msg.sender][stakeIndex];

        uint256 amount = stake.amount;
        uint256 reward = calculateReward(amount, stake.startTimestamp);
        uint256 rewardTokenAmount = calculateRewardToken(amount, stake.startTimestamp);

        FLD.transfer(msg.sender, amount + reward);
        rewardToken.transfer(msg.sender, rewardTokenAmount);

        totalRewardsPaid += reward;
        totalRewardsTokenPaid += rewardTokenAmount;

        stakes[msg.sender][stakeIndex].startTimestamp = block.timestamp;

        emit RewardTokensClaimed(msg.sender, receiver, reward, rewardTokenAmount, block.timestamp);
    }

    function getStakes(address account) external view returns (Stake[] memory) {
        return stakes[account];
    }

    function setRewardToken(address _rewardTokenAddress) onlyOwner external {
        rewardToken = IERC20(_rewardTokenAddress);
        emit RewardTokenUpdated(_rewardTokenAddress, block.timestamp);
    }
    function setRewardRate(uint256 _rewardRate) onlyOwner external {
        rewardRate = _rewardRate;
        emit RewardRateSet(_rewardRate, block.timestamp);
    }

    function setRewardTokenRewarRate(uint256 _rewardRate) onlyOwner external {
        rewardTokenRewardRate = _rewardRate;
        emit RewardTokenRewardRateSet(_rewardRate, block.timestamp);
    }

    function getCurrentRewards(address account, uint256 stakeIndex) external view returns (uint256, uint256) {
        require(stakes[account].length > stakeIndex, "Stake does not exist");

        Stake memory stake = stakes[account][stakeIndex];

        uint256 currentReward = calculateReward(stake.amount, stake.startTimestamp);
        uint256 currentRewardTokenReward = calculateRewardToken(stake.amount, stake.startTimestamp);
        
        return (currentReward,currentRewardTokenReward) ;
    }

    function calculateReward(uint256 amount, uint256 startTimestamp) private view returns (uint256) {
        uint256 currentTimestamp = block.timestamp;
        uint256 duration = currentTimestamp - startTimestamp;
        uint256 reward = (amount * duration * rewardRate)/1e18;
        return reward;
    }

    function calculateRewardToken(uint256 amount, uint256 startTimestamp) private view returns (uint256) {
        uint256 currentTimestamp = block.timestamp;
        uint256 duration = currentTimestamp - startTimestamp;
        uint256 rewardTokenAmount = (amount * duration * rewardTokenRewardRate)/1e18;
        return rewardTokenAmount;
    }

    function addRewardToken(uint256 amount) onlyOwner external {
        rewardToken.transferFrom(msg.sender, address(this), amount);
    }

   function distributeRewardTokens(uint256 amount, address[] calldata accounts) onlyOwner external {

        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 stakeCount = stakes[account].length;
            for (uint256 j = 0; j < stakeCount; j++) {
                Stake memory stake = stakes[account][j];
                
                uint256 rewardAmount = calculateReward(stake.amount, stake.startTimestamp);
                uint256 rewardTokenAmount = calculateReward(stake.amount, stake.startTimestamp);
                
                FLD.transfer(msg.sender, rewardAmount);
                rewardToken.transfer(account, rewardTokenAmount);

                stakes[account][j].startTimestamp = block.timestamp;

                emit RewardsDistributed(account, rewardAmount, rewardTokenAmount, block.timestamp);
            }
        }
    }

    receive() external payable {}
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