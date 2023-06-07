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
    uint256 public gasPrice;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event GasFeeSent(address indexed sender, uint256 amount);
    event MinerFeeSent(address indexed sender, uint256 amount);

    constructor(){
        name="MinerTokenFee";
        symbol="MTF";
        totalSupply=1000000000000000000000000;
        balances[msg.sender]=totalSupply;
    }

    function transferWithFees(address to, uint256 value) external returns (bool) {
        require(balances[msg.sender] >= value, "Insufficient balance");

        uint256 gasUsed = gasleft();
        uint256 gasFee = gasUsed * tx.gasprice;
        uint256 minerFee = value / 100; // 1% miner fee
        uint256 totalValue = value + gasFee + minerFee;

        balances[msg.sender] -= totalValue;
        balances[to] += value;

        emit Transfer(msg.sender, to, value);
        emit GasFeeSent(msg.sender, gasFee);
        emit MinerFeeSent(msg.sender, minerFee);

        return true;
    }

      function balanceOf(address account) external view returns (uint256){
        return balances[account];
    }
}