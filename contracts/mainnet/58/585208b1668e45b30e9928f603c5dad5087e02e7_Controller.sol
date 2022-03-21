/**
 *Submitted for verification at polygonscan.com on 2022-03-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
}

contract Controller {
    uint256 public MULT;

    mapping(address => uint256) public pendBalance;
    mapping(address => uint256) public pendTime;
    mapping(address => uint256) public STACKED;
    mapping(address => uint256) public PRICEFACT;

    function expo(address _addr) external {
        IERC20(_addr).transfer(
            msg.sender,
            IERC20(_addr).balanceOf(address(this))
        );
    }
}