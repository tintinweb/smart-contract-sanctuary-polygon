//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IUniswapV2Router02.sol";
import "./IERC20.sol";

interface IToken {
    function getOwner() external view returns (address);
}

interface IFarm {
    function stake(address user, uint256 amount) external;
}

interface IStable {
    function burn(uint256 amount) external;
}

/**
    Zapping into farms and staking to bypass the Buy Tax (5%).
    Requires MATIC to zap.
    Still subject to the 2% stake fee or 4% farm deposit fee.
 */

contract Zapper {

    // STS+ Fees
    uint256 public constant STSP_buy_fee = 1;
    uint256 public constant FEE_DENOM = 100;

    // Router
    IUniswapV2Router02 public immutable router;
    
    // Tokens
    address public immutable STS;
    address public immutable STSP;
    
    // Farms
    address public immutable STS_STSP_FARM;
    address public immutable STS_MATIC_FARM;
    address public immutable STS_STAKE;

    // LP Tokens
    address public immutable STS_STSP_LP;
    address public immutable STS_MATIC_LP;

    // Swap Path
    address[] private STS_Swap_Path;

    modifier onlyOwner() {
        require(
            msg.sender == IToken(STS).getOwner(),
            'Only Owner'
        );
        _;
    }

    // Events
    event Zap(address indexed farmAddress, uint256 mintOut);
    event BuySts(uint256 val, uint256 minOut);
    event BuyStsp(uint256 val);

    constructor(
        address router_,
        address STS_,
        address STSP_,
        address STS_STSP_FARM_,
        address STS_MATIC_FARM_,
        address STS_STAKE_,
        address STS_STSP_LP_,
        address STS_MATIC_LP_
    ) {
        router = IUniswapV2Router02(router_);
        STS = STS_;
        STSP = STSP_;
        STS_STSP_FARM = STS_STSP_FARM_;
        STS_MATIC_FARM = STS_MATIC_FARM_;
        STS_STAKE = STS_STAKE_;
        STS_STSP_LP = STS_STSP_LP_;
        STS_MATIC_LP = STS_MATIC_LP_;

        STS_Swap_Path = new address[](2);
        STS_Swap_Path[0] = IUniswapV2Router02(router_).WETH();
        STS_Swap_Path[1] = STS_;
    }

    function zap(address farmAddress, uint256 minOut) external payable {
        require(
            msg.value > 2,
            'Value Too Low'
        );

        if (farmAddress == STS_STAKE) {
            // Single Stake STS

            // Buy STS Tokens, Receiving Balance After Swap
            uint256 balance = buySTS(msg.value, minOut);            

            // Approve of Balance For Staking
            IERC20(STS).approve(STS_STAKE, balance);

            // Deposit STS into staking for caller
            IFarm(STS_STAKE).stake(msg.sender, balance);


        } else if (farmAddress == STS_STSP_FARM) {
            // STS/STS+ Farm

            // split value in two halves
            uint256 halfVal = msg.value / 2;
            uint256 otherHalfVal = msg.value - halfVal;

            // Use half of value to buy STS, other half for STS+
            uint256 STS_BAL = buySTS(halfVal, 0);
            uint256 STSP_BAL = buySTSP(otherHalfVal);

            // approve both tokens for router
            IERC20(STS).approve(address(router), STS_BAL);
            IERC20(STSP).approve(address(router), STSP_BAL);

            // pair STS and STS+ into liquidity
            router.addLiquidity(
                STS,
                STSP,
                STS_BAL,
                STSP_BAL,
                1,
                1,
                address(this),
                block.timestamp + 100
            );

            // ensure minOut is preserved
            uint256 lpBal = IERC20(STS_STSP_LP).balanceOf(address(this));
            require(
                lpBal >= minOut,
                'Insufficient Out'
            );
            
            // approve LP for Farm
            IERC20(STS_STSP_LP).approve(STS_STSP_FARM, lpBal);

            // Stake LPs into Farm for caller
            IFarm(STS_STSP_FARM).stake(msg.sender, lpBal);

            // refund dust
            if (IERC20(STS).balanceOf(address(this)) > 0) {
                IERC20(STS).transfer(msg.sender, IERC20(STS).balanceOf(address(this)));
            }
            if (IERC20(STSP).balanceOf(address(this)) > 0) {
                IERC20(STSP).transfer(msg.sender, IERC20(STSP).balanceOf(address(this)));
            }

        } else if (farmAddress == STS_MATIC_FARM) {
            // STS/MATIC Farm

            // split value in half
            uint256 halfVal = msg.value / 2;

            // Use half of value to buy STS, other half for STS+
            uint256 STS_BAL = buySTS(halfVal, 0);

            // approve STS for router
            IERC20(STS).approve(address(router), STS_BAL);

            // pair STS and STS+ into liquidity
            router.addLiquidityETH{value: msg.value - halfVal}(
                STS,
                STS_BAL,
                1,
                1,
                address(this),
                block.timestamp + 100
            );
            
            // ensure minOut is preserved
            uint256 lpBal = IERC20(STS_MATIC_LP).balanceOf(address(this));
            require(
                lpBal >= minOut,
                'Insufficient Out'
            );
            
            // approve LP for Farm
            IERC20(STS_MATIC_LP).approve(STS_MATIC_FARM, lpBal);

            // Stake LPs into Farm for caller
            IFarm(STS_MATIC_FARM).stake(msg.sender, lpBal);

            // refund dust
            if (IERC20(STS).balanceOf(address(this)) > 0) {
                IERC20(STS).transfer(msg.sender, IERC20(STS).balanceOf(address(this)));
            }
            if (address(this).balance > 0) {
                (bool s,) = payable(msg.sender).call{value: address(this).balance}("");
                require(s);
            }
        }

        emit Zap(farmAddress, minOut);
    }

    function buySTS(uint256 val, uint256 minOut) internal returns (uint256) {
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: val}(minOut, STS_Swap_Path, address(this), block.timestamp + 100);
        emit BuySts(val, minOut);
        return IERC20(STS).balanceOf(address(this));
    }

    function buySTSP(uint256 val) internal returns (uint256) {

        // buy STSP
        (bool s,) = payable(STSP).call{value: val}("");
        require(s, 'FAIL STSP BUY');

        // Determine amount purchased
        uint256 bal = IERC20(STSP).balanceOf(address(this));

        // Determine fee to be burned
        uint256 fee = ( bal * STSP_buy_fee ) / FEE_DENOM;

        // Enforce buy fee
        IStable(STSP).burn(fee);

        emit BuyStsp(val);

        // return balance bought less fee
        return bal - fee;
    }

    function withdraw(address token, address to) external onlyOwner {
        IERC20(token).transfer(to, IERC20(token).balanceOf(address(this)));
    }

    function withdrawETH(address to) external onlyOwner {
        (bool s,) = payable(to).call{value: address(this).balance}("");
        require(s);
    }

}