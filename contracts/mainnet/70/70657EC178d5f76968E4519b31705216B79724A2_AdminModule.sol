pragma solidity ^0.8.0;


import "../common/variables.sol";
import "./events.sol";
import "../../../infiniteProxy/IProxy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ERC20Interface is IERC20 {
    function decimals() external view returns (uint8);
}

interface IUniswapV3Pool {

    function token0() external view returns (address);

    function token1() external view returns (address);

}

interface IModule2 {
    function updateRewards(address token_) external returns (uint[] memory newRewardPrices_);
}

contract Internals is Variables, Events {
    using SafeMath for uint64;
    using SafeMath for uint128;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
    * @dev refunds the amount undistributed back to the owner.
    * @param token_ address of token.
    * @param rewardToken_ address of reward token.
    */
    function refundUndistributedReward(address token_, address rewardToken_) internal {
        RewardRate memory rewardRate_ = _rewardRate[token_][rewardToken_];
        if (rewardRate_.endTime > block.timestamp) {
            uint fromTime_ = (block.timestamp > rewardRate_.startTime) ? block.timestamp : rewardRate_.startTime;
            uint amount_ = rewardRate_.rewardRate.mul(rewardRate_.endTime.sub(fromTime_));
            address owner_ = IProxy(address(this)).getAdmin();
            IERC20(rewardToken_).safeTransferFrom(address(rewardPool), owner_, amount_);
        }
    }

    /**
    * @dev checks if reward token already exists for that token pair. If it does, refunds the amount undistributed back to the owner, if it doesn't, adds the reward token to the array.
    * @param token_ address of token.
    * @param rewardToken_ address of reward token.
    */
    function checkRewardToken(address token_, address rewardToken_) internal {
        bool exists_;
        address[] memory rewardTokens_ = _rewardTokens[token_];
        for (uint i = 0; i < rewardTokens_.length; i++) {
            if (rewardTokens_[i] == rewardToken_) {
                exists_ = true;
                break;
            }
        }
        if (exists_) {
            refundUndistributedReward(token_, rewardToken_);
        } else {
            _rewardTokens[token_].push(rewardToken_);
        }
    }

}

