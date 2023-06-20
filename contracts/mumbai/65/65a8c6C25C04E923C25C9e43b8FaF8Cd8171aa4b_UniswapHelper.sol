/**
 *Submitted for verification at polygonscan.com on 2023-06-20
*/

pragma solidity =0.6.6;
pragma experimental ABIEncoderV2;


interface IUniswapV2Factory {
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
}

interface IUniswapV2Pair {
    function decimals() external pure returns (uint8);
    function balanceOf(address owner) external view returns (uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function totalSupply() external view returns (uint);
}

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract UniswapHelper {

    address immutable public factory;

    constructor(address _factory) public {
        factory = _factory;
    }

    struct BalanceOfPair {
        address token0;
        string tokenName0;
        string tokenSymbol0;
        uint8 tokenDecimals0;
        uint112 reserve0;
        address token1;
        string tokenName1;
        string tokenSymbol1;
        uint8 tokenDecimals1;
        uint112 reserve1;
        uint8 decimals;
        uint balance;
        uint totalSupply;
    }

    function getListPool(address _address) public view returns (BalanceOfPair[] memory) {
        uint pairsLength = IUniswapV2Factory(factory).allPairsLength();

        BalanceOfPair[] memory balances = new BalanceOfPair[](pairsLength);

        for(uint i = 0; i < pairsLength; i++) {
            address pair = IUniswapV2Factory(factory).allPairs(i);
            (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();

            balances[i] = BalanceOfPair({
                token0: IUniswapV2Pair(pair).token0(),
                tokenName0: IERC20(IUniswapV2Pair(pair).token0()).name(),
                tokenSymbol0: IERC20(IUniswapV2Pair(pair).token0()).symbol(),
                tokenDecimals0: IERC20(IUniswapV2Pair(pair).token0()).decimals(),
                reserve0: reserve0,
                token1: IUniswapV2Pair(pair).token1(),
                tokenName1: IERC20(IUniswapV2Pair(pair).token1()).name(),
                tokenSymbol1: IERC20(IUniswapV2Pair(pair).token1()).symbol(),
                tokenDecimals1: IERC20(IUniswapV2Pair(pair).token1()).decimals(),
                reserve1: reserve1,
                decimals: IUniswapV2Pair(pair).decimals(),
                balance: IUniswapV2Pair(pair).balanceOf(_address),
                totalSupply: IUniswapV2Pair(pair).totalSupply()
            });
        }

        return balances;
    }
}