/**
 *Submitted for verification at polygonscan.com on 2022-06-25
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IToken {
    function comptroller() external view returns (address);
    function mint(uint mintAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
}

interface EtherIToken is IToken{
    function mint() external payable;
}

interface IComptroller {
    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function getAccountLiquidity(address account) external view returns (uint, uint, uint);
    function oracle() external view returns (address);
}

interface IOracle{
    function getUnderlyingPrice(address market) external view returns(uint);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient,uint256 amount ) external returns (bool);
}



contract MintXAndBorrowY {
    uint constant MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    IUniswapV2Router02 public router = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    IUniswapV2Pair constant pair = IUniswapV2Pair(0xf04adBF75cDFc5eD26eeA4bbbb991DB002036Bdd);

   address constant nativeToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address constant tokenX = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant tokenY = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063; 
    address constant marketX = 0x12D803497D1e58dD4D4A4F455D754f1d0F937C8b;
    address constant marketY = 0x5cFad792C4Df1323188180778AeC58E00eAcE32a;


    address public owner;
    
    constructor() {
        owner = msg.sender;
    }

    function exec(uint amount) public {

        uint amount0 = pair.token0() == tokenX ? amount : 0;
        uint amount1 = amount0 == 0 ? amount : 0;

        pair.swap(amount0, amount1, address(this), abi.encode(""));
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external {
        sender;data;

        uint amount = amount0 == 0 ? amount1 : amount0;

        if(tokenX == nativeToken){
            IWETH wappedToken = IWETH(router.WETH());
            wappedToken.withdraw(amount);
            EtherIToken(marketX).mint{value:amount}();
        }else{
            IERC20(tokenX).approve(marketX, amount);
            IToken(marketX).mint(amount);
        }

        IComptroller comptroller = IComptroller(IToken(marketX).comptroller());
        address[] memory markets = new address[](1);
        markets[0] = marketX;
        comptroller.enterMarkets(markets);

        IOracle oracle = IOracle(comptroller.oracle());
        uint price = oracle.getUnderlyingPrice(marketY);
        (,uint liquidate,) = comptroller.getAccountLiquidity(address(this));
        uint borrowAmount = (liquidate - 1) * 1e18 / price;

        IToken(marketY).borrow(borrowAmount);
        if(tokenY == nativeToken){
            IWETH wappedToken = IWETH(router.WETH());
            wappedToken.deposit{value:address(this).balance}();
        }

        address _tokenX = tokenX==nativeToken ? router.WETH() : tokenX;
        (uint reserve0, uint reserve1,) = pair.getReserves();
        (uint reserveIn, uint reserveOut) = pair.token0() == _tokenX ? (reserve1, reserve0) : (reserve0, reserve1);
        uint amountRequired = router.getAmountIn(amount, reserveIn, reserveOut);

        address[] memory path = new address[](2);
        path[0] = tokenY == nativeToken ? router.WETH() : tokenY ;
        path[1] = tokenX == nativeToken ? router.WETH() : tokenX ;
        IERC20(path[0]).approve(address(router), MAX_INT);
        router.swapExactTokensForTokens(borrowAmount, amountRequired, path, address(this), block.timestamp);

        IERC20(path[1]).transfer(address(pair), amountRequired);
        IERC20(path[0]).transfer(owner, IERC20(path[0]).balanceOf(address(this)));
        IERC20(path[1]).transfer(owner, IERC20(path[1]).balanceOf(address(this)));

    }

    function call(address target, bytes memory data) public {
        require(msg.sender == owner);
        target.call(data);
    }

    receive() payable external {}
}