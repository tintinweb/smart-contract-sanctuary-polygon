// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract TransaksiPenjualan {
  
    mapping (address => uint) public balances;

    event Sent(address from, address to, uint amount);

    error InsufficientBalance(uint requested, uint available);

    function send(address receiver, uint amount) public {
        if (amount > balances[msg.sender])
            revert InsufficientBalance({
                requested: amount,
                available: balances[msg.sender]
            });

        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender, receiver, amount);
    }
}