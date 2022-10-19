/**
 *Submitted for verification at polygonscan.com on 2022-10-18
*/

// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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


// Dependency file: @openzeppelin/contracts/utils/Context.sol


// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/access/Ownable.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// Dependency file: contracts/IStakingContract.sol

// pragma solidity 0.8.0;

interface IStakingContract {
    event Staked(address indexed staker, uint256 indexed stakeId, uint256 amount, uint256 reward);
    event Withdrawn(address indexed staker, uint256 indexed stakeId, uint256 amount, uint256 reward);
    event ForceWithdrawn(address indexed staker, uint256 indexed stakeId, uint256 amount);
    event RewardClaimed(address indexed staker, uint256 indexed stakeId, uint256 amount);

    function stake(uint256 amount, uint256 stakeId) external;
    function withdraw(uint256 amount, uint256 stakeId) external;
    function forceWithdraw(uint256 stakeId) external returns (uint256);
    function claim(uint256 stakeId) external returns (uint256);
    function emergencyStakeRecovery() external;
    function calculateReward(address staker, uint256 stakeId) external view returns (uint256);
    function timeOfNextReward(address staker, uint256 stakeId) external view returns (uint256);
    function stakedAmount(address staker, uint256 stakeId) external view returns (uint256);
    function stakedTime(address staker, uint256 stakeId) external view returns (uint256);
    function compoundedStake(address staker, uint256 stakeId) external view returns (uint256);
    function compoundedTotalStake() external view returns (uint256);
    function totalStaked() external view returns (uint256);
    function stakingToken() external view returns (address);
}

// Root file: contracts/StakingContract.sol

pragma solidity 0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

// import "contracts/IStakingContract.sol";

