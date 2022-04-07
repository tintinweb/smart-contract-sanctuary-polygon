// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PromoStaking {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    uint256 constant ACCURACY = 1e12;

    bool public inited;
    uint256 public lastUpdated;
    uint256 public totalStaked;
    uint256 public totalRewardPaid;
    uint256 public cumulativeRewardPerShare;
    mapping(address => UserInfo) public userInfo;

    // immutable
    uint256 public rewardPerBlock;
    uint256 public totalReward;
    uint256 public startBlock;
    uint256 public endBlock;
    address public token;
    address public owner;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(address _owner) {
        owner = _owner;
    }

    function _transferReward(address to, uint256 amount) private {
        require(totalRewardPaid + amount <= totalReward);
        IERC20(token).transfer(to, amount);
        totalRewardPaid += amount;
    }

    function getPendingTokens(address _user) external view returns (uint256 pending) {
        UserInfo storage user = userInfo[_user];
        pending = (user.amount * cumulativeRewardPerShare) / ACCURACY - user.rewardDebt;
    }

    function getStakedAmount(address _user) external view returns (uint256 amount) {
        amount = userInfo[_user].amount;
    }

    function initialize(
        address _token,
        uint256 _totalReward,
        uint256 _startBlock,
        uint256 stakingDurationInBlocks
    ) external {
        require(msg.sender == owner, "Only owner");
        require(!inited, "Already inited");
        token = _token;
        totalReward = _totalReward;
        startBlock = _startBlock;
        lastUpdated = _startBlock;
        endBlock = _startBlock + stakingDurationInBlocks;
        rewardPerBlock = totalReward / stakingDurationInBlocks;
        inited = true;
    }

    function updCumulativeRewardPerShare() public onlyOnInited {
        if (block.number <= lastUpdated) {
            return;
        }
        if (totalStaked == 0) {
            lastUpdated = block.number;
            return;
        }
        if (block.number < endBlock) {
            uint256 timePassed = block.number - lastUpdated;
            cumulativeRewardPerShare += (timePassed * rewardPerBlock * ACCURACY) / totalStaked;
            lastUpdated = block.number;
        }
    }

    function stake(uint256 amount, address recipientAddress) external onlyOnInited notFinished {
        UserInfo storage recipient = userInfo[recipientAddress];
        address staker = msg.sender;
        updCumulativeRewardPerShare();

        uint256 pending = (recipient.amount * cumulativeRewardPerShare) / ACCURACY - recipient.rewardDebt;
        if (pending > 0) {
            _transferReward(recipientAddress, pending);
        }
        if (amount > 0) {
            IERC20(token).transferFrom(staker, address(this), amount);
            recipient.amount += amount;
            totalStaked += amount;
        }
        recipient.rewardDebt = (recipient.amount * cumulativeRewardPerShare) / ACCURACY;

        emit Deposit(recipientAddress, amount);
    }

    function unstake(uint256 amount) external onlyOnInited {
        UserInfo storage user = userInfo[msg.sender];
        updCumulativeRewardPerShare();

        require(user.amount >= amount, "Stake is not enough");
        uint256 pending = (user.amount * cumulativeRewardPerShare) / ACCURACY - user.rewardDebt;
        if (pending > 0) {
            _transferReward(msg.sender, pending);
        }
        if (amount > 0) {
            user.amount -= amount;
            totalStaked -= amount;
            IERC20(token).transfer(msg.sender, amount);
        }
        user.rewardDebt = (user.amount * cumulativeRewardPerShare) / ACCURACY;

        emit Withdraw(msg.sender, amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() external onlyOnInited {
        UserInfo storage user = userInfo[msg.sender];
        IERC20(token).transfer(address(msg.sender), user.amount);
        user.amount = 0;
        user.rewardDebt = 0;

        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    modifier onlyOnInited() {
        require(inited, "Not inited");
        _;
    }

    modifier notFinished() {
        require(block.number < endBlock, "Promo staking finished");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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