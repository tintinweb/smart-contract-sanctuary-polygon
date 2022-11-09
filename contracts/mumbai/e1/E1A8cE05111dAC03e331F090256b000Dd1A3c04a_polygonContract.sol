// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IWETH {
  function deposit() external payable;
  function transfer(address to, uint256 value) external returns (bool);
  function withdraw(uint256 value) external payable;
}

interface IERC20 {
  function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
} 

contract polygonContract {
  address public WETH = 0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa;
  function send(uint256 _amount) public {
    require(_amount <= IERC20(WETH).balanceOf(msg.sender),"invalid amount");
    IERC20(WETH).transfer(address(this), _amount);
  }

  function balance() public view returns(uint) {
    uint256 bal = IERC20(WETH).balanceOf(address(this));
    return bal;
  }

  function withdrawWeth(uint256 _amount) public {

  }
}