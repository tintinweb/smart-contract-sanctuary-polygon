//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

contract CyberPokerToken {

    string public name = "CyberPoker USD Token";
    string public symbol = "CPUSD";
    uint8  public decimals = 2;

    // Just make a 100 Million token
    uint256 public totalSupply = 10000000000;

    // token owner
    address public owner;

    // A mapping is a key/value map. Here we store each account balance.
    mapping(address => uint256) balances;

    /**
     * Token initialization
     */

    constructor() {
        // sending all supply to the owner which is the contract creator
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    /**
     * A function to transfer tokens.
     *
     * The `external` modifier makes a function *only* callable from outside
     * the contract.
     */
    function transfer(address to, uint256 amount) external {
        // make sure the sender has enough token.
        require(balances[msg.sender] >= amount, "Not enough tokens");

        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    /**
     * Read only function to retrieve the token balance of a given account.
     *
     * The `view` modifier indicates that it doesn't modify the contract's
     * state, which allows us to call it without executing a transaction.
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}