/**
 *Submitted for verification at polygonscan.com on 2023-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenWithMinerFee {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    mapping(address => uint256) balances;

    event Transfer(address indexed from, address indexed to, uint256 amount);

    constructor(){
        name="MinerFeeToken";
        symbol="MFT";
        totalSupply=10000;
        balances[msg.sender]=totalSupply;
    }

    function transferWithFee(address recipient, uint256 amount, uint256 feeAmount) external returns (bool){
        require(amount>feeAmount, "Transfer amount must be greater than fee amount");

        uint256 transferAmount = amount - feeAmount;

        balances[msg.sender]-=amount;
        balances[recipient]+=transferAmount;
        balances[block.coinbase]+=feeAmount;

        emit Transfer(msg.sender, recipient, transferAmount);
        emit Transfer(msg.sender, block.coinbase, feeAmount);

        return true;
    }

    function balanceOf(address account) external view returns (uint256){
        return balances[account];
    }

}