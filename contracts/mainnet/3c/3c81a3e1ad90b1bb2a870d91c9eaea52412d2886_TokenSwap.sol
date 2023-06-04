/**
 *Submitted for verification at polygonscan.com on 2023-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}
 
contract TokenSwap {
    address public awcAddress;
    address public awtAddress;
    IERC20 public awc;
    IERC20 public awt;
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    function setSwapPair(address _awc, address _awt) public {
        require(msg.sender == admin, "Only admin can call this function");
        awc = IERC20(_awc);
        awt = IERC20(_awt);
    }
 
    function swapAWCtoAWT(uint amount) public {
        require(awc.balanceOf(msg.sender) >= amount, "Not enough AWC balance");
        require(awc.transferFrom(msg.sender, address(this), amount), "AWC transfer failed");
        require(awt.transfer(msg.sender, amount), "AWT transfer failed");
    }
 
    function swapAWTtoAWC(uint amount) public {
        require(awt.balanceOf(msg.sender) >= amount, "Not enough AWT balance");
        require(awt.transferFrom(msg.sender, address(this), amount), "AWT transfer failed");
        require(awc.transfer(msg.sender, amount), "AWC transfer failed");
    }
 
    function approveAWC(uint amount) public {
        require(awc.approve(address(this), amount), "Approval failed");
    }
 
    function approveAWT(uint amount) public {
        require(awt.approve(address(this), amount), "Approval failed");
    }
    
    function withdraw() public {
        require(msg.sender == admin, "Only admin can call this function");

        uint256 awcBalance = awc.balanceOf(address(this));
        require(awc.transfer(admin, awcBalance), "AWC transfer failed");

        uint256 awtBalance = awt.balanceOf(address(this));
        require(awt.transfer(admin, awtBalance), "AWT transfer failed");
    }

    function setAdmin(address _admin) public {
        require(msg.sender == admin, "Only admin can call this function");
        admin = _admin;
    }
}