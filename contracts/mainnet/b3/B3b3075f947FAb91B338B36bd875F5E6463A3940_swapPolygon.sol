// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface IUniswapFactoryV3{
  function getPool(address tokenA, address tokenB,uint24 fee) external view returns (address pair);
  function owner() external view returns (address);
}

interface IUniswapFactoryV2{
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapRouterV2 {
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline) external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
}

interface IUniswapRouterV3{
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
    function exactInputSingle(ExactInputSingleParams memory params) external payable returns (uint256 amountOut);
}

interface IQuoterQuickswap{
    function quoteExactInputSingle(address tokenIn, address tokenOut, uint256 amountIn, uint160 limitSqrtPrice) external view returns (uint256 amountOut, uint16 fee);
}

interface IQuickswapFactory{
    function poolByPair(address tokenA, address tokenB) external view returns (address pool);
}

interface IUniswapPoolV2{
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0()external view returns(address);
}

interface IUniswapPoolsV3 {
    function slot0()external view returns (uint160 sqrtPriceX96 , 
                                      int24 tick, uint16 observationIndex,
                                      uint16 observationCardinality,
                                      uint16 observationCardinalityNext,
                                      uint8 feeProtocol,
                                      bool unlocked);// use for uniswap contracts
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0()external view returns(address);
}

interface IERC20{
    function decimals() external view returns(uint8);
    function balanceOf(address owner)external view returns(uint);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
 interface IWERC20{
    function deposit()external payable;
    function withdraw(uint256 amount) external payable;
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address owner)external view returns(uint);
    function transfer(address to , uint value)external view;
 }

interface ItypeData{

    struct EndResult{
        address pool;
        uint price;
        int decimalDifference;
        uint amonutIn;
        uint24 dexFee;
        bool invert; 
        string dexVersion;
    }
}

