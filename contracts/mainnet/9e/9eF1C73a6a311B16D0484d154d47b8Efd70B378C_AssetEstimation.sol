// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

//import "../openzeppelin/Ownable.sol";
//import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
//import "../openzeppelin/OwnableUpgradeable.sol";
//import "../token/ERC20Interface.sol";
import "./Exponential.sol";


library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x / y) * y == x, 'ds-math-div-overflow');
    }
}

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

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Pair {
    function totalSupply() external view returns (uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IDeveloperLendLens {
    function currentExchangeRateStored(address pToken) external view returns (uint);

    function getUnderlyingByPToken(address underlying) external view returns (address pToken);
}

contract AssetEstimation is Exponential{
    //最低流动性
    uint public constant MINIMUM_LIQUIDITY = 10**3;
    // LEND封装查询接口
    IDeveloperLendLens public developerLendLens;
    // swap工厂合约
    IUniswapV2Factory public quickFactory;
    IUniswapV2Factory public dpFactory;

    address public WETH;

    address public owner;

    constructor() public {
        developerLendLens = IDeveloperLendLens(address(0x76831939fc9A078a9Fd4A5B005C8A19c9012bA45));
        quickFactory = IUniswapV2Factory(address(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32));
        dpFactory = IUniswapV2Factory(address(0xccAD9555bd30E3847344768Bf12Dd8Fed16e567C));
        WETH = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
        //将 msg.sender 设置为初始所有者。
        owner = msg.sender;
    }

    // lend存款预估值
    function lendEstimation(address token, uint amount) external view returns(uint quantity, uint8 decimals) {
        // require(msg.sender == owner, "sender is not owner");
        address pToken = developerLendLens.getUnderlyingByPToken(token);
        decimals = IERC20(pToken).decimals();
        uint exchange = developerLendLens.currentExchangeRateStored(pToken);
        uint _amount = amount;
        ( , quantity) = divScalarByExpTruncate(_amount, Exp({mantissa : exchange}));

        //uint a = (amount * 1e36) / exchange
        //uint b = a / 1e18;
    }

    // swapETH预估值
    function quickSwapETHEstimation(address token, uint amountTokenDesired, uint amountETHDesired) external view returns(address pair, uint8 decimals, uint liquidity){
        (pair, decimals, liquidity) = quickSwapEstimation(WETH, token, amountETHDesired, amountTokenDesired);
    }

    // swap流动性预估值
    function quickSwapEstimation(address tokenA, address tokenB, uint amountADesired, uint amountBDesired) public view returns(address pair, uint8 decimals, uint liquidity) {
        pair = quickFactory.getPair(tokenA, tokenB);
        decimals = IERC20(pair).decimals();
        (uint112 _reserve0, uint112 _reserve1, ) = IUniswapV2Pair(pair).getReserves();
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        uint balance0 = IERC20(token0).balanceOf(pair);
        uint balance1 = IERC20(token1).balanceOf(pair);
        balance0 = add_(balance0, amountADesired);
        balance1 = add_(balance1, amountBDesired);
        uint amount0 = sub_(balance0, _reserve0);
        uint amount1 = sub_(balance1, _reserve1);
        uint _totalSupply = IUniswapV2Pair(pair).totalSupply();
        if (_totalSupply == 0) {
            uint min = Math.sqrt(mul_(amount0, amount1));
            liquidity = sub_(min, MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min(mul_(amount0, _totalSupply) / _reserve0, mul_(amount1, _totalSupply) / _reserve1);
        }
    }


    function dpSwapETHEstimation(address token, uint amountTokenDesired, uint amountETHDesired) external view returns(address pair, uint8 decimals, uint liquidity){
        (pair, decimals, liquidity) = dpSwapEstimation(WETH, token, amountETHDesired, amountTokenDesired);
    }

    function dpSwapEstimation(address tokenA, address tokenB, uint amountADesired, uint amountBDesired) public view returns(address pair, uint8 decimals, uint liquidity) {
        pair = dpFactory.getPair(tokenA, tokenB);
        decimals = IERC20(pair).decimals();
        (uint112 _reserve0, uint112 _reserve1, ) = IUniswapV2Pair(pair).getReserves();
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        uint balance0 = IERC20(token0).balanceOf(pair);
        uint balance1 = IERC20(token1).balanceOf(pair);
        balance0 = add_(balance0, amountADesired);
        balance1 = add_(balance1, amountBDesired);
        uint amount0 = sub_(balance0, _reserve0);
        uint amount1 = sub_(balance1, _reserve1);
        uint _totalSupply = IUniswapV2Pair(pair).totalSupply();
        if (_totalSupply == 0) {
            uint min = Math.sqrt(mul_(amount0, amount1));
            liquidity = sub_(min, MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min(mul_(amount0, _totalSupply) / _reserve0, mul_(amount1, _totalSupply) / _reserve1);
        }
    }


}