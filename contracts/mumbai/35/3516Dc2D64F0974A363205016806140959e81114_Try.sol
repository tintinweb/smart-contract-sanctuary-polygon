/**
 *Submitted for verification at polygonscan.com on 2022-02-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Try{
    uint public a;
    function send(address payable _receiver, uint amount) public payable returns(uint){
        _receiver.transfer(amount);
        a = msg.value;
        return msg.value;
    }

}