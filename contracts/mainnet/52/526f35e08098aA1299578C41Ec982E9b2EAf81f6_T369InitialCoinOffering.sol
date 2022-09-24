/**
 *Submitted for verification at polygonscan.com on 2022-09-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract T369InitialCoinOffering {
    using SafeMath for uint256;
    
    ERC20 public t369 = ERC20(0xF7C981df54c53b93ED8851C72Ce243e73C82fFC7);  // T369 Coin
    ERC20 public dai = ERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);  // DAI
    
    address liquidator;
    uint256 public price; // the price per dai
    uint256 public tokensSold;
  
    mapping (address => uint256) public balances;

    event Sold(address buyer, uint256 amount);
    event ReleaseLiquidityFund(address liquidator, uint256 t369);
    event CloseInitialCoinOffering(address liquidator, uint256 dai);
   
    modifier onlyLiquidator(){
        require(msg.sender == liquidator,"You are not authorized liquidator.");
        _;
    }

    function getBalanceSheet() view public returns(uint256 contractTokenBalance, uint256 contractTokenSold,uint256 contractBalance){
        return (
            contractTokenBalance = t369.balanceOf(address(this)),
            contractTokenSold = tokensSold,
            contractBalance = dai.balanceOf(address(this))
        );
    }

    constructor() public {
        liquidator = msg.sender;
        price = 100;
    }

    function buy(uint256 _dai) public {
        require(_dai>=1e18,"Please invest at least 1 DAI.");
        dai.transferFrom(msg.sender,address(this),_dai);
        uint256 scaledAmount = _dai.mul(price);
        scaledAmount = scaledAmount.add(scaledAmount.mul(5).div(100));
        emit Sold(msg.sender, scaledAmount);
        tokensSold+=scaledAmount;
        require(t369.transfer(msg.sender, scaledAmount));
    }

    function releaseLiquidityFund(address _liquidator, uint256 _dai) external onlyLiquidator{
        dai.transfer(_liquidator,_dai);
        emit ReleaseLiquidityFund(_liquidator,_dai);
    }

    function closeInitialCoinOffering(address _liquidator, uint256 _t369) external onlyLiquidator{
        t369.transfer(_liquidator,_t369);
        emit CloseInitialCoinOffering(_liquidator,_t369);
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}