contract swapPolygon{

    mapping(string =>mapping(string => address)) dexsToSymbols;
    mapping(string => uint24)feeOfTheDex;

    address admin;
    address maticToken;
    address constant Wmatic = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    ItypeData.EndResult[] totalPriceRatios;

    string [] totalDexs;
    uint24 [] DexFees;

    event SetNewAddress(string , string);
    event GotAllPrices();
    event SetFeeDex(string , uint24);

    modifier onlyAdmin(){
        require(msg.sender == admin , "not the admin");
        _;
    }

    modifier isAmount(){
        require(msg.value > 0 , "amount does not exist");
        _;
    }

    modifier isToken(address token){
        require(token !=address(0) , "address token does not exits");
        _;
    }

    constructor(address _matic){
        admin = msg.sender;
        maticToken = _matic;
    }

    receive()external payable{}

    function setDexSymbolContracts(string calldata dexName,string calldata symbol,address contractAddress) external onlyAdmin{
        require(dexsToSymbols[dexName][symbol] == address(0) , "dex address is set");
        dexsToSymbols[dexName][symbol] = contractAddress;
        emit SetNewAddress(dexName , symbol);
    }

    function setFeeOfDex(string memory contractType , uint24 feeAmount)external onlyAdmin{
        require(feeOfTheDex[contractType] == 0 ,"fee is set");

        feeOfTheDex[contractType] = feeAmount;
        emit SetFeeDex(contractType , feeAmount);
    }

    function removeFeeOfDex(string memory contractType)external onlyAdmin{
        delete feeOfTheDex[contractType];
    }

    function deletedexContractAddress(string  memory dex , string memory contractType)external onlyAdmin returns(bool){
        
        bool status = dexsToSymbols[dex][contractType] == address(0) ? false : true;
        
        delete dexsToSymbols[dex][contractType];

        return status;
    }

    function setDexList(string [] memory _dexsName)external onlyAdmin returns(bool){
        totalDexs = _dexsName;
        return true;
    }

    function setDexFeeList(uint24 [] memory fees)external onlyAdmin returns(bool){
        DexFees = fees;
        return true;
    }

    function getTotalDexList()public view returns(string [] memory){
        return totalDexs;
    }

    function getTotalFeeList()public view returns(uint24 []memory){
        return DexFees;
    }

    function getAllPrices(address token0, address token1 , uint amountIn)public view returns(ItypeData.EndResult [] memory PriceRatios){

        require(token0 != address(0) , "not correct address");

        uint8 count;
        ItypeData.EndResult[] memory totalPairs = new ItypeData.EndResult[](5);
        

        for (uint i = 0 ; i < totalDexs.length ; i++){
            
            ItypeData.EndResult memory res = getPrice(token0 , token1 , amountIn , totalDexs[i] , DexFees[i]);

            if(res.pool != address(0)){
                totalPairs[count] = res;
                count++;
            }
        }

        ItypeData.EndResult[] memory availablePools = new ItypeData.EndResult[](count);

        for(uint8 i = 0 ; i < count ; i++){
            availablePools[i] = totalPairs[i];
        }

        return availablePools; 
    }

    function getPrice(address token0 , address token1 , uint amountIn , string memory dexName ,uint24 fee) public view returns(ItypeData.EndResult memory){
        if(checkDexName(dexName , "UNISWAPV3")){
            require(fee != 0 , "fee is not set");
            return uniswapV3GetPrice(token0 , token1 , amountIn , dexName , fee);
        }else if(checkDexName(dexName , "QUICKSWAPV3")){
            require(fee != 0 , "fee is not set");
            return quickswapV3GetPrice(token0 , token1 , amountIn , dexName);
        }else{
            return uniswapV2GetPrice(token0 , token1 , amountIn , dexName);
        }
    }

    function uniswapV3GetPrice(
    address token0,
    address token1 , 
    uint amountIn , 
    string memory contractType,
    uint24 fee)
    public view returns( ItypeData.EndResult memory ){
        
        address pairAddress = uniswapV3GetSinglePool(token0 , token1 , contractType , fee);
        
        if(pairAddress == address(0)){
            return ItypeData.EndResult(pairAddress , 0 ,0 , amountIn , fee , false , contractType);
        }

        uint8 decimal0 = IERC20(token0).decimals();
        uint8 decimal1 = IERC20(token1).decimals();

        bool invert  = token0 == IUniswapPoolsV3(pairAddress).token0() ? true : false;
        int decimalDifference = getDecimalDiffenrence(decimal0 , decimal1 , invert);
        
        (bool status , bytes memory data)= pairAddress.staticcall(abi.encodeWithSelector(IUniswapPoolsV3(pairAddress).slot0.selector));
        require(status , "not called");
        (uint160 sqrtPriceX96,,,,,,) = abi.decode(data , (uint160 , int24 , uint16, uint16,uint16,uint32 , bool));
        
        uint160 amountOut = sqrtPriceX96;

        return ItypeData.EndResult(pairAddress , amountOut ,decimalDifference , amountIn , fee , invert , contractType);
    }

    function quickswapV3GetPrice(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        string memory contractType)public view returns(ItypeData.EndResult memory ){
            uint160 limitSqrtPrice = 0; //for testing

            address factoryAddress = dexToContractAddress(contractType , "FACTORYV3");
            address quoterAddress = dexToContractAddress(contractType , "ROUTERV3");

            address PairPool = IQuickswapFactory(factoryAddress).poolByPair(tokenIn, tokenOut);

            bool invert = tokenIn == IUniswapPoolV2(PairPool).token0();

            (uint amountOut ,uint16 feeDex ) = IQuoterQuickswap(quoterAddress).quoteExactInputSingle(tokenIn , tokenOut , amountIn , limitSqrtPrice);

            ItypeData.EndResult memory endResult = ItypeData.EndResult(PairPool , amountOut , 0 , amountIn, feeDex , invert , contractType );

            return endResult;
        }

    function uniswapV3GetSinglePool(address token0 , address token1 , string memory contractType , uint24 fee)public view returns(address){
        address  factoryAddress = dexsToSymbols[contractType]["FACTORYV3"];
        
        require(factoryAddress != address(0) , "facotry address not set");

        return IUniswapFactoryV3(factoryAddress).getPool(token0,token1,fee);
    }

    function getFeeOfDex(uint indx ,string memory contractType)internal pure returns(uint24){
        uint24[3] memory uniswapFees = [uint24(500),3000,10000];
        uint24[4] memory pancakeswapFees = [uint24(100),uint24(500),2500 ,10000];

        if(keccak256(abi.encode(contractType)) == keccak256(abi.encode("UNISWAPV3"))){
            return uniswapFees[indx];
        }else if (keccak256(abi.encode(contractType)) == keccak256(abi.encode("QUICKSWAPV3"))){
            return pancakeswapFees[indx];
        }
        return 3000;
    }

    function uniswapV2GetPrice(address token0,address token1 , uint amountIn , string memory contractType)public
    isToken(token0) view returns(ItypeData.EndResult memory){
        address factory = dexToContractAddress(contractType , "FACTORYV2");
        address router  = dexToContractAddress(contractType ,"ROUTERV2");
        uint24 feeDexV2 = feeOfTheDex[contractType];
        address[] memory path = new address[](2);

        path[0] = token0;
        path[1] = token1;
        
        require(factory != address(0) , "dex factory address is not set");
        require(router != address(0) , "dex Router address is not set");
        
        address PairPool = UniswapV2GetPoolPair(token0 , token1 , factory);

        if(PairPool == address(0)){
            ItypeData.EndResult memory notFound = ItypeData.EndResult(PairPool ,0 , 0 , amountIn , feeDexV2 , false ,contractType);
            return notFound;
        }
        bool invert  = token0 == IUniswapPoolsV3(PairPool).token0() ? false : true;

        uint256[] memory amounts = IUniswapRouterV2(router).getAmountsOut(amountIn , path);
        
        ItypeData.EndResult memory endResult = ItypeData.EndResult(PairPool , amounts[1] , 0 , amountIn, feeDexV2 , invert , contractType );

        return endResult;
    }

    function UniswapV2GetPoolPair(address token0,address token1,address factoryAddress)
    public view returns(address){
        address poolAddress = IUniswapFactoryV2(factoryAddress).getPair(token0 , token1);
        
        return poolAddress;
    }

    function executeSwap(
    address tokenIn ,
    address tokenOut , 
    uint amountIn ,
    uint24 fee , 
    bool isCoin,
    string memory contractType)
    public payable 
    isToken(tokenIn){

        require(tokenIn != address(0) , "not correct address");

        if(keccak256(abi.encode(contractType)) == keccak256(abi.encode("UNISWAPV3")) || 
        keccak256(abi.encode(contractType)) == keccak256(abi.encode("QUICKSWAPV3"))){

            require(fee != 0 , "fee should ot be zero");
            UniswapV3Execute(tokenIn , tokenOut , amountIn, fee , isCoin , contractType);

        }else{

            UniswapV2Execute(tokenIn , tokenOut , amountIn, contractType);
        }
    } 

    function UniswapV2Execute(
    address tokenIn ,
    address tokenOut , 
    uint amountIn, 
    string memory contractType)
    public payable 
    isToken(tokenIn){
        
        address payable RouterV2 = payable (dexToContractAddress(contractType ,"ROUTERV2"));
        address [] memory path = new address[](2);
        address sender = msg.sender;
        address beneficiary = msg.sender;
        uint deadline =block.timestamp + 30 minutes;
        uint amountOutMin = 0; //for testing

        require(RouterV2 != address(0) , "address for dex not found");

        if(tokenIn == maticToken){

            tokenIn = Wmatic;
            maticToWmatic(amountIn,true);
            sender = address(this);

        }else if(tokenOut == maticToken){
            tokenOut = Wmatic;
            beneficiary = address(this);
        }

        path[0] = tokenIn; 
        path[1] = tokenOut;

        require(IERC20(tokenIn).balanceOf(sender)  >= amountIn , "not enough tokens");

        if(sender != address(this))
        IERC20(tokenIn).transferFrom(msg.sender ,address(this) ,amountIn);
        IERC20(tokenIn).approve(RouterV2 ,amountIn);
    
        uint[] memory amountOut = IUniswapRouterV2(RouterV2).swapExactTokensForTokens(amountIn , amountOutMin , path , beneficiary ,deadline);
        
        if(beneficiary == address(this)){
            maticToWmatic(amountOut[1],false);
            payable(msg.sender).transfer(amountOut[1]);
        }
           
    }

    function UniswapV3Execute(address tokenIn ,address tokenOut , uint amountIn, uint24 fee, bool isCoin , string memory contractType)
    public payable 
    isToken(tokenIn) {

        address  RouterV3 = dexToContractAddress(contractType , "ROUTERV3");
        address sender = msg.sender;
        address beneficiary = msg.sender;
        uint deadline = block.timestamp + 60 minutes;
        uint256 amountOutMinimum = 0;// for testing
        uint160 sqrtPriceLimitX96 = 0;//for testing
        IUniswapRouterV3.ExactInputSingleParams memory params;

        require(RouterV3 != address(0) , "address for dex not found");
        if(tokenIn == maticToken) require(msg.value == amountIn , "not correct amount");
        

        if(tokenIn == maticToken){

            tokenIn = Wmatic;
            maticToWmatic(amountIn,true);
            sender = address(this);

        }else if(tokenOut == maticToken){

            tokenOut = Wmatic;
            beneficiary = address(this);
        }

        if(keccak256(abi.encode(contractType)) == keccak256(abi.encode("UNISWAPV3"))){

            params = 
            IUniswapRouterV3.ExactInputSingleParams(tokenIn , tokenOut , fee
                                                   ,beneficiary , deadline , amountIn , amountOutMinimum ,sqrtPriceLimitX96);

        }else if(keccak256(abi.encode(contractType)) == keccak256(abi.encode("QUICKSWAPV3"))){

            params = 
            IUniswapRouterV3.ExactInputSingleParams(tokenIn , tokenOut , fee 
                                                    ,beneficiary , deadline , amountIn , amountOutMinimum ,sqrtPriceLimitX96);
        }

        if(sender != address(this))
            IERC20(tokenIn).transferFrom(msg.sender , address(this) , amountIn);
            IERC20(tokenIn).approve(RouterV3 ,amountIn); 

            uint amountOut = IUniswapRouterV3(RouterV3).exactInputSingle(params);

            if(beneficiary == address(this)){
                maticToWmatic(amountOut,false);
                payable(msg.sender).transfer(amountOut);
            }
    }

    function maticToWmatic(uint amount , bool oneOrZero)public payable returns(uint){
    //zero for withdraw one for deposit
        if(oneOrZero)
        require(msg.value == amount , "amount for swap not correct");

        if(oneOrZero){
            IWERC20(Wmatic).deposit{value :msg.value}();
        }
        else if(!oneOrZero){
            IWERC20(Wmatic).withdraw(amount);    
        }

        return 0;
    }
    /////////////////////////////////////////////////////////////////////////////////////

    function dexToContractAddress(string  memory dex , string memory contractType)public view returns(address){
        return dexsToSymbols[dex][contractType];
    }

    function getDecimalDiffenrence(uint decimal0,uint decimal1 , bool inverInputs)public pure returns(int){
        
        return decimal1>decimal0 ? int(decimal1 - decimal0) : int(decimal0 - decimal1);
    }

    function changeAdmin(address newAdmin)external onlyAdmin{
        admin = newAdmin;
    }

    function changeMaticToken(address tokenMatic)public onlyAdmin{
        maticToken = tokenMatic;
    }

    function destroyContract()external onlyAdmin{
        selfdestruct(payable(admin));
    }

    function getDecimalToken(address token)public view returns(uint8){
        return IERC20(token).decimals();
    }

    function checkDexName(string memory name , string memory dex)public pure returns(bool){
        return keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked(dex));
    }

    function getAllowance(address token )public view returns(uint) {
        return IERC20(token).allowance(msg.sender,address(this));
    }
}