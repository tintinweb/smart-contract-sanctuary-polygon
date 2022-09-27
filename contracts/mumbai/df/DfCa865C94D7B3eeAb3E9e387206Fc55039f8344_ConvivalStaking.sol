// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./interfaces/IERC20Mintable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./pancake-swap/libraries/TransferHelper.sol";

contract ConvivalStaking is Ownable {
    uint256 internal constant WEIGHT_MULTIPLIER = 1e6;
    uint256 internal constant MIN_STAKE_PERIOD = 30 days;
    uint256 internal constant MAX_STAKE_PERIOD = 365 days;
    uint256 internal constant REWARD_PER_WEIGHT_MULTIPLIER = 1e20;
    uint256 internal constant YIELD_STAKE_WEIGHT_MULTIPLIER = 2 * 1e6;
    uint256 internal constant DECREASE_PERCENT = 97;
    uint256 internal constant DENOMINATOR = 100;

    address public immutable CVL;
    address public immutable lpCVL;
    uint256 public immutable START;

    uint256 public cvlPerSecond;
    uint256 public totalAllocPoint;
    uint64 public endTime;

    PoolInfo[] public poolInfo;

    EpochInfo public epochInfo;

    mapping(address => uint256[]) public tokenToPid;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    struct Data {
        uint256 value;
        uint64 lockedFrom;
        uint64 lockedUntil;
        bool isYield;
    }

    struct UserInfo {
        uint128 pendingYield;
        uint248 totalWeight;
        uint256 yieldRewardsPerWeightPaid;
        Data[] stakes;
    }

    struct PoolInfo {
        address token;
        uint256 allocPoint;
        uint256 lastRewardTime;
        uint256 accPerShare;
        uint256 totalWeight;
        uint256 totalStaked;
        bool isFlash;
    }

    struct EpochInfo {
        uint64 duration;
        uint64 lastUpdate;
    }

    struct UnstakeParameter {
        uint256 stakeId;
        uint256 value;
    }

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event MultipleWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        bool isYield
    );
    event ClaimRewards(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event EpochUpdated(uint256 time, uint256 currentRewardPerSecond);
    event PoolAdded(uint256 pid, address token, uint256 allocPoint);
    event PoolUpdated(uint256 pid, address token, uint256 allocPoint);

    constructor(
        address _cvl,
        address _lpcvl,
        uint256 _cvlPerSecond,
        uint256 _cvlAllocPoint,
        uint256 _lpcvlAllocPoint,
        uint256 _start,
        uint64 _epochDuration,
        uint64 _endTime
    ) {
        require(
            _cvl != address(0) && _lpcvl != address(0),
            "Convival: zero addresses"
        );
        require(_start >= block.timestamp, "Convival: wrong start");
        require(_epochDuration > 0, "Convival: zero epoch duration");
        require(_endTime > block.timestamp, "Convival: wrong end time");
        CVL = _cvl;
        lpCVL = _lpcvl;
        START = _start;
        cvlPerSecond = _cvlPerSecond;
        endTime = _endTime;

        poolInfo.push(
            PoolInfo({
                token: _cvl,
                allocPoint: _cvlAllocPoint,
                lastRewardTime: START,
                accPerShare: 0,
                totalWeight: 0,
                totalStaked: 0,
                isFlash: false
            })
        );
        poolInfo.push(
            PoolInfo({
                token: _lpcvl,
                allocPoint: _lpcvlAllocPoint,
                lastRewardTime: START,
                accPerShare: 0,
                totalWeight: 0,
                totalStaked: 0,
                isFlash: false
            })
        );

        epochInfo = EpochInfo({
            duration: _epochDuration,
            lastUpdate: uint64(_start)
        });

        tokenToPid[_cvl].push(0);
        tokenToPid[_lpcvl].push(1);

        totalAllocPoint = _cvlAllocPoint + _lpcvlAllocPoint;
    }

    modifier poolExist(uint256 _pid) {
        require(_pid < poolInfo.length, "Convival: wrong pool ID");
        _;
    }

    /** @dev View function to see pending CVLs
     * @param _pid pool ID
     * @param _user address
     * @return user's CVL rewards
     */
    function pendingCVL(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accPerShare = pool.accPerShare;
        if (block.timestamp > pool.lastRewardTime && pool.totalWeight > 0) {
            uint256 reward;
            if (shouldUpdateEpoch()) {
                uint256 iterations = (block.timestamp > endTime)
                    ? (endTime - epochInfo.lastUpdate) / epochInfo.duration
                    : (block.timestamp - epochInfo.lastUpdate) /
                        epochInfo.duration;
                uint64 until = epochInfo.lastUpdate +
                    uint64(epochInfo.duration * iterations);
                uint256 currentRPS = cvlPerSecond;
                for (uint256 i; i < iterations; i++) {
                    if (i == 0)
                        reward += (pool.allocPoint == 0)
                            ? 0
                            : ((epochInfo.lastUpdate +
                                epochInfo.duration -
                                pool.lastRewardTime) *
                                currentRPS *
                                pool.allocPoint) / totalAllocPoint;
                    else
                        reward += (pool.allocPoint == 0)
                            ? 0
                            : (epochInfo.duration *
                                currentRPS *
                                pool.allocPoint) / totalAllocPoint;
                    currentRPS = (currentRPS * DECREASE_PERCENT) / DENOMINATOR;
                }
                if (until != block.timestamp && until != endTime) {
                    uint256 rightBoarder = (block.timestamp > endTime)
                        ? endTime
                        : block.timestamp;
                    reward += (pool.allocPoint == 0)
                        ? 0
                        : ((rightBoarder - until) *
                            currentRPS *
                            pool.allocPoint) / totalAllocPoint;
                }
                accPerShare +=
                    (reward * REWARD_PER_WEIGHT_MULTIPLIER) /
                    pool.totalWeight;
            } else {
                uint256 multiplier = (block.timestamp > endTime)
                    ? endTime - pool.lastRewardTime
                    : block.timestamp - pool.lastRewardTime;
                reward = (pool.allocPoint == 0)
                    ? 0
                    : (multiplier * cvlPerSecond * pool.allocPoint) /
                        totalAllocPoint;
                accPerShare +=
                    (reward * REWARD_PER_WEIGHT_MULTIPLIER) /
                    pool.totalWeight;
            }
        }
        return
            (user.totalWeight *
                (accPerShare - user.yieldRewardsPerWeightPaid)) /
            REWARD_PER_WEIGHT_MULTIPLIER +
            user.pendingYield;
    }

    /** @dev View functioin to see current epoch number
     * @return current epoch number
     */
    function currentEpoch() external view returns (uint256) {
        if (block.timestamp < START) return 0;
        else return (block.timestamp - START) / epochInfo.duration + 1;
    }

    /** @dev View functioin to see should update or not
     * @return true - should update / false - shouldn't update
     */
    function shouldUpdateEpoch() public view returns (bool) {
        if (epochInfo.lastUpdate + epochInfo.duration >= endTime) return false;
        if (epochInfo.lastUpdate + epochInfo.duration < block.timestamp)
            return true;
        else return false;
    }

    /** @dev View function to see weight amount according to the staked value and lock duration
     * @param value staked value
     * @param duration lock duration
     * @return weight
     */
    function valueToWeight(uint256 value, uint256 duration)
        public
        pure
        returns (uint256)
    {
        return
            value *
            ((duration * WEIGHT_MULTIPLIER) /
                MAX_STAKE_PERIOD +
                WEIGHT_MULTIPLIER);
    }

    /** @dev View function to see total pools number
     * @return total staking pool amount
     */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /** @dev View function to see all user's stakes at the current pool
     * @param user address
     * @param pid pool ID
     * @return all user's stakes info at the current pool
     */
    function getUserStakes(address user, uint256 pid)
        external
        view
        returns (Data[] memory)
    {
        return userInfo[pid][user].stakes;
    }

    /** @dev Function to add new stalking pool
     * @notice available for owner only
     * @param _poolToken staked token
     * @param _allocPoint new pool wight
     * @param _withUpdate should update accPerShare of others pools
     */
    function addPool(
        address _poolToken,
        uint256 _allocPoint,
        bool _withUpdate
    ) external onlyOwner {
        require(
            _poolToken != address(0) && _allocPoint > 0,
            "Convival: wrong params"
        );
        if (_withUpdate) {
            _updateEpoch();
        }
        tokenToPid[_poolToken].push(poolInfo.length);
        poolInfo.push(
            PoolInfo({
                token: _poolToken,
                allocPoint: _allocPoint,
                lastRewardTime: block.timestamp > START
                    ? block.timestamp
                    : START,
                accPerShare: 0,
                totalWeight: 0,
                totalStaked: 0,
                isFlash: true
            })
        );
        totalAllocPoint += _allocPoint;

        emit PoolAdded(poolInfo.length - 1, _poolToken, _allocPoint);
    }

    /** @dev Function to change pool weight (its possible to close pool by setting 0 allocation)
     * @notice available for owner only
     * @param _pid pool ID
     * @param _allocPoint new pool wight
     * @param _withUpdate should update accPerShare of existed pools
     */
    function setAllocPoint(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external onlyOwner poolExist(_pid) {
        if (_withUpdate) {
            _updateEpoch();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        totalAllocPoint = totalAllocPoint - prevAllocPoint + _allocPoint;

        emit PoolUpdated(_pid, poolInfo[_pid].token, _allocPoint);
    }

    /** @dev Function to change global end time
     * @notice available for owner only
     * @param _newValue new end time value
     * @param _withUpdate should update accPerShare of existed pools
     */
    function setEndTime(uint64 _newValue, bool _withUpdate) external onlyOwner {
        require(
            _newValue > block.timestamp &&
                _newValue > START &&
                endTime > block.timestamp &&
                _newValue != endTime,
            "Convival: wrong value"
        );

        if (_withUpdate) {
            _updateEpoch();
        }
        endTime = _newValue;
    }

    /** @dev Function to update epoch (if necessary) || update accPerShare of existed pools
     */
    function update() external {
        _updateEpoch();
    }

    /** @dev Function to update (increase) staking lock duration
     * @param _pid pool ID
     * @param _stakeId stake ID
     * @param _lockedUntil new locked intel value
     */
    function updateStakeLock(
        uint256 _pid,
        uint256 _stakeId,
        uint64 _lockedUntil
    ) external poolExist(_pid) {
        require(poolInfo[_pid].isFlash, "Convival: pool is not flash");
        UserInfo storage user = userInfo[_pid][_msgSender()];
        require(_stakeId < user.stakes.length, "Convival: wrong stake ID");
        Data storage userStake = user.stakes[_stakeId];
        require(
            userStake.lockedUntil < _lockedUntil &&
                _lockedUntil > block.timestamp,
            "Convival: wrong new value 1"
        );

        if (shouldUpdateEpoch()) _updateEpoch();
        else _updatePool(_pid, uint64(block.timestamp));

        _updateUserReward(user, _pid);

        uint128 prevWeight = uint128(
            valueToWeight(
                userStake.value,
                userStake.lockedUntil - userStake.lockedFrom
            )
        );

        if (userStake.lockedFrom == 0) {
            require(
                _lockedUntil - block.timestamp <= MAX_STAKE_PERIOD,
                "Convival: wrong new value 2"
            );
            userStake.lockedFrom = uint64(block.timestamp);
        } else {
            require(
                _lockedUntil - userStake.lockedFrom <= MAX_STAKE_PERIOD,
                "Convival: wrong new value 2"
            );
        }

        uint128 newWeight = uint128(
            valueToWeight(userStake.value, _lockedUntil - userStake.lockedFrom)
        );
        userStake.lockedUntil = _lockedUntil;
        user.totalWeight += (newWeight - prevWeight);
        poolInfo[_pid].totalWeight += (newWeight - prevWeight);
    }

    /** @dev Function to stake
     * @param _pid pool ID
     * @param _duration staking lock duration
     * @param _amount staked amount
     */
    function deposit(
        uint256 _pid,
        uint256 _duration,
        uint256 _amount
    ) external poolExist(_pid) {
        require(_amount > 0, "Convival: zero amount");

        UserInfo storage user = userInfo[_pid][_msgSender()];
        PoolInfo storage pool = poolInfo[_pid];
        uint64 lockedFrom;
        uint64 lockedUntil;
        if (pool.isFlash) {
            require(_duration <= MAX_STAKE_PERIOD, "Convival: wrong duration");
            if (_duration > 0) {
                lockedFrom = uint64(block.timestamp);
                lockedUntil = uint64(block.timestamp + _duration);
            }
        } else {
            require(
                _duration >= MIN_STAKE_PERIOD && _duration <= MAX_STAKE_PERIOD,
                "Convival: wrong duration"
            );
            lockedFrom = uint64(block.timestamp);
            lockedUntil = uint64(block.timestamp + _duration);
        }
        if (shouldUpdateEpoch()) _updateEpoch();
        else _updatePool(_pid, uint64(block.timestamp));

        _updateUserReward(user, _pid);

        uint256 stakeWeight = valueToWeight(_amount, _duration);
        require(stakeWeight > 0, "Convival: wrong weight");

        Data memory userStake = Data({
            value: _amount,
            lockedFrom: lockedFrom,
            lockedUntil: lockedUntil,
            isYield: false
        });
        user.stakes.push(userStake);
        user.totalWeight += uint248(stakeWeight);
        pool.totalWeight += stakeWeight;
        pool.totalStaked += _amount;

        TransferHelper.safeTransferFrom(
            pool.token,
            _msgSender(),
            address(this),
            _amount
        );

        emit Deposit(_msgSender(), _pid, _amount);
    }

    /** @dev Function to unstake
     * @param _pid pool ID
     * @param _param stake ID and amount to unstake
     */
    function unstake(uint256 _pid, UnstakeParameter memory _param)
        external
        poolExist(_pid)
    {
        UserInfo storage user = userInfo[_pid][_msgSender()];
        require(
            _param.stakeId < user.stakes.length,
            "Convival: wrong stake ID"
        );
        Data memory userStake = user.stakes[_param.stakeId];
        require(
            userStake.lockedUntil <= block.timestamp,
            "Convival: early unstake"
        );
        require(
            _param.value > 0 && _param.value <= userStake.value,
            "Convival: wrong amount"
        );

        if (shouldUpdateEpoch()) _updateEpoch();
        else _updatePool(_pid, uint64(block.timestamp));

        _updateUserReward(user, _pid);

        uint128 prevWeight = uint128(
            valueToWeight(
                userStake.value,
                userStake.lockedUntil - userStake.lockedFrom
            )
        );
        uint128 newWeight = uint128(
            valueToWeight(
                userStake.value - _param.value,
                userStake.lockedUntil - userStake.lockedFrom
            )
        );
        if (newWeight == 0) {
            _removeUserStake(_msgSender(), _pid, _param.stakeId);
        } else {
            user.stakes[_param.stakeId].value -= _param.value;
        }
        user.totalWeight -= (prevWeight - newWeight);
        poolInfo[_pid].totalWeight -= (prevWeight - newWeight);
        poolInfo[_pid].totalStaked -= _param.value;

        if (userStake.isYield) {
            IERC20Mintable(CVL).mint(_msgSender(), _param.value);
        } else {
            TransferHelper.safeTransfer(
                poolInfo[_pid].token,
                _msgSender(),
                _param.value
            );
        }

        emit Withdraw(_msgSender(), _pid, _param.value);
    }

    /** @dev Function to unstake several stakes from one pool with the same "yield" status
     * @param _params array of stake IDs and amounts to unstake
     * @param _pid pool ID
     */
    function unstakeMultiple(UnstakeParameter[] memory _params, uint256 _pid)
        external
        poolExist(_pid)
    {
        UserInfo storage user = userInfo[_pid][_msgSender()];
        require(
            user.stakes.length > 0 && _params.length > 0,
            "Convival: you're not staker"
        );

        if (shouldUpdateEpoch()) _updateEpoch();
        else _updatePool(_pid, uint64(block.timestamp));

        _updateUserReward(user, _pid);

        bool unstakingYield;
        uint256 weightToRemove;
        uint256 valueToUnstake;
        Data memory userStake;
        uint128 prevWeight;
        uint128 newWeight;
        for (uint256 i = _params.length - 1; i >= 0; i--) {
            if (i > 0)
                require(
                    _params[i].stakeId > _params[i - 1].stakeId,
                    "Convival: wrong stakeId order"
                );
            require(
                _params[i].stakeId < user.stakes.length,
                "Convival: wrong stakeId"
            );
            userStake = user.stakes[_params[i].stakeId];
            require(
                userStake.lockedUntil <= block.timestamp,
                "Convival: early unstake"
            );
            require(
                _params[i].value <= userStake.value && _params[i].value > 0,
                "Convival: wrong amount"
            );
            if (i == _params.length - 1) unstakingYield = userStake.isYield;
            else
                require(
                    userStake.isYield == unstakingYield,
                    "Convival: wrong stake type"
                );
            prevWeight = uint128(
                valueToWeight(
                    userStake.value,
                    userStake.lockedUntil - userStake.lockedFrom
                )
            );
            newWeight = uint128(
                valueToWeight(
                    userStake.value - _params[i].value,
                    userStake.lockedUntil - userStake.lockedFrom
                )
            );
            if (newWeight == 0) {
                _removeUserStake(_msgSender(), _pid, _params[i].stakeId);
            } else {
                user.stakes[_params[i].stakeId].value -= _params[i].value;
            }
            weightToRemove += prevWeight - newWeight;
            valueToUnstake += _params[i].value;
            if (i == 0) break;
        }
        user.totalWeight -= uint248(weightToRemove);
        poolInfo[_pid].totalWeight -= weightToRemove;
        poolInfo[_pid].totalStaked -= valueToUnstake;

        if (unstakingYield) {
            IERC20Mintable(CVL).mint(_msgSender(), valueToUnstake);
        } else {
            TransferHelper.safeTransfer(
                poolInfo[_pid].token,
                _msgSender(),
                valueToUnstake
            );
        }

        emit MultipleWithdraw(
            _msgSender(),
            _pid,
            valueToUnstake,
            unstakingYield
        );
    }

    /** @dev Function to move earned rewards to the vesting
     * @param _pid pool ID
     */
    function claimRewards(uint256 _pid) external poolExist(_pid) {
        _claimRewards(_pid);
    }

    /** @dev Function to move earned rewards to the vesting from several pools
     * @param _pids array of pool IDs
     */
    function claimRewardsMultiple(uint256[] memory _pids) external {
        require(
            _pids.length <= poolInfo.length,
            "Convival: wrong _pids length"
        );
        for (uint256 i; i < _pids.length; i++) {
            require(_pids[i] < poolInfo.length, "Convival: wrong pid");
            _claimRewards(_pids[i]);
        }
    }

    function _updateEpoch() internal {
        if (shouldUpdateEpoch()) {
            uint256 iterations = (block.timestamp > endTime)
                ? (endTime - epochInfo.lastUpdate) / epochInfo.duration
                : (block.timestamp - epochInfo.lastUpdate) / epochInfo.duration;
            uint64 until;
            for (uint256 i; i < iterations; i++) {
                until =
                    epochInfo.lastUpdate +
                    uint64(epochInfo.duration * (i + 1));
                _massUpdatePools(until);
                cvlPerSecond = (cvlPerSecond * DECREASE_PERCENT) / DENOMINATOR;
            }
            if (until != block.timestamp) {
                _massUpdatePools(uint64(block.timestamp));
            }
            epochInfo.lastUpdate = until;
            emit EpochUpdated(until, cvlPerSecond);
        } else {
            _massUpdatePools(uint64(block.timestamp));
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function _updatePool(uint256 _pid, uint64 _until) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (_until > endTime) _until = endTime;
        if (_until <= pool.lastRewardTime) {
            return;
        }
        if (pool.totalWeight == 0) {
            pool.lastRewardTime = _until;
            return;
        }
        uint256 multiplier = _until - pool.lastRewardTime;
        uint256 reward = (pool.allocPoint == 0)
            ? 0
            : (multiplier * cvlPerSecond * pool.allocPoint) / totalAllocPoint;
        pool.accPerShare +=
            (reward * REWARD_PER_WEIGHT_MULTIPLIER) /
            pool.totalWeight;
        pool.lastRewardTime = _until;
    }

    function _massUpdatePools(uint64 _until) internal {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updatePool(pid, _until);
        }
    }

    function _updateUserReward(UserInfo storage _user, uint256 _pid) internal {
        _user.pendingYield += uint128(
            (_user.totalWeight *
                (poolInfo[_pid].accPerShare -
                    _user.yieldRewardsPerWeightPaid)) /
                REWARD_PER_WEIGHT_MULTIPLIER
        );
        _user.yieldRewardsPerWeightPaid = poolInfo[_pid].accPerShare;
    }

    function _removeUserStake(
        address _user,
        uint256 _pid,
        uint256 _id
    ) internal {
        uint256 len = userInfo[_pid][_user].stakes.length;
        if (_id < len - 1) {
            Data memory _lastStake = userInfo[_pid][_user].stakes[len - 1];
            userInfo[_pid][_user].stakes[_id] = _lastStake;
        }
        userInfo[_pid][_user].stakes.pop();
    }

    function _claimRewards(uint256 _pid) internal {
        if (shouldUpdateEpoch()) _updateEpoch();
        else {
            _updatePool(_pid, uint64(block.timestamp));
            if (_pid > 0) _updatePool(0, uint64(block.timestamp));
        }

        UserInfo storage user = userInfo[_pid][_msgSender()];
        _updateUserReward(user, _pid);
        if (_pid > 0) _updateUserReward(userInfo[0][_msgSender()], 0);

        uint256 pendingYieldToClaim = user.pendingYield;
        if (pendingYieldToClaim == 0) return;
        user.pendingYield = 0;
        uint256 stakeWeight = pendingYieldToClaim *
            YIELD_STAKE_WEIGHT_MULTIPLIER;
        Data memory newStake = Data({
            value: pendingYieldToClaim,
            lockedFrom: uint64(block.timestamp),
            lockedUntil: uint64(block.timestamp + MAX_STAKE_PERIOD),
            isYield: true
        });
        userInfo[0][_msgSender()].stakes.push(newStake);
        userInfo[0][_msgSender()].totalWeight += uint248(stakeWeight);
        poolInfo[0].totalWeight += stakeWeight;
        poolInfo[0].totalStaked += pendingYieldToClaim; //_pid == 0 is CVL pool; reinvest yield rewards

        emit ClaimRewards(_msgSender(), _pid, pendingYieldToClaim);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Mintable is IERC20 {

    function mint(address account, uint256 amount) external;
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

pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
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