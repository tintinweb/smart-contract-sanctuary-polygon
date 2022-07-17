/**
 *Submitted for verification at polygonscan.com on 2022-07-16
*/

/**
 *Submitted for verification at polygonscan.com on 2022-07-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
interface IRouter {
    function factory() external view returns (address);
    function swapExactTokensForTokens(uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to, 
        uint256 deadline) external returns (uint[] memory amounts);
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
    function transfer(address _to, uint256 value) external ;
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
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function balanceOf(address _token) public view returns (uint256){
        IToken token = IToken(_token);
        return token.balanceOf(address(this));
    }

    function getLiquidityPool(address routerAddress, uint32 ordinal) external view 
    returns (address  _poolAddress, address[2] memory _tokenAddresses, string[2] memory _tokenNames, string[2] memory _tokenSymbols, uint8[2] memory _tokenDecimals) {
        IRouter router = IRouter(routerAddress);
        address factoryAddress = router.factory();
        IFactory factory = IFactory(factoryAddress);
        address poolAddress = factory.allPairs(ordinal);
        IToken pair = IToken(poolAddress);
        address token0Address = pair.token0();
        address token1Address = pair.token1();
        IToken token0 = IToken(token0Address);
        IToken token1 = IToken(token1Address);

        _poolAddress = poolAddress;
        _tokenAddresses = [token0Address, token1Address]; 
        _tokenNames = [token0.name(), token1.name()];
        _tokenSymbols = [token0.symbol(), token1.symbol()];
        _tokenDecimals = [token0.decimals(), token1.decimals()];
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


    function withdraw(address _token, address _to, uint256 _value) external {
        require(msg.sender == owner, "Access Denied");
        IToken token = IToken(_token);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= _value, "Insufficient Balance");
        token.transfer(_to, _value);
    }

    function CrossDexChainSwap(Swap[] calldata swaps, uint256 primaryReserve) external {
        require(msg.sender == owner, "Access Denied");
        uint256 reserve = primaryReserve;
        
        for(uint i=0; i<swaps.length; i++)
        {
            Swap memory swap = swaps[0]; 
            if(!swap.approved){
                IToken fromToken = IToken(swap.fromToken);
                fromToken.approve(swap.routerAddress, 2**256 -1);
            }
            uint256 toBalance;
            {
                IToken toToken = IToken(swap.toToken);
                toBalance = toToken.balanceOf(address(this));
            }
            DoSwap(swap, reserve);
            reserve = toBalance;
        }
    }

    function DoSwap(Swap memory swap, uint256 reserve) internal {
        IToken fromToken  = IToken(swap.fromToken); 
        uint256 availableBalance = fromToken.balanceOf(address(this)) - reserve;
        
        IRouter router = IRouter(swap.routerAddress);
        (uint112 _inReserve, uint112 _outReserve) = pickReserves(swap.pairAddress, swap.fromToken, swap.toToken);
        uint256 amountOutMax = router.getAmountOut(availableBalance, _inReserve, _outReserve );
        address[] memory tokens = new address[](2);
        tokens[0] = swap.fromToken;
        tokens[1] = swap.toToken;
        router.swapExactTokensForTokens(availableBalance, amountOutMax - (amountOutMax / swap.slip), tokens, address(this), block.timestamp + (5 hours) );
    }

    function pickReserves(address pairAddress, address inTokenAddress, address outTokenAddress) internal returns(uint112 _inReserve, uint112 _outReserve)
    {
        IToken pair = IToken(pairAddress);
        address token0 = pair.token0();
        (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) = pair.getReserves();
        if(token0 == inTokenAddress)
           return (_reserve0, _reserve1);
        else
            return (_reserve1, _reserve0);
    }
}