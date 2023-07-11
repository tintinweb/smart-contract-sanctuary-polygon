/**
 *Submitted for verification at polygonscan.com on 2023-07-10
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: stake.sol

pragma solidity >=0.8.18;


contract StakingContract {
    struct Deposit {
        uint256 poolId;
        uint256 stakedAmount;
        uint256 lastRewardTimestamp;
        uint256 joiningTime;
        uint256 totalWithdrawn;
    }
    struct User {
        address referrer;
        uint256 directReferralsCount;
        uint256 referralIncome;
        uint256 levelIncome;
        uint256 roiEarned;
        mapping(uint256 => Deposit) deposits;
        uint256[15] levelWiseIncome;
    }

    struct Pool {
        uint256[] levelRewards;
        uint256 minAmount;
        uint256 timePeriod;
        uint256 roiPercent;
        uint256 directRefPercent;
        uint256 totalStake;
        uint256 maxPoolSize;
    }

    mapping(address => User) public users;
    mapping(uint256 => Pool) public pools;
    mapping(uint256 => uint256) public levelConditions;
    uint256 public poolsCount = 0;
    address public admin;
    IERC20 public token;
    uint256 public lapsedAmount;

    constructor(IERC20 _token) {
        admin = msg.sender;
        token = _token;
        // Set default level conditions
        levelConditions[0] = 1;
        levelConditions[1] = 2;
        levelConditions[2] = 3;
        levelConditions[3] = 4;
        levelConditions[4] = 5;
        levelConditions[5] = 6;
        levelConditions[6] = 7;
        levelConditions[7] = 7;
        levelConditions[8] = 7;
        levelConditions[9] = 7;
        levelConditions[10] = 7;
        levelConditions[11] = 8;
        levelConditions[12] = 10;
        levelConditions[13] = 13;
        levelConditions[14] = 18;
        users[msg.sender].referrer = address(0);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    function checkForMaxAllowedStake(uint256 amount, uint256 poolIndex)
        public
        view
        returns (bool)
    {
        uint256 totalRewardPercent = 0;
        totalRewardPercent +=
            ((pools[poolIndex].totalStake + amount) *
                pools[poolIndex].directRefPercent) /
            100;
        totalRewardPercent +=
            ((pools[poolIndex].totalStake + amount) *
                pools[poolIndex].roiPercent) /
            100;
        for (uint256 i = 0; i < 15; i++) {
            totalRewardPercent +=
                ((pools[poolIndex].totalStake + amount) *
                    pools[poolIndex].levelRewards[i]) /
                100;
        }
        if (totalRewardPercent > pools[poolIndex].maxPoolSize) {
            return false;
        }
        return true;
    }

    function createPool(
        uint256 timePeriod,
        uint256 directRefPercent,
        uint256 roiPercent,
        uint256 maxStake,
        uint256[] memory rewardPercentages
    ) external onlyAdmin {
        require(
            rewardPercentages.length == 15,
            "Invalid number of reward percentages"
        );

        Pool storage pool = pools[poolsCount];
        poolsCount++;
        pool.directRefPercent = directRefPercent;
        pool.timePeriod = timePeriod;
        pool.levelRewards = rewardPercentages;
        pool.roiPercent = roiPercent;
        pool.maxPoolSize = maxStake;
    }

    function setLevelCondition(uint256 level, uint256 condition)
        external
        onlyAdmin
    {
        require(level <= 15, "Invalid level");
        levelConditions[level] = condition;
    }

    function stake(
        uint256 poolIndex,
        address referrer,
        uint256 stakingAmount
    ) external {
        require(
            users[msg.sender].deposits[poolIndex].stakedAmount == 0,
            "User is already staked"
        );
        require(referrer != msg.sender, "Cannot refer yourself");
        require(poolIndex < poolsCount, "Invalid pool index");
        require(referrer != address(0), "Invalid referrer");
        if (users[msg.sender].referrer != address(0)) {
            referrer = users[msg.sender].referrer;
        } else {
            users[referrer].directReferralsCount++;
        }
        Pool storage pool = pools[poolIndex];
        require(
            stakingAmount >= pool.minAmount,
            "Amount should be greater than minAmount"
        );
        // require(
        //     checkForMaxAllowedStake(stakingAmount, poolIndex),
        //     "Max Stake amount reached"
        // );

        // Assign referrer
        users[msg.sender].referrer = referrer;

        // Stake amount and last claimed day
        users[msg.sender].deposits[poolIndex].stakedAmount += stakingAmount;
        users[referrer].referralIncome +=
            (stakingAmount * pools[poolIndex].directRefPercent) /
            10000;

        pools[poolIndex].totalStake += stakingAmount;

        users[msg.sender].deposits[poolIndex].lastRewardTimestamp = block
            .timestamp;
        users[msg.sender].deposits[poolIndex].joiningTime = block.timestamp;
    }

    function claimRewards(address user, uint256 poolIndex) public {
        require(
            users[user].deposits[poolIndex].stakedAmount > 0,
            "User is not staked"
        );
        uint256 currTime = block.timestamp;
        if (
            (users[user].deposits[poolIndex].joiningTime +
                pools[poolIndex].timePeriod) < block.timestamp
        ) {
            currTime =
                users[user].deposits[poolIndex].joiningTime +
                pools[poolIndex].timePeriod;
        }
        uint256 timePassed = currTime -
            users[user].deposits[poolIndex].lastRewardTimestamp;
        address ref = users[user].referrer;
        for (uint256 i = 0; i < 15; i++) {
            if (ref == address(0)) {
                break;
            }
            if (users[ref].directReferralsCount < levelConditions[i]) {
                lapsedAmount +=
                    (timePassed *
                        users[user].deposits[poolIndex].stakedAmount *
                        pools[poolIndex].levelRewards[i]) /
                    10000 /
                    pools[poolIndex].timePeriod;
                continue;
            }
            users[ref].levelWiseIncome[i] +=
                (timePassed *
                    users[user].deposits[poolIndex].stakedAmount *
                    pools[poolIndex].levelRewards[i]) /
                10000 /
                pools[poolIndex].timePeriod;
            users[ref].levelIncome +=
                (timePassed *
                    users[user].deposits[poolIndex].stakedAmount *
                    pools[poolIndex].levelRewards[i]) /
                10000 /
                pools[poolIndex].timePeriod;

            ref = users[ref].referrer;
        }
        token.transfer(
            msg.sender,
            (timePassed *
                users[user].deposits[poolIndex].stakedAmount *
                pools[poolIndex].roiPercent) /
                10000 /
                pools[poolIndex].timePeriod
        );

    users[msg.sender].deposits[poolIndex].totalWithdrawn+= (timePassed *
                users[user].deposits[poolIndex].stakedAmount *
                pools[poolIndex].roiPercent) /
                10000 /
                pools[poolIndex].timePeriod;

        users[user].roiEarned +=
            (timePassed *
                users[user].deposits[poolIndex].stakedAmount *
                pools[poolIndex].roiPercent) /
            10000 /
            pools[poolIndex].timePeriod;

        users[user].deposits[poolIndex].lastRewardTimestamp = block.timestamp;
    }

   

    function getPendingRewards(address user, uint256 poolIndex)
        public 
        view
        returns (uint256)
    {
        uint256 currTime = block.timestamp;
        if (
            (users[user].deposits[poolIndex].joiningTime +
                pools[poolIndex].timePeriod) < block.timestamp
        ) {
            currTime =
                users[user].deposits[poolIndex].joiningTime +
                pools[poolIndex].timePeriod;
        }
        uint256 timePassed = currTime -
            users[user].deposits[poolIndex].lastRewardTimestamp;

        uint256 reward = (timePassed *
            users[user].deposits[poolIndex].stakedAmount *
            pools[poolIndex].roiPercent) /
            pools[poolIndex].timePeriod /
            10000;

        return reward;
    }

    function unstake(uint256 poolIndex) external {
        require(
            users[msg.sender].deposits[poolIndex].stakedAmount > 0,
            "User is not staked"
        );
        require(
            (block.timestamp -
                users[msg.sender].deposits[poolIndex].joiningTime) >=
                pools[poolIndex].timePeriod,
            "Its locked"
        );
        
        pools[poolIndex].totalStake -= users[msg.sender]
            .deposits[poolIndex]
            .stakedAmount;

        users[msg.sender].deposits[poolIndex].stakedAmount = 0;
        claimRewards(msg.sender, poolIndex);
    }

    function getTotalDeposits(address user) external view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < poolsCount; i++) {
            total += users[user].deposits[i].stakedAmount;
        }
        return total;
    }

    function getDepositInfo(address user, uint256 poolIndex)
        external
        view
        returns (Deposit memory)
    {
        return users[user].deposits[poolIndex];
    }

    function getLevelWiseIncome(address user, uint256 level) external view returns(uint256){
       return users[user].levelWiseIncome[level];
    }

    function getTotalPendingReward(address user) external view returns(uint256){
        uint256 total = 0;
        for(uint256 i=0;i<poolsCount;i++){
            total+=getPendingRewards(user,i);
        }
        return total;
    }

    function withdrawLevelIncome() external {
        require(users[msg.sender].levelIncome>0,"0 amount can't be withdrawn");
        token.transfer(msg.sender, users[msg.sender].levelIncome);
        users[msg.sender].levelIncome = 0;
    }

    function withdrawReferralIncome() external {
        require(users[msg.sender].referralIncome>0,"0 amount can't be withdrawn");
        token.transfer(msg.sender, users[msg.sender].referralIncome);
        users[msg.sender].referralIncome = 0;
    }
}