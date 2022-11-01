// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
pragma abicoder v2;


import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./StakingPool.sol";
import "./IHashStratDAOToken.sol";


/**
 * A Farm contract to distribute HashStrat DAO tokens among LP token stakers proportionally to the amount and duration of the their stakes.
 * Users are free to add and remove tokens to their stake at any time.
 * Users can also claim their pending HashStrat DAO tokens at any time.
 *
 * The contract implements an efficient O(1) algo to distribute the rewards based on this paper:
 * https://uploads-ssl.webflow.com/5ad71ffeb79acc67c8bcdaba/5ad8d1193a40977462982470_scalable-reward-distribution-paper.pdf
 *
 * Owner of this contract should be DAOOperations to add (and remvoe) supported LP tokens
 *
 */

contract HashStratDAOTokenFarm is StakingPool {

    event RewardPaid(address indexed user, uint256 reward);

    uint public totalStakedValue; // T: sum of the initial value of all active stakes
    uint public rewardPerValueStaked; // S: SUM(reward/T) - sum of all rewards distributed divided all active stakes
    uint public lastUpdated;  // when the totalStakedWeight was last updated (after last stake was ended)


    struct RewardPeriod {
        uint id;
        uint reward;
        uint from;
        uint to;
        uint totalRewardsPaid; 
    }

    struct UserInfo {
        uint stakedLPValue;    // the initial value of the LP staked
        uint userRewardPerTokenStaked;
        uint pendingRewards;
        uint rewardsPaid;
    }

    struct RewardsStats {
        // user stats
        uint claimableRewards;
        uint rewardsPaid;
        // general stats
        uint rewardRate;
        uint totalRewardsPaid;
    }

    // The DAO token to distribute to stakers
    IHashStratDAOToken immutable public hstToken;

    // Fixed amount of token distributed over the 10 periods
    uint public immutable REWARD_PERIODS = 10;
    uint public immutable TOKEN_MAX_SUPPLY;


    RewardPeriod[] public rewardPeriods;
    mapping(address => UserInfo) userInfos;
    uint constant rewardPrecision = 1e9;
    uint public tokensFarmed;

   
    constructor(address hstTokenAddress) StakingPool() {
        hstToken = IHashStratDAOToken(hstTokenAddress);
        TOKEN_MAX_SUPPLY = hstToken.maxSupply();
    }


    //// Public View Functions ////

    function getRewardPeriods() public view returns (RewardPeriod[] memory) {
        return rewardPeriods;
    }


    function rewardPeriodsCount()  public view returns (uint) {
        return rewardPeriods.length;
    }


    function hstTokenBalance() public view returns (uint) {
        return hstToken.balanceOf(address(this));
    }


    // return the id of the last reward period that started before current block.timestamp
    // assumes reward periods are chronologically ordered
    function getLastRewardPeriodId() public view returns (uint) {
        if (REWARD_PERIODS == 0) return 0;
        for (uint i=rewardPeriods.length; i>0; i--) {
            RewardPeriod memory period = rewardPeriods[i-1];
            if (period.from <= block.timestamp) {
                return period.id;
            }
        }
        return 0;
    }


    function getRewardsStats(address account) public view returns (RewardsStats memory) {
        UserInfo memory userInfo = userInfos[msg.sender];

        RewardsStats memory stats = RewardsStats(0, 0, 0, 0);
        // user stats
        stats.claimableRewards = claimableReward(account);
        stats.rewardsPaid = userInfo.rewardsPaid;

        // reward period stats
        uint periodId = getLastRewardPeriodId();
        if (periodId > 0) {
            RewardPeriod memory period = rewardPeriods[periodId-1];
            stats.rewardRate = rewardRate(period);
            stats.totalRewardsPaid = period.totalRewardsPaid;
        }

        return stats;
    }

    
   
    //// Public Functions ////

    function startStake(address lpToken, uint amount) public override {

        address pool = lptokenToPool[lpToken];
        require(pool != address(0), "No pool found for LP token");

        uint periodId = getLastRewardPeriodId();
        RewardPeriod memory period = rewardPeriods[periodId-1];
        require(periodId > 0 && period.from <= block.timestamp, "No active reward period found");

        uint stakedValue = IPoolV3(pool).lpTokensValue(amount);

        update();
        super.startStake(lpToken, amount);

        UserInfo storage userInfo = userInfos[msg.sender];  
        userInfo.stakedLPValue += stakedValue;
        totalStakedValue += stakedValue;
    }


    function endStake(address lpToken, uint amount) public override {

        uint staked = getStakedBalance(msg.sender, lpToken);

        // percentage of staked lp tokens that is being unstaked
        uint percUnstake = amount <= staked ?  rewardPrecision * amount / staked  : rewardPrecision;

        UserInfo storage userInfo = userInfos[msg.sender]; 
        uint valueUnstaked = userInfo.stakedLPValue * percUnstake / rewardPrecision;

        update();
        super.endStake(lpToken, amount);
        
        userInfo.stakedLPValue -= (valueUnstaked <= userInfo.stakedLPValue) ? valueUnstaked : userInfo.stakedLPValue;
        totalStakedValue -= (valueUnstaked <= totalStakedValue) ? valueUnstaked : totalStakedValue;

        claim();

    }


    function claimableReward(address account) public view returns (uint) {
        uint periodId = getLastRewardPeriodId();
        if (periodId == 0) return 0;

        RewardPeriod memory period = rewardPeriods[periodId-1];
        uint newRewardPerValueStaked = calculateRewardDistribution(period);
        uint reward = calculateReward(account, newRewardPerValueStaked);

        UserInfo memory userInfo = userInfos[account];
        uint pending = userInfo.pendingRewards;

        return pending + reward;
    }

 
    function claimReward() public {
        update();
        claim();
    }


    function addRewardPeriods() public  {
        require(rewardPeriods.length == 0, "Reward periods already set");

        // firt year reward is 500k tokens halving every following year
        uint initialRewardAmount = TOKEN_MAX_SUPPLY / 2;
        
        uint secondsInYear = 365 * 24 * 60 * 60;

        uint rewardAmount = initialRewardAmount;
        uint from = block.timestamp;
        uint to = from + secondsInYear - 1;
        
        // create all distribution periods
        uint totalAmount = 0;
        for (uint i=0; i<REWARD_PERIODS; i++) {
            if (i == (REWARD_PERIODS-1)) {
                rewardAmount = TOKEN_MAX_SUPPLY - totalAmount;
            }
            addRewardPeriod(rewardAmount, from, to);

            totalAmount += rewardAmount;
            from = (to + 1);
            to = (from + secondsInYear - 1);
            rewardAmount /= 2;
        }
    }



    //// INTERNAL FUNCTIONS ////

    function claim() internal {

        UserInfo storage userInfo = userInfos[msg.sender];
        uint rewardsToPay = userInfo.pendingRewards;

        if (rewardsToPay != 0) {
            userInfo.pendingRewards = 0;

            uint periodId = getLastRewardPeriodId();
            RewardPeriod storage period = rewardPeriods[periodId-1];
            period.totalRewardsPaid += rewardsToPay;

            // set the sender as delegate if none is set
            if (hstToken.delegates(msg.sender) == address(0)) {
                hstToken.delegate(msg.sender, msg.sender);
            }

            payReward(msg.sender, rewardsToPay);
        }
    }


    function payReward(address account, uint reward) internal {
        UserInfo storage userInfo = userInfos[msg.sender];
        userInfo.rewardsPaid += reward;
        tokensFarmed += reward;

        hstToken.mint(account, reward);

        emit RewardPaid(account, reward);
    }


    function addRewardPeriod(uint reward, uint from, uint to) internal {
        require(reward > 0, "Invalid reward amount");
        require(to > from && to > block.timestamp, "Invalid period interval");
        require(rewardPeriods.length == 0 || from > rewardPeriods[rewardPeriods.length-1].to, "Invalid period start time");

        rewardPeriods.push(RewardPeriod(rewardPeriods.length+1, reward, from, to, 0));
    }



    /// Reward calcualtion logic


    // calculate the updated average rate of reward to be distributed from from 'lastUpdated' to min(block.timestamp, period.to)
    function rewardRate(RewardPeriod memory last) internal view returns (uint) {

        uint from = lastUpdated;
        uint to = lastUpdated;
        uint reward;
     
        // cycle through all period and deterine the reward to be distributed and the interval
        uint i=0;
        while (i < rewardPeriods.length && rewardPeriods[i].id <= last.id) {

            RewardPeriod memory period = rewardPeriods[i];

            if (lastUpdated <= period.to && block.timestamp >= period.from ) {
                uint start = Math.max(lastUpdated, period.from); // lastUpdated > period.from ? lastUpdated : period.from; // start at max(lastUpdated or period.from),
                uint end = Math.min(block.timestamp, period.to); // block.timestamp > period.to ? period.to : block.timestamp; // end at min(block.timestamp or period.to)
                
                uint interval = end - start;
                uint periodRate = period.reward / (period.to - period.from);
                uint rewardForInterval = interval * periodRate;

                reward += rewardForInterval;
                to = Math.max(to, end);
            }

            i++;
        }
        
        uint rate = (to > from) ? reward / (to - from) : 0;
        return rate;
    }


    function update() internal {
        
        uint periodId = getLastRewardPeriodId();
        if (periodId == 0) return;

        RewardPeriod storage period = rewardPeriods[periodId-1];
        uint newRewardPerValueStaked = calculateRewardDistribution(period);

        // update pending rewards reward since rewardPerValueStaked was updated
        uint reward = calculateReward(msg.sender, newRewardPerValueStaked);
        UserInfo storage userInfo = userInfos[msg.sender];
        userInfo.pendingRewards += reward;
        userInfo.userRewardPerTokenStaked = newRewardPerValueStaked;

        require(newRewardPerValueStaked >= rewardPerValueStaked, "Reward distribution should be monotonic increasing");

        rewardPerValueStaked = newRewardPerValueStaked;
        lastUpdated = block.timestamp;
    }


    // Returns the reward for one unit of value staked from 'lastUpdated' up to the 'period 'provided
    function calculateRewardDistribution(RewardPeriod memory period) internal view returns (uint) {

        // calculate an updated average rate of the reward/second to be distributed since lastUpdated
        uint rate = rewardRate(period);

      
        // calculate the amount of additional reward to be distributed from 'lastUpdated' to min(block.timestamp, period.to)
        uint rewardIntervalEnd = block.timestamp > period.to ? period.to : block.timestamp;
        uint deltaTime = rewardIntervalEnd > lastUpdated ? rewardIntervalEnd - lastUpdated : 0;
        uint reward = deltaTime * rate; // the additional reward

        // S = S + r / T
        uint newRewardPerValueStaked = (totalStakedValue == 0)?  
                                        rewardPerValueStaked :
                                        rewardPerValueStaked + ( rewardPrecision * reward / totalStakedValue ); 

        return newRewardPerValueStaked;
    }


    // calculates the additional reward for the 'account' based on the 'rewardDistributionPerValue' 
    function calculateReward(address account, uint rewardDistributionPerValue) internal view returns (uint) {
        if (rewardDistributionPerValue == 0) return 0;

        UserInfo memory userInfo = userInfos[account];
        uint reward = (userInfo.stakedLPValue * (rewardDistributionPerValue - userInfo.userRewardPerTokenStaked)) / rewardPrecision;
        return reward;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
        return a >= b ? a : b;
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
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IPoolV3.sol";
import "./IHashStratDAOTokenFarm.sol";


contract StakingPool is IHashStratDAOTokenFarm, Ownable {

    event Staked(address indexed user, address indexed lpTokenAddresses, uint amount);
    event UnStaked(address indexed user, address indexed lpTokenAddresses, uint256 amount);
    event Deposited(address indexed user, address indexed lpTokenAddress, uint256 amount);
    event Withdrawn(address indexed user, address indexed lpTokenAddress, uint256 amount);

 
    // the addresses of Pools and Indexes supported
    address[] private poolsArray;
    mapping(address => bool) internal enabledPools;
    mapping(address => address) internal lptokenToPool;
    
    
    uint internal enabledPoolsCount = 0;

    // users that deposited CakeLP tokens into their balances
    address[] private usersArray;
    mapping(address => bool) private existingUsers;


    // addresses that have active stakes
    address[] public stakers; 

   // account_address -> (lp_token_address -> lp_token_balance)
    mapping(address => mapping(address => uint256) ) private balances;

    // account_address => (lp_token_address => stake_balance)
    mapping (address => mapping(address =>  uint)) private stakes;
 


    //// Public View Functions ////

    function getStakers() external view returns (address[] memory) {
        return stakers;
    }


    function getStakedBalance(address account, address lpToken) public view returns (uint) {
        if(lptokenToPool[lpToken] == address(0)) return 0;

        return stakes[account][lpToken];
    }


    function getBalance(address _userAddress, address _lpAddr) external view returns (uint256) {
        return balances[_userAddress][_lpAddr];
    }


    function getUsers() external view returns (address[] memory) {
        return usersArray;
    }


    // return the array of the addresses of the enabled pools
    function getPools() public view returns (address[] memory) {
        address[] memory enabed = new address[](enabledPoolsCount);

        uint j = 0;
        for (uint i = 0; i<poolsArray.length; i++){
            address pool = poolsArray[i];
            if (enabledPools[pool]) {
                enabed[j] = pool;
                j++;
            }
        }

        return enabed;
    }

    function getLPTokens() public view returns (address[] memory) {
        address[] memory enabed = new address[](enabledPoolsCount);
        uint j = 0;
        for (uint i = 0; i<poolsArray.length; i++){
            address pool = poolsArray[i];
            if (enabledPools[pool]) {
                enabed[j] = address( IPoolV3(pool).lpToken() );
                j++;
            }
        }

        return enabed;
    }
        


    //// Public Functions ////

    function deposit(address lpAddress, uint256 amount) public {
        require(amount > 0, "Deposit amount should not be 0");
        require(lptokenToPool[lpAddress] != address(0), "LP Token not supported");

        require(
            IERC20(lpAddress).allowance(msg.sender, address(this)) >= amount, "Insufficient allowance"
        );

        balances[msg.sender][lpAddress] += amount;

        // remember accounts that deposited LP tokens
        if (existingUsers[msg.sender] == false) {
            existingUsers[msg.sender] = true;
            usersArray.push(msg.sender);
        }

        IERC20(lpAddress).transferFrom(msg.sender, address(this), amount);

        emit Deposited(msg.sender, lpAddress, amount);
    }


    function withdraw(address lpAddress, uint256 amount) public {
        require(lptokenToPool[lpAddress] != address(0), "LP Token not supported");
        require(balances[msg.sender][lpAddress] >= amount, "Insufficient token balance");

        balances[msg.sender][lpAddress] -= amount;
        IERC20(lpAddress).transfer(msg.sender, amount);

        emit Withdrawn(msg.sender, lpAddress, amount);
    }


    function startStake(address lpToken, uint amount) virtual public {
        require(lptokenToPool[lpToken] != address(0), "LP Token not supported");
        require(amount > 0, "Stake must be a positive amount greater than 0");
        require(balances[msg.sender][lpToken] >= amount, "Not enough tokens to stake");

        // move tokens from lp token balance to the staked balance
        balances[msg.sender][lpToken] -= amount;
        stakes[msg.sender][lpToken] += amount;
       
        emit Staked(msg.sender, lpToken, amount);
    }


    function endStake(address lpToken, uint amount) virtual public {
        require(lptokenToPool[lpToken] != address(0), "LP Token not supported");
        require(stakes[msg.sender][lpToken] >= amount, "Not enough tokens staked");

        // return lp tokens to lp token balance
        balances[msg.sender][lpToken] += amount;
        stakes[msg.sender][lpToken] -= amount; 

        emit UnStaked(msg.sender, lpToken, amount);
    }


    function depositAndStartStake(address lpToken, uint256 amount) public {
        deposit(lpToken, amount);
        startStake(lpToken, amount);
    }


    function endStakeAndWithdraw(address lpToken, uint amount) public {
        endStake(lpToken, amount);
        withdraw(lpToken, amount);
    }



    //// ONLY OWNER FUNCTIONALITY ////

    function addPools(address[] memory poolsAddresses) external override onlyOwner {
        for (uint i = 0; i<poolsAddresses.length; i++) {
            address pool = poolsAddresses[i];
            if (pool != address(0) && enabledPools[pool] == false) {
                enabledPools[pool] = true;
                lptokenToPool[ address(IPoolV3(pool).lpToken()) ] = pool;
                poolsArray.push(pool);
                enabledPoolsCount++;
            }
        }
    }


    function removePools(address[] memory poolsAddresses) external override onlyOwner {
        for (uint i = 0; i<poolsAddresses.length; i++) {
            address pool = poolsAddresses[i];
            if (pool != address(0) && enabledPools[pool] == true) {
                enabledPools[pool] = false;
                lptokenToPool[ address(IPoolV3(pool).lpToken()) ] = address(0);
                enabledPoolsCount--;
            }
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IHashStratDAOToken is IERC20Metadata {

    function maxSupply() external view returns (uint);
    function mint(address to, uint256 amount) external;
    function getPastVotes(address account, uint256 blockNumber) external view  returns (uint256);
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);


    function delegates(address account) external view returns (address);
    function delegate(address delegator, address delegatee) external;

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
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
*  Pool's functionality required by DAOOperations and DAOFarm
*/

interface IPoolV3 {

    function lpToken() external view returns (IERC20Metadata);
    function lpTokensValue (uint lpTokens) external view returns (uint);

    function portfolioValue(address addr) external view returns (uint);
    function collectFees(uint amount) external;

    function setFeesPerc(uint feesPerc) external;
    function setSlippageThereshold(uint slippage) external;
    function setStrategy(address strategyAddress) external;
    function setUpkeepInterval(uint upkeepInterval) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IHashStratDAOTokenFarm {

    function addPools(address[] memory poolsAddresses) external;
    function removePools(address[] memory poolsAddresses) external;
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