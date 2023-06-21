/**
 *Submitted for verification at polygonscan.com on 2023-06-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IST20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract DxBank_Presale {
  using SafeMath for uint256;
  IST20 public token;
  IST20 public USDT; // Agregar variable para USDT
  uint256 public rate;
  uint256 public weiRaised;
  uint256 public weiMaxPurchaseUsdt; // Cambiar el nombre de la variable
  address payable private admin;
  mapping(address => uint256) public purchasedUsdt; // Cambiar el nombre del mapping
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  
  constructor(uint256 _rate, IST20 _usdt, uint256 _max) public { // Cambiar el nombre del argumento y la variable
    require(_rate > 0);
    require(_max > 0);
    require(_usdt != IST20(address(0)));
    rate = _rate;
    USDT = _usdt; // Establecer la variable USDT
    weiMaxPurchaseUsdt = _max; // Cambiar el nombre de la variable
    admin = 0xc575ec628e73daa6B12ff7965639D3f4eF35c547;
  }
  fallback () external payable {
    revert();    
  }
  receive () external payable {
    revert();
  }
  function buyTokens(address _beneficiary, uint256 _usdtAmount) public {
    require(_beneficiary != address(0));
    require(_usdtAmount != 0);
    uint256 maxUsdtAmount = maxUsdt(_beneficiary);
    uint256 weiAmount = _usdtAmount.mul(1e18).div(rate); // Convertir la cantidad de USDT a wei en función del tipo de cambio
    require(weiAmount <= maxUsdtAmount, "Exceeds the maximum allowed purchase amount");
    uint256 tokenAmount = _getTokenAmount(_usdtAmount);
    require(tokenAmount <= USDT.balanceOf(address(this)), "Not enough tokens in the contract");
    weiRaised = weiRaised.add(weiAmount);
    USDT.transferFrom(msg.sender, address(this), _usdtAmount); // Transferir los USDT del comprador al contrato
    _processPurchase(_beneficiary, tokenAmount);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokenAmount);
    _updatePurchasingState(_beneficiary, weiAmount);
  }
  function _preValidatePurchase(address _beneficiary, uint256 _usdtAmount) public view returns (uint256) {
    require(_beneficiary != address(0));
    require(_usdtAmount != 0);
    uint256 weiAmount = _usdtAmount.mul(1e18).div(rate);
    uint256 tokenAmount = _getTokenAmount(_usdtAmount);
    uint256 curBalance = USDT.balanceOf(address(this));
    if (tokenAmount > curBalance) {
      return curBalance.mul(rate).div(1e18);
    }
    return weiAmount;
  }
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
    purchasedUsdt[_beneficiary] = _weiAmount.add(purchasedUsdt[_beneficiary]);    
  }
  function _getTokenAmount(uint256 _usdtAmount) public view returns (uint256) {
    return _usdtAmount.mul(1e18).div(rate); // Convertir la cantidad de USDT a tokens en función del tipo de cambio
  }
  function setPresaleRate(uint256 _rate) external {
    require(admin == msg.sender, "caller is not the owner");
    rate = _rate;
  }    
  function maxUsdt(address _beneficiary) public view returns (uint256) {
    return weiMaxPurchaseUsdt.sub(purchasedUsdt[_beneficiary]);
  }
  function withdrawCoins() external {
    require(admin == msg.sender, "caller is not the owner");
    admin.transfer(address(this).balance);
  }
  function withdrawTokens(address tokenAddress, uint256 tokens) external {
    require(admin == msg.sender, "caller is not the owner");
    IST20(tokenAddress).transfer(admin, tokens);
  }
}