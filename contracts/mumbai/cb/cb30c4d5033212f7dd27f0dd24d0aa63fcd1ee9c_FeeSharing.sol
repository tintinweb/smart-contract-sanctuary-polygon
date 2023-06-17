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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title FeeSharing
 *
 * @dev
 *  A contract for sharing the platform fees (in native token) in exchange for ERC-20 token staking. The lifetime of a stake is divided into three periods:
 *      1. Waiting
 *      2. Epoch-based staking period
 *      3. Non-epoch based staking
 *  The waiting period lasts from the stake registration until the start of the next epoch, E.g. if the stake is deployed at 9pm, and new epochs start everyday at midnight, this period would last 3 hours.
 *      No reward is accumulated during this period and the stake can be withdrawn for free.
 *  The epoch-based staking lasts for a period of time declared during the deposit. The declared period must be a multiple of one epoch length. During this period the reward for a given stake accumulates up
 *      until the period ends, after which it can be harvested. Canceling the stake before the period ends can be done only on the expense of losing all accumulated rewards.
 *      Reward coefficients in this stage are dependent on period lengths and determined by the `stakeLengthToWeightCoeff` mapping.
 *  The non-epoch based staking starts automatically after the previous period ends. This time all the received rewards are immediately available for harvest. Stake can be withdrawn at any time, retaining all
 *      accumulated rewards. Reward coefficient in this stage is the same for all stakes: `matureStakeWeightCoeff`
 */

