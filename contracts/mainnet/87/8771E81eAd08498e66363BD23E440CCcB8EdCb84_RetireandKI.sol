// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface IStaking {
        function stake( uint _amount, address _recipient ) external returns ( bool );
        function claim ( address _recipient ) external;
        function rebase() external;
        function unstake( uint _amount, bool _trigger ) external;
}


interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

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

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}



interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}


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
    function transferFrom(
        address sender,
        address recipient,
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

interface IRetire {
     function retireCarbon(
        address _sourceToken,
        address _poolToken,
        uint256 _amount,
        bool _amountInCarbon,
        address _beneficiaryAddress,
        string memory _beneficiaryString,
        string memory _retirementMessage
    ) external;
    /*Not necessary for this test
    function KLIMA() external view returns (address);
    function sKLIMA() external view returns (address);
    function wsKLIMA() external view returns (address);
    function USDC() external view returns (address);
    function staking() external view returns (address);
    function stakingHelper() external view returns (address);
    function treasury() external view returns (address);
    function klimaRetirementStorage() external view returns (address);
    */
}

interface IarKLIMA {
    function wrap( uint _amount ) external returns ( uint );
}

//ideally replace these "magic numbers" with constructors
address constant AggregatorAdd = 0xEde3bd57a04960E6469B70B4863cE1c9d9363Cb8;
address constant SushiRouterAdd = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
address constant KswapRouterAdd = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
address constant MCO2Add = 0xAa7DbD1598251f856C12f63557A4C4397c253Cea;
address constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
address constant BCTAdd = 0x2F800Db0fdb5223b3C3f354886d907A671414A7F;
address constant MCO2BondAdd = 0x27217c3F5bEc4c12Fa506A101bC4bd15417AEAa8; 
address constant KLIMA = 0x4e78011Ce80ee02d2c3e649Fb657E45898257815;
address constant staking = 0x25d28a24Ceb6F81015bB0b2007D795ACAc411b4d;
address constant sKLIMA = 0xb0C22d8D350C67420f06F48936654f567C73E8C8;
address constant KLIMAUSDC = 0x5786b267d35F9D011c4750e0B0bA584E1fDbeAD1;
//address constant GWAMILabsAdd = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

/// @dev note on tests so far: the function seems to return a weird string
///      rather than uint. this might be to do with it modifying the state.
contract RetireandKI {
    
    uint public slippageFactor = 50;//add one decimal place
    uint public USDCFromSwap;
    uint public KLIMAFromSwap;
    uint public amtLastStaked;
    uint public amtLastWrapped;
    uint public arKLIMABalance;
    address public arKLIMA;
    address public beneficiary;

    constructor( address _arKLIMA, address _beneficiary) {
        require(_arKLIMA != address(0), "arKLIMA incorrect address!");
        arKLIMA = _arKLIMA;
        beneficiary = _beneficiary;
    }
    

    function retireAndKI() public payable {
        require(msg.value >= 1 ether, "Remainder must be at least 1 Matic");
        swapMaticToUSDC();
        retireBCT((USDCFromSwap * 50) / 1000 );
        stakeinKI ((USDCFromSwap * 50) / 1000 );
        
        //current simple logic:
        uint256 DollarsRemaining = IERC20(USDC).balanceOf(address(this));
        
        IERC20(USDC).approve(beneficiary, DollarsRemaining);
        IERC20(USDC).transfer(beneficiary, DollarsRemaining);

    }

    /// @notice swap all value received to USDC.
    function swapMaticToUSDC() private {
        IUniswapV2Router02 sushiswap = IUniswapV2Router02(SushiRouterAdd);
        address wMatic = sushiswap.WETH();
        address [] memory path = new address[](2);
        path[0] = wMatic;
        path[1] = USDC;
        uint sellAmount = (msg.value*990)/1000;
        uint256[] memory minOut 
                    = sushiswap.getAmountsOut(sellAmount, path);
        
        uint[] memory  amounts = sushiswap.swapExactETHForTokens{value:sellAmount}(
                                    (minOut[1]
                                        *(1000-slippageFactor))/1000,
                                    path,
                                    address(this),
                                    block.timestamp+10*5 
                                        );
        USDCFromSwap = amounts[amounts.length-1];
        
    }

    function retireBCT(uint _retireAmt) private {
        IRetire Aggregator = IRetire(AggregatorAdd);
        IERC20(USDC).approve(AggregatorAdd, _retireAmt);
        Aggregator.retireCarbon(
            USDC,
            BCTAdd,
            _retireAmt,
            false,
            msg.sender,
            "KNS",
            "KNS"
        );

    }


    function stakeinKI( uint _USDCAmt) private {
         
        _swapUSDCToKlima(_USDCAmt);
        _stakeKLIMA();
        _wrapArKLIMA();
        
    }

    function _swapUSDCToKlima(uint _USDCAmt) private {
        
        IERC20(USDC).approve(SushiRouterAdd, _USDCAmt);
        IUniswapV2Router02 sushiswap = IUniswapV2Router02(SushiRouterAdd);
        address token0 = IUniswapV2Pair(KLIMAUSDC).token0();
        address token1 = IUniswapV2Pair(KLIMAUSDC).token1();

        address[] memory path = new address[](2);
        if (token0 == USDC) {
                    path[0] = token0;
                    path[1] = token1;
        } else {
                    path[1] = token0;
                    path[0] = token1;
        }

        uint256[] memory minOut 
                    = sushiswap.getAmountsOut(_USDCAmt, path);
        
        uint[] memory  amounts = sushiswap.swapExactTokensForTokens(
                                    _USDCAmt,
                                    (minOut[1]
                                        *(1000-slippageFactor))/1000,
                                    path,
                                    address(this),
                                    block.timestamp 
                                        );
        
        KLIMAFromSwap = amounts[amounts.length-1];
        require(KLIMAFromSwap >0, "Didn't process swap to klima properly");
    }

    function _stakeKLIMA() private {
        uint AmounttoStake = IERC20(KLIMA).balanceOf(address(this));
        IERC20(KLIMA).approve(staking, AmounttoStake);
        IStaking(staking).stake(AmounttoStake, address(this));
        IStaking(staking).claim(address(this));
    }
    

    function _wrapArKLIMA() private {
        uint AmountToWrap = IERC20(sKLIMA).balanceOf(address(this));
        IERC20(sKLIMA).approve(arKLIMA, AmountToWrap);
        amtLastWrapped = IarKLIMA(arKLIMA).wrap(AmountToWrap);
        arKLIMABalance += amtLastWrapped;
    }

}