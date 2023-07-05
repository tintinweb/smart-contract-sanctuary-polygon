// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

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

interface IsingleSwap{

    struct SwapInputs{
    address tokenIn;
    address tokenOut;
    uint amountIn;
    uint24 fee;
    bool isCoin;
    uint deadline;
    uint amountOutMinimum;
    string contractType;
    }
}

contract swapPolygonV1{

    mapping(string =>mapping(string => address)) dexsToSymbols;
    mapping(string => uint24)feeOfTheDex;

    address admin;
    address maticToken;
    address constant Wmatic = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    ItypeData.EndResult[] totalPriceRatios;

    string [] totalDexs;
    uint24 [] DexFees;

    event SetNewAddress(string , string);
    event Swap(address indexed user,uint indexed amount, address indexed token);
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

    function executeSwap(IsingleSwap.SwapInputs memory swapInput)
    public payable 
    isToken(swapInput.tokenIn){

        // require(tokenIn != address(0) , "not correct address");

        if(keccak256(abi.encode(swapInput.contractType)) == keccak256(abi.encode("UNISWAPV3")) || 
        keccak256(abi.encode(swapInput.contractType)) == keccak256(abi.encode("QUICKSWAPV3"))){

            require(swapInput.fee != 0 , "fee should ot be zero");
            UniswapV3Execute(swapInput);

        }else{

            UniswapV2Execute(swapInput);
        }

        emit Swap(msg.sender , swapInput.amountIn, swapInput.tokenIn);
    } 

    function UniswapV2Execute(IsingleSwap.SwapInputs memory swapInput)
    public payable 
    isToken(swapInput.tokenIn){
        
        address payable RouterV2 = payable (dexToContractAddress(swapInput.contractType ,"ROUTERV2"));
        address [] memory path = new address[](2);
        address sender = msg.sender;
        address beneficiary = msg.sender;
        // uint deadline =block.timestamp + 30 minutes;
        // uint amountOutMin = 0; //for testing

        require(RouterV2 != address(0) , "address for dex not found");

        if(swapInput.tokenIn == maticToken){

            swapInput.tokenIn = Wmatic;
            maticToWmatic(swapInput.amountIn,true);
            sender = address(this);

        }else if(swapInput.tokenOut == maticToken){
            swapInput.tokenOut = Wmatic;
            beneficiary = address(this);
        }

        path[0] = swapInput.tokenIn; 
        path[1] = swapInput.tokenOut;

        require(IERC20(swapInput.tokenIn).balanceOf(sender)  >= swapInput.amountIn , "not enough tokens");

        if(sender != address(this))
        IERC20(swapInput.tokenIn).transferFrom(msg.sender ,address(this) ,swapInput.amountIn);
        IERC20(swapInput.tokenIn).approve(RouterV2 ,swapInput.amountIn);
    
        uint[] memory amountOut = IUniswapRouterV2(RouterV2).swapExactTokensForTokens(swapInput.amountIn , swapInput.amountOutMinimum , path , beneficiary ,swapInput.deadline);
        
        if(beneficiary == address(this)){
            maticToWmatic(amountOut[1],false);
            payable(msg.sender).transfer(amountOut[1]);
        }
           
    }

    function UniswapV3Execute(IsingleSwap.SwapInputs memory swapInput)
    public payable 
    isToken(swapInput.tokenIn) {

        address  RouterV3 = dexToContractAddress(swapInput.contractType , "ROUTERV3");
        address sender = msg.sender;
        address beneficiary = msg.sender;
        // uint deadline = block.timestamp + 60 minutes;
        // uint256 amountOutMinimum = 0;// for testing
        uint160 sqrtPriceLimitX96 = 0;//for testing
        IUniswapRouterV3.ExactInputSingleParams memory params;

        require(RouterV3 != address(0) , "address for dex not found");
        if(swapInput.tokenIn == maticToken) require(msg.value == swapInput.amountIn , "not correct amount");
        

        if(swapInput.tokenIn == maticToken){

            swapInput.tokenIn = Wmatic;
            maticToWmatic(swapInput.amountIn,true);
            sender = address(this);

        }else if(swapInput.tokenOut == maticToken){

            swapInput.tokenOut = Wmatic;
            beneficiary = address(this);
        }

        if(keccak256(abi.encode(swapInput.contractType)) == keccak256(abi.encode("UNISWAPV3"))){

            params = 
            IUniswapRouterV3.ExactInputSingleParams(swapInput.tokenIn , swapInput.tokenOut , swapInput.fee
                                                   ,beneficiary , swapInput.deadline , swapInput.amountIn , swapInput.amountOutMinimum ,sqrtPriceLimitX96);

        }else if(keccak256(abi.encode(swapInput.contractType)) == keccak256(abi.encode("QUICKSWAPV3"))){

            params = 
            IUniswapRouterV3.ExactInputSingleParams(swapInput.tokenIn , swapInput.tokenOut , swapInput.fee 
                                                    ,beneficiary , swapInput.deadline , swapInput.amountIn , swapInput.amountOutMinimum ,sqrtPriceLimitX96);
        }

        if(sender != address(this))
            IERC20(swapInput.tokenIn).transferFrom(msg.sender , address(this) , swapInput.amountIn);
            IERC20(swapInput.tokenIn).approve(RouterV3 ,swapInput.amountIn); 

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

    function changeAdmin(address newAdmin)external onlyAdmin{
        admin = newAdmin;
    }

    function changeMaticToken(address tokenMatic)public onlyAdmin{
        maticToken = tokenMatic;
    }

    function checkDexName(string memory name , string memory dex)public pure returns(bool){
        return keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked(dex));
    }
}