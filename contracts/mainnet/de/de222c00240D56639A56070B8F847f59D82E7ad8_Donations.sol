/**
 *Submitted for verification at polygonscan.com on 2022-07-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
}

contract Donations {

    IERC20 dai = IERC20(0x39c51E95A037Fe59E42B3a474D6ee4aB400E9Cd2);
    IERC20 usdc = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    uint256 public totalDonations;

    event newDonation(address);

    function donationSimulation(uint amount) public {
        require(amount > 0, "Donation value > 0");
        uint256 daiBalance = dai.balanceOf(msg.sender);
        uint256 usdcBalance = usdc.balanceOf(msg.sender);
        require(usdcBalance + daiBalance >= amount, "You don't have enough funds");
        totalDonations += amount;
        emit newDonation(msg.sender);
    }
}