/**
 *Submitted for verification at polygonscan.com on 2023-06-16
*/

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

interface ISTSP {
    function mintWithBacking(uint256 numTokens, address recipient) external returns (uint256);
    function sell(uint256 tokenAmount) external returns (uint256);
}

/**
    Arbitrage As A Service Contract
 */
contract AAAS {

    /** Wrapped MATIC */
    address public constant WETH = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    /** USDC */
    address public constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    /** STS+ */
    address public STSP;

    /** Wallet To Receive Dev Percent Of Profit Generated */
    address public devFeeReceiver;

    /** Wallet To Receive Client Percent Of Profit Gained */
    address public clientFeeReceiver;

    /** Mapping from address to permission to access arby */
    mapping ( address => bool ) public isAllowedToTrigger;

    /** Percentage of profits retained by dev */
    uint256 public profitPercentage = 30;

    mapping (address => bool) public approvedStables;

    /** Contract Operator */
    address public operator;
    modifier onlyOperator(){
        require(msg.sender == operator, 'Only Operator');
        _;
    }

    constructor(
        address devFeeReceiver_,
        address clientFeeReceiver_,
        address STSP_
    ){
        devFeeReceiver = devFeeReceiver_;
        clientFeeReceiver = clientFeeReceiver_;
        STSP = STSP_;
        operator = msg.sender;
    }

    // operator functions
    function withdraw(address token) external onlyOperator {
        IERC20(token).transfer(operator, IERC20(token).balanceOf(address(this)));
    }

    function withdraw() external onlyOperator {
        (bool s,) = payable(operator).call{value: address(this).balance}("");
        require(s);
    }

    function changeOwner(address newOwner) external onlyOperator {
        operator = newOwner;
    }

    function setDevFeeRecipient(address newRecipient) external onlyOperator {
        devFeeReceiver = newRecipient;
    }

    function setClientFeeRecipient(address newRecipient) external onlyOperator {
        clientFeeReceiver = newRecipient;
    }

    function setCanTrigger(address user, bool canTrigger) external onlyOperator {
        isAllowedToTrigger[user] = canTrigger;
    }

    function setProfitPercentage(uint256 newProfitPercentage) external onlyOperator {
        profitPercentage = newProfitPercentage;
    }

    function setSTSP(address STSP_) external onlyOperator {
        STSP = STSP_;
    }

    // BNB -> Token0 on Sushi Swap
    // Token0 -> BNB on Pancake Swap
    // Token0: [BNB, Token0]
    // Token1: [Token0, BNB]
    // DEXES:  [Sushi, Pancake]
    function trigger(
        address[] calldata token0,
        address[] calldata token1,
        address[] calldata DEXes,
        uint256 gasCost
    ) external payable {

        // ensure sender is allowed to trigger
        require(
            isAllowedToTrigger[msg.sender],
            'Invalid Permissions'
        );

        // define minimum value received
        uint256 minValueBack = msg.value + gasCost;

        // cycle through swaps
        uint len = DEXes.length;
        for (uint i = 0; i < len;) {
            
            uint256 _token0Modified = token0[i] == WETH ? address(this).balance : IERC20(token0[i]).balanceOf(address(this));

            handleSwaps(
                DEXes[i], 
                token0[i], 
                token1[i], 
                _token0Modified
            );
            unchecked { ++i; }
        }

        // check profitability
        require(
            address(this).balance >= minValueBack,
            'Non Profitable'
        );

        // send value plus gas back to sender
        (bool s,) = payable(msg.sender).call{value: minValueBack}("");
        require(s);

        // split profits between client and dev
        uint256 forDev = ( address(this).balance * profitPercentage ) / 100;
        uint256 forClient = address(this).balance - forDev;

        // send profits to respective addresses
        if (forDev > 0) {
            (bool s1,) = payable(devFeeReceiver).call{value: forDev}("");
            require(s1, 'Failure On Dev Transfer');
        }
        if (forClient > 0) {
            (bool s2,) = payable(clientFeeReceiver).call{value: forClient}("");
            require(s2, 'Failure On Client Transfer');
        }
    }


    function handleSwaps(
        address DEX, 
        address _token0, 
        address _token1, 
        uint256 amount
    ) internal {

        if (_token0 == STSP && approvedStables[_token1]) {
            // Sell STSP Via Contract
            _sellSTSP(amount);
        } else if (_token1 == STSP && approvedStables[_token0]) {
            // Buy STSP Via Contract
            _mintSTSP(amount);
        } else if (_token1 == WETH) {
            // DEX Sell 
            _sellTokenForBNB(DEX, _token0, amount);
        } else if (_token0 == WETH) {
            // DEX Buy
            _buyTokenWithBNB(DEX, _token1, amount);
        } else {
            // DEX Swap
            _swapTokenForToken(DEX, _token0, _token1, amount);
        }

    }

    // DEX Router Swaps

    function _sellSTSP(uint256 amount) internal {
        ISTSP(STSP).sell(amount);
    }

    function _mintSTSP(uint256 amount) internal {
        IERC20(USDC).approve(STSP, amount);
        ISTSP(STSP).mintWithBacking(amount, address(this));
    }

    function _swapTokenForToken(address DEX, address tokenIn, address tokenOut, uint256 amountTokenIn) internal {

        // instantiate DEX router
        IUniswapV2Router02 router = IUniswapV2Router02(DEX);

        // define swap path
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        // make approval
        IERC20(tokenIn).approve(DEX, amountTokenIn);

        // make the swap
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountTokenIn, 0, path, address(this), block.timestamp + 3000);
    
        // clear saved data
        delete path;
    }

    function _sellTokenForBNB(address DEX, address token, uint256 amount) internal {

        // instantiate DEX router
        IUniswapV2Router02 router = IUniswapV2Router02(DEX);

        // define swap path
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = WETH;

        // make approval
        IERC20(token).approve(DEX, amount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, address(this), block.timestamp + 3000);

        // clear saved data
        delete path;
    }

    function _buyTokenWithBNB(address DEX, address token, uint256 amount) internal {

        // instantiate DEX router
        IUniswapV2Router02 router = IUniswapV2Router02(DEX);

        // define swap path
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = token;

        // make the swap
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(0, path, address(this), block.timestamp + 3000);
    
        // clear saved data
        delete path;
    }


    // On MATIC Received
    receive() external payable {}

}