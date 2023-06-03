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

// interface IERC20 {
//     function transfer(address recipient, uint256 amount) external returns (bool);
//     function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
//     function balanceOf(address account) external view returns (uint256);
//     function approve(address spender, uint256 amount) external returns (bool);
// }

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakingContract {
    uint256 private constant APY = 12; // 5% fixed APY
    uint256 private constant SECONDS_IN_YEAR = 31536000; // Number of seconds in a year (365 days)
    uint256 public MINIMUM_STAKING_TIME; // seconds in a month (30 days)
    bool public instant_withdrawl_allowed = false;
    address private owner;

    mapping(address => Stake) private stakes;
    mapping(address => uint256) private rewards_ewarned;

    struct Stake {
        uint256 amount;
        uint256 timestamp;
    }

    IERC20 private token;

    event StakeDeposited(
        address indexed staker,
        uint256 amount,
        uint256 timestamp
    );
    event StakeWithdrawn(
        address indexed staker,
        uint256 amount,
        uint256 reward,
        uint256 timestamp
    );
    event RewardsWithdrawn(address indexed staker, uint256 amount);

    constructor(address tokenAddress, uint256 minmum_staking_time_in_days) {
        token = IERC20(tokenAddress);
        MINIMUM_STAKING_TIME = minmum_staking_time_in_days * 24 * 60 * 60;

        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function depositStake(uint256 amount) external {
        require(amount > 0, "Invalid stake amount");

        uint256 existingAmount = stakes[msg.sender].amount;
        if (existingAmount > 0) {
            rewards_ewarned[msg.sender] += calculateReward(msg.sender);
        }
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Stake transfer failed"
        );

        uint256 newAmount = existingAmount + amount;

        stakes[msg.sender] = Stake(newAmount, block.timestamp);
        emit StakeDeposited(msg.sender, amount, block.timestamp);
    }

    function withdrawStake(uint256 amount) external {
        require(stakes[msg.sender].amount > 0, "No stake found");
        require(
            amount <= stakes[msg.sender].amount,
            "It is more than current balance."
        );
        require(
            (block.timestamp - stakes[msg.sender].timestamp >=
                MINIMUM_STAKING_TIME) || instant_withdrawl_allowed,
            "MINIMUM STAKING TIME is not passed"
        );

        // uint256 amount = stakes[msg.sender].amount;
        uint256 reward = calculateReward(msg.sender);

        rewards_ewarned[msg.sender] += calculateReward(msg.sender);
        // uint256 totalAmount = amount + reward;

        // delete stakes[msg.sender];

        uint256 newAmount = stakes[msg.sender].amount - amount;
        stakes[msg.sender] = Stake(newAmount, block.timestamp);

        require(token.transfer(msg.sender, amount), "Stake withdrawal failed");

        emit StakeWithdrawn(msg.sender, amount, reward, block.timestamp);
    }

    function withdrawReward(uint256 amount) external {
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

    function calculateReward(address staker) public view returns (uint256) {
        uint256 amount = stakes[staker].amount;
        uint256 timestamp = stakes[staker].timestamp;
        uint256 timeElapsed = block.timestamp - timestamp;

        return (amount * APY * timeElapsed) / (100 * SECONDS_IN_YEAR);
    }

    function getStakeAmount(address staker) external view returns (uint256) {
        return stakes[staker].amount;
    }

    function getStakeTimestamp(address staker) external view returns (uint256) {
        return stakes[staker].timestamp;
    }

    function getRewardsEarned(address staker) external view returns (uint256) {
        return stakes[staker].timestamp;
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

    function changeOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}