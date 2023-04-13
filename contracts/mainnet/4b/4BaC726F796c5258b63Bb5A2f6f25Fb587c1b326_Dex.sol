/**
 *Submitted for verification at polygonscan.com on 2023-04-13
*/

// File: @uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol


pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// File: https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/ISwapRouter.sol


pragma solidity >=0.7.5;
pragma abicoder v2;


/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// File: contracts/flashloan/dex.sol

// contracts/FlashLoan.sol

pragma solidity ^0.8.0;


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



contract Dex {



    // Aave ERC20 Token addresses on Goerli network
    address private wmaticAddress =
        0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address private usdcAddress =
        0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    IERC20 private wmatic;
    IERC20 private usdc;



 address public constant routerAddressSushiswap =
        0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
 address public constant routerAddressQuickswap =
        0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;


    ISwapRouter public immutable swapRouterQuickswap = ISwapRouter(routerAddressQuickswap);
    ISwapRouter public immutable swapRouterSushiswap = ISwapRouter(routerAddressSushiswap);

    IERC20 public wmaticToken = IERC20(wmaticAddress);
    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant poolFee = 300;

    // keeps track of individuals' dai balances
    mapping(address => uint256) public wmaticBalances;

    // keeps track of individuals' USDC balances
    mapping(address => uint256) public usdcBalances;

     constructor() public {
        wmatic = IERC20(wmaticAddress);
        usdc = IERC20(usdcAddress);
    }

    function depositUSDC(uint256 _amount) external {
        usdcBalances[msg.sender] += _amount;
        uint256 allowance = usdc.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
        usdc.transferFrom(msg.sender, address(this), _amount);
    }

    

        
   
    function depositWMATIC(uint256 _amount) external {
        wmaticBalances[msg.sender] += _amount;
        uint256 allowance = wmatic.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
        wmatic.transferFrom(msg.sender, address(this), _amount);
    }


    function sushiswapBuyWMATIC(uint256 _amountUSDC) public  returns (uint256) {
       
 usdc.approve(address(swapRouterSushiswap), _amountUSDC);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: usdcAddress,
                tokenOut: wmaticAddress,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp+15,
                amountIn: _amountUSDC,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

      uint256 amountOut = swapRouterSushiswap.exactInputSingle(params);
                return amountOut;

    }

    function quickswapBuyWMATIC(uint256 _amountUSDC) public  returns (uint256) {
   
            
 wmatic.approve(address(swapRouterQuickswap), _amountUSDC);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: usdcAddress,
                tokenOut: wmaticAddress,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp+15,
                amountIn: _amountUSDC,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

      uint256 amountOut = swapRouterQuickswap.exactInputSingle(params);
    return amountOut;
    }


    function sushiswapSellWMATIC(uint256 _amountWMATIC) public  returns (uint256) {    
        
 wmatic.approve(address(swapRouterSushiswap), _amountWMATIC);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: usdcAddress,
                tokenOut: wmaticAddress,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp+15,
                amountIn: _amountWMATIC,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

      uint256 amountOut = swapRouterQuickswap.exactInputSingle(params);
    return amountOut;


    }



    function quickswapSellWMATIC(uint256 _amountWMATIC) public  returns (uint256) {
           
 wmatic.approve(address(swapRouterQuickswap), _amountWMATIC);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: usdcAddress,
                tokenOut: wmaticAddress,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp+15,
                amountIn: _amountWMATIC,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

      uint256 amountOut = swapRouterQuickswap.exactInputSingle(params);
    return amountOut;
    }

    function getBalance(address _tokenAddress) external  returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    function withdraw(address _tokenAddress) external  {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }


}