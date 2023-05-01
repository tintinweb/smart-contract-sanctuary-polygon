// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

contract Sender {

    function send(address payable[] memory to) public payable {
        uint value = msg.value / to.length;
        for(uint i; i < to.length; i++) {
            require(to[i].send(value), "Not possible to send");
        }
    }
}