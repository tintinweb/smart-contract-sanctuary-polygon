/**
 *Submitted for verification at polygonscan.com on 2023-04-04
*/

/**
 *Submitted for verification at polygonscan.com on 2023-04-04
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/dsync-stake.sol



pragma solidity ^0.8.7;



contract StakeDsync is ReentrancyGuard {

    using SafeMath for uint;

    struct Stake {
        bool initialized;
        address beneficiary;
        uint256 depositDate;
        uint256 value;
        uint256 rewardRate;
        uint256 rewardStartDate;
        uint256 withdrawDate;
        uint256 claimed;
        uint8 nonce;
    }

    struct StakeOption {
        uint8 apr;
        uint256 rewardPerDay;
        uint256 rewardPeriod;
        uint256 withdrawPeriod;
    }
    mapping(address => uint8) private nonces;
    mapping(bytes32 => Stake) private stakes;
    mapping(address => uint256) private balances;


    mapping(uint8 => StakeOption) private stakeOptions;

    uint256 private totalSupply;
    uint256 private totalClaimed;
    uint256 private totalWithdrawn;

    IERC20 private cDsync;

    event TokensStaked(bytes32 indexed index, address beneficiary, uint256 value);
    event RewardClaimed(bytes32 indexed index, address beneficiary, uint256 value);
    event TokensWithdrawn(bytes32 indexed index, address beneficiary, uint256 value);

    constructor(address _token) {
        cDsync = IERC20(_token);

        stakeOptions[1] = StakeOption({
            apr: 10,
            rewardPerDay: getTokenRewardDay(10),
            rewardPeriod: 15 days,
            withdrawPeriod: 30 days
        });

        stakeOptions[2] = StakeOption({
            apr: 40,
            rewardPerDay: getTokenRewardDay(40),
            rewardPeriod: 60 days,
            withdrawPeriod: 120 days
        });

        stakeOptions[3] = StakeOption({
            apr: 60,
            rewardPerDay: getTokenRewardDay(60),
            rewardPeriod: 180 days,
            withdrawPeriod: 360 days
        });
    }

    function simple_stake(
        bool _init,
        address _sender,
        uint256 _value,
        uint256 _rewardRate,
        uint256 _rsDate,
        uint256 _wsDate
    ) public returns (bytes32) {
        require(_value > 0, "StakeDsync: Cannot stake 0");
        require(cDsync.transferFrom(_sender, address(this), _value), "StakeDsync: Token transfer failed");
        require(_rsDate > block.timestamp, "StakeDsync: Reward start date must be in the future");
        require(_wsDate > _rsDate, "StakeDsync: Withdraw date must be after reward start date");

        nonces[_sender] += 1;
        uint8 nonce = nonces[_sender];
        bytes32 index = getIndexBytes(_sender, nonce);

        stakes[index] = Stake({
            initialized: _init,
            beneficiary: _sender,
            depositDate: block.timestamp,
            value: _value,
            rewardRate: _rewardRate,
            rewardStartDate: _rsDate,
            withdrawDate: _wsDate,
            claimed: 0,
            nonce: nonce
        });

        balances[_sender] += _value;
        totalSupply += _value;

        emit TokensStaked(index, _sender, _value);
        return index;

    }

    function stake(uint256 _value, uint8 _option) external nonReentrant returns (bytes32) {
        StakeOption memory option = stakeOptions[_option];
        require(option.rewardPerDay > 0, "StakeDsync: Invalid option");

        uint256 rewardRate = option.rewardPerDay * (_value.div(1e18));
        uint256 rewardStartDate = block.timestamp + option.rewardPeriod;
        uint256 withdrawDate = block.timestamp + option.withdrawPeriod;
        return simple_stake(true, msg.sender, _value, rewardRate, rewardStartDate, withdrawDate);
    }

    function claimReward(bytes32 _index) external nonReentrant {
        Stake storage _stake = stakes[_index];
        require(_stake.initialized, "StakeDsync: Stake not initialized");
        require(_stake.beneficiary == msg.sender, "StakeDsync: Not beneficiary");
        require(block.timestamp >= _stake.rewardStartDate, "StakeDsync: Reward not available yet");

        uint256 reward = getUserReward(_index);
        require(reward > 0, "StakeDsync: No reward available");
        require(cDsync.balanceOf(address(this)) >= totalSupply + reward, "StakeDsync: Reward Tokens surplus error");

        require(cDsync.transfer(msg.sender, reward), "StakeDsync: Token transfer failed");
        _stake.claimed += reward;
        balances[msg.sender] += reward;
        totalClaimed += reward;

        emit RewardClaimed(_index, msg.sender, reward);
    }

    function withdraw(bytes32 _index) external nonReentrant {
        Stake storage _stake = stakes[_index];
        require(_stake.initialized, "StakeDsync: Stake not initialized");
        require(_stake.beneficiary == msg.sender, "StakeDsync: Not beneficiary");
        require(block.timestamp >= _stake.withdrawDate, "StakeDsync: Withdraw not available yet");

        require(cDsync.transfer(msg.sender, _stake.value), "StakeDsync: Token transfer failed");
        _stake.initialized = false;
        balances[msg.sender] -= _stake.value;
        totalSupply -= _stake.value;
        totalWithdrawn += _stake.value;

        emit TokensWithdrawn(_index, msg.sender, _stake.value);
    }

    function getIndexBytes(address _address, uint8 _nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_address, _nonce));
    }

    function getTokenRewardDay(uint _apr) public pure returns (uint256) {
        // 60% APR = 0.16438356% per day
        // this function returns the reward for 1 token per day
        uint256 reward = (_apr.mul(1e16)).div(36525);
        return reward;
    }

    function getUserReward(bytes32 _index) public view returns (uint256) {
        Stake storage _stake = stakes[_index];
        uint256 reward = _stake.rewardRate * ((block.timestamp - _stake.depositDate) / 1 days);
        return reward;
    }

    function getStake(bytes32 _index) external view returns (Stake memory) {
        return stakes[_index];
    }

    function getStakeOption(uint8 _option) external view returns (StakeOption memory) {
        return stakeOptions[_option];
    }

    function balanceOf(address _account) external view returns (uint256) {
        return balances[_account];
    }

    function getTotalSupply() external view returns (uint256) {
        return totalSupply;
    }

    function getTotalClaimed() external view returns (uint256) {
        return totalClaimed;
    }

    function getTotalWithdrawn() external view returns (uint256) {
        return totalWithdrawn;
    }

    function getRewardTokenAddress() external view returns (address) {
        return address(cDsync);
    }
}


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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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