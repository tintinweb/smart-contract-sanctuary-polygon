/**
 *Submitted for verification at polygonscan.com on 2022-11-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.12;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint value) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}
contract a {
    event aa (address _user,uint256 _amount);
    uint256 public usdtAmount = 0;
    IERC20 public USDT = IERC20(0x110981e124BB0fb272036a4433428c6563D90178);
    fallback() external  {
       if (USDT.balanceOf(address(this))>usdtAmount) {
           usdtAmount = USDT.balanceOf(address(this));
           emit aa(msg.sender,USDT.balanceOf(address(this))-usdtAmount);
       }
    }
}