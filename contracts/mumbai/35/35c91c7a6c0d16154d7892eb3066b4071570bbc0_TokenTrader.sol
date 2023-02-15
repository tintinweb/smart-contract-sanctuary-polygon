/**
 *Submitted for verification at polygonscan.com on 2023-02-14
*/

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


pragma solidity ^0.8.0;

interface IPancakeSwapRouter {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

interface IPriceOracle {
    function getLatestPrice() external view returns (uint);
}

contract TokenTrader {
    address private constant PANCAKE_ROUTER_ADDRESS = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private constant PRICE_ORACLE_ADDRESS = 0x18B2A687610328590Bc8F2e5fEdDe3b582A49cdA;
    address private constant WETH_ADDRESS = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    IPancakeSwapRouter private pancakeRouter;
    IPriceOracle private priceOracle;

    constructor() {
        pancakeRouter = IPancakeSwapRouter(PANCAKE_ROUTER_ADDRESS);
        priceOracle = IPriceOracle(PRICE_ORACLE_ADDRESS);
    }

    function buyToken(address tokenAddress, uint amountIn) external {
        require(amountIn > 0, "Amount must be greater than 0");

        address[] memory path = new address[](2);
        path[0] = WETH_ADDRESS;
        path[1] = tokenAddress;

        uint[] memory amounts = pancakeRouter.getAmountsOut(amountIn, path);
        uint expectedAmountOut = amounts[1];

        uint latestPrice = priceOracle.getLatestPrice();
        require(expectedAmountOut >= latestPrice, "Token price too high");

        // Transfer WETH to the contract
        payable(address(this)).transfer(amountIn);

        // Approve PancakeSwap to spend WETH
        IERC20(WETH_ADDRESS).approve(PANCAKE_ROUTER_ADDRESS, amountIn);

        // Swap WETH for token
        pancakeRouter.swapExactTokensForTokens(amountIn, expectedAmountOut, path, msg.sender, block.timestamp + 120);
    }

    function sellToken(address tokenAddress, uint amountIn) external {
        require(amountIn > 0, "Amount must be greater than 0");

        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = WETH_ADDRESS;

        uint[] memory amounts = pancakeRouter.getAmountsOut(amountIn, path);
        uint expectedAmountOut = amounts[1];

        uint latestPrice = priceOracle.getLatestPrice();
        require(expectedAmountOut >= latestPrice, "Token price too high");

        // Transfer token to the contract
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amountIn);

        // Approve PancakeSwap to spend token
        IERC20(tokenAddress).approve(PANCAKE_ROUTER_ADDRESS, amountIn);

        // Swap token for WETH
        pancakeRouter.swapExactTokensForTokens(amountIn, expectedAmountOut, path, msg.sender, block.timestamp + 120);
    }
}