/**
 *Submitted for verification at polygonscan.com on 2022-05-10
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8;

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

interface IQuickRouter02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IApeRouter02 {
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}



contract myswap{
    address internal owner;
    address internal constant IQuickRouter02add = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address internal constant IApeRouter02add = 0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607;
    address weth= 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address usdc= 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    IQuickRouter02 private quickrouter2;
    IApeRouter02 private aperouter2;


    constructor() {
        quickrouter2 = IQuickRouter02(IQuickRouter02add);
        aperouter2 = IApeRouter02(IApeRouter02add);

        owner = msg.sender; 
        }


    modifier isOwner(){
        require(msg.sender == owner, "Caller is not owner");
        _;
        }


    function quicktoapeswap(uint amountIn,address tokenAddress) external isOwner{
        IERC20(weth).approve(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff,amountIn);
        uint256 ethbefore = IERC20(weth).balanceOf(address(this));
        quickrouter2.swapExactTokensForTokens(amountIn,0,getPathForEthToToken(tokenAddress),address(this),block.timestamp);
        uint256 tokenMiddle = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).approve(0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607,tokenMiddle);
        aperouter2.swapExactTokensForTokens(tokenMiddle, 0, getPathForTokenToEth(tokenAddress), address(this), block.timestamp); 
        uint256 ethafter = IERC20(weth).balanceOf(address(this));
        require(ethafter > ethbefore, "ETH not enough");
    }

    function apetoquickswap(uint amountIn,address tokenAddress) external isOwner{
        IERC20(weth).approve(0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607,amountIn);
        uint256 ethbefore = IERC20(weth).balanceOf(address(this));
        aperouter2.swapExactTokensForTokens(amountIn,0,getPathForEthToToken(tokenAddress),address(this),block.timestamp);
        uint256 tokenMiddle = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).approve(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff,tokenMiddle);
        quickrouter2.swapExactTokensForTokens(tokenMiddle,0,getPathForTokenToEth(tokenAddress),address(this),block.timestamp);
        uint256 ethafter = IERC20(weth).balanceOf(address(this));
        require(ethafter > ethbefore, "ETH not enough");
   }

    function getPathForEthToToken(address tokenAddress) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = tokenAddress;
        return path;
        }    
        
    function getPathForTokenToEth(address tokenAddress) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = address(weth);
        return path;
        }

    function Swap(uint amountIn) external isOwner{
        IERC20(weth).approve(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff,amountIn);
        address[] memory path = new address[](2);
        path[0]=address(weth);
        path[1]=address(usdc);
        quickrouter2.swapExactTokensForTokens(amountIn,0,path,msg.sender,block.timestamp);
    }

    function withdraw(address payable _address, uint withdrawAmount) public payable isOwner{
        _address.transfer(withdrawAmount);
    }
    
    function sendEther() public payable isOwner{
    }

}