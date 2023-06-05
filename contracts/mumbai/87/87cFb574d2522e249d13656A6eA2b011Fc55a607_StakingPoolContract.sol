// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StakingPoolContract is ReentrancyGuard {
    uint256 private FIXED_APY;
    uint256 private constant SECONDS_IN_YEAR = 31536000; // Number of seconds in a year (365 days)
    uint256 public MINIMUM_STAKING_TIME; // seconds in a month (30 days)
    bool public instant_withdrawl_allowed = false;
    address private owner;

    mapping(address => mapping(uint256 => Stake)) private stakes_pool;
    mapping(address => uint256) private stakes_count;
    mapping(address => uint256) private rewards_ewarned;

    struct Stake {
        uint256 id;
        uint256 amount;
        uint256 timestamp;
    }

    IERC20 private token;

    event StakeDeposited(
        address indexed staker,
        uint256 indexed id,
        uint256 amount,
        uint256 timestamp
    );
    event StakeWithdrawn(
        address indexed staker,
        uint256 indexed id,
        uint256 amount,
        uint256 reward,
        uint256 timestamp
    );
    event RewardsWithdrawn(address indexed staker, uint256 amount);

    constructor(
        address tokenAddress,
        uint256 _FIXED_APY,
        uint256 minmum_staking_time_in_days
    ) {
        token = IERC20(tokenAddress);
        MINIMUM_STAKING_TIME = minmum_staking_time_in_days * 24 * 60 * 60;
        FIXED_APY = _FIXED_APY;

        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function depositStake(uint256 amount)
        external
        nonReentrant
        returns (uint256)
    {
        require(amount > 0, "Invalid stake amount");

        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Stake transfer failed"
        );

        uint256 stake_id = stakes_count[msg.sender] + 1;

        stakes_pool[msg.sender][stake_id] = Stake(
            stake_id,
            amount,
            block.timestamp
        );
        emit StakeDeposited(msg.sender, stake_id, amount, block.timestamp);
        return stake_id;
    }

    function withdrawStake(uint256 amount, uint256 stake_id)
        external
        nonReentrant
    {
        require(stakes_count[msg.sender] > 0, "No stake found");
        require(
            amount <= stakes_pool[msg.sender][stake_id].amount,
            "Withdraw amount is more than balance of stake."
        );
        require(
            (block.timestamp - stakes_pool[msg.sender][stake_id].timestamp >=
                MINIMUM_STAKING_TIME) || instant_withdrawl_allowed,
            "MINIMUM STAKING TIME is not passed"
        );

        uint256 reward = calculateRewardPerStake(msg.sender, stake_id);

        rewards_ewarned[msg.sender] += reward;

        uint256 newAmount = stakes_pool[msg.sender][stake_id].amount - amount;
        stakes_pool[msg.sender][stake_id] = Stake(
            stake_id,
            newAmount,
            block.timestamp
        );

        require(token.transfer(msg.sender, amount), "Stake withdrawal failed");

        emit StakeWithdrawn(
            msg.sender,
            stake_id,
            amount,
            reward,
            block.timestamp
        );
    }

    function withdrawReward(uint256 amount) external nonReentrant {
        require(rewards_ewarned[msg.sender] > 0, "No Rewards Earned");
        require(
            amount <= rewards_ewarned[msg.sender],
            "It is more than current reward earned."
        );

        rewards_ewarned[msg.sender] -= amount;

        require(
            token.transfer(msg.sender, amount),
            "Rewards withdrawal failed"
        );

        emit RewardsWithdrawn(msg.sender, amount);
    }

    function calculateRewardPerStake(address staker, uint256 stake_id)
        public
        view
        returns (uint256)
    {
        uint256 amount = stakes_pool[staker][stake_id].amount;
        uint256 timestamp = stakes_pool[staker][stake_id].timestamp;
        uint256 timeElapsed = block.timestamp - timestamp;

        return (amount * FIXED_APY * timeElapsed) / (100 * SECONDS_IN_YEAR);
    }

    function getStakeAmount(address staker, uint256 stake_id)
        external
        view
        returns (uint256)
    {
        return stakes_pool[staker][stake_id].amount;
    }

    function getStakeTimestamp(address staker, uint256 stake_id)
        external
        view
        returns (uint256)
    {
        return stakes_pool[staker][stake_id].timestamp;
    }

    function getRewardsWithdrawable(address staker)
        external
        view
        returns (uint256)
    {
        return rewards_ewarned[staker];
    }

    function updateMinimumStakingTime(uint256 _days) external onlyOwner {
        MINIMUM_STAKING_TIME = _days * 24 * 60 * 60;
    }

    function toggleWithdrawlInstantOrMonthly() external onlyOwner {
        instant_withdrawl_allowed = !instant_withdrawl_allowed;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function set_FIXED_APY(uint256 new_FIXED_APY) external {
        FIXED_APY = new_FIXED_APY;
    }

    function get_FIXED_APY() external view returns (uint256) {
        return FIXED_APY;
    }

    function changeOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}