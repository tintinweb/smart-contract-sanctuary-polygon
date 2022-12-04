/**
 *Submitted for verification at polygonscan.com on 2022-12-04
*/

/**
 *Submitted for verification at polygonscan.com on 2022-10-26
*/

// File: Owned.sol


pragma solidity ^0.8.17;

contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}
// File: Address.sol


pragma solidity ^0.8.17;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}
// File: IERC20.sol


pragma solidity ^0.8.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: SafeMath.sol


pragma solidity ^0.8.17;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
// File: SafeERC20.sol


pragma solidity ^0.8.17;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
// File: StakingRewards.sol


pragma solidity ^0.8.17;





contract StakingRewards is Owned{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== CONSTRUCTOR ========== */
    constructor() Owned(msg.sender) {}

    /* ========== Staking Pools ========== */
    struct Pool{
        IERC20 rewardsToken;
        IERC20 stakingToken;
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 rewardsDuration;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        uint256 totalSupply;
    } 
    uint256 public totalPools;
    mapping (uint256 => Pool) private pools;
    function getPool(uint256 id) external view returns (Pool memory) {
        return pools[id];
    }
    function addPool(address _rewardsToken,address _stakingToken,uint256 _rewardDuration) external onlyOwner{
        pools[totalPools].rewardsToken = IERC20(_rewardsToken);
        pools[totalPools].stakingToken = IERC20(_stakingToken);
        pools[totalPools].rewardsDuration = _rewardDuration;
        totalPools++;
        emit poolAdded(totalPools);
    } 


    /* ========== USER STATE VARIABLES ========== */
    mapping (uint256 => mapping(address => uint256)) public userRewardPerTokenPaid;
    mapping (uint256 => mapping(address => uint256)) public rewards;
    mapping (uint256 => mapping(address => uint256)) private userBalances;

    /* ========== VIEWS ========== */
    function totalSupply(uint256 id) external view returns (uint256) {
        return pools[id].totalSupply;
    }
    function balanceOf(uint256 id,address account) external view returns (uint256) {
        return userBalances[id][account];
    }
    function lastTimeRewardApplicable(uint256 id) public view returns (uint256) {
        return block.timestamp < pools[id].periodFinish ? block.timestamp : pools[id].periodFinish;
    }
    function rewardPerToken(uint256 id) public view returns (uint256) {
        if (pools[id].totalSupply == 0) {
            return pools[id].rewardPerTokenStored;
        }
        return
        pools[id].rewardPerTokenStored.add(
            lastTimeRewardApplicable(id).sub(pools[id].lastUpdateTime).mul(pools[id].rewardRate).mul(1e18).div(pools[id].totalSupply)
        );
    }
    function earned(uint256 id,address account) public view returns (uint256) {
        return userBalances[id][account].mul(rewardPerToken(id).sub(userRewardPerTokenPaid[id][account])).div(1e18).add(rewards[id][account]);
    }
    function getRewardForDuration(uint256 id) external view returns (uint256) {
        return pools[id].rewardRate.mul(pools[id].rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function stake(uint256 id,uint256 amount) external updateReward(id,msg.sender) {
        require(amount > 0, "Cannot stake 0");
        
        pools[id].totalSupply = pools[id].totalSupply.add(amount);
        userBalances[id][msg.sender] = userBalances[id][msg.sender].add(amount);
        pools[id].stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(id,msg.sender, amount);
    }
    function withdraw(uint256 id,uint256 amount) public updateReward(id,msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        pools[id].totalSupply = pools[id].totalSupply.sub(amount);
        userBalances[id][msg.sender] = userBalances[id][msg.sender].sub(amount);
        pools[id].stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(id,msg.sender, amount);
    }
    function getReward(uint256 id) public updateReward(id,msg.sender) {
        uint256 reward = rewards[id][msg.sender];
        if (reward > 0) {
            rewards[id][msg.sender] = 0;
            pools[id].rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(id,msg.sender, reward);
        }
    }
    function exit(uint256 id) external {
        withdraw(id,userBalances[id][msg.sender]);
        getReward(id);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    function notifyRewardAmount(uint256 id,uint256 reward) external updateReward(id,address(0)) onlyOwner{
        if (block.timestamp >= pools[id].periodFinish) {
            pools[id].rewardRate = reward.div(pools[id].rewardsDuration);
        } else {
            uint256 remaining = pools[id].periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(pools[id].rewardRate);
            pools[id].rewardRate = reward.add(leftover).div(pools[id].rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
     
        uint balance = pools[id].rewardsToken.balanceOf(address(this))+reward;
        require(pools[id].rewardRate <= balance.div(pools[id].rewardsDuration), "Provided reward too high");
   
        pools[id].rewardsToken.safeTransferFrom(msg.sender, address(this), reward);

        pools[id].lastUpdateTime = block.timestamp;
        pools[id].periodFinish = block.timestamp.add(pools[id].rewardsDuration);
        emit RewardAdded(id,reward);
    }
    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(uint256 id,address tokenAddress, uint256 tokenAmount) external onlyOwner{
        require(tokenAddress != address(pools[id].stakingToken), "Cannot withdraw the staking token");
        IERC20(tokenAddress).safeTransfer(owner, tokenAmount);
        emit Recovered(id,tokenAddress, tokenAmount);
    }
    function setRewardsDuration(uint256 id,uint256 _rewardsDuration) external onlyOwner{
        require(
            block.timestamp > pools[id].periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        pools[id].rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(id,pools[id].rewardsDuration);
    }

    /* ========== MODIFIERS ========== */
    modifier updateReward(uint256 id,address account) {
        pools[id].rewardPerTokenStored = rewardPerToken(id);
        pools[id].lastUpdateTime = lastTimeRewardApplicable(id);
        if (account != address(0)) {
            rewards[id][account] = earned(id,account);
            userRewardPerTokenPaid[id][account] = pools[id].rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */
    event RewardAdded(uint256 id,uint256 reward);
    event Staked(uint256 id,address indexed user, uint256 amount);
    event Withdrawn(uint256 id,address indexed user, uint256 amount);
    event RewardPaid(uint256 id,address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 id,uint256 newDuration);
    event Recovered(uint256 id,address token, uint256 amount);
    event poolAdded(uint256 id);
}