pragma solidity >=0.8.10;

import "SafeMath.sol";

interface IUniswapV2Router {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Pair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}


contract ArbitrageExecutor {
    using SafeMath for uint;

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint r) internal pure returns (uint amountOut) {
        uint amountInWithFee = amountIn.mul(r);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an input amount of an asset, asset address and pair address, returns the maximum output amount of the other asset
    function getAmountOutForToken(uint amountIn, address tokenInAddr, address pairAddr, uint r) internal view returns (uint256 amountOut) {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddr);
        (uint112 reserve0, uint112 reserve1, )= pair.getReserves();
        amountOut = pair.token0() == tokenInAddr ? getAmountOut(amountIn, reserve0, reserve1, r) : getAmountOut(amountIn, reserve1, reserve0, r);
    }

    // execute call of flashswap interface
    function _callExecute(address sender, uint amount0, uint amount1, bytes calldata data) private {
        (uint initialAmount, uint finalAmount, address pairSellAddr, address sideTokenAddr, address baseTokenAddr) = abi.decode(data, (uint, uint, address, address, address));

        // Swap BaseToken with SideToken on SellPair
        IERC20(baseTokenAddr).transfer(pairSellAddr, amount0 + amount1);
        IUniswapV2Pair(pairSellAddr).swap(
            baseTokenAddr < sideTokenAddr ? 0 : finalAmount,
            baseTokenAddr < sideTokenAddr ? finalAmount : 0,
            sender,
            new bytes(0)
        );
        // Pay back in SideToken to BuyPair
        IERC20(sideTokenAddr).transfer(msg.sender, initialAmount);
    }

    // Delegate for different interfaces
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external {
        _callExecute(sender, amount0, amount1, data);
    }
    function apeCall(address sender, uint amount0, uint amount1, bytes calldata data) external {
        _callExecute(sender, amount0, amount1, data);
    }



    // main function to be called in order to execute arbitrage
    function execute(uint initialAmount, uint profit,
                     address pairBuyAddr, uint pairBuyR,
                     address pairSellAddr, uint pairSellR,
                     address sideTokenAddr, address baseTokenAddr) public {

        // Initial Check
        uint middleAmount = getAmountOutForToken(initialAmount, sideTokenAddr, pairBuyAddr, pairBuyR);
        uint finalAmount = getAmountOutForToken(middleAmount, baseTokenAddr, pairSellAddr, pairSellR);
        require(finalAmount >= initialAmount + profit, "ArbitrageExecutor: Initial check failed!");

        // Borow BaseToken from BuyPair
        IUniswapV2Pair(pairBuyAddr).swap(
            baseTokenAddr < sideTokenAddr ? middleAmount : 0,
            baseTokenAddr < sideTokenAddr ? 0 : middleAmount,
            address(this),
            abi.encode(initialAmount, finalAmount, pairSellAddr, sideTokenAddr, baseTokenAddr)
        );

        // Send profit to contract owner
        IERC20(sideTokenAddr).transfer(msg.sender, finalAmount - initialAmount);
    }
}