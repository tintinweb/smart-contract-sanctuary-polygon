// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./SafeERC20.sol";

contract giveaway  {
    address public owner;
    uint256 public balance;
    mapping (address => uint) timeouts;

    address payable admin;
    
    event TransferReceived(address _from, uint _amount);
    event TransferSent(address _from, address _destAddr, uint _amount);
    
    constructor() {
        owner = msg.sender;
    }
    
    receive() payable external {
        balance += msg.value;
        emit TransferReceived(msg.sender, msg.value);
    }    

    function transferERC20(IERC20 token, address to) public { 
        uint256 erc20balance = token.balanceOf(address(this));
        uint amount = 50000 * 10000; // 50K
        require(amount <= erc20balance, "balance is low");
        if (msg.sender!=owner) require(timeouts[msg.sender] <= block.timestamp - 61 days, "Just once. We are sorry.");
        token.transfer(to, amount);
        timeouts[msg.sender] = block.timestamp;
        emit TransferSent(msg.sender, to, amount);
    }

    function endGiveaway() public {
        if (msg.sender == owner) selfdestruct(admin);
    }

}