contract AdminModule is Internals {
    using SafeMath for uint64;
    using SafeMath for uint128;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    modifier onlyOwner {
        require(IProxy(address(this)).getAdmin() == msg.sender, "P3:M1: not-an-admin");
        _;
    }

    modifier poolEnabled(address pool_) {
        require(_poolEnabled[pool_], "P3:M1: pool-not-enabled");
        _;
    }
    
    /**
    * @dev To list a new pool to allow borrowing.
    * @param pool_ address of uniswap pool
    * @param minTick_ minimum tick difference (upperTick - lowerTick) position should have
    * @param borrowLimitNormal_ borrow limit normal (subtract same token from borrow & supply side)
    * @param borrowLimitExtended_ borrow limit extended (total borrow / total deposit)
    * @param priceSlippage_ allowed price slippage of uniswapPrice + slippage < chainlinkPrice < uniswapPrice - slippage
    * @param tickSlippages_ ticks slippage. Tracking 5 past checkpoints to see the liquidator has not manipulated the pool
    * @param timeAgos_ time ago for checkpoint to check slippage.
    * @param borrowMarkets_ allowed tokens for borrow.
    */
    function listPool(
        address pool_,
        uint minTick_,
        uint128 borrowLimitNormal_,
        uint128 borrowLimitExtended_,
        uint priceSlippage_,
        uint24[] memory tickSlippages_,
        uint24[] memory timeAgos_,
        address[] memory borrowMarkets_,
        uint256[] memory borrowLimits_,
        address[] memory oracles_
    ) external onlyOwner {
        require(!_poolEnabled[pool_], "P3:M1: pool-already-enabled");
        _poolEnabled[pool_] = true;
        updateMinTick(pool_, minTick_);
        addBorrowMarket(pool_, borrowMarkets_);
        updatePoolBorrowLimit(pool_, borrowMarkets_, borrowLimits_);
        updateBorrowLimit(pool_, borrowLimitNormal_, borrowLimitExtended_);
        updatePriceSlippage(pool_, priceSlippage_);
        updateTicksCheck(pool_, tickSlippages_, timeAgos_);
        addChainlinkOracle(borrowMarkets_, oracles_);
        emit listPoolLog(pool_);
    }

    /**
    * @dev To update min tick for NFT deposit
    * @param pool_ address of uniswap pool
    * @param minTick_ minimum tick difference (upperTick - lowerTick) position should have
    */
    function updateMinTick(address pool_, uint minTick_) public onlyOwner poolEnabled(pool_) {
        _minTick[pool_] = minTick_;
        emit updateMinTickLog(pool_, minTick_);
    }

    /**
    * @dev To list a new pool to allow borrowing.
    * @param pool_ address of uniswap pool
    * @param tokens_ allowed tokens for borrow.
    */
    function addBorrowMarket(
        address pool_,
        address[] memory tokens_
    ) public onlyOwner poolEnabled(pool_) {
        for (uint i = 0; i < tokens_.length; i++) {
            require(!_borrowAllowed[pool_][tokens_[i]], "P3:M1: market-already-exist");

            address[] memory markets_ = _poolMarkets[pool_];
            for (uint j = 0; j < markets_.length; j++) {
                require(markets_[j] != tokens_[i], "P3:M1: market-already-exist");
            }
            _poolMarkets[pool_].push(tokens_[i]);
            _borrowAllowed[pool_][tokens_[i]] = true;
        }

        // first 2 tokens in markets should always be token0 & token1
        require(_poolMarkets[pool_][0] == IUniswapV3Pool(pool_).token0(), "P3:M1: first-market-not-token0");
        require(_poolMarkets[pool_][1] == IUniswapV3Pool(pool_).token1(), "P3:M1: first-market-not-token1");

        emit addBorrowMarketLog(pool_, tokens_);
    }

    /**
    * @dev updates borrow Limit for tokens Uniswap pool.
    * @param pool_ address of uniswap pool
    * @param tokens_ token addresses
    * @param borrowLimits_ borrow limits for the respective tokens
    */
    function updatePoolBorrowLimit(address pool_, address[] memory tokens_, uint256[] memory borrowLimits_) public onlyOwner poolEnabled(pool_) {
        uint256 length_ = tokens_.length;
        require(borrowLimits_.length == length_, "P3:M1 lengths-not-equal");
        address[] memory markets_ = _poolMarkets[pool_];
        for(uint i = 0; i < length_; i++) {
            bool isMarket;
            for (uint j = 0; j < markets_.length; j++) {
                if (markets_[j] == tokens_[i]) {
                    isMarket = true;
                    break;
                }
            }
            require(isMarket, "P3:M1 non-borrow-market");
            _poolBorrowLimit[pool_][tokens_[i]] =  borrowLimits_[i];
        }
        emit updatePoolBorrowLimitLog(pool_, tokens_, borrowLimits_);
    }
       

    /**
    * @dev updates borrow Limit for a particular Uniswap pool. 85% = 8500, 90% = 9000.
    * @param pool_ address of uniswap pool
    * @param normal_ normal borrow limit
    * @param extended_ extended borrow limit
    */
    function updateBorrowLimit(address pool_, uint128 normal_, uint128 extended_) public onlyOwner poolEnabled(pool_) {
        _borrowLimit[pool_] = BorrowLimit(normal_, extended_);
        emit updateBorrowLimitLog(pool_, normal_, extended_);
    }

    /**
    * @dev enable a token for borrow. Needs to be already be added in markets.
    * @param pool_ address of uniswap pool
    * @param token_ address of token
    */
    function enableBorrow(address pool_, address token_) external onlyOwner poolEnabled(pool_) {
        require(!_borrowAllowed[pool_][token_], "P3:M1: token-already-enabled");
        bool isOk_;
        address[] memory markets_ = _poolMarkets[pool_];
        for (uint i = 0; i < markets_.length; i++) {
            if (markets_[i] == token_) {
                isOk_ = true;
                break;
            }
        }
        require(isOk_, "P3:M1: use-addBorrowMarket()");
        _borrowAllowed[pool_][token_] = true;

        emit enableBorrowLog(pool_, token_);
    }

    /**
    * @dev disable borrow for a specific token. Needs to be already be added in markets.
    * @param pool_ address of uniswap pool
    * @param token_ address of token
    */
    function disableBorrow(address pool_, address token_) external onlyOwner poolEnabled(pool_) {
        require(_borrowAllowed[pool_][token_], "P3:M1: token-already-disabled");
        _borrowAllowed[pool_][token_] = false;
        emit disableBorrowLog(pool_, token_);
    }

    /**
    * @dev updates the price slippage for a particular pool which is used to compare difference between Uniswap & Chainklink oracle
    * @param pool_ address of uniswap pool
    * @param priceSlippage_ max acceptable slippage. 1 = 0.01%, 100 = 1%.
    */
    function updatePriceSlippage(address pool_, uint priceSlippage_) public onlyOwner poolEnabled(pool_) {
        _priceSlippage[pool_] = priceSlippage_;
        emit updatePriceSlippageLog(pool_, priceSlippage_);
    }

    /**
    * @dev updates the max allowed ticks slippages at different time instant.
    * @param pool_ address of uniswap pool
    * @param tickSlippages_ 1 = 1 tick difference, 600 = 600 ticks difference
    * @param timeAgos_ time ago in seconds
    */
    function updateTicksCheck(
        address pool_,
        uint24[] memory tickSlippages_,
        uint24[] memory timeAgos_
    ) public onlyOwner poolEnabled(pool_) {
        require(tickSlippages_.length == 5, "P3:M1: length-should-be-5");
        require(timeAgos_.length == 5, "P3:M1: length-should-be-5");
        _tickCheck[pool_] = TickCheck(
            tickSlippages_[0],
            timeAgos_[0],
            tickSlippages_[1],
            timeAgos_[1],
            tickSlippages_[2],
            timeAgos_[2],
            tickSlippages_[3],
            timeAgos_[3],
            tickSlippages_[4],
            timeAgos_[4]
        );
        emit updateTicksCheckLog(pool_, tickSlippages_, timeAgos_);
    }

    function addChainlinkOracle(address[] memory tokens_, address[] memory oracles_) public onlyOwner {
        for (uint i = 0; i < tokens_.length; i++) {
            _chainlinkOracle[tokens_[i]] = oracles_[i];
        }
        emit addChainlinkOracleLog(tokens_, oracles_);
    }

    /**
    * @dev Set rewards for a market.
    * @param token_ address of token for which rewards to set.
    * @param rewardtoken_ reward token for the token.
    * @param rewardAmount_ reward amount to be distributed throughout the duration.
    * @param startTime_ start time for distributing rewards. If is zero, consider current time.
    * @param duration_ duration of reward.
    */
    function setupRewards(address token_, address rewardtoken_, uint128 rewardAmount_, uint64 startTime_, uint64 duration_) external onlyOwner {
        if (startTime_ == 0) startTime_ = uint64(block.timestamp);
        require(startTime_ >= block.timestamp, "P3:M1: start-time-should-be-more-than-current-time");
        checkRewardToken(token_, rewardtoken_);

        IERC20 rewardTokenContract_ = IERC20(rewardtoken_);
        rewardTokenContract_.safeTransferFrom(msg.sender, address(rewardPool), rewardAmount_);
        uint allowance_ = rewardTokenContract_.allowance(address(rewardPool), address(this));
        if (allowance_ > 0) rewardPool.giveAllowance(rewardtoken_);
        
        RewardRate memory _oldRewardRate = _rewardRate[token_][rewardtoken_];
        if (_oldRewardRate.rewardRate > 0) {
            IModule2(address(this)).updateRewards(token_);
        } else {
            _rewardPrice[token_][rewardtoken_].lastUpdateTime = block.timestamp;
        }
        _rewardRate[token_][rewardtoken_] = RewardRate(uint128(rewardAmount_.div(duration_)), startTime_, uint64(startTime_.add(duration_)));

        emit setupRewardsLog(token_, rewardtoken_, rewardAmount_, startTime_, duration_);
    }

}

