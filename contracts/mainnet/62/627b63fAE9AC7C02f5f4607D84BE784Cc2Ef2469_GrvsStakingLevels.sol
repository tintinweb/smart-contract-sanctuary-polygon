//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract GrvsStakingLevels is Ownable, Pausable {
    using SafeCast for uint256;
    using SafeCast for int256;

    IERC20 public stakeToken;

    IERC20 public rewardToken;

    uint256 private constant MAGNITUDE = 2**128;

    struct Stake {
        uint256 amount;
        uint256 locked;
    }

    struct StakingLevel {
        bool enabled;
        uint256 minLevelAmount;
        uint256 rewardPerTokenPerSecond;
        mapping(address => uint256) stakeOf;
        // mapping(address => uint256) lockOf;
        mapping(address => Stake) stakes;

        uint256 lockPeriod;
        uint256 totalStakes;
        uint256 lastRewardDistribution;
        uint256 _magnifiedRewardPerShare;
        mapping(address => int256) _magnifiedRewardCorrections;
        mapping(address => uint256) _withdrawnRewardOf;
    }

    mapping(uint256 => StakingLevel) public levels;
    uint256 public levelsLength;
    uint256 public minAmount;
    address public treasury;
    bool public forceUnstakeMode;

    constructor(
        IERC20 stakeToken_,
        IERC20 rewardToken_,
        uint256 minAmount_,
        address treasury_
    ) {
        require(minAmount_ >= 0, "Staking: minimum amount must be greater than zero");

        stakeToken = stakeToken_;
        rewardToken = rewardToken_;
        minAmount = minAmount_;
        treasury = treasury_;
    }

    // PUBLIC FUNCTIONS

    function stake(uint256 amount) external {
        require(!paused(), "Staking: stake while paused");
        require(amount >= minAmount, "Staking: rejected by minimum amount");
        uint256 levelIndex = upLevelIndex(msg.sender, amount);

        StakingLevel storage level = levels[levelIndex];
        _distributeRewards(level);

        stakeToken.transferFrom(msg.sender, address(this), amount);

        (uint256 unstakedAmount, uint256 locked) = _restakeLevels(msg.sender, levelIndex);
        amount+= unstakedAmount;
        if (locked == 0) {
            locked = block.timestamp;
        }

        Stake memory pollStake = Stake(
            amount,
            locked
        );
        level.stakes[msg.sender] = pollStake;

        level.totalStakes += amount;
        level.stakeOf[msg.sender] += amount;

        level._magnifiedRewardCorrections[msg.sender] -= (
            (level._magnifiedRewardPerShare * amount).toInt256()
        );
    }

    function unstakeAll() external {
        uint256 amount;
        for(uint256 i; i < levelsLength; i++) {
            amount+= _unstake(msg.sender, i, false);
        }

        _unstakeSend(amount);
    }

    function claimReward() external {
        require(!forceUnstakeMode, "Staking: just unstake mode");

        uint256 amount;
        for(uint256 i; i < levelsLength; i++) {
            amount+= _claimReward(i);
        }

        _rewardSend(amount);
    }

    // RESTRICTED FUNCTIONS

    function addLevel(
        uint256 minLevelAmount_,
        uint256 rewardPerTokenPerYear_,
        uint256 lockPeriod_
    ) external onlyOwner {
        levelsLength++;
        setLevel(levelsLength - 1, minLevelAmount_, rewardPerTokenPerYear_, lockPeriod_, true);
    }

    function setLevel(
        uint256 levelIndex,
        uint256 minLevelAmount_,
        uint256 rewardPerTokenPerYear_,
        uint256 lockPeriod_,
        bool enabled_
    ) public onlyOwner {
        require(levelIndex < levelsLength, "Staking: Unknown levelIndex");

        if (levelIndex > 0) {
            require(levels[levelIndex - 1].minLevelAmount < minLevelAmount_, "Staking: Amount must be greater than previous level");
        }

        StakingLevel storage level = levels[levelIndex];
        _distributeRewards(level);

        level.minLevelAmount = minLevelAmount_;
        level.rewardPerTokenPerSecond = rewardPerTokenPerYear_ / (365 days);
        level.lockPeriod = lockPeriod_;
        level.enabled = enabled_;
    }

    function setForceUnstakeMode(bool forceUnstakeMode_) external onlyOwner {
        forceUnstakeMode = forceUnstakeMode_;
    }

    function setPause(bool pause_) external onlyOwner {
        if (pause_) {
            _pause();
        }
        else {
            _unpause();
        }
    }

    function withdrawRewardTokens(uint256 amount) external onlyOwner {
        rewardToken.transfer(treasury, amount);
    }

    // VIEW FUNCTIONS

    function upLevelIndex(address account, uint256 addAmount) public view returns(uint256) {
        uint256 staked = stakeOf(account) + addAmount;
        uint256 levelIndex;
        for(uint256 i; i < levelsLength; i++) {
            if (staked >= levels[i].minLevelAmount && (levels[i].enabled || levels[i].stakeOf[account] > 0)) {
                levelIndex = i;
            }
        }

        return levelIndex;
    }

    function currentLevelIndex(address account) public view returns(uint256) {
        uint256 levelIndex;
        for(uint256 i; i < levelsLength; i++) {
            if (levels[i].stakeOf[account] > 0) {
                levelIndex = i;
            }
        }

        return levelIndex;
    }

    function stakeOf(address account) public view returns (uint256) {
        uint256 amount;
        for(uint256 i; i < levelsLength; i++) {
            amount+= levels[i].stakeOf[account];
        }

        return amount;
    }

    function stakeOf(address account, uint256 levelIndex) external view returns (uint256) {
        require(levelIndex < levelsLength, "Staking: Unknown levelIndex");

        return levels[levelIndex].stakeOf[account];
    }

    function totalStakes() external view returns (uint256) {
        uint256 amount;
        for(uint256 i; i < levelsLength; i++) {
            amount+= levels[i].totalStakes;
        }

        return amount;
    }

    function stakeInfo(address account, uint256 levelIndex) public view returns (Stake memory) {
        require(levelIndex < levelsLength, "Staking: Unknown levelIndex");

        return levels[levelIndex].stakes[account];
    }

    function rewardOf(address account) public view returns (uint256) {
        uint256 amount;
        for(uint256 i; i < levelsLength; i++) {
            StakingLevel storage level = levels[i];

            uint256 currentRewardPerShare = level._magnifiedRewardPerShare;
            if (block.timestamp > level.lastRewardDistribution && level.totalStakes > 0) {
                currentRewardPerShare +=
                    (level.rewardPerTokenPerSecond *
                        (block.timestamp - level.lastRewardDistribution) *
                        MAGNITUDE) /
                    10**18;
            }

            amount+= _rewardOf(account, level, currentRewardPerShare);
        }

        return amount;
    }

    function _rewardOf(address account, StakingLevel storage level, uint256 currentRewardPerShare)
        private
        view
        returns (uint256)
    {
        uint256 accumulatedReward = ((
            (currentRewardPerShare * level.stakeOf[account]).toInt256()
        ) + level._magnifiedRewardCorrections[account]).toUint256() / MAGNITUDE;
        return accumulatedReward - level._withdrawnRewardOf[account];
    }

    // INTERNAL FUNCTIONS

    function _unstake(address account, uint256 levelIndex, bool force) internal returns (uint256) {
        if (forceUnstakeMode) force = forceUnstakeMode;

        StakingLevel storage level = levels[levelIndex];
        uint256 lock = (level.stakes[account].locked + level.lockPeriod);

        if(!force && block.timestamp < lock) {
            return 0;
        }

        uint256 amount = level.stakes[account].amount;
        delete level.stakes[account];

        _distributeRewards(level);

        level.totalStakes-= amount;
        level.stakeOf[account]-= amount;

        level._magnifiedRewardCorrections[account] += (
            (level._magnifiedRewardPerShare * amount).toInt256()
        );

        return amount;
    }

    function _unstakeSend(uint256 amount) internal {
        require(amount > 0, "Staking: Nothing to unstake");

        stakeToken.transfer(msg.sender, amount);
    }

    function _restakeLevels(address account, uint256 levelIndex) internal returns (uint256, uint256) {
        uint256 unstakedAmount;
        uint256 locked;
        for (uint256 i; i <= levelIndex; i++) {
            locked = levels[i].stakes[account].locked;
            unstakedAmount+= _unstake(account, i, true);
            // if (unstakedAmount > 0) break;
        }

        return (unstakedAmount, locked);
    }

    function _claimReward(uint256 levelIndex) internal returns (uint256) {
        StakingLevel storage level = levels[levelIndex];
        _distributeRewards(level);

        uint256 reward = _rewardOf(msg.sender, level, level._magnifiedRewardPerShare);
        level._withdrawnRewardOf[msg.sender] += reward;

        return reward;
    }

    function _rewardSend(uint256 amount) internal {
        if(amount > 0) {
            rewardToken.transfer(msg.sender, amount);
        }
    }

    function _distributeRewards(StakingLevel storage level) private {
        if (block.timestamp > level.lastRewardDistribution) {
            if (level.totalStakes > 0) {
                level._magnifiedRewardPerShare +=
                    (level.rewardPerTokenPerSecond *
                        (block.timestamp - level.lastRewardDistribution) *
                        MAGNITUDE) /
                    10**18;
            }

            level.lastRewardDistribution = block.timestamp;
        }
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

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