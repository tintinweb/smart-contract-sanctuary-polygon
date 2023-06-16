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

interface IYield {
    function stake(address user, uint256 amount) external;
    function taxlessWithdraw(address user, uint256 amount) external;
    function token() external view returns (address);
}

interface IStable {
    function sell(uint256 tokenAmount) external returns (uint256);
}

contract TaxlessWithdrawContract {

    uint256 public switchTax = 20; // 2%
    uint256 public constant TAX_DENOM = 1000;

    // farm addresses
    address public farm0;
    address public farm1;

    // setter address
    address public setter;

    // STS
    address public immutable STS;
    address public immutable STSP;
    address public immutable Underlying;

    // Switch Tax receiver
    address public feeReceiver;

    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    address public ZERO = 0x0000000000000000000000000000000000000000;

    // router address
    IUniswapV2Router02 public router;

    // Events
    event SetSetter(address indexed setter_);
    event SetFarms(address indexed farm0_, address indexed farm1_);
    event SetSwitchTax(uint256 newTax);
    event SetRouter(address newRouter);
    event FeeReceiverSet(address newReceiver);
    event SwitchFarm(address src, address dst, uint256 amount, uint256 minOut, bool srcFromETH);

    constructor(
        address farm0_, 
        address farm1_, 
        address router_, 
        address STS_, 
        address STSP_, 
        address Underlying_, 
        address feeReceiver_
    ) {
        farm0 = farm0_;
        farm1 = farm1_;
        router = IUniswapV2Router02(router_);
        STS = STS_;
        STSP = STSP_;
        Underlying = Underlying_;
        feeReceiver = feeReceiver_;
        setter = msg.sender;
    }

    function setSetter(address setter_) external {
        require(msg.sender == setter, 'Only Setter');
        require(goodAddress(setter_) == true, 'Invalid Address!');
        setter = setter_;

        emit SetSetter(setter_);
    }

    function setFarms(address farm0_, address farm1_) external {
        require(msg.sender == setter, 'Only Setter');
        require(goodAddress(farm0_) == true, 'Invalid Address!');
        require(goodAddress(farm1_) == true, 'Invalid Address!');
        farm0 = farm0_;
        farm1 = farm1_;

        emit SetFarms(farm0_, farm1_);
    }

    function setSwitchTax(uint256 newTax) external {
        require(msg.sender == setter, 'Only Setter');
        switchTax = newTax;

        emit SetSwitchTax(newTax);
    }

    function setRouter(address newRouter) external {
        require(msg.sender == setter, 'Only Setter');
        require(goodAddress(newRouter) == true, 'Invalid Address!');
        router = IUniswapV2Router02(newRouter);

        emit SetRouter(newRouter);
    }

    function setFeeReceiver(address newReceiver) external {
        require(msg.sender == setter, 'Only Setter');
        require(goodAddress(newReceiver) == true, 'Invalid Address!');
        feeReceiver = newReceiver;

        emit FeeReceiverSet(newReceiver);
    }

    function withdraw(address token) external {
        require(msg.sender == setter, 'Only Setter');
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }
    
    function withdrawETH() external {
        require(msg.sender == setter, 'Only Setter');
        (bool s,) = payable(msg.sender).call{value: address(this).balance}("");
        require(s);
    }

    function switchFarm(address src, address dst, uint256 amount, uint256 minOut, bool srcFromETH) external {
        require(
            ( src == farm0 || src == farm1 ) && ( dst == farm0 || dst == farm1 ),
            'Invalid Src or Dest'
        );

        // fetch LP tokens from both yield sources
        address srcToken = IYield(src).token();
        address dstToken = IYield(dst).token();

        // remove LPs tax free from old farm
        IYield(src).taxlessWithdraw(msg.sender, amount);

        // calculate amount of LP tokens
        uint256 amountReceived = IERC20(srcToken).balanceOf(address(this));

        // calculate switch fee
        uint256 fee = ( amountReceived * switchTax ) / TAX_DENOM;

        // determine amount to break, sub fee
        uint256 received = amountReceived - fee;

        // take switch fee
        if (fee > 0) {
            IERC20(srcToken).transfer(feeReceiver, fee);
        }

        // break LP received
        IERC20(srcToken).approve(address(router), received);
        if (srcFromETH) {

            // remove liquidity with ETH
            router.removeLiquidityETHSupportingFeeOnTransferTokens(
                STS, received, 1, 1, address(this), block.timestamp + 100
            );

            // ETH -> STSP
            (bool s,) = payable(STSP).call{value: address(this).balance}("");
            require(s);

            // Pair STS and STSP into LP
            uint stsBal = IERC20(STS).balanceOf(address(this));
            uint stspBal = IERC20(STSP).balanceOf(address(this));
            IERC20(STS).approve(address(router), stsBal);
            IERC20(STSP).approve(address(router), stspBal);

            // add to liquidity
            router.addLiquidity(STS, STSP, stsBal, stspBal, 1, 1, address(this), block.timestamp + 100);

            // stake new liquidity into farm
            uint newBal = IERC20(dstToken).balanceOf(address(this));
            require(
                newBal >= minOut,
                'Min Out Not Preserved'
            );
            IERC20(dstToken).approve(dst, newBal);
            IYield(dst).stake(msg.sender, newBal);

            // refund dust
            stsBal = IERC20(STS).balanceOf(address(this));
            stspBal = IERC20(STSP).balanceOf(address(this));
            if (stsBal > 0) {
                IERC20(STS).transfer(msg.sender, stsBal);
            }
            if (stspBal > 0) {
                IERC20(STSP).transfer(msg.sender, stspBal);
            }

        } else {

            // remove liquidity between two tokens
            router.removeLiquidity(
                STS, STSP, received, 1, 1, address(this), block.timestamp + 100
            );

            // STSP -> USDC
            IStable(STSP).sell(IERC20(STSP).balanceOf(address(this)));

            // USDC -> ETH
            IERC20(Underlying).approve(address(router), 10**50);
            address[] memory path = new address[](2);
            path[0] = Underlying;
            path[1] = router.WETH();
            router.swapExactTokensForETH(
                IERC20(Underlying).balanceOf(address(this)), 
                1, path, address(this), block.timestamp + 100
            );

            // remove path for memory
            delete path;

            // pair STS and ETH into liquidity
            uint stsBal = IERC20(STS).balanceOf(address(this));
            IERC20(STS).approve(address(router), stsBal);
            router.addLiquidityETH{value: address(this).balance}(
                STS, stsBal, 1, 1, address(this), block.timestamp + 100
            );

            // stake new LP tokens
            uint newBal = IERC20(dstToken).balanceOf(address(this));
            require(
                newBal >= minOut,
                'Min Out Not Preserved'
            );
            IERC20(dstToken).approve(dst, newBal);
            IYield(dst).stake(msg.sender, newBal);

            // refund dust
            stsBal = IERC20(STS).balanceOf(address(this));
            if (stsBal > 0) {
                IERC20(STS).transfer(msg.sender, stsBal);
            }
            if (address(this).balance > 0) {
                (bool s,) = payable(msg.sender).call{value: address(this).balance}("");
                require(s);
            }
        }

        emit SwitchFarm(src, dst, amount, minOut, srcFromETH);
    }

    receive() external payable {}

    function goodAddress(address _target) internal returns (bool) {
        if (
            _target == DEAD || 
            _target == ZERO
        ) {
            return false;
        } else {
            return true;
        }
    }
}