contract FeeSharing is Ownable, ReentrancyGuard {
    event Withdrawal(address indexed staker, uint256 indexed id);
    event Deposit(address indexed staker, uint256 indexed id, uint256 amount, uint48 epochStart, uint48 epochEnd);
    event Cancellation(address indexed staker, uint256 indexed id);
    event ConfigAdded(uint256 length, uint256 weightCoeff);
    event ConfigRemoved(uint256 length, uint256 weightCoeff);

    IERC20 public baseToken;

    // params for epoch staking
    uint256 public currentEpochReward;
    uint256 public totalWeights;
    uint256 public waitingWeights;

    // params for non-epoch mature staking
    uint256 public matureWeights;
    uint256 public matureRewardPerShareCumulated;

    // general params
    uint256 public matureStakeWeightCoeff;
    mapping(uint256 => uint256) public stakeLengthToWeightCoeff;
    uint256 public constant EPOCH_LENGTH = 1 days;
    uint256 public constant WEIGHT_PRECISION_COEFF = 1e15;

    struct Stake {
        uint256 weightMature;
        uint256 weight;
        uint256 amount;
        uint256 paidReward;
        address staker;
        uint48 startEpoch;
        uint48 endEpoch;
    }
    // main mapping holding all the stakes

    mapping(uint256 => Stake) public stakes;

    // sums of stake weights of various categories in specific epochs
    mapping(uint256 => uint256) private stakingEpochsRewardPerShareCumulated;
    mapping(uint256 => uint256) private stakingEpochsMatureRewardPerShareCumulated;
    mapping(uint256 => uint256) private stakingEpochsEndingStakesWeight;
    mapping(uint256 => uint256) private stakingEpochsMatureStakesWeight;

    uint256 private counter;
    uint48 public startingEpoch;
    uint48 public currentEpoch;

    constructor(address token_) {
        baseToken = IERC20(token_);
        startingEpoch = _getEpoch(block.timestamp);
        matureStakeWeightCoeff = 1;
    }

    /**
     * @notice
     *   Deposit a stake. Stake is stored in stakes map under the returned id.
     *   @param staker address of stake owner, to whom all the rewards will be forwarded, and who can decide on stake withdrawal/cancelation
     *   @param length stake length expressed in seconds. Has to exist in stakeLengthToWeightCoeff mapping
     *   @param amount amount of ERC-20 tokens to stake. This contract must be approved to the declared amount. Staking will be based on the amount excluding the last `WEIGHT_PRECISION_COEFF` digits,
     *         e.g. staking 1.001 tokens will yield the same rewards as staking 1.0019 tokens.
     *   @return id id of the stake
     */
    function deposit(address staker, uint256 length, uint256 amount) external returns (uint256) {
        require(stakeLengthToWeightCoeff[length] != 0, "FeeSharing: invalid stake length");
        require(amount > 0, "FeeSharing: amount must be positive");
        updateEpochs();
        baseToken.transferFrom(msg.sender, address(this), amount);
        uint48 startEpoch = _getCurrentEpoch();
        uint48 endEpoch = startEpoch + uint48(length / EPOCH_LENGTH); // length must be checked to be a multiple of EPOCH_LENGTH, when written into stakeParams
        uint256 weight = amount * stakeLengthToWeightCoeff[length] / WEIGHT_PRECISION_COEFF;
        uint256 weightMature = amount * matureStakeWeightCoeff / WEIGHT_PRECISION_COEFF;
        stakes[++counter] = Stake(weightMature, weight, amount, 0, staker, startEpoch, endEpoch);
        waitingWeights += weight;
        stakingEpochsEndingStakesWeight[endEpoch] += weight;
        stakingEpochsMatureStakesWeight[endEpoch] += weightMature;
        emit Deposit(msg.sender, counter, amount, startEpoch, endEpoch);
        return counter;
    }

    /**
     * @notice
     *   Harvest the reward accumulated on a specified stake. Will revert if called on an immature stake (in stage 1 or 2)
     *   @param id stake id
     */
    function harvest(uint256 id) public nonReentrant {
        Stake storage stake = stakes[id];
        require(stake.endEpoch < _getCurrentEpoch(), "FeeSharing: stake not mature");
        updateEpochs();
        uint256 reward = pendingReward(id);
        if (reward > 0) {
            (bool transferSucceeded,) = payable(stake.staker).call{value: reward}("");
            require(transferSucceeded, "FeeSharing: Transaction unsuccessful");
            stake.paidReward += reward;
        }
    }

    /**
     * @notice
     *   Withdraw a mature stake and harvest the reward.
     *   @param id stake id
     */
    function withdraw(uint256 id) external {
        Stake storage stake = stakes[id];
        require(stake.staker == msg.sender, "FeeSharing: stake can be withdrawn only by the owner");
        harvest(id);
        matureWeights -= stake.weightMature;
        baseToken.transfer(stake.staker, stake.amount);
        emit Withdrawal(stake.staker, id);
        delete stakes[id];
    }

    /**
     * @notice
     *   Cancel an immature stake.
     *   @param id stake id
     */
    function cancel(uint256 id) external {
        Stake storage stake = stakes[id];
        require(stake.staker == msg.sender, "FeeSharing: stake can be cancelled only by the owner");
        require(stake.endEpoch >= _getCurrentEpoch(), "FeeSharing: trying to cancel a mature stake");
        updateEpochs();
        // epoch-based period reward
        stakingEpochsEndingStakesWeight[stake.endEpoch] -= stake.weight;
        stakingEpochsMatureStakesWeight[stake.endEpoch] -= stake.weightMature;
        if (stake.startEpoch > _getCurrentEpoch()) {
            waitingWeights -= stake.weight;
        } else {
            totalWeights -= stake.weight;
            uint256 reward = projectedReward(id);
            _distributeInflow(reward);
        }
        baseToken.transfer(stake.staker, stake.amount);
        emit Cancellation(stake.staker, id);
        delete stakes[id];
    }

    receive() external payable {
        updateEpochs();
        _distributeInflow(msg.value);
    }

    /**
     * @notice
     *   Calculate the accumulated reward ready for harvest. Does not include the accumulated reward of immature stakes in stage 2
     *   @param id stake id
     *   @return pendingReward reward ready for harvest
     */
    function pendingReward(uint256 id) public view returns (uint256) {
        Stake memory stake = stakes[id];
        // after epoch-based period reward
        uint256 reward;
        if (stake.endEpoch < _getCurrentEpoch()) {
            reward +=
                stake.weightMature * (matureRewardPerShareCumulated - _getMatureRewardPerShareCumulated(stake.endEpoch));
            reward += stake.weight
                * (_getRewardPerShareCumulated(stake.endEpoch) - _getRewardPerShareCumulated(stake.startEpoch));
        }
        return reward - stake.paidReward;
    }

    /**
     * @notice
     *   Calculate the projected reward. Includes the accumulated reward of stakes in stage 2. For stakes in stage 3 is equal to pendingReward
     *   @param id stake id
     *   @return projectedReward
     */
    function projectedReward(uint256 id) public view returns (uint256) {
        Stake memory stake = stakes[id];
        // after epoch-based period reward
        uint256 reward;
        if (stake.endEpoch < _getCurrentEpoch()) {
            reward +=
                stake.weightMature * (matureRewardPerShareCumulated - _getMatureRewardPerShareCumulated(stake.endEpoch));
            reward += stake.weight
                * (_getRewardPerShareCumulated(stake.endEpoch) - _getRewardPerShareCumulated(stake.startEpoch));
        } else if (stake.startEpoch <= _getCurrentEpoch()) {
            reward += stake.weight
                * (_getRewardPerShareCumulated(_getCurrentEpoch()) - _getRewardPerShareCumulated(stake.startEpoch));
            if (totalWeights > 0) reward += stake.weight * currentEpochReward / totalWeights;
        } else {
            return 0;
        }
        return reward - stake.paidReward;
    }

    /**
     * @dev
     *   Update the state on epoch change. Close the past epochs.
     */
    function updateEpochs() public {
        uint48 newCurrentEpoch = _getCurrentEpoch();
        if (newCurrentEpoch == currentEpoch) {
            return;
        }

        if (totalWeights > 0 && currentEpochReward > 0) {
            uint256 newRewardsPerShareCumulated =
                _getRewardPerShareCumulated(_getPreviousEpoch(currentEpoch)) + currentEpochReward / totalWeights;
            stakingEpochsRewardPerShareCumulated[currentEpoch] = newRewardsPerShareCumulated;
            currentEpochReward = 0;
        }

        uint256 endingStakeWeights;
        uint256 matureStakeWeights;
        for (uint48 epoch = currentEpoch; epoch < newCurrentEpoch; epoch++) {
            endingStakeWeights += stakingEpochsEndingStakesWeight[epoch];
            matureStakeWeights += stakingEpochsMatureStakesWeight[epoch];
        }

        stakingEpochsMatureRewardPerShareCumulated[currentEpoch] = matureRewardPerShareCumulated; // save starting rpsc for stakes maturing in this period

        totalWeights += waitingWeights;
        totalWeights -= endingStakeWeights;
        matureWeights += matureStakeWeights;
        currentEpoch = newCurrentEpoch;
        waitingWeights = 0;
    }

    /**
     * @dev
     *   Distribute the inflowing fee between the pools for epoch-based staking and non-epoch based staking.
     */
    function _distributeInflow(uint256 amount) internal {
        if ((matureWeights) > 0) {
            uint256 amountForEpochs = amount * totalWeights / (totalWeights + matureWeights);
            currentEpochReward += amountForEpochs;
            matureRewardPerShareCumulated += (amount - amountForEpochs) / matureWeights;
        } else {
            currentEpochReward += amount;
        }
    }

    function _getRewardPerShareCumulated(uint48 epoch) internal view returns (uint256) {
        uint256 rpsc = stakingEpochsRewardPerShareCumulated[uint256(epoch)];
        if (rpsc == 0) {
            while (epoch > startingEpoch) {
                epoch = _getPreviousEpoch(epoch);
                rpsc = stakingEpochsRewardPerShareCumulated[uint256(epoch)];
                if (rpsc == 0) continue;
                return rpsc;
            }
        }
        return rpsc;
    }

    function _getMatureRewardPerShareCumulated(uint48 epoch) internal view returns (uint256) {
        uint256 rpsc = stakingEpochsMatureRewardPerShareCumulated[uint256(epoch)];
        if (rpsc == 0) {
            while (epoch > startingEpoch) {
                epoch = _getPreviousEpoch(epoch);
                rpsc = stakingEpochsMatureRewardPerShareCumulated[uint256(epoch)];
                if (rpsc == 0) continue;
                return rpsc;
            }
        }
        return rpsc;
    }

    function _getCurrentEpoch() internal view returns (uint48) {
        return _getEpoch(block.timestamp);
    }

    function _getNextEpoch(uint256 timestamp) internal pure returns (uint48) {
        return _getEpoch(timestamp) + 1;
    }

    function _getEpoch(uint256 timestamp) internal pure returns (uint48) {
        return uint48(timestamp / EPOCH_LENGTH);
    }

    function _getPreviousEpoch(uint48 epoch) internal pure returns (uint48) {
        return epoch - 1;
    }

    /**
     * @notice
     *   Add the new staking length option with a specified weight. Can also be used for modifying an existing option.
     *   @param length stake length, must be a multiple of `EPOCH_LENGTH`
     *   @param coeff weight coefficient
     */
    function addStakeLengthToWeightCoeffEntry(uint256 length, uint256 coeff) external onlyOwner {
        require(
            length > 0 && length % EPOCH_LENGTH == 0, "FeeSharing: length must be a positive multiple of epoch length"
        );
        require(coeff > 0, "FeeSharing: coeff must be positive.");
        stakeLengthToWeightCoeff[length] = coeff;
        emit ConfigAdded(length, coeff);
    }

    /**
     * @notice
     *   Remove an existing staking length option
     */
    function removeStakeLengthToWeightCoeffEntry(uint256 length) external onlyOwner {
        emit ConfigRemoved(length, stakeLengthToWeightCoeff[length]);
        delete stakeLengthToWeightCoeff[length];
    }

    /**
     * @notice
     *   Set weight coefficient for stakes in stage 3
     */
    function setMatureStakeWeightCoeff(uint256 coeff) external onlyOwner {
        require(coeff > 0, "FeeSharing: coeff must be positive.");
        matureStakeWeightCoeff = coeff;
    }
}