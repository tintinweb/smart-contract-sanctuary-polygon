/**
 *Submitted for verification at polygonscan.com on 2022-09-23
*/

pragma solidity 0.8.0;

interface IPair {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
    function token0() external view returns(address);
    function token1() external view returns(address);
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address owner) external returns (uint256);
    function approve(address spender, uint256 allowance) external;
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;
}

interface IFactory {
function getPair(address tokenA, address tokenB) external view returns (address pair);

}

contract swapper {
    address v2router;
    address owner;
    address public factory ;
    constructor(address _v2router, address _factory) {
                owner = msg.sender;
                factory = _factory;
    }

    function getPair(address t0, address t1) external view returns (address) {
        return IFactory(factory).getPair(t0, t1);
    }

    function xaswap(
        uint256 amountIn,
        uint256 amountOut,
        address pair,
        address tokenIn,
        address tokenOut,
        bool tokenInFirstIndex
    ) external {
        IERC20(tokenIn).transferFrom(msg.sender, pair, amountIn);
        if (tokenInFirstIndex) {
            IPair(pair).swap(0, amountOut, msg.sender, "0x");
        } else {
            IPair(pair).swap(amountOut, 0, msg.sender, "0x");
        }
        uint256 balance = IERC20(tokenOut).balanceOf(address(this));
        require(balance > 0);
        IERC20(tokenOut).transfer(msg.sender, balance);
    }
}