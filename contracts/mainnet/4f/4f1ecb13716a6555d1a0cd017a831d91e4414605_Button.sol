/**
 *Submitted for verification at polygonscan.com on 2023-04-18
*/

// SPDX-License-Identifier: UNLICENSED
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


contract Button {
    address payable public admin;
    uint256 public constant MINIMUM_DEPOSIT = 1 ether;
    uint256 public constant DEPOSIT_AMOUNT = 1 ether;
    uint256 public constant COUNTDOWN_TIME = 4 hours;
    uint256 public constant ADMIN_FEE_PERCENTAGE = 1000; // 0.1%

    uint256 public endTime;
    uint256 public totalDepositedAmount;
    address payable public lastDepositor;
    IERC20 public maticToken;

    event Deposit(address indexed depositor, uint256 amount);
    event Withdraw(address indexed winner, uint256 amount);

    constructor(address _maticTokenAddress) {
        admin = payable(msg.sender);
        maticToken = IERC20(_maticTokenAddress);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    function deposit() external {
        require(maticToken.balanceOf(msg.sender) >= DEPOSIT_AMOUNT, "Insufficient balance.");
        require(maticToken.allowance(msg.sender, address(this)) >= DEPOSIT_AMOUNT, "Insufficient allowance.");

        maticToken.transferFrom(msg.sender, address(this), DEPOSIT_AMOUNT);
        totalDepositedAmount += DEPOSIT_AMOUNT;
        lastDepositor = payable(msg.sender);

        if (endTime == 0) {
            endTime = block.timestamp + COUNTDOWN_TIME;
        } else {
            endTime = block.timestamp + COUNTDOWN_TIME;
        }

        emit Deposit(msg.sender, DEPOSIT_AMOUNT);
    }

    function withdraw() external {
        require(block.timestamp >= endTime, "Countdown has not reached zero.");
        uint256 adminFee = (totalDepositedAmount * ADMIN_FEE_PERCENTAGE) / 100000;
        uint256 winnerAmount = totalDepositedAmount - adminFee;

        if (totalDepositedAmount == MINIMUM_DEPOSIT) {
            maticToken.transfer(lastDepositor, winnerAmount);
        } else {
            maticToken.transfer(lastDepositor, winnerAmount);
            maticToken.transfer(admin, adminFee);
        }

        emit Withdraw(lastDepositor, winnerAmount);

        // Reset the game state
        totalDepositedAmount = 0;
        endTime = 0;
        lastDepositor = payable(address(0));
    }

    function updateMaticTokenAddress(address _maticTokenAddress) external onlyAdmin {
        maticToken = IERC20(_maticTokenAddress);
    }
}