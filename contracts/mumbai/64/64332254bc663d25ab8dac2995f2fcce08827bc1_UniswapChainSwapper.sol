/**
 *Submitted for verification at polygonscan.com on 2022-07-14
*/

/**
 *Submitted for verification at polygonscan.com on 2022-07-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IRouter {
    function factory() external view returns (address);
    function swapExactTokensForTokens(uint256 amountin,
        uint256 amountOutMin,
        address[2] memory path,
        address to, 
        uint256 deadline) external;
    function getAmountOut(uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut) external view returns (uint256);
}
interface IFactory{
    function allPairs(uint256 a) external view returns (address) ;
    function allPairsLength() external view returns (uint256) ;
}

interface IToken {
    function getReserves() external view returns(uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function token0() external view returns (address token);
    function token1() external view returns (address token);
    function balanceOf(address a) external view returns (uint256) ;
    function decimals() external view returns (uint8);
    function name() external view returns(string memory);
    function symbol() external view returns (string memory) ;
    function approve(address addy, uint256 value) external  ;
}
struct LiquidityPool {
    address poolAddress;
    address[2] tokenAddresses;
    string[2] tokenNames;
    string[2] tokenSymbols;
    uint8[2] tokenDecimals;
}
struct Swap {
    address routerAddress;
    address pairAddress;
    address fromToken;
    address toToken;
    uint256 slip;
    bool approved;
}
contract UniswapChainSwapper {
    string constant ERROR_PERMISSION = "Permission Denied";
    string constant ERROR_SLIPIN = "SLIP IN ERROR";
    string constant ERROR_SLIPOUT = "SLIP OUT ERROR";
    string constant ERROR_TRADE_UNPROFITABLE = "Trade Unprofitable";
    mapping( address => uint8) permissions;

    constructor() public {
        permissions[msg.sender] = uint8(1);
    }

    function grantPermission(address grantee) public {
        permissions[grantee] = 1;
    }

    function getLiquidityPool(address routerAddress, uint32 ordinal) external view returns (LiquidityPool memory pool) {
        IRouter router = IRouter(routerAddress);
        address factoryAddress = router.factory();
        IFactory factory = IFactory(factoryAddress);
        address poolAddress = factory.allPairs(ordinal);
        IToken pair = IToken(pool.poolAddress);
        address token0Address = pair.token0();
        address token1Address = pair.token1();
        IToken token0 = IToken(token0Address);
        IToken token1 = IToken(token1Address);

        pool = LiquidityPool(poolAddress,
            [token0Address, token1Address], 
            [token0.name(), token1.name()],
            [token0.symbol(), token1.symbol()], 
            [token0.decimals(), token1.decimals()]);
    }
    function numPools(address routerAddress) public view returns (uint256) {
        IRouter router = IRouter(routerAddress);
        address factoryAddress = router.factory();
        IFactory factory = IFactory(factoryAddress);
        return factory.allPairsLength();
    }
    function getReserves(address pairAddress) public view returns (uint112 _reserves0, uint112 _reserves1, uint32 _blockTimestampLast){
        IToken pair = IToken(pairAddress);
        return pair.getReserves();
    }

    function CrossDexChainSwap(Swap[] calldata swaps, uint256 primaryReserve) external {
        uint8 i=0;
        uint256 reserve = primaryReserve;
        for(i=0; i< swaps.length; i++)
        {         
            Swap memory swap = swaps[i]; 
            if(!swap.approved){
                IToken fromToken = IToken(swap.fromToken);
                fromToken.approve(swap.routerAddress, 2**256 -1);
            }
            uint256 toBalance;
            {
                IToken toToken = IToken(swap.toToken);
                toBalance = toToken.balanceOf(msg.sender);
            }
            DoSwap(swap, reserve);
            reserve = toBalance;
        }
    }

    function DoSwap(Swap memory swap, uint256 reserve) internal {
        IRouter router = IRouter(swap.routerAddress);
        IToken pair = IToken(swap.pairAddress);
        IToken fromToken  = IToken(swap.fromToken); 
        (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) = pair.getReserves();
        uint256 availableBalance = fromToken.balanceOf(msg.sender) - reserve;
        uint256 amountOutMax = router.getAmountOut(availableBalance, _reserve0, _reserve1 );
        router.swapExactTokensForTokens(availableBalance, amountOutMax - (amountOutMax / swap.slip), [swap.fromToken, swap.toToken], msg.sender, block.timestamp + 1 hours );
    }
}