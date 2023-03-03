// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

/**
 * @dev The base unit for times in seconds.
 */
// For staging, the base unit is one minute. That means all configuration values in "days" are
// instead counted in minutes. This is meant for test deployments.
uint256 constant BASE_TIME_UNIT_SECONDS = 60;

pragma solidity 0.8.18;// SPDX-License-Identifier: UNLICENSED
import "../openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../openzeppelin-contracts/contracts/access/Ownable.sol";
import "../openzeppelin-contracts/contracts/security/Pausable.sol";
import "../openzeppelin-contracts/contracts/utils/math/Math.sol";
import "@config/LockedWombatStakingConfig.sol";

contract LockedWombatStaking is Ownable, Pausable {

    /**
     * @dev Constant defining how many seconds there are in a day.
     */
    uint256 constant SECONDS_DAY = BASE_TIME_UNIT_SECONDS;

    /**
     * @dev Constant defining how many seconds there are in a year. A year is defined as 360 days
     * for the purpose of this smart contract.
     */
    uint256 constant SECONDS_YEAR = 360 * SECONDS_DAY;

    /**
     * @dev The token that can be staked.
     */
    IERC20 public immutable token;

    /**
     * @dev Amount of tokens owned by the smart contract that are used to pay out rewards. This is
     * used to ensure we never use other users funds to payout rewards so we don't turn into a ponzi
     * scheme.
     */
    uint256 public rewardPool;

    /**
     * @dev Data for a locked position by a user
     */
    struct LockedStake {
        /**
         * @dev Unique identifier for the locked stake
         */
        uint256 id;

        /**
         * @dev The amount of tokens locked
         */
        uint256 amount;

        /**
         * @dev Unix timestamp in seconds when the tokens were locked
         */
        uint256 startAt;

        /**
         * @dev Unix timestamp in seconds when the lock ends (afterwards they can be redeemed)
         */
        uint256 endAt;

        /**
         * @dev The amount of tokens already claimed as rewards
         */
        uint256 rewardClaimed;

        /**
         * @dev The total amount of tokens rewarded
         */
        uint256 totalReward;

        /**
         * @dev The APR on the position in percent
         */
        uint16 apr;
    }

    /**
     * @dev Event emitted when a locked stake is created by someone
     * @param from The address that staked
     * @param stake The stake that was created
     */
    event LockedStakeCreated(address indexed from, LockedStake stake);

    /**
     * @dev Event emitted when someone claims the reward of a locked stake
     * @param from The address that claimed
     * @param id The identifier of the position
     * @param reward The reward paid out
     */
    event RewardClaimed(address indexed from, uint256 id, uint256 reward);

    /**
     * @dev Event emitted when someone redeems a locked stake that has expired
     * @param from The address that redeemed
     * @param id The identifier of the position
     */
    event LockedStakeRedeemed(address indexed from, uint256 id);

    /**
     * @dev Sequence storing the ids for locked stakes to be able to uniquely identify them.
     */
    uint256 private idSequence;

    /**
     * @dev Mapping of addresses to the created locked stakes of that address
     */
    mapping(address => LockedStake[]) public lockedStakes;

    /**
     * @dev Configuration to create a locked stake. Users have to chose a configuration when
     * creating a locked stake.
     */
    struct LockedStakeConfig {
        /**
         * @dev The APR in percent for this config
         */
        uint16 apr;

        /**
         * @dev The amount of days the tokens stay locked when using this config
         */
        uint16 amountDays;
    }

    /**
     * @dev Sequence to create ids of locked stake configs.
     */
    uint256 private lockedStakeConfigIdSequence = 0;

    /**
     * @dev Stores the actual locked stake configurations.
     */
    mapping(uint256 => LockedStakeConfig) private lockedStakeConfigs;

    /**
     * @dev The identifiers of the available LockedStakeConfig stored in lockedStakeConfigs. Used
     *  so we can have O(1) access to the config when creating a locked stake.
     */
    uint256[] private configIds;

    /**
     * @param _token The address of the token that can be staked
     * @param _newOwner An address that will be set as the owner of the smart contract.
     */
    constructor(address _token, address _newOwner) Ownable() Pausable() {
        require(_token != address(0), "Token address must not be 0");
        token = IERC20(_token);
        require(_newOwner != address(0), "New owner must not be 0");
        _transferOwnership(_newOwner);
        rewardPool = 0;
        idSequence = 0;
    }

    /**
     * @dev Pause the smart contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the smart contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Create a new locked stake configuration available to users
     * @param apr The APR for the new position in percent
     * @param amountDays The amount of days of the locking period for the new config
     * @return configId The identifier of the new config
     */
    function createLockedConfig(
        uint16 apr, uint16 amountDays
    ) external onlyOwner()returns (uint256 configId) {
        require(apr > 0, "APR must be greater than 0");
        require(amountDays > 0, "amountDays must be greater than 0");
        configId = lockedStakeConfigIdSequence++;
        LockedStakeConfig storage config = lockedStakeConfigs[configId];
        config.apr = apr;
        config.amountDays = amountDays;
        configIds.push(configId);
    }

    /**
     * @dev Remove a lock configuration by its id. Users won't be able to create new locked stakes
     *  with that config anymore.
     * @param configId The id of the configuration to remove
     */
    function removeLockConfig(uint256 configId) external onlyOwner() {
        // Example:
        // configIds = [0, 1, 2, 3], delete 1
        // Index to delete = 1. Copy last id to index to delete
        // configIds = [0, 3, 2, 3]
        // Pop last entry
        // configIds = [0, 3, 2]

        // Find the index of the config id to remove in the array.
        for (uint256 i = 0; i < configIds.length; i++) {
            if (configIds[i] == configId) {
                // Copy the last config id to the index of the deleted id
                configIds[i] = configIds[configIds.length - 1];
                // Reduce the array length by 1
                configIds.pop();
                // Stop here, only one config id to delete
                break;
            }
        }
        // Remove the actual config data
        delete lockedStakeConfigs[configId];
    }

    /**
     * @dev View struct of LockedStakeConfig that includes the id
     */
    struct LockedStakeConfigView {
        /**
         * @dev The identifier of the config id required for lockTokens
         */
        uint256 id;
        /**
         * @dev The APR in percent
         */
        uint16 apr;
        /**
         * @dev The amount of days the tokens stay locked when using this config
         */
        uint16 amountDays;
    }

    /**
     * @dev Get all available locked staking configurations
     * @return configs All configurations that can be used to create locked stakes
     */
    function getLockedStakeConfigs() external view returns (LockedStakeConfigView[] memory configs) {
        configs = new LockedStakeConfigView[](configIds.length);
        for (uint256 i = 0; i < configIds.length; i++) {
            uint256 configId = configIds[i];
            LockedStakeConfig memory config = lockedStakeConfigs[configId];
            LockedStakeConfigView memory configView = LockedStakeConfigView(configId,
                config.apr, config.amountDays);
            configs[i] = configView;
        }
        return configs;
    }

    /**
     * @dev Add tokens to the reward pool. Requires ERC20 approval of the $WOMBAT token to this
     * smart contract beforehand.
     */
    function chargeRewardPool(uint256 amount) external {
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        rewardPool += amount;
    }

    /**
     * @dev Remove tokens from the reward pool. Can only be called by the owner.
     * @param amount The amount of tokens to remove
     * @param to The address to transfer the tokens to
     */
    function drainRewardPool(uint256 amount, address to) external onlyOwner {
        require(amount <= rewardPool, "Pool too small");
        require(token.transfer(to, amount), "Token transfer failed");
        rewardPool -= amount;
    }

    /**
     * @dev Create a locked position. Requires ERC20 approval of the $WOMBAT token to this smart
     * contract beforehand.
     * Tokens in a locked position can be released after a certain amount of days, gaining APR
     * during that time. The so-far accumulated reward can be claimed in between as well.
     * @param configId The LockedStakeConfig to create the lock with
     * @param amount The amount of tokens to lock.
     */
    function lockTokens(uint256 configId, uint256 amount) external whenNotPaused {
        LockedStakeConfig memory config = lockedStakeConfigs[configId];
        require(config.apr > 0, "Config does not exist");
        require(amount > 0, "Must stake more than 0");
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        uint256 startAt = block.timestamp;
        uint256 endAt = startAt + config.amountDays * SECONDS_DAY;
        LockedStake memory stake = LockedStake(idSequence, amount, startAt, endAt, 0, 0, config.apr);
        // Increase the id sequence for the next locked stake created
        idSequence = idSequence + 1;
        uint256 reward = calculateReward(stake, endAt);
        stake.totalReward = reward;
        require(rewardPool >= reward, "Not enough tokens in reward pool");
        rewardPool -= reward;
        lockedStakes[msg.sender].push(stake);
        emit LockedStakeCreated(msg.sender, stake);
    }

    /**
     * @dev Get the locked stakes of an address
     *  This is required to get all locked stakes of an address as the generated accessor for
     *  lockedStakes includes the array index.
     * @param owner The address to get the locked stakes for
     * @return All non-redeemed locked stakes for the given address
     */
    function getLockedStakes(address owner) external view returns (LockedStake[] memory) {
        return lockedStakes[owner];
    }

    /**
     * @dev Claim the so-far accumulated reward of a locked position.
     * @param index The index of the locked position in the array of locked stakes for the message
     * sender
     */
    function claimReward(uint256 index) external whenNotPaused {
        LockedStake[] storage stakes = lockedStakes[msg.sender];
        require(index < stakes.length, "Index does not exist");
        LockedStake storage stake = stakes[index];
        uint256 payout = calculatePayout(stake, block.timestamp);
        if (payout > 0) {
            require(token.transfer(msg.sender, payout), "Token transfer failed");
            stake.rewardClaimed += payout;
            emit RewardClaimed(msg.sender, stake.id, payout);
        }
    }

    /**
     * @dev Calculate the payout for a locked position
     * @param from The address to calculate the payout for
     * @param index The index of the locked position in the array of locked stakes for the message
     * sender
     * @param timestamp The timestamp for which to calculate the payout.
     * @return The payout that can be claimed at the given timestamp
     */
    function calculatePayout(
        address from, uint256 index, uint256 timestamp
    ) external view returns (uint256) {
        LockedStake[] memory stakes = lockedStakes[from];
        if (index >= stakes.length) {
            // Don't fail but just return 0 if the stake does not exist
            return 0;
        }
        LockedStake memory stake = stakes[index];
        return calculatePayout(stake, timestamp);
    }

    /**
     * @dev Redeem a locked position. This is only possible after it has expired. It will transfer
     * the initial investment plus any outstanding reward back to the owner.
     * @param index The index of the locked position in the array of locked stakes for the message
     * sender
     */
    function redeemLocked(uint256 index) external whenNotPaused {
        LockedStake[] storage stakes = lockedStakes[msg.sender];
        require(index < stakes.length, "Index does not exist");
        LockedStake storage stake = stakes[index];
        require(stake.endAt <= block.timestamp, "Not redeemable yet");
        uint256 remainingReward = stake.totalReward - stake.rewardClaimed;
        uint256 totalAmount = stake.amount + remainingReward;
        require(token.transfer(msg.sender, totalAmount), "Token transfer failed");
        emit LockedStakeRedeemed(msg.sender, stake.id);

        // Delete locked stake from array
        if (stakes.length == 1) {
            stakes.pop();
        } else {
            stakes[index] = stakes[stakes.length - 1];
            stakes.pop();
        }
    }

    /**
     * @dev Calculate the payout for a locked position at a given timestamp. Already paid out
     * rewards are taken into account.
     * @param stake The position to calculate the payout for
     * @param _now The timestamp to calculate the reward for
     * @return payout The payout that can be claimed at the given timestamp
     */
    function calculatePayout(
        LockedStake memory stake, uint256 _now
    ) private pure returns (uint256 payout) {
        // Get the end timestamp. This must be "now" during the locking period, but be capped
        // at the end date (otherwise we'd pay out too much after the end).
        uint256 end = Math.min(stake.endAt, _now);
        uint256 reward = calculateReward(stake, end);
        payout = reward - stake.rewardClaimed;
    }

    /**
     * @dev Calculate the reward for a locked position. Already paid out rewards are not taken into
     * account.
     * @param stake The position to calculate the payout for
     * @param _now The timestamp to calculate the reward for
     * @return reward The total accumulated reward at the given timestamp
     */
    function calculateReward(
        LockedStake memory stake, uint256 _now
    ) private pure returns (uint256 reward) {
        uint256 elapsed = _now - stake.startAt;
        reward = (stake.amount * stake.apr * elapsed) / (100 * SECONDS_YEAR);
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}