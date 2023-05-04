/**
 *Submitted for verification at polygonscan.com on 2023-05-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract paymentProcessor {

    mapping (address => uint) public balances;

    event paymentDone(
        address customer,
        uint cost,
        uint date
    );

    function pay() payable public {
        require(msg.value == 2 ether);
        balances[msg.sender] += msg.value;
        emit paymentDone(msg.sender, msg.value, block.timestamp);
    }

}