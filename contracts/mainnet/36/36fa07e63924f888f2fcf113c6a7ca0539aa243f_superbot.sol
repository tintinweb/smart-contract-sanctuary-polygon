/**
 *Submitted for verification at polygonscan.com on 2022-12-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

interface IuniswapRouter {
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
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);
}

interface IquickswapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IsushiswapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract superbot {
    // arbitrage tokens addresses
    address usdtAddress = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address maticAddress = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address wethAddress = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

    // dexes swap router addresses
    address quickswapRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address sushiswapRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address uniswapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    // arbitrage smart contract owner
    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // buy matic on quickswap and sell on sushiswap
    function quicktosushiARB(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) public onlyOwner returns (bool success) {
        IquickswapRouter(quickswapRouter).swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            deadline
        );
        uint256 amountIn2 = IERC20(maticAddress).balanceOf(address(this));
        IsushiswapRouter(sushiswapRouter).swapExactTokensForTokens(
            amountIn2,
            amountOutMin,
            path,
            address(this),
            deadline
        );
        return true;
    }

    // buy matic on sushiswap and sell on quickswap
    function sushitoquickARB(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) public onlyOwner returns (bool success) {
        IsushiswapRouter(sushiswapRouter).swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            deadline
        );
        uint256 amountIn2 = IERC20(maticAddress).balanceOf(address(this));
        IquickswapRouter(quickswapRouter).swapExactTokensForTokens(
            amountIn2,
            amountOutMin,
            path,
            address(this),
            deadline
        );
        return true;
    }

    // buy on uniswap and sell on sushiswap
    function unitosushiARB(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline,
        IuniswapRouter.ExactInputSingleParams calldata params
    ) public onlyOwner returns (bool success) {
        IuniswapRouter(uniswapRouter).exactInputSingle(params);
        uint256 amountIn2 = IERC20(maticAddress).balanceOf(address(this));
        IsushiswapRouter(sushiswapRouter).swapExactTokensForTokens(
            amountIn2,
            amountOutMin,
            path,
            address(this),
            deadline
        );
        return true;
    }

    // buy on sushiswap sell on uniswap
    function sushitouniARB(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) public onlyOwner returns (bool success) {
        IsushiswapRouter(sushiswapRouter).swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            deadline
        );
        uint256 amountIn2 = IERC20(maticAddress).balanceOf(address(this));
        IuniswapRouter.ExactInputSingleParams memory params = IuniswapRouter
            .ExactInputSingleParams({
                tokenIn: maticAddress,
                tokenOut: usdtAddress,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn2,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        IuniswapRouter(uniswapRouter).exactInputSingle(params);
        return true;
    }

    // buy on uniswap and sell on quickswap
    function unitoquickARB(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline,
        IuniswapRouter.ExactInputSingleParams calldata params
    ) public onlyOwner returns (bool success) {
        IuniswapRouter(uniswapRouter).exactInputSingle(params);
        uint256 amountIn2 = IERC20(maticAddress).balanceOf(address(this));
        IquickswapRouter(quickswapRouter).swapExactTokensForTokens(
            amountIn2,
            amountOutMin,
            path,
            address(this),
            deadline
        );
        return true;
    }

    // buy on quickswap sell on uniswap
    function quicktouniARB(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) public onlyOwner returns (bool success) {
        IquickswapRouter(quickswapRouter).swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            deadline
        );
        uint256 amountIn2 = IERC20(maticAddress).balanceOf(address(this));
        IuniswapRouter.ExactInputSingleParams memory params = IuniswapRouter
            .ExactInputSingleParams({
                tokenIn: maticAddress,
                tokenOut: usdtAddress,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn2,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        IuniswapRouter(uniswapRouter).exactInputSingle(params);
        return true;
    }

    // withdraw usdt from contract
    function withdrawUSDT(uint256 _amount)
        public
        onlyOwner
        returns (uint256 amount)
    {
        IERC20(usdtAddress).transfer(msg.sender, _amount);
        return amount;
    }

    // withdraw matic from contract
    function withdrawMATIC(uint256 _amount)
        public
        onlyOwner
        returns (uint256 amount)
    {
        IERC20(maticAddress).transfer(msg.sender, _amount);
        return amount;
    }

    // withdraw weth from contract
    function withdrawWETH(uint256 _amount)
        public
        onlyOwner
        returns (uint256 amount)
    {
        IERC20(wethAddress).transfer(msg.sender, _amount);
        return amount;
    }
}