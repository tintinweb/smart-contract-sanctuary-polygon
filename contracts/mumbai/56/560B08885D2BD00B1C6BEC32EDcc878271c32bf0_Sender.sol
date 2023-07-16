// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <0.9.0;

contract Sender {
    function getSender() public view returns(address) {
        return msg.sender;
    }
}