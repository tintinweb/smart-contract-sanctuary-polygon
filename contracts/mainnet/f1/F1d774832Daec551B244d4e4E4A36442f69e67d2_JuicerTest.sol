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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IJuicer {
    function swapUsdcForEth(uint256 usdcAmount) external;
}

contract JuicerTest {
    IJuicer public juicer;
    IERC20 public usdcToken;

    event SwapTest(uint256 usdcAmount, uint256 ethReceived);
    event SwapWithdraw(uint256 usdcAmount, uint256 ethReceived);

    constructor(address _juicer, address _usdcToken) {
        juicer = IJuicer(_juicer);
        usdcToken = IERC20(_usdcToken);
    }

    function withdrawSwapUsdcForEth(uint256 usdcAmount, uint256 swapUsdcAmount) external {
        // Require usdcAmount to be greater than contract balance
        uint256 totalUsdcAmount = usdcAmount + swapUsdcAmount;
        require(totalUsdcAmount >= usdcToken.balanceOf(address(this)), "Not enough USDC in the contract");

        // Approve the Juicer contract to spend USDC on behalf of this contract
        usdcToken.approve(address(juicer), swapUsdcAmount);

        // Check the contract's ETH balance before the swap
        uint256 initialEthBalance = address(this).balance;

        // Perform the swap using the Juicer contract
        juicer.swapUsdcForEth(swapUsdcAmount);

        // Calculate the amount of ETH received
        uint256 ethReceived = address(this).balance - initialEthBalance;

        // Emit an event with the swap details
        emit SwapTest(swapUsdcAmount, ethReceived);

        // Withdraw the USDC from the Juicer contract
        usdcToken.transfer(msg.sender, usdcAmount);

        // withdraw the ETH from the Juicer contract
        payable(msg.sender).transfer(ethReceived);

        // Emit an event with the swap details
        emit SwapWithdraw(swapUsdcAmount, ethReceived);
    }

    // Function to deposit USDC into the test contract
    function depositUsdc(uint256 amount) external {
        usdcToken.transferFrom(msg.sender, address(this), amount);
    }

    // Function to withdraw USDC from the test contract
    function withdrawUsdc(uint256 amount) external {
        usdcToken.transfer(msg.sender, amount);
    }

    // Function to withdraw ETH from the test contract
    function withdrawEth(uint256 amount) external {
        payable(msg.sender).transfer(amount);
    }

    // Allow the test contract to receive ETH
    receive() external payable {}
}