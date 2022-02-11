/**
 *Submitted for verification at polygonscan.com on 2022-02-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
interface IQuickSwapPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
interface IQuickSwapRouter {
    function factory() external pure returns (address);
    function addLiquidity(address tokenA,address tokenB,uint amountADesired,uint amountBDesired,uint amountAMin,uint amountBMin,address to,uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external;
    function swapExactTokensForTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external returns (uint[] memory amounts);
}
interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function decimals() external pure returns (uint8);
}
contract Liquidity {
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived,uint256 tokensIntoLiqudity);
    bool inSwapAndLiquify=false;
    IQuickSwapPair public pair;
    IQuickSwapRouter public quickSwapRouter;
    mapping (address => bool) public permitedAddress;
    constructor(){
        permitedAddress[msg.sender]=true;
    }
    modifier whenPermited() {
        require(permitedAddress[msg.sender],"Not permited");
        _;
    }
    function setRouterAddress(address ad) public whenPermited {
        quickSwapRouter=IQuickSwapRouter(ad);
    }
    function setPairAddress(address ad) public whenPermited {
        pair=IQuickSwapPair(ad);
    }
    function setPermitedAddress(address ad, bool permited) public whenPermited {
        permitedAddress[ad]=permited;
    }
    function getToken0()public view returns(address){
        return pair.token0();
    }
    function getToken1()public view returns(address){
        return pair.token1();
    }
    function getTokenPrice() public view returns(uint){
        (uint Res0, uint Res1,) = pair.getReserves();
        uint res0 = Res0*(10**IERC20(getToken1()).decimals());
        return res0/Res1; // return amount of token0 needed to buy token1
    }
    receive() external payable {}
    function swapAndLiquify(uint256 amount) public whenPermited {
        if(!inSwapAndLiquify){
            inSwapAndLiquify=true;
            uint256 half = amount/2;
            uint256 otherHalf = amount-half;
            uint256 initialBalance = IERC20(getToken1()).balanceOf(address(this));
            swapTokensForTokens(half);
            uint256 tokenToAdd = IERC20(getToken1()).balanceOf(address(this))-initialBalance;
            addLiquidity(otherHalf, tokenToAdd);
            emit SwapAndLiquify(half, tokenToAdd, otherHalf);
            inSwapAndLiquify=false;
        }
    }
    function swapTokensForTokens(uint256 tokenAmount) public whenPermited{
        address[] memory path = new address[](2);
        path[0] = getToken0();
        path[1] = getToken1();
        IERC20(getToken0()).approve(address(quickSwapRouter),tokenAmount);
        quickSwapRouter.swapExactTokensForTokens(tokenAmount,0,path,address(this),block.timestamp);
    }
    function addLiquidity(uint256 tokenAmount, uint256 otherTokenAmount) public whenPermited{
        IERC20(getToken0()).approve(address(quickSwapRouter),tokenAmount);
        IERC20(getToken1()).approve(address(quickSwapRouter),otherTokenAmount);
        quickSwapRouter.addLiquidity(getToken0(), getToken1(), tokenAmount, otherTokenAmount, 0, 0, address(this), block.timestamp);
    }
    function withdrawToken(address _tokenContract, uint256 _amount) public whenPermited {
        IERC20(_tokenContract).transfer(msg.sender, _amount);
    }
}