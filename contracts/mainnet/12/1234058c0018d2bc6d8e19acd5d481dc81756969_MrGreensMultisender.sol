/**
 *Submitted for verification at polygonscan.com on 2022-07-06
*/

// Code written by MrGreenCrypto
// SPDX-License-Identifier: None

pragma solidity 0.8.15;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MrGreensMultisender {
    address private MrGreen = 0xe6497e1F2C5418978D5fC2cD32AA23315E7a41Fb;

    constructor() {}

    function sendETH(address[] calldata wallets, uint256[] calldata amounts) external payable{
        for(uint256 i = 0; i < wallets.length; i++) {
            payable(wallets[i]).transfer(amounts[i]);
        }
        if(address(this).balance > 0) payable(MrGreen).transfer(address(this).balance);
    }

    function sendTokens(address token, address[] calldata wallets, uint256[] calldata amounts) external payable{
        uint256 multiplier = 10 ** IBEP20(token).decimals();
        for(uint256 i = 0; i < wallets.length; i++) {
            IBEP20(token).transferFrom(msg.sender, wallets[i],amounts[i] * multiplier);
        }
        if(address(this).balance > 0) payable(MrGreen).transfer(address(this).balance);
    }
}