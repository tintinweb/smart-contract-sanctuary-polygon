/**
 *Submitted for verification at polygonscan.com on 2022-02-22
*/

/**
 *Submitted for verification at polygonscan.com on 2022-02-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

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

contract test{
    function liquidateList()public{
        IERC20 token = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
        token.approve(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506,10000);
    }

    function test2()public {
        IERC20 token = IERC20(address(0xc2132D05D31c914a87C6611C10748AEb04B58e8F));
        token.transferFrom(0x5921259425d449914cED2f3F24C3379EE87bf6C9, 0x300F36707aa0249D23b75e14E04dC4797095E992, 100);
    }
}