/**
 *Submitted for verification at polygonscan.com on 2022-12-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
// IRC20 interface
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Token {
    IERC20 cguToken =IERC20(cguAddress);
    address constant cguAddress = 0xb870318Bca4f5903895bF30743B11EE0fF78AA2d;
    uint  init=10**18;
    function getBalance()public view returns(uint){
        return cguToken.balanceOf(msg.sender);
    }
    function traferToken(address _to, uint _amount)public{
        cguToken.transfer( _to ,_amount * init);
    }
}