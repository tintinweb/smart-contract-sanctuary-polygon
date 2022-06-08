/**
 *Submitted for verification at polygonscan.com on 2022-06-08
*/

// File: contracts/Token/Swaper.sol


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
contract SwapperV7 {
    struct dex_router {
        string nombre;
        address router;
        uint version;
    }
    struct Swap_router {
        dex_router dex;
        address tokenA;
        address tokenB;
    }
    dex_router[] private _routers_DEX;
    address[] private _midPairs;
    mapping (address => bool) public permitedAddress;
    ILiquidity public liquidity;
    address private _feeToken;
    address private _pairFeeToken;
    address public wmatic=0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public matic=0x0000000000000000000000000000000000001010;
    bool public promo=false;
    constructor(){
        permitedAddress[msg.sender]=true;
        _midPairs=[
            0x1b69D5b431825cd1fC68B8F883104835F3C72C80,//HBLOCK
            0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270,//WMATIC
            0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174,//USDC
            0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619,//ETH
            0xc2132D05D31c914a87C6611C10748AEb04B58e8F,//USDT
            0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,//DAI
            0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6,//BTC
            0xa3Fa99A148fA48D14Ed51d610c367C61876997F1,//miMATIC
            0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39,//LINK
            0x385Eeac5cB85A38A9a07A70c73e0a3271CfB54A7,//Aavegotchi
            0xD6DF932A45C0f255f85145f286eA0b292B21C90B,//Aave
            0xb33EaAd8d922B1083446DC23f610c2567fB5180f,//UNISWAP
            0xf28164A485B0B2C90639E47b0f377b4a438a16B1,//QUICKSWAP
            0xdF7837DE1F2Fa4631D716CF2502f8b230F1dcc32//TELCOIN
        ];
    }
    modifier whenPermited() {
        require(permitedAddress[msg.sender],"Not permited");
        _;
    }
    function setPermitedAddress(address ad, bool permited) public whenPermited {
        permitedAddress[ad]=permited;
    }
    function setPromo(bool enabled) public whenPermited {
        promo=enabled;
    }
    function setLiquidityAddress(address ad) public whenPermited {
        liquidity=ILiquidity(ad);
        _feeToken=liquidity.getToken0();
        _pairFeeToken=liquidity.getToken1();
    }
    function addRouterDEX(string memory nombre,address router_dex,uint version) public whenPermited {
        bool exist=false;
        for(uint i=0;i<_routers_DEX.length;i++){
            if(_routers_DEX[i].router==router_dex){
                exist=true;
                break;
            }
        }
        if(!exist){_routers_DEX.push(dex_router(nombre,router_dex,version));}
    }
    function deleteRouterDEX(uint pos) public whenPermited {
        require(pos>=0 && pos<_routers_DEX.length,"Index ERROR");
        _routers_DEX[pos]=_routers_DEX[_routers_DEX.length-1];
        _routers_DEX.pop();
    }
    function getRoutersDEX() public view returns(dex_router[] memory){
        return _routers_DEX;
    }
    function allMidPairs() public view returns(address[] memory){
        return _midPairs;
    }
    function addMidPair(address[] memory tokens) public whenPermited {
        for(uint i=0;i<tokens.length;i++){
            _midPairs.push(tokens[i]);
        }
    }
    function deleteMidPair(uint pos) public whenPermited {
        require(pos>=0 && pos<_midPairs.length,"Index ERROR");
        _midPairs[pos]=_midPairs[_midPairs.length-1];
        _midPairs.pop();
    }
    function getPairV2ByTokens(address router,address tokenA, address tokenB) public view returns (address) {
        return IDEXFactory(IDEXRouter(router).factory()).getPair(tokenA, tokenB);
    }
    function getPairV3ByTokens(address router,address tokenA, address tokenB,uint24 fee) public view returns (address) {
        return IDEXFactory(IDEXRouter(router).factory()).getPool(tokenA,tokenB,fee);
    }
    function getAllV2PairsLength(address router) public view returns (uint) {
        return IDEXFactory(IDEXRouter(router).factory()).allPairsLength();
    }
    function getPairV2ByID(address router,uint i) public view returns (address) {
        return IDEXFactory(IDEXRouter(router).factory()).allPairs(i);
    }
    function getPairsV2ByTokens(address tokenA, address tokenB) public view returns (address[] memory pairs) {
        uint count = 0;
        address[] memory result = new address[](_routers_DEX.length);
        for(uint i=0;i<_routers_DEX.length;i++){
            address pair=getPairV2ByTokens(_routers_DEX[i].router,tokenA, tokenB);
            if(pair!=address(0)){
                result[count]=pair;
                count++;
            }
        }
        address[] memory trimmedResult = new address[](count);
        for (uint i = 0; i < count; i++) {
            trimmedResult[i] = result[i];
        }
        return trimmedResult;
    }
    function getBestSwapsByTokens(address tokenA, address tokenB,uint amountA) public view returns (uint price,Swap_router[] memory bestSwap) {
        require(tokenA!=tokenB,"Same tokens");
        require(tokenA!=address(0),"ZERO address");
        require(tokenB!=address(0),"ZERO address");
        if((wmatic==tokenA && matic==tokenB) || (matic==tokenA && wmatic==tokenB)){
            price=amountA;
            bestSwap = new Swap_router[](1);
            bestSwap[0]=Swap_router(dex_router("SC",wmatic,1),tokenA,tokenB);
        }else{
            if(matic==tokenA){tokenA=wmatic;}
            if(matic==tokenB){tokenB=wmatic;}
            (price,bestSwap) = getBestPriceByTokens(tokenA,tokenB,amountA);
            if(price==0){
                (price,bestSwap) = getBestMidSwapByTokens(tokenA,tokenB,amountA);
                if(price==0){
                    (price,bestSwap) = getBestMultiSwapByTokens(tokenA,tokenB,amountA);
                }
            }
        }
    }
    function getBestMultiSwapByTokens(address tokenA, address tokenB,uint amountA) public view returns (uint bestPrice,Swap_router[] memory bestSwaps) {
        address[] memory path=new address[](4);
        path[0]=tokenA;path[3]=tokenB;
        uint size=_midPairs.length;
        for(uint i=0;i<size;i++){
            path[1]=_midPairs[i];
            for(uint j=0;j<size;j++){
                path[2]=_midPairs[j];
                (bestPrice,bestSwaps)=checkSwaps(path,amountA,bestPrice,bestSwaps);
            }
        }
    }
    function getSwapsByMidToken(address[] memory path,uint amountA) public view returns (uint price,Swap_router[] memory bestSwaps) {
        bestSwaps = new Swap_router[](path.length-1);
        Swap_router[] memory swap;
        price=amountA;
        for(uint i=0;i<path.length-1;i++){
            (price,swap) = getBestPriceByTokens(path[i],path[i+1],price);
            bestSwaps[i]=swap[0];
        }
    }
    function checkSwaps(address[] memory path,uint amountA, uint _price,Swap_router[] memory _swap) public view returns (uint bestPrice,Swap_router[] memory bestSwaps) {
        bestPrice=_price;
        bestSwaps=_swap;
        if(!duplicate(path)){
            (uint price,Swap_router[] memory swap) = getSwapsByMidToken(path,amountA);
            if(price>bestPrice){
                bestPrice=price;
                bestSwaps=swap;
            }
        }
    }
    function getBestMidSwapByTokens(address tokenA, address tokenB,uint amountA) public view returns (uint bestPrice,Swap_router[] memory bestSwaps) {
        address[] memory path=new address[](3);
        path[0]=tokenA;path[2]=tokenB;
        for(uint i=0;i<_midPairs.length;i++){
            path[1]=_midPairs[i];
            (bestPrice,bestSwaps)=checkSwaps(path,amountA,bestPrice,bestSwaps);
        }
    }
    function duplicate(address[] memory path) public pure returns (bool){
        for(uint i=0;i<path.length-1;i++){
            for(uint j=i+1;j<path.length;j++){
                if(path[i]==path[j]){
                    return true;
                }
            }
        }
        return false;
    }
    function getBestPriceByTokens(address tokenA, address tokenB,uint amountA) public view returns (uint bestPrice,Swap_router[] memory bestSwaps) {
        bestSwaps = new Swap_router[](1);
        for(uint i=0;i<_routers_DEX.length;i++){
            uint price=getTokenAPrice(_routers_DEX[i],tokenA,tokenB,amountA);
            if(price>bestPrice){
                bestPrice = price;
                bestSwaps[0]=Swap_router(_routers_DEX[i],tokenA,tokenB);
            }
        }
    }
    function getTokenAPrice(dex_router memory dex,address tokenA,address tokenB,uint amountA) public view returns(uint){
        if(dex.version==2){
            return getTokenAPriceV2(dex.router,tokenA,tokenB,amountA);
        }
        if(dex.version==3){
            return getTokenAPriceV3(dex.router,tokenA,tokenB,amountA);
        }
        return 0;
    }
    function getLiquidity(address ad) public view returns(uint){
       return (ad==address(0))?0:IDEXPair(ad).liquidity();
    }
    function getBestLiquidity(address router,address tokenA,address tokenB) public view returns(uint,uint24){
        uint liq500=getLiquidity(getPairV3ByTokens(router,tokenA,tokenB,500));
        uint liq3000=getLiquidity(getPairV3ByTokens(router,tokenA,tokenB,3000));
        uint liq10000=getLiquidity(getPairV3ByTokens(router,tokenA,tokenB,10000));
        return (liq500>liq3000)?((liq500>liq10000)?(liq500,500):(liq10000,10000)):((liq3000>liq10000)?(liq3000,3000):(liq10000,10000));
    }
    function getTokenAPriceV3(address router,address tokenA,address tokenB,uint amountA) public view returns(uint){
        (uint liquid,uint24 fee)=getBestLiquidity(router,tokenA,tokenB);
        if(liquid==0){return 0;}
        address ad=getPairV3ByTokens(router,tokenA,tokenB,fee);
        if(ad==address(0)){return 0;}
        try IDEXPair(ad).slot0() returns (uint160 sqrtPriceX96,int24 tick,uint16 observationIndex,uint16 observationCardinality,uint16 observationCardinalityNext,uint8 feeProtocol,bool unlocked){
            uint sqrtPriceX48=sqrtPriceX96/(2**48);
            return tokenA < tokenB ? amountA*(sqrtPriceX48**2)/(2**96) : amountA*(2**96)/(sqrtPriceX48**2);
        } catch (bytes memory) {}
        return 0;
    }
    function getTokenAPriceV2(address router,address tokenA,address tokenB,uint amountA) public view returns(uint){
        if(tokenB==tokenA || tokenA==address(0) || tokenB==address(0)){return 0;}
        address pair=getPairV2ByTokens(router,tokenA,tokenB);
        if(pair==address(0) || amountA==0){return 0;}
        (uint r0,uint r1,)=IDEXPair(pair).getReserves();
        if(r0==0 || r1==0){return 0;}
        (address t0,) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        (uint rA, uint rB) = tokenA == t0 ? (r0, r1) : (r1, r0);
        return IDEXRouter(router).getAmountOut(amountA,rA,rB);
    }
    receive() external payable {}
    function promotion(uint fee) internal{
        uint feeTokenAmount=internalSwapTokensForTokens(_pairFeeToken,_feeToken,fee);
        require(IERC20(_feeToken).transfer(msg.sender,feeTokenAmount),"Error on transfer");
    }
    function autoLiquidityFee(uint fee) internal{
        uint minBalanceFeeToken=(fee*liquidity.getTokenPrice())/(10**IERC20(_pairFeeToken).decimals());
        if(IERC20(_feeToken).balanceOf(address(liquidity))>=minBalanceFeeToken){
            require(IERC20(_pairFeeToken).transfer(address(liquidity),fee),"Error on transfer");
            liquidity.addLiquidity(minBalanceFeeToken,fee);
        }else{
            uint feeTokenAmount=internalSwapTokensForTokens(_pairFeeToken,_feeToken,fee);
            require(IERC20(_feeToken).transfer(address(liquidity),feeTokenAmount),"Error on transfer");
            liquidity.swapAndLiquify(feeTokenAmount);
        }
    }
    function payfee(address token,uint amount) internal returns(uint fee){
        fee=amount*3/1000;
        uint feeOnTokenPair=fee;
        if(token!=_pairFeeToken){
            feeOnTokenPair=internalSwapTokensForTokens(token,_pairFeeToken,fee);
        }
        if(promo){
            uint amountPromo=feeOnTokenPair/3;
            promotion(amountPromo);
            feeOnTokenPair-=amountPromo;
        }
        autoLiquidityFee(feeOnTokenPair);
    }
    function internalSwapTokensForTokens(address tokenA,address tokenB,uint amountA) internal returns(uint amountTokenB) {
        (uint price,Swap_router[] memory bestSwap) = getBestSwapsByTokens(tokenA,tokenB,amountA);
        require(price>0,"No route for swap");
        uint init = IERC20(tokenB).balanceOf(address(this));
        uint amount=amountA;
        for(uint i=0;i<bestSwap.length;i++){
            uint tokenB_balance=IERC20(bestSwap[i].tokenB).balanceOf(address(this));
            swapTokensForTokens(bestSwap[i].dex,bestSwap[i].tokenA,bestSwap[i].tokenB,amount);
            amount=IERC20(bestSwap[i].tokenB).balanceOf(address(this))-tokenB_balance;
        }
        amountTokenB = IERC20(tokenB).balanceOf(address(this))-init;
    }
    function bestPathSwapTokensForTokens(address tokenA,address tokenB,uint amountA,uint slippage) public payable {
        require(tokenA!=tokenB,"Same tokens");
        require(tokenA!=address(0),"ZERO address");
        require(tokenB!=address(0),"ZERO address");
        if(matic==tokenA){
            require(msg.value>0,"Invalid params");
            amountA=msg.value;
            IERC20(wmatic).deposit{value:amountA}();
            tokenA=wmatic;
            if(tokenB==wmatic){
                require(IERC20(wmatic).transfer(msg.sender,amountA),"Error on transfer");
                return;
            }
        }else{
            require(IERC20(tokenA).transferFrom(msg.sender,address(this),amountA),"Need approval");
        }
        if(wmatic==tokenA && matic==tokenB){
            IERC20(wmatic).withdraw(amountA);
            payable(msg.sender).transfer(amountA);
            return;
        }
        if(matic==tokenB){
            tokenB=wmatic;
        }
        (uint price,Swap_router[] memory bestSwap) = getBestSwapsByTokens(tokenA,tokenB,amountA);
        require(price>0,"No route for swap");
        uint init = IERC20(tokenB).balanceOf(address(this));
        uint amount=amountA-payfee(tokenA,amountA);
        for(uint i=0;i<bestSwap.length;i++){
            uint tokenB_balance=IERC20(bestSwap[i].tokenB).balanceOf(address(this));
            swapTokensForTokens(bestSwap[i].dex,bestSwap[i].tokenA,bestSwap[i].tokenB,amount);
            amount=IERC20(bestSwap[i].tokenB).balanceOf(address(this))-tokenB_balance;
        }
        uint amountTokenB = IERC20(tokenB).balanceOf(address(this))-init;
        require(amountTokenB*10000>=(price*(10000-slippage)),"Bad swaps");
        if(wmatic==tokenB){
            IERC20(wmatic).withdraw(amountTokenB);
            payable(msg.sender).transfer(amountTokenB);
        }else{
            require(IERC20(tokenB).transfer(msg.sender,amountTokenB),"Error on transfer");
        }
    }
    function swapTokensForTokens(dex_router memory dex,address tokenA,address tokenB,uint amountA) public {
        if(dex.version==2){
            swapTokensForTokensV2(dex,tokenA,tokenB,amountA);
        }
        if(dex.version==3){
            swapTokensForTokensV3(dex,tokenA,tokenB,amountA);
        }
    }
    function swapTokensForTokensV3(dex_router memory dex,address tokenA,address tokenB,uint amountA) internal {
        (uint liquid,uint24 fee)=getBestLiquidity(dex.router,tokenA,tokenB);
        require(liquid>0,"Bad Swap");
        IERC20(tokenA).approve(dex.router,amountA);
        IDEXRouter(dex.router).exactInputSingle(IDEXRouter.ExactInputSingleParams(tokenA,tokenB,fee,address(this),amountA,0,0));
    }
    function swapTokensForTokensV2(dex_router memory dex,address tokenA,address tokenB,uint amountA) internal {
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
        IERC20(tokenA).approve(dex.router,amountA);
        IDEXRouter(dex.router).swapExactTokensForTokensSupportingFeeOnTransferTokens(amountA,0,path,address(this),block.timestamp);
    }
}