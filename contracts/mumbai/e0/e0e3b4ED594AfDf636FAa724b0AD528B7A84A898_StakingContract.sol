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

contract StakingContract {
    IERC20 public token;
    uint256 public totalStaked;
    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public stakingTimestamp;

    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 amount);
    event RewardClaimed(address indexed staker, uint256 amount);

    constructor(address _token) {
        token = IERC20(_token);
    }

    modifier validStake() {
        require(stakedBalance[msg.sender] > 0, "No staked balance");
        _;
    }

    function stake(uint256 _amount) external {
        require(_amount > 0, "Invalid amount");
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );

        stakedBalance[msg.sender] += _amount;
        totalStaked += _amount;
        stakingTimestamp[msg.sender] = block.timestamp;

        emit Staked(msg.sender, _amount);
    }

    function unstake(uint256 _amount) external validStake {
        require(
            _amount > 0 && _amount <= stakedBalance[msg.sender],
            "Invalid amount"
        );

        stakedBalance[msg.sender] -= _amount;
        totalStaked -= _amount;

        require(token.transfer(msg.sender, _amount), "Transfer failed");

        emit Unstaked(msg.sender, _amount);
    }

    function claimReward() external validStake {
        uint256 reward = calculateReward(msg.sender);
        require(reward > 0, "No reward available");

        stakingTimestamp[msg.sender] = block.timestamp;

        require(token.transfer(msg.sender, reward), "Transfer failed");

        emit RewardClaimed(msg.sender, reward);
    }

    function calculateReward(address _staker) public view returns (uint256) {
        uint256 stakedTime = block.timestamp - stakingTimestamp[_staker];
        uint256 stakedAmount = stakedBalance[_staker];

        // Here, we can implement our own reward calculation logic based on stakedTime and stakedAmount
        // For simplicity, 1 assume a fixed reward rate of 0.1% per day
        uint256 rewardRate = 10; // 0.1% (divided by 1000)
        uint256 reward = (stakedAmount * stakedTime * rewardRate) /
            (1000 * 1 days);

        return reward;
    }

    function getAPY() public pure returns (uint256) {
        // Here, we can implement our own reward calculation logic based on stakedTime and stakedAmount
        // For simplicity, 1 assume a fixed reward rate of 0.1% per day
        uint256 rewardRate = 10; // 0.1% (divided by 1000)
        uint256 stakingDuration = 365 days; // 1 year

        uint256 apy = (rewardRate * stakingDuration) / (1000 * 1 days);
        return apy;
    }
}