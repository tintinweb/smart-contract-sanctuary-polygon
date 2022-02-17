// SPDX-License-Identifier: MIT

pragma solidity ^0.6.9;


import {IERC20} from "IERC20.sol";


import "dodoV2.sol";

import "IUniswapRouterV2.sol";
import "StableSwap.sol";



contract FlashloanV2 {

    address public owner;

    address public constant ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address public constant ATRIV1 = 0x3FCD5De6A9fC8A99995c406c77DDa3eD7E406f81; // v1
    address public constant ATRIV3 = 0x1d8b86e3D88cDb2d34688e87E72F388Cb541B7C8; // v3
    address public fromToken;
    uint256 public fromTokenInd;
    address public toToken;
    uint256 public toTokenInd;
    uint256 public owed;
    uint256 public bal;

    address public flashLoanPool; //You will make a flashloan from this DODOV2 pool
    address public loanToken;

    bool public tokensSet = false; 


    event BalanceCheck(string aMessage, uint aBalance);
    event FeedBackMessage(string bMessage);

    
    constructor() public{
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Sorry! Only the creator of this contract can use this function.");
        _;
    }


    function flashloan(
        uint256 loanAmount
    ) external  {
        //Note: The data can be structured with any variables required by your logic. The following code is just an example
        bytes memory data = abi.encode(flashLoanPool, loanToken, loanAmount);

        owed = loanAmount;

        address flashLoanBase = IDODO(flashLoanPool)._BASE_TOKEN_();
        if(flashLoanBase == loanToken) {
            IDODO(flashLoanPool).flashLoan(loanAmount, 0, address(this), data);
        } else {
            IDODO(flashLoanPool).flashLoan(0, loanAmount, address(this), data);
        }
    }

    //Note: CallBack function executed by DODOV2(DVM) flashLoan pool
    function DVMFlashLoanCall(address sender, uint256 baseAmount, uint256 quoteAmount,bytes calldata data) external {
        _flashLoanCallBack(sender, baseAmount, quoteAmount, data);
    }

    //Note: CallBack function executed by DODOV2(DPP) flashLoan pool
    function DPPFlashLoanCall(address sender, uint256 baseAmount, uint256 quoteAmount, bytes calldata data) external {
        _flashLoanCallBack(sender, baseAmount, quoteAmount, data);
    }

    //Note: CallBack function executed by DODOV2(DSP) flashLoan pool
    function DSPFlashLoanCall(address sender, uint256 baseAmount, uint256 quoteAmount, bytes calldata data) external {
        _flashLoanCallBack(sender, baseAmount, quoteAmount, data);
    }

    function _flashLoanCallBack(address sender, uint256, uint256, bytes calldata data) internal {
        (address _flashLoanPool, address _loanToken, uint256 loanAmount) = abi.decode(data, (address, address, uint256));
        
        require(sender == address(this) && msg.sender == _flashLoanPool, "HANDLE_FLASH_NENIED");





        //===========Note: Realize your own logic using the token from flashLoan pool.==========


        require(tokensSet, "Tokens not set");

        emit BalanceCheck( 'pre-operation balance', IERC20(fromToken).balanceOf(address(this)) );

        swap_curve(ATRIV3, IERC20(fromToken).balanceOf(address(this)));
        swap_quickswap(IERC20(toToken).balanceOf(address(this)));

        bal = IERC20(fromToken).balanceOf(address(this));

        emit BalanceCheck( 'post-operation balance', IERC20(fromToken).balanceOf(address(this)) );
        emit BalanceCheck( 'borrowed amount', owed );

        if(bal > owed){
            emit FeedBackMessage( 'May trigger require statement to go false' );
        }
        require(bal > owed, "Did not make profit");
        

        
        // * Approve the LendingPool contract allowance to *pull* the owed amount
        IERC20(fromToken).approve(address(_flashLoanPool), loanAmount);


        // ================================= End of Logic =======================================





        //Return funds
        IERC20(_loanToken).transfer(_flashLoanPool, loanAmount);

        emit FeedBackMessage('Flashloan successful');
        emit BalanceCheck( 'final balance', IERC20(fromToken).balanceOf(address(this)) );

    }



    function swap_quickswap(uint256 amount) public {
        address[] memory path;
        path = new address[](2);
        path[0] = toToken;
        // path[1] = WMATIC;
        path[1] = fromToken;
        IUniswapRouterV2(ROUTER).swapExactTokensForTokens(amount, 1, path, address(this), block.timestamp + 99999999);
    }

    function swap_curve(address from_pool, address to_pool, uint256 amount) public {
        StableSwap(from_pool).exchange_underlying(fromTokenInd, toTokenInd, amount, 1);

        StableSwap(to_pool).exchange_underlying(toTokenInd, fromTokenInd, IERC20(toToken).balanceOf(address(this)), 1);
    }

    function swap_curve(address from_pool, uint256 amount) public {
        StableSwap(from_pool).exchange_underlying(fromTokenInd, toTokenInd, amount, 1);
    }

    function setTokens(address lendingPool, address borrowedToken, address from, uint256 fromInd, address to, uint256 toInd) public onlyOwner {
        flashLoanPool = lendingPool;
        loanToken = borrowedToken;
        
        fromToken = from;
        fromTokenInd = fromInd;
        toToken = to;
        toTokenInd = toInd;
        tokensSet = true;

        IERC20(toToken).approve(ROUTER, type(uint256).max);
        // IERC20(toToken).approve(ATRIV3, type(uint256).max);
        // IERC20(fromToken).approve(ROUTER, type(uint256).max);
        IERC20(fromToken).approve(ATRIV3, type(uint256).max);
    }

    function getProfit(address _asset) public onlyOwner {
        
        IERC20(fromToken).transfer(msg.sender, IERC20(fromToken).balanceOf(address(this)));
        // withdraw(_asset);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.9;

interface IERC20 {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.9;

interface IDODO {
    function flashLoan(
        uint256 baseAmount,
        uint256 quoteAmount,
        address assetTo,
        bytes calldata data
    ) external;

    function _BASE_TOKEN_() external view returns (address);
}

interface IDODOCallee {
    function DVMSellShareCall(
        address payable assetTo,
        uint256,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata
    ) external;

    function DPPFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.9;

interface IUniswapRouterV2 {
    function factory() external view returns (address);
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

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.9;

interface StableSwap {
    function exchange_underlying(uint256 assetA, uint256 assetB, uint256 amount, uint256 minAmount) external;
}