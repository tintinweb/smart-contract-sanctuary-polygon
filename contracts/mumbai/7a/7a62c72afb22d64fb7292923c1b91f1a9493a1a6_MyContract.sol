/**
 *Submitted for verification at polygonscan.com on 2022-10-16
*/

pragma solidity ^0.4.24;

interface IERC20 {
  function transfer(address recipient, uint256 amount) external;
  function balanceOf(address account) external view returns (uint256);
  function transferFrom(address sender, address recipient, uint256 amount) external ;
  function decimals() external view returns (uint8);
}

contract  MyContract {
   	IERC20 usdt;
	constructor(IERC20 _usdt) public  {
        usdt = _usdt;
    }

   
  function  transferOut(address to, uint256 amount) external {
    usdt.transfer(to, amount);
  }

  function  transferIn(address from,  uint256 amount) external {
    usdt.transferFrom(from, address(this), amount);
  }
}