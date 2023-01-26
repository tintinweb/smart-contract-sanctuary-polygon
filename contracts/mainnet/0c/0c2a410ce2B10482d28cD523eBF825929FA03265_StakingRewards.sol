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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error UnsuccessfulFetchOfTokenBalance();

contract StakingRewards is Ownable {
	IERC20 public immutable stakingToken;
	IERC20 public immutable rewardsToken;

	// Duration of rewards to be paid out (in seconds)
	uint256 public duration;
	// Timestamp of when the rewards finish
	uint256 public finishAt;
	// Minimum of last updated time and reward finish time
	uint256 public updatedAt;
	// Reward to be paid out per second
	uint256 public rewardRate;
	// Sum of (reward rate * dt * 1e18 / total supply)
	uint256 public rewardPerTokenStored;
	// User address => rewardPerTokenStored
	mapping(address => uint256) public userRewardPerTokenPaid;
	// User address => rewards to be claimed
	mapping(address => uint256) public rewards;

	// Total staked
	uint256 public totalSupply;
	// User address => staked amount
	mapping(address => uint256) public balanceOf;

	event RewardAdded(uint256 reward);
	event Staked(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RewardPaid(address indexed user, uint256 reward);
	event RewardsDurationUpdated(uint256 newDuration);
	event Recovered(address token, uint256 amount);

	constructor(address _stakingToken, address _rewardToken, uint256 _duration) {
		stakingToken = IERC20(_stakingToken);
		rewardsToken = IERC20(_rewardToken);
		setRewardsDuration(_duration);
	}

	modifier updateReward(address _account) {
		rewardPerTokenStored = rewardPerToken();
		updatedAt = lastTimeRewardApplicable();

		if (_account != address(0)) {
			rewards[_account] = earned(_account);
			userRewardPerTokenPaid[_account] = rewardPerTokenStored;
		}

		_;
	}

	function lastTimeRewardApplicable() public view returns (uint256) {
		return _min(finishAt, block.timestamp);
	}

	function rewardPerToken() public view returns (uint256) {
		if (totalSupply == 0) {
			return rewardPerTokenStored;
		}

		return rewardPerTokenStored + (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) / totalSupply;
	}

	function stake(uint256 _amount) external updateReward(msg.sender) {
		require(_amount > 0, "Cannot stake 0");
		uint256 balance = getTokenBalance(address(stakingToken));
		stakingToken.transferFrom(msg.sender, address(this), _amount);
		uint256 transferredAmount = getTokenBalance(address(stakingToken)) - balance;
		balanceOf[msg.sender] += transferredAmount;
		totalSupply += transferredAmount;
		emit Staked(msg.sender, transferredAmount);
	}

	function withdraw(uint256 _amount) public updateReward(msg.sender) {
		require(_amount > 0, "Cannot withdraw 0");
		require(balanceOf[msg.sender] >= _amount, "Withdraw exceeds balance");
		balanceOf[msg.sender] -= _amount;
		totalSupply -= _amount;
		stakingToken.transfer(msg.sender, _amount);
		emit Withdrawn(msg.sender, _amount);
	}

	function getRewardForDuration() external view returns (uint256) {
		return rewardRate * duration;
	}

	function earned(address _account) public view returns (uint256) {
		return
			((balanceOf[_account] * (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) + rewards[_account];
	}

	function getReward() public updateReward(msg.sender) {
		uint256 reward = rewards[msg.sender];
		if (reward > 0) {
			rewards[msg.sender] = 0;
			rewardsToken.transfer(msg.sender, reward);
			emit RewardPaid(msg.sender, reward);
		}
	}

	function setRewardsDuration(uint256 _duration) public onlyOwner {
		require(
			block.timestamp > finishAt,
			"Previous rewards period must be complete before changing the duration for the new period"
		);
		duration = _duration;
		emit RewardsDurationUpdated(_duration);
	}

	function notifyRewardAmount(uint256 _amount) external onlyOwner updateReward(address(0)) {
		if (block.timestamp >= finishAt) {
			rewardRate = _amount / duration;
		} else {
			uint256 remainingRewards = (finishAt - block.timestamp) * rewardRate;
			rewardRate = (_amount + remainingRewards) / duration;
		}

		require(rewardRate > 0, "reward rate = 0");
		require(rewardRate * duration <= rewardsToken.balanceOf(address(this)), "Provided reward too high");

		finishAt = block.timestamp + duration;
		updatedAt = block.timestamp;
		emit RewardAdded(_amount);
	}

	function exit() external {
		withdraw(balanceOf[msg.sender]);
		getReward();
	}

	// Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
	function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
		require(tokenAddress != address(stakingToken), "Cannot withdraw the staking token");
		IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
		emit Recovered(tokenAddress, tokenAmount);
	}

	function getTokenBalance(address token) internal view returns (uint256) {
		(bool success, bytes memory encodedBalance) = token.staticcall(
			abi.encodeWithSelector(IERC20.balanceOf.selector, address(this))
		);

		if (success && encodedBalance.length >= 32) {
			return abi.decode(encodedBalance, (uint256));
		}
		revert UnsuccessfulFetchOfTokenBalance();
	}

	function _min(uint256 x, uint256 y) private pure returns (uint256) {
		return x <= y ? x : y;
	}
}