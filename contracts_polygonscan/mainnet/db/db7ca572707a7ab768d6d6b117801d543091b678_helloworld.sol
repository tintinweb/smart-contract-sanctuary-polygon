/**
 *Submitted for verification at polygonscan.com on 2021-12-16
*/

pragma solidity >=0.5.0;
// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
contract erc20Contract {
    using SafeMath for uint;
    mapping(address => uint) balances;
    event Transfer(address indexed from, address indexed to, uint tokens);
    
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
}
contract wethContract{
     function balanceOf(address account) external view returns (uint256);
}
contract usdcContract{
     function balanceOf(address account) external view returns (uint256);
     function approve(address spender, uint256 amount) external returns (bool);
}
contract quickSwapContract{
    using SafeMath for uint;
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)external payable returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)external returns (uint[] memory amounts);
}
contract sushiSwapContract{
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)external payable returns (uint[] memory amounts);
}
contract helloworld {
    using SafeMath for uint;
    address public owner;
    address public weth = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; 

    address weth_usdc_quickSwap = 0x6e7a5FAFcec6BB1e78bAE2A1F0B612012BF14827;
    address public quickSwap = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;

    address weth_usdc_sushi =  0xcd353F79d9FADe311fC3119B841e1f456b54e858; 
    address public sushiRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    wethContract wethcontract_ = wethContract(weth);
    usdcContract usdcContract_ = usdcContract(usdc);
    quickSwapContract quickSwapContract_ = quickSwapContract(quickSwap);
    sushiSwapContract sushiSwapContract_ = sushiSwapContract(sushiRouter);

    uint256 public ValueOut;
    uint256 public ValueIn;
    

    constructor() public {
        owner = msg.sender;
}
    // SWAP ETH->USDC->ETH PATH:Quick->Sushi
    function SwapEthToUsdcByQuick(uint amountOutMin) public payable {
        require(msg.sender == owner);
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = usdc;
         quickSwapContract_.swapExactETHForTokens.value(msg.value)(amountOutMin, path, address(this),3279146672);
    }
    function SwapUsdcToEthBySushi(uint amountIn, uint amountOutMin)public {
        require(msg.sender == owner);
        address[] memory path = new address[](2);
        path[0] = usdc;
        path[1] = weth;
        sushiSwapContract_.swapExactTokensForETH(amountIn , amountOutMin, path , msg.sender, 3279146672);
    }
    function EthQuickToSushi()public payable {
        require(msg.sender == owner);
        uint256 amountOut = EthToUsdcByQuick(msg.value);
        SwapEthToUsdcByQuick(amountOut.div(2));
        uint256 ETHamountOutMin = UsdcToEthBySushi(amountOut);
        SwapUsdcToEthBySushi(amountOut,ETHamountOutMin.div(2));

        ValueIn = msg.value;
        ValueOut = ETHamountOutMin;
        // require();
    }

    //SWAP ETH->USDC->ETH  PATH:Sushi->Quick
    function SwapEthToUsdcBySushi(uint amountOutMin) public payable {
        require(msg.sender == owner);
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = usdc;
        sushiSwapContract_.swapExactETHForTokens.value(msg.value)(amountOutMin, path, address(this),3279146672);
    }

       function SwapUsdcToEthByQuick(uint amountIn, uint amountOutMin)public {
        require(msg.sender == owner);
        address[] memory path = new address[](2);
        path[0] = usdc;
        path[1] = weth;
        quickSwapContract_.swapExactTokensForETH(amountIn , amountOutMin, path , msg.sender, 3279146672);
    }
    function EthSushiToQuick()public payable {
        require(msg.sender == owner);
        uint256 amountOut = EthToUsdcBySushi(msg.value);
        SwapEthToUsdcBySushi(amountOut.div(2));
        uint256 ETHamountOutMin = UsdcToEthByQuick(amountOut);
        SwapUsdcToEthByQuick(amountOut,ETHamountOutMin.div(2));
        
    }

    function wethAmountInQuickSwap() public view returns(uint256){
        return wethcontract_.balanceOf(weth_usdc_quickSwap);
    }
    function usdcAmountInQuickSwap() public view returns(uint256){
        return usdcContract_.balanceOf(weth_usdc_quickSwap);
    }
    function wethAmountInSushiSwap() public view returns(uint256){
        return wethcontract_.balanceOf(weth_usdc_sushi);
    }
    function usdcAmountInSushiSwap() public view returns(uint256){
        return usdcContract_.balanceOf(weth_usdc_sushi);
    }


    function EthToQuick(uint256 EthAmount) public view returns(uint256){
        uint256 EthIn = EthAmount.mul(1*(10**18));
        return UsdcToEthBySushi(EthToUsdcByQuick(EthIn));
    }
    function EthToUsdcByQuick(uint256 eth) public view returns(uint256){
        return quickSwapContract_.getAmountOut(eth, wethAmountInQuickSwap(),usdcAmountInQuickSwap());
    }
    function UsdcToEthBySushi(uint256 UsdcIn) public view returns(uint256){
        return quickSwapContract_.getAmountOut(UsdcIn,usdcAmountInSushiSwap(),wethAmountInSushiSwap());
    }



    function EthToSushi(uint256 EthAmount) public view returns(uint256){
        uint256 EthIn = EthAmount.mul(1*(10**18));
        return UsdcToEthByQuick(EthToUsdcBySushi(EthIn));
    }
    function EthToUsdcBySushi(uint256 eth) public view returns(uint256){
        return quickSwapContract_.getAmountOut(eth, wethAmountInSushiSwap(),usdcAmountInSushiSwap());
    }
    function UsdcToEthByQuick(uint256 UsdcIn) public view returns(uint256){
        return quickSwapContract_.getAmountOut(UsdcIn, usdcAmountInQuickSwap(),wethAmountInQuickSwap());
    }

    function approveUsdcForSushi()public{
        require(msg.sender == owner);
        usdcContract_.approve(sushiRouter,10000000000);
    }

        function approveUsdcForQuick()public{
        require(msg.sender == owner);
        usdcContract_.approve(quickSwap,10000000000);
    }


    function withdrawETH(uint256 ethWei) public{
        require(msg.sender == owner);
        msg.sender.transfer(ethWei);
    }

    function withdrawERC20(address tokenAddress) public{
        require(msg.sender == owner);
        erc20Contract myContract = erc20Contract(tokenAddress);
        uint256 balances_ = myContract.balanceOf(address(this));
        myContract.transfer(owner,balances_);
    }


}