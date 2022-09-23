/**
 *Submitted for verification at polygonscan.com on 2022-09-22
*/

/*  
 * SendMoneyToElkNet
 * 
 * Written by: MrGreenCrypto
 * Co-Founder of CodeCraftrs.com
 * 
 * SPDX-License-Identifier: None
 */
pragma solidity 0.8.17;

interface IBEP20 {
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IElkNet {
    function transfer(uint32 chainID, address recipient, uint256 elkAmount, uint256 gas) external;
}

interface IElkRouterMatic {
    function WMATIC() external pure returns (address);
    function swapExactMATICForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapExactTokensForMATIC(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactMATICForTokensSupportingFeeOnTransferTokens( uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function swapExactTokensForMATICSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

contract SendMoneyFromMaticToBsc {
    address public constant CEO = 0xe6497e1F2C5418978D5fC2cD32AA23315E7a41Fb;
    IBEP20 public constant ELK = IBEP20(0xeEeEEb57642040bE42185f49C52F7E9B38f8eeeE);
    IElkRouterMatic public constant ELK_ROUTER = IElkRouterMatic(0xf38a7A7Ac2D745E2204c13F824c00139DF831FFf);
    IElkNet public constant ELK_NET = IElkNet(0xb1F120578A7589FD9336315C4dF7d5A5d90173A8);

    uint256 public decimals;
    address[] private pathForBuyingElk = new address[](2);

    modifier onlyOwner() {if(msg.sender != CEO) return; _;}

    constructor() {
        decimals = ELK.decimals();
        pathForBuyingElk[0] = ELK_ROUTER.WMATIC();
        pathForBuyingElk[1] = address(ELK);
        ELK.approve(address(ELK_NET), type(uint256).max);
    }

    receive() external payable {}

    function bridgeMaticToBsc() external payable {
        ELK_ROUTER.swapExactMATICForTokens(0, pathForBuyingElk, address(this), block.timestamp);
        ELK_NET.transfer(56, CEO, ELK.balanceOf(address(this)), 1000000000000000000);
    }

    function bridgeMaticToBscAllSwap() external payable {
        ELK_ROUTER.swapExactMATICForTokens(0, pathForBuyingElk, address(this), block.timestamp);
        uint256 elkBalance = ELK.balanceOf(address(this));
        ELK_NET.transfer(56, CEO, elkBalance, elkBalance);
    }

    function bridgeMaticToBscPercentSwap(uint256 percent) external payable {
        ELK_ROUTER.swapExactMATICForTokens(0, pathForBuyingElk, address(this), block.timestamp);
        uint256 elkBalance = ELK.balanceOf(address(this));
        ELK_NET.transfer(56, CEO, elkBalance, elkBalance * percent / 100);
    }

    function bridgeMaticToBscKeepSomeElk(uint256 elkToKeep) external payable {
        ELK_ROUTER.swapExactMATICForTokens(0, pathForBuyingElk, address(this), block.timestamp);
        uint256 elkBalance = ELK.balanceOf(address(this));
        ELK_NET.transfer(56, CEO, elkBalance, elkBalance - (elkToKeep * 10**decimals));
    }

    function rescueAnyToken(address token) external onlyOwner {
        IBEP20(token).transfer(msg.sender, IBEP20(token).balanceOf(address(this)));
    }
    
    function rescueMatic() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}