pragma solidity ^0.8.0;


import "../../common/ILiquidity.sol";

interface IRewardPool {
    function giveAllowance(address token_) external;
}

contract Variables {

    // status for re-entrancy. 1 = allow/non-entered, 2 = disallow/entered
    uint256 internal _status;

    ILiquidity constant internal liquidity = ILiquidity(0x11dE7Bd1251d1DB7Dc877e35e1648649a864102a); // TODO: add the core liquidity address
    IRewardPool constant internal rewardPool = IRewardPool(0x023e85cEeedF463b82541E2a7a8Fe49F41dEe0A8); // TODO: add the reward pool address

    // pool => bool. To enable a pool
    mapping (address => bool) internal _poolEnabled;

    // pool_address => token_address => rawBorrowAmount.
    mapping (address => mapping (address => uint256)) internal _poolRawBorrow;

    // pool_address => token_address => rawBorrowLimit.
    mapping (address => mapping (address => uint256)) internal _poolBorrowLimit;

    // owner => NFT ID => bool
    mapping (address => mapping (uint => bool)) internal _position;

    struct NftLink {
        uint96 first;
        uint96 last;
        uint64 count;
    }

    struct NftList {
        uint48 prev;
        uint48 next;
        address owner;
    }

    // NFT Link (User Address => NftLink(NFTID of First and Last And Count of NFTID's)).
    mapping (address => NftLink) internal _nftLink;

    // Linked List of NFTIDs (NFTID =>  NftList(Previous and next NFTID, owner of this NFT)).
    mapping (uint96 => NftList) internal _nftList;

    // NFT ID => bool
    mapping (uint => bool) internal _isStaked;

    // NFT ID => no. of stakes
    mapping (uint => uint) internal _stakeCount;

    uint public constant maxStakeCount = 5;

    // rewards accrued at the time of unstaking. NFTID -> token address -> reward amount
    mapping (uint => mapping(address => uint)) internal _rewardAccrued;

    // pool => minimum tick. Minimum tick difference a position should have to deposit (upperTick - lowerTick)
    mapping (address => uint) internal _minTick;

    // NFT ID => token => uint
    mapping (uint => mapping (address => uint)) internal _borrowBalRaw;

    // pool => token => bool
    mapping (address => mapping (address => bool)) internal _borrowAllowed;

    // pool => array or tokens. Market of borrow tokens for particular pool.
    // first 2 markets are always token0 & token1
    mapping (address => address[]) internal _poolMarkets;

    // normal. 8500 = 0.85.
    // extended. 9500 = 0.95.
    // extended meaning max totalborrow/totalsupply ratio
    // normal meaning canceling the same token borrow & supply and calculate ratio from rest of the tokens, meaning
    // if NFT has 1 ETH & 4000 USDC (at 1 ETH = 4000 USDC) and debt of 0.5 ETH & 5000 USDC then the ratio would be
    // extended = (2000 + 5000) / (4000 + 4000) = 7/8
    // normal = (0 + 1000) / (2000) = 1/2
    struct BorrowLimit {
        uint128 normal;
        uint128 extended;
    }

    // pool address => Borrow limit
    mapping (address => BorrowLimit) internal _borrowLimit;

    // pool => _priceSlippage
    // 1 = 0.01%. 10000 = 100%
    // used to check Uniswap and chainlink price
    mapping (address => uint) internal _priceSlippage;

    // Tick checkpoints
    // 5 checkpoints Eg:-
    // Past 10 sec.
    // Past 30 sec.
    // Past 60 sec.
    // Past 120 sec.
    // Past 300 sec.
    struct TickCheck {
        uint24 tickSlippage1;
        uint24 secsAgo1;
        uint24 tickSlippage2;
        uint24 secsAgo2;
        uint24 tickSlippage3;
        uint24 secsAgo3;
        uint24 tickSlippage4;
        uint24 secsAgo4;
        uint24 tickSlippage5;
        uint24 secsAgo5;
    }

    // pool => TickCheck
    mapping (address => TickCheck) internal _tickCheck;

    // token => oracle contract. Price in USD.
    mapping (address => address) internal _chainlinkOracle;

    struct RewardRate {
        uint128 rewardRate; // reward rate per sec
        uint64 startTime; // reward start time
        uint64 endTime; // reward end time
    }

    struct RewardPrice {
        uint256 rewardPrice; // rewards per total current raw borrow from start. Keeping it 256 bit as we're multiplying with 1e27 for proper decimal calculation
        uint256 lastUpdateTime; // in sec
    }

    struct NftReward {
        uint256 lastRewardPrice; // last updated reward price for this nft. Keeping it 256 bit as we're multiplying with 1e27 for proper decimal calculation
        uint256 reward; // rewards available for claiming for user
    }

    // token => reward tokens. One token can have multiple rewards going on.
    mapping (address => address[]) internal _rewardTokens;

    // token => reward token => reward rate per sec
    mapping (address => mapping (address => RewardRate)) internal _rewardRate;

    // rewards per total current raw borrow. _rewardPrice = _rewardPrice + (_rewardRate * timeElapsed) / total current raw borrow
    // multiplying with 1e27 to get decimal precision otherwise the number could get 0. To calculate users reward divide by 1e27 in the end.
    // token => reward token => reward price
    mapping (address => mapping (address => RewardPrice)) internal _rewardPrice; // starts from 0 & increase overtime.

    // last reward price stored for a nft. Multiplying (current - last) * (amount of token borrowed on nft) will give users new rewards earned
    // nftid => token => reward token => reward amount
    mapping (uint96 => mapping (address => mapping (address => NftReward))) internal _nftRewards;

}

