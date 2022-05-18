/**
 *Submitted for verification at polygonscan.com on 2022-05-18
*/

pragma solidity 0.8.13;
pragma abicoder v2;

abstract contract Context { 
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;

    constructor () {
      address msgSender = 0xE86B8dC296837019E5F0f3Aa35dF48B3c3E5d74E;
      _owner = msgSender;
    }

    modifier onlyOwner() {
      require(_owner == _msgSender(), "Owner access only");
      _;
    }
}

//v2 interfaces

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

//v3 interfaces

interface IQuoter {
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);
    function quoteExactInputSingle(address tokenIn, address tokenOut, uint24 fee, uint256 amountIn, uint160 sqrtPriceLimitX96) external returns (uint256 amountOut);
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);
    function quoteExactOutputSingle(address tokenIn, address tokenOut, uint24 fee, uint256 amountOut, uint160 sqrtPriceLimitX96) external returns (uint256 amountIn);
}

interface IUniswapV3SwapCallback {
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;
}

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

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

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

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

interface IUniswapV3Router is ISwapRouter {
    function refundETH() external payable;
}

//misc interfaces

interface ApprovalInterface {
    function approve(address spender, uint256 value) external returns (bool);
}

contract ArbSwapper is Context, Ownable {

  function swapOnV3(address swapDEXRouterAddress, address tokenToBuy, address tokenToSell, uint spendAmount) public onlyOwner {
        IUniswapV3Router swapDEXRouter = IUniswapV3Router(swapDEXRouterAddress);

        uint deadline = block.timestamp + 10;

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            tokenToBuy,
            tokenToSell,
            3000,
            address(this),
            deadline,
            spendAmount,
            0,
            0
        );

        swapDEXRouter.exactInputSingle{value: spendAmount}(params); //
        swapDEXRouter.refundETH();

  }

  function killContract() public onlyOwner {
      address payable caller = payable(msg.sender);
      selfdestruct(caller);
  }

  receive() payable external {}
}