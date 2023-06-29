/**
 *Submitted for verification at polygonscan.com on 2023-06-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SmartDex
{
    struct DexData{
        address routerAddress;
        string name;
    }
    
    struct RoutData{
        string name;
        address routerAddress;
        uint256 OutAmount;
        uint InAmountPercent;
    }
    DexData[] public DexList;
    address owner ;
    uint256 fee = 1;
    
    event Received(address, uint);

    constructor(){
         owner = msg.sender;
    }

    function addDex(address routerAddress , string memory name) external onlyOwner returns(bool){
        require(!isDexExsist(routerAddress) , "dex is already exsists!");
        DexData memory newDex =  DexData(routerAddress , name);
        DexList.push(newDex);
        return true;
    }

    function isDexExsist(address routerAddress) private view returns(bool){
        bool retValue = false;
        for(uint i = 0 ; i < DexList.length ; i++)
        {
            if(DexList[i].routerAddress == routerAddress)
            {
                retValue = true;

            }
        }
        return retValue;
    }
    
    function getSimpleSwapBestPrice(address token0 ,address token1 , uint256 amount , address[] memory activeDex)
     external view returns(RoutData memory data){
         uint256 trueAmount = amount - ((amount / 1000) * fee);
         uint256 retOutAmount = 0;
         string memory retName;
         address retRouterAddress;
         if(activeDex.length == 0)
         {
            for(uint i = 0 ; i < DexList.length ; i++)
            {
                    IUniswapV2Router router = IUniswapV2Router(DexList[i].routerAddress);
                    address[] memory path;
                    path = new address[](2);
                    path[0] = token0;
                    path[1] = token1;
                    uint256[] memory amounts = router.getAmountsOut(trueAmount , path);
                    if(amounts[1]>retOutAmount)
                    {
                        retOutAmount = amounts[1];
                        retName = DexList[i].name;
                        retRouterAddress = DexList[i].routerAddress;
                    }
            }
         }
         else
         {
            for(uint i = 0 ; i < activeDex.length ; i++)
            {
                    IUniswapV2Router router = IUniswapV2Router(activeDex[i]);
                    address[] memory path;
                    path = new address[](2);
                    path[0] = token0;
                    path[1] = token1;
                    uint256[] memory amounts = router.getAmountsOut(trueAmount , path);
                    if(amounts[1]>retOutAmount)
                    {
                        retOutAmount = amounts[1];
                        retName = getDexNameByRouterAddress(activeDex[i]);
                        retRouterAddress = activeDex[i];
                    }
            }
        
         }
         return  RoutData(retName , retRouterAddress , retOutAmount , 100);
     }
    
    
    function simpleSwapTokens(address token1,address token2,uint256 inAmount , uint256 outAmountMin ,address router) public returns(uint256 outAmount)
    {
        require(isDexExsist(router) , "Router address not found!");

        IUniswapV2Router  routerFrom = IUniswapV2Router(router);
        IERC20 _token1 = IERC20(token1);

        require(_token1.balanceOf(msg.sender) > inAmount , "The account balance is insufficient!");
        require(_token1.allowance(address(msg.sender ) , address(this) ) > inAmount , "The amount of allowance is not enough");


        uint256 feeAmount = inAmount / 1000 * fee;
        uint256 newInAmount = inAmount - feeAmount;

        _token1.transferFrom(msg.sender, address(this), feeAmount);
        _token1.approve(address(routerFrom), newInAmount);

        address[] memory path;
        path = new address[](2);
        path[0] = token1;
        path[1] = token2;

        uint[] memory amounts = routerFrom.swapExactTokensForTokens(
            newInAmount,
            outAmountMin,
            path,
            address(msg.sender),
            block.timestamp
        );

        return amounts[1];
    }
    
    function getDexNameByRouterAddress(address router) view public returns(string memory name){
        string memory returnValue = "not found";
        for(uint i = 0 ; i < DexList.length ; i++)
        {
            if(DexList[i].routerAddress == router)
            {
                returnValue = DexList[i].name;
            }
        }
        return returnValue;
    }

    function isOwner() public view returns(bool){
        return msg.sender == owner;
    }
     modifier onlyOwner(){
        require(isOwner() , "only by owner");
        _;
    }

    function withdraw(uint _amount) public onlyOwner {
        require(address(this).balance>= _amount);
        (bool sent,) = msg.sender.call{value: _amount}("Sent");
        require(sent);
    }

    function getContractBalance() public view returns(uint256){
        return address(this).balance;
    }

    function withdrawToken(address tokenAddress ,uint256 _amount) public onlyOwner {
        require(IERC20(tokenAddress).balanceOf(address(this)) >= _amount);
        IERC20(tokenAddress).transfer(owner,_amount);
    }

    function getContractTokenBalance(address tokenAddress) public view returns(uint256){
          return IERC20(tokenAddress).balanceOf(address(this));
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

}

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}