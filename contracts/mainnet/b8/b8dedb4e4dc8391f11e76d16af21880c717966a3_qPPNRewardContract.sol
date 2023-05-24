/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

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

// File: qPPN-Rewards.sol



pragma solidity ^0.8.0;


contract qPPNRewardContract {
    IERC20 public qppnToken;
    mapping(address => uint256) public lastRewardTime;

    // The owner of the contract
    address public owner;

    constructor() {
        // Set the contract deployer as the owner
        owner = msg.sender;
    }

    // Only the owner can set the qPPN token
    function setQppnToken(IERC20 _qppnToken) external {
        require(msg.sender == owner, "Only the owner can set the qPPN token");
        qppnToken = _qppnToken;
    }

    // A function to approve a certain amount of tokens to be spent by this contract
    function approveSpending(uint256 amount) external {
        require(msg.sender == owner, "Only the owner can approve spending");
        qppnToken.approve(address(this), amount);
    }

    function claimReward() external {
        require(readyForReward(msg.sender), "You must wait 4 hours between claiming rewards");

        uint256 reward = calculateReward(msg.sender);

        // Check if the contract has enough tokens to give as a reward
        uint256 contractBalance = qppnToken.balanceOf(address(this));
        require(contractBalance >= reward, "The contract does not have enough tokens to give as a reward");

        // Transfer the reward to the user
        qppnToken.transfer(msg.sender, reward);
        // Update the last reward time to now
        lastRewardTime[msg.sender] = block.timestamp;
    }

    function calculateReward(address user) public view returns (uint256) {
        uint256 balance = qppnToken.balanceOf(user);
        uint256 reward = balance / 25;  // 4% reward
        return reward;
    }

    function readyForReward(address user) public view returns (bool) {
        uint256 lastReward = lastRewardTime[user];
        uint256 timeSinceLastReward = block.timestamp - lastReward;
        return timeSinceLastReward >= 4 hours;
    }
}