pragma solidity ^0.8.0;


contract Events {

    event listPoolLog(address indexed pool_);

    event updateMinTickLog(address indexed pool_, uint minTick_);

    event addBorrowMarketLog(address pool_, address[] tokens_);

    event updatePoolBorrowLimitLog(address pool_, address[] tokens_, uint256[] borrowLimits_);

    event updateBorrowLimitLog(address pool_, uint128 normal_, uint128 extended_);

    event enableBorrowLog(address pool_, address token_);

    event disableBorrowLog(address pool_, address token_);

    event updatePriceSlippageLog(address pool_, uint priceSlippage_);

    event updateTicksCheckLog(address pool_, uint24[] tickSlippages_, uint24[] timeAgos_);

    event setInitialBorrowRateLog(address token_);

    event addChainlinkOracleLog(address[] tokens_, address[] oracles_);

    event setupRewardsLog(address token_, address rewardtoken_, uint rewardAmount_, uint startTime_, uint duration_);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IProxy {

    function getAdmin() external view returns (address);

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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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

pragma solidity ^0.8.0;


interface ILiquidity {

    function supply(
        address token_,
        uint amount_
    ) external returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    );

    function withdraw(
        address token_,
        uint amount_
    ) external returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    );

    function borrow(
        address token_,
        uint amount_
    ) external returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    );

    function payback(
        address token_,
        uint amount_
    ) external returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    );

    function updateInterest(
        address token_
    ) external view returns (
        uint newSupplyExchangePrice,
        uint newBorrowExchangePrice
    );

    function isProtocol(address protocol_) external view returns (bool);

    function protocolBorrowLimit(address protocol_, address token_) external view returns (uint256);

    function totalSupplyRaw(address token_) external view returns (uint256);

    function totalBorrowRaw(address token_) external view returns (uint256);

    function protocolRawSupply(address protocol_, address token_) external view returns (uint256);

    function protocolRawBorrow(address protocol_, address token_) external view returns (uint256);

    struct Rates {
        uint96 lastSupplyExchangePrice; // last stored exchange price. Increases overtime.
        uint96 lastBorrowExchangePrice; // last stored exchange price. Increases overtime.
        uint48 lastUpdateTime; // in sec
        uint16 utilization; // utilization. 10000 = 100%
    }

    function rate(address token_) external view returns (Rates memory);

}

// SPDX-License-Identifier: MIT

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