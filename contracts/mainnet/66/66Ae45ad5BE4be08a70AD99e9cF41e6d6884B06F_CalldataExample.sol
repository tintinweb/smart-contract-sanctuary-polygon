pragma solidity ^0.8.0;

interface ISwapRouter {
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
}

contract CalldataExample {
    address uniswapV3Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564; // Address of Uniswap V3 Router contract

    function prepareExactInputSingleCalldata(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        address recipient,
        uint256 amountIn
    ) public view returns (bytes memory) {
         ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: fee,
                recipient: recipient,
                deadline: block.timestamp + (2 hours),
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });


        bytes memory _data = abi.encodeWithSelector(
            ISwapRouter.exactInputSingle.selector,
            params
        );
        
        return _data;
    }
}