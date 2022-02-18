// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./IMechaniumStakingPoolFactory.sol";
import "./IMechaniumStakingPool.sol";
import "./MechaniumStakingPool.sol";
import "../MechaniumUtils/MechaniumCanReleaseUnintendedOwnable.sol";

/**
 * @title MechaniumStakingPoolFactory - Staking pool factory smart contract
 * @author EthernalHorizons - <https://ethernalhorizons.com/>
 * @custom:project-website  https://mechachain.io/
 * @custom:security-contact [email protected]
 */
contract MechaniumStakingPoolFactory is
    IMechaniumStakingPoolFactory,
    Ownable,
    MechaniumCanReleaseUnintendedOwnable
{
    using SafeERC20 for IERC20;

    /**
     * ========================
     *          Events
     * ========================
     */

    /**
     * @notice Event emitted when a staking pool is created
     */
    event CreatePool(
        address indexed poolAddress,
        uint256 allocatedTokens,
        uint256 initBlock,
        uint256 minStakingTime,
        uint256 maxStakingTime,
        uint256 minWeightMultiplier,
        uint256 maxWeightMultiplier,
        uint256 rewardsLockingPeriod,
        uint256 rewardsPerBlock
    );

    /**
     * @notice Event emitted when a staking flash pool is created
     */
    event CreateFlashPool(
        address indexed poolAddress,
        uint256 allocatedTokens,
        uint256 initBlock,
        uint256 minStakingTime,
        uint256 maxStakingTime,
        uint256 minWeightMultiplier,
        uint256 maxWeightMultiplier,
        uint256 rewardsPerBlock
    );

    /**
     * @notice Event emitted when an `amount` of tokens is added to `poolAddress` token allocation
     */
    event AddAllocatedTokens(address indexed poolAddress, uint256 amount);

    /**
     * @notice Event emitted when an `amount` of tokens is added to `poolAddress` token allocation
     */
    event AddAllocatedTokens(
        address indexed poolAddress,
        uint256 amount,
        uint256 rewardsPerBlock
    );

    /**
     * @notice Event emitted when `amount` of unallocated tokens is withdrawn to an `account`
     */
    event WithdrawUnallocated(address indexed account, uint256 amount);

    /**
     * ========================
     *  Constants & Immutables
     * ========================
     */

    /// Main staking ERC20 token
    IERC20 internal immutable _token;

    /**
     * ========================
     *         Storage
     * ========================
     */

    /// List of registered staking pools
    mapping(address => bool) public registeredPools;
    address[] public registeredPoolsList;

    /**
     * ========================
     *     Public Functions
     * ========================
     */

    constructor(IERC20 token_) {
        require(address(token_) != address(0));
        _token = token_;

        _addLockedToken(address(token_));
    }

    /**
     * @notice Create new staking pool
     * @dev Deploy an instance of the StakingPool smart contract and transfer the tokens to it
     * @param allocatedTokens The number of tokens allocated for the pool
     * @param initBlock The initial block of the pool to start
     * @param minStakingTime The minimum time allowed for staking
     * @param maxStakingTime The maximum time allowed for staking
     * @param minWeightMultiplier The minimum weight multiplier
     * @param maxWeightMultiplier The maximum weight multiplier
     * @param rewardsLockingPeriod The rewards locking period
     * @param rewardsPerBlock The rewards per block
     */
    function createPool(
        uint256 allocatedTokens,
        uint32 initBlock,
        uint64 minStakingTime,
        uint64 maxStakingTime,
        uint16 minWeightMultiplier,
        uint16 maxWeightMultiplier,
        uint64 rewardsLockingPeriod,
        uint256 rewardsPerBlock
    ) public override onlyOwner returns (bool) {
        uint256 factoryBalance = _token.balanceOf(address(this));

        require(
            factoryBalance >= allocatedTokens,
            "Not enough tokens in factory"
        );

        IMechaniumStakingPool stakingPool = new MechaniumStakingPool(
            _token,
            _token,
            initBlock,
            minStakingTime,
            maxStakingTime,
            minWeightMultiplier,
            maxWeightMultiplier,
            rewardsLockingPeriod,
            rewardsPerBlock
        );

        address stakingPoolAddr = address(stakingPool);

        registeredPools[stakingPoolAddr] = true;
        registeredPoolsList.push(stakingPoolAddr);

        addAllocatedTokens(stakingPoolAddr, allocatedTokens);

        emit CreatePool(
            stakingPoolAddr,
            allocatedTokens,
            initBlock,
            minStakingTime,
            maxStakingTime,
            minWeightMultiplier,
            maxWeightMultiplier,
            rewardsLockingPeriod,
            rewardsPerBlock
        );

        return true;
    }

    /**
     * @notice Create new staking flash pool
     * @dev Deploy an instance of the StakingPool smart contract and transfer the tokens to it
     * @param allocatedTokens The number of tokens allocated for the pool
     * @param initBlock The initial block of the pool to start
     * @param minStakingTime The minimum time allowed for staking
     * @param maxStakingTime The maximum time allowed for staking
     * @param minWeightMultiplier The minimum weight multiplier
     * @param maxWeightMultiplier The maximum weight multiplier
     * @param rewardsPerBlock The rewards per block
     */
    function createFlashPool(
        IERC20 stakedToken,
        uint256 allocatedTokens,
        uint32 initBlock,
        uint64 minStakingTime,
        uint64 maxStakingTime,
        uint16 minWeightMultiplier,
        uint16 maxWeightMultiplier,
        uint256 rewardsPerBlock
    ) public override onlyOwner returns (bool) {
        uint256 factoryBalance = _token.balanceOf(address(this));

        require(
            factoryBalance >= allocatedTokens,
            "Not enough tokens in factory"
        );

        IMechaniumStakingPool stakingPool = new MechaniumStakingPool(
            stakedToken,
            _token,
            initBlock,
            minStakingTime,
            maxStakingTime,
            minWeightMultiplier,
            maxWeightMultiplier,
            0,
            rewardsPerBlock
        );

        address stakingPoolAddr = address(stakingPool);

        registeredPools[stakingPoolAddr] = true;
        registeredPoolsList.push(stakingPoolAddr);

        addAllocatedTokens(stakingPoolAddr, allocatedTokens);

        emit CreateFlashPool(
            stakingPoolAddr,
            allocatedTokens,
            initBlock,
            minStakingTime,
            maxStakingTime,
            minWeightMultiplier,
            maxWeightMultiplier,
            rewardsPerBlock
        );

        return true;
    }

    /**
     * @notice Allocate more tokens to a staking pool
     * @dev Safe transfer the tokens to the pool
     * @param poolAddr The pool address
     * @param amount The amount of tokens to allocate
     */
    function addAllocatedTokens(address poolAddr, uint256 amount)
        public
        override
        onlyOwner
        returns (bool)
    {
        require(registeredPools[poolAddr], "Staking pool not registered");

        _transferTokens(poolAddr, amount);

        emit AddAllocatedTokens(poolAddr, amount);

        return true;
    }

    /**
     * @notice Allocate more tokens to a staking pool and change the rewards per block
     * @dev Safe transfer the tokens to the pool
     * @param poolAddr The pool address
     * @param amount The amount of tokens to allocate
     * @param rewardsPerBlock The new rewards per block
     */
    function addAllocatedTokens(
        address payable poolAddr,
        uint256 amount,
        uint256 rewardsPerBlock
    ) public override onlyOwner returns (bool) {
        require(registeredPools[poolAddr], "Staking pool not registered");

        _transferTokens(poolAddr, amount);

        IMechaniumStakingPool pool = MechaniumStakingPool(poolAddr);

        pool.setRewardsPerBlock(rewardsPerBlock);

        emit AddAllocatedTokens(poolAddr, amount, rewardsPerBlock);

        return true;
    }

    /**
     * @notice Withdraw unallocated tokens
     * @param account The account that will receive the tokens
     * @param amount The amount of tokens to withdraw
     */
    function withdrawUnallocated(address account, uint256 amount)
        public
        override
        onlyOwner
        returns (bool)
    {
        _transferTokens(account, amount);

        emit WithdrawUnallocated(account, amount);

        return true;
    }

    /**
     * @notice Release unintended tokens
     * @param pool The staking pool to release from
     * @param token_ The token to release
     * @param account The account to send the tokens to
     * @param amount The amount of tokens to release
     */
    function releaseUnintendedFromPool(
        address payable pool,
        address token_,
        address account,
        uint256 amount
    ) public override onlyOwner returns (bool) {
        MechaniumStakingPool stakingPool = MechaniumStakingPool(pool);

        stakingPool.releaseUnintended(token_, account, amount);

        return true;
    }

    /**
     * ========================
     *    Private functions
     * ========================
     */

    function _transferTokens(address account, uint256 amount)
        internal
        returns (bool)
    {
        require(account != address(0), "Address must not be 0");
        require(amount > 0, "Amount must be superior to zero");

        uint256 factoryBalance = balance();

        require(factoryBalance >= amount, "Not enough tokens in factory");

        _token.safeTransfer(account, amount);

        return true;
    }

    /**
     * ========================
     *          Views
     * ========================
     */

    /**
     * @notice Get the factory ERC20 token
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @notice Get the factory ERC20 token balance
     */
    function balance() public view returns (uint256) {
        return _token.balanceOf(address(this));
    }

    /**
     * @notice Get staking pool data
     * @param poolAddr The pool address
     */
    function getPoolData(address payable poolAddr)
        public
        view
        override
        returns (PoolData memory)
    {
        require(registeredPools[poolAddr], "Pool not registered");

        MechaniumStakingPool pool = MechaniumStakingPool(poolAddr);

        uint256 poolBalance = _token.balanceOf(poolAddr);

        PoolData memory poolData = PoolData(
            poolBalance - pool.totalTokensStaked(),
            pool.initBlock(),
            pool.minStakingTime(),
            pool.maxStakingTime(),
            pool.minWeightMultiplier(),
            pool.maxWeightMultiplier(),
            pool.rewardsLockingPeriod(),
            pool.rewardsPerBlock()
        );

        return poolData;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IMechaniumCanReleaseUnintendedOwnable.sol";

/**
 * @title MechaniumCanReleaseUnintendedOwnable - Abstract class for util can release unintended tokens smart contract
 * @author EthernalHorizons - <https://ethernalhorizons.com/>
 * @custom:project-website  https://mechachain.io/
 * @custom:security-contact [email protected]
 */
abstract contract MechaniumCanReleaseUnintendedOwnable is
    Ownable,
    IMechaniumCanReleaseUnintendedOwnable
{
    using SafeERC20 for IERC20;

    /**
     * @notice Event emitted when release unintended `amount` of `token` for `account` address
     */
    event ReleaseUintentedTokens(
        address indexed token,
        address indexed account,
        uint256 amount
    );

    /// Locked tokens that can't be released for contract
    mapping(address => bool) private _lockedTokens;

    /// fallback payable function ( used to receive ETH in tests )
    fallback() external payable {}

    /// receive payable function ( used to receive ETH in tests )
    receive() external payable {}

    /**
     * @notice Add a locked `token_` ( can't be released )
     */
    function _addLockedToken(address token_) internal {
        _lockedTokens[token_] = true;
    }

    /**
     * @notice Release an `amount` of `token` to an `account`
     * This function is used to prevent unintended tokens that got sent to be stuck on the contract
     * @param token The address of the token contract (zero address for claiming native coins).
     * @param account The address of the tokens/coins receiver.
     * @param amount Amount to claim.
     */
    function releaseUnintended(
        address token,
        address account,
        uint256 amount
    ) public override onlyOwner returns (bool) {
        require(amount > 0, "Amount must be superior to zero");
        require(
            account != address(0) && account != address(this),
            "Amount must be superior to zero"
        );
        require(!_lockedTokens[token], "Token can't be released");

        if (token == address(0)) {
            require(
                address(this).balance >= amount,
                "Address: insufficient balance"
            );
            (bool success, ) = account.call{value: amount}("");
            require(
                success,
                "Address: unable to send value, recipient may have reverted"
            );
        } else {
            IERC20 customToken = IERC20(token);
            require(
                customToken.balanceOf(address(this)) >= amount,
                "Address: insufficient balance"
            );
            customToken.safeTransfer(account, amount);
        }

        emit ReleaseUintentedTokens(token, account, amount);

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @dev Mechanium can release unintended ( ownable ) smart contract interface
 * @author EthernalHorizons - <https://ethernalhorizons.com/>
 * @custom:project-website  https://mechachain.io/
 * @custom:security-contact [email protected]
 */
interface IMechaniumCanReleaseUnintendedOwnable {
    /**
     * @dev Release unintended tokens sent to smart contract ( only owner )
     * This function is used to prevent unintended tokens that got sent to be stuck on the contract
     * @param token The address of the token contract (zero address for claiming native coins).
     * @param account The address of the tokens/coins receiver.
     * @param amount Amount to claim.
     */
    function releaseUnintended(
        address token,
        address account,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./IMechaniumStakingPool.sol";
import "../MechaniumUtils/MechaniumCanReleaseUnintendedOwnable.sol";

/**
 * @title MechaniumStakingPool - Staking pool smart contract
 * @author EthernalHorizons - <https://ethernalhorizons.com/>
 * @custom:project-website  https://mechachain.io/
 * @custom:security-contact [email protected]
 */
contract MechaniumStakingPool is
    IMechaniumStakingPool,
    Ownable,
    MechaniumCanReleaseUnintendedOwnable
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /**
     * ========================
     *          Events
     * ========================
     */

    /**
     * @notice Event emitted when an `account` stakes `amount` for `lockPeriod`
     */
    event Stake(address indexed account, uint256 amount, uint64 lockPeriod);

    /**
     * @notice Event emitted when an `account` unstaked a deposit (`depositId`)
     */
    event Unstake(address indexed account, uint256 amount, uint256 depositId);

    /**
     * @notice Event emitted when an `account` unstaked several deposits (`depositIds`)
     */
    event Unstake(
        address indexed account,
        uint256 amount,
        uint256[] depositIds
    );

    /**
     * @notice Event emitted when an `account` updated stake `lockPeriod` for a `depositId`
     */
    event StakeLockUpdated(
        address indexed account,
        uint256 depositId,
        uint64 lockPeriod
    );

    /**
     * @notice Event emitted when an `rewardsPerBlock` is updated
     */
    event RewardsPerBlockChanged(uint256 rewardsPerBlock);

    /**
     * @notice Event emitted when `rewards` are processed for an `account`
     */
    event ProcessRewards(address indexed account, uint256 rewards);

    /**
     * @notice Event emitted when `_rewardsPerWeight` is updated
     */
    event RewardsPerWeightUpdated(uint256 _rewardsPerWeight);

    /**
     * ========================
     *  Constants & Immutables
     * ========================
     */

    /// ERC20 token to be staked
    IERC20 public immutable stakedToken;

    /// ERC20 token to be rewarded
    IERC20 public immutable rewardToken;

    /// Block number for staking pool start
    uint32 public immutable initBlock;

    /// Staking rewards locking period
    uint64 public immutable rewardsLockingPeriod;

    /// Minimum staking time
    uint64 public immutable minStakingTime;

    /// Maximum staking time
    uint64 public immutable maxStakingTime;

    /// Minimum weight multiplier
    uint16 public immutable minWeightMultiplier;

    /// Maximum weight multiplier
    uint16 public immutable maxWeightMultiplier;

    /// Weight multiplier ( used for floating weight )
    uint256 public immutable WEIGHT_MULTIPLIER = 1e12;

    /**
     * ========================
     *         Storage
     * ========================
     */

    /// Amount of tokens to be rewarded per block
    uint256 public rewardsPerBlock;

    /// Mapping of users addresses and User structure
    mapping(address => User) public users;

    /// Total staking weight for users
    uint256 public totalUsersWeight;

    /// Total tokens staked by users
    uint256 public totalTokensStaked;

    /// Total of processed rewards
    uint256 public totalProcessedRewards;

    /// Track the last block number of rewards update
    uint256 public lastRewardsUpdate;

    /// Total rewards at the last update, use `updatedTotalRewards` for get the last value
    uint256 internal _totalRewards;

    /// Rewards in tokens per weight at the last update, use `updatedRewardsPerWeight` for get the last value
    uint256 internal _rewardsPerWeight;

    /**
     * ========================
     *     Public Functions
     * ========================
     */

    /**
     * @notice Contract constructor sets the configuration of the staking pool
     * @param stakedToken_ The token to be staked ( can be same as rewardToken if not flash pool )
     * @param rewardToken_  The token to be rewarded
     * @param initBlock_ The init block ( if set to 0 will take the current block )
     * @param minStakingTime_ The minimum allowed locking time
     * @param maxStakingTime_ The maximum allowed locking time
     * @param minWeightMultiplier_ The minimum weight multiplier ( Used to calculate weight range )
     * @param maxWeightMultiplier_ The maximum weight multiplier ( Used to calculate weight range )
     * @param rewardsLockingPeriod_  The rewards locking period ( Can be 0 if flash pool )
     * @param rewardsPerBlock_ The amount of tokens to be rewarded per block passed
     */
    constructor(
        IERC20 stakedToken_,
        IERC20 rewardToken_,
        uint32 initBlock_,
        uint64 minStakingTime_,
        uint64 maxStakingTime_,
        uint16 minWeightMultiplier_,
        uint16 maxWeightMultiplier_,
        uint64 rewardsLockingPeriod_,
        uint256 rewardsPerBlock_
    ) {
        require(rewardsPerBlock_ > 0, "Rewards can't be null");
        require(minWeightMultiplier_ > 0, "minWeightMultiplier can't be null");
        require(
            minStakingTime_ <= maxStakingTime_,
            "minStakingTime can't be greater than maxStakingTime"
        );
        require(
            minWeightMultiplier_ <= maxWeightMultiplier_,
            "minWeightMultiplier can't be greater than maxWeightMultiplier"
        );

        /// Requirement to handle flash pools
        require(
            (address(stakedToken_) == address(rewardToken_)) ||
                rewardsLockingPeriod_ == 0,
            "Rewards locking period must be 0 for flash pools"
        );
        require(
            rewardsLockingPeriod_ == 0 ||
                rewardsLockingPeriod_ >= minStakingTime_,
            "Rewards locking period must be 0 or lower than minStakingTime"
        );
        require(
            rewardsLockingPeriod_ == 0 ||
                rewardsLockingPeriod_ <= maxStakingTime_,
            "Rewards locking period must be 0 or greater than maxStakingTime"
        );

        stakedToken = stakedToken_;
        rewardToken = rewardToken_;
        initBlock = initBlock_ == 0 ? uint32(block.number) : initBlock_;
        rewardsLockingPeriod = rewardsLockingPeriod_;
        minStakingTime = minStakingTime_;
        maxStakingTime = maxStakingTime_;
        minWeightMultiplier = minWeightMultiplier_;
        maxWeightMultiplier = maxWeightMultiplier_;
        rewardsPerBlock = rewardsPerBlock_;

        _addLockedToken(address(stakedToken_));
        _addLockedToken(address(rewardToken_));
    }

    /**
     * @notice Used to stake an `amount` of tokens for a `lockPeriod` for the `msg.sender`
     * @dev Uses the `depositFor` function
     * @param amount The amount of tokens to stake
     * @param lockPeriod The locking period ( in seconds )
     */
    function stake(uint256 amount, uint64 lockPeriod)
        public
        override
        returns (bool)
    {
        address account = msg.sender;

        depositFor(account, amount, uint256(lockPeriod));

        return true;
    }

    /**
     * @notice Used to stake an `amount` of tokens for a `lockPeriod` for an `account`
     * @dev Will make a safe transfer from the `account` and calculate the weight and create a deposit
     * @param account The account that we will stake the tokens for
     * @param amount The amount of tokens to stake
     * @param lockPeriod The locking period ( in seconds )
     */
    function depositFor(
        address account,
        uint256 amount,
        uint256 lockPeriod
    ) public override returns (bool) {
        require(account != address(0), "Address must not be 0");
        require(amount > 0, "Amount must be superior to zero");
        require(
            lockPeriod >= minStakingTime,
            "Staking time less than minimum required"
        );
        require(
            lockPeriod <= maxStakingTime,
            "Staking time greater than maximum required"
        );

        // Update rewards
        if (canUpdateRewards()) {
            updateRewards();
        }

        // Process rewards with no update to not do it twice
        _processRewards(account, false);

        stakedToken.safeTransferFrom(msg.sender, address(this), amount);

        User storage user = users[account];

        uint64 _lockPeriod = uint64(lockPeriod);

        uint256 weight = calculateUserWeight(amount, _lockPeriod);

        uint64 lockStart = uint64(block.timestamp);
        uint64 lockEnd = lockStart + _lockPeriod;

        Deposit memory deposit = Deposit({
            amount: amount,
            weight: weight,
            lockedFrom: lockStart,
            lockedUntil: lockEnd,
            isRewards: false,
            isClaimed: false
        });

        // Update user and total records
        user.deposits.push(deposit);
        _increaseUserRecords(user, amount, weight, true);

        emit Stake(account, amount, _lockPeriod);

        return true;
    }

    /**
     * @notice Used to calculate and pay pending rewards to the `msg.sender`
     *
     * @dev Automatically updates rewards before processing them
     * @dev When there are no rewards to calculate, throw error
     * @dev If `rewardsLockingPeriod` is set, rewards are staked in a new deposit,
     *      otherwise they are transmitted directly to the user (as for flash pools)
     *
     * @return userPendingRewards rewards calculated and optionally re-staked
     */
    function processRewards()
        public
        override
        returns (uint256 userPendingRewards)
    {
        userPendingRewards = _processRewards(msg.sender, true);
        require(userPendingRewards != 0, "No rewards to process");
    }

    /**
     * @notice Used to unstake several deposits for the `msg.sender`
     *
     * @dev ProcessRewards and transfer all deposits to the user
     * @dev Revert if the `lockedUntil` of a deposit has not passed
     *
     * @param depositIds Array of deposit id that will be unstaked
     */
    function unstake(uint256[] memory depositIds)
        public
        override
        returns (bool)
    {
        // Update rewards
        if (canUpdateRewards()) {
            updateRewards();
        }

        // Process rewards with no update to not do it twice
        _processRewards(msg.sender, false);

        User storage user = users[msg.sender];

        uint256 totalAmount = 0;
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < depositIds.length; i++) {
            (uint256 amount, uint256 weight) = _drainDeposit(
                user,
                depositIds[i]
            );
            totalAmount = totalAmount.add(amount);
            totalWeight = totalWeight.add(weight);
        }

        // Update user and total records
        _decreaseUserRecords(user, totalAmount, totalWeight, true);

        // Transfer tokens
        rewardToken.safeTransfer(msg.sender, totalAmount);

        emit Unstake(msg.sender, totalAmount, depositIds);
        return true;
    }

    /**
     * @notice Used to unstake a `depositId` for the `msg.sender`
     *
     * @dev ProcessRewards and transfer all the deposit to the user
     * @dev Revert if the `lockedUntil` of the deposit has not passed
     *
     * @param depositId The deposit id that will be unstaked
     */
    function unstake(uint256 depositId) public override returns (bool) {
        // Update rewards
        if (canUpdateRewards()) {
            updateRewards();
        }

        // Process rewards with no update to not do it twice
        _processRewards(msg.sender, false);

        User storage user = users[msg.sender];
        (uint256 amount, uint256 weight) = _drainDeposit(user, depositId);

        // Update user and total records
        _decreaseUserRecords(user, amount, weight, true);

        // Transfer tokens
        stakedToken.safeTransfer(msg.sender, amount);

        emit Unstake(msg.sender, amount, depositId);
        return true;
    }

    /**
     * @notice Used to update the rewards per weight and the total rewards
     * @dev Must be called before each total weight change
     */
    function updateRewards() public override returns (bool) {
        require(canUpdateRewards(), "initBlock is not reached");

        _rewardsPerWeight = updatedRewardsPerWeight();
        _totalRewards = updatedTotalRewards();

        lastRewardsUpdate = block.number;

        emit RewardsPerWeightUpdated(_rewardsPerWeight);

        return true;
    }

    /**
     * @notice Used to change the rewardsPerBlock
     *
     * @dev Will update rewards before changing the rewardsPerBlock
     * @dev Can only by call by owner (the factory if deployed by it)
     * @dev Revert if the new rewards per block is less than the previous one
     *
     * @param rewardsPerBlock_ the new value for rewardsPerBlock ( must be superior to old value )
     */
    function setRewardsPerBlock(uint256 rewardsPerBlock_)
        public
        override
        onlyOwner
        returns (bool)
    {
        require(
            rewardsPerBlock_ > rewardsPerBlock,
            "Rewards per block must be greater than the previous one"
        );

        if (canUpdateRewards()) {
            updateRewards();
        }

        rewardsPerBlock = rewardsPerBlock_;

        emit RewardsPerBlockChanged(rewardsPerBlock);

        return true;
    }

    /**
     * ========================
     *           Views
     * ========================
     */

    /**
     * @notice Used to get the remaining allocated tokens
     */
    function remainingAllocatedTokens() public view override returns (uint256) {
        uint256 balance = rewardToken.balanceOf(address(this));

        uint256 remainingTokens = balance.sub(
            totalTokensStaked.add(updatedTotalRewards()).sub(
                totalProcessedRewards
            )
        );

        return remainingTokens;
    }

    /**
     * @notice Used to get the pending rewards for an `account`
     * @param account The account to calculate the pending rewards for
     * @return the rewards that the user has but which have not been processed
     */
    function pendingRewards(address account)
        public
        view
        override
        returns (uint256)
    {
        if (block.number < initBlock || users[account].totalStaked == 0) {
            return 0;
        }

        // All rewards according to account weight
        uint256 _pendingRewards = weightToReward(
            users[account].totalWeight,
            updatedRewardsPerWeight()
        );

        // Remove rewards released before accounts allocations or that they have already been processed
        _pendingRewards = _pendingRewards.sub(users[account].missingRewards);

        return _pendingRewards;
    }

    /**
     * @notice Can we call the rewards update function or is it useless and will cause an error
     */
    function canUpdateRewards() public view override returns (bool) {
        return block.number >= initBlock;
    }

    /**
     * @notice Used to get the balance for an `account`
     * @param account The account to get the balance for
     */
    function balanceOf(address account) public view override returns (uint256) {
        User memory user = users[account];
        return user.totalStaked.add(pendingRewards(account));
    }

    /**
     * @notice Used to get the deposit (`depositId`) for an `account`
     * @param account The account to get the balance for
     * @param depositId The deposit id the get
     */
    function getDeposit(address account, uint256 depositId)
        public
        view
        override
        returns (Deposit memory)
    {
        User memory user = users[account];

        require(depositId < user.deposits.length, "Deposit does not exist");

        Deposit memory deposit = user.deposits[depositId];

        return deposit;
    }

    /**
     * @notice Used to get the length of deposits for an `account`
     * @param account The account to get the balance for
     */
    function getDepositsLength(address account)
        public
        view
        override
        returns (uint256)
    {
        User memory user = users[account];

        return user.deposits.length;
    }

    /**
     * @notice Used to get the User data for an `account`
     * @param account The account address
     */
    function getUser(address account)
        public
        view
        override
        returns (User memory)
    {
        User memory user = users[account];

        return user;
    }

    /**
     * @notice Get the updated rewards
     * @dev Used to calculate the rewards for last period ( in blocks ) without updating them
     */
    function updatedRewards() public view override returns (uint256) {
        if (block.number < initBlock) {
            return 0;
        }

        uint256 _lastRewardsUpdate = lastRewardsUpdate > 0
            ? lastRewardsUpdate
            : initBlock;

        uint256 passedBlocks = block.number.sub(_lastRewardsUpdate);

        uint256 cumulatedRewards = passedBlocks.mul(rewardsPerBlock);

        /**
         * Calculate old remaining tokens
         * Used to check if we have enough tokens to reward
         */
        uint256 balance = rewardToken.balanceOf(address(this));

        uint256 oldRemainingTokens = balance.sub(
            totalTokensStaked.add(_totalRewards).sub(totalProcessedRewards)
        );

        return
            cumulatedRewards > oldRemainingTokens
                ? oldRemainingTokens
                : cumulatedRewards;
    }

    /**
     * @notice Get the total updated rewards
     * @dev Used to calculate the rewards from the init block without updating them
     */
    function updatedTotalRewards() public view override returns (uint256) {
        uint256 _updatedTotalRewards = _totalRewards.add(updatedRewards());

        return _updatedTotalRewards;
    }

    /**
     * @notice Get the updated rewards per weight
     * @dev Used to calculate `_rewardsPerWeight` without updating them
     */
    function updatedRewardsPerWeight() public view override returns (uint256) {
        uint256 cumulatedRewards = updatedRewards();

        cumulatedRewards = cumulatedRewards.mul(WEIGHT_MULTIPLIER);

        uint256 newRewardsPerWeight = cumulatedRewards.div(totalUsersWeight);

        newRewardsPerWeight = newRewardsPerWeight.add(_rewardsPerWeight);

        return newRewardsPerWeight;
    }

    /**
     * @notice Calculate the weight based on `amount` and `stakingTime`
     * @param amount The staking amount
     * @param stakingTime The staking time
     */
    function calculateUserWeight(uint256 amount, uint64 stakingTime)
        public
        view
        override
        returns (uint256)
    {
        return
            amount
                .mul(
                    _getRange(
                        minStakingTime,
                        uint256(minWeightMultiplier).mul(WEIGHT_MULTIPLIER),
                        maxStakingTime,
                        uint256(maxWeightMultiplier).mul(WEIGHT_MULTIPLIER),
                        uint256(stakingTime)
                    )
                )
                .div(WEIGHT_MULTIPLIER);
    }

    /**
     * @dev Converts stake weight to reward value, applying the division on weight
     *
     * @param weight_ stake weight
     * @param rewardsPerWeight_ reward per weight
     * @return reward value normalized with WEIGHT_MULTIPLIER
     */
    function weightToReward(uint256 weight_, uint256 rewardsPerWeight_)
        public
        pure
        override
        returns (uint256)
    {
        return weight_.mul(rewardsPerWeight_).div(WEIGHT_MULTIPLIER);
    }

    /**
     * ========================
     *     Private functions
     * ========================
     */

    /**
     * @notice Update the user and total records by increasing the weight and the total staked
     *
     * @dev Increase user's `totalStaked`, `totalWeight` and reset `missingRewards`
     * @dev Increase `totalUsersWeight` and `totalTokensStaked`
     * @dev Rewards MUST be updated before and processed for this users
     *
     * @param user The user to update
     * @param amount The amount to increase
     * @param weight The weight to increase
     */
    function _increaseUserRecords(
        User storage user,
        uint256 amount,
        uint256 weight,
        bool updateMissingRewards
    ) internal returns (bool) {
        // Update user records
        user.totalStaked = user.totalStaked.add(amount);
        user.totalWeight = user.totalWeight.add(weight);

        if (updateMissingRewards) {
            // Reset the missingRewards of the user
            user.missingRewards = weightToReward(
                user.totalWeight,
                _rewardsPerWeight
            );
        }

        // Update total records
        totalUsersWeight = totalUsersWeight.add(weight);
        totalTokensStaked = totalTokensStaked.add(amount);
        return true;
    }

    /**
     * @notice Update the user and total records by decreasing the weight and the total staked
     *
     * @dev Decrease user's `totalStaked`, `totalWeight` and reset `missingRewards`
     * @dev Decrease `totalUsersWeight` and `totalTokensStaked`
     * @dev Rewards MUST be updated before and processed for this users
     * @dev If `updateMissingRewards` is false, `missingRewards` rewards MUST be updated after
     *
     * @param user The user to update
     * @param amount The amount to decrease
     * @param weight The weight to decrease
     * @param updateMissingRewards If we have to update the missing rewards of the user
     */
    function _decreaseUserRecords(
        User storage user,
        uint256 amount,
        uint256 weight,
        bool updateMissingRewards
    ) internal returns (bool) {
        // Update user records
        user.totalStaked = user.totalStaked.sub(amount);
        user.totalWeight = user.totalWeight.sub(weight);

        if (updateMissingRewards) {
            // Reset the missingRewards of the user
            user.missingRewards = weightToReward(
                user.totalWeight,
                _rewardsPerWeight
            );
        }

        // Update total records
        totalUsersWeight = totalUsersWeight.sub(weight);
        totalTokensStaked = totalTokensStaked.sub(amount);
        return true;
    }

    /**
     * @notice Remove a deposit if the locking is over and return its amount and weight
     *
     * @dev Set the deposit's `isClaimed` to true
     * @dev Revert if `depositId` does not exist or if the `lockedUntil`
     *      of the deposit has not passed
     * @dev Does not update records : rewards MUST be updated before and
     *      user's profile and total record MUST be updated after
     *
     * @param user The user who owns the deposit
     * @param depositId The deposit id that will be drain
     */
    function _drainDeposit(User storage user, uint256 depositId)
        internal
        returns (uint256 amount, uint256 weight)
    {
        require(depositId < user.deposits.length, "Deposit does not exist");
        Deposit storage deposit = user.deposits[depositId];
        require(!deposit.isClaimed, "Deposit already claimed");
        require(
            deposit.lockedUntil <= uint64(block.timestamp),
            "Staking of this deposit is not yet complete"
        );

        amount = deposit.amount;
        weight = deposit.weight;

        // Claim deposit
        deposit.isClaimed = true;
    }

    /**
     * @notice Used to calculate and pay pending rewards to the `_staker`
     *
     * @dev When there are no rewards to calculate, function doesn't throw and exits silently
     * @dev If `rewardsLockingPeriod` is set, rewards are staked in a new deposit,
     *      otherwise they are transmitted directly to the user (as for flash pools)
     * @dev If `_withUpdate` is false, rewards MUST be updated before and user's missing rewards
     *      MUST be reset after
     * @dev Executed internally in `unstake`, `depositFor`, `updateStakeLock` and `processRewards` functions
     *
     * @param _staker Staker address
     * @param _withUpdate If we need to update rewards and user's missing rewards in this function
     *
     * @return userPendingRewards rewards calculated and optionally re-staked
     */

    function _processRewards(address _staker, bool _withUpdate)
        internal
        returns (uint256 userPendingRewards)
    {
        if (_withUpdate && canUpdateRewards()) {
            // Update rewards before use them if it hasn't been done before
            updateRewards();
        }

        userPendingRewards = pendingRewards(_staker);
        if (userPendingRewards == 0) {
            return 0;
        }

        User storage user = users[_staker];

        // If no locking/staking for rewards
        if (rewardsLockingPeriod == 0) {
            // transfer tokens for user
            rewardToken.safeTransfer(_staker, userPendingRewards);
        } else {
            // Stake rewards
            uint256 weight = calculateUserWeight(
                userPendingRewards,
                rewardsLockingPeriod
            );

            uint64 lockStart = uint64(block.timestamp);
            uint64 lockEnd = lockStart + rewardsLockingPeriod;

            Deposit memory deposit = Deposit({
                amount: userPendingRewards,
                weight: weight,
                lockedFrom: lockStart,
                lockedUntil: lockEnd,
                isRewards: true,
                isClaimed: false
            });

            // Update user and total records
            user.deposits.push(deposit);
            _increaseUserRecords(user, userPendingRewards, weight, false);
        }

        user.releasedRewards = user.releasedRewards.add(userPendingRewards);
        totalProcessedRewards = totalProcessedRewards.add(userPendingRewards);

        if (_withUpdate) {
            // Reset the missingRewards of the user if it will not be done next
            user.missingRewards = weightToReward(
                user.totalWeight,
                _rewardsPerWeight
            );
        }

        emit ProcessRewards(_staker, userPendingRewards);
    }

    /**
     * @notice Used to get the range for the staking time
     * @param x1 The minimum staking time
     * @param y1 The minimum weight time
     * @param x2 The maximum staking time
     * @param y2 The maximum weight time
     * @param a The actual staking time
     */
    function _getRange(
        uint256 x1,
        uint256 y1,
        uint256 x2,
        uint256 y2,
        uint256 a
    ) internal pure returns (uint256) {
        return y1.add(a.sub(x1).mul(y2.sub(y1)).div(x2.sub(x1)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Staking pool factory smart contract interface
 * @author EthernalHorizons - <https://ethernalhorizons.com/>
 * @custom:project-website  https://mechachain.io/
 * @custom:security-contact [email protected]
 */
interface IMechaniumStakingPoolFactory {
    /// Pool data structure
    struct PoolData {
        uint256 allocatedTokens;
        uint256 initBlock;
        uint256 minStakingTime;
        uint256 maxStakingTime;
        uint256 minWeightMultiplier;
        uint256 maxWeightMultiplier;
        uint256 rewardsLockingPeriod;
        uint256 rewardsPerBlock;
    }

    /**
     * @notice Function used to create a new staking pool
     */
    function createPool(
        uint256 allocatedTokens,
        uint32 initBlock,
        uint64 minStakingTime,
        uint64 maxStakingTime,
        uint16 minWeightMultiplier,
        uint16 maxWeightMultiplier,
        uint64 rewardsLockingPeriod,
        uint256 rewardsPerBlock
    ) external returns (bool);

    /**
     * @notice Function used to create a new staking flash pool
     */
    function createFlashPool(
        IERC20 stakedToken,
        uint256 allocatedTokens,
        uint32 initBlock,
        uint64 minStakingTime,
        uint64 maxStakingTime,
        uint16 minWeightMultiplier,
        uint16 maxWeightMultiplier,
        uint256 rewardsPerBlock
    ) external returns (bool);

    /**
     * @notice Function used to add more tokens to a staking pool
     */
    function addAllocatedTokens(address pool, uint256 amount)
        external
        returns (bool);

    /**
     * @notice Function used to add more tokens to a staking pool
     */
    function addAllocatedTokens(
        address payable pool,
        uint256 amount,
        uint256 rewardPerBlock
    ) external returns (bool);

    /**
     * @notice Function used to withdraw unallocated tokens
     */
    function withdrawUnallocated(address account, uint256 amount)
        external
        returns (bool);

    function releaseUnintendedFromPool(
        address payable pool,
        address token_,
        address account,
        uint256 amount
    ) external returns (bool);

    function getPoolData(address payable poolAddr)
        external
        view
        returns (PoolData memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @title Staking pool smart contract interface
 * @author EthernalHorizons - <https://ethernalhorizons.com/>
 * @custom:project-website  https://mechachain.io/
 * @custom:security-contact [email protected]
 */
interface IMechaniumStakingPool {
    struct User {
        uint256 totalStaked;
        uint256 totalWeight;
        uint256 missingRewards;
        uint256 releasedRewards;
        Deposit[] deposits;
    }

    struct Deposit {
        uint256 amount;
        uint256 weight;
        uint64 lockedFrom;
        uint64 lockedUntil;
        bool isRewards;
        bool isClaimed;
    }

    /**
     * @notice Used to stake an `amount` of tokens for a `lockPeriod` for the `msg.sender`
     */
    function stake(uint256 amount, uint64 lockPeriod) external returns (bool);

    /**
     * @notice Used to stake an `amount` of tokens for a `lockPeriod` for an `account`
     */
    function depositFor(
        address account,
        uint256 amount,
        uint256 lockPeriod
    ) external returns (bool);

    /**
     * @notice Used to calculate and pay pending rewards to the `msg.sender`
     */
    function processRewards() external returns (uint256);

    /**
     * @notice Used to unstake several deposits for the `msg.sender`
     */
    function unstake(uint256[] memory depositIds) external returns (bool);

    /**
     * @notice Used to unstake a `depositId` for the `msg.sender`
     */
    function unstake(uint256 depositId) external returns (bool);

    /**
     * @notice Used to update the rewards per weight and the total rewards
     */
    function updateRewards() external returns (bool);

    /**
     * @notice Used to change the rewardsPerBlock
     */
    function setRewardsPerBlock(uint256 rewardsPerBlock)
        external
        returns (bool);

    /**
     * @notice Used to get the remaining allocated tokens
     */
    function remainingAllocatedTokens() external returns (uint256);

    /**
     * @notice Used to get the pending rewards for an `account`
     */
    function pendingRewards(address account) external returns (uint256);

    /**
     * @notice Can we call the rewards function or is it useless and will cause an error
     */
    function canUpdateRewards() external returns (bool);

    /**
     * @notice Used to get the balance for an `account`
     */
    function balanceOf(address account) external returns (uint256);

    /**
     * @notice Used to get the deposit (`depositId`) for an `account`
     */
    function getDeposit(address account, uint256 depositId)
        external
        returns (Deposit memory);

    /**
     * @notice Used to get the length of deposits for an `account`
     */
    function getDepositsLength(address account) external returns (uint256);

    /**
     * @notice Used to get the User data for an `account`
     */
    function getUser(address account) external returns (User memory);

    /**
     * @notice Get the updated rewards
     */
    function updatedRewards() external returns (uint256);

    /**
     * @notice Get the total updated rewards
     */
    function updatedTotalRewards() external returns (uint256);

    /**
     * @notice Get the updated rewards per weight
     */
    function updatedRewardsPerWeight() external returns (uint256);

    /**
     * @notice Calculate the weight based on `amount` and `stakingTime`
     */
    function calculateUserWeight(uint256 amount, uint64 stakingTime)
        external
        returns (uint256);

    /**
     * @notice Converts stake weight to reward value, applying the division on weight
     */
    function weightToReward(uint256 _weight, uint256 _rewardsPerWeight)
        external
        returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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