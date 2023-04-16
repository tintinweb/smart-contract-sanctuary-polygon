/**
 *Submitted for verification at polygonscan.com on 2023-04-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EscrowPoly {
    address payable public owner;
    address payable public attacker;
    address payable public fundReceiver;
    uint public funds;
    bool public mutex;
    event Funded(address indexed sender, uint value);
    event AttackerAddressSet(address indexed attacker);
    event FundsReleased(address indexed receiver, uint value);

    constructor() {
        owner = payable (msg.sender);
        mutex = false;
    }

    function fund() public payable {
        require(msg.value > 0);
        //require(gasleft() <= 200000, "Too much gas");
        funds += msg.value;
        fundReceiver = payable(msg.sender);
        emit Funded(msg.sender, msg.value);
    }

    function attackerAddress(address payable _attacker)payable public {
        require(msg.sender == owner);
        attacker = _attacker;
        emit AttackerAddressSet(_attacker);
    }

    function releaseFund() public {
        require(msg.sender == owner);
        require(attacker != address(0));
        require(!mutex);
        mutex = true;
        attacker.transfer(funds);
        mutex = false;
        emit FundsReleased(attacker, funds);
    }
}