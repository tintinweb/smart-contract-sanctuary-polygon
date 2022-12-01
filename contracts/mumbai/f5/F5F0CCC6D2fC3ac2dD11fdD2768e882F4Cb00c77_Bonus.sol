/**
 *Submitted for verification at polygonscan.com on 2022-12-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Bonus {
    address public minter;
    mapping(address => uint256) public balances;
    address DappLeader;
    //DappLeader = msg.sender;
    //Write a condition for bonus

    event Sent(address from, address to, uint256 amount);

    constructor() {
        minter = msg.sender;
    }

    // Sends an amount of newly created coins to an address
    // Can only be called by the contract creator
    function mint(address receiver, uint256 amount) public {
        require(msg.sender == minter);
        balances[receiver] += amount;
    }

    //Add a  code for symbol, check if symbol is same in the community
    //require(

    function check_community(address community, uint256 amount) public {
        require(msg.sender == minter); //define above the each and every community stuff
        balances[community] += amount;
    }

    error InsufficientBalance(uint256 requested, uint256 available);
    error CantClaimMoney(address from, address to);

    // Sends an amount of existing coins
    // from any caller to an address
    function send(address receiver, uint256 amount) public {
        if (amount > balances[msg.sender])
            revert InsufficientBalance({
                requested: amount,
                available: balances[msg.sender]
            });

        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender, receiver, amount);
    }

    //Add memo string condition
}