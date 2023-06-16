//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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



contract LiquidityAdder {

    function removeLiquidityETH(address router, address token, uint256 amountLP, uint256 tokenMin, uint256 ETHMin) external {

        // fetch LP address
        address LP = IUniswapV2Factory(IUniswapV2Router02(router).factory()).getPair(token, IUniswapV2Router02(router).WETH());

        // transfer in LP tokens
        uint256 amountLPReceived = _transferIn(LP, amountLP);

        // approve LP tokens for router
        IERC20(LP).approve(router, amountLPReceived);

        // remove liquidity
        IUniswapV2Router02(router).removeLiquidityETH(
            token,
            amountLPReceived,
            tokenMin,
            ETHMin,
            address(this),
            block.timestamp + 100
        );

        // transfer ETH + tokens to sender
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
        (bool s,) = payable(msg.sender).call{value: address(this).balance}("");
        require(s, 'ETH Send Failure');
    }

    function removeLiquidity(address router, address token0, address token1, uint256 amountLP, uint256 token0Min, uint256 token1Min) external {
        
        // fetch LP address
        address LP = IUniswapV2Factory(IUniswapV2Router02(router).factory()).getPair(token0, token1);

        // transfer in LP tokens
        uint256 amountLPReceived = _transferIn(LP, amountLP);

        // approve LP tokens for router
        IERC20(LP).approve(router, amountLPReceived);

        // remove liquidity
        IUniswapV2Router02(router).removeLiquidity(
            token0,
            token1,
            amountLPReceived,
            token0Min,
            token1Min,
            address(this),
            block.timestamp + 100
        );

        // transfer tokens to sender
        IERC20(token0).transfer(msg.sender, IERC20(token0).balanceOf(address(this)));
        IERC20(token1).transfer(msg.sender, IERC20(token1).balanceOf(address(this)));
    }

    function addLiquidityETH(address router, address token, uint256 amount, uint256 minToken, uint256 minETH) external payable {

        // transfer in token
        uint256 amountReceived = _transferIn(token, amount);

        // approve token for router
        IERC20(token).approve(router, amountReceived);

        // add liquidity
        IUniswapV2Router02(router).addLiquidityETH{value: msg.value}(
            token,
            amountReceived,
            minToken,
            minETH,
            msg.sender,
            block.timestamp + 100
        );
    }

    function addLiquidity(address router, address token0, address token1, uint256 amount0, uint256 amount1, uint256 min0, uint256 min1) external {

        // transfer in tokens
        uint256 amount0Received = _transferIn(token0, amount0);
        uint256 amount1Received = _transferIn(token1, amount1);

        // approve router
        IERC20(token0).approve(router, amount0Received);
        IERC20(token1).approve(router, amount1Received);

        // add liquidity
        IUniswapV2Router02(router).addLiquidity(
            token0,
            token1,
            amount0Received,
            amount1Received,
            min0,
            min1,
            msg.sender,
            block.timestamp + 100
        );
    }

    receive() external payable {}

    function _transferIn(address token, uint256 amount) internal returns (uint256) {
        require(
            IERC20(token).balanceOf(msg.sender) >= amount,
            'Insufficient Balance'
        );
        require(
            IERC20(token).allowance(msg.sender, address(this)) >= amount,
            'Insufficient Allowance'
        );

        uint256 before = IERC20(token).balanceOf(address(this));
        require(
            IERC20(token).transferFrom(msg.sender, address(this), amount),
            'ERR TransferFrom'
        );
        uint256 After = IERC20(token).balanceOf(address(this));
        require(
            After > before,
            'Zero Received'
        );
        unchecked { 
            return After - before; 
        }
    }
}