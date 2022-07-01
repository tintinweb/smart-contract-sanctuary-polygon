/**
 *Submitted for verification at polygonscan.com on 2022-06-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
interface IDEXFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    //V3
    function getPool(address tokenA,address tokenB,uint24 fee) external view returns (address pool);
}
interface IDEXPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(address indexed sender,uint amount0In,uint amount1In,uint amount0Out,uint amount1Out,address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
    //v3
    function liquidity() external view returns (uint128);
    function observe(uint32[] calldata secondsAgos) external view returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);
    function slot0() external view returns (uint160 sqrtPriceX96,int24 tick,uint16 observationIndex,uint16 observationCardinality,uint16 observationCardinalityNext,uint8 feeProtocol,bool unlocked);
}
interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(address tokenA,address tokenB,uint amountADesired,uint amountBDesired,uint amountAMin,uint amountBMin,address to,uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(address token,uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,address to,uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(address tokenA,address tokenB,uint liquidity,uint amountAMin,uint amountBMin,address to,uint deadline) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(address token,uint liquidity,uint amountTokenMin,uint amountETHMin,address to,uint deadline) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(address tokenA,address tokenB,uint liquidity,uint amountAMin,uint amountBMin,address to,uint deadline,bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(address token,uint liquidity,uint amountTokenMin,uint amountETHMin,address to,uint deadline,bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(uint amountOut,uint amountInMax,address[] calldata path,address to,uint deadline) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function removeLiquidityETHSupportingFeeOnTransferTokens(address token,uint liquidity,uint amountTokenMin,uint amountETHMin,address to,uint deadline) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address token,uint liquidity,uint amountTokenMin,uint amountETHMin,address to,uint deadline,bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin,address[] calldata path,address to,uint deadline) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external;
    //V3
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}
interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function decimals() external pure returns (uint8);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    //extra
    function withdraw(uint wad) external;
    function deposit() external payable;
}
interface ILiquidity {
    function swapAndLiquify(uint256 amount) external;
    function addLiquidity(uint256 tokenAmount, uint256 otherTokenAmount) external;
    function getToken0() external view returns(address);
    function getToken1() external view returns(address);
    function getTokenPrice() external view returns(uint);
}
interface IRouter {
    struct DexRouter {
        string nombre;
        address router;
        uint32 version;
    }
    struct Swap_router {
        DexRouter dex;
        address tokenA;
        address tokenB;
    }
    function getBestSwapsByTokens(address tokenA, address tokenB,uint amountA) external view returns (uint price,Swap_router[] memory bestSwap);
    function getGasEfficientSwapsByTokens(address tokenA, address tokenB,uint amountA) external view returns (uint price,Swap_router[] memory bestSwap);
    function getBestLiquidity(address router,address tokenA,address tokenB) external view returns(uint,uint24);
}
contract OnlySwapV6 {
    ILiquidity public liquidity;
    IRouter public route;
    bool public promo=true;
    address private _feeToken;
    address private _pairFeeToken;
    mapping (address => bool) public permitedAddress;
    
    constructor(){
        permitedAddress[msg.sender]=true;
        liquidity=ILiquidity(0xA967d9e99b94704369e099CAb4c2235Cd417E6b6);
        _feeToken=liquidity.getToken0();
        _pairFeeToken=liquidity.getToken1();
    }
    modifier whenPermited() {
        require(permitedAddress[msg.sender],"Not permited");
        _;
    }
    function setPermitedAddress(address ad, bool permited) external whenPermited {
        permitedAddress[ad]=permited;
    }
    function setPromo(bool enabled) external whenPermited {
        promo=enabled;
    }
    function setLiquidityAddress(address ad) external whenPermited {
        liquidity=ILiquidity(ad);
        _feeToken=liquidity.getToken0();
        _pairFeeToken=liquidity.getToken1();
    }
    function setRouter(address ad) external whenPermited {
        route=IRouter(ad);
    }
    function unsafe32_inc(uint32 x) internal pure returns (uint32) {
        unchecked { return x + 1; }
    }
    receive() external payable {}
    function swapAndSendHBLOCK(address ad,uint amount) internal{
        address[] memory path = new address[](2);
        path[0] = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
        path[1] = 0x1b69D5b431825cd1fC68B8F883104835F3C72C80;
        IERC20(_pairFeeToken).approve(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff,amount);
        IDEXRouter(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff).swapExactTokensForTokensSupportingFeeOnTransferTokens(amount,0,path,ad,block.timestamp);
    }
    function autoLiquidityFee(uint fee) internal{
        uint minBalanceFeeToken=(fee*liquidity.getTokenPrice())/(10**IERC20(_pairFeeToken).decimals());
        if(IERC20(_feeToken).balanceOf(address(liquidity))>=minBalanceFeeToken){
            IERC20(_pairFeeToken).transfer(address(liquidity),fee);
            liquidity.addLiquidity(minBalanceFeeToken,fee);
        }else{
            swapAndSendHBLOCK(address(liquidity),fee);
            uint tAmount=IERC20(_feeToken).balanceOf(address(liquidity));
            if(tAmount>200*10**IERC20(_feeToken).decimals()){
                liquidity.swapAndLiquify(tAmount);
            }
        }
    }
    function payfee(address token) internal {
        uint feeOnTokenPair=IERC20(token).balanceOf(address(this));
        if(token!=_pairFeeToken){
            (uint price,IRouter.Swap_router[] memory path) = route.getGasEfficientSwapsByTokens(token,_pairFeeToken,feeOnTokenPair);
            if(price>0){
                for(uint32 i;i<path.length;i=unsafe32_inc(i)){
                    swapTokensForTokens(path[i].dex.router,path[i].tokenA,path[i].tokenB,path[i].dex.version);
                }
                feeOnTokenPair=IERC20(_pairFeeToken).balanceOf(address(this));
            }else{
                require(IERC20(token).transfer(msg.sender,feeOnTokenPair),"Error on transfer");
                return;
            }
        }
        if(promo){
            uint amountPromo=feeOnTokenPair/3;
            swapAndSendHBLOCK(msg.sender,amountPromo);
            feeOnTokenPair-=amountPromo;
        }
        autoLiquidityFee(feeOnTokenPair);
    }
    function getBestSwapsByTokens(address tokenA, address tokenB,uint amountA) external view returns (uint,IRouter.Swap_router[] memory){
        return route.getBestSwapsByTokens(tokenA,tokenB,amountA);
    }
    function bestSwapTokensForTokensByPath(IRouter.Swap_router[] calldata path,uint amountA,uint minAmountTokenB) external payable {
        require(path.length>0,"Bad tokens");
        address tokenA=path[0].tokenA;
        address tokenB=path[path.length-1].tokenB;
        bool hasTokenA=false;
        (hasTokenA,tokenB)=receiveTokenA(tokenA,tokenB,amountA);
        if(hasTokenA){
            for(uint32 i;i<path.length;i=unsafe32_inc(i)){
                swapTokensForTokens(path[i].dex.router,path[i].tokenA,path[i].tokenB,path[i].dex.version);
            }
            sendTokenB(tokenB,minAmountTokenB);
            payfee(tokenB);
        }
    }
    function bestPathSwapTokensForTokens(address tokenA,address tokenB,uint amountA,uint minAmountTokenB) external payable {
        require(tokenA!=tokenB && tokenA!=address(0) && tokenB!=address(0),"Bad tokens");
        (uint price,IRouter.Swap_router[] memory path) = route.getGasEfficientSwapsByTokens(tokenA,tokenB,amountA);
        require(price>0,"No route for swap");
        this.bestSwapTokensForTokensByPath(path,amountA,minAmountTokenB);
    }
    function receiveTokenA(address tokenA,address tokenB,uint amountA) internal returns(bool,address){
        address wmatic=0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
        address matic=0x0000000000000000000000000000000000001010;
        if(matic==tokenA && wmatic==tokenB){
            amountA=msg.value;
            IERC20(wmatic).deposit{value:amountA}();
            IERC20(wmatic).transfer(msg.sender,amountA);
            return (false,tokenB);
        }
        if((matic==tokenA || wmatic==tokenA) && msg.value>0){
            amountA=msg.value;
            IERC20(wmatic).deposit{value:amountA}();
        }else{
            IERC20(tokenA).transferFrom(msg.sender,address(this),amountA);
        }
        if(wmatic==tokenA && matic==tokenB){
            IERC20(wmatic).withdraw(amountA);
            payable(msg.sender).transfer(amountA);
            return (false,tokenB);
        }
        if(matic==tokenB){
            tokenB=wmatic;
        }
        return (true,tokenB);
    }
    function sendTokenB(address tokenB,uint minAmountTokenB) internal {
        address wmatic=0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
        uint amount=IERC20(tokenB).balanceOf(address(this))*997/1000;
        require(amount>0 && amount>=minAmountTokenB,"Bad swaps");
        if(wmatic==tokenB){
            IERC20(wmatic).withdraw(amount);
            payable(msg.sender).transfer(amount);
        }else{
            require(IERC20(tokenB).transfer(msg.sender,amount),"Error on transfer");
        }
        //refund matic send by error
        uint maticBalance=address(this).balance;
        if(maticBalance>0){
            payable(msg.sender).transfer(maticBalance);
        }
    }
    function swapTokensForTokens(address router,address tokenA,address tokenB,uint32 version) internal {
        uint amountA=IERC20(tokenA).balanceOf(address(this));
        require(amountA>0,"Insufficient funds.");
        IERC20(tokenA).approve(router,amountA);
        if(version==2){
            swapTokensForTokensV2(router,tokenA,tokenB,amountA);
        }else if(version==3){
            swapTokensForTokensV3(router,tokenA,tokenB,amountA);
        }
        //refund if swap fails
        amountA=IERC20(tokenA).balanceOf(address(this));
        if(amountA>0){
            require(IERC20(tokenA).transfer(msg.sender,amountA),"Error on transfer");  
        }
    }
    function swapTokensForTokensV3(address router,address tokenA,address tokenB,uint amountA) internal {
        (uint liquid,uint24 fee)=route.getBestLiquidity(router,tokenA,tokenB);
        require(liquid>0,"Bad Swap");
        IDEXRouter(router).exactInputSingle(IDEXRouter.ExactInputSingleParams(tokenA,tokenB,fee,address(this),amountA,0,0));
    }
    function swapTokensForTokensV2(address router,address tokenA,address tokenB,uint amountA) internal {
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
        IDEXRouter(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(amountA,0,path,address(this),block.timestamp);
    }
}