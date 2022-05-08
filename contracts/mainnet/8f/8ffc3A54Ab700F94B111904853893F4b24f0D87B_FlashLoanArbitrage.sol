pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity 0.8.9;

// import required interfaces
import '@uniswap/v2-core/contracts/interfaces/IERC20.sol';
import "./interfaces/external/univ2/IUniswapV2Router02.sol";
import "./interfaces/external/univ2/IUniswapV2Pair.sol";
import "./interfaces/external/univ2/IUniswapV2Factory.sol";


contract FlashLoanArbitrage {

  //uniswap factory address
  address public factory;

  //create pointer to the sushiswapRouter
  IUniswapV2Router02 public sushiSwapRouter;

    // trader needs to monitor for arbitrage opportunities with a bot or script
    // this is the function that trader will call when an arbitrage opportunity exists
    // tokens are the addresses that you want to trade
    // this first function will create the flash loan on uniswap
    // one of the amounts will be 0 and the other amount will be the amount you want to borrow
    function executeTrade(address token0, address token1, uint amount0, uint amount1, address _factory, address _router) external {
      factory = _factory;
      sushiSwapRouter = IUniswapV2Router02(_router);
      // get liquidity pair address for tokens on uniswap
      address pairAddress = IUniswapV2Factory(factory).getPair(token0, token1);

      // make sure the pair exists in uniswap
      require(pairAddress != address(0), 'Could not find pool on uniswap');

      // create flashloan
      // create pointer to the liquidity pair address
      // to create a flashloan call the swap function on the pair contract
      // one amount will be 0 and the non 0 amount is for the token you want to borrow
      // address is where you want to receive token that you are borrowing
      // bytes can not be empty.  Need to inculde some text to initiate the flash loan
      // if bytes is empty it will initiate a traditional swap
      IUniswapV2Pair(pairAddress).swap(amount0, amount1, address(this), bytes('flashloan'));
    }



      // After the flashloan is created the below function will be called back by Uniswap
      // Uniswap is expecting the function to be named uniswapV2Call
      // the parameters below will be sent
      // sender is the smart contract address
      // amount will be the amount borrowed from the flashloan and other amount will be 0
      // bytes is the calldata passed in above
    function uniswapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external {

      // the path is the array of addresses to capture pricing information
      address[] memory path = new address[](2);

      // get the amount of tokens that were borrowed in the flash loan amount 0 or amount 1
      // call it amountTokenBorrowed and will use later in the function
      uint amountTokenBorrowed = _amount0 == 0 ? _amount1 : _amount0;

      // get the addresses of the two tokens from the uniswap liquidity pool
      address token0 = IUniswapV2Pair(msg.sender).token0();
      address token1 = IUniswapV2Pair(msg.sender).token1();

      // make sure the call to this function originated from
      // one of the pair contracts in uniswap to prevent unauthorized behavior
      require(msg.sender == pairFor(factory, token0, token1), 'Invalid Request');

      // make sure one of the amounts = 0
      require(_amount0 == 0 || _amount1 == 0);

      // create and populate path array for sushiswap.
      // this defines what token we are buying or selling
      // if amount0 == 0 then we are going to sell token 1 and buy token 0 on sushiswap
      // if amount0 is not 0 then we are going to sell token 0 and buy token 1 on sushiswap
      path[0] = _amount0 == 0 ? token1 : token0;
      path[1] = _amount0 == 0 ? token0 : token1;

      // create a pointer to the token we are going to sell on sushiswap
      IERC20 token = IERC20(_amount0 == 0 ? token1 : token0);

      // approve the sushiSwapRouter to spend our tokens so the trade can occur
      token.approve(address(sushiSwapRouter), amountTokenBorrowed);

      // calculate the amount of tokens we need to reimburse uniswap for the flashloan
      uint amountRequired = getAmountsIn(factory, amountTokenBorrowed, path)[0];

      // finally sell the token we borrowed from uniswap on sushiswap
      // amountTokenBorrowed is the amount to sell
      // amountRequired is the minimum amount of token to receive in exchange required to payback the flash loan
      // path what we are selling or buying
      // msg.sender address to receive the tokens
      // deadline is the order time limit
      // if the amount received does not cover the flash loan the entire transaction is reverted
      uint amountReceived = sushiSwapRouter.swapExactTokensForTokens(amountTokenBorrowed, amountRequired, path, msg.sender, block.timestamp + 100)[1];

      // pointer to output token from sushiswap
      IERC20 outputToken = IERC20(_amount0 == 0 ? token0 : token1);

      // amount to payback flashloan
      // amountRequired is the amount we need to payback
      // uniswap can accept any token as payment
      outputToken.transfer(msg.sender, amountRequired);

      // send profit (remaining tokens) back to the address that initiated the transaction
      outputToken.transfer(tx.origin, amountReceived - amountRequired);
    }

    function pairFor(address factory, address tokenA, address tokenB) internal returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        return IUniswapV2Factory(factory).getPair(token0, token1);
    }
//    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
//        (address token0, address token1) = sortTokens(tokenA, tokenB);
//        pair = address(uint160(uint256(keccak256(abi.encodePacked(
//                hex'ff',
//                factory,
//                keccak256(abi.encodePacked(token0, token1)),
//                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
//            )))));
//    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    function sortTokens(address tokenA, address tokenB) internal returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    function getReserves(address factory, address tokenA, address tokenB) internal returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IUniswapV2Factory {
    function getPair(address token0, address token1) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function token0() external view returns (address);

    function token1() external view returns (address);
}

pragma solidity >=0.6.2;

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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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