/// @notice token holder of _stakingToken can stake and get rewards in _fidaToken every PERIOD
/// Ownable: owner (governor) is entitled to call emergencyStakeRecovery()
/// @dev the formula for rewards is (_initialPool/360 days)*(sum_i dt_i*stakedAmount/total_staked_amount_i)
/// where dt_i are time intervals that cover a time period for a reward claim with respect to the total stake changes
contract StakingContract is IStakingContract, Ownable {
    /// @dev reward token
    /// returns true or revert tx on transfer so no need to check transfer and transferFrom return values
    IERC20 immutable public _fidaToken;
    /// @dev total supply capped by 2**192, or at least it is limit of total stakes
    /// returns true or revert tx on transfer so no need to check transfer and transferFrom return values
    IERC20 immutable public _stakingToken;
    /// @dev initial pool of rewards, affects the value of rewards, reward token is _fidaToken
    uint256 immutable public _initialPool;
    /// @dev current stakes, timestamp + amount
    /// staker address => staked value
    /// the staked value is uint256 composition of uint32 timestamp and uint224 amount
    /// the timestamp is a creation date of a stake or a last claim or reward
    /// the amount is capped by 2**224
    mapping(address => mapping(uint256 => uint256)) internal _staked;
    /// @dev the value of compounded total stake at the time of stake creation or last reward claim
    /// (user's stake timestamp)
    mapping(address => mapping(uint256 => uint256)) internal _compoundedStakes;
    /// @dev time (uint32) of last _compoundedTotalStaked calculation + current total stake (uint224)
    /// the composition is for gas saving reasons
    /// 224 bits are reserved for total stake but actually it is capped by 2**196
    uint256 internal _totalStaked;
    /// @dev compounded total stake, an artifact required to calculate rewards
    /// this is fixed point decimal with 224 bits precision
    /// the formula is sum_i dt_i/total_staked_i - the denominator in the weighted harmonic average
    uint256 internal _compoundedTotalStaked;
    uint256 constant internal PERIOD = 1;

//    event Staked(address indexed staker, uint256 indexed stakeId, uint256 amount, uint256 reward);
//    event Withdrawn(address indexed staker, uint256 indexed stakeId, uint256 amount, uint256 reward);
//    event ForceWithdrawn(address indexed staker, uint256 indexed stakeId, uint256 amount);
//    event RewardClaimed(address indexed staker, uint256 indexed stakeId, uint256 amount);

    constructor (IERC20 fidaToken_, IERC20 stakingToken_, uint256 initialPool_) {
        _fidaToken = fidaToken_;
        _stakingToken = stakingToken_;
        _initialPool = initialPool_;
    }

    /// @notice create a new stake or increase existing
    /// claims rewards and resets creation timestamp
    function stake(uint256 amount, uint256 stakeId) external override {
        require(amount > 0, "StakingContract: cannot stake 0 amount");
        require(stakeId > 0, "StakingContract: cannot stake 0 stake id");

        uint256 totalStaked_ = _totalStaked;
        uint256 totalStakedAmount = totalStaked_ % 2**224;
        uint256 totalStakedTimestamp = totalStaked_ >> 224;
        // with these constraints no stake ever exceeds 2**192, and there is no overflows in the reward calculation
        require(totalStakedAmount + amount < 2**192, "StakingContract: maximal total stake exceeded");

        uint256 staked_ = _staked[msg.sender][stakeId];
        uint256 stakedAmount_ = staked_ % 2**224;  // the name stakedAmount is taken
        uint256 stakedTimestamp = staked_ >> 224;
        uint256 reward;

        // copy to memory for gas efficiency
        uint256 compoundedTotalStaked = _compoundedTotalStaked;
        // new compounded total stake
        if (totalStakedAmount > 0) {
            // shift by 224 bits for precision reason
            compoundedTotalStaked += ((block.timestamp - totalStakedTimestamp) << 224) / totalStakedAmount;
        } else {
            require(compoundedTotalStaked == 0, 'StakingContract: why not zero?');
            //assert();
        }

        if (stakedAmount_ > 0 && stakedTimestamp + PERIOD <= block.timestamp) {
            // it holds totalStakedAmount > 0 because stakedAmount_ > 0
            // it holds compoundedTotalStaked > 0 because totalStakedAmount >= stakedAmount_ for at least PERIOD
            reward = calculateReward(stakedAmount_, compoundedTotalStaked-_compoundedStakes[msg.sender][stakeId]);
        } else {
            reward = 0;
        }

        _staked[msg.sender][stakeId] = (block.timestamp << 224) + stakedAmount_ + amount;
        _totalStaked = (block.timestamp << 224) + totalStakedAmount + amount;
        _compoundedTotalStaked = compoundedTotalStaked;
        _compoundedStakes[msg.sender][stakeId] = compoundedTotalStaked;

        emit Staked(msg.sender, stakeId, amount, reward);
        if (reward > 0) {
            _fidaToken.transfer(msg.sender, reward);
        }
        _stakingToken.transferFrom(msg.sender, address(this), amount);
    }

    /// @notice withdraw part or all the stake
    /// claims rewards and resets creation timestamp of the stake or deletes the stake
    function withdraw(uint256 amount, uint256 stakeId) external override {
        require(amount > 0, "StakingContract: cannot withdraw 0 amount");

        uint256 totalStaked_ = _totalStaked;
        uint256 totalStakedAmount = totalStaked_ % 2**224;
        uint256 totalStakedTimestamp = totalStaked_ >> 224;

        uint256 staked_ = _staked[msg.sender][stakeId];
        uint256 stakedAmount_ = staked_ % 2**224;
        uint256 stakedTimestamp = staked_ >> 224;
        require(stakedAmount_ > 0, "StakingContract: the stake does not exist");
        require(stakedAmount_ >= amount, "StakingContract: amount exceeds the stake");
        uint256 reward;

        // copy to memory for gas efficiency
        uint256 compoundedTotalStaked = _compoundedTotalStaked;
        // new compounded total stake
        // shift by 224 bits for precision reason
        compoundedTotalStaked += ((block.timestamp - totalStakedTimestamp) << 224) / totalStakedAmount;

        if (stakedAmount_ > 0 && stakedTimestamp + PERIOD <= block.timestamp) {
            // it holds totalStakedAmount > 0 because stakedAmount_ > 0
            // it holds compoundedTotalStaked > 0 because totalStakedAmount >= stakedAmount_ for at least PERIOD
            reward = calculateReward(stakedAmount_, compoundedTotalStaked-_compoundedStakes[msg.sender][stakeId]);
        } else {
            reward = 0;
        }

        if (amount == stakedAmount_) {
            delete _staked[msg.sender][stakeId];
            delete _compoundedStakes[msg.sender][stakeId];
        } else {
            _staked[msg.sender][stakeId] = (block.timestamp << 224) + stakedAmount_ - amount;
            _compoundedStakes[msg.sender][stakeId] = compoundedTotalStaked;
        }
        _totalStaked = (block.timestamp << 224) + totalStakedAmount - amount;

        if (_totalStaked % 2**224 == 0){
            _compoundedTotalStaked = 0;
        } else {
            _compoundedTotalStaked = compoundedTotalStaked;
        }

        emit Withdrawn(msg.sender, stakeId, amount, reward);
        if (reward > 0) {
            _fidaToken.transfer(msg.sender, reward);
        }
        _stakingToken.transfer(msg.sender, amount);
    }

    /// @notice withdraw all stake and abandon rewards
    /// in case stake is somehow locked
    function forceWithdraw(uint256 stakeId) external override returns (uint256) {
        uint256 stake_ = _staked[msg.sender][stakeId];
        if (stake_ > 0) {
            uint256 stakedAmount_ = stake_ % 2**224;
            // copy to memory for gas efficiency
            uint256 totalStaked_ = _totalStaked;
            uint256 totalStakedAmount = totalStaked_ % 2**224;
            uint256 totalStakedTimestamp = totalStaked_ >> 224;

            delete _staked[msg.sender][stakeId];
            delete _compoundedStakes[msg.sender][stakeId];
            _totalStaked = (block.timestamp << 224) + totalStakedAmount - stakedAmount_;

            // new compounded total stake
            // shift by 224 bits for precision reason
            _compoundedTotalStaked += ((block.timestamp - totalStakedTimestamp) << 224) / totalStakedAmount;

            emit ForceWithdrawn(msg.sender, stakeId, stakedAmount_);
            _stakingToken.transfer(msg.sender, stakedAmount_);
            return stakedAmount_;
        } else {
            return 0;
        }
    }

    /// @notice claim rewards without changing stake
    /// gets rewards and creation timestamp moves to current time
    function claim(uint256 stakeId) external override returns (uint256) {
        uint256 stake_ = _staked[msg.sender][stakeId];
        require(stake_ > 0, "StakingContract: stake does not exist for the claim");

        uint256 totalStaked_ = _totalStaked;
        uint256 totalStakedAmount = totalStaked_ % 2**224;
        uint256 totalStakedTimestamp = totalStaked_ >> 224;

        uint256 staked_ = _staked[msg.sender][stakeId];
        uint256 stakedAmount_ = staked_ % 2**224;
        uint256 stakedTimestamp = staked_ >> 224;
        require(stakedAmount_ > 0, "StakingContract: stake does not exist for the claim");
        require(stakedTimestamp + PERIOD <= block.timestamp, "Staking contract: time has not elapsed for claim");

        // copy to memory for gas efficiency
        uint256 compoundedTotalStaked = _compoundedTotalStaked;
        // new compounded total stake
        // shift by 224 bits for precision reason
        compoundedTotalStaked += ((block.timestamp - totalStakedTimestamp) << 224) / totalStakedAmount;

        uint256 reward = calculateReward(stakedAmount_, compoundedTotalStaked-_compoundedStakes[msg.sender][stakeId]);

        _staked[msg.sender][stakeId] = (block.timestamp << 224) + stakedAmount_;
        _compoundedStakes[msg.sender][stakeId] = compoundedTotalStaked;

        if (reward == 0) {
            return 0;
        }

        emit RewardClaimed(msg.sender, stakeId, reward);
        _fidaToken.transfer(msg.sender, reward);
        return reward;
    }

    /// @notice if someone simply transfers staking tokens instead of stake() function
    function emergencyStakeRecovery() external override onlyOwner {
        uint256 balance = _stakingToken.balanceOf(address(this));
        uint256 recoveryAmount = balance - (_totalStaked % 2**224);
        require(recoveryAmount > 0, "StakingContract: there are no additional staking tokens for recovery in the contract");
        _stakingToken.transfer(msg.sender, recoveryAmount);
    }

    function calculateReward(address staker, uint256 stakeId) external view override returns (uint256) {
        uint256 staked_ = _staked[staker][stakeId];
        if (staked_ == 0) {
            return 0;
        }

        uint256 totalStaked_ = _totalStaked;
        uint256 totalStakedAmount = totalStaked_ % 2**224;
        uint256 totalStakedTimestamp = totalStaked_ >> 224;

        uint256 stakedAmount_ = staked_ % 2**224;
        uint256 stakedTimestamp = staked_ >> 224;
        if (stakedAmount_ == 0 || stakedTimestamp + PERIOD > block.timestamp) {
            return 0;
        }

        // copy to memory for gas efficiency
        uint256 compoundedTotalStaked = _compoundedTotalStaked;
        // new compounded total stake
        // shift by 224 bits for precision reason
        compoundedTotalStaked += ((block.timestamp - totalStakedTimestamp) << 224) / totalStakedAmount;

        uint256 reward = calculateReward(stakedAmount_, compoundedTotalStaked-_compoundedStakes[msg.sender][stakeId]);

        return reward;
    }

    /// @dev reward = _initialPool/(360 days) * stakeAmount_ *  compoundedTotalStakedDelta / 2**224
    /// calculation with overflow
    /// compoundedTotalStakedDelta is fixed point decimal with 224 precision
    function calculateReward(uint256 stakeAmount_, uint256 compoundedTotalStakedDelta) private view returns (uint256) {
        uint256 totalRewardPerSecond = _initialPool/(360 days);
        uint256 stakeShare = stakeAmount_ * compoundedTotalStakedDelta;  // cannot overflow

        // ranges are under control, arithmetic ops checks are a waste of gas
        unchecked {
            // each element represent 128 bits,
            // there are only 3 elements because we immediately shift the result by 128 bits
            // 96 more bits left to shift
            uint256[3] memory result;
            // totalRewardPerSecond and stakeShare are decomposed as high and low 128 bits
            uint256 x = (totalRewardPerSecond % 2**128) * (stakeShare % 2**128);
            result[0] = x >> 128;
            x = (totalRewardPerSecond >> 128) * (stakeShare % 2**128);
            result[0] += x % 2**128;
            result[1] += x >> 128;
            x = (totalRewardPerSecond % 2**128) * (stakeShare >> 128);
            result[0] += x % 2**128;
            result[1] += x >> 128;
            x = (totalRewardPerSecond >> 128) * (stakeShare >> 128);
            result[1] += x % 2**128;
            result[2] += x >> 128;

            // no threat for uint256 overflow because result[2] < 2**128
            // we check if the result < 2**(256+96) so it can be safely shifted by 96 bits
            // note that result[0] and result[1] can exceed 2**128
            assert((((result[0]>>128)+result[1])>>128)+result[2] < 2**96);

            // this is the result shifted by 96
            // no threat for overflow
            return (result[0] >> 96) + (result[1] << 32) + (result[2] << 180);
        }

    }

    function timeOfNextReward(address staker, uint256 stakeId) public view override returns (uint256) {
        uint256 staked_ = _staked[staker][stakeId];
        if (staked_ > 0) {
            return (staked_ >> 224) + PERIOD;
        } else {
            return block.timestamp + PERIOD;
        }
    }

    function stakedAmount(address staker, uint256 stakeId) external view override returns (uint256) {
        return _staked[staker][stakeId] % 2**224;
    }

    function stakedTime(address staker, uint256 stakeId) external view override returns (uint256) {
        return _staked[staker][stakeId] >> 224;
    }

    function compoundedStake(address staker, uint256 stakeId) external view override returns (uint256) {
        return _compoundedStakes[staker][stakeId];
    }

    function compoundedTotalStake() external view override returns (uint256) {
        return _compoundedTotalStaked;
    }

    function totalStaked() external view override returns (uint256) {
        return _totalStaked % 2**224;
    }

    function stakingToken() external view override returns (address) {
        return address(_stakingToken);
    }
}