/**
 *Submitted for verification at polygonscan.com on 2022-08-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )external payable returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function faucet(address account,uint256 amount,uint256 price) external;
  function burnt(address account,uint256 amount,uint256 price) external;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) { owner = _owner; }
    modifier onlyOwner() { require(isOwner(msg.sender), "!OWNER"); _; }

    function getOwner() public view returns (address) {
        return owner;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract RewardBank is Ownable {
  using SafeMath for uint256;

  event onDeposit(uint256 _id,address indexed _from,uint256 _amountWETH,uint256 _amountUSDT,uint256 _when);

  IUniswapV2Router public router;
  address private MATIC_ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
  address private MATIC_USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

  address private receiver1;
  address private receiver2;
  uint256 private periodamount;
  uint256 private periodcooldown;

  uint256 private wait;

  uint256 private depositid;
  mapping (uint256=>address) private recipe_depositor;
  mapping (uint256=>uint256) private recipe_amountWETH;
  mapping (uint256=>uint256) private recipe_amountUSDT;
  mapping (uint256=>uint256) private recipe_block;

  uint256 private depositfee;
  uint256 private denominator;
  
  constructor(
      address _receive1,
      address _receive2,
      uint256 _periodamount,
      uint256 _periodcooldown,
      uint256 _fee,
      uint256 _denominator
    ) Ownable(msg.sender)
    {
      receiver1 = _receive1;
      receiver2 = _receive2;
      periodamount = _periodamount;
      periodcooldown = _periodcooldown;
      depositfee = _fee;
      denominator = _denominator;
      router = IUniswapV2Router(MATIC_ROUTER);
    }

  function configBank(
      address _receiver1,
      address _receiver2,
      uint256 _periodamount,
      uint256 _periodcooldown,
      uint256 _fee,
      uint256 _denominator
    ) external onlyOwner returns (bool)
    {
      receiver1 = _receiver1;
      receiver2 = _receiver2;
      periodamount = _periodamount;
      periodcooldown = _periodcooldown;
      depositfee = _fee;
      denominator = _denominator;
      return true;
    }

  function getBank() external view returns (
      address _receiver1,
      address _receiver2,
      uint256 _periodamount,
      uint256 _periodcooldown,
      uint256 _fee,
      uint256 _denominator)
    { return 
      (
      receiver1,
      receiver2,
      periodamount,
      periodcooldown,
      depositfee,
      denominator
      );
    }

  function deposit() external payable returns (uint256 id,address txowner,uint256 amountWETH,uint256 amountUSDT,uint256 when) {
    IERC20 a = IERC20(MATIC_USDT);
    uint256 beforebalance = a.balanceOf(address(this));
    address[] memory path = new address[](2);
    path[0] = router.WETH();
    path[1] = MATIC_USDT;
    router.swapExactETHForTokens{ value : msg.value }(0,path,address(this),block.timestamp.add(300));
    uint256 afterbalance = a.balanceOf(address(this));
    uint256 amount = afterbalance.sub(beforebalance);
    uint256 takefee = amount.mul(depositfee).div(denominator);
    a.transfer(receiver1,takefee);
    a.transfer(receiver2,takefee);
    generaterecipe(msg.sender,msg.value,amount,block.timestamp);
    emit onDeposit(depositid,recipe_depositor[depositid],recipe_amountWETH[depositid],recipe_amountUSDT[depositid],recipe_block[depositid]);
    return (
      depositid,
      recipe_depositor[depositid],
      recipe_amountWETH[depositid],
      recipe_amountUSDT[depositid],
      recipe_block[depositid]
    );
  }

  function aprroval(address erc20address,address spender,bool flag) external onlyOwner returns (bool) {
    IERC20 a = IERC20(erc20address);
    if(flag){
    a.approve(spender,type(uint256).max);
    }else{
    a.approve(spender,0);
    }
    return true;
  }

  function reserve() external returns (bool) {
    require(block.timestamp>wait,"IBANK : revert by transfer wait");
    wait = block.timestamp.add(periodcooldown);
    IERC20 a = IERC20(MATIC_USDT);
    a.transferFrom(address(this),msg.sender,periodamount);
    return true;
  }

  function getoracleprice(uint256 dollar) external view returns (uint[] memory) {
    address[] memory path = new address[](2);
    path[0] = router.WETH();
    path[1] = MATIC_USDT;
    return router.getAmountsIn(dollar,path);
  }

  function getlastdeposit() external view returns (uint256 id,address txowner,uint256 amountWETH,uint256 amountUSDT,uint256 when){
    return (
      depositid,
      recipe_depositor[depositid],
      recipe_amountWETH[depositid],
      recipe_amountUSDT[depositid],
      recipe_block[depositid]
    );
  }

  function getrecipe(uint256 recipeid) external view returns (uint256 id,address txowner,uint256 amountWETH,uint256 amountUSDT,uint256 when){
    return (
      recipeid,
      recipe_depositor[recipeid],
      recipe_amountWETH[recipeid],
      recipe_amountUSDT[recipeid],
      recipe_block[recipeid]
    );
  }

  function generaterecipe(address _depositor,uint256 _amountWETH,uint256 _amountUSDT,uint256 _when) internal returns (bool) {
    depositid = depositid.add(1);
    recipe_depositor[depositid] = _depositor;
    recipe_amountWETH[depositid] = _amountWETH;
    recipe_amountUSDT[depositid] = _amountUSDT;
    recipe_block[depositid] = _when;
    return true;
  }

  function purge() external onlyOwner() returns (bool) {
    (bool success, ) = msg.sender.call{ value : address(this).balance }("");
    require(success,"purge fail!");
    return true;
  }

  function getwait() external view returns (uint256) { return wait; }
  function getdepositid() external view returns (uint256) { return depositid; }
  function recaive() public payable {}
  function balance() public view returns (uint256) { return address(this).balance; }
}